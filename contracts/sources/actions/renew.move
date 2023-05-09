module suins::renew {
    use std::vector;
    use std::option;
    use std::string;
    use sui::coin::{Self, Coin};
    use sui::clock::{timestamp_ms, Clock};
    use sui::sui::SUI;
    use sui::object;

    use suins::controller::assert_valid_user_registerable_domain;
    use suins::domain;
    use suins::constants;
    use suins::name_record;
    use suins::registry::{Self, Registry};
    use suins::suins::{Self, SuiNS};
    use suins::config::{Self, Config};
    use suins::registration_nft::{Self as nft, RegistrationNFT};

    /// Number of years passed is not within [1-5] interval.
    const EInvalidYearsArgument: u64 = 0;
    /// Trying to register a subdomain (only *.sui is currently allowed).
    /// The payment does not match the price for the domain.
    const EIncorrectAmount: u64 = 4;

    const EInvalidNewExpiredAt: u64 = 10;

    /// Authorization token for the app.
    struct App has drop {}

    /// Renew a registered domain name by a number of years (not exceeding 5).
    /// The domain name must be already registered and active; `RegistrationNFT`
    /// serves as the proof of that.
    ///
    /// We make sure that (in order):
    /// - the domain is already registered and active
    /// - the RegistrationNFT matches the NameRecord.nft_id
    /// - the domain TLD is .sui
    /// - the domain is not a subdomain
    /// - number of years is within [1-5] interval
    /// - the new expiration does not exceed 5 years from now
    /// - the payment matches the price for the domain
    public fun renew(
        suins: &mut SuiNS,
        nft: &mut RegistrationNFT,
        no_years: u8,
        payment: Coin<SUI>,
        clock: &Clock,
    ) {
        suins::assert_app_is_authorized<App>(suins);

        let domain = nft::domain(nft);
        let registry = suins::registry<Registry>(suins);

        // Lookup the existing record and verify ownership and expiration including grace period
        let record = option::destroy_some(registry::lookup(registry, domain));
        assert!(object::id(nft) == name_record::nft_id(&record), 0);
        assert!(!name_record::has_expired_past_grace_period(&record, clock), 0);
        assert!(!nft::has_expired_past_grace_period(nft, clock), 0);

        assert_valid_user_registerable_domain(&domain);

        let config = suins::get_config<Config>(suins);
        assert!(0 < no_years && no_years <= 5, EInvalidYearsArgument);
        let label = vector::borrow(domain::labels(&domain), 0);
        let price = config::calculate_price(config, (string::length(label) as u8), no_years);
        assert!(coin::value(&payment) == price, EIncorrectAmount);

        let expiration_timestamp_ms = name_record::expiration_timestamp_ms(&record);
        let new_expiration_timestamp_ms = expiration_timestamp_ms + ((no_years as u64) * constants::year_ms());
        // Ensure that the new expiration timestamp is less than 5 years from now
        assert!(new_expiration_timestamp_ms - timestamp_ms(clock) <= 5 * constants::year_ms(), EInvalidNewExpiredAt);

        let registry = suins::app_registry_mut<App, Registry>(App {}, suins);
        registry::set_expiration_timestamp_ms(registry, nft, domain, new_expiration_timestamp_ms);

        suins::app_add_balance(App {}, suins, coin::into_balance(payment));
    }
}