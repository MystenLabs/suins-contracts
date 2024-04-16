// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// A simple package to allows us set a target address &  default name in a single PTB in frontend.
/// Unblocks better UX in the registration flow | easier adoption for non-technical users.
module utils::direct_setup {
    use std::string::{String};

    use sui::{tx_context::{sender}, clock::Clock};

    use suins::{domain, registry::Registry, suins::{Self, SuiNS}, suins_registration::SuinsRegistration};

    /// Authorization token for the controller.
    public struct DirectSetup has drop {}

    /// Set the target address of a domain.
    public fun set_target_address(
        suins: &mut SuiNS,
        nft: &SuinsRegistration,
        new_target: address,
        clock: &Clock,
    ) {
        let registry = suins::app_registry_mut<DirectSetup, Registry>(DirectSetup {}, suins);
        registry.assert_nft_is_authorized(nft, clock);

        let domain = nft.domain();
        registry.set_target_address(domain, option::some(new_target));
    }

    /// Set the reverse lookup address for the domain
    public fun set_reverse_lookup(suins: &mut SuiNS, domain_name: String, ctx: &TxContext) {
        let domain = domain::new(domain_name);
        let registry = suins::app_registry_mut<DirectSetup, Registry>(DirectSetup {}, suins);
        registry.set_reverse_lookup(sender(ctx), domain);
    }
}
