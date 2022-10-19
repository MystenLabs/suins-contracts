#[test_only]
module suins::base_registrar_tests {
    use sui::test_scenario::{Self, Scenario};
    use sui::tx_context;
    use suins::base_registry::{Self, Registry, AdminCap};
    use suins::base_registrar::{Self, BaseRegistrar, RegistrationNFT, TLDsList};
    use std::string;
    use std::vector;
    use suins::ipfs_images::{Self, IpfsImages};
    use sui::vec_map;

    const SUINS_ADDRESS: address = @0xA001;
    const FIRST_USER: address = @0xB001;
    const SECOND_USER: address = @0xB002;
    const FIRST_RESOLVER: address = @0xC001;
    const SECOND_RESOLVER: address = @0xC002;
    const SUB_NODE: vector<u8> = b"eastagile.move";
    const FIRST_LABEL: vector<u8> = b"eastagile";
    const SECOND_LABEL: vector<u8> = b"ea";

    fun init(): Scenario {
        let scenario = test_scenario::begin(&SUINS_ADDRESS);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            base_registry::test_init(ctx);
            base_registrar::test_init(ctx);
            ipfs_images::test_init(ctx);
        };
        scenario
    }

    fun register(scenario: &mut Scenario) {
        test_scenario::next_tx(scenario, &SUINS_ADDRESS);
        {
            let registry_wrapper = test_scenario::take_shared<Registry>(scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);
            let registrar_wrapper = test_scenario::take_last_created_shared<BaseRegistrar>(scenario);
            let registrar = test_scenario::borrow_mut(&mut registrar_wrapper);
            let image_wrapper = test_scenario::take_shared<IpfsImages>(scenario);
            let image = test_scenario::borrow_mut(&mut image_wrapper);

            base_registrar::register(
                registrar,
                registry,
                image,
                FIRST_LABEL,
                FIRST_USER,
                365,
                FIRST_RESOLVER,
                test_scenario::ctx(scenario)
            );
            test_scenario::return_shared(scenario, registry_wrapper);
            test_scenario::return_shared(scenario, image_wrapper);
            test_scenario::return_shared(scenario, registrar_wrapper);
        };

        test_scenario::next_tx(scenario, &FIRST_USER);
        {
            assert!(test_scenario::can_take_owned<RegistrationNFT>(scenario), 0);
            let nft = test_scenario::take_owned<RegistrationNFT>(scenario);
            let (name, _) = base_registrar::get_nft_fields(&nft);
            assert!(name == string::utf8(SUB_NODE), 0);

            test_scenario::return_owned(scenario, nft);
        };
    }

    #[test]
        fun test_register() {
        let scenario = init();

        test_scenario::next_tx(&mut scenario, &FIRST_USER);
        {
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);

            assert!(base_registry::get_records_len(registry) == 3, 0);

            test_scenario::return_shared(&mut scenario, registry_wrapper);
        };

        register(&mut scenario);

        test_scenario::next_tx(&mut scenario, &FIRST_USER);
        {
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);
            assert!(base_registry::get_records_len(registry) == 4, 0);

            // index 0 is .sui
            let (_, record) = base_registry::get_record_at_index(registry, 3);
            assert!(base_registry::get_record_owner(record) == FIRST_USER, 0);
            assert!(base_registry::get_record_resolver(record) == FIRST_RESOLVER, 0);
            assert!(base_registry::get_record_ttl(record) == 0, 0);

            test_scenario::return_shared(&mut scenario, registry_wrapper);
        };

        // test `available` function
        test_scenario::next_tx(&mut scenario, &FIRST_USER);
        {
            let registrar_wrapper = test_scenario::take_last_created_shared<BaseRegistrar>(&mut scenario);
            let registrar = test_scenario::borrow_mut(&mut registrar_wrapper);

            let label = string::utf8(b"eastagile");
            assert!(!base_registrar::available(registrar, label, test_scenario::ctx(&mut scenario)), 0);

            let label = string::utf8(b"ea");
            assert!(base_registrar::available(registrar, label, test_scenario::ctx(&mut scenario)), 0);

            test_scenario::return_shared(&mut scenario, registrar_wrapper);
        };

        // test `name_expires` function
        test_scenario::next_tx(&mut scenario, &FIRST_USER);
        {
            let registrar_wrapper = test_scenario::take_last_created_shared<BaseRegistrar>(&mut scenario);
            let registrar = test_scenario::borrow_mut(&mut registrar_wrapper);

            let label = string::utf8(b"eastagile");
            assert!(base_registrar::name_expires(registrar, label) == 365, 0);

            let label = string::utf8(b"ea");
            assert!(base_registrar::name_expires(registrar, label) == 0, 0);

            test_scenario::return_shared(&mut scenario, registrar_wrapper);
        };
    }

    #[test]
    #[expected_failure(abort_code = 203)]
    fun test_register_abort_with_invalid_utf8_label() {
        let scenario = init();
        test_scenario::next_tx(&mut scenario, &SUINS_ADDRESS);
        {
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);
            let registrar_wrapper = test_scenario::take_last_created_shared<BaseRegistrar>(&mut scenario);
            let registrar = test_scenario::borrow_mut(&mut registrar_wrapper);
            let image_wrapper = test_scenario::take_shared<IpfsImages>(&mut scenario);
            let image = test_scenario::borrow_mut(&mut image_wrapper);
            let invalid_label = vector::empty<u8>();
            // 0xFE cannot appear in a correct UTF-8 string
            vector::push_back(&mut invalid_label, 0xFE);

            base_registrar::register(
                registrar,
                registry,
                image,
                invalid_label,
                FIRST_USER,
                365,
                FIRST_RESOLVER,
                test_scenario::ctx(&mut scenario)
            );

            test_scenario::return_shared(&mut scenario, registry_wrapper);
            test_scenario::return_shared(&mut scenario, registrar_wrapper);
            test_scenario::return_shared(&mut scenario, image_wrapper);
        };
    }

    #[test]
    #[expected_failure(abort_code = 206)]
    fun test_register_abort_with_zero_duration() {
        let scenario = init();
        test_scenario::next_tx(&mut scenario, &SUINS_ADDRESS);
        {
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);
            let registrar_wrapper = test_scenario::take_last_created_shared<BaseRegistrar>(&mut scenario);
            let registrar = test_scenario::borrow_mut(&mut registrar_wrapper);
            let image_wrapper = test_scenario::take_shared<IpfsImages>(&mut scenario);
            let image = test_scenario::borrow_mut(&mut image_wrapper);

            base_registrar::register(
                registrar,
                registry,
                image,
                FIRST_LABEL,
                FIRST_USER,
                0,
                FIRST_RESOLVER,
                test_scenario::ctx(&mut scenario)
            );

            test_scenario::return_shared(&mut scenario, registry_wrapper);
            test_scenario::return_shared(&mut scenario, registrar_wrapper);
            test_scenario::return_shared(&mut scenario, image_wrapper);
        };
    }

    #[test]
    #[expected_failure(abort_code = 206)]
    fun test_register_abort_if_label_unavailable() {
        let scenario = init();
        test_scenario::next_tx(&mut scenario, &SUINS_ADDRESS);
        {
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);
            let registrar_wrapper = test_scenario::take_last_created_shared<BaseRegistrar>(&mut scenario);
            let registrar = test_scenario::borrow_mut(&mut registrar_wrapper);
            let image_wrapper = test_scenario::take_shared<IpfsImages>(&mut scenario);
            let image = test_scenario::borrow_mut(&mut image_wrapper);

            base_registrar::register(
                registrar,
                registry,
                image,
                FIRST_LABEL,
                FIRST_USER,
                0,
                FIRST_RESOLVER,
                test_scenario::ctx(&mut scenario)
            );

            test_scenario::return_shared(&mut scenario, registry_wrapper);
            test_scenario::return_shared(&mut scenario, registrar_wrapper);
            test_scenario::return_shared(&mut scenario, image_wrapper);
        };

        test_scenario::next_tx(&mut scenario, &SUINS_ADDRESS);
        {
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);
            let registrar_wrapper = test_scenario::take_last_created_shared<BaseRegistrar>(&mut scenario);
            let registrar = test_scenario::borrow_mut(&mut registrar_wrapper);
            let image_wrapper = test_scenario::take_shared<IpfsImages>(&mut scenario);
            let image = test_scenario::borrow_mut(&mut image_wrapper);

            base_registrar::register(
                registrar,
                registry,
                image,
                FIRST_LABEL,
                FIRST_USER,
                0,
                FIRST_RESOLVER,
                test_scenario::ctx(&mut scenario)
            );

            test_scenario::return_shared(&mut scenario, registry_wrapper);
            test_scenario::return_shared(&mut scenario, image_wrapper);
            test_scenario::return_shared(&mut scenario, registrar_wrapper);
        };
    }

    #[test]
    fun test_renew() {
        let scenario = init();
        register(&mut scenario);
        test_scenario::next_tx(&mut scenario, &FIRST_USER);
        {
            let registrar_wrapper = test_scenario::take_last_created_shared<BaseRegistrar>(&mut scenario);
            let registrar = test_scenario::borrow_mut(&mut registrar_wrapper);

            assert!(base_registrar::name_expires(registrar, string::utf8(FIRST_LABEL)) == 365, 0);
            base_registrar::renew(registrar, FIRST_LABEL, 100, test_scenario::ctx(&mut scenario));
            assert!(base_registrar::name_expires(registrar, string::utf8(FIRST_LABEL)) == 465, 0);

            test_scenario::return_shared(&mut scenario, registrar_wrapper);
        };
    }

    #[test]
    #[expected_failure(abort_code = 207)]
    fun test_renew_abort_if_label_not_exists() {
        let scenario = init();
        register(&mut scenario);
        test_scenario::next_tx(&mut scenario, &FIRST_USER);
        {
            let registrar_wrapper = test_scenario::take_last_created_shared<BaseRegistrar>(&mut scenario);
            let registrar = test_scenario::borrow_mut(&mut registrar_wrapper);
            assert!(base_registrar::name_expires(registrar, string::utf8(SECOND_LABEL)) == 0, 0);
            base_registrar::renew(registrar, SECOND_LABEL, 100, test_scenario::ctx(&mut scenario));
            test_scenario::return_shared(&mut scenario, registrar_wrapper);
        };
    }

    #[test]
    #[expected_failure(abort_code = 205)]
    fun test_renew_abort_if_label_expired() {
        let scenario = init();
        register(&mut scenario);
        test_scenario::next_tx(&mut scenario, &FIRST_USER);
        {
            let registrar_wrapper = test_scenario::take_last_created_shared<BaseRegistrar>(&mut scenario);
            let registrar = test_scenario::borrow_mut(&mut registrar_wrapper);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                500,
                0
            );

            assert!(base_registrar::name_expires(registrar, string::utf8(FIRST_LABEL)) == 365, 0);
            base_registrar::renew(registrar, FIRST_LABEL, 100, &ctx);

            test_scenario::return_shared(&mut scenario, registrar_wrapper);
        };
    }

    #[test]
    fun test_reclaim() {
        let scenario = init();
        register(&mut scenario);

        test_scenario::next_tx(&mut scenario, &SUINS_ADDRESS);
        {
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);

            let owner = base_registry::owner(registry, SUB_NODE);
            assert!(FIRST_USER == owner, 0);

            test_scenario::return_shared(&mut scenario, registry_wrapper);
        };

        test_scenario::next_tx(&mut scenario, &FIRST_USER);
        {
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);
            let registrar_wrapper = test_scenario::take_last_created_shared<BaseRegistrar>(&mut scenario);
            let registrar = test_scenario::borrow_mut(&mut registrar_wrapper);

            base_registrar::reclaim(registrar, registry, FIRST_LABEL, SECOND_USER, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(&mut scenario, registry_wrapper);
            test_scenario::return_shared(&mut scenario, registrar_wrapper);
        };

        test_scenario::next_tx(&mut scenario, &SUINS_ADDRESS);
        {
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);

            let owner = base_registry::owner(registry, SUB_NODE);
            assert!(SECOND_USER == owner, 0);

            test_scenario::return_shared(&mut scenario, registry_wrapper);
        };

        test_scenario::next_tx(&mut scenario, &FIRST_USER);
        {
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);
            let registrar_wrapper = test_scenario::take_last_created_shared<BaseRegistrar>(&mut scenario);
            let registrar = test_scenario::borrow_mut(&mut registrar_wrapper);

            base_registrar::reclaim(registrar, registry, FIRST_LABEL, FIRST_USER, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(&mut scenario, registry_wrapper);
            test_scenario::return_shared(&mut scenario, registrar_wrapper);
        };

        test_scenario::next_tx(&mut scenario, &SUINS_ADDRESS);
        {
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);

            let owner = base_registry::owner(registry, SUB_NODE);
            assert!(FIRST_USER == owner, 0);

            test_scenario::return_shared(&mut scenario, registry_wrapper);
        };
    }

    #[test]
    #[expected_failure(abort_code = 205)]
    fun test_reclaim_abort_caller_is_label_expired() {
        let scenario = init();
        register(&mut scenario);

        test_scenario::next_tx(&mut scenario, &FIRST_USER);
        {
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);
            let registrar_wrapper = test_scenario::take_last_created_shared<BaseRegistrar>(&mut scenario);
            let registrar = test_scenario::borrow_mut(&mut registrar_wrapper);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                500,
                0
            );

            base_registrar::reclaim(registrar, registry, FIRST_LABEL, SECOND_USER, &mut ctx);

            test_scenario::return_shared(&mut scenario, registry_wrapper);
            test_scenario::return_shared(&mut scenario, registrar_wrapper);
        };
    }

    #[test]
    #[expected_failure(abort_code = 207)]
    fun test_reclaim_abort_caller_is_label_not_exists() {
        let scenario = init();
        register(&mut scenario);

        test_scenario::next_tx(&mut scenario, &FIRST_USER);
        {
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);
            let registrar_wrapper = test_scenario::take_last_created_shared<BaseRegistrar>(&mut scenario);
            let registrar = test_scenario::borrow_mut(&mut registrar_wrapper);

            base_registrar::reclaim(registrar, registry, SECOND_LABEL, SECOND_USER, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(&mut scenario, registry_wrapper);
            test_scenario::return_shared(&mut scenario, registrar_wrapper);
        };
    }

    #[test]
    fun test_reclaim_by_nft_owner() {
        let scenario = init();
        register(&mut scenario);

        test_scenario::next_tx(&mut scenario, &FIRST_USER);
        {
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);
            let nft = test_scenario::take_owned<RegistrationNFT>(&mut scenario);
            base_registrar::reclaim_by_nft_owner(registry, &nft, SECOND_USER);

            test_scenario::return_owned(&mut scenario, nft);
            test_scenario::return_shared(&mut scenario, registry_wrapper);
        };

        test_scenario::next_tx(&mut scenario, &SUINS_ADDRESS);
        {
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);

            let owner = base_registry::owner(registry, SUB_NODE);
            assert!(SECOND_USER == owner, 0);

            test_scenario::return_shared(&mut scenario, registry_wrapper);
        };
    }

    #[test]
    fun test_new_tld() {
        let scenario = init();

        test_scenario::next_tx(&mut scenario, &SUINS_ADDRESS);
        {
            let tlds_list_wrapper = test_scenario::take_shared<TLDsList>(&mut scenario);
            let tlds_list = test_scenario::borrow_mut(&mut tlds_list_wrapper);

            let tlds = base_registrar::get_tlds(tlds_list);
            assert!(vector::length(tlds) == 2, 0);

            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);

            assert!(base_registry::get_records_len(registry) == 3, 0);

            test_scenario::return_shared(&mut scenario, tlds_list_wrapper);
            test_scenario::return_shared(&mut scenario, registry_wrapper);
        };

        test_scenario::next_tx(&mut scenario, &SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_owned<AdminCap>(&mut scenario);
            let tlds_list_wrapper = test_scenario::take_shared<TLDsList>(&mut scenario);
            let tlds_list = test_scenario::borrow_mut(&mut tlds_list_wrapper);
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);

            base_registrar::new_tld(
                &admin_cap,
                tlds_list,
                registry,
                b"com",
                test_scenario::ctx(&mut scenario)
            );

            test_scenario::return_owned(&mut scenario, admin_cap);
            test_scenario::return_shared(&mut scenario, tlds_list_wrapper);
            test_scenario::return_shared(&mut scenario, registry_wrapper);
        };

        test_scenario::next_tx(&mut scenario, &SUINS_ADDRESS);
        {
            let tlds_list_wrapper = test_scenario::take_shared<TLDsList>(&mut scenario);
            let tlds_list = test_scenario::borrow_mut(&mut tlds_list_wrapper);

            let tlds = base_registrar::get_tlds(tlds_list);
            assert!(vector::length(tlds) == 3, 0);
            assert!(vector::borrow(tlds, 2) == &string::utf8(b"com"), 0);

            let com_registrar_wrapper = test_scenario::take_last_created_shared<BaseRegistrar>(&mut scenario);
            let com_registrar = test_scenario::borrow_mut(&mut com_registrar_wrapper);

            let (base_node, base_node_bytes, expiries) = base_registrar::get_registrar(com_registrar);
            assert!(base_node == &string::utf8(b"com"), 0);
            assert!(base_node_bytes == &b"com", 0);
            assert!(vec_map::size(expiries) == 0, 0);

            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);

            assert!(base_registry::get_records_len(registry) == 4, 0);
            let (node, record) = base_registry::get_record_at_index(registry, 3);
            assert!(node == &string::utf8(b"com"), 0);
            assert!(base_registry::get_record_owner(record) == SUINS_ADDRESS, 0);
            assert!(base_registry::get_record_ttl(record) == 0x100000, 0);
            assert!(base_registry::get_record_resolver(record) == @0x0, 0);

            test_scenario::return_shared(&mut scenario, tlds_list_wrapper);
            test_scenario::return_shared(&mut scenario, com_registrar_wrapper);
            test_scenario::return_shared(&mut scenario, registry_wrapper);
        };

        test_scenario::next_tx(&mut scenario, &FIRST_USER);
        {
            let registry_wrapper =
                test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);
            let com_registrar_wrapper =
                test_scenario::take_last_created_shared<BaseRegistrar>(&mut scenario);
            let com_registrar = test_scenario::borrow_mut(&mut com_registrar_wrapper);
            let image_wrapper = test_scenario::take_shared<IpfsImages>(&mut scenario);
            let image = test_scenario::borrow_mut(&mut image_wrapper);

            base_registrar::register(
                com_registrar,
                registry,
                image,
                FIRST_LABEL,
                FIRST_USER,
                365,
                FIRST_RESOLVER,
                test_scenario::ctx(&mut scenario)
            );
            test_scenario::return_shared(&mut scenario, registry_wrapper);
            test_scenario::return_shared(&mut scenario, image_wrapper);
            test_scenario::return_shared(&mut scenario, com_registrar_wrapper);
        };

        test_scenario::next_tx(&mut scenario, &SUINS_ADDRESS);
        {
            let com_registrar_wrapper = test_scenario::take_last_created_shared<BaseRegistrar>(&mut scenario);
            let com_registrar = test_scenario::borrow_mut(&mut com_registrar_wrapper);

            let (_, _, expiries) = base_registrar::get_registrar(com_registrar);
            assert!(vec_map::size(expiries) == 1, 0);
            let (key, value) = vec_map::get_entry_by_idx(expiries, 0);
            assert!(key == &string::utf8(FIRST_LABEL), 0);

            let (owner, expiry) = base_registrar::get_registration_detail(value);
            assert!(owner == &FIRST_USER, 0);
            assert!(expiry == &365, 0);

            test_scenario::return_shared(&mut scenario, com_registrar_wrapper);
        };
    }

    #[test]
    #[expected_failure(abort_code = 208)]
    fun test_new_tld_abort_with_duplicated_tld() {
        let scenario = init();

        test_scenario::next_tx(&mut scenario, &SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_owned<AdminCap>(&mut scenario);
            let tlds_list_wrapper = test_scenario::take_shared<TLDsList>(&mut scenario);
            let tlds_list = test_scenario::borrow_mut(&mut tlds_list_wrapper);
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);

            base_registrar::new_tld(
                &admin_cap,
                tlds_list,
                registry,
                b"move",
                test_scenario::ctx(&mut scenario)
            );

            test_scenario::return_owned(&mut scenario, admin_cap);
            test_scenario::return_shared(&mut scenario, tlds_list_wrapper);
            test_scenario::return_shared(&mut scenario, registry_wrapper);
        };
    }
}
