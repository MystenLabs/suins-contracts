// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// Admin features of the SuiNS application. Meant to be called directly
/// by the suins admin.
module suins::admin {
    use std::string::String;
    use sui::{clock::Clock, tx_context::{sender}};

    use suins::{domain, config, suins::{Self, AdminCap, SuiNS}, suins_registration::SuinsRegistration, registry::Registry};

    /// The authorization witness.
    public struct Admin has drop {}

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
        registry.add_record(domain, no_years, clock, ctx)
    }

    /// Reserve a list of domains.
    entry fun reserve_domains(
        _: &AdminCap,
        suins: &mut SuiNS,
        mut domains: vector<String>,
        no_years: u8,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let sender = sender(ctx);
        let registry = suins::app_registry_mut<Admin, Registry>(Admin {}, suins);
        while (!domains.is_empty()) {
            let domain = domain::new(domains.pop_back());
            config::assert_valid_user_registerable_domain(&domain);
            let nft = registry.add_record(domain, no_years, clock, ctx);
            sui::transfer::public_transfer(nft, sender);
        };
    }
}
