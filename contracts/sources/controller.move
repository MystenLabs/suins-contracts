/// Copying controller logic here to see what we can do with it.
/// Stores the main user interaction logic (except for the Auction).
module suins::controller {
    use std::vector;
    use std::string::{Self, String};
    use sui::coin::{Self, Coin};
    use sui::tx_context::TxContext;
    use sui::clock::Clock;
    use sui::sui::SUI;

    use suins::domain;
    use suins::constants;
    use suins::name_record;
    use suins::suins::{Self, SuiNS};
    use suins::config::{Self, Config};
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

    /// Allows direct purchases on domains longer than 5 symbols (6+ symbols).
    ///
    /// Makes sure that:
    /// - the domain is not already registered (or, if active, expired)
    /// - the domain TLD is .sui
    /// - the domain is not a subdomain
    /// - the domain length is higher than 5 symbols
    /// - number of years is within [1-5] interval
    public fun register(
        suins: &mut SuiNS,
        domain_name: String,
        no_years: u8,
        payment: Coin<SUI>,
        clock: &Clock,
        ctx: &mut TxContext
    ): RegistrationNFT {
        let config = suins::get_config<Config>(suins);
        let price = config::calculate_price(config, 6, no_years);
        let domain = domain::new(domain_name);
        let labels = domain::labels(&domain);

        assert!(vector::length(labels) == 2, EInvalidDomain);
        assert!(string::length(vector::borrow(labels, 0)) > 5, EInvalidDomainLength);
        assert!(domain::tld(&domain) == &constants::sui_tld(), EInvalidTld);
        assert!(0 < no_years && no_years <= 5, EInvalidYearsArgument);
        assert!(coin::value(&payment) == price, EIncorrectAmount);

        // if the domain is already registered but expired (!) we can re-register it
        if (suins::has_name_record(suins, domain)) {
            assert!(name_record::has_expired(suins::name_record(suins, domain), clock), ENotExpired);
        };

        suins::app_add_balance(App {}, suins, coin::into_balance(payment));
        suins::app_add_record(App {}, suins, domain, no_years, clock, ctx)
    }
}
