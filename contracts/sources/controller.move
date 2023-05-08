/// Copying controller logic here to see what we can do with it.
/// Stores the main user interaction logic (except for the Auction).
module suins::controller {
    use std::vector;
    use std::option::Option;
    use std::string::{Self, String};
    use sui::coin::{Self, Coin};
    use sui::tx_context::{sender, TxContext};
    use sui::clock::Clock;
    use sui::sui::SUI;

    use suins::domain;
    use suins::constants;
    use suins::registry::{Self, Registry};
    use suins::suins::{Self, SuiNS};
    use suins::config::{Self, Config};
    use suins::domain::Domain;
    use suins::registration_nft::RegistrationNFT;

    /// Number of years passed is not within [1-5] interval.
    const EInvalidYearsArgument: u64 = 0;
    /// Trying to register a subdomain (only *.sui is currently allowed).
    const EInvalidDomain: u64 = 1;
    /// Trying to register a domain name in a different TLD (not .sui).
    const EInvalidTld: u64 = 2;
    /// Trying to register domain name that is shorter than 6 symbols.
    const EInvalidDomainLength: u64 = 3;
    /// The payment does not match the price for the domain.
    const EIncorrectAmount: u64 = 4;
    /// Trying to purchase a domain that is already registered and active.
    const ENotExpired: u64 = 5;

    /// Authorization token for the app.
    struct App has drop {}

    // Allows direct purchases of domains
    //
    // Makes sure that:
    // - the domain is not already registered (or, if active, expired)
    // - the domain TLD is .sui
    // - the domain is not a subdomain
    // - number of years is within [1-5] interval
    public fun register(
        suins: &mut SuiNS,
        domain_name: String,
        no_years: u8,
        payment: Coin<SUI>,
        clock: &Clock,
        ctx: &mut TxContext
    ): RegistrationNFT {
        suins::assert_app_is_authorized<App>(suins);

        let config = suins::get_config<Config>(suins);
        assert!(config::is_user_registration_enabled(config), 0);

        let domain = domain::new(domain_name);
        assert_valid_user_registerable_domain(&domain);

        assert!(0 < no_years && no_years <= 5, EInvalidYearsArgument);

        let label = vector::borrow(domain::labels(&domain), 0);
        let price = config::calculate_price(config, (string::length(label) as u8), no_years);

        assert!(coin::value(&payment) == price, EIncorrectAmount);

        suins::app_add_balance(App {}, suins, coin::into_balance(payment));
        let registry = suins::app_registry_mut<App, Registry>(App {}, suins);
        registry::add_record(registry, domain, no_years, clock, ctx)
    }

    // === Update Records Functionality ===

    public fun set_target_address(
        suins: &mut SuiNS,
        nft: &RegistrationNFT,
        new_target: Option<address>,
        clock: &Clock,
    ) {
        suins::assert_app_is_authorized<App>(suins);

        let registry = suins::app_registry_mut<App, Registry>(App {}, suins);
        registry::set_target_address(registry, nft, new_target, clock);
    }

    public fun set_reverse_lookup(
        suins: &mut SuiNS,
        domain: Option<Domain>,
        ctx: &TxContext,
    ) {
        suins::assert_app_is_authorized<App>(suins);

        let registry = suins::app_registry_mut<App, Registry>(App {}, suins);
        let sender = sender(ctx);
        registry::set_reverse_lookup(registry, sender, domain);
    }

    /// === Helpers ===

    /// Asserts that a domain is registerable by a user:
    /// - TLD is "sui"
    /// - only has 1 label, "name", other than the TLD
    /// - "name" is >= 3 characters long
    public fun assert_valid_user_registerable_domain(domain: &Domain) {
        assert!(domain::tld(domain) == &constants::sui_tld(), EInvalidTld);
        let labels = domain::labels(domain);
        assert!(vector::length(labels) == 2, EInvalidDomain);
        assert!(string::length(vector::borrow(labels, 0)) >= 3, EInvalidDomainLength);
    }
}
