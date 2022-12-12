#[test_only]
module suins::base_registrar_tests {
    use sui::test_scenario::{Self, Scenario};
    use sui::tx_context;
    use sui::vec_map;
    use suins::base_registry::{Self, Registry, AdminCap};
    use suins::base_registrar::{Self, BaseRegistrar, RegistrationNFT, TLDsList};
    use suins::configuration::{Self, Configuration};
    use std::string;
    use std::vector;

    const SUINS_ADDRESS: address = @0xA001;
    const FIRST_USER: address = @0xB001;
    const SECOND_USER: address = @0xB002;
    const FIRST_RESOLVER: address = @0xC001;
    const SECOND_RESOLVER: address = @0xC002;
    const SUB_NODE: vector<u8> = b"eastagile.move";
    const FIRST_LABEL: vector<u8> = b"eastagile";
    const SECOND_LABEL: vector<u8> = b"ea";

    fun test_init(): Scenario {
        let scenario = test_scenario::begin(SUINS_ADDRESS);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            base_registry::test_init(ctx);
            base_registrar::test_init(ctx);
            configuration::test_init(ctx);

        };
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let tlds_list = test_scenario::take_shared<TLDsList>(&mut scenario);

            base_registrar::new_tld(&admin_cap, &mut tlds_list, b"sui", test_scenario::ctx(&mut scenario));
            base_registrar::new_tld(&admin_cap, &mut tlds_list, b"addr.reverse", test_scenario::ctx(&mut scenario));
            base_registrar::new_tld(&admin_cap, &mut tlds_list, b"move", test_scenario::ctx(&mut scenario));
            test_scenario::return_shared(tlds_list);
            test_scenario::return_to_sender(&mut scenario, admin_cap);
        };
        scenario
    }

    fun register(scenario: &mut Scenario) {
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(scenario);
            let image = test_scenario::take_shared<Configuration>(scenario);

            base_registrar::register(
                &mut registrar,
                &mut registry,
                &image,
                FIRST_LABEL,
                FIRST_USER,
                365,
                FIRST_RESOLVER,
                test_scenario::ctx(scenario)
            );
            test_scenario::return_shared(registry);
            test_scenario::return_shared(image);
            test_scenario::return_shared(registrar);
        };

        test_scenario::next_tx(scenario, FIRST_USER);
        {
            assert!(test_scenario::has_most_recent_for_sender<RegistrationNFT>(scenario), 0);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(scenario);
            let (name, _) = base_registrar::get_nft_fields(&nft);
            assert!(name == string::utf8(SUB_NODE), 0);

            test_scenario::return_to_sender(scenario, nft);
        };
    }

    #[test]
    fun test_register() {
        let scenario = test_init();

        test_scenario::next_tx(&mut scenario, FIRST_USER);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);

            assert!(base_registry::get_records_len(&registry) == 0, 0);

            test_scenario::return_shared(registry);
        };

        register(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
            assert!(base_registry::get_records_len(&registry) == 1, 0);

            // index 0 is .sui
            let (_, record) = base_registry::get_record_at_index(&registry, 0);
            assert!(base_registry::get_record_owner(record) == FIRST_USER, 0);
            assert!(base_registry::get_record_resolver(record) == FIRST_RESOLVER, 0);
            assert!(base_registry::get_record_ttl(record) == 0, 0);

            test_scenario::return_shared(registry);
        };

        // test `available` function
        test_scenario::next_tx(&mut scenario, FIRST_USER);
        {
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);

            let label = string::utf8(b"eastagile");
            assert!(!base_registrar::available(&registrar, label, test_scenario::ctx(&mut scenario)), 0);

            let label = string::utf8(b"ea");
            assert!(base_registrar::available(&registrar, label, test_scenario::ctx(&mut scenario)), 0);

            test_scenario::return_shared(registrar);
        };

        // test `name_expires` function
        test_scenario::next_tx(&mut scenario, FIRST_USER);
        {
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);

            let label = string::utf8(b"eastagile");
            assert!(base_registrar::name_expires(&registrar, label) == 365, 0);

            let label = string::utf8(b"ea");
            assert!(base_registrar::name_expires(&registrar, label) == 0, 0);

            test_scenario::return_shared(registrar);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = base_registrar::EInvalidLabel)]
    fun test_register_abort_with_invalid_utf8_label() {
        let scenario = test_init();
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let image = test_scenario::take_shared<Configuration>(&mut scenario);
            let invalid_label = vector::empty<u8>();
            // 0xFE cannot appear in a correct UTF-8 string
            vector::push_back(&mut invalid_label, 0xFE);

            base_registrar::register(
                &mut registrar,
                &mut registry,
                &image,
                invalid_label,
                FIRST_USER,
                365,
                FIRST_RESOLVER,
                test_scenario::ctx(&mut scenario)
            );

            test_scenario::return_shared(registry);
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(image);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = base_registrar::EInvalidDuration)]
    fun test_register_abort_with_zero_duration() {
        let scenario = test_init();
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let image = test_scenario::take_shared<Configuration>(&mut scenario);

            base_registrar::register(
                &mut registrar,
                &mut registry,
                &image,
                FIRST_LABEL,
                FIRST_USER,
                0,
                FIRST_RESOLVER,
                test_scenario::ctx(&mut scenario)
            );

            test_scenario::return_shared(registry);
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(image);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = base_registrar::EInvalidDuration)]
    fun test_register_abort_with_invalid_duration() {
        let scenario = test_init();
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let image = test_scenario::take_shared<Configuration>(&mut scenario);

            base_registrar::register(
                &mut registrar,
                &mut registry,
                &image,
                FIRST_LABEL,
                FIRST_USER,
                0,
                FIRST_RESOLVER,
                test_scenario::ctx(&mut scenario)
            );

            test_scenario::return_shared(registry);
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(image);
        };

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = base_registrar::ELabelUnAvailable)]
    fun test_register_abort_if_label_unavailable() {
        let scenario = test_init();
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let image = test_scenario::take_shared<Configuration>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                0,
                0,
            );

            base_registrar::register(
                &mut registrar,
                &mut registry,
                &image,
                FIRST_LABEL,
                FIRST_USER,
                365,
                FIRST_RESOLVER,
                &mut ctx,
            );

            test_scenario::return_shared(registry);
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(image);
        };

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let image = test_scenario::take_shared<Configuration>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                10,
                0,
            );

            base_registrar::register(
                &mut registrar,
                &mut registry,
                &image,
                FIRST_LABEL,
                FIRST_USER,
                365,
                FIRST_RESOLVER,
                &mut ctx,
            );

            test_scenario::return_shared(registry);
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(image);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_renew() {
        let scenario = test_init();
        register(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER);
        {
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);

            assert!(base_registrar::name_expires(&registrar, string::utf8(FIRST_LABEL)) == 365, 0);
            base_registrar::renew(&mut registrar, FIRST_LABEL, 100, test_scenario::ctx(&mut scenario));
            assert!(base_registrar::name_expires(&registrar, string::utf8(FIRST_LABEL)) == 465, 0);

            test_scenario::return_shared(registrar);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = base_registrar::ELabelNotExists)]
    fun test_renew_abort_if_label_not_exists() {
        let scenario = test_init();
        register(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER);
        {
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            assert!(base_registrar::name_expires(&registrar, string::utf8(SECOND_LABEL)) == 0, 0);
            base_registrar::renew(&mut registrar, SECOND_LABEL, 100, test_scenario::ctx(&mut scenario));
            test_scenario::return_shared(registrar);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = base_registrar::ELabelExpired)]
    fun test_renew_abort_if_label_expired() {
        let scenario = test_init();
        register(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER);
        {
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                500,
                0
            );

            assert!(base_registrar::name_expires(&registrar, string::utf8(FIRST_LABEL)) == 365, 0);
            base_registrar::renew(&mut registrar, FIRST_LABEL, 100, &ctx);

            test_scenario::return_shared(registrar);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_reclaim_by_nft_owner() {
        let scenario = test_init();
        register(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);

            base_registrar::reclaim_by_nft_owner(
                &registrar,
                &mut registry,
                &nft,
                SECOND_USER,
                test_scenario::ctx(&mut scenario)
            );

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(registry);
            test_scenario::return_shared(registrar);
        };

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);

            let owner = base_registry::owner(&registry, SUB_NODE);
            assert!(SECOND_USER == owner, 0);

            test_scenario::return_shared(registry);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = base_registrar::EInvalidBaseNode)]
    fun test_reclaim_by_nft_owner_abort_with_wrong_base_node() {
        let scenario = test_init();
        register(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
            let move_registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let sui_registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);

            base_registrar::reclaim_by_nft_owner(
                &sui_registrar,
                &mut registry,
                &nft,
                SECOND_USER,
                test_scenario::ctx(&mut scenario)
            );

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(registry);
            test_scenario::return_shared(move_registrar);
            test_scenario::return_shared(sui_registrar);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = base_registrar::ELabelNotExists)]
    fun test_reclaim_by_nft_owner_abort_if_label_not_exists() {
        let scenario = test_init();
        register(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
            let move_registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            base_registrar::set_nft_domain(&mut nft, string::utf8(b"thisisadomain.move"));

            base_registrar::reclaim_by_nft_owner(
                &move_registrar,
                &mut registry,
                &nft,
                SECOND_USER,
                test_scenario::ctx(&mut scenario)
            );

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(registry);
            test_scenario::return_shared(move_registrar);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = base_registrar::ELabelExpired)]
    fun test_reclaim_by_nft_owner_abort_if_label_expired() {
        let scenario = test_init();
        register(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
            let move_registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                500,
                0
            );
            base_registrar::reclaim_by_nft_owner(
                &move_registrar,
                &mut registry,
                &nft,
                SECOND_USER,
                &mut ctx,
            );

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(registry);
            test_scenario::return_shared(move_registrar);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_new_tld() {
        let scenario = test_init();

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let tlds_list = test_scenario::take_shared<TLDsList>(&mut scenario);

            let tlds = base_registrar::get_tlds(&tlds_list);
            assert!(vector::length(tlds) == 3, 0);

            let registry = test_scenario::take_shared<Registry>(&mut scenario);

            assert!(base_registry::get_records_len(&registry) == 0, 0);

            test_scenario::return_shared(tlds_list);
            test_scenario::return_shared(registry);
        };

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let tlds_list = test_scenario::take_shared<TLDsList>(&mut scenario);
            base_registrar::new_tld(
                &admin_cap,
                &mut tlds_list,
                b"com",
                test_scenario::ctx(&mut scenario)
            );

            test_scenario::return_to_sender(&mut scenario, admin_cap);
            test_scenario::return_shared(tlds_list);
        };

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let tlds_list = test_scenario::take_shared<TLDsList>(&mut scenario);

            let tlds = base_registrar::get_tlds(&tlds_list);
            assert!(vector::length(tlds) == 4, 0);
            assert!(vector::borrow(tlds, 3) == &string::utf8(b"com"), 0);

            let com_registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);

            let (base_node, base_node_bytes, expiries) =
                base_registrar::get_registrar(&com_registrar);
            assert!(base_node == &string::utf8(b"com"), 0);
            assert!(base_node_bytes == &b"com", 0);
            assert!(vec_map::size(expiries) == 0, 0);

            let registry = test_scenario::take_shared<Registry>(&mut scenario);
            assert!(base_registry::get_records_len(&registry) == 0, 0);

            test_scenario::return_shared(tlds_list);
            test_scenario::return_shared(com_registrar);
            test_scenario::return_shared(registry);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER);
        {
            let registry =
                test_scenario::take_shared<Registry>(&mut scenario);
            let com_registrar =
                test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let image = test_scenario::take_shared<Configuration>(&mut scenario);

            base_registrar::register(
                &mut com_registrar,
                &mut registry,
                &image,
                FIRST_LABEL,
                FIRST_USER,
                365,
                FIRST_RESOLVER,
                test_scenario::ctx(&mut scenario)
            );
            test_scenario::return_shared(registry);
            test_scenario::return_shared(image);
            test_scenario::return_shared(com_registrar);
        };

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let com_registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);

            let (_, _, expiries) = base_registrar::get_registrar(&com_registrar);
            assert!(vec_map::size(expiries) == 1, 0);
            let (key, value) = vec_map::get_entry_by_idx(expiries, 0);
            assert!(key == &string::utf8(FIRST_LABEL), 0);

            let expiry = base_registrar::get_registration_detail(value);
            assert!(expiry == 365, 0);

            test_scenario::return_shared(com_registrar);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = base_registrar::ETLDExists)]
    fun test_new_tld_abort_with_duplicated_tld() {
        let scenario = test_init();

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let tlds_list = test_scenario::take_shared<TLDsList>(&mut scenario);

            base_registrar::new_tld(
                &admin_cap,
                &mut tlds_list,
                b"move",
                test_scenario::ctx(&mut scenario)
            );

            test_scenario::return_to_sender(&mut scenario, admin_cap);
            test_scenario::return_shared(tlds_list);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = base_registrar::ETLDExists)]
    fun test_admin_set() {
        let scenario = test_init();

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let tlds_list = test_scenario::take_shared<TLDsList>(&mut scenario);

            base_registrar::new_tld(
                &admin_cap,
                &mut tlds_list,
                b"move",
                test_scenario::ctx(&mut scenario)
            );

            test_scenario::return_to_sender(&mut scenario, admin_cap);
            test_scenario::return_shared(tlds_list);
        };
        test_scenario::end(scenario);
    }
}
