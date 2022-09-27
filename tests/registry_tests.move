#[test_only]
module suins::registry_tests {
    use sui::test_scenario::{Self, Scenario};
    use sui::url::Url;
    use suins::base_registry::{Self, AdminCap, Registry, RecordNFT};
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
            assert!(!test_scenario::can_take_owned<RecordNFT>(scenario), 0);
        };

        test_scenario::next_tx(scenario, &SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_owned<AdminCap>(scenario);
            let registry_wrapper = test_scenario::take_shared<Registry>(scenario);
            let registry_test = test_scenario::borrow_mut(&mut registry_wrapper);
            let ctx = test_scenario::ctx(scenario);

            assert!(base_registry::get_registry_len(registry_test) == 0, 0);
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
            assert!(base_registry::get_registry_len(registry_test) == 1, 0);

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
            assert!(test_scenario::can_take_owned<RecordNFT>(&mut scenario), 0);
            let record = test_scenario::take_owned<RecordNFT>(&mut scenario);
            assert!(base_registry::get_record_NFT_node(&record) == string::utf8(BASE_NODE), 0);
            test_scenario::return_owned(&mut scenario, record);

            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);

            assert!(base_registry::owner(registry, BASE_NODE) == FIRST_USER_ADDRESS, 0);
            assert!(base_registry::resolver(registry, BASE_NODE) == FIRST_RESOLVER_ADDRESS, 0);
            assert!(base_registry::ttl(registry, BASE_NODE) == 10, 0);

            test_scenario::return_shared(&mut scenario, registry_wrapper);
        };

        test_scenario::next_tx(&mut scenario, &SECOND_USER_ADDRESS);
        {
            assert!(!test_scenario::can_take_owned<RecordNFT>(&mut scenario), 0);
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
            assert!(test_scenario::can_take_owned<RecordNFT>(&mut scenario), 0);
            let record = test_scenario::take_owned<RecordNFT>(&mut scenario);
            assert!(base_registry::get_record_NFT_node(&record) == string::utf8(BASE_NODE), 0);
            test_scenario::return_owned(&mut scenario, record);

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
            assert!(!test_scenario::can_take_owned<RecordNFT>(&mut scenario), 0);
        };

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let record = test_scenario::take_owned<RecordNFT>(&mut scenario);
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);

            assert!(base_registry::get_registry_len(registry) == 1, 0);
            base_registry::set_owner(registry, record, SECOND_USER_ADDRESS);
            assert!(base_registry::get_registry_len(registry) == 1, 0);

            test_scenario::return_shared(&mut scenario, registry_wrapper);
        };

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            assert!(!test_scenario::can_take_owned<RecordNFT>(&mut scenario), 0);
        };

        test_scenario::next_tx(&mut scenario, &SECOND_USER_ADDRESS);
        {
            assert!(test_scenario::can_take_owned<RecordNFT>(&mut scenario), 0);

            let record = test_scenario::take_owned<RecordNFT>(&mut scenario);
            assert!(base_registry::get_record_NFT_node(&record) == string::utf8(BASE_NODE), 0);
            test_scenario::return_owned(&mut scenario, record);

            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);

            assert!(base_registry::owner(registry, BASE_NODE) == SECOND_USER_ADDRESS, 0);

            test_scenario::return_shared(&mut scenario, registry_wrapper);
        };
    }

    #[test]
    fun test_set_owner_delete_nft_if_it_expired() {
        let scenario = init();
        mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            assert!(test_scenario::can_take_owned<RecordNFT>(&mut scenario), 0);
        };

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let record = test_scenario::take_owned<RecordNFT>(&mut scenario);
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);

            assert!(base_registry::get_registry_len(registry) == 1, 0);

            base_registry::delete_record_by_key(registry, string::utf8(BASE_NODE));
            base_registry::set_owner(registry, record, SECOND_USER_ADDRESS);

            assert!(base_registry::get_registry_len(registry) == 0, 0);
            test_scenario::return_shared(&mut scenario, registry_wrapper);
        };

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            assert!(!test_scenario::can_take_owned<RecordNFT>(&mut scenario), 0);
        };

        test_scenario::next_tx(&mut scenario, &SECOND_USER_ADDRESS);
        {
            assert!(!test_scenario::can_take_owned<RecordNFT>(&mut scenario), 0);
        };
    }

    #[test]
    fun test_set_subnode_owner() {
        let scenario = init();
        mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, &SECOND_USER_ADDRESS);
        {
            assert!(!test_scenario::can_take_owned<RecordNFT>(&mut scenario), 0);
        };

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let record = test_scenario::take_owned<RecordNFT>(&mut scenario);
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);

            assert!(base_registry::get_registry_len(registry) == 1, 0);
            base_registry::set_subnode_owner(
                registry,
                record,
                b"ea",
                SECOND_USER_ADDRESS,
                test_scenario::ctx(&mut scenario)
            );
            assert!(base_registry::get_registry_len(registry) == 2, 0);

            test_scenario::return_shared(&mut scenario, registry_wrapper);
        };

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            assert!(test_scenario::can_take_owned<RecordNFT>(&mut scenario), 0);
        };

        test_scenario::next_tx(&mut scenario, &SECOND_USER_ADDRESS);
        {
            assert!(test_scenario::can_take_owned<RecordNFT>(&mut scenario), 0);

            let record = test_scenario::take_owned<RecordNFT>(&mut scenario);
            assert!(base_registry::get_record_NFT_node(&record) == string::utf8(SUB_NODE), 0);
            test_scenario::return_owned(&mut scenario, record);

            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);

            assert!(base_registry::owner(registry, SUB_NODE) == SECOND_USER_ADDRESS, 0);

            test_scenario::return_shared(&mut scenario, registry_wrapper);
        };
    }

    #[test]
    fun test_set_subnode_owner_delete_nft_if_it_expired() {
        let scenario = init();
        mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, &SECOND_USER_ADDRESS);
        {
            assert!(!test_scenario::can_take_owned<RecordNFT>(&mut scenario), 0);
        };

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let record = test_scenario::take_owned<RecordNFT>(&mut scenario);
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);

            base_registry::delete_record_by_key(registry, string::utf8(BASE_NODE));
            assert!(base_registry::get_registry_len(registry) == 0, 0);
            base_registry::set_subnode_owner(
                registry,
                record,
                b"ea",
                SECOND_USER_ADDRESS,
                test_scenario::ctx(&mut scenario)
            );
            assert!(base_registry::get_registry_len(registry) == 0, 0);

            test_scenario::return_shared(&mut scenario, registry_wrapper);
        };

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            assert!(!test_scenario::can_take_owned<RecordNFT>(&mut scenario), 0);
        };

        test_scenario::next_tx(&mut scenario, &SECOND_USER_ADDRESS);
        {
            assert!(!test_scenario::can_take_owned<RecordNFT>(&mut scenario), 0);
        };
    }

    #[test]
    fun test_set_subnode_owner_overwrite_value_if_it_exists() {
        let scenario = init();
        mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, &SECOND_USER_ADDRESS);
        {
            assert!(!test_scenario::can_take_owned<RecordNFT>(&mut scenario), 0);
        };

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let record = test_scenario::take_owned<RecordNFT>(&mut scenario);
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);

            assert!(base_registry::get_registry_len(registry) == 1, 0);
            base_registry::set_subnode_owner(
                registry,
                record,
                b"ea",
                SECOND_USER_ADDRESS,
                test_scenario::ctx(&mut scenario)
            );
            assert!(base_registry::get_registry_len(registry) == 2, 0);

            test_scenario::return_shared(&mut scenario, registry_wrapper);
        };

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let record = test_scenario::take_owned<RecordNFT>(&mut scenario);
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);

            assert!(base_registry::get_registry_len(registry) == 2, 0);
            // after this call, the first user will have 2 NFTs
            base_registry::set_subnode_owner(
                registry,
                record,
                b"ea",
                FIRST_USER_ADDRESS,
                test_scenario::ctx(&mut scenario)
            );
            assert!(base_registry::get_registry_len(registry) == 2, 0);

            test_scenario::return_shared(&mut scenario, registry_wrapper);
        };

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let record = test_scenario::take_owned<RecordNFT>(&mut scenario);
            assert!(base_registry::get_record_NFT_node(&record) == string::utf8(BASE_NODE), 0);

            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);

            test_scenario::return_owned<RecordNFT>(&mut scenario, record);

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
            let record = test_scenario::take_owned<RecordNFT>(&mut scenario);

            base_registry::set_resolver(
                registry,
                record,
                SECOND_RESOLVER_ADDRESS,
                test_scenario::ctx(&mut scenario)
            );
            test_scenario::return_shared(&mut scenario, registry_wrapper);
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
            let record = test_scenario::take_owned<RecordNFT>(&mut scenario);

            assert!(base_registry::get_registry_len(registry) == 1, 0);
            base_registry::set_resolver(registry, record, SECOND_RESOLVER_ADDRESS, test_scenario::ctx(&mut scenario));
            assert!(base_registry::get_registry_len(registry) == 1, 0);

            test_scenario::return_shared(&mut scenario, registry_wrapper);
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
    fun test_set_resolver_delete_nft_if_it_expired() {
        let scenario = init();
        mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            assert!(test_scenario::can_take_owned<RecordNFT>(&mut scenario), 0);
        };

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let record = test_scenario::take_owned<RecordNFT>(&mut scenario);
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);

            assert!(base_registry::get_registry_len(registry) == 1, 0);

            base_registry::delete_record_by_key(registry, string::utf8(BASE_NODE));
            base_registry::set_resolver(registry, record, SECOND_RESOLVER_ADDRESS, test_scenario::ctx(&mut scenario));

            assert!(base_registry::get_registry_len(registry) == 0, 0);
            test_scenario::return_shared(&mut scenario, registry_wrapper);
        };

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            assert!(!test_scenario::can_take_owned<RecordNFT>(&mut scenario), 0);
        };

        test_scenario::next_tx(&mut scenario, &SECOND_USER_ADDRESS);
        {
            assert!(!test_scenario::can_take_owned<RecordNFT>(&mut scenario), 0);
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
            let record = test_scenario::take_owned<RecordNFT>(&mut scenario);

            base_registry::set_TTL(registry, record, 20, test_scenario::ctx(&mut scenario));
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
            let record = test_scenario::take_owned<RecordNFT>(&mut scenario);

            assert!(base_registry::get_registry_len(registry) == 1, 0);
            base_registry::set_TTL(registry, record, 20, test_scenario::ctx(&mut scenario));
            assert!(base_registry::get_registry_len(registry) == 1, 0);

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
    fun test_set_ttl_delete_nft_if_it_expired() {
        let scenario = init();
        mint_record(&mut scenario);

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            assert!(test_scenario::can_take_owned<RecordNFT>(&mut scenario), 0);
        };

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let record = test_scenario::take_owned<RecordNFT>(&mut scenario);
            let registry_wrapper = test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);

            assert!(base_registry::get_registry_len(registry) == 1, 0);

            base_registry::delete_record_by_key(registry, string::utf8(BASE_NODE));
            base_registry::set_TTL(registry, record, 20, test_scenario::ctx(&mut scenario));

            assert!(base_registry::get_registry_len(registry) == 0, 0);
            test_scenario::return_shared(&mut scenario, registry_wrapper);
        };

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            assert!(!test_scenario::can_take_owned<RecordNFT>(&mut scenario), 0);
        };

        test_scenario::next_tx(&mut scenario, &SECOND_USER_ADDRESS);
        {
            assert!(!test_scenario::can_take_owned<RecordNFT>(&mut scenario), 0);
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

            assert!(test_scenario::can_take_owned<RecordNFT>(&mut scenario), 0);

            let record_nft = test_scenario::take_owned<RecordNFT>(&mut scenario);

            assert!(base_registry::get_record_NFT_node(&record_nft) == string::utf8(SUB_NODE), 0);
            assert!(base_registry::owner(registry, SUB_NODE) == SECOND_USER_ADDRESS, 0);
            assert!(base_registry::resolver(registry, SUB_NODE) == SECOND_RESOLVER_ADDRESS, 0);
            assert!(base_registry::ttl(registry, SUB_NODE) == 20, 0);

            test_scenario::return_owned(&mut scenario, record_nft);
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
            assert!(test_scenario::can_take_owned<RecordNFT>(&mut scenario), 0);

            let record_nft = test_scenario::take_owned<RecordNFT>(&mut scenario);

            assert!(base_registry::get_record_NFT_node(&record_nft) == string::utf8(SUB_NODE), 0);
            assert!(base_registry::owner(registry, SUB_NODE) == FIRST_USER_ADDRESS, 0);
            assert!(base_registry::resolver(registry, SUB_NODE) == FIRST_RESOLVER_ADDRESS, 0);
            assert!(base_registry::ttl(registry, SUB_NODE) == 10, 0);

            test_scenario::return_owned(&mut scenario, record_nft);
            test_scenario::return_shared(&mut scenario, registry_wrapper);
        };
    }
}
