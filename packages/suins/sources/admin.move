// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// Admin features of the SuiNS application. Meant to be called directly
/// by the suins admin.
module suins::admin {
    use std::vector;
    use std::string::String;
    use sui::clock::Clock;
    use sui::tx_context::{sender, TxContext};

    use suins::domain;
    use suins::config;
    use suins::suins::{Self, AdminCap, SuiNS};
    use suins::suins_registration::SuinsRegistration;
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
    ): SuinsRegistration {
        let domain = domain::new(domain_name);
        config::assert_valid_user_registerable_domain(&domain);
        let registry = suins::app_registry_mut<Admin, Registry>(Admin {}, suins);
        registry::add_record(registry, domain, no_years, clock, ctx)
    }

    /// Reserve a list of domains.
    entry fun reserve_domains(
        _: &AdminCap,
        suins: &mut SuiNS,
        domains: vector<String>,
        no_years: u8,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let sender = sender(ctx);
        let registry = suins::app_registry_mut<Admin, Registry>(Admin {}, suins);
        while (!vector::is_empty(&domains)) {
            let domain = domain::new(vector::pop_back(&mut domains));
            config::assert_valid_user_registerable_domain(&domain);
            let nft = registry::add_record(registry, domain, no_years, clock, ctx);
            sui::transfer::public_transfer(nft, sender);
        };
    }
}
