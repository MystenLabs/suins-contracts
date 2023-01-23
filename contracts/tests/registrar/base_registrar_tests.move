#[test_only]
module suins::base_registrar_tests {
    use sui::test_scenario::{Self, Scenario};
    use sui::tx_context;
    use sui::table;
    use suins::base_registry::{Self, Registry, AdminCap};
    use suins::base_registrar::{Self, BaseRegistrar, RegistrationNFT, TLDsList};
    use suins::configuration::{Self, Configuration};
    use std::vector;
    use std::string::utf8;
    use sui::url;

    const SUINS_ADDRESS: address = @0xA001;
    const FIRST_USER: address = @0xB001;
    const SECOND_USER: address = @0xB002;
    const FIRST_RESOLVER: address = @0xC001;
    const SECOND_RESOLVER: address = @0xC002;
    const FIRST_LABEL: vector<u8> = b"eastagile";
    const FIRST_NODE: vector<u8> = b"eastagile.sui";
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

            base_registrar::new_tld(&admin_cap, &mut tlds_list, b"move", test_scenario::ctx(&mut scenario));
            base_registrar::new_tld(&admin_cap, &mut tlds_list, b"sui", test_scenario::ctx(&mut scenario));
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
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                10,
                0
            );

            assert!(base_registry::get_records_len(&registry) == 0, 0);

            base_registrar::register(
                &mut registrar,
                &mut registry,
                &image,
                FIRST_LABEL,
                FIRST_USER,
                365,
                FIRST_RESOLVER,
                &mut ctx
            );
            test_scenario::return_shared(registry);
            test_scenario::return_shared(image);
            test_scenario::return_shared(registrar);
        };

        test_scenario::next_tx(scenario, FIRST_USER);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(scenario);
            let registry = test_scenario::take_shared<Registry>(scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(scenario);
            let (name, url) = base_registrar::get_nft_fields(&nft);
            let (_, _, expiries) = base_registrar::get_registrar(&registrar);
            let detail = table::borrow(expiries, utf8(FIRST_LABEL));

            assert!(base_registrar::get_registration_detail(detail) == 10 + 365, 0);
            assert!(name == utf8(FIRST_NODE), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmWjyuoBW7gSxAqvkTYSNbXnNka6iUHNqs3ier9bN3g7Y2"),
                0
            ); // 2024
            assert!(base_registry::get_records_len(&registry) == 1, 0);

            let (owner, resolver, ttl) = base_registry::get_record_by_key(&registry, utf8(FIRST_NODE));

            assert!(owner == FIRST_USER, 0);
            assert!(resolver == FIRST_RESOLVER, 0);
            assert!(ttl == 0, 0);
            test_scenario::return_to_sender(scenario, nft);
            test_scenario::return_shared(registry);
            test_scenario::return_shared(registrar);
        };
    }

    #[test]
    fun test_register() {
        let scenario = test_init();
        register(&mut scenario);

        // test `available` function
        test_scenario::next_tx(&mut scenario, FIRST_USER);
        {
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);

            let label = utf8(b"eastagile");
            assert!(!base_registrar::available(&registrar, label, test_scenario::ctx(&mut scenario)), 0);

            let label = utf8(b"ea");
            assert!(base_registrar::available(&registrar, label, test_scenario::ctx(&mut scenario)), 0);

            test_scenario::return_shared(registrar);
        };

        // test `name_expires` function
        test_scenario::next_tx(&mut scenario, FIRST_USER);
        {
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);

            let label = utf8(b"eastagile");
            assert!(base_registrar::name_expires(&registrar, label) == 10 + 365, 0);

            let label = utf8(b"ea");
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

    #[test, expected_failure(abort_code = base_registrar::ELabelUnAvailable)]
    fun test_register_abort_if_label_unavailable() {
        let scenario = test_init();
        register(&mut scenario);
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let image = test_scenario::take_shared<Configuration>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                10,
                10,
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

            assert!(base_registrar::name_expires(&registrar, utf8(FIRST_LABEL)) == 375, 0);
            let new_expiry = base_registrar::renew(&mut registrar, FIRST_LABEL, 100, test_scenario::ctx(&mut scenario));
            assert!(base_registrar::name_expires(&registrar, utf8(FIRST_LABEL)) == 475, 0);
            assert!(new_expiry == 475, 0);

            test_scenario::return_shared(registrar);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = base_registrar::ELabelNotExists)]
    fun test_renew_abort_if_label_not_exists() {
        let scenario = test_init();
        test_scenario::next_tx(&mut scenario, FIRST_USER);
        {
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            assert!(base_registrar::name_expires(&registrar, utf8(SECOND_LABEL)) == 0, 0);

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

            assert!(base_registrar::name_expires(&registrar, utf8(FIRST_LABEL)) == 375, 0);
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

            let owner = base_registry::owner(&registry, FIRST_NODE);
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
            let sui_registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let move_registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);

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
            let sui_registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            base_registrar::set_nft_domain(&mut nft, utf8(b"thisisadomain.sui"));

            base_registrar::reclaim_by_nft_owner(
                &sui_registrar,
                &mut registry,
                &nft,
                SECOND_USER,
                test_scenario::ctx(&mut scenario)
            );

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(registry);
            test_scenario::return_shared(sui_registrar);
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
            let registry = test_scenario::take_shared<Registry>(&mut scenario);

            assert!(vector::length(tlds) == 2, 0);
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
            let com_registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let registry = test_scenario::take_shared<Registry>(&mut scenario);

            assert!(vector::length(tlds) == 3, 0);
            assert!(vector::borrow(tlds, 2) == &utf8(b"com"), 0);
            assert!(base_registry::get_records_len(&registry) == 0, 0);

            let (base_node, base_node_bytes, expiries) =
                base_registrar::get_registrar(&com_registrar);
            assert!(base_node == &utf8(b"com"), 0);
            assert!(base_node_bytes == &b"com", 0);
            assert!(table::length(expiries) == 0, 0);

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
            assert!(table::length(expiries) == 1, 0);
            let value = table::borrow(expiries, utf8(FIRST_LABEL));
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
                b"sui",
                test_scenario::ctx(&mut scenario)
            );

            test_scenario::return_to_sender(&mut scenario, admin_cap);
            test_scenario::return_shared(tlds_list);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = base_registrar::ETLDExists)]
    fun test_admin_set_new_tld() {
        let scenario = test_init();

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let tlds_list = test_scenario::take_shared<TLDsList>(&mut scenario);

            base_registrar::new_tld(
                &admin_cap,
                &mut tlds_list,
                b"sui",
                test_scenario::ctx(&mut scenario)
            );

            test_scenario::return_to_sender(&mut scenario, admin_cap);
            test_scenario::return_shared(tlds_list);
        };
        test_scenario::end(scenario);
    }
}
