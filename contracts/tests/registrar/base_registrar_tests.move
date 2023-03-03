#[test_only]
module suins::base_registrar_tests {

    use sui::test_scenario::{Self, Scenario};
    use sui::tx_context;
    use sui::url;
    use sui::dynamic_field;
    use suins::base_registry::{Self, Registry, AdminCap};
    use suins::base_registrar::{Self, BaseRegistrar, RegistrationNFT, TLDList};
    use suins::configuration::{Self, Configuration};
    use std::vector;
    use std::string::utf8;

    const SUINS_ADDRESS: address = @0xA001;
    const FIRST_USER: address = @0xB001;
    const SECOND_USER: address = @0xB002;
    const FIRST_RESOLVER: address = @0xC001;
    const SECOND_RESOLVER: address = @0xC002;
    const FIRST_LABEL: vector<u8> = b"eastagile";
    const FIRST_NODE: vector<u8> = b"eastagile.sui";
    const SECOND_LABEL: vector<u8> = b"ea";
    const THIRD_LABEL: vector<u8> = b"eastagil";

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
            let tlds_list = test_scenario::take_shared<TLDList>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);

            base_registrar::new_tld(&admin_cap, &mut tlds_list, b"move", test_scenario::ctx(&mut scenario));
            base_registrar::new_tld(&admin_cap, &mut tlds_list, b"sui", test_scenario::ctx(&mut scenario));
            configuration::set_public_key(
                &admin_cap,
                &mut config,
                x"0445e28df251d0ec0f66f284f7d5598db7e68b1a196396e4e13a3942d1364812ae5ed65ebb3d20cbf073ad50c6bbafa92505dc9b306e30476e57919a63ac824cab"
            );
            test_scenario::return_shared(tlds_list);
            test_scenario::return_shared(config);
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
            let (_, _, uid) = base_registrar::get_registrar(&registrar);
            let detail = dynamic_field::borrow(uid, utf8(FIRST_LABEL));

            assert!(base_registrar::get_registration_expiry(detail) == 10 + 365, 0);
            assert!(base_registrar::get_registration_owner(detail) == FIRST_USER, 0);
            assert!(name == utf8(FIRST_NODE), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );

            let (owner, resolver, ttl) = base_registry::get_record_by_key(&registry, utf8(FIRST_NODE));

            assert!(owner == FIRST_USER, 0);
            assert!(resolver == FIRST_RESOLVER, 0);
            assert!(ttl == 0, 0);
            test_scenario::return_to_sender(scenario, nft);
            test_scenario::return_shared(registry);
            test_scenario::return_shared(registrar);
        };
    }

    fun register_with_image(
        scenario: &mut Scenario,
        signature: vector<u8>,
        hashed_msg: vector<u8>,
        raw_msg: vector<u8>
    ) {
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

            base_registrar::register_with_image(
                &mut registrar,
                &mut registry,
                &image,
                FIRST_LABEL,
                FIRST_USER,
                365,
                FIRST_RESOLVER,
                signature,
                hashed_msg,
                raw_msg,
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
            let (_, _, uid) = base_registrar::get_registrar(&registrar);
            let detail = dynamic_field::borrow(uid, utf8(FIRST_LABEL));

            assert!(base_registrar::get_registration_expiry(detail) == 10 + 365, 0);
            assert!(base_registrar::get_registration_owner(detail) == FIRST_USER, 0);
            assert!(name == utf8(FIRST_NODE), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k"),
                0
            );

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
            assert!(!base_registrar::is_available(&registrar, label, test_scenario::ctx(&mut scenario)), 0);

            let label = utf8(b"ea");
            assert!(base_registrar::is_available(&registrar, label, test_scenario::ctx(&mut scenario)), 0);

            test_scenario::return_shared(registrar);
        };

        // test `name_expires` function
        test_scenario::next_tx(&mut scenario, FIRST_USER);
        {
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);

            let label = utf8(b"eastagile");
            assert!(base_registrar::name_expires_at(&registrar, label) == 10 + 365, 0);

            let label = utf8(b"ea");
            assert!(base_registrar::name_expires_at(&registrar, label) == 0, 0);

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

            assert!(base_registrar::name_expires_at(&registrar, utf8(FIRST_LABEL)) == 375, 0);
            let new_expiry = base_registrar::renew(&mut registrar, FIRST_LABEL, 100, test_scenario::ctx(&mut scenario));
            assert!(base_registrar::name_expires_at(&registrar, utf8(FIRST_LABEL)) == 475, 0);
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
            assert!(base_registrar::name_expires_at(&registrar, utf8(SECOND_LABEL)) == 0, 0);

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

            assert!(base_registrar::name_expires_at(&registrar, utf8(FIRST_LABEL)) == 375, 0);
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

            base_registrar::reclaim_name(
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
    fun test_reclaim_name_by_nft_owner_abort_with_wrong_base_node() {
        let scenario = test_init();
        register(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
            let sui_registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let move_registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);

            base_registrar::reclaim_name(
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

    #[test, expected_failure(abort_code = dynamic_field::EFieldDoesNotExist)]
    fun test_reclaim_name_by_nft_owner_abort_if_label_not_exists() {
        let scenario = test_init();
        register(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
            let sui_registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            base_registrar::set_nft_domain(&mut nft, utf8(b"thisisadomain.sui"));

            base_registrar::reclaim_name(
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

    #[test, expected_failure(abort_code = base_registrar::ENFTExpired)]
    fun test_reclaim_name_by_nft_owner_abort_if_nft_expired() {
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

            base_registrar::reclaim_name(
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
            let tlds_list = test_scenario::take_shared<TLDList>(&mut scenario);
            let tlds = base_registrar::get_tlds(&tlds_list);
            let registry = test_scenario::take_shared<Registry>(&mut scenario);

            assert!(vector::length(tlds) == 2, 0);

            test_scenario::return_shared(tlds_list);
            test_scenario::return_shared(registry);
        };

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let tlds_list = test_scenario::take_shared<TLDList>(&mut scenario);

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
            let tlds_list = test_scenario::take_shared<TLDList>(&mut scenario);
            let tlds = base_registrar::get_tlds(&tlds_list);
            let com_registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let registry = test_scenario::take_shared<Registry>(&mut scenario);

            assert!(vector::length(tlds) == 3, 0);
            assert!(vector::borrow(tlds, 2) == &utf8(b"com"), 0);

            let (base_node, base_node_bytes, _) =
                base_registrar::get_registrar(&com_registrar);
            assert!(base_node == &utf8(b"com"), 0);
            assert!(base_node_bytes == &b"com", 0);

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
            let (_, _, uid) = base_registrar::get_registrar(&com_registrar);
            let value = dynamic_field::borrow(uid, utf8(FIRST_LABEL));
            assert!(base_registrar::get_registration_expiry(value) == 365, 0);
            assert!(base_registrar::get_registration_owner(value) == FIRST_USER, 0);

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
            let tlds_list = test_scenario::take_shared<TLDList>(&mut scenario);

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
            let tlds_list = test_scenario::take_shared<TLDList>(&mut scenario);

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

    #[test]
    fun test_update_image_url() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        register(scenario);

        test_scenario::next_tx(scenario, FIRST_USER);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(scenario);
            let (name, url) = base_registrar::get_nft_fields(&nft);

            assert!(name == utf8(FIRST_NODE), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );
            test_scenario::return_to_sender(scenario, nft);
        };

        test_scenario::next_tx(scenario, FIRST_USER);
        {
            let registrar = test_scenario::take_shared<BaseRegistrar>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(scenario);
            let ctx = tx_context::new(
                FIRST_USER,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                10,
                0
            );
            let signature =
                x"1750ce9c94af251d3288589b4e98369ee09a41530b42f545eab96763ecbaa8b941f0a814e7440eacd803c507633825ca1f70dc9018b59cb3e49871ca6ddcf704";

            base_registrar::update_image_url(
                &mut registrar,
                &config,
                &mut nft,
                signature,
                x"c9cbb723ef1dce214552f05378404491ce9cb36429df9ca307b1619268f09335",
                b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,eastagile.sui,375",
                &mut ctx
            );
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(config);
            test_scenario::return_to_sender(scenario, nft);
        };
        test_scenario::next_tx(scenario, FIRST_USER);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(scenario);
            let (name, url) = base_registrar::get_nft_fields(&nft);

            assert!(name == utf8(FIRST_NODE), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k"),
                0
            );
            test_scenario::return_to_sender(scenario, nft);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = base_registrar::EInvalidImageMessage)]
    fun test_update_image_url_aborts_with_incorrect_expiry() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        register(scenario);

        test_scenario::next_tx(scenario, FIRST_USER);
        {
            let registrar = test_scenario::take_shared<BaseRegistrar>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(scenario);

            let ctx = tx_context::new(
                FIRST_USER,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                10,
                0
            );
            base_registrar::update_image_url(
                &mut registrar,
                &config,
                &mut nft,
                x"e35de3997a3f9f5614b207f4d7516ca1709e8d46bf2c45ada5ac0383c2939df050859994404b04cdc9f01aa200322b3af6738866347fe50d195b58982d5fa725",
                x"fee40dbc963366e0d1eb8337bf2b491c2b96a6958d56aca077484861ef61cf89",
                b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,000000000000000000000000000000000000b001,475,abcc",
                &mut ctx
            );
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(config);
            test_scenario::return_to_sender(scenario, nft);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = base_registrar::EInvalidImageMessage)]
    fun test_update_image_url_aborts_with_incorrect_expiry_2() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        register(scenario);

        test_scenario::next_tx(scenario, FIRST_USER);
        {
            let registrar = test_scenario::take_shared<BaseRegistrar>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(scenario);

            let ctx = tx_context::new(
                FIRST_USER,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                10,
                0
            );
            base_registrar::update_image_url(
                &mut registrar,
                &config,
                &mut nft,
                x"b7b041efd085fca2c51390c7b14a7435c03e34108db6fe246042122afdc2eb2c4c1854ef36648687caa544824430789b46600ba1b3f825238c0dc51398be470c",
                x"94d2dee8cbd671f216dea04e603f48372ff53be37903db078ecc2a359489d74f",
                b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,000000000000000000000000000000000000b001,0,12323",
                &mut ctx
            );
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(config);
            test_scenario::return_to_sender(scenario, nft);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = base_registrar::EInvalidImageMessage)]
    fun test_update_image_url_aborts_with_incorrect_expiry_3() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        register(scenario);

        test_scenario::next_tx(scenario, FIRST_USER);
        {
            let registrar = test_scenario::take_shared<BaseRegistrar>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(scenario);

            let ctx = tx_context::new(
                FIRST_USER,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                10,
                0
            );
            base_registrar::update_image_url(
                &mut registrar,
                &config,
                &mut nft,
                x"b809099a3de92d522bee0c5b7d99b83c9a00655a2ac7a7362b565e01746fa086774d196101fdadaee4116c0e0e1a0b41fa4ca82a38704f6b7c80f329dba67544",
                x"f19357bae95101a5cac9e88b28b8e46984d7d49bc999ccbe1c1e00ba5ee84ef1",
                b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,000000000000000000000000000000000000b001,100,020",
                &mut ctx
            );
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(config);
            test_scenario::return_to_sender(scenario, nft);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = base_registrar::EInvalidImageMessage)]
    fun test_update_image_url_aborts_with_incorrect_owner() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        register(scenario);

        test_scenario::next_tx(scenario, FIRST_USER);
        {
            let registrar = test_scenario::take_shared<BaseRegistrar>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(scenario);

            let ctx = tx_context::new(
                FIRST_USER,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                10,
                0
            );
            let signature = x"e9e1685a4f0c0ef26c4425705ca9e7828ef0c42ad2a5e563e83d109d1fafd9d10106131af6bae1d69c0d7669cac7da85839f536d7a7d9e467136f308927a7312";
            base_registrar::update_image_url(
                &mut registrar,
                &config,
                &mut nft,
                signature,
                x"849fdf5caead3e290f4adf2db7968fb5c5e0686a14a75f8da6e48292fd73a10e",
                b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,000000000000000000000000000000000000b002,375",
                &mut ctx
            );
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(config);
            test_scenario::return_to_sender(scenario, nft);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = base_registrar::EInvalidImageMessage)]
    fun test_update_image_url_aborts_with_incorrect_owner_2() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        register(scenario);

        test_scenario::next_tx(scenario, FIRST_USER);
        {
            let registrar = test_scenario::take_shared<BaseRegistrar>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(scenario);

            let ctx = tx_context::new(
                FIRST_USER,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                10,
                0
            );
            let signature = x"05c15ea13b1f91cb4aed4fdd288e61d58d49392f4a12ccbdc4e0ff0c262559250315f37eec7f0b39b6bdd01d40ae9c130b4efbf6136d6ed35d2038b184ee3d2c";
            base_registrar::update_image_url(
                &mut registrar,
                &config,
                &mut nft,
                signature,
                x"92c9867de4f4961482b7ca66e19141e641d193f56d244e4403f1335b37b67891",
                    b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,b001,375",
                &mut ctx
            );
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(config);
            test_scenario::return_to_sender(scenario, nft);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = base_registrar::ESignatureNotMatch)]
    fun test_update_image_url_aborts_with_incorrect_signature() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        register(scenario);

        test_scenario::next_tx(scenario, FIRST_USER);
        {
            let registrar = test_scenario::take_shared<BaseRegistrar>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(scenario);

            let ctx = tx_context::new(
                FIRST_USER,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                10,
                0
            );
            let signature = x"6aab992032d59442c5418c3f5b29db45518b40a3d76f1b396b70c902b557e93b206b0ce9ab84ce44277d84055da9dd10ff77c490ba8473cd86ead37be874b9662f";
            base_registrar::update_image_url(
                &mut registrar,
                &config,
                &mut nft,
                signature,
                x"127552ffa7fb7c3718ee61851c49eba03ef7d0dc0933c7c5802cdd98226f6006",
                b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,000000000000000000000000000000000000b001,375",
                &mut ctx
            );
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(config);
            test_scenario::return_to_sender(scenario, nft);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = base_registrar::EHashedMessageNotMatch)]
    fun test_update_image_url_aborts_with_incorrect_hashed_message() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        register(scenario);

        test_scenario::next_tx(scenario, FIRST_USER);
        {
            let registrar = test_scenario::take_shared<BaseRegistrar>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(scenario);

            let ctx = tx_context::new(
                FIRST_USER,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                10,
                0
            );
            base_registrar::update_image_url(
                &mut registrar,
                &config,
                &mut nft,
                x"6aab9920d59442c5478c3f5b29db45518b40a3d76f1b396b70c902b557e93b206b0ce9ab84ce44277d84055da9dd10ff77c490ba8473cd86ead37be874b9662f",
                x"127552ffa7f12b7c3718ee61851c49eba03ef7d0dc0923c7c5802cdd98226f6006",
                b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,000000000000000000000000000000000000b001,375",
                &mut ctx
            );
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(config);
            test_scenario::return_to_sender(scenario, nft);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = base_registrar::EInvalidImageMessage)]
    fun test_update_image_url_aborts_with_empty_signature() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        register(scenario);

        test_scenario::next_tx(scenario, FIRST_USER);
        {
            let registrar = test_scenario::take_shared<BaseRegistrar>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(scenario);

            let ctx = tx_context::new(
                FIRST_USER,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                10,
                0
            );
            base_registrar::update_image_url(
                &mut registrar,
                &config,
                &mut nft,
                x"",
                x"3431f0a9e0fe14c885766842f37b43b774e60dbd96f8502cc327e1ac20d06257",
                b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,000000000000000000000000000000000000b001,475",
                &mut ctx
            );
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(config);
            test_scenario::return_to_sender(scenario, nft);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = base_registrar::EInvalidImageMessage)]
    fun test_update_image_url_aborts_with_empty_hashed_msg() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        register(scenario);

        test_scenario::next_tx(scenario, FIRST_USER);
        {
            let registrar = test_scenario::take_shared<BaseRegistrar>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(scenario);

            let ctx = tx_context::new(
                FIRST_USER,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                10,
                0
            );
            base_registrar::update_image_url(
                &mut registrar,
                &config,
                &mut nft,
                x"6aab9920d59442c5478c3f5b29db45518b40a3d76f1b396b70c902b557e93b206b0ce9ab84ce44277d84055da9dd10ff77c490ba8473cd86ead37be874b9662f",
                x"",
                b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,000000000000000000000000000000000000b001,475",
                &mut ctx
            );
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(config);
            test_scenario::return_to_sender(scenario, nft);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = base_registrar::EInvalidImageMessage)]
    fun test_update_image_url_aborts_with_empty_raw_msg() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        register(scenario);

        test_scenario::next_tx(scenario, FIRST_USER);
        {
            let registrar = test_scenario::take_shared<BaseRegistrar>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(scenario);

            let ctx = tx_context::new(
                FIRST_USER,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                10,
                0
            );
            base_registrar::update_image_url(
                &mut registrar,
                &config,
                &mut nft,
                x"6aab9920d59442c5478c3f5b29db45518b40a3d76f1b396b70c902b557e93b206b0ce9ab84ce44277d84055da9dd10ff77c490ba8473cd86ead37be874b9662f",
                x"3431f0a9e0fe14c885766842f37b43b774e60dbd96f8502cc327e1ac20d06257",
                b"",
                &mut ctx
            );
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(config);
            test_scenario::return_to_sender(scenario, nft);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_register_with_image() {
        let scenario = test_init();
        register_with_image(
            &mut scenario,
            x"acba9ddee8ee59cdbdf00cc67d3b9c7edea4dd438da6eb14a4e6f4e4092acf6f7ccd4227dde6fc47c446fa3223ff7c236ef66ec63d88ecb8b8abc1dda76a808c",
            x"63051bdac22fbebcebb1ff3bf7bd9f1bb6bc5b318b47688d7eab9c4753eee4c3",
            b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,eastagile.sui,375,375",
        );
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = base_registrar::ESignatureNotMatch)]
    fun test_register_with_image_aborts_with_incorrect_signature() {
        let scenario = test_init();
        register_with_image(
            &mut scenario,
            x"5d15c178ed2ba9aa8f31d014bfafbf891452d5688cd8361de8c8e41b5dfd9a3b4508b9dedfe8e7ca5db686d61e382f596dcd037e0adbf459898686852ec7680a",
            x"ed22c86bed41e4bafc4f7dfd4b7061ec50b8b920cf319820325656d95b134298",
            b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,000000000000000000000000000000000000b001,375,zzzz",
        );
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = base_registrar::EHashedMessageNotMatch)]
    fun test_register_with_image_aborts_with_incorrect_hash_msg() {
        let scenario = test_init();
        register_with_image(
            &mut scenario,
            x"6aab9920d59442c5478c3f5b29db45518b40a3d76f1b396b70c902b557e93b206b0ce9ab84ce44277d84055da9dd10ff77c490ba8473cd86ead37be874b9662f",
            x"127552ff17fb7c3718ee61851c49eba03ef7d0dc0933c7c5802cdd98226f6006",
            b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,000000000000000000000000000000000000b001,375",
        );
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = base_registrar::EInvalidImageMessage)]
    fun test_register_with_image_aborts_with_incorrect_owner() {
        let scenario = test_init();
        register_with_image(
            &mut scenario,
            x"654f29638be12f65e7ab956e6b7a853fe251fdd906fd26a85e7c2c0a3c818d733e4f28daad7237dc44a874cd03580b23e0b1df237790adcb32c6a24d061211a3",
            x"dbb83d406751dab7a0d674454dcdf5622eda7a81093581c174c8d52f91a75273",
            b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,000000000000000000000000000000000000b002,375,owner",
        );
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = base_registrar::EInvalidImageMessage)]
    fun test_register_with_image_aborts_with_incorrect_owner_2() {
        let scenario = test_init();
        register_with_image(
            &mut scenario,
            x"53a7a61b7ed28b790c59394df858b95759687c2ce5f333e8bb2cb389753c48e5286c827aa6135ddfef84a14419afb3b9fb2138cd85d0131e29089afadbb91e81",
            x"7019634e1149b310540db5256748f5428f45f0030b87f078fb9a7f7874fedadb",
            b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,00000000000000000000000b001,375,QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k",
        );

        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = base_registrar::EInvalidImageMessage)]
    fun test_register_with_image_aborts_with_incorrect_expiry() {
        let scenario = test_init();
        register_with_image(
            &mut scenario,
            x"b85a85727edfce141b6e3e9a1aceb0d3b4e82e553a96b321f8af8038f77a9d943756be43355faa81c674c2ab319a2d4df38eccf6e20a5b4e58cc03c7df080adf",
            x"e07a64047259b2ab6cab9be81bea78817f28304faf517e1f59581cf705ef22ce",
            b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,000000000000000000000000000000000000b001,475,500",
        );
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = base_registrar::EInvalidImageMessage)]
    fun test_register_with_image_aborts_with_incorrect_expiry_2() {
        let scenario = test_init();
        register_with_image(
            &mut scenario,
            x"dc9abf416a15e326ba98759e729ba883b9e340a4b6a3a2482e6b5611301d8207173eb825019fd2716bb5a3273a546d5d8db6b5ddfadbd8ce13700b38991e391c",
            x"0b772ef9ced4f7f3ad69ec3e481531b7308900c540c9c64f5519af00dd9d9058",
            b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,000000000000000000000000000000000000b001,0,aaaa",
        );
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = base_registrar::ENFTExpired)]
    fun test_update_image_url_aborts_if_nft_expired() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        register(scenario);

        test_scenario::next_tx(scenario, FIRST_USER);
        {
            let registrar = test_scenario::take_shared<BaseRegistrar>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(scenario);

            let ctx = tx_context::new(
                FIRST_USER,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                500,
                0
            );
            base_registrar::update_image_url(
                &mut registrar,
                &config,
                &mut nft,
                x"b85eceafd8685ce006f9ec4f93ca5ffccc125b8720816a6f811cb72039a201870d07b4fa2bbbe1bd8d6e43550eaceda9ce9291535a90435784dbdd31f88d6d84",
                x"88ef894aa6ed87392968c14d3287781517f3bf921b0bafb7e0cd54170b4d8f91",
                b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,000000000000000000000000000000000000b001,375,000000000000000000000000000000000000b001",
                &mut ctx
            );
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(config);
            test_scenario::return_to_sender(scenario, nft);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = base_registrar::ENFTExpired)]
    fun test_update_image_url_aborts_if_nft_expired_2() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        register(scenario);

        test_scenario::next_tx(scenario, FIRST_USER);
        {
            let registrar = test_scenario::take_shared<BaseRegistrar>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(scenario);

            let ctx = tx_context::new(
                FIRST_USER,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                500,
                0
            );
            let signature = x"35fe21d14e11f1df853296a6d3002216a88f1a92a369f85b8ac42e78b2e72f680ab249f808a758a5b0f104a62755f44f212225998fc1368130f6a25270e5cefe";

            base_registrar::update_image_url(
                &mut registrar,
                &config,
                &mut nft,
                signature,
                x"73f028f35491f06b3daa0fde10b4f408f3d61f293467a6267c700828a0f9750d",
                b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,eastagile.sui,675",
                &mut ctx
            );
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(config);
            test_scenario::return_to_sender(scenario, nft);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = base_registrar::ENFTExpired)]
    fun test_update_image_url_aborts_if_previous_owner_uses_hashed_msg_of_new_owner() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        register(scenario);

        test_scenario::next_tx(scenario, SECOND_USER);
        {
            let registry = test_scenario::take_shared<Registry>(scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(scenario);
            let image = test_scenario::take_shared<Configuration>(scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                530,
                10
            );

            base_registrar::register(
                &mut registrar,
                &mut registry,
                &image,
                FIRST_LABEL,
                SECOND_USER,
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
            let registrar = test_scenario::take_shared<BaseRegistrar>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(scenario);

            let ctx = tx_context::new(
                FIRST_USER,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                600,
                0
            );

            base_registrar::update_image_url(
                &mut registrar,
                &config,
                &mut nft,
                x"868d254e6ed4599a3c1bb93492008d2c8995233a02136c88a5f52b606383a7f46b1b4a83f9bf155852fd7e393421131d4b3ef9e5f8a02fd79c4c8a9b37bf67d7",
                x"3fc956b60da3d565cee6c7cc66efa0034bb32ef777b40982191e34b9c76191d8",
                b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,eastagile.sui,895",
                &mut ctx
            );
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(config);
            test_scenario::return_to_sender(scenario, nft);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_update_image_url_works_if_being_called_by_new_owner() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        register(scenario);

        test_scenario::next_tx(scenario, SECOND_USER);
        {
            let registry = test_scenario::take_shared<Registry>(scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(scenario);
            let image = test_scenario::take_shared<Configuration>(scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                530,
                10
            );

            base_registrar::register(
                &mut registrar,
                &mut registry,
                &image,
                FIRST_LABEL,
                SECOND_USER,
                365,
                FIRST_RESOLVER,
                &mut ctx
            );
            test_scenario::return_shared(registry);
            test_scenario::return_shared(image);
            test_scenario::return_shared(registrar);
        };
        test_scenario::next_tx(scenario, SECOND_USER);
        {
            let registrar = test_scenario::take_shared<BaseRegistrar>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(scenario);

            let ctx = tx_context::new(
                SECOND_USER,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                600,
                0
            );

            base_registrar::update_image_url(
                &mut registrar,
                &config,
                &mut nft,
                x"868d254e6ed4599a3c1bb93492008d2c8995233a02136c88a5f52b606383a7f46b1b4a83f9bf155852fd7e393421131d4b3ef9e5f8a02fd79c4c8a9b37bf67d7",
                x"3fc956b60da3d565cee6c7cc66efa0034bb32ef777b40982191e34b9c76191d8",
                b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,eastagile.sui,895",
                &mut ctx,
            );
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(config);
            test_scenario::return_to_sender(scenario, nft);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_update_image_url_works_if_user_has_2_nfts_same_domain_and_uses_valid_one() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        register(scenario);

        test_scenario::next_tx(scenario, FIRST_USER);
        {
            let registry = test_scenario::take_shared<Registry>(scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(scenario);
            let image = test_scenario::take_shared<Configuration>(scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                530,
                10
            );

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
            let registrar = test_scenario::take_shared<BaseRegistrar>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let new_nft = test_scenario::take_from_sender<RegistrationNFT>(scenario);
            let old_nft = test_scenario::take_from_sender<RegistrationNFT>(scenario);
            let ctx = tx_context::new(
                FIRST_USER,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                600,
                0
            );

            base_registrar::update_image_url(
                &mut registrar,
                &config,
                &mut new_nft,
                x"868d254e6ed4599a3c1bb93492008d2c8995233a02136c88a5f52b606383a7f46b1b4a83f9bf155852fd7e393421131d4b3ef9e5f8a02fd79c4c8a9b37bf67d7",
                x"3fc956b60da3d565cee6c7cc66efa0034bb32ef777b40982191e34b9c76191d8",
                b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,eastagile.sui,895",
                &mut ctx
            );
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(config);
            test_scenario::return_to_sender(scenario, old_nft);
            test_scenario::return_to_sender(scenario, new_nft);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = base_registrar::ENFTExpired)]
    fun test_update_image_url_works_if_user_has_2_nfts_same_domain_and_uses_expired_one() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        register(scenario);

        test_scenario::next_tx(scenario, FIRST_USER);
        {
            let registry = test_scenario::take_shared<Registry>(scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(scenario);
            let image = test_scenario::take_shared<Configuration>(scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                530,
                10
            );

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
            let registrar = test_scenario::take_shared<BaseRegistrar>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let new_nft = test_scenario::take_from_sender<RegistrationNFT>(scenario);
            let old_nft = test_scenario::take_from_sender<RegistrationNFT>(scenario);
            let ctx = tx_context::new(
                FIRST_USER,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                600,
                0
            );

            base_registrar::update_image_url(
                &mut registrar,
                &config,
                &mut old_nft,
                x"868d254e6ed4599a3c1bb93492008d2c8995233a02136c88a5f52b606383a7f46b1b4a83f9bf155852fd7e393421131d4b3ef9e5f8a02fd79c4c8a9b37bf67d7",
                x"3fc956b60da3d565cee6c7cc66efa0034bb32ef777b40982191e34b9c76191d8",
                b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,eastagile.sui,895",
                &mut ctx
            );
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(config);
            test_scenario::return_to_sender(scenario, old_nft);
            test_scenario::return_to_sender(scenario, new_nft);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_update_image_url_works_if_user_owns_2_nfts_different_domains_and_uses_right_one() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        register(scenario);

        test_scenario::next_tx(scenario, FIRST_USER);
        {
            let registry = test_scenario::take_shared<Registry>(scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(scenario);
            let image = test_scenario::take_shared<Configuration>(scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                30,
                10
            );

            base_registrar::register(
                &mut registrar,
                &mut registry,
                &image,
                THIRD_LABEL,
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
            let registrar = test_scenario::take_shared<BaseRegistrar>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let second_nft = test_scenario::take_from_sender<RegistrationNFT>(scenario);
            let first_nft = test_scenario::take_from_sender<RegistrationNFT>(scenario);
            let ctx = tx_context::new(
                FIRST_USER,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                50,
                0
            );

            base_registrar::update_image_url(
                &mut registrar,
                &config,
                &mut first_nft,
                x"1750ce9c94af251d3288589b4e98369ee09a41530b42f545eab96763ecbaa8b941f0a814e7440eacd803c507633825ca1f70dc9018b59cb3e49871ca6ddcf704",
                x"c9cbb723ef1dce214552f05378404491ce9cb36429df9ca307b1619268f09335",
                b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,eastagile.sui,375",
                &mut ctx
            );
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(config);
            test_scenario::return_to_sender(scenario, first_nft);
            test_scenario::return_to_sender(scenario, second_nft);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = base_registrar::EInvalidImageMessage)]
    fun test_update_image_url_works_if_user_owns_2_nfts_and_uses_wrong_one() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        register(scenario);

        test_scenario::next_tx(scenario, FIRST_USER);
        {
            let registry = test_scenario::take_shared<Registry>(scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(scenario);
            let image = test_scenario::take_shared<Configuration>(scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                30,
                10
            );

            base_registrar::register(
                &mut registrar,
                &mut registry,
                &image,
                THIRD_LABEL,
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
            let registrar = test_scenario::take_shared<BaseRegistrar>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let second_nft = test_scenario::take_from_sender<RegistrationNFT>(scenario);
            let first_nft = test_scenario::take_from_sender<RegistrationNFT>(scenario);
            let ctx = tx_context::new(
                FIRST_USER,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                50,
                0
            );

            base_registrar::update_image_url(
                &mut registrar,
                &config,
                &mut second_nft,
                x"1750ce9c94af251d3288589b4e98369ee09a41530b42f545eab96763ecbaa8b941f0a814e7440eacd803c507633825ca1f70dc9018b59cb3e49871ca6ddcf704",
                x"c9cbb723ef1dce214552f05378404491ce9cb36429df9ca307b1619268f09335",
                b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,eastagile.sui,375",
                &mut ctx
            );
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(config);
            test_scenario::return_to_sender(scenario, first_nft);
            test_scenario::return_to_sender(scenario, second_nft);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_reclaim_works_if_user_has_2_nfts_of_same_domains_and_uses_new_one() {
        let scenario = test_init();
        register(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let image = test_scenario::take_shared<Configuration>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                466,
                10
            );

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

        test_scenario::next_tx(&mut scenario, FIRST_USER);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let new_nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let old_nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);

            base_registrar::reclaim_name(
                &registrar,
                &mut registry,
                &new_nft,
                SECOND_USER,
                test_scenario::ctx(&mut scenario)
            );

            test_scenario::return_to_sender(&mut scenario, new_nft);
            test_scenario::return_to_sender(&mut scenario, old_nft);
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

    #[test, expected_failure(abort_code = base_registrar::ENFTExpired)]
    fun test_reclaim_aborts_if_user_has_2_nfts_of_same_domains_and_uses_old_one() {
        let scenario = test_init();
        register(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let image = test_scenario::take_shared<Configuration>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                466,
                10
            );

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

        test_scenario::next_tx(&mut scenario, FIRST_USER);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let new_nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let old_nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);

            base_registrar::reclaim_name(
                &registrar,
                &mut registry,
                &old_nft,
                SECOND_USER,
                test_scenario::ctx(&mut scenario)
            );

            test_scenario::return_to_sender(&mut scenario, new_nft);
            test_scenario::return_to_sender(&mut scenario, old_nft);
            test_scenario::return_shared(registry);
            test_scenario::return_shared(registrar);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_reclaim_works_if_being_called_by_new_owner() {
        let scenario = test_init();
        register(&mut scenario);
        test_scenario::next_tx(&mut scenario, SECOND_USER);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let image = test_scenario::take_shared<Configuration>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                466,
                20
            );

            base_registrar::register(
                &mut registrar,
                &mut registry,
                &image,
                FIRST_LABEL,
                SECOND_USER,
                365,
                FIRST_RESOLVER,
                &mut ctx
            );
            test_scenario::return_shared(registry);
            test_scenario::return_shared(image);
            test_scenario::return_shared(registrar);
        };

        test_scenario::next_tx(&mut scenario, SECOND_USER);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);

            base_registrar::reclaim_name(
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

    #[test, expected_failure(abort_code = base_registrar::ENFTExpired)]
    fun test_reclaim_works_if_being_called_by_old_owner() {
        let scenario = test_init();
        register(&mut scenario);
        test_scenario::next_tx(&mut scenario, SECOND_USER);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let image = test_scenario::take_shared<Configuration>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                466,
                20
            );

            base_registrar::register(
                &mut registrar,
                &mut registry,
                &image,
                FIRST_LABEL,
                SECOND_USER,
                365,
                FIRST_RESOLVER,
                &mut ctx
            );
            test_scenario::return_shared(registry);
            test_scenario::return_shared(image);
            test_scenario::return_shared(registrar);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER);
        {
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);

            base_registrar::reclaim_name(
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
        test_scenario::end(scenario);
    }
}
