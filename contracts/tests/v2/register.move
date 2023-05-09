#[test_only]
module suins::register {
    use std::vector;
    use std::string::{Self, String};
    use sui::coin::{Self, Coin};
    use sui::tx_context::TxContext;
    use sui::clock::Clock;
    use sui::sui::SUI;

    use suins::registry::assert_valid_user_registerable_domain;
    use suins::domain;
    use suins::registry::{Self, Registry};
    use suins::suins::{Self, SuiNS};
    use suins::config::{Self, Config};
    use suins::registration_nft::RegistrationNFT;

    /// Number of years passed is not within [1-5] interval.
    const EInvalidYearsArgument: u64 = 0;
    /// Trying to register a subdomain (only *.sui is currently allowed).
    /// The payment does not match the price for the domain.
    const EIncorrectAmount: u64 = 4;

    /// Authorization token for the app.
    struct Register has drop {}

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
        suins::assert_app_is_authorized<Register>(suins);

        let config = suins::get_config<Config>(suins);

        let domain = domain::new(domain_name);
        assert_valid_user_registerable_domain(&domain);

        assert!(0 < no_years && no_years <= 5, EInvalidYearsArgument);

        let label = vector::borrow(domain::labels(&domain), 0);
        let price = config::calculate_price(config, (string::length(label) as u8), no_years);

        assert!(coin::value(&payment) == price, EIncorrectAmount);

        suins::app_add_balance(Register {}, suins, coin::into_balance(payment));
        let registry = suins::app_registry_mut<Register, Registry>(Register {}, suins);
        registry::add_record(registry, domain, no_years, clock, ctx)
    }
}
