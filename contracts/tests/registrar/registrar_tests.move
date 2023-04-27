#[test_only]
module suins::registrar_tests {

    use sui::test_scenario::{Self, Scenario};
    use sui::url;
    use sui::dynamic_field;
    use suins::entity::{Self, SuiNS};
    use suins::registry::{Self, AdminCap};
    use suins::registrar::{Self, RegistrationNFT, get_record_expired_at, assert_registrar_exists};
    use suins::configuration::{Self, Configuration};
    use std::string::{Self, utf8};
    use suins::auction_tests::ctx_new;

    const SUINS_ADDRESS: address = @0xA001;
    const FIRST_USER: address = @0xB001;
    const SECOND_USER: address = @0xB002;
    const FIRST_LABEL: vector<u8> = b"eastagile";
    const FIRST_DOMAIN_NAME: vector<u8> = b"eastagile.sui";
    const SECOND_LABEL: vector<u8> = b"ea";
    const THIRD_LABEL: vector<u8> = b"eastagil";
    const MOVE_REGISTRAR: vector<u8> = b"move";
    const SUI_REGISTRAR: vector<u8> = b"sui";

    fun test_init(): Scenario {
        let scenario = test_scenario::begin(SUINS_ADDRESS);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            registry::test_init(ctx);
            entity::test_init(ctx);
            configuration::test_init(ctx);
        };
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            registrar::new_tld(&admin_cap, &mut suins, utf8(MOVE_REGISTRAR), test_scenario::ctx(&mut scenario));
            registrar::new_tld(&admin_cap, &mut suins, utf8(SUI_REGISTRAR), test_scenario::ctx(&mut scenario));
            configuration::set_public_key(
                &admin_cap,
                &mut config,
                x"0445e28df251d0ec0f66f284f7d5598db7e68b1a196396e4e13a3942d1364812ae5ed65ebb3d20cbf073ad50c6bbafa92505dc9b306e30476e57919a63ac824cab"
            );
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
            test_scenario::return_to_sender(&mut scenario, admin_cap);
        };
        scenario
    }

    fun register(scenario: &mut Scenario) {
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let image = test_scenario::take_shared<Configuration>(scenario);
            let ctx = ctx_new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                10,
                0
            );

            registrar::register_with_image_internal(
                &mut suins,
                utf8(SUI_REGISTRAR),
                &image,
                utf8(FIRST_LABEL),
                FIRST_USER,
                365,
                vector[],
                vector[],
                vector[],
                &mut ctx
            );
            test_scenario::return_shared(suins);
            test_scenario::return_shared(image);
        };

        test_scenario::next_tx(scenario, FIRST_USER);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            registrar::assert_registrar_exists(&suins, SUI_REGISTRAR);
            let expired_at = get_record_expired_at(&suins, SUI_REGISTRAR, FIRST_LABEL);

            assert!(expired_at == 10 + 365, 0);

            let (name, url) = registrar::get_nft_fields(&nft);
            assert!(name == utf8(FIRST_DOMAIN_NAME), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );

            let (owner, linked_addr, ttl, name) = registry::get_name_record_all_fields(&suins, utf8(FIRST_DOMAIN_NAME));

            assert!(owner == FIRST_USER, 0);
            assert!(linked_addr == FIRST_USER, 0);
            assert!(ttl == 0, 0);
            assert!(name == utf8(b""), 0);
            test_scenario::return_to_sender(scenario, nft);
            test_scenario::return_shared(suins);
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
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let image = test_scenario::take_shared<Configuration>(scenario);
            let ctx = ctx_new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                10,
                0
            );

            registrar::register_with_image_internal(
                &mut suins,
                utf8(SUI_REGISTRAR),
                &image,
                utf8(FIRST_LABEL),
                FIRST_USER,
                365,
                signature,
                hashed_msg,
                raw_msg,
                &mut ctx
            );
            test_scenario::return_shared(suins);
            test_scenario::return_shared(image);
        };

        test_scenario::next_tx(scenario, FIRST_USER);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let (name, url) = registrar::get_nft_fields(&nft);
            registrar::assert_registrar_exists(&suins, SUI_REGISTRAR);
            let expired_at = get_record_expired_at(&suins, SUI_REGISTRAR, FIRST_LABEL);

            assert!(expired_at == 10 + 365, 0);
            assert!(name == utf8(FIRST_DOMAIN_NAME), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k"),
                0
            );

            let (owner, linked_addr, ttl, name) = registry::get_name_record_all_fields(&suins, utf8(FIRST_DOMAIN_NAME));

            assert!(owner == FIRST_USER, 0);
            assert!(linked_addr == FIRST_USER, 0);
            assert!(ttl == 0, 0);
            assert!(name == utf8(b""), 0);

            test_scenario::return_to_sender(scenario, nft);
            test_scenario::return_shared(suins);
        };
    }

    #[test]
    fun test_register() {
        let scenario = test_init();
        register(&mut scenario);

        // test `available` function
        test_scenario::next_tx(&mut scenario, FIRST_USER);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            let label = utf8(b"eastagile");
            assert!(!registrar::is_available(&suins, utf8(SUI_REGISTRAR), label, test_scenario::ctx(&mut scenario)), 0);

            let label = utf8(b"ea");
            assert!(registrar::is_available(&suins, utf8(SUI_REGISTRAR), label,test_scenario::ctx(&mut scenario)), 0);

            test_scenario::return_shared(suins);
        };

        // test `name_expires` function
        test_scenario::next_tx(&mut scenario, FIRST_USER);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            assert!(registrar::name_expires_at(&suins, utf8(SUI_REGISTRAR), utf8(b"eastagile")) == 10 + 365, 0);
            assert!(registrar::name_expires_at(&suins, utf8(SUI_REGISTRAR), utf8(b"ea")) == 0, 0);

            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registrar::EInvalidDuration)]
    fun test_register_abort_with_zero_duration() {
        let scenario = test_init();
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let image = test_scenario::take_shared<Configuration>(&mut scenario);

            registrar::register_with_image_internal(
                &mut suins,
                utf8(SUI_REGISTRAR),
                &image,
                utf8(FIRST_LABEL),
                FIRST_USER,
                0,
                vector[],
                vector[],
                vector[],
                test_scenario::ctx(&mut scenario)
            );

            test_scenario::return_shared(suins);
            test_scenario::return_shared(image);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registrar::ELabelUnavailable)]
    fun test_register_abort_if_label_unavailable() {
        let scenario = test_init();
        register(&mut scenario);
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let image = test_scenario::take_shared<Configuration>(&mut scenario);
            let ctx = ctx_new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                10,
                10,
            );

            registrar::register_with_image_internal(
                &mut suins,
                utf8(SUI_REGISTRAR),
                &image,
                utf8(FIRST_LABEL),
                FIRST_USER,
                365,
                vector[],
                vector[],
                vector[],
                &mut ctx,
            );

            test_scenario::return_shared(suins);
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
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            assert!(registrar::name_expires_at(&suins, utf8(SUI_REGISTRAR), utf8(FIRST_LABEL)) == 375, 0);
            let new_expired_at = registrar::renew(&mut suins, utf8(SUI_REGISTRAR), utf8(FIRST_LABEL), 100, test_scenario::ctx(&mut scenario));
            assert!(registrar::name_expires_at(&suins, utf8(SUI_REGISTRAR), utf8(FIRST_LABEL)) == 475, 0);
            assert!(new_expired_at == 475, 0);

            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registrar::ELabelNotExists)]
    fun test_renew_abort_if_label_not_exists() {
        let scenario = test_init();
        test_scenario::next_tx(&mut scenario, FIRST_USER);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            assert!(registrar::name_expires_at(&suins, utf8(SUI_REGISTRAR), utf8(b"SECOND_LABEL")) == 0, 0);

            registrar::renew(&mut suins, utf8(SUI_REGISTRAR), utf8(SECOND_LABEL), 100, test_scenario::ctx(&mut scenario));
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registrar::ELabelExpired)]
    fun test_renew_abort_if_label_expired() {
        let scenario = test_init();
        register(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let ctx = ctx_new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                500,
                0
            );

            assert!(registrar::name_expires_at(&suins, utf8(SUI_REGISTRAR), utf8(FIRST_LABEL)) == 375, 0);
            registrar::renew(&mut suins, utf8(SUI_REGISTRAR), utf8(FIRST_LABEL), 100, &ctx);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_reclaim_by_nft_owner() {
        let scenario = test_init();
        register(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);

            registrar::reclaim_name(
                &nft,
                &mut suins,
                SECOND_USER,
                test_scenario::ctx(&mut scenario)
            );

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            let owner = registry::owner(&suins, utf8(FIRST_DOMAIN_NAME));
            assert!(SECOND_USER == owner, 0);

            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = dynamic_field::EFieldDoesNotExist)]
    fun test_reclaim_name_by_nft_owner_abort_if_label_not_exists() {
        let scenario = test_init();
        register(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            registrar::set_nft_domain(&mut nft, utf8(b"thisisadomain.sui"));

            registrar::reclaim_name(
                &nft,
                &mut suins,
                SECOND_USER,
                test_scenario::ctx(&mut scenario)
            );

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registrar::ENFTExpired)]
    fun test_reclaim_name_by_nft_owner_abort_if_nft_expired() {
        let scenario = test_init();
        register(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let ctx = ctx_new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                500,
                0
            );

            registrar::reclaim_name(
                &nft,
                &mut suins,
                SECOND_USER,
                &mut ctx,
            );

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_new_tld() {
        let scenario = test_init();

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            registrar::new_tld(
                &admin_cap,
                &mut suins,
                utf8(b"com"),
                test_scenario::ctx(&mut scenario)
            );

            test_scenario::return_shared(suins);
            test_scenario::return_to_sender(&mut scenario, admin_cap);
        };

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            assert_registrar_exists(&suins, b"com");
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let image = test_scenario::take_shared<Configuration>(&mut scenario);

            registrar::register_with_image_internal(
                &mut suins,
                utf8(b"com"),
                &image,
                utf8(FIRST_LABEL),
                FIRST_USER,
                365,
                vector[],
                vector[],
                vector[],
                test_scenario::ctx(&mut scenario)
            );
            test_scenario::return_shared(suins);
            test_scenario::return_shared(image);
        };

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            registrar::assert_registrar_exists(&suins, b"com");

            let expired_at = get_record_expired_at(&suins, b"com", FIRST_LABEL);
            assert!(expired_at == 365, 0);

            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = dynamic_field::EFieldAlreadyExists)]
    fun test_new_tld_abort_with_duplicated_tld() {
        let scenario = test_init();

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            registrar::new_tld(
                &admin_cap,
                &mut suins,
                utf8(b"sui"),
                test_scenario::ctx(&mut scenario)
            );

            test_scenario::return_to_sender(&mut scenario, admin_cap);
            test_scenario::return_shared(suins);
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
            let (name, url) = registrar::get_nft_fields(&nft);

            assert!(name == utf8(FIRST_DOMAIN_NAME), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );
            test_scenario::return_to_sender(scenario, nft);
        };

        test_scenario::next_tx(scenario, FIRST_USER);
        {
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(scenario);
            let ctx = ctx_new(
                FIRST_USER,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                10,
                0
            );

            registrar::update_image_url(
                &mut suins,
                &config,
                &mut nft,
                x"e041acf25defbb7dd21a7e016eb9e729597eb1cdc3bba31492f5345143ad0d3f7a1e6362ca1ed9902af5600ab08a4fece9125847402ad4b3c2c9298eca436bd5",
                x"48edd2317fd8150bd29b17eaa8837403295f03092e89f3c28e6ddc88ceef9b72",
                b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,eastagile.sui,375,,,,,,,",
                &mut ctx
            );
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
            test_scenario::return_to_sender(scenario, nft);
        };
        test_scenario::next_tx(scenario, FIRST_USER);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(scenario);
            let (name, url) = registrar::get_nft_fields(&nft);

            assert!(name == utf8(FIRST_DOMAIN_NAME), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k"),
                0
            );
            test_scenario::return_to_sender(scenario, nft);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = registrar::EInvalidImageMessage)]
    fun test_update_image_url_aborts_with_incorrect_expired_at() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        register(scenario);

        test_scenario::next_tx(scenario, FIRST_USER);
        {
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(scenario);

            let ctx = ctx_new(
                FIRST_USER,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                10,
                0
            );
            registrar::update_image_url(
                &mut suins,
                &config,
                &mut nft,
                x"e35de3997a3f9f5614b207f4d7516ca1709e8d46bf2c45ada5ac0383c2939df050859994404b04cdc9f01aa200322b3af6738866347fe50d195b58982d5fa725",
                x"fee40dbc963366e0d1eb8337bf2b491c2b96a6958d56aca077484861ef61cf89",
                b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,000000000000000000000000000000000000b001,475,abcc",
                &mut ctx
            );
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
            test_scenario::return_to_sender(scenario, nft);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = registrar::EInvalidImageMessage)]
    fun test_update_image_url_aborts_with_incorrect_expired_at_2() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        register(scenario);

        test_scenario::next_tx(scenario, FIRST_USER);
        {
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(scenario);

            let ctx = ctx_new(
                FIRST_USER,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                10,
                0
            );
            registrar::update_image_url(
                &mut suins,
                &config,
                &mut nft,
                x"b7b041efd085fca2c51390c7b14a7435c03e34108db6fe246042122afdc2eb2c4c1854ef36648687caa544824430789b46600ba1b3f825238c0dc51398be470c",
                x"94d2dee8cbd671f216dea04e603f48372ff53be37903db078ecc2a359489d74f",
                b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,000000000000000000000000000000000000b001,0,12323",
                &mut ctx
            );
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
            test_scenario::return_to_sender(scenario, nft);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = registrar::EInvalidImageMessage)]
    fun test_update_image_url_aborts_with_incorrect_expired_at_3() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        register(scenario);

        test_scenario::next_tx(scenario, FIRST_USER);
        {
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(scenario);

            let ctx = ctx_new(
                FIRST_USER,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                10,
                0
            );
            registrar::update_image_url(
                &mut suins,
                &config,
                &mut nft,
                x"b809099a3de92d522bee0c5b7d99b83c9a00655a2ac7a7362b565e01746fa086774d196101fdadaee4116c0e0e1a0b41fa4ca82a38704f6b7c80f329dba67544",
                x"f19357bae95101a5cac9e88b28b8e46984d7d49bc999ccbe1c1e00ba5ee84ef1",
                b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,000000000000000000000000000000000000b001,100,020",
                &mut ctx
            );
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
            test_scenario::return_to_sender(scenario, nft);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = registrar::EInvalidImageMessage)]
    fun test_update_image_url_aborts_with_incorrect_owner() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        register(scenario);

        test_scenario::next_tx(scenario, FIRST_USER);
        {
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(scenario);

            let ctx = ctx_new(
                FIRST_USER,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                10,
                0
            );
            registrar::update_image_url(
                &mut suins,
                &config,
                &mut nft,
                x"a72170513be09f7056bbf852aff30e7f2c3fb08b14df517930cd54d3639205fb4703e76db29aebbcce96bcbf29a6807847a56dfc94e862fe0aefd90c865f5c96",
                x"915f955c6b0ecf13650ec6f25acaf136e61bebda53a8805cc33e77775e890a63",
                b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,000000000000000000000000000000000000b002,375,adasdasdsd,",
                &mut ctx
            );
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
            test_scenario::return_to_sender(scenario, nft);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = registrar::EInvalidImageMessage)]
    fun test_update_image_url_aborts_with_incorrect_owner_2() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        register(scenario);

        test_scenario::next_tx(scenario, FIRST_USER);
        {
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(scenario);

            let ctx = ctx_new(
                FIRST_USER,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                10,
                0
            );
            registrar::update_image_url(
                &mut suins,
                &config,
                &mut nft,
                x"8bb0345d636835e8a782afaae4083dbeba33eb0557b6f771263f95c6999e8cee0aea6345454e98a58b3d1d2b2eb90a4b1e0d319ccea196ec47e02cf6698a7b6c",
                x"0ae1392cec5d3773213c4fb351aa755b6ced6387428feb3ac00d350c8914026a",
                    b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,b001,375,1,",
                &mut ctx
            );
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
            test_scenario::return_to_sender(scenario, nft);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = registrar::ESignatureNotMatch)]
    fun test_update_image_url_aborts_with_incorrect_signature() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        register(scenario);

        test_scenario::next_tx(scenario, FIRST_USER);
        {
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(scenario);

            let ctx = ctx_new(
                FIRST_USER,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                10,
                0
            );
            let signature = x"6aab992032d59442c5418c3f5b29db45518b40a3d76f1b396b70c902b557e93b206b0ce9ab84ce44277d84055da9dd10ff77c490ba8473cd86ead37be874b9662f";
            registrar::update_image_url(
                &mut suins,
                &config,
                &mut nft,
                signature,
                x"127552ffa7fb7c3718ee61851c49eba03ef7d0dc0933c7c5802cdd98226f6006",
                b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,000000000000000000000000000000000000b001,375",
                &mut ctx
            );
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
            test_scenario::return_to_sender(scenario, nft);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = registrar::EHashedMessageNotMatch)]
    fun test_update_image_url_aborts_with_incorrect_hashed_message() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        register(scenario);

        test_scenario::next_tx(scenario, FIRST_USER);
        {
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(scenario);

            let ctx = ctx_new(
                FIRST_USER,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                10,
                0
            );
            registrar::update_image_url(
                &mut suins,
                &config,
                &mut nft,
                x"6aab9920d59442c5478c3f5b29db45518b40a3d76f1b396b70c902b557e93b206b0ce9ab84ce44277d84055da9dd10ff77c490ba8473cd86ead37be874b9662f",
                x"127552ffa7f12b7c3718ee61851c49eba03ef7d0dc0923c7c5802cdd98226f6006",
                b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,000000000000000000000000000000000000b001,375",
                &mut ctx
            );
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
            test_scenario::return_to_sender(scenario, nft);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = registrar::EInvalidImageMessage)]
    fun test_update_image_url_aborts_with_empty_signature() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        register(scenario);

        test_scenario::next_tx(scenario, FIRST_USER);
        {
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(scenario);

            let ctx = ctx_new(
                FIRST_USER,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                10,
                0
            );
            registrar::update_image_url(
                &mut suins,
                &config,
                &mut nft,
                x"",
                x"3431f0a9e0fe14c885766842f37b43b774e60dbd96f8502cc327e1ac20d06257",
                b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,000000000000000000000000000000000000b001,475",
                &mut ctx
            );
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
            test_scenario::return_to_sender(scenario, nft);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = registrar::EInvalidImageMessage)]
    fun test_update_image_url_aborts_with_empty_hashed_msg() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        register(scenario);

        test_scenario::next_tx(scenario, FIRST_USER);
        {
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(scenario);

            let ctx = ctx_new(
                FIRST_USER,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                10,
                0
            );
            registrar::update_image_url(
                &mut suins,
                &config,
                &mut nft,
                x"6aab9920d59442c5478c3f5b29db45518b40a3d76f1b396b70c902b557e93b206b0ce9ab84ce44277d84055da9dd10ff77c490ba8473cd86ead37be874b9662f",
                x"",
                b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,000000000000000000000000000000000000b001,475",
                &mut ctx
            );
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
            test_scenario::return_to_sender(scenario, nft);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = registrar::EInvalidImageMessage)]
    fun test_update_image_url_aborts_with_empty_raw_msg() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        register(scenario);

        test_scenario::next_tx(scenario, FIRST_USER);
        {
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(scenario);

            let ctx = ctx_new(
                FIRST_USER,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                10,
                0
            );
            registrar::update_image_url(
                &mut suins,
                &config,
                &mut nft,
                x"6aab9920d59442c5478c3f5b29db45518b40a3d76f1b396b70c902b557e93b206b0ce9ab84ce44277d84055da9dd10ff77c490ba8473cd86ead37be874b9662f",
                x"3431f0a9e0fe14c885766842f37b43b774e60dbd96f8502cc327e1ac20d06257",
                b"",
                &mut ctx
            );
            test_scenario::return_shared(suins);
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

    #[test, expected_failure(abort_code = registrar::ESignatureNotMatch)]
    fun test_register_with_image_aborts_with_incorrect_signature() {
        let scenario = test_init();
        register_with_image(
            &mut scenario,
            x"98f11a9c73c4eba070b0064f21ac9de4cf2db745ce18332ec294d69f7cb0f12e03741eff428df8ed6a35219887eb2b2effbb3cad40b59021c6c311884df48d21",
            x"1ebe7ce341df8b5c1c56ad54af85924b00ffe38a32e7300d73b65005f3d2b4f4",
            b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,eastagile.sui,375,zzzz",
        );
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registrar::EHashedMessageNotMatch)]
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

    #[test, expected_failure(abort_code = registrar::EInvalidImageMessage)]
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

    #[test, expected_failure(abort_code = registrar::EInvalidImageMessage)]
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

    #[test, expected_failure(abort_code = registrar::EInvalidImageMessage)]
    fun test_register_with_image_aborts_with_incorrect_expired_at() {
        let scenario = test_init();
        register_with_image(
            &mut scenario,
            x"b85a85727edfce141b6e3e9a1aceb0d3b4e82e553a96b321f8af8038f77a9d943756be43355faa81c674c2ab319a2d4df38eccf6e20a5b4e58cc03c7df080adf",
            x"e07a64047259b2ab6cab9be81bea78817f28304faf517e1f59581cf705ef22ce",
            b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,000000000000000000000000000000000000b001,475,500",
        );
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registrar::EInvalidImageMessage)]
    fun test_register_with_image_aborts_with_incorrect_expired_at_2() {
        let scenario = test_init();
        register_with_image(
            &mut scenario,
            x"dc9abf416a15e326ba98759e729ba883b9e340a4b6a3a2482e6b5611301d8207173eb825019fd2716bb5a3273a546d5d8db6b5ddfadbd8ce13700b38991e391c",
            x"0b772ef9ced4f7f3ad69ec3e481531b7308900c540c9c64f5519af00dd9d9058",
            b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,000000000000000000000000000000000000b001,0,aaaa",
        );
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registrar::ENFTExpired)]
    fun test_update_image_url_aborts_if_nft_expired() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        register(scenario);

        test_scenario::next_tx(scenario, FIRST_USER);
        {
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(scenario);

            let ctx = ctx_new(
                FIRST_USER,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                500,
                0
            );
            registrar::update_image_url(
                &mut suins,
                &config,
                &mut nft,
                x"b85eceafd8685ce006f9ec4f93ca5ffccc125b8720816a6f811cb72039a201870d07b4fa2bbbe1bd8d6e43550eaceda9ce9291535a90435784dbdd31f88d6d84",
                x"88ef894aa6ed87392968c14d3287781517f3bf921b0bafb7e0cd54170b4d8f91",
                b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,000000000000000000000000000000000000b001,375,000000000000000000000000000000000000b001",
                &mut ctx
            );
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
            test_scenario::return_to_sender(scenario, nft);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = registrar::ENFTExpired)]
    fun test_update_image_url_aborts_if_nft_expired_2() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        register(scenario);

        test_scenario::next_tx(scenario, FIRST_USER);
        {
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(scenario);

            let ctx = ctx_new(
                FIRST_USER,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                500,
                0
            );
            let signature = x"35fe21d14e11f1df853296a6d3002216a88f1a92a369f85b8ac42e78b2e72f680ab249f808a758a5b0f104a62755f44f212225998fc1368130f6a25270e5cefe";

            registrar::update_image_url(
                &mut suins,
                &config,
                &mut nft,
                signature,
                x"73f028f35491f06b3daa0fde10b4f408f3d61f293467a6267c700828a0f9750d",
                b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,eastagile.sui,675",
                &mut ctx
            );
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
            test_scenario::return_to_sender(scenario, nft);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = registrar::ENFTExpired)]
    fun test_update_image_url_aborts_if_previous_owner_uses_hashed_msg_of_new_owner() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        register(scenario);

        test_scenario::next_tx(scenario, SECOND_USER);
        {
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let image = test_scenario::take_shared<Configuration>(scenario);
            let ctx = ctx_new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                530,
                10
            );

            registrar::register_with_image_internal(
                &mut suins,
                utf8(SUI_REGISTRAR),
                &image,
                utf8(FIRST_LABEL),
                SECOND_USER,
                365,
                vector[],
                vector[],
                vector[],
                &mut ctx
            );
            test_scenario::return_shared(suins);
            test_scenario::return_shared(image);
        };
        test_scenario::next_tx(scenario, FIRST_USER);
        {
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(scenario);

            let ctx = ctx_new(
                FIRST_USER,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                600,
                0
            );

            registrar::update_image_url(
                &mut suins,
                &config,
                &mut nft,
                x"868d254e6ed4599a3c1bb93492008d2c8995233a02136c88a5f52b606383a7f46b1b4a83f9bf155852fd7e393421131d4b3ef9e5f8a02fd79c4c8a9b37bf67d7",
                x"3fc956b60da3d565cee6c7cc66efa0034bb32ef777b40982191e34b9c76191d8",
                b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,eastagile.sui,895",
                &mut ctx
            );
            test_scenario::return_shared(suins);
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
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let image = test_scenario::take_shared<Configuration>(scenario);
            let ctx = ctx_new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                530,
                10
            );

            registrar::register_with_image_internal(
                &mut suins,
                utf8(SUI_REGISTRAR),
                &image,
                utf8(FIRST_LABEL),
                SECOND_USER,
                365,
                vector[],
                vector[],
                vector[],
                &mut ctx
            );
            test_scenario::return_shared(suins);
            test_scenario::return_shared(image);
        };
        test_scenario::next_tx(scenario, SECOND_USER);
        {
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(scenario);

            let ctx = ctx_new(
                SECOND_USER,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                600,
                0
            );

            registrar::update_image_url(
                &mut suins,
                &config,
                &mut nft,
                x"4f23a349f88e07b26b246fb34e81983c3ce70e8e2c82ce217e433ed7baf2d7152685b713318839cc092e8bd38807a8531196ada8c2502103852381ecd763e91e",
                x"4367073bdc58860b472e5381074b3691ef9aec24ac9b82a615922bf98b3a64ec",
                b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,eastagile.sui,895,QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k",
                &mut ctx,
            );
            test_scenario::return_shared(suins);
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
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let image = test_scenario::take_shared<Configuration>(scenario);
            let ctx = ctx_new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                530,
                10
            );

            registrar::register_with_image_internal(
                &mut suins,
                utf8(SUI_REGISTRAR),
                &image,
                utf8(FIRST_LABEL),
                FIRST_USER,
                365,
                vector[],
                vector[],
                vector[],
                &mut ctx
            );
            test_scenario::return_shared(suins);
            test_scenario::return_shared(image);
        };
        test_scenario::next_tx(scenario, FIRST_USER);
        {
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let new_nft = test_scenario::take_from_sender<RegistrationNFT>(scenario);
            let old_nft = test_scenario::take_from_sender<RegistrationNFT>(scenario);
            let ctx = ctx_new(
                FIRST_USER,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                600,
                0
            );

            registrar::update_image_url(
                &mut suins,
                &config,
                &mut new_nft,
                x"5f786520119ea7e0c73e95d779f2a0d8e686101d52dfa83818fa1b8cb2d3ec796c7215479bc9c089818d1b5587e86f3d85ebf151eb7c1d2523646c6593f648dd",
                x"5e37331f6d756fe9df668a8a6f2ead1e121a6f5f35f4c5c7dfd9cd06a5b268dd",
                b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,eastagile.sui,895,aaaaz",
                &mut ctx
            );
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
            test_scenario::return_to_sender(scenario, old_nft);
            test_scenario::return_to_sender(scenario, new_nft);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = registrar::ENFTExpired)]
    fun test_update_image_url_works_if_user_has_2_nfts_same_domain_and_uses_expired_one() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        register(scenario);

        test_scenario::next_tx(scenario, FIRST_USER);
        {
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let image = test_scenario::take_shared<Configuration>(scenario);
            let ctx = ctx_new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                530,
                10
            );

            registrar::register_with_image_internal(
                &mut suins,
                utf8(SUI_REGISTRAR),
                &image,
                utf8(FIRST_LABEL),
                FIRST_USER,
                365,
                vector[],
                vector[],
                vector[],
                &mut ctx
            );
            test_scenario::return_shared(suins);
            test_scenario::return_shared(image);
        };
        test_scenario::next_tx(scenario, FIRST_USER);
        {
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let new_nft = test_scenario::take_from_sender<RegistrationNFT>(scenario);
            let old_nft = test_scenario::take_from_sender<RegistrationNFT>(scenario);
            let ctx = ctx_new(
                FIRST_USER,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                600,
                0
            );

            registrar::update_image_url(
                &mut suins,
                &config,
                &mut old_nft,
                x"868d254e6ed4599a3c1bb93492008d2c8995233a02136c88a5f52b606383a7f46b1b4a83f9bf155852fd7e393421131d4b3ef9e5f8a02fd79c4c8a9b37bf67d7",
                x"3fc956b60da3d565cee6c7cc66efa0034bb32ef777b40982191e34b9c76191d8",
                b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,eastagile.sui,895",
                &mut ctx
            );
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
            test_scenario::return_to_sender(scenario, old_nft);
            test_scenario::return_to_sender(scenario, new_nft);
        };
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_update_image_url_works_if_user_owns_2_different_nft_domains_and_uses_right_one() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        register(scenario);

        test_scenario::next_tx(scenario, FIRST_USER);
        {
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let image = test_scenario::take_shared<Configuration>(scenario);
            let ctx = ctx_new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                30,
                10
            );

            registrar::register_with_image_internal(
                &mut suins,
                utf8(SUI_REGISTRAR),
                &image,
                utf8(THIRD_LABEL),
                FIRST_USER,
                365,
                vector[],
                vector[],
                vector[],
                &mut ctx
            );
            test_scenario::return_shared(suins);
            test_scenario::return_shared(image);
        };
        test_scenario::next_tx(scenario, FIRST_USER);
        {
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let second_nft = test_scenario::take_from_sender<RegistrationNFT>(scenario);
            let first_nft = test_scenario::take_from_sender<RegistrationNFT>(scenario);
            let ctx = ctx_new(
                FIRST_USER,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                50,
                0
            );

            registrar::update_image_url(
                &mut suins,
                &config,
                &mut first_nft,
                x"09aedbb41c34fcf9d085667d1aeb650d7dedf7a99d4ef7394b0f9d79b66ce6294f14ccc0a0dc09f14d107c0ba3c76a134763098d1aae2a95df041e421678ffd8",
                x"9a31f44c103a90bb61da20d92c47ee09fb46f0bca2e4c0cbc73de2b5fb1f66eb",
                b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,eastagile.sui,375,zz123asd-asd",
                &mut ctx
            );
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
            test_scenario::return_to_sender(scenario, first_nft);
            test_scenario::return_to_sender(scenario, second_nft);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = string::EINVALID_INDEX)]
    fun test_update_image_url_aborts_if_msg_has_wrong_format() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        register(scenario);

        test_scenario::next_tx(scenario, FIRST_USER);
        {
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let image = test_scenario::take_shared<Configuration>(scenario);
            let ctx = ctx_new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                30,
                10
            );

            registrar::register_with_image_internal(
                &mut suins,
                utf8(SUI_REGISTRAR),
                &image,
                utf8(THIRD_LABEL),
                FIRST_USER,
                365,
                vector[],
                vector[],
                vector[],
                &mut ctx
            );
            test_scenario::return_shared(suins);
            test_scenario::return_shared(image);
        };
        test_scenario::next_tx(scenario, FIRST_USER);
        {
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let second_nft = test_scenario::take_from_sender<RegistrationNFT>(scenario);
            let first_nft = test_scenario::take_from_sender<RegistrationNFT>(scenario);
            let ctx = ctx_new(
                FIRST_USER,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                50,
                0
            );

            registrar::update_image_url(
                &mut suins,
                &config,
                &mut first_nft,
                x"1750ce9c94af251d3288589b4e98369ee09a41530b42f545eab96763ecbaa8b941f0a814e7440eacd803c507633825ca1f70dc9018b59cb3e49871ca6ddcf704",
                x"c9cbb723ef1dce214552f05378404491ce9cb36429df9ca307b1619268f09335",
                b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,eastagile.sui,375",
                &mut ctx
            );
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
            test_scenario::return_to_sender(scenario, first_nft);
            test_scenario::return_to_sender(scenario, second_nft);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = string::EINVALID_INDEX)]
    fun test_update_image_url_aborts_if_msg_has_wrong_format_2() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        register(scenario);

        test_scenario::next_tx(scenario, FIRST_USER);
        {
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let image = test_scenario::take_shared<Configuration>(scenario);
            let ctx = ctx_new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                30,
                10
            );

            registrar::register_with_image_internal(
                &mut suins,
                utf8(SUI_REGISTRAR),
                &image,
                utf8(THIRD_LABEL),
                FIRST_USER,
                365,
                vector[],
                vector[],
                vector[],
                &mut ctx
            );
            test_scenario::return_shared(suins);
            test_scenario::return_shared(image);
        };
        test_scenario::next_tx(scenario, FIRST_USER);
        {
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let second_nft = test_scenario::take_from_sender<RegistrationNFT>(scenario);
            let first_nft = test_scenario::take_from_sender<RegistrationNFT>(scenario);
            let ctx = ctx_new(
                FIRST_USER,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                50,
                0
            );

            registrar::update_image_url(
                &mut suins,
                &config,
                &mut first_nft,
                x"1750ce9c94af251d3288589b4e98369ee09a41530b42f545eab96763ecbaa8b941f0a814e7440eacd803c507633825ca1f70dc9018b59cb3e49871ca6ddcf704",
                x"c9cbb723ef1dce214552f05378404491ce9cb36429df9ca307b1619268f09335",
                b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,eastagile.sui,375",
                &mut ctx
            );
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
            test_scenario::return_to_sender(scenario, first_nft);
            test_scenario::return_to_sender(scenario, second_nft);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = registrar::EInvalidImageMessage)]
    fun test_update_image_url_works_if_user_owns_2_nfts_and_uses_wrong_one() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;
        register(scenario);

        test_scenario::next_tx(scenario, FIRST_USER);
        {
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let image = test_scenario::take_shared<Configuration>(scenario);
            let ctx = ctx_new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                30,
                10
            );

            registrar::register_with_image_internal(
                &mut suins,
                utf8(SUI_REGISTRAR),
                &image,
                utf8(THIRD_LABEL),
                FIRST_USER,
                365,
                vector[],
                vector[],
                vector[],
                &mut ctx
            );
            test_scenario::return_shared(suins);
            test_scenario::return_shared(image);
        };
        test_scenario::next_tx(scenario, FIRST_USER);
        {
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let second_nft = test_scenario::take_from_sender<RegistrationNFT>(scenario);
            let first_nft = test_scenario::take_from_sender<RegistrationNFT>(scenario);
            let ctx = ctx_new(
                FIRST_USER,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                50,
                0
            );

            registrar::update_image_url(
                &mut suins,
                &config,
                &mut second_nft,
                x"d20dcb2b1a42690935bd7c81bcb43484fe05522eaf46dae633f0a9f8a14fb2bf0f8751c31de29ca34fe161584dca874938e0c6c036b459b7ae7d45811260095b",
                x"d0eae9ebf64029567b1afd715b14c7dc4cac40fe89391c55e5230335a7c5e00a",
                b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,eastagile.sui,375,hmm",
                &mut ctx
            );
            test_scenario::return_shared(suins);
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
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let image = test_scenario::take_shared<Configuration>(&mut scenario);
            let ctx = ctx_new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                466,
                10
            );

            registrar::register_with_image_internal(
                &mut suins,
                utf8(SUI_REGISTRAR),
                &image,
                utf8(FIRST_LABEL),
                FIRST_USER,
                365,
                vector[],
                vector[],
                vector[],
                &mut ctx
            );
            test_scenario::return_shared(suins);
            test_scenario::return_shared(image);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let new_nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let old_nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);

            registrar::reclaim_name(
                &new_nft,
                &mut suins,
                SECOND_USER,
                test_scenario::ctx(&mut scenario)
            );

            test_scenario::return_to_sender(&mut scenario, new_nft);
            test_scenario::return_to_sender(&mut scenario, old_nft);
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            let owner = registry::owner(&suins, utf8(FIRST_DOMAIN_NAME));
            assert!(SECOND_USER == owner, 0);

            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registrar::ENFTExpired)]
    fun test_reclaim_aborts_if_user_has_2_nfts_of_same_domains_and_uses_old_one() {
        let scenario = test_init();
        register(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let image = test_scenario::take_shared<Configuration>(&mut scenario);
            let ctx = ctx_new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                466,
                10
            );

            registrar::register_with_image_internal(
                &mut suins,
                utf8(SUI_REGISTRAR),
                &image,
                utf8(FIRST_LABEL),
                FIRST_USER,
                365,
                vector[],
                vector[],
                vector[],
                &mut ctx
            );
            test_scenario::return_shared(suins);
            test_scenario::return_shared(image);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let new_nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let old_nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);

            registrar::reclaim_name(
                &old_nft,
                &mut suins,
                SECOND_USER,
                test_scenario::ctx(&mut scenario)
            );

            test_scenario::return_to_sender(&mut scenario, new_nft);
            test_scenario::return_to_sender(&mut scenario, old_nft);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_reclaim_works_if_being_called_by_new_owner() {
        let scenario = test_init();
        register(&mut scenario);
        test_scenario::next_tx(&mut scenario, SECOND_USER);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let image = test_scenario::take_shared<Configuration>(&mut scenario);
            let ctx = ctx_new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                466,
                20
            );

            registrar::register_with_image_internal(
                &mut suins,
                utf8(SUI_REGISTRAR),
                &image,
                utf8(FIRST_LABEL),
                SECOND_USER,
                365,
                vector[],
                vector[],
                vector[],
                &mut ctx
            );
            test_scenario::return_shared(suins);
            test_scenario::return_shared(image);
        };

        test_scenario::next_tx(&mut scenario, SECOND_USER);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);

            registrar::reclaim_name(
                &nft,
                &mut suins,
                SECOND_USER,
                test_scenario::ctx(&mut scenario)
            );

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            let owner = registry::owner(&suins, utf8(FIRST_DOMAIN_NAME));
            assert!(SECOND_USER == owner, 0);

            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registrar::ENFTExpired)]
    fun test_reclaim_works_if_being_called_by_old_owner() {
        let scenario = test_init();
        register(&mut scenario);
        test_scenario::next_tx(&mut scenario, SECOND_USER);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let image = test_scenario::take_shared<Configuration>(&mut scenario);
            let ctx = ctx_new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                466,
                20
            );

            registrar::register_with_image_internal(
                &mut suins,
                utf8(SUI_REGISTRAR),
                &image,
                utf8(FIRST_LABEL),
                SECOND_USER,
                365,
                vector[],
                vector[],
                vector[],
                &mut ctx
            );
            test_scenario::return_shared(suins);
            test_scenario::return_shared(image);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);

            registrar::reclaim_name(
                &nft,
                &mut suins,
                SECOND_USER,
                test_scenario::ctx(&mut scenario)
            );

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }
}
