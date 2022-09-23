#[test_only]
module suins::base_registry_tests {
    use sui::test_scenario::{Self, Scenario};
    use sui::url::Url;
    use suins::base_registry::{Self, AdminCap, Registry, RegistrationNFT};
    use std::string;
    use std::option;

    const SUINS_ADDRESS: address = @0xA001;
    const FIRST_USER_ADDRESS: address = @0xB001;
    const SECOND_USER_ADDRESS: address = @0xB002;
    const FIRST_RESOLVER_ADDRESS: address = @0xC001;
    const SECOND_RESOLVER_ADDRESS: address = @0xC002;
    const BASE_NODE: vector<u8> = b"sui";
    const SUB_NODE: vector<u8> = b"ea.sui";

    fun init(): Scenario {
        let scenario = test_scenario::begin(&SUINS_ADDRESS);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            base_registry::test_init(ctx);
        };
        scenario
    }

    fun mint_record(scenario: &mut Scenario) {
        test_scenario::next_tx(scenario, &FIRST_USER_ADDRESS);
        {
            assert!(!test_scenario::can_take_owned<RegistrationNFT>(scenario), 0);
        };

        test_scenario::next_tx(scenario, &SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_owned<AdminCap>(scenario);
            let registry_wrapper = test_scenario::take_shared<Registry>(scenario);
            let registry_test = test_scenario::borrow_mut(&mut registry_wrapper);
            let ctx = test_scenario::ctx(scenario);

            // registry has default records for `sui` and `move` TLD
            assert!(base_registry::get_registry_len(registry_test) == 2, 0);
            base_registry::set_record(
                &admin_cap,
                registry_test,
                BASE_NODE,
                FIRST_USER_ADDRESS,
                FIRST_RESOLVER_ADDRESS,
                10,
                option::none<Url>(),
                ctx
            );
            assert!(base_registry::get_registry_len(registry_test) == 3, 0);

            test_scenario::return_owned(scenario, admin_cap);
            test_scenario::return_shared(scenario, registry_wrapper);
        };
    }

    // TODO: test for emitted events
    #[test]
    fun test_mint_new_record() {
        let scenario = init();
        mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            assert!(test_scenario::can_take_owned<RegistrationNFT>(&mut scenario), 0);
            let nft = test_scenario::take_owned<RegistrationNFT>(&mut scenario);
            assert!(base_registry::get_NFT_node(&nft) == string::utf8(BASE_NODE), 0);
            test_scenario::return_owned(&mut scenario, nft);

            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);

            assert!(base_registry::owner(registry, BASE_NODE) == FIRST_USER_ADDRESS, 0);
            assert!(base_registry::resolver(registry, BASE_NODE) == FIRST_RESOLVER_ADDRESS, 0);
            assert!(base_registry::ttl(registry, BASE_NODE) == 10, 0);

            test_scenario::return_shared(&mut scenario, registry_wrapper);
        };

        test_scenario::next_tx(&mut scenario, &SECOND_USER_ADDRESS);
        {
            assert!(!test_scenario::can_take_owned<RegistrationNFT>(&mut scenario), 0);
        };

        test_scenario::next_tx(&mut scenario, &SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_owned<AdminCap>(&mut scenario);
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry_test = test_scenario::borrow_mut(&mut registry_wrapper);
            let ctx = test_scenario::ctx(&mut scenario);

            assert!(base_registry::get_registry_len(registry_test) == 1, 0);
            base_registry::set_record(
                &admin_cap,
                registry_test,
                BASE_NODE,
                SECOND_USER_ADDRESS,
                SECOND_RESOLVER_ADDRESS,
                20,
                option::none<Url>(),
                ctx
            );
            assert!(base_registry::get_registry_len(registry_test) == 1, 0);

            test_scenario::return_owned(&mut scenario, admin_cap);
            test_scenario::return_shared(&mut scenario, registry_wrapper);
        };

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            assert!(test_scenario::can_take_owned<RegistrationNFT>(&mut scenario), 0);
            let nft = test_scenario::take_owned<RegistrationNFT>(&mut scenario);
            assert!(base_registry::get_NFT_node(&nft) == string::utf8(BASE_NODE), 0);
            test_scenario::return_owned(&mut scenario, nft);

            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);
            let (_, record) = base_registry::get_record_at_index(registry, 0);

            assert!(base_registry::get_record_node(record) == string::utf8(BASE_NODE), 0);
            assert!(base_registry::get_record_owner(record) == SECOND_USER_ADDRESS, 0);
            assert!(base_registry::get_record_resolver(record) == SECOND_RESOLVER_ADDRESS, 0);
            assert!(base_registry::get_record_ttl(record) == 20, 0);

            test_scenario::return_shared(&mut scenario, registry_wrapper);
        };
    }

    #[test]
    fun test_set_owner() {
        let scenario = init();
        mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, &SECOND_USER_ADDRESS);
        {
            assert!(!test_scenario::can_take_owned<RegistrationNFT>(&mut scenario), 0);
        };

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let nft = test_scenario::take_owned<RegistrationNFT>(&mut scenario);
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);

            assert!(base_registry::get_registry_len(registry) == 1, 0);
            base_registry::set_owner(registry, nft, SECOND_USER_ADDRESS);
            assert!(base_registry::get_registry_len(registry) == 1, 0);

            test_scenario::return_shared(&mut scenario, registry_wrapper);
        };

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            assert!(!test_scenario::can_take_owned<RegistrationNFT>(&mut scenario), 0);
        };

        test_scenario::next_tx(&mut scenario, &SECOND_USER_ADDRESS);
        {
            assert!(test_scenario::can_take_owned<RegistrationNFT>(&mut scenario), 0);

            let nft = test_scenario::take_owned<RegistrationNFT>(&mut scenario);
            assert!(base_registry::get_NFT_node(&nft) == string::utf8(BASE_NODE), 0);
            test_scenario::return_owned(&mut scenario, nft);

            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);

            assert!(base_registry::owner(registry, BASE_NODE) == SECOND_USER_ADDRESS, 0);

            test_scenario::return_shared(&mut scenario, registry_wrapper);
        };
    }

    #[test]
    #[expected_failure(abort_code = 101)]
    fun test_set_owner_abort_if_nft_expired() {
        let scenario = init();
        mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            assert!(test_scenario::can_take_owned<RegistrationNFT>(&mut scenario), 0);
        };

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let nft = test_scenario::take_owned<RegistrationNFT>(&mut scenario);
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);

            assert!(base_registry::get_registry_len(registry) == 1, 0);

            base_registry::delete_record_by_key(registry, string::utf8(BASE_NODE));
            base_registry::set_owner(registry, nft, SECOND_USER_ADDRESS);

            assert!(base_registry::get_registry_len(registry) == 0, 0);
            test_scenario::return_shared(&mut scenario, registry_wrapper);
        };
    }

    #[test]
    fun test_set_subnode_owner() {
        let scenario = init();
        mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, &SECOND_USER_ADDRESS);
        {
            assert!(!test_scenario::can_take_owned<RegistrationNFT>(&mut scenario), 0);
        };

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let nft = test_scenario::take_owned<RegistrationNFT>(&mut scenario);
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);

            assert!(base_registry::get_registry_len(registry) == 1, 0);
            base_registry::set_subnode_owner(
                registry,
                &nft,
                b"ea",
                SECOND_USER_ADDRESS,
                test_scenario::ctx(&mut scenario)
            );
            assert!(base_registry::get_registry_len(registry) == 2, 0);

            test_scenario::return_shared(&mut scenario, registry_wrapper);
            test_scenario::return_owned(&mut scenario, nft);
        };

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            assert!(test_scenario::can_take_owned<RegistrationNFT>(&mut scenario), 0);
        };

        test_scenario::next_tx(&mut scenario, &SECOND_USER_ADDRESS);
        {
            assert!(test_scenario::can_take_owned<RegistrationNFT>(&mut scenario), 0);

            let nft = test_scenario::take_owned<RegistrationNFT>(&mut scenario);
            assert!(base_registry::get_NFT_node(&nft) == string::utf8(SUB_NODE), 0);
            test_scenario::return_owned(&mut scenario, nft);

            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);

            assert!(base_registry::owner(registry, SUB_NODE) == SECOND_USER_ADDRESS, 0);

            test_scenario::return_shared(&mut scenario, registry_wrapper);
        };
    }

    #[test]
    #[expected_failure(abort_code = 101)]
    fun test_set_subnode_owner_abort_if_nft_expired() {
        let scenario = init();
        mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, &SECOND_USER_ADDRESS);
        {
            assert!(!test_scenario::can_take_owned<RegistrationNFT>(&mut scenario), 0);
        };

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let nft = test_scenario::take_owned<RegistrationNFT>(&mut scenario);
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);

            base_registry::delete_record_by_key(registry, string::utf8(BASE_NODE));
            assert!(base_registry::get_registry_len(registry) == 0, 0);
            base_registry::set_subnode_owner(
                registry,
                &nft,
                b"ea",
                SECOND_USER_ADDRESS,
                test_scenario::ctx(&mut scenario)
            );
            assert!(base_registry::get_registry_len(registry) == 0, 0);

            test_scenario::return_shared(&mut scenario, registry_wrapper);
            test_scenario::return_owned(&mut scenario, nft);
        };
    }

    #[test]
    fun test_set_subnode_owner_overwrite_value_if_nft_exists() {
        let scenario = init();
        mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, &SECOND_USER_ADDRESS);
        {
            assert!(!test_scenario::can_take_owned<RegistrationNFT>(&mut scenario), 0);
        };

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let nft = test_scenario::take_owned<RegistrationNFT>(&mut scenario);
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);

            assert!(base_registry::get_registry_len(registry) == 1, 0);
            base_registry::set_subnode_owner(
                registry,
                &nft,
                b"ea",
                SECOND_USER_ADDRESS,
                test_scenario::ctx(&mut scenario)
            );
            assert!(base_registry::get_registry_len(registry) == 2, 0);

            test_scenario::return_shared(&mut scenario, registry_wrapper);
            test_scenario::return_owned(&mut scenario, nft);
        };

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let nft = test_scenario::take_owned<RegistrationNFT>(&mut scenario);
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);

            assert!(base_registry::get_registry_len(registry) == 2, 0);
            // after this call, the first user will have 2 NFTs
            base_registry::set_subnode_owner(
                registry,
                &nft,
                b"ea",
                FIRST_USER_ADDRESS,
                test_scenario::ctx(&mut scenario)
            );
            assert!(base_registry::get_registry_len(registry) == 2, 0);

            test_scenario::return_shared(&mut scenario, registry_wrapper);
            test_scenario::return_owned(&mut scenario, nft);
        };

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let nft = test_scenario::take_owned<RegistrationNFT>(&mut scenario);
            assert!(base_registry::get_NFT_node(&nft) == string::utf8(BASE_NODE), 0);

            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);

            test_scenario::return_owned<RegistrationNFT>(&mut scenario, nft);

            let (_, record) = base_registry::get_record_at_index(registry, 1);
            assert!(base_registry::get_record_node(record) == string::utf8(SUB_NODE), 0);

            test_scenario::return_shared(&mut scenario, registry_wrapper);
        };
    }

    #[test]
    fun test_set_resolver() {
        let scenario = init();
        mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);
            let nft = test_scenario::take_owned<RegistrationNFT>(&mut scenario);

            base_registry::set_resolver(registry, &nft, SECOND_RESOLVER_ADDRESS);
            test_scenario::return_shared(&mut scenario, registry_wrapper);
            test_scenario::return_owned(&mut scenario, nft);
        };

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);

            assert!(base_registry::resolver(registry, BASE_NODE) == SECOND_RESOLVER_ADDRESS, 0);

            test_scenario::return_shared(&mut scenario, registry_wrapper);
        };

        // new resolver == current resolver
        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);
            let nft = test_scenario::take_owned<RegistrationNFT>(&mut scenario);

            assert!(base_registry::get_registry_len(registry) == 1, 0);
            base_registry::set_resolver(registry, &nft, SECOND_RESOLVER_ADDRESS);
            assert!(base_registry::get_registry_len(registry) == 1, 0);

            test_scenario::return_shared(&mut scenario, registry_wrapper);
            test_scenario::return_owned(&mut scenario, nft);
        };

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);

            assert!(base_registry::resolver(registry, BASE_NODE) == SECOND_RESOLVER_ADDRESS, 0);

            test_scenario::return_shared(&mut scenario, registry_wrapper);
        };
    }

    #[test]
    #[expected_failure(abort_code = 101)]
    fun test_set_resolver_abort_if_nft_expired() {
        let scenario = init();
        mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            assert!(test_scenario::can_take_owned<RegistrationNFT>(&mut scenario), 0);
        };

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let nft = test_scenario::take_owned<RegistrationNFT>(&mut scenario);
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);

            assert!(base_registry::get_registry_len(registry) == 1, 0);

            base_registry::delete_record_by_key(registry, string::utf8(BASE_NODE));
            base_registry::set_resolver(registry, &nft, SECOND_RESOLVER_ADDRESS);

            assert!(base_registry::get_registry_len(registry) == 0, 0);
            test_scenario::return_shared(&mut scenario, registry_wrapper);
            test_scenario::return_owned(&mut scenario, nft);
        };
    }

    #[test]
    fun test_set_ttl() {
        let scenario = init();
        mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);
            let nft = test_scenario::take_owned<RegistrationNFT>(&mut scenario);

            base_registry::set_TTL(registry, &nft, 20);
            test_scenario::return_owned(&mut scenario, nft);
            test_scenario::return_shared(&mut scenario, registry_wrapper);
        };

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);

            assert!(base_registry::ttl(registry, BASE_NODE) == 20, 0);

            test_scenario::return_shared(&mut scenario, registry_wrapper);
        };

        // new ttl == current ttl
        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);
            let nft = test_scenario::take_owned<RegistrationNFT>(&mut scenario);

            assert!(base_registry::get_registry_len(registry) == 1, 0);
            base_registry::set_TTL(registry, &nft, 20);
            assert!(base_registry::get_registry_len(registry) == 1, 0);

            test_scenario::return_owned(&mut scenario, nft);
            test_scenario::return_shared(&mut scenario, registry_wrapper);
        };

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);

            assert!(base_registry::ttl(registry, BASE_NODE) == 20, 0);

            test_scenario::return_shared(&mut scenario, registry_wrapper);
        };
    }

    #[test]
    #[expected_failure(abort_code = 101)]
    fun test_set_ttl_abort_if_nft_expired() {
        let scenario = init();
        mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            assert!(test_scenario::can_take_owned<RegistrationNFT>(&mut scenario), 0);
        };

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let nft = test_scenario::take_owned<RegistrationNFT>(&mut scenario);
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);

            assert!(base_registry::get_registry_len(registry) == 1, 0);

            base_registry::delete_record_by_key(registry, string::utf8(BASE_NODE));
            base_registry::set_TTL(registry, &nft, 20);

            assert!(base_registry::get_registry_len(registry) == 0, 0);

            test_scenario::return_owned(&mut scenario, nft);
            test_scenario::return_shared(&mut scenario, registry_wrapper);
        };
    }

    #[test]
    fun test_set_subnode_record() {
        let scenario = init();
        mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, &SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_owned<AdminCap>(&mut scenario);
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);

            assert!(base_registry::get_registry_len(registry) == 1, 0);
            base_registry::set_subnode_record(
                &admin_cap,
                registry,
                string::utf8(BASE_NODE),
                b"ea",
                SECOND_USER_ADDRESS,
                SECOND_RESOLVER_ADDRESS,
                20,
                option::none<Url>(),
                test_scenario::ctx(&mut scenario)
            );
            assert!(base_registry::get_registry_len(registry) == 2, 0);

            test_scenario::return_owned(&mut scenario, admin_cap);
            test_scenario::return_shared(&mut scenario, registry_wrapper);
        };

        test_scenario::next_tx(&mut scenario, &SECOND_USER_ADDRESS);
        {
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);

            assert!(test_scenario::can_take_owned<RegistrationNFT>(&mut scenario), 0);

            let nft = test_scenario::take_owned<RegistrationNFT>(&mut scenario);

            assert!(base_registry::get_NFT_node(&nft) == string::utf8(SUB_NODE), 0);
            assert!(base_registry::owner(registry, SUB_NODE) == SECOND_USER_ADDRESS, 0);
            assert!(base_registry::resolver(registry, SUB_NODE) == SECOND_RESOLVER_ADDRESS, 0);
            assert!(base_registry::ttl(registry, SUB_NODE) == 20, 0);

            test_scenario::return_owned(&mut scenario, nft);
            test_scenario::return_shared(&mut scenario, registry_wrapper);
        };

        test_scenario::next_tx(&mut scenario, &SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_owned<AdminCap>(&mut scenario);
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);

            assert!(base_registry::get_registry_len(registry) == 2, 0);
            base_registry::set_subnode_record(
                &admin_cap,
                registry,
                string::utf8(BASE_NODE),
                b"ea",
                FIRST_USER_ADDRESS,
                FIRST_RESOLVER_ADDRESS,
                10,
                option::none<Url>(),
                test_scenario::ctx(&mut scenario)
            );
            assert!(base_registry::get_registry_len(registry) == 2, 0);

            test_scenario::return_owned(&mut scenario, admin_cap);
            test_scenario::return_shared(&mut scenario, registry_wrapper);
        };

        test_scenario::next_tx(&mut scenario, &SECOND_USER_ADDRESS);
        {
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);

            // we currently cannot transfer the NFT to new owner
            assert!(test_scenario::can_take_owned<RegistrationNFT>(&mut scenario), 0);

            let nft = test_scenario::take_owned<RegistrationNFT>(&mut scenario);

            assert!(base_registry::get_NFT_node(&nft) == string::utf8(SUB_NODE), 0);
            assert!(base_registry::owner(registry, SUB_NODE) == FIRST_USER_ADDRESS, 0);
            assert!(base_registry::resolver(registry, SUB_NODE) == FIRST_RESOLVER_ADDRESS, 0);
            assert!(base_registry::ttl(registry, SUB_NODE) == 10, 0);

            test_scenario::return_owned(&mut scenario, nft);
            test_scenario::return_shared(&mut scenario, registry_wrapper);
        };
    }
}
