#[test_only]
module suins::sui_registrar_tests {
    use sui::test_scenario::{Self, Scenario};
    use suins::base_registry::{Self, RegistrationNFT, Registry};
    use suins::sui_registrar::{Self, SuiRegistrar};
    use std::string;

    const SUINS_ADDRESS: address = @0xA001;
    const FIRST_USER_ADDRESS: address = @0xB001;
    const SECOND_USER_ADDRESS: address = @0xB002;
    const FIRST_RESOLVER_ADDRESS: address = @0xC001;
    const SECOND_RESOLVER_ADDRESS: address = @0xC002;
    const BASE_NODE: vector<u8> = b"sui";
    const SUB_NODE: vector<u8> = b"eastagile.sui";

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
            assert!(test_scenario::can_take_owned<RegistrationNFT>(scenario), 0);
            let sui_tld_nft = test_scenario::take_owned<RegistrationNFT>(scenario);
            let registry_wrapper = test_scenario::take_shared<Registry>(scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);

            let registrar_wrapper = test_scenario::take_shared<SuiRegistrar>(scenario);
            let registrar = test_scenario::borrow_mut(&mut registrar_wrapper);


            sui_registrar::register(
                registrar,
                registry,
                b"eastagile",
                FIRST_USER_ADDRESS,
                365,
                test_scenario::ctx(scenario)
            );
            test_scenario::return_shared(scenario, registry_wrapper);
            test_scenario::return_shared(scenario, registrar_wrapper);
            test_scenario::return_owned(scenario, sui_tld_nft);
        };
    }

    #[test]
    fun test_register() {
        let scenario = init();

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);

            assert!(!test_scenario::can_take_owned<RegistrationNFT>(&mut scenario), 0);
            assert!(base_registry::get_registry_len(registry) == 1, 0);

            test_scenario::return_shared(&mut scenario, registry_wrapper);
        };

        register(&mut scenario);

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            assert!(test_scenario::can_take_owned<RegistrationNFT>(&mut scenario), 0);
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);
            let nft = test_scenario::take_owned<RegistrationNFT>(&mut scenario);

            assert!(base_registry::get_NFT_node(&nft) == string::utf8(SUB_NODE), 0);
            assert!(base_registry::get_registry_len(registry) == 2, 0);

            // index 0 is .sui
            let (_, record) = base_registry::get_record_at_index(registry, 1);
            assert!(base_registry::get_record_owner(record) == FIRST_USER_ADDRESS, 0);
            assert!(base_registry::get_record_resolver(record) == @0x0, 0);
            assert!(base_registry::get_record_ttl(record) == 0, 0);

            test_scenario::return_shared(&mut scenario, registry_wrapper);
            test_scenario::return_owned(&mut scenario, nft);
        };

        // test `available` function
        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
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
        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
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
    fun test_register_only() {
        let scenario = init();

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);

            assert!(!test_scenario::can_take_owned<RegistrationNFT>(&mut scenario), 0);
            assert!(base_registry::get_registry_len(registry) == 1, 0);

            test_scenario::return_shared(&mut scenario, registry_wrapper);
        };

        test_scenario::next_tx(&mut scenario, &SUINS_ADDRESS);
        {
            assert!(test_scenario::can_take_owned<RegistrationNFT>(&mut scenario), 0);
            let sui_tld_nft = test_scenario::take_owned<RegistrationNFT>(&mut scenario);
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);

            let registrar_wrapper = test_scenario::take_shared<SuiRegistrar>(&mut scenario);
            let registrar = test_scenario::borrow_mut(&mut registrar_wrapper);

            sui_registrar::register_only(
                registrar,
                registry,
                b"eastagile",
                FIRST_USER_ADDRESS,
                365,
                test_scenario::ctx(&mut scenario)
            );
            test_scenario::return_shared(&mut scenario, registry_wrapper);
            test_scenario::return_shared(&mut scenario, registrar_wrapper);
            test_scenario::return_owned(&mut scenario, sui_tld_nft);
        };

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            assert!(!test_scenario::can_take_owned<RegistrationNFT>(&mut scenario), 0);
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);

            assert!(base_registry::get_registry_len(registry) == 1, 0);

            test_scenario::return_shared(&mut scenario, registry_wrapper);
        };

        // test `available` function
        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
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
        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
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
}
