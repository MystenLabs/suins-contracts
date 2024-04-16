// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

module suins::controller {
    use std::string::String;
    use sui::{tx_context::{sender}, clock::Clock};

    use suins::{domain, registry::Registry, suins::{Self, SuiNS}, suins_registration::SuinsRegistration};

    const AVATAR: vector<u8> = b"avatar";
    const CONTENT_HASH: vector<u8> = b"content_hash";

    const EUnsupportedKey: u64 = 0;

    /// Authorization token for the controller.
    public struct Controller has drop {}

    // === Update Records Functionality ===

    /// User-facing function (upgradable) - set the target address of a domain.
    entry fun set_target_address(
        suins: &mut SuiNS,
        nft: &SuinsRegistration,
        new_target: Option<address>,
        clock: &Clock,
    ) {
        let registry = suins::app_registry_mut<Controller, Registry>(Controller {}, suins);
        registry.assert_nft_is_authorized(nft, clock);

        let domain = nft.domain();
        registry.set_target_address(domain, new_target);
    }

    /// User-facing function (upgradable) - set the reverse lookup address for the domain.
    entry fun set_reverse_lookup(suins: &mut SuiNS, domain_name: String, ctx: &TxContext) {
        let domain = domain::new(domain_name);
        let registry = suins::app_registry_mut<Controller, Registry>(Controller {}, suins);
        registry.set_reverse_lookup(sender(ctx), domain);
    }

    /// User-facing function (upgradable) - unset the reverse lookup address for the domain.
    entry fun unset_reverse_lookup(suins: &mut SuiNS, ctx: &TxContext) {
        let registry = suins::app_registry_mut<Controller, Registry>(Controller {}, suins);
        registry.unset_reverse_lookup(sender(ctx));
    }

    /// User-facing function (upgradable) - add a new key-value pair to the name record's data.
    entry fun set_user_data(
        suins: &mut SuiNS, nft: &SuinsRegistration, key: String, value: String, clock: &Clock
    ) {

        let registry = suins::app_registry_mut<Controller, Registry>(Controller {}, suins);
        let mut data = *registry.get_data(nft.domain());
        let domain = nft.domain();

        registry.assert_nft_is_authorized(nft, clock);
        let key_bytes = *key.bytes();
        assert!(key_bytes == AVATAR || key_bytes == CONTENT_HASH, EUnsupportedKey);

        if (data.contains(&key)) {
            data.remove(&key);
        };

        data.insert(key, value);
        registry.set_data(domain, data);
    }

    /// User-facing function (upgradable) - remove a key from the name record's data.
    entry fun unset_user_data(
        suins: &mut SuiNS, nft: &SuinsRegistration, key: String, clock: &Clock
    ) {
        let registry = suins::app_registry_mut<Controller, Registry>(Controller {}, suins);
        let mut data = *registry.get_data(nft.domain());
        let domain = nft.domain();

        registry.assert_nft_is_authorized(nft, clock);

        if (data.contains(&key)) {
            data.remove(&key);
        };

        registry.set_data(domain, data);
    }

    // === Testing ===

    #[test_only]
    public fun set_target_address_for_testing(
        suins: &mut SuiNS, nft: &SuinsRegistration, new_target: Option<address>, clock: &Clock
    ) {
        set_target_address(suins, nft, new_target, clock)
    }

    #[test_only]
    public fun set_reverse_lookup_for_testing(
        suins: &mut SuiNS, domain_name: String, ctx: &TxContext
    ) {
        set_reverse_lookup(suins, domain_name, ctx)
    }

    #[test_only]
    public fun unset_reverse_lookup_for_testing(suins: &mut SuiNS, ctx: &TxContext) {
        unset_reverse_lookup(suins, ctx)
    }

    #[test_only]
    public fun set_user_data_for_testing(
        suins: &mut SuiNS, nft: &SuinsRegistration, key: String, value: String, clock: &Clock
    ) {
        set_user_data(suins, nft, key, value, clock);
    }

    #[test_only]
    public fun unset_user_data_for_testing(
        suins: &mut SuiNS, nft: &SuinsRegistration, key: String, clock: &Clock
    ) {
        unset_user_data(suins, nft, key, clock);
    }
}
