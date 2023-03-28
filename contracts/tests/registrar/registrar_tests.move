#[test_only]
module suins::registrar_tests {

    use sui::test_scenario::{Self, Scenario};
    use sui::url;
    use sui::dynamic_field;
    use suins::registry::{Self, AdminCap};
    use suins::registrar::{Self, RegistrationNFT, get_record_detail, assert_registrar_exists};
    use suins::configuration::{Self, Configuration};
    use std::vector;
    use std::string::utf8;
    use suins::entity::SuiNS;
    use suins::entity;
    use suins::auction_tests::ctx_new;

    const SUINS_ADDRESS: address = @0xA001;
    const FIRST_USER: address = @0xB001;
    const SECOND_USER: address = @0xB002;
    const FIRST_RESOLVER: address = @0xC001;
    const SECOND_RESOLVER: address = @0xC002;
    const FIRST_LABEL: vector<u8> = b"eastagile";
    const FIRST_NODE: vector<u8> = b"eastagile.sui";
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

            registrar::new_tld(&admin_cap, &mut suins, MOVE_REGISTRAR, test_scenario::ctx(&mut scenario));
            registrar::new_tld(&admin_cap, &mut suins, SUI_REGISTRAR, test_scenario::ctx(&mut scenario));
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

            registrar::register(
                &mut suins,
                SUI_REGISTRAR,
                &image,
                FIRST_LABEL,
                FIRST_USER,
                365,
                FIRST_RESOLVER,
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
            let (expiry, owner) = get_record_detail(&suins, SUI_REGISTRAR, FIRST_LABEL);

            assert!(expiry == 10 + 365, 0);
            assert!(owner == FIRST_USER, 0);

            let (name, url) = registrar::get_nft_fields(&nft);
            assert!(name == utf8(FIRST_NODE), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );

            let (owner, resolver, ttl) = registry::get_record_by_key(&suins, utf8(FIRST_NODE));

            assert!(owner == FIRST_USER, 0);
            assert!(resolver == FIRST_RESOLVER, 0);
            assert!(ttl == 0, 0);
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

            registrar::register_with_image(
                &mut suins,
                SUI_REGISTRAR,
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
            test_scenario::return_shared(suins);
            test_scenario::return_shared(image);
        };

        test_scenario::next_tx(scenario, FIRST_USER);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let (name, url) = registrar::get_nft_fields(&nft);
            registrar::assert_registrar_exists(&suins, SUI_REGISTRAR);
            let (expiry, owner) = get_record_detail(&suins, SUI_REGISTRAR, FIRST_LABEL);

            assert!(expiry == 10 + 365, 0);
            assert!(owner == FIRST_USER, 0);
            assert!(name == utf8(FIRST_NODE), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k"),
                0
            );

            let (owner, resolver, ttl) = registry::get_record_by_key(&suins, utf8(FIRST_NODE));

            assert!(owner == FIRST_USER, 0);
            assert!(resolver == FIRST_RESOLVER, 0);
            assert!(ttl == 0, 0);
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
            assert!(!registrar::is_available(&suins, SUI_REGISTRAR, label, test_scenario::ctx(&mut scenario)), 0);

            let label = utf8(b"ea");
            assert!(registrar::is_available(&suins, SUI_REGISTRAR, label,test_scenario::ctx(&mut scenario)), 0);

            test_scenario::return_shared(suins);
        };

        // test `name_expires` function
        test_scenario::next_tx(&mut scenario, FIRST_USER);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            assert!(registrar::name_expires_at(&suins, SUI_REGISTRAR, b"eastagile") == 10 + 365, 0);
            assert!(registrar::name_expires_at(&suins, SUI_REGISTRAR, b"ea") == 0, 0);

            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registrar::EInvalidLabel)]
    fun test_register_abort_with_invalid_utf8_label() {
        let scenario = test_init();
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let image = test_scenario::take_shared<Configuration>(&mut scenario);
            let invalid_label = vector::empty<u8>();
            // 0xFE cannot appear in a correct UTF-8 string
            vector::push_back(&mut invalid_label, 0xFE);

            registrar::register(
                &mut suins,
                SUI_REGISTRAR,
                &image,
                invalid_label,
                FIRST_USER,
                365,
                FIRST_RESOLVER,
                test_scenario::ctx(&mut scenario)
            );

            test_scenario::return_shared(suins);
            test_scenario::return_shared(image);
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

            registrar::register(
                &mut suins,
                SUI_REGISTRAR,
                &image,
                FIRST_LABEL,
                FIRST_USER,
                0,
                FIRST_RESOLVER,
                test_scenario::ctx(&mut scenario)
            );

            test_scenario::return_shared(suins);
            test_scenario::return_shared(image);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registrar::ELabelUnAvailable)]
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

            registrar::register(
                &mut suins,
                SUI_REGISTRAR,
                &image,
                FIRST_LABEL,
                FIRST_USER,
                365,
                FIRST_RESOLVER,
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

            assert!(registrar::name_expires_at(&suins, SUI_REGISTRAR, FIRST_LABEL) == 375, 0);
            let new_expiry = registrar::renew(&mut suins, SUI_REGISTRAR, FIRST_LABEL, 100, test_scenario::ctx(&mut scenario));
            assert!(registrar::name_expires_at(&suins, SUI_REGISTRAR, FIRST_LABEL) == 475, 0);
            assert!(new_expiry == 475, 0);

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

            assert!(registrar::name_expires_at(&suins, SUI_REGISTRAR, b"SECOND_LABEL") == 0, 0);

            registrar::renew(&mut suins, SUI_REGISTRAR, SECOND_LABEL, 100, test_scenario::ctx(&mut scenario));
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

            assert!(registrar::name_expires_at(&suins, SUI_REGISTRAR, FIRST_LABEL) == 375, 0);
            registrar::renew(&mut suins, SUI_REGISTRAR, FIRST_LABEL, 100, &ctx);
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
                &mut suins,
                SUI_REGISTRAR,
                &nft,
                SECOND_USER,
                test_scenario::ctx(&mut scenario)
            );

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            let owner = registry::owner(&suins, FIRST_NODE);
            assert!(SECOND_USER == owner, 0);

            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registrar::EInvalidBaseNode)]
    fun test_reclaim_name_by_nft_owner_abort_with_wrong_base_node() {
        let scenario = test_init();
        register(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);

            registrar::reclaim_name(
                &mut suins,
                MOVE_REGISTRAR,
                &nft,
                SECOND_USER,
                test_scenario::ctx(&mut scenario)
            );

            test_scenario::return_to_sender(&mut scenario, nft);
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
                &mut suins,
                SUI_REGISTRAR,
                &nft,
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
                &mut suins,
                SUI_REGISTRAR,
                &nft,
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
                b"com",
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

            registrar::register(
                &mut suins,
                b"com",
                &image,
                FIRST_LABEL,
                FIRST_USER,
                365,
                FIRST_RESOLVER,
                test_scenario::ctx(&mut scenario)
            );
            test_scenario::return_shared(suins);
            test_scenario::return_shared(image);
        };

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            registrar::assert_registrar_exists(&suins, b"com");

            let (expiry, owner) = get_record_detail(&suins, b"com", FIRST_LABEL);
            assert!(expiry == 365, 0);
            assert!(owner == FIRST_USER, 0);

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
                b"sui",
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

            assert!(name == utf8(FIRST_NODE), 0);
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
            let signature =
                x"1750ce9c94af251d3288589b4e98369ee09a41530b42f545eab96763ecbaa8b941f0a814e7440eacd803c507633825ca1f70dc9018b59cb3e49871ca6ddcf704";

            registrar::update_image_url(
                &mut suins,
                SUI_REGISTRAR,
                &config,
                &mut nft,
                signature,
                x"c9cbb723ef1dce214552f05378404491ce9cb36429df9ca307b1619268f09335",
                b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,eastagile.sui,375",
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

            assert!(name == utf8(FIRST_NODE), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k"),
                0
            );
            test_scenario::return_to_sender(scenario, nft);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = registrar::EInvalidImageMessage)]
    fun test_update_image_url_aborts_with_incorrect_expiry() {
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
            let signature = x"2a1e950f3f591a69249edfe144f36cee833963c5f1864182996d8dfe012af070389133ad07a2ae00709d3b60d090bc8d56b0c41d8f19aaeb662a1f556f81d452";
            registrar::update_image_url(
                &mut suins,
                SUI_REGISTRAR,
                &config,
                &mut nft,
                signature,
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
    fun test_update_image_url_aborts_with_incorrect_expiry_2() {
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
            let signature = x"74716e2b81ce8f982db8ab6c1b6e5d0c1df50d9ecad26dbc285b92f2721a35d7515f6e97d8eb5dba686af2a42d37c79622d89570bd55bdbb399fe0257f1c899e";
            registrar::update_image_url(
                &mut suins,
                SUI_REGISTRAR,
                &config,
                &mut nft,
                signature,
                x"7e7edd15b1a66887c5a18849bcb82180f339eb970c5c18e51d85c0c64d7ca587",
                b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,000000000000000000000000000000000000b001,0",
                &mut ctx
            );
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
            test_scenario::return_to_sender(scenario, nft);
        };
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = registrar::EInvalidImageMessage)]
    fun test_update_image_url_aborts_with_incorrect_expiry_3() {
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
            let signature = x"9ac9dcb87c02f9c7d5a509aedef026a2581703a0403ad3e6bfa1013e8c21c80b5d91e5ab10ee641265f388c43517f61338c872cb6370fc2c13f3dfe0491db986";
            registrar::update_image_url(
                &mut suins,
                SUI_REGISTRAR,
                &config,
                &mut nft,
                signature,
                x"a397f397765a84c1885c046f3847cec6ca875b2c071d691e996edad3d845a7df",
                b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,000000000000000000000000000000000000b001,100",
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
            let signature = x"e9e1685a4f0c0ef26c4425705ca9e7828ef0c42ad2a5e563e83d109d1fafd9d10106131af6bae1d69c0d7669cac7da85839f536d7a7d9e467136f308927a7312";
            registrar::update_image_url(
                &mut suins,
                SUI_REGISTRAR,
                &config,
                &mut nft,
                signature,
                x"849fdf5caead3e290f4adf2db7968fb5c5e0686a14a75f8da6e48292fd73a10e",
                b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,000000000000000000000000000000000000b002,375",
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
            let signature = x"05c15ea13b1f91cb4aed4fdd288e61d58d49392f4a12ccbdc4e0ff0c262559250315f37eec7f0b39b6bdd01d40ae9c130b4efbf6136d6ed35d2038b184ee3d2c";
            registrar::update_image_url(
                &mut suins,
                SUI_REGISTRAR,
                &config,
                &mut nft,
                signature,
                x"92c9867de4f4961482b7ca66e19141e641d193f56d244e4403f1335b37b67891",
                    b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,b001,375",
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
                SUI_REGISTRAR,
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
                SUI_REGISTRAR,
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
                SUI_REGISTRAR,
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
                SUI_REGISTRAR,
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
                SUI_REGISTRAR,
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
            x"1750ce9c94af251d3288589b4e98369ee09a41530b42f545eab96763ecbaa8b941f0a814e7440eacd803c507633825ca1f70dc9018b59cb3e49871ca6ddcf704",
            x"c9cbb723ef1dce214552f05378404491ce9cb36429df9ca307b1619268f09335",
            b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,eastagile.sui,375",
        );
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registrar::ESignatureNotMatch)]
    fun test_register_with_image_aborts_with_incorrect_signature() {
        let scenario = test_init();
        register_with_image(
            &mut scenario,
            x"6aab99201d259442c5478c3f5b29db45518b40a3d76f1b396b70c902b557e93b206b0ce9ab84ce44277d84055da9dd10ff77c490ba8473cd86ead37be874b9662f",
            x"127552ffa7fb7c3718ee61851c49eba03ef7d0dc0933c7c5802cdd98226f6006",
            b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,000000000000000000000000000000000000b001,375",
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
            x"e9e1685a4f0c0ef26c4425705ca9e7828ef0c42ad2a5e563e83d109d1fafd9d10106131af6bae1d69c0d7669cac7da85839f536d7a7d9e467136f308927a7312",
            x"849fdf5caead3e290f4adf2db7968fb5c5e0686a14a75f8da6e48292fd73a10e",
            b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,000000000000000000000000000000000000b002,375",
        );
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registrar::EInvalidImageMessage)]
    fun test_register_with_image_aborts_with_incorrect_owner_2() {
        let scenario = test_init();
        register_with_image(
            &mut scenario,
            x"ea4abdb40e717429107b8b198436d574306444d87d505c7c3b0847b122af6b45239fe3e8ddbb561854ce78f73345a0dc9880dd0878046ff1be3f6a1df4dab287",
            x"f6221e1f7a27baeab302011f89cfc863ae1b469c54dc4f2415e63369999c7ffe",
                b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,00000000000000000000000b001,375",
        );

        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registrar::EInvalidImageMessage)]
    fun test_register_with_image_aborts_with_incorrect_expiry() {
        let scenario = test_init();
        register_with_image(
            &mut scenario,
            x"2a1e950f3f591a69249edfe144f36cee833963c5f1864182996d8dfe012af070389133ad07a2ae00709d3b60d090bc8d56b0c41d8f19aaeb662a1f556f81d452",
            x"3431f0a9e0fe14c885766842f37b43b774e60dbd96f8502cc327e1ac20d06257",
            b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,000000000000000000000000000000000000b001,475",
        );
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registrar::EInvalidImageMessage)]
    fun test_register_with_image_aborts_with_incorrect_expiry_2() {
        let scenario = test_init();
        register_with_image(
            &mut scenario,
            x"74716e2b81ce8f982db8ab6c1b6e5d0c1df50d9ecad26dbc285b92f2721a35d7515f6e97d8eb5dba686af2a42d37c79622d89570bd55bdbb399fe0257f1c899e",
            x"7e7edd15b1a66887c5a18849bcb82180f339eb970c5c18e51d85c0c64d7ca587",
            b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,000000000000000000000000000000000000b001,0",
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
            let signature = x"6aab9920d59442c5478c3f5b29db45518b40a3d76f1b396b70c902b557e93b206b0ce9ab84ce44277d84055da9dd10ff77c490ba8473cd86ead37be874b9662f";

            registrar::update_image_url(
                &mut suins,
                SUI_REGISTRAR,
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
                SUI_REGISTRAR,
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

            registrar::register(
                &mut suins,
                SUI_REGISTRAR,
                &image,
                FIRST_LABEL,
                SECOND_USER,
                365,
                FIRST_RESOLVER,
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
                SUI_REGISTRAR,
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

            registrar::register(
                &mut suins,
                SUI_REGISTRAR,
                &image,
                FIRST_LABEL,
                SECOND_USER,
                365,
                FIRST_RESOLVER,
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
                SUI_REGISTRAR,
                &config,
                &mut nft,
                x"868d254e6ed4599a3c1bb93492008d2c8995233a02136c88a5f52b606383a7f46b1b4a83f9bf155852fd7e393421131d4b3ef9e5f8a02fd79c4c8a9b37bf67d7",
                x"3fc956b60da3d565cee6c7cc66efa0034bb32ef777b40982191e34b9c76191d8",
                b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,eastagile.sui,895",
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

            registrar::register(
                &mut suins,
                SUI_REGISTRAR,
                &image,
                FIRST_LABEL,
                FIRST_USER,
                365,
                FIRST_RESOLVER,
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
                SUI_REGISTRAR,
                &config,
                &mut new_nft,
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

            registrar::register(
                &mut suins,
                SUI_REGISTRAR,
                &image,
                FIRST_LABEL,
                FIRST_USER,
                365,
                FIRST_RESOLVER,
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
                SUI_REGISTRAR,
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

            registrar::register(
                &mut suins,
                SUI_REGISTRAR,
                &image,
                THIRD_LABEL,
                FIRST_USER,
                365,
                FIRST_RESOLVER,
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
                SUI_REGISTRAR,
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

            registrar::register(
                &mut suins,
                SUI_REGISTRAR,
                &image,
                THIRD_LABEL,
                FIRST_USER,
                365,
                FIRST_RESOLVER,
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
                SUI_REGISTRAR,
                &config,
                &mut second_nft,
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

            registrar::register(
                &mut suins,
                SUI_REGISTRAR,
                &image,
                FIRST_LABEL,
                FIRST_USER,
                365,
                FIRST_RESOLVER,
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
                &mut suins,
                SUI_REGISTRAR,
                &new_nft,
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

            let owner = registry::owner(&suins, FIRST_NODE);
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

            registrar::register(
                &mut suins,
                SUI_REGISTRAR,
                &image,
                FIRST_LABEL,
                FIRST_USER,
                365,
                FIRST_RESOLVER,
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
                &mut suins,
                SUI_REGISTRAR,
                &old_nft,
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

            registrar::register(
                &mut suins,
                SUI_REGISTRAR,
                &image,
                FIRST_LABEL,
                SECOND_USER,
                365,
                FIRST_RESOLVER,
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
                &mut suins,
                SUI_REGISTRAR,
                &nft,
                SECOND_USER,
                test_scenario::ctx(&mut scenario)
            );

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            let owner = registry::owner(&suins, FIRST_NODE);
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

            registrar::register(
                &mut suins,
                SUI_REGISTRAR,
                &image,
                FIRST_LABEL,
                SECOND_USER,
                365,
                FIRST_RESOLVER,
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
                &mut suins,
                SUI_REGISTRAR,
                &nft,
                SECOND_USER,
                test_scenario::ctx(&mut scenario)
            );

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }
}
