// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

module suins::controller {
    use std::option::Option;
    use std::string::String;
    use sui::tx_context::{sender, TxContext};
    use sui::clock::Clock;
    use sui::vec_map;

    use suins::domain;
    use suins::registry::{Self, Registry};
    use suins::suins::{Self, SuiNS};
    use suins::suins_registration::{Self as nft, SuinsRegistration};
    use std::string;

    const AVATAR: vector<u8> = b"avatar";
    const CONTENT_HASH: vector<u8> = b"content_hash";

    const EUnsupportedKey: u64 = 0;

    /// Authorization token for the controller.
    struct Controller has drop {}

    // === Update Records Functionality ===

    /// User-facing function (upgradable) - set the target address of a domain.
    entry fun set_target_address(
        suins: &mut SuiNS,
        nft: &SuinsRegistration,
        new_target: Option<address>,
        clock: &Clock,
    ) {
        let registry = suins::app_registry_mut<Controller, Registry>(Controller {}, suins);
        registry::assert_nft_is_authorized(registry, nft, clock);

        let domain = nft::domain(nft);
        registry::set_target_address(registry, domain, new_target);
    }

    /// User-facing function (upgradable) - set the reverse lookup address for the domain.
    entry fun set_reverse_lookup(suins: &mut SuiNS, domain_name: String, ctx: &TxContext) {
        let domain = domain::new(domain_name);
        let registry = suins::app_registry_mut<Controller, Registry>(Controller {}, suins);
        registry::set_reverse_lookup(registry, sender(ctx), domain);
    }

    /// User-facing function (upgradable) - unset the reverse lookup address for the domain.
    entry fun unset_reverse_lookup(suins: &mut SuiNS, ctx: &TxContext) {
        let registry = suins::app_registry_mut<Controller, Registry>(Controller {}, suins);
        registry::unset_reverse_lookup(registry, sender(ctx));
    }

    /// User-facing function (upgradable) - add a new key-value pair to the name record's data.
    entry fun set_user_data(
        suins: &mut SuiNS, nft: &SuinsRegistration, key: String, value: String, clock: &Clock
    ) {

        let registry = suins::app_registry_mut<Controller, Registry>(Controller {}, suins);
        let data = *registry::get_data(registry, nft::domain(nft));
        let domain = nft::domain(nft);

        registry::assert_nft_is_authorized(registry, nft, clock);
        let key_bytes = *string::bytes(&key);
        assert!(key_bytes == AVATAR || key_bytes == CONTENT_HASH, EUnsupportedKey);

        if (vec_map::contains(&data, &key)) {
            vec_map::remove(&mut data, &key);
        };

        vec_map::insert(&mut data, key, value);
        registry::set_data(registry, domain, data);
    }

    /// User-facing function (upgradable) - remove a key from the name record's data.
    entry fun unset_user_data(
        suins: &mut SuiNS, nft: &SuinsRegistration, key: String, clock: &Clock
    ) {
        let registry = suins::app_registry_mut<Controller, Registry>(Controller {}, suins);
        let data = *registry::get_data(registry, nft::domain(nft));
        let domain = nft::domain(nft);

        registry::assert_nft_is_authorized(registry, nft, clock);

        if (vec_map::contains(&data, &key)) {
            vec_map::remove(&mut data, &key);
        };

        registry::set_data(registry, domain, data);
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
