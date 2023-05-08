/// Admin features of the SuiNS application. Meant to be called directly
/// by the suins admin.
module suins::admin {
    use std::string::String;
    use sui::clock::Clock;
    use sui::tx_context::TxContext;

    use suins::domain;
    use suins::suins::{Self, AdminCap, SuiNS};
    use suins::registration_nft::RegistrationNFT;
    use suins::registry::{Self, Registry};

    /// The authorization witness.
    struct Admin has drop {}

    /// Authorize the admin application in the SuiNS to get access
    /// to protected functions. Must be called in order to use the rest
    /// of the functions.
    public fun authorize(cap: &AdminCap, suins: &mut SuiNS) {
        suins::authorize_app<Admin>(cap, suins)
    }

    /// Reserve a `domain` in the `SuiNS`.
    public fun reserve_domain(
        _: &AdminCap,
        suins: &mut SuiNS,
        domain_name: String,
        no_years: u8,
        clock: &Clock,
        ctx: &mut TxContext
    ): RegistrationNFT {
        let registry = suins::app_registry_mut<Admin, Registry>(Admin {}, suins);
        registry::add_record(
            registry, domain::new(domain_name), no_years, clock, ctx
        )
    }
}
