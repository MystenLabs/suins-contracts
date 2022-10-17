#[test_only]
module suins::sui_registrar_tests {
    use sui::test_scenario::{Self, Scenario};
    use sui::tx_context;
    use sui::url;
    use suins::base_registry::{Self, Registry};
    use suins::sui_registrar::{Self, SuiRegistrar, RegistrationNFT};
    use std::string;
    use std::vector;

    const SUINS_ADDRESS: address = @0xA001;
    const FIRST_USER: address = @0xB001;
    const SECOND_USER: address = @0xB002;
    const FIRST_RESOLVER: address = @0xC001;
    const SECOND_RESOLVER: address = @0xC002;
    const BASE_NODE: vector<u8> = b"sui";
    const SUB_NODE: vector<u8> = b"eastagile.sui";
    const FIRST_LABEL: vector<u8> = b"eastagile";
    const SECOND_LABEL: vector<u8> = b"ea";
    const DEFAULT_URL: vector<u8> = b"ipfs://bafkreibngqhl3gaa7daob4i2vccziay2jjlp435cf66vhono7nrvww53ty";

    fun init(): Scenario {
        let scenario = test_scenario::begin(&SUINS_ADDRESS);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            base_registry::test_init(ctx);
            sui_registrar::test_init(ctx);
        };
        scenario
    }

    fun register(scenario: &mut Scenario) {
        test_scenario::next_tx(scenario, &SUINS_ADDRESS);
        {
            let registry_wrapper = test_scenario::take_shared<Registry>(scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);

            let registrar_wrapper = test_scenario::take_shared<SuiRegistrar>(scenario);
            let registrar = test_scenario::borrow_mut(&mut registrar_wrapper);


            sui_registrar::register(
                registrar,
                registry,
                FIRST_LABEL,
                FIRST_USER,
                365,
                FIRST_RESOLVER,
                url::new_unsafe_from_bytes(DEFAULT_URL),
                test_scenario::ctx(scenario)
            );
            test_scenario::return_shared(scenario, registry_wrapper);
            test_scenario::return_shared(scenario, registrar_wrapper);
        };

        test_scenario::next_tx(scenario, &FIRST_USER);
        {
            assert!(test_scenario::can_take_owned<RegistrationNFT>(scenario), 0);
            let nft = test_scenario::take_owned<RegistrationNFT>(scenario);
            let (name, url) = sui_registrar::get_nft_fields(&nft);
            assert!(name == string::utf8(SUB_NODE), 0);
            assert!(url == url::new_unsafe_from_bytes(DEFAULT_URL), 0);

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

            assert!(base_registry::get_records_len(registry) == 2, 0);

            test_scenario::return_shared(&mut scenario, registry_wrapper);
        };

        register(&mut scenario);

        test_scenario::next_tx(&mut scenario, &FIRST_USER);
        {
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);
            assert!(base_registry::get_records_len(registry) == 3, 0);

            // index 0 is .sui
            let (_, record) = base_registry::get_record_at_index(registry, 2);
            assert!(base_registry::get_record_owner(record) == FIRST_USER, 0);
            assert!(base_registry::get_record_resolver(record) == FIRST_RESOLVER, 0);
            assert!(base_registry::get_record_ttl(record) == 0, 0);

            test_scenario::return_shared(&mut scenario, registry_wrapper);
        };

        // test `available` function
        test_scenario::next_tx(&mut scenario, &FIRST_USER);
        {
            let registrar_wrapper = test_scenario::take_shared<SuiRegistrar>(&mut scenario);
            let registrar = test_scenario::borrow_mut(&mut registrar_wrapper);

            let subnode = string::utf8(b"eastagile");
            assert!(!sui_registrar::available(registrar, subnode, test_scenario::ctx(&mut scenario)), 0);

            let subnode = string::utf8(b"ea");
            assert!(sui_registrar::available(registrar, subnode, test_scenario::ctx(&mut scenario)), 0);

            test_scenario::return_shared(&mut scenario, registrar_wrapper);
        };

        // test `name_expires` function
        test_scenario::next_tx(&mut scenario, &FIRST_USER);
        {
            let registrar_wrapper = test_scenario::take_shared<SuiRegistrar>(&mut scenario);
            let registrar = test_scenario::borrow_mut(&mut registrar_wrapper);

            let subnode = string::utf8(b"eastagile");
            assert!(sui_registrar::name_expires(registrar, subnode) == 365, 0);

            let subnode = string::utf8(b"ea");
            assert!(sui_registrar::name_expires(registrar, subnode) == 0, 0);

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
            let registrar_wrapper = test_scenario::take_shared<SuiRegistrar>(&mut scenario);
            let registrar = test_scenario::borrow_mut(&mut registrar_wrapper);
            let invalid_label = vector::empty<u8>();
            // 0xFE cannot appear in a correct UTF-8 string
            vector::push_back(&mut invalid_label, 0xFE);

            sui_registrar::register(
                registrar,
                registry,
                invalid_label,
                FIRST_USER,
                365,
                FIRST_RESOLVER,
                url::new_unsafe_from_bytes(DEFAULT_URL),
                test_scenario::ctx(&mut scenario)
            );

            test_scenario::return_shared(&mut scenario, registry_wrapper);
            test_scenario::return_shared(&mut scenario, registrar_wrapper);
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
            let registrar_wrapper = test_scenario::take_shared<SuiRegistrar>(&mut scenario);
            let registrar = test_scenario::borrow_mut(&mut registrar_wrapper);

            sui_registrar::register(
                registrar,
                registry,
                FIRST_LABEL,
                FIRST_USER,
                0,
                FIRST_RESOLVER,
                url::new_unsafe_from_bytes(DEFAULT_URL),
                test_scenario::ctx(&mut scenario)
            );

            test_scenario::return_shared(&mut scenario, registry_wrapper);
            test_scenario::return_shared(&mut scenario, registrar_wrapper);
        };
    }

    #[test]
    fun test_register_only() {
        let scenario = init();

        test_scenario::next_tx(&mut scenario, &FIRST_USER);
        {
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);

            assert!(base_registry::get_records_len(registry) == 2, 0);

            test_scenario::return_shared(&mut scenario, registry_wrapper);
        };

        test_scenario::next_tx(&mut scenario, &SUINS_ADDRESS);
        {
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);

            let registrar_wrapper = test_scenario::take_shared<SuiRegistrar>(&mut scenario);
            let registrar = test_scenario::borrow_mut(&mut registrar_wrapper);

            sui_registrar::register_only(
                registrar,
                registry,
                b"eastagile",
                FIRST_USER,
                365,
                FIRST_RESOLVER,
                url::new_unsafe_from_bytes(DEFAULT_URL),
                test_scenario::ctx(&mut scenario)
            );
            test_scenario::return_shared(&mut scenario, registry_wrapper);
            test_scenario::return_shared(&mut scenario, registrar_wrapper);
        };

        test_scenario::next_tx(&mut scenario, &FIRST_USER);
        {
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);

            assert!(base_registry::get_records_len(registry) == 2, 0);

            test_scenario::return_shared(&mut scenario, registry_wrapper);
        };

        // test `available` function
        test_scenario::next_tx(&mut scenario, &FIRST_USER);
        {
            let registrar_wrapper = test_scenario::take_shared<SuiRegistrar>(&mut scenario);
            let registrar = test_scenario::borrow_mut(&mut registrar_wrapper);

            let subnode = string::utf8(b"eastagile");
            assert!(!sui_registrar::available(registrar, subnode, test_scenario::ctx(&mut scenario)), 0);

            let subnode = string::utf8(b"ea");
            assert!(sui_registrar::available(registrar, subnode, test_scenario::ctx(&mut scenario)), 0);

            test_scenario::return_shared(&mut scenario, registrar_wrapper);
        };

        // test `name_expires` function
        test_scenario::next_tx(&mut scenario, &FIRST_USER);
        {
            let registrar_wrapper = test_scenario::take_shared<SuiRegistrar>(&mut scenario);
            let registrar = test_scenario::borrow_mut(&mut registrar_wrapper);

            let subnode = string::utf8(b"eastagile");
            assert!(sui_registrar::name_expires(registrar, subnode) == 365, 0);

            let subnode = string::utf8(b"ea");
            assert!(sui_registrar::name_expires(registrar, subnode) == 0, 0);

            test_scenario::return_shared(&mut scenario, registrar_wrapper);
        };
    }

    #[test]
    fun test_renew() {
        let scenario = init();
        register(&mut scenario);
        test_scenario::next_tx(&mut scenario, &FIRST_USER);
        {
            let registrar_wrapper = test_scenario::take_shared<SuiRegistrar>(&mut scenario);
            let registrar = test_scenario::borrow_mut(&mut registrar_wrapper);

            assert!(sui_registrar::name_expires(registrar, string::utf8(FIRST_LABEL)) == 365, 0);
            sui_registrar::renew(registrar, FIRST_LABEL, 100, test_scenario::ctx(&mut scenario));
            assert!(sui_registrar::name_expires(registrar, string::utf8(FIRST_LABEL)) == 465, 0);

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
            let registrar_wrapper = test_scenario::take_shared<SuiRegistrar>(&mut scenario);
            let registrar = test_scenario::borrow_mut(&mut registrar_wrapper);
            assert!(sui_registrar::name_expires(registrar, string::utf8(SECOND_LABEL)) == 0, 0);
            sui_registrar::renew(registrar, SECOND_LABEL, 100, test_scenario::ctx(&mut scenario));
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
            let registrar_wrapper = test_scenario::take_shared<SuiRegistrar>(&mut scenario);
            let registrar = test_scenario::borrow_mut(&mut registrar_wrapper);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                500,
                0
            );

            assert!(sui_registrar::name_expires(registrar, string::utf8(FIRST_LABEL)) == 365, 0);
            sui_registrar::renew(registrar, FIRST_LABEL, 100, &ctx);

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

        test_scenario::next_tx(&mut scenario, &SUINS_ADDRESS);
        {
            let registrar_wrapper = test_scenario::take_shared<SuiRegistrar>(&mut scenario);
            let registrar = test_scenario::borrow_mut(&mut registrar_wrapper);
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);

            sui_registrar::reclaim(registrar, registry, FIRST_LABEL, BASE_NODE, SECOND_USER, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(&mut scenario, registrar_wrapper);
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

        test_scenario::next_tx(&mut scenario, &SUINS_ADDRESS);
        {
            let registrar_wrapper = test_scenario::take_shared<SuiRegistrar>(&mut scenario);
            let registrar = test_scenario::borrow_mut(&mut registrar_wrapper);
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);

            sui_registrar::reclaim(registrar, registry, FIRST_LABEL, BASE_NODE, FIRST_USER, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(&mut scenario, registrar_wrapper);
            test_scenario::return_shared(&mut scenario, registry_wrapper);
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
    #[expected_failure(abort_code = 201)]
    fun test_reclaim_abort_caller_is_unauthorized() {
        let scenario = init();
        register(&mut scenario);

        test_scenario::next_tx(&mut scenario, &SECOND_USER);
        {
            let registrar_wrapper = test_scenario::take_shared<SuiRegistrar>(&mut scenario);
            let registrar = test_scenario::borrow_mut(&mut registrar_wrapper);
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);

            sui_registrar::reclaim(registrar, registry, FIRST_LABEL, BASE_NODE, SECOND_USER, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(&mut scenario, registrar_wrapper);
            test_scenario::return_shared(&mut scenario, registry_wrapper);
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
            sui_registrar::reclaim_by_nft_owner(registry, &nft, FIRST_LABEL, SECOND_USER);

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
    #[expected_failure(abort_code = 201)]
    fun test_reclaim_by_nft_owner_abort_if_unauthorised() {
        let scenario = init();
        register(&mut scenario);

        test_scenario::next_tx(&mut scenario, &FIRST_USER);
        {
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);
            let nft = test_scenario::take_owned<RegistrationNFT>(&mut scenario);
            sui_registrar::reclaim_by_nft_owner(registry, &nft, SECOND_LABEL, SECOND_USER);

            test_scenario::return_owned(&mut scenario, nft);
            test_scenario::return_shared(&mut scenario, registry_wrapper);
        };
    }
}
