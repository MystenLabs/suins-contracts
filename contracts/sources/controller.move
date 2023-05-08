module suins::controller {
    use std::vector;
    use std::option::Option;
    use std::string;
    use sui::tx_context::{sender, TxContext};
    use sui::clock::Clock;

    use suins::domain;
    use suins::constants;
    use suins::registry::{Self, Registry};
    use suins::suins::{Self, SuiNS};
    use suins::domain::Domain;
    use suins::registration_nft::{Self as nft, RegistrationNFT};

    /// Trying to register a subdomain (only *.sui is currently allowed).
    const EInvalidDomain: u64 = 1;
    /// Trying to register a domain name in a different TLD (not .sui).
    const EInvalidTld: u64 = 2;
    /// Trying to register domain name that is shorter than 6 symbols.
    const EInvalidDomainLength: u64 = 3;

    /// Authorization token for the app.
    struct App has drop {}

    // === Update Records Functionality ===

    public fun set_target_address(
        suins: &mut SuiNS,
        nft: &RegistrationNFT,
        new_target: Option<address>,
        clock: &Clock,
    ) {
        suins::assert_app_is_authorized<App>(suins);

        let registry = suins::app_registry_mut<App, Registry>(App {}, suins);
        registry::assert_nft_is_authorized(registry, nft, clock);

        let domain = nft::domain(nft);
        registry::set_target_address(registry, domain, new_target);
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
