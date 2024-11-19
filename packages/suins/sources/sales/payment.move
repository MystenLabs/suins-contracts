/// This module is used to streamline our payment flows.
///
/// Whenever a registration or renewal request comes in, we issue a
/// `PaymentIntent` that holds the data required to complete the payment,
/// nominated in the base price units (will be USDC in our case).
///
/// Authorized apps are required to finalize any payment, so we can ensure that
/// we can keep
/// our payment flows upgradeable, without the need to upgrade the packages
/// whenever the
/// core protocol has a change, as well as gated
/// (so we can turn registrations/renewals off in case of an emergency).
///
/// Authorized apps can also apply discounts to the payment intent. This is
/// useful for system-level discounts, or user-specific discounts.
///
/// TODO: Convert percentages to basis points (u16: 1-10_000) instead of u8
/// (1-100) (??)
/// TODO: Add system-level events for renewals / registrations.
/// TODO: Add metadata (for future-proofness) VecMap on `RequestData`
/// TODO: Consider re-using `RequestData` inside the `Receipt`.
module suins::payment;

use std::string::String;
use sui::clock::Clock;
use sui::coin::Coin;
use suins::config;
use suins::constants;
use suins::domain::{Self, Domain};
use suins::pricing_config::{PricingConfig, RenewalConfig};
use suins::registry::Registry;
use suins::suins::SuiNS;
use suins::suins_registration::SuinsRegistration;

/// The version of the payment module. Can be used by authorized apps
/// to ensure that they are only interacting with a `PaymentIntent`
/// of the correct version.
///
/// Also used by the register/renew functions to ensure that the receipt
/// can match the intent.
///
/// This will only be incremented if we have any breaking changes.
const PAYMENT_VERSION: u8 = 1;

#[error]
const ENotMultipleDiscountsAllowed: vector<u8> =
    b"Multiple discounts are not allowed";
#[error]
const ENotSupportedType: vector<u8> =
    b"Renewal is not supported in this function call. Call `renew` instead.";
#[error]
const ERecordNotFound: vector<u8> =
    b"Tries to renew a name that does not exist in the registry (has expired + has been burned)";
#[error]
const ERecordExpired: vector<u8> =
    b"Tries to renew an expired name (post grace period).";
#[error]
const EReceiptDomainMissmatch: vector<u8> =
    b"The receipt domain does not match the domain of the NFT.";
#[error]
const EVersionMismatch: vector<u8> =
    b"Version mismatch. The payment intent is not of the correct version for this package.";
#[error]
const EInvalidDiscountPercentage: vector<u8> = b"Discount range is [0, 100].";
#[error]
const ECannotRenewSubdomain: vector<u8> =
    b"Cannot renew a subdomain using the payment system.";

/// The data required to complete a payment request.
public struct RequestData has drop {
    /// The version of the payment module.
    version: u8,
    /// The domain for which the payment is being made.
    domain: Domain,
    /// The years for which the payment is being made.
    /// Defaults to 1 for registration.
    years: u8,
    /// The amount the user has to pay in base units.
    base_amount: u64,
    /// Whether a discount has already been applied to the amount.
    discount_applied: bool,
    // TODO: Add metadata for future-proofness?
}

/// The payment intent for a given domain
/// - Registration: The user is registering a new domain.
/// - Renewal: The user is renewing an existing domain.
public enum PaymentIntent {
    Registration(RequestData),
    Renewal(RequestData),
}

/// A receipt that is generated after a successful payment.
/// Can be used to:
/// - Prove that the payment was successful.
/// - Register a new name, or renew an existing one.
public enum Receipt {
    Registration { domain: Domain, years: u8, version: u8 },
    Renewal { domain: Domain, years: u8, version: u8 },
}

/// Allow an authorized app to apply a percentage discount to
/// the payment intent.
public fun apply_percentage_discount<App: drop>(
    intent: &mut PaymentIntent,
    suins: &mut SuiNS,
    _: App,
    // discount can be in range [1, 100]
    discount: u8,
    // whether multiple discounts can be applied. This is here to allow for
    // system-level
    // discounts to be applied on top of user discounts.
    // E.g. an NS payment can apply a 10% discount on top of a user's 20%
    // discount.
    allow_multiple_discounts: bool,
) {
    suins.assert_app_is_authorized<App>();

    match (intent) {
        PaymentIntent::Registration(base) => {
            base.adjust_discount(discount, allow_multiple_discounts);
        },
        PaymentIntent::Renewal(base) => {
            base.adjust_discount(discount, allow_multiple_discounts);
        },
    }
}

/// Allow an authorized app to finalize a payment.
/// Returns a receipt that can be used to register or renew a domain.
public fun finalize_payment<A: drop, T>(
    intent: PaymentIntent,
    suins: &mut SuiNS,
    app: A,
    // could also be a 0 balance coin if the app offers a free registration.
    coin: Coin<T>,
): Receipt {
    // Ensure the app is authorized to finalize the payment.
    suins.assert_app_is_authorized<A>();
    // add funds to SuiNS balance.
    suins.app_add_custom_balance(app, coin.into_balance());

    match (intent) {
        PaymentIntent::Registration(data) => {
            Receipt::Registration {
                domain: data.domain,
                years: data.years,
                version: data.version,
            }
        },
        PaymentIntent::Renewal(data) => {
            Receipt::Renewal {
                domain: data.domain,
                years: data.years,
                version: data.version,
            }
        },
    }
}

/// Adjusts the amount based on the discount.
fun adjust_discount(
    data: &mut RequestData,
    discount: u8,
    allow_multiple_discounts: bool,
) {
    assert!(
        allow_multiple_discounts || !data.discount_applied,
        ENotMultipleDiscountsAllowed,
    );
    assert!(discount <= 100, EInvalidDiscountPercentage);

    let price = data.base_amount;
    let discount_amount = (((price as u128) * (discount as u128) / 100) as u64);

    data.base_amount = price - discount_amount;
    data.discount_applied = true;
}

/// Creates a `PaymentIntent` for registering a new domain.
/// This is a hot-potato and can only be consumed in a single transaction.
public fun init_registration(suins: &mut SuiNS, domain: String): PaymentIntent {
    let domain = domain::new(domain);
    config::assert_valid_user_registerable_domain(&domain);

    let price = suins
        .get_config<PricingConfig>()
        .calculate_base_price(domain.sld().length());

    PaymentIntent::Registration(RequestData {
        domain,
        years: 1,
        base_amount: price,
        discount_applied: false,
        version: PAYMENT_VERSION,
    })
}

/// Creates a `PaymentIntent` for renewing an existing domain.
/// This is a hot-potato and can only be consumed in a single transaction.
public fun init_renewal(
    suins: &mut SuiNS,
    nft: &SuinsRegistration,
    years: u8,
): PaymentIntent {
    let domain = nft.domain();
    assert!(!domain.is_subdomain(), ECannotRenewSubdomain);

    let price = suins
        .get_config<RenewalConfig>()
        .config()
        .calculate_base_price(domain.sld().length());

    PaymentIntent::Renewal(RequestData {
        domain,
        years,
        base_amount: price * (years as u64),
        discount_applied: false,
        version: PAYMENT_VERSION,
    })
}

/// Register a domain with the given receipt.
/// This is a hot-potato and can only be consumed in a single transaction.
public fun register(
    receipt: Receipt,
    suins: &mut SuiNS,
    clock: &Clock,
    ctx: &mut TxContext,
): SuinsRegistration {
    match (receipt) {
        Receipt::Registration { domain, years, version } => {
            assert!(version == PAYMENT_VERSION, EVersionMismatch);
            suins
                .pkg_registry_mut<Registry>()
                .add_record(domain, years, clock, ctx)
        },
        Receipt::Renewal { domain: _, years: _, version: _ } => {
            abort ENotSupportedType
        },
    }
}

/// Renew a domain with the given receipt.
/// This is a hot-potato and can only be consumed in a single transaction.
public fun renew(
    receipt: Receipt,
    suins: &mut SuiNS,
    nft: &mut SuinsRegistration,
    clock: &Clock,
    _ctx: &mut TxContext,
) {
    match (receipt) {
        Receipt::Renewal { domain, years, version } => {
            assert!(version == PAYMENT_VERSION, EVersionMismatch);
            assert!(nft.domain() == domain, EReceiptDomainMissmatch);
            let registry = suins.pkg_registry_mut<Registry>();
            // Calculate target expiration. Aborts if expiration or selected
            // years are invalid.
            let target_expiration = target_expiration(
                registry,
                domain,
                clock,
                years,
            );

            // set the expiration of the NFT + the registry's name record.
            registry.set_expiration_timestamp_ms(
                nft,
                domain,
                target_expiration,
            );
        },
        Receipt::Registration { domain: _, years: _, version: _ } => {
            abort ENotSupportedType
        },
    }
}

/// Getters
public fun request_data(intent: &PaymentIntent): &RequestData {
    match (intent) {
        PaymentIntent::Registration(data) => data,
        PaymentIntent::Renewal(data) => data,
    }
}

public fun years(self: &RequestData): u8 { self.years }

public fun base_amount(self: &RequestData): u64 { self.base_amount }

public fun domain(self: &RequestData): &Domain { &self.domain }

public fun discount_applied(self: &RequestData): bool { self.discount_applied }

/// Calculate the target expiration for a domain,
/// or abort if the domain or the expiration setup is invalid.
fun target_expiration(
    registry: &Registry,
    domain: Domain,
    clock: &Clock,
    no_years: u8,
): u64 {
    let name_record_option = registry.lookup(domain);
    // validate that the name_record still exists in the registry.
    assert!(name_record_option.is_some(), ERecordNotFound);

    let name_record = name_record_option.destroy_some();

    // Validate that the name has not expired. If it has, we can only
    // re-purchase (and that might involve different pricing).
    assert!(!name_record.has_expired_past_grace_period(clock), ERecordExpired);

    // Calculate the target expiration!
    let target =
        name_record.expiration_timestamp_ms() + (no_years as u64) * constants::year_ms();

    target
}

#[test_only]
public(package) fun test_registration_receipt(
    name: String,
    years: u8,
    version: u8,
): Receipt {
    Receipt::Registration {
        domain: domain::new(name),
        years,
        version,
    }
}

#[test_only]
public(package) fun test_renewal_receipt(
    name: String,
    years: u8,
    version: u8,
): Receipt {
    Receipt::Renewal {
        domain: domain::new(name),
        years,
        version,
    }
}
