#[test_only]
module suins::controller_tests {

    use sui::coin::{Self, Coin};
    use sui::test_scenario::{Self, Scenario};
    use sui::tx_context;
    use sui::sui::SUI;
    use sui::url;
    use suins::auction::{Auction, make_seal_bid};
    use suins::auction;
    use suins::auction_tests::{start_an_auction_util, place_bid_util, reveal_bid_util};
    use suins::registrar::{Self, RegistrationNFT};
    use suins::registry::{Self, AdminCap};
    use suins::configuration::{Self, Configuration};
    use suins::controller;
    use suins::emoji;
    use std::option::{Self, Option, some};
    use std::string::utf8;
    use std::vector;
    use suins::entity::SuiNS;
    use suins::entity;

    const SUINS_ADDRESS: address = @0xA001;
    const FIRST_USER_ADDRESS: address = @0xB001;
    const SECOND_USER_ADDRESS: address = @0xB002;
    const FIRST_RESOLVER_ADDRESS: address = @0xC001;
    const FIRST_LABEL: vector<u8> = b"eastagile-123";
    const FIRST_NODE: vector<u8> = b"eastagile-123.sui";
    const SECOND_LABEL: vector<u8> = b"suinameservice";
    const THIRD_LABEL: vector<u8> = b"thirdsuinameservice";
    const FIRST_SECRET: vector<u8> = b"oKz=QdYd)]ryKB%";
    const SECOND_SECRET: vector<u8> = b"a9f8d4a8daeda2f35f02";
    const FIRST_INVALID_LABEL: vector<u8> = b"east.agile";
    const SECOND_INVALID_LABEL: vector<u8> = b"ea";
    const THIRD_INVALID_LABEL: vector<u8> = b"zkaoxpcbarubhtxkunajudxezneyczueajbggrynkwbepxjqjxrigrtgglhfjpax";
    const AUCTIONED_LABEL: vector<u8> = b"suins";
    const AUCTIONED_NODE: vector<u8> = b"suins.sui";
    const FOURTH_INVALID_LABEL: vector<u8> = b"-eastagile";
    const FIFTH_INVALID_LABEL: vector<u8> = b"east/?agile";
    const REFERRAL_CODE: vector<u8> = b"X43kS8";
    const DISCOUNT_CODE: vector<u8> = b"DC12345";
    const BIDDING_PERIOD: u64 = 3;
    const REVEAL_PERIOD: u64 = 3;
    const START_AUCTION_START_AT: u64 = 50;
    const START_AUCTION_END_AT: u64 = 120;
    const START_AN_AUCTION_AT: u64 = 110;
    const EXTRA_PERIOD: u64 = 30;
    const SUI_REGISTRAR: vector<u8> = b"sui";

    fun test_init(): Scenario {
        let scenario = test_scenario::begin(SUINS_ADDRESS);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            registry::test_init(ctx);
            configuration::test_init(ctx);
            entity::test_init(ctx);
            auction::test_init(ctx);
        };
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            registrar::new_tld(&admin_cap, &mut suins, SUI_REGISTRAR, test_scenario::ctx(&mut scenario));
            configuration::new_referral_code(&admin_cap, &mut config, REFERRAL_CODE, 10, SECOND_USER_ADDRESS);
            configuration::new_discount_code(&admin_cap, &mut config, DISCOUNT_CODE, 15, FIRST_USER_ADDRESS);
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

    fun make_commitment(scenario: &mut Scenario, label: Option<vector<u8>>) {
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let no_of_commitments = controller::commitment_len(&suins);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                50,
                0
            );
            if (option::is_none(&label)) label = option::some(FIRST_LABEL);
            let commitment = controller::test_make_commitment(
                SUI_REGISTRAR,
                option::extract(&mut label),
                FIRST_USER_ADDRESS,
                FIRST_SECRET
            );

            controller::commit(
                &mut suins,
                commitment,
                &mut ctx,
            );
            assert!(controller::commitment_len(&suins) - no_of_commitments == 1, 0);

            test_scenario::return_shared(suins);
            };
    }

    fun register(scenario: &mut Scenario) {
        make_commitment(scenario, option::none());

        // register
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let auction = test_scenario::take_shared<Auction>(scenario);
            // simulate user wait for next epoch to call `register`
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                51,
                0
            );
            let coin = coin::mint_for_testing<SUI>(1000001, &mut ctx);

            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, FIRST_LABEL), 0);
            assert!(!registry::record_exists(&suins, utf8(FIRST_NODE)), 0);
            assert!(controller::balance(&suins) == 0, 0);
            assert!(!test_scenario::has_most_recent_for_sender<RegistrationNFT>(scenario), 0);

            controller::register_with_config(
                &mut suins,
                SUI_REGISTRAR,
                &mut config,
                &auction,
                FIRST_LABEL,
                FIRST_USER_ADDRESS,
                1,
                FIRST_SECRET,
                FIRST_RESOLVER_ADDRESS,
                &mut coin,
                &mut ctx,
            );
            assert!(coin::value(&coin) == 1, 0);

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(scenario);
            let (name, url) = registrar::get_nft_fields(&nft);
            registrar::assert_registrar_exists(&suins, SUI_REGISTRAR);

            assert!(controller::balance(&suins) == 1000000, 0);
            assert!(name == utf8(FIRST_NODE), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );

            let (expiry, owner) = registrar::get_record_detail(&suins, SUI_REGISTRAR, FIRST_LABEL);
            assert!(expiry == 51 + 365, 0);
            assert!(owner== FIRST_USER_ADDRESS, 0);

            let (owner, resolver, ttl) = registry::get_record_by_key(&suins, utf8(FIRST_NODE));
            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(resolver == FIRST_RESOLVER_ADDRESS, 0);
            assert!(ttl == 0, 0);


            test_scenario::return_to_sender(scenario, nft);
            test_scenario::return_shared(suins);
        };
    }

    #[test]
    fun test_make_commitment() {
        let scenario = test_init();

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            assert!(controller::commitment_len(&suins) == 0, 0);
            test_scenario::return_shared(suins);
        };
        make_commitment(&mut scenario, option::none());
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            assert!(controller::commitment_len(&suins) == 1, 0);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_register() {
        let scenario = test_init();
        make_commitment(&mut scenario, option::none());

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                21,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, FIRST_LABEL), 0);
            assert!(controller::balance(&suins) == 0, 0);
            assert!(controller::commitment_len(&suins) == 1, 0);
            assert!(!registry::record_exists(&suins, utf8(FIRST_NODE)), 0);
            assert!(!test_scenario::has_most_recent_for_sender<RegistrationNFT>(&mut scenario), 0);

            controller::register(
                &mut suins,
                SUI_REGISTRAR,
                &mut config,
                &auction,
                FIRST_LABEL,
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                &mut ctx,
            );
            assert!(coin::value(&coin) == 1000000, 0);
            assert!(controller::commitment_len(&suins) == 0, 0);

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&nft);
            registrar::assert_registrar_exists(&suins, SUI_REGISTRAR);

            assert!(controller::balance(&suins) == 2000000, 0);
            assert!(name == utf8(FIRST_NODE), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );

            let (expiry, owner) = registrar::get_record_detail(&suins, SUI_REGISTRAR, FIRST_LABEL);
            assert!(expiry == 21 + 730, 0);
            assert!(owner == FIRST_USER_ADDRESS, 0);

            let (owner, resolver, ttl) = registry::get_record_by_key(&suins, utf8(FIRST_NODE));
            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(resolver == @0x0, 0);
            assert!(ttl == 0, 0);

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = controller::ECommitmentNotExists)]
    fun test_register_abort_with_difference_label() {
        let scenario = test_init();
        make_commitment(&mut scenario, option::none());

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            // simulate user wait for next epoch to call `register`
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                51,
                0
            );
            let coin = coin::mint_for_testing<SUI>(1000001, &mut ctx);

            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, SECOND_LABEL), 0);

            controller::register(
                &mut suins,
                SUI_REGISTRAR,
                &mut config,
                &auction,
                SECOND_LABEL,
                FIRST_USER_ADDRESS,
                1,
                FIRST_SECRET,
                &mut coin,
                &mut ctx,
            );

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = controller::ECommitmentNotExists)]
    fun test_register_abort_with_wrong_secret() {
        let scenario = test_init();
        make_commitment(&mut scenario, option::none());

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            // simulate user wait for next epoch to call `register`
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                51,
                0
            );
            let coin = coin::mint_for_testing<SUI>(1000001, &mut ctx);
            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, FIRST_LABEL), 0);

            controller::register(
                &mut suins,
                SUI_REGISTRAR,
                &mut config,
                &auction,
                SECOND_LABEL,
                FIRST_USER_ADDRESS,
                1,
                SECOND_SECRET,
                &mut coin,
                &mut ctx,
            );

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = controller::ECommitmentNotExists)]
    fun test_register_abort_with_wrong_owner() {
        let scenario = test_init();
        make_commitment(&mut scenario, option::none());

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                51,
                0
            );
            let coin = coin::mint_for_testing<SUI>(1000001, &mut ctx);
            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, FIRST_LABEL), 0);

            controller::register(
                &mut suins,
                SUI_REGISTRAR,
                &mut config,
                &auction,
                SECOND_LABEL,
                SECOND_USER_ADDRESS,
                1,
                FIRST_SECRET,
                &mut coin,
                &mut ctx,
            );

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = controller::ECommitmentTooOld)]
    fun test_register_abort_if_called_too_late() {
        let scenario = test_init();
        make_commitment(&mut scenario, option::none());

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            // simulate user call `register` in the same epoch as `commit`
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                53,
                0
            );
            let coin = coin::mint_for_testing<SUI>(1000000, &mut ctx);

            controller::register(
                &mut suins,
                SUI_REGISTRAR,
                &mut config,
                &auction,
                FIRST_LABEL,
                FIRST_USER_ADDRESS,
                1,
                FIRST_SECRET,
                &mut coin,
                &mut ctx,
            );

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = controller::ENotEnoughFee)]
    fun test_register_abort_if_not_enough_fee() {
        let scenario = test_init();
        make_commitment(&mut scenario, option::none());

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            // simulate user wait for next epoch to call `register`
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                52,
                0
            );
            let coin = coin::mint_for_testing<SUI>(9999, &mut ctx);

            controller::register(
                &mut suins,
                SUI_REGISTRAR,
                &mut config,
                &auction,
                FIRST_LABEL,
                FIRST_USER_ADDRESS,
                1,
                FIRST_SECRET,
                &mut coin,
                &mut ctx,
            );

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = controller::ELabelUnAvailable)]
    fun test_register_abort_if_label_was_registered_before() {
        let scenario = test_init();
        register(&mut scenario);
        make_commitment(&mut scenario, option::none());

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            // simulate user wait for next epoch to call `register`
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                51,
                0
            );
            let coin = coin::mint_for_testing<SUI>(1000001, &mut ctx);
            assert!(controller::balance(&suins) == 1000000, 0);

            controller::register(
                &mut suins,
                SUI_REGISTRAR,
                &mut config,
                &auction,
                FIRST_LABEL,
                FIRST_USER_ADDRESS,
                1,
                FIRST_SECRET,
                &mut coin,
                &mut ctx,
            );

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_register_works_if_previous_registration_is_expired() {
        let scenario = test_init();
        register(&mut scenario);

        test_scenario::next_tx(&mut scenario, SECOND_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                599,
                10
            );
            let commitment = controller::test_make_commitment(
                SUI_REGISTRAR,
                FIRST_LABEL,
                SECOND_USER_ADDRESS,
                FIRST_SECRET
            );

            controller::commit(
                &mut suins,
                commitment,
                &mut ctx,
            );

            test_scenario::return_shared(suins);
            };

        test_scenario::next_tx(&mut scenario, SECOND_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            // simulate user wait for next epoch to call `register`
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                600,
                20
            );
            let coin = coin::mint_for_testing<SUI>(1000001, &mut ctx);
            assert!(controller::balance(&suins) == 1000000, 0);

            controller::register(
                &mut suins,
                SUI_REGISTRAR,
                &mut config,
                &auction,
                FIRST_LABEL,
                SECOND_USER_ADDRESS,
                1,
                FIRST_SECRET,
                &mut coin,
                &mut ctx,
            );

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
            test_scenario::return_shared(auction);
        };

        test_scenario::next_tx(&mut scenario, SECOND_USER_ADDRESS);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&nft);
            registrar::assert_registrar_exists(&suins, SUI_REGISTRAR);

            assert!(controller::balance(&suins) == 2000000, 0);
            assert!(name == utf8(FIRST_NODE), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );

            let (expiry, owner) = registrar::get_record_detail(&suins, SUI_REGISTRAR, FIRST_LABEL);
            assert!(expiry == 600 + 365, 0);
            assert!(owner == SECOND_USER_ADDRESS, 0);

            let (owner, resolver, ttl) = registry::get_record_by_key(&suins, utf8(FIRST_NODE));
            assert!(owner == SECOND_USER_ADDRESS, 0);
            assert!(resolver == @0x0, 0);
            assert!(ttl == 0, 0);

            let registrar = registrar::get_registrar(&suins, SUI_REGISTRAR);
            registrar::assert_nft_not_expires(
                registrar,
                utf8(SUI_REGISTRAR),
                &nft,
                test_scenario::ctx(&mut scenario)
            );

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registrar::ENFTExpired)]
    fun test_register_works_if_previous_registration_is_expired_2() {
        let scenario = test_init();
        register(&mut scenario);

        test_scenario::next_tx(&mut scenario, SECOND_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                599,
                10
            );
            let commitment = controller::test_make_commitment(
                SUI_REGISTRAR,
                FIRST_LABEL,
                SECOND_USER_ADDRESS,
                FIRST_SECRET
            );

            controller::commit(
                &mut suins,
                commitment,
                &mut ctx,
            );

            test_scenario::return_shared(suins);
            };

        test_scenario::next_tx(&mut scenario, SECOND_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            // simulate user wait for next epoch to call `register`
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                600,
                20
            );
            let coin = coin::mint_for_testing<SUI>(1000001, &mut ctx);
            assert!(controller::balance(&suins) == 1000000, 0);

            controller::register(
                &mut suins,
                SUI_REGISTRAR,
                &mut config,
                &auction,
                FIRST_LABEL,
                SECOND_USER_ADDRESS,
                1,
                FIRST_SECRET,
                &mut coin,
                &mut ctx,
            );

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
            test_scenario::return_shared(auction);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            let registrar = registrar::get_registrar(&suins, SUI_REGISTRAR);
            registrar::assert_nft_not_expires(
                registrar,
                utf8(SUI_REGISTRAR),
                &nft,
                test_scenario::ctx(&mut scenario)
            );

            test_scenario::return_shared(suins);
            test_scenario::return_to_sender(&mut scenario, nft);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_register_with_config() {
        let scenario = test_init();
        make_commitment(&mut scenario, option::none());

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                51,
                0
            );
            let coin = coin::mint_for_testing<SUI>(4000001, &mut ctx);

            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, FIRST_LABEL), 0);
            assert!(!registry::record_exists(&suins, utf8(FIRST_NODE)), 0);
            assert!(controller::balance(&suins) == 0, 0);
            assert!(!test_scenario::has_most_recent_for_sender<RegistrationNFT>(&mut scenario), 0);

            controller::register_with_config(
                &mut suins,
                SUI_REGISTRAR,
                &mut config,
                &auction,
                FIRST_LABEL,
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                FIRST_RESOLVER_ADDRESS,
                &mut coin,
                &mut ctx,
            );
            assert!(coin::value(&coin) == 2000001, 0);

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&nft);
            registrar::assert_registrar_exists(&suins, SUI_REGISTRAR);


            assert!(controller::balance(&suins) == 2000000, 0);
            assert!(name == utf8(FIRST_NODE), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );

            let (expiry, owner) = registrar::get_record_detail(&suins, SUI_REGISTRAR, FIRST_LABEL);
            assert!(expiry == 51 + 730, 0);
            assert!(owner== FIRST_USER_ADDRESS, 0);

            let (owner, resolver, ttl) = registry::get_record_by_key(&suins, utf8(FIRST_NODE));
            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(resolver == FIRST_RESOLVER_ADDRESS, 0);
            assert!(ttl == 0, 0);

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(suins);
        };

        // withdraw
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            assert!(controller::balance(&suins) == 2000000, 0);
            assert!(!test_scenario::has_most_recent_for_sender<Coin<SUI>>(&mut scenario), 0);

            controller::withdraw(&admin_cap, &mut suins, test_scenario::ctx(&mut scenario));
            assert!(controller::balance(&suins) == 0, 0);

            test_scenario::return_shared(suins);
            test_scenario::return_to_sender(&mut scenario, admin_cap);
        };

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            assert!(test_scenario::has_most_recent_for_sender<Coin<SUI>>(&mut scenario), 0);
            let coin = test_scenario::take_from_sender<Coin<SUI>>(&mut scenario);
            assert!(coin::value(&coin) == 2000000, 0);
            test_scenario::return_to_sender(&mut scenario, coin);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = emoji::EInvalidLabel)]
    fun test_register_with_config_abort_with_too_short_label() {
        let scenario = test_init();
        make_commitment(&mut scenario, option::none());

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(10001, test_scenario::ctx(&mut scenario));

            controller::register_with_config(
                &mut suins,
                SUI_REGISTRAR,
                &mut config,
                &auction,
                SECOND_INVALID_LABEL,
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                FIRST_RESOLVER_ADDRESS,
                &mut coin,
                test_scenario::ctx(&mut scenario),
            );

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
        };

        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = emoji::EInvalidLabel)]
    fun test_register_with_config_abort_with_too_long_label() {
        let scenario = test_init();
        make_commitment(&mut scenario, option::none());

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(1000001, test_scenario::ctx(&mut scenario));

            controller::register_with_config(
                &mut suins,
                SUI_REGISTRAR,
                &mut config,
                &auction,
                THIRD_INVALID_LABEL,
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                FIRST_RESOLVER_ADDRESS,
                &mut coin,
                test_scenario::ctx(&mut scenario),
            );

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
        };

        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = emoji::EInvalidLabel)]
    fun test_register_with_config_abort_if_label_starts_with_hyphen() {
        let scenario = test_init();
        make_commitment(&mut scenario, option::none());

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(10001, test_scenario::ctx(&mut scenario));

            controller::register_with_config(
                &mut suins,
                SUI_REGISTRAR,
                &mut config,
                &auction,
                FOURTH_INVALID_LABEL,
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                FIRST_RESOLVER_ADDRESS,
                &mut coin,
                test_scenario::ctx(&mut scenario),
            );

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
        };

        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = emoji::EInvalidLabel)]
    fun test_register_with_config_abort_with_invalid_label() {
        let scenario = test_init();
        make_commitment(&mut scenario, option::none());

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(1000001, test_scenario::ctx(&mut scenario));

            controller::register_with_config(
                &mut suins,
                SUI_REGISTRAR,
                &mut config,
                &auction,
                FIFTH_INVALID_LABEL,
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                FIRST_RESOLVER_ADDRESS,
                &mut coin,
                test_scenario::ctx(&mut scenario),
            );

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
        };

        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = controller::ENoProfits)]
    fun test_withdraw_abort_if_no_profits() {
        let scenario = test_init();

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            controller::withdraw(&admin_cap, &mut suins, test_scenario::ctx(&mut scenario));
            test_scenario::return_shared(suins);
            test_scenario::return_to_sender(&mut scenario, admin_cap);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = emoji::EInvalidLabel)]
    fun test_register_abort_if_label_is_reserved_for_auction() {
        let scenario = test_init();
        make_commitment(&mut scenario, option::none());

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(1000001, test_scenario::ctx(&mut scenario));

            controller::register(
                &mut suins,
                SUI_REGISTRAR,
                &mut config,
                &auction,
                AUCTIONED_LABEL,
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                test_scenario::ctx(&mut scenario),
            );

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
        };

        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = emoji::EInvalidLabel)]
    fun test_register_abort_if_label_is_invalid() {
        let scenario = test_init();

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                50,
                0
            );

            assert!(controller::commitment_len(&suins) == 0, 0);

            let commitment = controller::test_make_commitment(
                SUI_REGISTRAR,
                FIRST_INVALID_LABEL,
                FIRST_USER_ADDRESS,
                FIRST_SECRET
            );
            controller::commit(
                &mut suins,
                commitment,
                &mut ctx,
            );
            assert!(controller::commitment_len(&suins) == 1, 0);
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                51,
                0
            );
            let coin = coin::mint_for_testing<SUI>(10001, &mut ctx);

            controller::register_with_config(
                &mut suins,
                SUI_REGISTRAR,
                &mut config,
                &auction,
                FIRST_INVALID_LABEL,
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                FIRST_RESOLVER_ADDRESS,
                &mut coin,
                &mut ctx,
            );

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_renew() {
        let scenario = test_init();
        register(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let ctx = test_scenario::ctx(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(2000001, ctx);

            assert!(registrar::name_expires_at(&suins, SUI_REGISTRAR, FIRST_LABEL) == 416, 0);
            assert!(controller::balance(&suins) == 1000000, 0);

            controller::renew(
                &mut suins,
                SUI_REGISTRAR,
                FIRST_LABEL,
                2,
                &mut coin,
                ctx,
            );

            assert!(coin::value(&coin) == 1, 0);
            assert!(registrar::name_expires_at(&suins, SUI_REGISTRAR, FIRST_LABEL) == 1146, 0);

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            assert!(controller::balance(&suins) == 3000000, 0);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registrar::ELabelNotExists)]
    fun test_renew_abort_if_label_not_exists() {
        let scenario = test_init();

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let ctx = test_scenario::ctx(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(1000001, ctx);

            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, FIRST_LABEL), 0);

            controller::renew(
                &mut suins,
                SUI_REGISTRAR,
                FIRST_LABEL,
                1,
                &mut coin,
                ctx,
            );

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registrar::ELabelExpired)]
    fun test_renew_abort_if_label_expired() {
        let scenario = test_init();
        register(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                1051,
                0
            );
            let coin = coin::mint_for_testing<SUI>(10000001, &mut ctx);

            controller::renew(
                &mut suins,
                SUI_REGISTRAR,
                FIRST_LABEL,
                1,
                &mut coin,
                &mut ctx,
            );

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = controller::ENotEnoughFee)]
    fun test_renew_abort_if_not_enough_fee() {
        let scenario = test_init();

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let ctx = test_scenario::ctx(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(4, ctx);

            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, FIRST_LABEL), 0);

            controller::renew(
                &mut suins,
                SUI_REGISTRAR,
                FIRST_LABEL,
                1,
                &mut coin,
                ctx,
            );

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_set_default_resolver() {
        let scenario = test_init();

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            assert!(controller::get_default_resolver(&suins) == @0x0, 0);
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            controller::set_default_resolver(&admin_cap, &mut suins, FIRST_RESOLVER_ADDRESS);
            test_scenario::return_shared(suins);
            test_scenario::return_to_sender(&mut scenario, admin_cap);
        };

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            assert!(controller::get_default_resolver(&suins) == FIRST_RESOLVER_ADDRESS, 0);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_remove_outdated_commitment() {
        let scenario = test_init();
        // outdated commitment
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                10,
                0
            );

            assert!(controller::commitment_len(&suins) == 0, 0);

            let commitment = controller::test_make_commitment(
                SUI_REGISTRAR,
                FIRST_LABEL,
                FIRST_USER_ADDRESS,
                FIRST_SECRET
            );
            controller::commit(
                &mut suins,
                commitment,
                &mut ctx,
            );

            assert!(controller::commitment_len(&suins) == 1, 0);
            test_scenario::return_shared(suins);
        };

        // outdated commitment
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                30,
                0
            );

            let commitment = controller::test_make_commitment(
                SUI_REGISTRAR,
                FIRST_LABEL,
                SECOND_USER_ADDRESS,
                FIRST_SECRET
            );
            controller::commit(
                &mut suins,
                commitment,
                &mut ctx,
            );
            assert!(controller::commitment_len(&suins) == 1, 0);

            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                48,
                0
            );

            let commitment = controller::test_make_commitment(
                SUI_REGISTRAR,
                FIRST_LABEL,
                FIRST_USER_ADDRESS,
                SECOND_SECRET
            );
            controller::commit(
                &mut suins,
                commitment,
                &mut ctx,
            );
            assert!(controller::commitment_len(&suins) == 1, 0);

            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                50,
                0
            );

            let commitment = controller::test_make_commitment(
                SUI_REGISTRAR,
                SECOND_LABEL,
                FIRST_USER_ADDRESS,
                FIRST_SECRET
            );
            controller::commit(
                &mut suins,
                commitment,
                &mut ctx,
            );
            assert!(controller::commitment_len(&suins) == 2, 0);

            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            // simulate user wait for next epoch to call `register`
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                51,
                0
            );
            let coin = coin::mint_for_testing<SUI>(2000001, &mut ctx);

            assert!(controller::commitment_len(&suins) == 2, 0);

            controller::register(
                &mut suins,
                SUI_REGISTRAR,
                &mut config,
                &auction,
                SECOND_LABEL,
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                &mut ctx,
            );

            assert!(coin::value(&coin) == 1, 0);
            assert!(controller::commitment_len(&suins) == 1, 0);

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_register_with_referral_code() {
        let scenario = test_init();
        make_commitment(&mut scenario, option::none());

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                51,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            assert!(controller::balance(&suins) == 0, 0);
            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, FIRST_LABEL), 0);
            assert!(!registry::record_exists(&suins, utf8(FIRST_NODE)), 0);
            assert!(!test_scenario::has_most_recent_for_sender<RegistrationNFT>(&mut scenario), 0);
            assert!(!test_scenario::has_most_recent_for_address<Coin<SUI>>(SECOND_USER_ADDRESS), 0);

            controller::register_with_code(
                &mut suins,
                SUI_REGISTRAR,
                &mut config,
                &auction,
                FIRST_LABEL,
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                REFERRAL_CODE,
                b"",
                &mut ctx,
            );

            assert!(coin::value(&coin) == 1000000, 0);

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&nft);
            let coin = test_scenario::take_from_address<Coin<SUI>>(&mut scenario, SECOND_USER_ADDRESS);

            registrar::assert_registrar_exists(&suins, SUI_REGISTRAR);

            assert!(name == utf8(FIRST_NODE), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );
            assert!(coin::value(&coin) == 200000, 0);
            assert!(controller::balance(&suins) == 1800000, 0);

            let (expiry, owner) = registrar::get_record_detail(&suins, SUI_REGISTRAR, FIRST_LABEL);
            assert!(expiry == 51 + 730, 0);
            assert!(owner== FIRST_USER_ADDRESS, 0);

            let (owner, resolver, ttl) = registry::get_record_by_key(&suins, utf8(FIRST_NODE));
            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(resolver == @0x0, 0);
            assert!(ttl == 0, 0);

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_to_address(SECOND_USER_ADDRESS, coin);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_register_with_config_referral_code() {
        let scenario = test_init();
        make_commitment(&mut scenario, option::none());

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                51,
                0
            );
            let coin = coin::mint_for_testing<SUI>(4000000, &mut ctx);

            assert!(controller::balance(&suins) == 0, 0);
            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, FIRST_LABEL), 0);
            assert!(!registry::record_exists(&suins, utf8(FIRST_NODE)), 0);
            assert!(!test_scenario::has_most_recent_for_sender<RegistrationNFT>(&mut scenario), 0);
            assert!(!test_scenario::has_most_recent_for_address<Coin<SUI>>(SECOND_USER_ADDRESS), 0);

            controller::register_with_config_and_code(
                &mut suins,
                SUI_REGISTRAR,
                &mut config,
                &auction,
                FIRST_LABEL,
                FIRST_USER_ADDRESS,
                3,
                FIRST_SECRET,
                FIRST_RESOLVER_ADDRESS,
                &mut coin,
                REFERRAL_CODE,
                b"",
                &mut ctx,
            );
            assert!(coin::value(&coin) == 1000000, 0);
            coin::destroy_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&nft);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let coin = test_scenario::take_from_address<Coin<SUI>>(&mut scenario, SECOND_USER_ADDRESS);

            registrar::assert_registrar_exists(&suins, SUI_REGISTRAR);

            assert!(name == utf8(FIRST_NODE), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );
            assert!(coin::value(&coin) == 300000, 0);
            assert!(controller::balance(&suins) == 2700000, 0);

            let (expiry, owner) = registrar::get_record_detail(&suins, SUI_REGISTRAR, FIRST_LABEL);
            assert!(expiry == 51 + 1095, 0);
            assert!(owner== FIRST_USER_ADDRESS, 0);

            let (owner, resolver, ttl) = registry::get_record_by_key(&suins, utf8(FIRST_NODE));
            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(resolver == FIRST_RESOLVER_ADDRESS, 0);
            assert!(ttl == 0, 0);

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_to_address(SECOND_USER_ADDRESS, coin);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_apply_referral() {
        let scenario = test_init();
        test_scenario::next_tx(&mut scenario, SECOND_USER_ADDRESS);
        {
            let config =
                test_scenario::take_shared<Configuration>(&mut scenario);
            let ctx = test_scenario::ctx(&mut scenario);
            let coin1 = coin::mint_for_testing<SUI>(4000000, ctx);
            let coin2 = coin::mint_for_testing<SUI>(909, ctx);

            assert!(!test_scenario::has_most_recent_for_address<Coin<SUI>>(SECOND_USER_ADDRESS), 0);
            controller::apply_referral_code_test(&config, &mut coin1, 4000000, REFERRAL_CODE, ctx);
            assert!(coin::value(&coin1) == 3600000, 0);

            controller::apply_referral_code_test(&config, &mut coin2, 909, REFERRAL_CODE, ctx);
            assert!(coin::value(&coin2) == 810, 0);

            coin::destroy_for_testing(coin2);
            coin::destroy_for_testing(coin1);
            test_scenario::return_shared(config);
        };

        test_scenario::next_tx(&mut scenario, SECOND_USER_ADDRESS);
        {
            let coin1 = test_scenario::take_from_address<Coin<SUI>>(&mut scenario, SECOND_USER_ADDRESS);
            let coin2 = test_scenario::take_from_address<Coin<SUI>>(&mut scenario, SECOND_USER_ADDRESS);

            assert!(coin::value(&coin1) == 99, 0);
            assert!(coin::value(&coin2) == 400000, 0);

            test_scenario::return_to_address(SECOND_USER_ADDRESS, coin1);
            test_scenario::return_to_address(SECOND_USER_ADDRESS, coin2);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_register_with_discount_code() {
        let scenario = test_init();
        make_commitment(&mut scenario, option::none());

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                51,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            assert!(controller::balance(&suins) == 0, 0);
            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, FIRST_LABEL), 0);
            assert!(!registry::record_exists(&suins, utf8(FIRST_NODE)), 0);
            assert!(!test_scenario::has_most_recent_for_sender<RegistrationNFT>(&mut scenario), 0);
            assert!(!test_scenario::has_most_recent_for_address<Coin<SUI>>(SECOND_USER_ADDRESS), 0);

            controller::register_with_code(
                &mut suins,
                SUI_REGISTRAR,
                &mut config,
                &auction,
                FIRST_LABEL,
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                b"",
                DISCOUNT_CODE,
                &mut ctx,
            );

            assert!(coin::value(&coin) == 1300000, 0);

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&nft);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            registrar::assert_registrar_exists(&suins, SUI_REGISTRAR);

            assert!(!test_scenario::has_most_recent_for_address<Coin<SUI>>(SECOND_USER_ADDRESS), 0);
            assert!(name == utf8(FIRST_NODE), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );
            assert!(controller::balance(&suins) == 1700000, 0);

            let (expiry, owner) = registrar::get_record_detail(&suins, SUI_REGISTRAR, FIRST_LABEL);
            assert!(expiry == 51 + 730, 0);
            assert!(owner== FIRST_USER_ADDRESS, 0);

            let (owner, resolver, ttl) = registry::get_record_by_key(&suins, utf8(FIRST_NODE));
            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(resolver == @0x0, 0);
            assert!(ttl == 0, 0);

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = configuration::EOwnerUnauthorized)]
    fun test_register_with_discount_code_abort_if_unauthorized() {
        let scenario = test_init();
        make_commitment(&mut scenario, option::none());

        test_scenario::next_tx(&mut scenario, SECOND_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            let ctx = tx_context::new(
                SECOND_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                51,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            controller::register_with_code(
                &mut suins,
                SUI_REGISTRAR,
                &mut config,
                &auction,
                FIRST_LABEL,
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                b"",
                DISCOUNT_CODE,
                &mut ctx,
            );

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = configuration::EDiscountCodeNotExists)]
    fun test_register_with_discount_code_abort_with_invalid_code() {
        let scenario = test_init();
        make_commitment(&mut scenario, option::none());

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                51,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            controller::register_with_code(
                &mut suins,
                SUI_REGISTRAR,
                &mut config,
                &auction,
                FIRST_LABEL,
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                b"",
                REFERRAL_CODE,
                &mut ctx,
            );

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_register_with_config_and_discount_code() {
        let scenario = test_init();
        make_commitment(&mut scenario, option::none());

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                51,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            assert!(controller::balance(&suins) == 0, 0);
            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, FIRST_LABEL), 0);
            assert!(!registry::record_exists(&suins, utf8(FIRST_NODE)), 0);
            assert!(!test_scenario::has_most_recent_for_sender<RegistrationNFT>(&mut scenario), 0);
            assert!(!test_scenario::has_most_recent_for_address<Coin<SUI>>(SECOND_USER_ADDRESS), 0);

            controller::register_with_config_and_code(
                &mut suins,
                SUI_REGISTRAR,
                &mut config,
                &auction,
                FIRST_LABEL,
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                FIRST_RESOLVER_ADDRESS,
                &mut coin,
                b"",
                DISCOUNT_CODE,
                &mut ctx,
            );
            assert!(coin::value(&coin) == 1300000, 0);

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&nft);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            
            registrar::assert_registrar_exists(&suins, SUI_REGISTRAR);

            assert!(!test_scenario::has_most_recent_for_address<Coin<SUI>>(SECOND_USER_ADDRESS), 0);
            assert!(name == utf8(FIRST_NODE), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );
            assert!(controller::balance(&suins) == 1700000, 0);

            let (expiry, owner) = registrar::get_record_detail(&suins, SUI_REGISTRAR, FIRST_LABEL);
            assert!(expiry == 51 + 730, 0);
            assert!(owner== FIRST_USER_ADDRESS, 0);

            let (owner, resolver, ttl) = registry::get_record_by_key(&suins, utf8(FIRST_NODE));
            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(resolver == FIRST_RESOLVER_ADDRESS, 0);
            assert!(ttl == 0, 0);

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = configuration::EOwnerUnauthorized)]
    fun test_register_with_config_and_discount_code_abort_if_unauthorized() {
        let scenario = test_init();
        make_commitment(&mut scenario, option::none());

        test_scenario::next_tx(&mut scenario, SECOND_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            let ctx = tx_context::new(
                SECOND_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                51,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            controller::register_with_config_and_code(
                &mut suins,
                SUI_REGISTRAR,
                &mut config,
                &auction,
                FIRST_LABEL,
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                FIRST_RESOLVER_ADDRESS,
                &mut coin,
                b"",
                DISCOUNT_CODE,
                &mut ctx,
            );

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = configuration::EDiscountCodeNotExists)]
    fun test_register_with_config_and_discount_code_abort_with_invalid_code() {
        let scenario = test_init();
        make_commitment(&mut scenario, option::none());

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                51,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            controller::register_with_config_and_code(
                &mut suins,
                SUI_REGISTRAR,
                &mut config,
                &auction,
                FIRST_LABEL,
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                FIRST_RESOLVER_ADDRESS,
                &mut coin,
                b"",
                REFERRAL_CODE,
                &mut ctx,
            );

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = configuration::EDiscountCodeNotExists)]
    fun test_register_with_discount_code_abort_if_being_used_twice() {
        let scenario = test_init();
        make_commitment(&mut scenario, option::none());

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                51,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            controller::register_with_code(
                &mut suins,
                SUI_REGISTRAR,
                &mut config,
                &auction,
                FIRST_LABEL,
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                b"",
                DISCOUNT_CODE,
                &mut ctx,
            );

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                60,
                0
            );
            let commitment = controller::test_make_commitment(
                SUI_REGISTRAR,
                SECOND_LABEL,
                FIRST_USER_ADDRESS,
                FIRST_SECRET
            );

            controller::commit(
                &mut suins,
                commitment,
                &mut ctx,
            );

            test_scenario::return_shared(suins);
            };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                61,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            controller::register_with_code(
                &mut suins,
                SUI_REGISTRAR,
                &mut config,
                &auction,
                SECOND_LABEL,
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                b"",
                DISCOUNT_CODE,
                &mut ctx,
            );

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_register_with_referral_code_works_if_code_is_used_twice() {
        let scenario = test_init();
        make_commitment(&mut scenario, option::none());
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                51,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, FIRST_LABEL), 0);

            controller::register_with_code(
                &mut suins,
                SUI_REGISTRAR,
                &mut config,
                &auction,
                FIRST_LABEL,
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                REFERRAL_CODE,
                b"",
                &mut ctx,
            );
            assert!(coin::value(&coin) == 1000000, 0);
            coin::destroy_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let coin = test_scenario::take_from_address<Coin<SUI>>(&mut scenario, SECOND_USER_ADDRESS);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            assert!(coin::value(&coin) == 200000, 0);
            assert!(controller::balance(&suins) == 1800000, 0);

            test_scenario::return_to_address(SECOND_USER_ADDRESS, coin);
            test_scenario::return_shared(suins);
        };
        make_commitment(&mut scenario, option::some(SECOND_LABEL));
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            // simulate user wait for next epoch to call `register`
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                51,
                2
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);
            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, SECOND_LABEL), 0);

            controller::register_with_code(
                &mut suins,
                SUI_REGISTRAR,
                &mut config,
                &auction,
                SECOND_LABEL,
                FIRST_USER_ADDRESS,
                1,
                FIRST_SECRET,
                &mut coin,
                REFERRAL_CODE,
                b"",
                &mut ctx,
            );
            assert!(coin::value(&coin) == 2000000, 0);
            coin::destroy_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let coin1 = test_scenario::take_from_address<Coin<SUI>>(&mut scenario, SECOND_USER_ADDRESS);
            let coin2 = test_scenario::take_from_address<Coin<SUI>>(&mut scenario, SECOND_USER_ADDRESS);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            assert!(coin::value(&coin1) == 100000, 0);
            assert!(coin::value(&coin2) == 200000, 0);
            assert!(controller::balance(&suins) == 2700000, 0);

            test_scenario::return_to_address(SECOND_USER_ADDRESS, coin2);
            test_scenario::return_shared(suins);
            test_scenario::return_to_address(SECOND_USER_ADDRESS, coin1);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = configuration::EReferralCodeNotExists)]
    fun test_register_with_referral_code_abort_with_wrong_referral_code() {
        let scenario = test_init();
        make_commitment(&mut scenario, option::none());
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                51,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            controller::register_with_code(
                &mut suins,
                SUI_REGISTRAR,
                &mut config,
                &auction,
                FIRST_LABEL,
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                DISCOUNT_CODE,
                b"",
                &mut ctx,
            );

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    // #[test]
    fun test_register_with_emoji() {
        let scenario = test_init();
        let label = vector[104, 109, 109, 109, 49, 240, 159, 145, 180];
        make_commitment(&mut scenario, option::some(label));

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            // simulate user wait for next epoch to call `register`
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                51,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, FIRST_LABEL), 0);
            assert!(controller::balance(&suins) == 0, 0);
            assert!(controller::commitment_len(&suins) == 1, 0);
            assert!(!registry::record_exists(&suins, utf8(FIRST_NODE)), 0);
            assert!(!test_scenario::has_most_recent_for_sender<RegistrationNFT>(&mut scenario), 0);

            controller::register(
                &mut suins,
                SUI_REGISTRAR,
                &mut config,
                &auction,
                label,
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                &mut ctx,
            );
            assert!(coin::value(&coin) == 1000000, 0);

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&nft);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            registrar::assert_registrar_exists(&suins, SUI_REGISTRAR);

            assert!(controller::balance(&suins) == 2000000, 0);
            assert!(name == utf8(FIRST_NODE), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );

            let (expiry, owner) = registrar::get_record_detail(&suins, SUI_REGISTRAR, FIRST_LABEL);
            assert!(expiry == 51 + 730, 0);
            assert!(owner== FIRST_USER_ADDRESS, 0);

            let (owner, resolver, ttl) = registry::get_record_by_key(&suins, utf8(FIRST_NODE));
            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(resolver == FIRST_RESOLVER_ADDRESS, 0);
            assert!(ttl == 0, 0);

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_register_with_code_apply_both_types_of_code() {
        let scenario = test_init();
        make_commitment(&mut scenario, option::none());
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            // simulate user wait for next epoch to call `register`
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                51,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            assert!(controller::balance(&suins) == 0, 0);
            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, FIRST_LABEL), 0);
            assert!(!registry::record_exists(&suins, utf8(FIRST_NODE)), 0);
            assert!(!test_scenario::has_most_recent_for_sender<RegistrationNFT>(&mut scenario), 0);
            assert!(!test_scenario::has_most_recent_for_address<Coin<SUI>>(SECOND_USER_ADDRESS), 0);

            controller::register_with_code(
                &mut suins,
                SUI_REGISTRAR,
                &mut config,
                &auction,
                FIRST_LABEL,
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                REFERRAL_CODE,
                DISCOUNT_CODE,
                &mut ctx,
            );
            assert!(coin::value(&coin) == 1300000, 0);

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&nft);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let coin = test_scenario::take_from_address<Coin<SUI>>(&mut scenario, SECOND_USER_ADDRESS);
            
            registrar::assert_registrar_exists(&suins, SUI_REGISTRAR);
            
            assert!(name == utf8(FIRST_NODE), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );
            assert!(coin::value(&coin) == 170000, 0);
            assert!(controller::balance(&suins) == 1700000 - 170000, 0);

            let (expiry, owner) = registrar::get_record_detail(&suins, SUI_REGISTRAR, FIRST_LABEL);
            assert!(expiry == 51 + 730, 0);
            assert!(owner== FIRST_USER_ADDRESS, 0);

            let (owner, resolver, ttl) = registry::get_record_by_key(&suins, utf8(FIRST_NODE));
            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(resolver == @0x0, 0);
            assert!(ttl == 0, 0);

            coin::destroy_for_testing(coin);
            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = configuration::EReferralCodeNotExists)]
    fun test_register_with_code_if_use_wrong_referral_code() {
        let scenario = test_init();
        make_commitment(&mut scenario, option::none());
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                51,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, FIRST_LABEL), 0);
            controller::register_with_code(
                &mut suins,
                SUI_REGISTRAR,
                &mut config,
                &auction,
                FIRST_LABEL,
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                DISCOUNT_CODE,
                DISCOUNT_CODE,
                &mut ctx,
            );

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = configuration::EDiscountCodeNotExists)]
    fun test_register_with_code_if_use_wrong_discount_code() {
        let scenario = test_init();
        make_commitment(&mut scenario, option::none());
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                51,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, FIRST_LABEL), 0);
            controller::register_with_code(
                &mut suins,
                SUI_REGISTRAR,
                &mut config,
                &auction,
                FIRST_LABEL,
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                REFERRAL_CODE,
                REFERRAL_CODE,
                &mut ctx,
            );

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_register_with_config_and_code_apply_both_types_of_code() {
        let scenario = test_init();
        make_commitment(&mut scenario, option::none());
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                51,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            assert!(controller::balance(&suins) == 0, 0);
            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, FIRST_LABEL), 0);
            assert!(!registry::record_exists(&suins, utf8(FIRST_NODE)), 0);
            assert!(!test_scenario::has_most_recent_for_sender<RegistrationNFT>(&mut scenario), 0);
            assert!(!test_scenario::has_most_recent_for_address<Coin<SUI>>(SECOND_USER_ADDRESS), 0);

            controller::register_with_config_and_code(
                &mut suins,
                SUI_REGISTRAR,
                &mut config,
                &auction,
                FIRST_LABEL,
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                FIRST_RESOLVER_ADDRESS,
                &mut coin,
                REFERRAL_CODE,
                DISCOUNT_CODE,
                &mut ctx,
            );
            assert!(coin::value(&coin) == 1300000, 0);
            coin::destroy_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&nft);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let coin = test_scenario::take_from_address<Coin<SUI>>(&mut scenario, SECOND_USER_ADDRESS);
            
            registrar::assert_registrar_exists(&suins, SUI_REGISTRAR);
            
            assert!(name == utf8(FIRST_NODE), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );
            assert!(coin::value(&coin) == 170000, 0);
            assert!(controller::balance(&suins) == 1700000 - 170000, 0);

            let (expiry, owner) = registrar::get_record_detail(&suins, SUI_REGISTRAR, FIRST_LABEL);
            assert!(expiry == 51 + 730, 0);
            assert!(owner== FIRST_USER_ADDRESS, 0);

            let (owner, resolver, ttl) = registry::get_record_by_key(&suins, utf8(FIRST_NODE));
            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(resolver == FIRST_RESOLVER_ADDRESS, 0);
            assert!(ttl == 0, 0);

            coin::destroy_for_testing(coin);
            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = configuration::EReferralCodeNotExists)]
    fun test_register_with_config_and_code_if_use_wrong_referral_code() {
        let scenario = test_init();
        make_commitment(&mut scenario, option::none());
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                51,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, FIRST_LABEL), 0);
            controller::register_with_config_and_code(
                &mut suins,
                SUI_REGISTRAR,
                &mut config,
                &auction,
                FIRST_LABEL,
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                FIRST_RESOLVER_ADDRESS,
                &mut coin,
                DISCOUNT_CODE,
                DISCOUNT_CODE,
                &mut ctx,
            );

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = configuration::EDiscountCodeNotExists)]
    fun test_register_with_config_and_code_if_use_wrong_discount_code() {
        let scenario = test_init();
        make_commitment(&mut scenario, option::none());
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                51,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, FIRST_LABEL), 0);
            controller::register_with_config_and_code(
                &mut suins,
                SUI_REGISTRAR,
                &mut config,
                &auction,
                FIRST_LABEL,
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                FIRST_RESOLVER_ADDRESS,
                &mut coin,
                REFERRAL_CODE,
                REFERRAL_CODE,
                &mut ctx,
            );
            coin::destroy_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario);
    }

    fun set_auction_config(scenario: &mut Scenario) {
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
            let auction = test_scenario::take_shared<Auction>(scenario);

            auction::configure_auction(
                &admin_cap,
                &mut auction,
                START_AUCTION_START_AT,
                START_AUCTION_END_AT,
                test_scenario::ctx(scenario)
            );

            test_scenario::return_shared(auction);
            test_scenario::return_to_sender(scenario, admin_cap);
        };
    }

    #[test, expected_failure(abort_code = emoji::EInvalidLabel)]
    fun test_register_abort_if_register_short_domain_while_auction_not_start_yet() {
        let scenario = test_init();
        set_auction_config(&mut scenario);

        make_commitment(&mut scenario, option::none());
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                21,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            controller::register(
                &mut suins,
                SUI_REGISTRAR,
                &mut config,
                &auction,
                AUCTIONED_LABEL,
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                &mut ctx,
            );

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_register_work_if_register_long_domain_while_auction_not_start_yet() {
        let scenario = test_init();
        set_auction_config(&mut scenario);

        make_commitment(&mut scenario, option::none());
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                21,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            controller::register(
                &mut suins,
                SUI_REGISTRAR,
                &mut config,
                &auction,
                FIRST_LABEL,
                FIRST_USER_ADDRESS,
                1,
                FIRST_SECRET,
                &mut coin,
                &mut ctx,
            );

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&nft);

            registrar::assert_registrar_exists(&suins, SUI_REGISTRAR);

            assert!(controller::balance(&suins) == 1000000, 0);
            assert!(name == utf8(FIRST_NODE), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );

            let (expiry, owner) = registrar::get_record_detail(&suins, SUI_REGISTRAR, FIRST_LABEL);
            assert!(expiry == 21 + 365, 0);
            assert!(owner== FIRST_USER_ADDRESS, 0);

            let (owner, resolver, ttl) = registry::get_record_by_key(&suins, utf8(FIRST_NODE));
            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(resolver == @0x0, 0);
            assert!(ttl == 0, 0);

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = emoji::EInvalidLabel)]
    fun test_register_abort_if_register_short_domain_while_auction_is_happening() {
        let scenario = test_init();
        set_auction_config(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                71,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            controller::register(
                &mut suins,
                SUI_REGISTRAR,
                &mut config,
                &auction,
                AUCTIONED_LABEL,
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                &mut ctx,
            );

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_register_work_if_register_lonng_domain_while_auction_is_happening() {
        let scenario = test_init();
        set_auction_config(&mut scenario);

        make_commitment(&mut scenario, some(FIRST_LABEL));
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                51,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            controller::register(
                &mut suins,
                SUI_REGISTRAR,
                &mut config,
                &auction,
                FIRST_LABEL,
                FIRST_USER_ADDRESS,
                1,
                FIRST_SECRET,
                &mut coin,
                &mut ctx,
            );

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&nft);

            registrar::assert_registrar_exists(&suins, SUI_REGISTRAR);

            assert!(controller::balance(&suins) == 1000000, 0);
            assert!(name == utf8(FIRST_NODE), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );

            let (expiry, owner) = registrar::get_record_detail(&suins, SUI_REGISTRAR, FIRST_LABEL);
            assert!(expiry == 51 + 365, 0);
            assert!(owner== FIRST_USER_ADDRESS, 0);

            let (owner, resolver, ttl) = registry::get_record_by_key(&suins, utf8(FIRST_NODE));
            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(resolver == @0x0, 0);
            assert!(ttl == 0, 0);

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_register_work_for_long_domain_if_auction_is_over() {
        let scenario = test_init();
        set_auction_config(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                220,
                0
            );
            let commitment = controller::test_make_commitment(
                SUI_REGISTRAR,
                FIRST_LABEL,
                FIRST_USER_ADDRESS,
                FIRST_SECRET
            );

            controller::commit(
                &mut suins,
                commitment,
                &mut ctx,
            );

            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                221,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            controller::register(
                &mut suins,
                SUI_REGISTRAR,
                &mut config,
                &auction,
                FIRST_LABEL,
                FIRST_USER_ADDRESS,
                1,
                FIRST_SECRET,
                &mut coin,
                &mut ctx,
            );

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&nft);

            registrar::assert_registrar_exists(&suins, SUI_REGISTRAR);

            assert!(controller::balance(&suins) == 1000000, 0);
            assert!(name == utf8(FIRST_NODE), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );

            let (expiry, owner) = registrar::get_record_detail(&suins, SUI_REGISTRAR, FIRST_LABEL);
            assert!(expiry == 221 + 365, 0);
            assert!(owner== FIRST_USER_ADDRESS, 0);

            let (owner, resolver, ttl) = registry::get_record_by_key(&suins, utf8(FIRST_NODE));
            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(resolver == @0x0, 0);
            assert!(ttl == 0, 0);

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_register_work_for_short_domain_if_auction_is_over() {
        let scenario = test_init();
        set_auction_config(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                220,
                0
            );
            let commitment = controller::test_make_commitment(
                SUI_REGISTRAR,
                AUCTIONED_LABEL,
                FIRST_USER_ADDRESS,
                FIRST_SECRET
            );

            controller::commit(
                &mut suins,
                commitment,
                &mut ctx,
            );

            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                221,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            controller::register(
                &mut suins,
                SUI_REGISTRAR,
                &mut config,
                &auction,
                AUCTIONED_LABEL,
                FIRST_USER_ADDRESS,
                1,
                FIRST_SECRET,
                &mut coin,
                &mut ctx,
            );

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&nft);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            registrar::assert_registrar_exists(&suins, SUI_REGISTRAR);

            assert!(controller::balance(&suins) == 1000000, 0);
            assert!(name == utf8(AUCTIONED_NODE), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );

            let (expiry, owner) = registrar::get_record_detail(&suins, SUI_REGISTRAR, AUCTIONED_LABEL);
            assert!(expiry == 221 + 365, 0);
            assert!(owner== FIRST_USER_ADDRESS, 0);

            let (owner, resolver, ttl) = registry::get_record_by_key(&suins, utf8(AUCTIONED_NODE));
            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(resolver == @0x0, 0);
            assert!(ttl == 0, 0);

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_register_work_if_name_not_wait_for_being_finalized() {
        let scenario = test_init();
        set_auction_config(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                120,
                0
            );
            let commitment = controller::test_make_commitment(
                SUI_REGISTRAR,
                FIRST_LABEL,
                FIRST_USER_ADDRESS,
                FIRST_SECRET
            );

            controller::commit(
                &mut suins,
                commitment,
                &mut ctx,
            );

            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                121,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            controller::register(
                &mut suins,
                SUI_REGISTRAR,
                &mut config,
                &auction,
                FIRST_LABEL,
                FIRST_USER_ADDRESS,
                1,
                FIRST_SECRET,
                &mut coin,
                &mut ctx,
            );

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&nft);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            registrar::assert_registrar_exists(&suins, SUI_REGISTRAR);

            assert!(controller::balance(&suins) == 1000000, 0);
            assert!(name == utf8(FIRST_NODE), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );

            let (expiry, owner) = registrar::get_record_detail(&suins, SUI_REGISTRAR, FIRST_LABEL);
            assert!(expiry == 121 + 365, 0);
            assert!(owner== FIRST_USER_ADDRESS, 0);

            let (owner, resolver, ttl) = registry::get_record_by_key(&suins, utf8(FIRST_NODE));
            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(resolver == @0x0, 0);
            assert!(ttl == 0, 0);

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = controller::ELabelUnAvailable)]
    fun test_register_abort_if_name_are_waiting_for_being_finalized() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        start_an_auction_util(&mut scenario, AUCTIONED_LABEL);
        let seal_bid = make_seal_bid(AUCTIONED_LABEL, FIRST_USER_ADDRESS, 1000, b"CnRGhPvfCu");
        place_bid_util(&mut scenario, seal_bid, 1100, FIRST_USER_ADDRESS);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<Auction>(&mut scenario);

            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                AUCTIONED_LABEL,
                1000,
                b"CnRGhPvfCu",
                FIRST_USER_ADDRESS,
                2
            );

            test_scenario::return_shared(auction);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                120,
                0
            );
            let commitment = controller::test_make_commitment(
                SUI_REGISTRAR,
                FIRST_LABEL,
                FIRST_USER_ADDRESS,
                FIRST_SECRET
            );

            controller::commit(
                &mut suins,
                commitment,
                &mut ctx,
            );

            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AUCTION_END_AT + BIDDING_PERIOD + REVEAL_PERIOD + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            controller::register(
                &mut suins,
                SUI_REGISTRAR,
                &mut config,
                &auction,
                AUCTIONED_LABEL,
                FIRST_USER_ADDRESS,
                1,
                FIRST_SECRET,
                &mut coin,
                &mut ctx,
            );

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = emoji::EInvalidLabel)]
    fun test_register_abort_if_name_are_waiting_for_being_finalized_2() {
        let scenario = test_init();
        set_auction_config(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AUCTION_END_AT + 1,
                0
            );
            let commitment = controller::test_make_commitment(
                SUI_REGISTRAR,
                FIRST_LABEL,
                FIRST_USER_ADDRESS,
                FIRST_SECRET
            );

            controller::commit(
                &mut suins,
                commitment,
                &mut ctx,
            );

            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AUCTION_END_AT + 2,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            controller::register(
                &mut suins,
                SUI_REGISTRAR,
                &mut config,
                &auction,
                AUCTIONED_LABEL,
                FIRST_USER_ADDRESS,
                1,
                FIRST_SECRET,
                &mut coin,
                &mut ctx,
            );

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = controller::ERegistrationIsDisabled)]
    fun test_register_abort_if_registration_is_disabled() {
        let scenario = test_init();
        set_auction_config(&mut scenario);

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            configuration::set_enable_controller(&admin_cap, &mut config, false);
            test_scenario::return_to_sender(&mut scenario, admin_cap);
            test_scenario::return_shared(config);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                220,
                0
            );
            let commitment = controller::test_make_commitment(
                SUI_REGISTRAR,
                AUCTIONED_LABEL,
                FIRST_USER_ADDRESS,
                FIRST_SECRET
            );

            controller::commit(
                &mut suins,
                commitment,
                &mut ctx,
            );

            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                221,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            controller::register(
                &mut suins,
                SUI_REGISTRAR,
                &mut config,
                &auction,
                AUCTIONED_LABEL,
                FIRST_USER_ADDRESS,
                1,
                FIRST_SECRET,
                &mut coin,
                &mut ctx,
            );

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&nft);

            assert!(controller::balance(&suins) == 1000000, 0);
            assert!(name == utf8(AUCTIONED_NODE), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );

            let (expiry, owner) = registrar::get_record_detail(&suins, SUI_REGISTRAR, FIRST_LABEL);
            assert!(expiry == 221 + 365, 0);
            assert!(owner == FIRST_USER_ADDRESS, 0);

            let (owner, resolver, ttl) = registry::get_record_by_key(&suins, utf8(AUCTIONED_NODE));
            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(resolver == @0x0, 0);
            assert!(ttl == 0, 0);

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = controller::ERegistrationIsDisabled)]
    fun test_register_abort_if_registration_is_disabled_2() {
        let scenario = test_init();
        set_auction_config(&mut scenario);

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            configuration::set_enable_controller(&admin_cap, &mut config, false);
            test_scenario::return_to_sender(&mut scenario, admin_cap);
            test_scenario::return_shared(config);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                220,
                0
            );
            let commitment = controller::test_make_commitment(
                SUI_REGISTRAR,
                AUCTIONED_LABEL,
                FIRST_USER_ADDRESS,
                FIRST_SECRET
            );

            controller::commit(
                &mut suins,
                commitment,
                &mut ctx,
            );

            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                221,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            controller::register(
                &mut suins,
                SUI_REGISTRAR,
                &mut config,
                &auction,
                AUCTIONED_LABEL,
                FIRST_USER_ADDRESS,
                1,
                FIRST_SECRET,
                &mut coin,
                &mut ctx,
            );

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&nft);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            registrar::assert_registrar_exists(&suins, SUI_REGISTRAR);

            assert!(controller::balance(&suins) == 1000000, 0);
            assert!(name == utf8(AUCTIONED_NODE), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b""),
                0
            );

            let (expiry, owner) = registrar::get_record_detail(&suins, SUI_REGISTRAR, FIRST_LABEL);
            assert!(expiry == 221 + 365, 0);
            assert!(owner== FIRST_USER_ADDRESS, 0);

            let (owner, resolver, ttl) = registry::get_record_by_key(&suins, utf8(AUCTIONED_NODE));
            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(resolver == @0x0, 0);
            assert!(ttl == 0, 0);

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_register_works_if_registration_is_reenabled() {
        let scenario = test_init();
        set_auction_config(&mut scenario);

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);

            configuration::set_enable_controller(&admin_cap, &mut config, false);

            test_scenario::return_to_sender(&mut scenario, admin_cap);
            test_scenario::return_shared(config);
        };
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);

            configuration::set_enable_controller(&admin_cap, &mut config, true);

            test_scenario::return_to_sender(&mut scenario, admin_cap);
            test_scenario::return_shared(config);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                220,
                0
            );
            let commitment = controller::test_make_commitment(
                SUI_REGISTRAR,
                AUCTIONED_LABEL,
                FIRST_USER_ADDRESS,
                FIRST_SECRET
            );

            controller::commit(
                &mut suins,
                commitment,
                &mut ctx,
            );

            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                221,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            controller::register(
                &mut suins,
                SUI_REGISTRAR,
                &mut config,
                &auction,
                AUCTIONED_LABEL,
                FIRST_USER_ADDRESS,
                1,
                FIRST_SECRET,
                &mut coin,
                &mut ctx,
            );

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&nft);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            registrar::assert_registrar_exists(&suins, SUI_REGISTRAR);

            assert!(controller::balance(&suins) == 1000000, 0);
            assert!(name == utf8(AUCTIONED_NODE), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );

            let (expiry, owner) = registrar::get_record_detail(&suins, SUI_REGISTRAR, AUCTIONED_LABEL);
            assert!(expiry == 221 + 365, 0);
            assert!(owner == FIRST_USER_ADDRESS, 0);

            let (owner, resolver, ttl) = registry::get_record_by_key(&suins, utf8(AUCTIONED_NODE));
            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(resolver == @0x0, 0);
            assert!(ttl == 0, 0);

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_commit_removes_only_50_outdated() {
        let scenario = test_init();

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                47,
                0
            );
            let i: u8 = 0;

            while (i < 70) {
                let secret = FIRST_SECRET;
                vector::push_back(&mut secret, i);
                let commitment = controller::test_make_commitment(SUI_REGISTRAR, FIRST_LABEL, FIRST_USER_ADDRESS, secret);
                controller::commit(
                    &mut suins,
                    commitment,
                    &mut ctx,
                );

                i = i + 1;
            };

            assert!(controller::commitment_len(&suins) == 70, 0);
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                50,
                0
            );
            let commitment = controller::test_make_commitment(SUI_REGISTRAR, b"label-1", FIRST_USER_ADDRESS, FIRST_SECRET);
            controller::commit(
                &mut suins,
                commitment,
                &mut ctx,
            );
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            assert!(controller::commitment_len(&suins) == 21, 0);
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                50,
                0
            );
            let commitment = controller::test_make_commitment(SUI_REGISTRAR, b"label-2", FIRST_USER_ADDRESS, FIRST_SECRET);
            controller::commit(
                &mut suins,
                commitment,
                &mut ctx,
            );
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            assert!(controller::commitment_len(&suins) == 2, 0);
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                51,
                0
            );
            let commitment = controller::test_make_commitment(SUI_REGISTRAR, b"label-3", FIRST_USER_ADDRESS, FIRST_SECRET);
            controller::commit(
                &mut suins,
                commitment,
                &mut ctx,
            );
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            assert!(controller::commitment_len(&suins) == 3, 0);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_commit_removes_only_50_outdated_2() {
        let scenario = test_init();

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                47,
                0
            );
            let i: u8 = 0;

            while (i < 40) {
                let secret = FIRST_SECRET;
                vector::push_back(&mut secret, i);
                let commitment = controller::test_make_commitment(SUI_REGISTRAR, FIRST_LABEL, FIRST_USER_ADDRESS, secret);
                controller::commit(
                    &mut suins,
                    commitment,
                    &mut ctx,
                );

                i = i + 1;
            };
            assert!(controller::commitment_len(&suins) == 40, 0);
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                50,
                0
            );
            let commitment = controller::test_make_commitment(SUI_REGISTRAR, b"label-2", FIRST_USER_ADDRESS, FIRST_SECRET);
            controller::commit(
                &mut suins,
                commitment,
                &mut ctx,
            );
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            assert!(controller::commitment_len(&suins) == 1, 0);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registrar::EInvalidImageMessage)]
    fun test_register_with_image_aborts_with_empty_signature() {
        let scenario = test_init();
        make_commitment(&mut scenario, option::none());

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                21,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            controller::register_with_image(
                &mut suins,
                SUI_REGISTRAR,
                &mut config,
                &auction,
                FIRST_LABEL,
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                x"",
                x"127552ffa7fb7c3718ee61851c49eba03ef7d0dc0933c7c5802cdd98226f6006",
                b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,000000000000000000000000000000000000b001,375",
                &mut ctx,
            );

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registrar::EInvalidImageMessage)]
    fun test_register_with_image_aborts_with_empty_hashed_message() {
        let scenario = test_init();
        make_commitment(&mut scenario, option::none());

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                21,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            controller::register_with_image(
                &mut suins,
                SUI_REGISTRAR,
                &mut config,
                &auction,
                FIRST_LABEL,
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                x"6aab9920d59442c5478c3f5b29db45518b40a3d76f1b396b70c902b557e93b206b0ce9ab84ce44277d84055da9dd10ff77c490ba8473cd86ead37be874b9662f",
                x"",
                b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,000000000000000000000000000000000000b001,375",
                &mut ctx,
            );

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registrar::EInvalidImageMessage)]
    fun test_register_with_image_aborts_with_empty_raw_message() {
        let scenario = test_init();
        make_commitment(&mut scenario, option::none());

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                21,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            controller::register_with_image(
                &mut suins,
                SUI_REGISTRAR,
                &mut config,
                &auction,
                FIRST_LABEL,
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                x"6aab9920d59442c5478c3f5b29db45518b40a3d76f1b396b70c902b557e93b206b0ce9ab84ce44277d84055da9dd10ff77c490ba8473cd86ead37be874b9662f",
                x"127552ffa7fb7c3718ee61851c49eba03ef7d0dc0933c7c5802cdd98226f6006",
                b"",
                &mut ctx,
            );

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_register_with_image() {
        let scenario = test_init();
        make_commitment(&mut scenario, option::none());

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                21,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, FIRST_LABEL), 0);
            assert!(controller::balance(&suins) == 0, 0);
            assert!(controller::commitment_len(&suins) == 1, 0);
            assert!(!registry::record_exists(&suins, utf8(FIRST_NODE)), 0);
            assert!(!test_scenario::has_most_recent_for_sender<RegistrationNFT>(&mut scenario), 0);

            controller::register_with_image(
                &mut suins,
                SUI_REGISTRAR,
                &mut config,
                &auction,
                FIRST_LABEL,
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                x"b8d5c020ccf043fb1dde772067d54e254041ec4c8e137f5017158711e59e86933d1889cf4d9c6ad8ef57290cc00d99b7ba60da5c0db64a996f72af010acdd2b0",
                x"64d1c3d80ac32235d4bf1c5499ac362fd28b88eba2984e81cc36924be09f5a2d",
                b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,eastagile-123.sui,751",
                &mut ctx,
            );
            assert!(coin::value(&coin) == 1000000, 0);
            assert!(controller::commitment_len(&suins) == 0, 0);

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&nft);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            registrar::assert_registrar_exists(&suins, SUI_REGISTRAR);

            assert!(controller::balance(&suins) == 2000000, 0);
            assert!(name == utf8(FIRST_NODE), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k"),
                0
            );

            let (expiry, owner) = registrar::get_record_detail(&suins, SUI_REGISTRAR, FIRST_LABEL);
            assert!(expiry == 21 + 730, 0);
            assert!(owner== FIRST_USER_ADDRESS, 0);

            let (owner, resolver, ttl) = registry::get_record_by_key(&suins, utf8(FIRST_NODE));
            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(resolver == @0x0, 0);
            assert!(ttl == 0, 0);

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_register_with_config_and_image() {
        let scenario = test_init();
        make_commitment(&mut scenario, option::none());

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                21,
                0
            );
            let coin = coin::mint_for_testing<SUI>(4000001, &mut ctx);

            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, FIRST_LABEL), 0);
            assert!(!registry::record_exists(&suins, utf8(FIRST_NODE)), 0);
            assert!(controller::balance(&suins) == 0, 0);
            assert!(!test_scenario::has_most_recent_for_sender<RegistrationNFT>(&mut scenario), 0);

            controller::register_with_config_and_image(
                &mut suins,
                SUI_REGISTRAR,
                &mut config,
                &auction,
                FIRST_LABEL,
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                FIRST_RESOLVER_ADDRESS,
                &mut coin,
                x"b8d5c020ccf043fb1dde772067d54e254041ec4c8e137f5017158711e59e86933d1889cf4d9c6ad8ef57290cc00d99b7ba60da5c0db64a996f72af010acdd2b0",
                x"64d1c3d80ac32235d4bf1c5499ac362fd28b88eba2984e81cc36924be09f5a2d",
                b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,eastagile-123.sui,751",
                &mut ctx,
            );
            assert!(coin::value(&coin) == 2000001, 0);

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&nft);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            registrar::assert_registrar_exists(&suins, SUI_REGISTRAR);

            assert!(controller::balance(&suins) == 2000000, 0);
            assert!(name == utf8(FIRST_NODE), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k"),
                0
            );

            let (expiry, owner) = registrar::get_record_detail(&suins, SUI_REGISTRAR, FIRST_LABEL);
            assert!(expiry == 21 + 730, 0);
            assert!(owner== FIRST_USER_ADDRESS, 0);

            let (owner, resolver, ttl) = registry::get_record_by_key(&suins, utf8(FIRST_NODE));
            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(resolver == FIRST_RESOLVER_ADDRESS, 0);
            assert!(ttl == 0, 0);

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(suins);
        };

        // withdraw
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            assert!(controller::balance(&suins) == 2000000, 0);
            assert!(!test_scenario::has_most_recent_for_sender<Coin<SUI>>(&mut scenario), 0);

            controller::withdraw(&admin_cap, &mut suins, test_scenario::ctx(&mut scenario));
            assert!(controller::balance(&suins) == 0, 0);

            test_scenario::return_shared(suins);
            test_scenario::return_to_sender(&mut scenario, admin_cap);
        };

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            assert!(test_scenario::has_most_recent_for_sender<Coin<SUI>>(&mut scenario), 0);
            let coin = test_scenario::take_from_sender<Coin<SUI>>(&mut scenario);
            assert!(coin::value(&coin) == 2000000, 0);
            test_scenario::return_to_sender(&mut scenario, coin);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registrar::EInvalidImageMessage)]
    fun test_register_with_config_and_image_aborts_with_empty_raw_message() {
        let scenario = test_init();
        make_commitment(&mut scenario, option::none());

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                21,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            controller::register_with_config_and_image(
                &mut suins,
                SUI_REGISTRAR,
                &mut config,
                &auction,
                FIRST_LABEL,
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                FIRST_RESOLVER_ADDRESS,
                &mut coin,
                x"b8d5c020ccf043fb1dde772067d54e254041ec4c8e137f5017158711e59e86933d1889cf4d9c6ad8ef57290cc00d99b7ba60da5c0db64a996f72af010acdd2b0",
                x"64d1c3d80ac32235d4bf1c5499ac362fd28b88eba2984e81cc36924be09f5a2d",
                b"",
                &mut ctx,
            );

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registrar::EInvalidImageMessage)]
    fun test_register_with_config_and_image_aborts_with_empty_signature() {
        let scenario = test_init();
        make_commitment(&mut scenario, option::none());

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                21,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            controller::register_with_config_and_image(
                &mut suins,
                SUI_REGISTRAR,
                &mut config,
                &auction,
                FIRST_LABEL,
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                FIRST_RESOLVER_ADDRESS,
                &mut coin,
                x"",
                x"64d1c3d80ac32235d4bf1c5499ac362fd28b88eba2984e81cc36924be09f5a2d",
                b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,eastagile-123.sui,751",
                &mut ctx,
            );

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registrar::EInvalidImageMessage)]
    fun test_register_with_config_and_image_aborts_with_empty_hashed_message() {
        let scenario = test_init();
        make_commitment(&mut scenario, option::none());

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                21,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            controller::register_with_config_and_image(
                &mut suins,
                SUI_REGISTRAR,
                &mut config,
                &auction,
                FIRST_LABEL,
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                FIRST_RESOLVER_ADDRESS,
                &mut coin,
                x"b8d5c020ccf043fb1dde772067d54e254041ec4c8e137f5017158711e59e86933d1889cf4d9c6ad8ef57290cc00d99b7ba60da5c0db64a996f72af010acdd2b0",
                x"",
                b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,eastagile-123.sui,751",
                &mut ctx,
            );

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_register_with_code_and_image() {
        let scenario = test_init();
        make_commitment(&mut scenario, option::none());
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            // simulate user wait for next epoch to call `register`
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                21,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            assert!(controller::balance(&suins) == 0, 0);
            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, FIRST_LABEL), 0);
            assert!(!registry::record_exists(&suins, utf8(FIRST_NODE)), 0);
            assert!(!test_scenario::has_most_recent_for_sender<RegistrationNFT>(&mut scenario), 0);
            assert!(!test_scenario::has_most_recent_for_address<Coin<SUI>>(SECOND_USER_ADDRESS), 0);

            controller::register_with_code_and_image(
                &mut suins,
                SUI_REGISTRAR,
                &mut config,
                &auction,
                FIRST_LABEL,
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                REFERRAL_CODE,
                DISCOUNT_CODE,
                x"b8d5c020ccf043fb1dde772067d54e254041ec4c8e137f5017158711e59e86933d1889cf4d9c6ad8ef57290cc00d99b7ba60da5c0db64a996f72af010acdd2b0",
                x"64d1c3d80ac32235d4bf1c5499ac362fd28b88eba2984e81cc36924be09f5a2d",
                b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,eastagile-123.sui,751",
                &mut ctx,
            );
            assert!(coin::value(&coin) == 1300000, 0);

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&nft);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let coin = test_scenario::take_from_address<Coin<SUI>>(&mut scenario, SECOND_USER_ADDRESS);

            registrar::assert_registrar_exists(&suins, SUI_REGISTRAR);

            assert!(name == utf8(FIRST_NODE), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k"),
                0
            );
            assert!(coin::value(&coin) == 170000, 0);
            assert!(controller::balance(&suins) == 1700000 - 170000, 0);

            let (expiry, owner) = registrar::get_record_detail(&suins, SUI_REGISTRAR, FIRST_LABEL);
            assert!(expiry == 21 + 730, 0);
            assert!(owner== FIRST_USER_ADDRESS, 0);

            let (owner, resolver, ttl) = registry::get_record_by_key(&suins, utf8(FIRST_NODE));
            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(resolver == @0x0, 0);
            assert!(ttl == 0, 0);

            coin::destroy_for_testing(coin);
            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registrar::EInvalidImageMessage)]
    fun test_register_with_code_and_image_aborts_with_empty_signature() {
        let scenario = test_init();
        make_commitment(&mut scenario, option::none());

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                21,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            controller::register_with_code_and_image(
                &mut suins,
                SUI_REGISTRAR,
                &mut config,
                &auction,
                FIRST_LABEL,
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                REFERRAL_CODE,
                DISCOUNT_CODE,
                x"",
                x"64d1c3d80ac32235d4bf1c5499ac362fd28b88eba2984e81cc36924be09f5a2d",
                b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,eastagile-123.sui,751",
                &mut ctx,
            );

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registrar::EInvalidImageMessage)]
    fun test_register_with_code_and_image_aborts_with_empty_hashed_message() {
        let scenario = test_init();
        make_commitment(&mut scenario, option::none());

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                21,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            controller::register_with_code_and_image(
                &mut suins,
                SUI_REGISTRAR,
                &mut config,
                &auction,
                FIRST_LABEL,
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                REFERRAL_CODE,
                DISCOUNT_CODE,
                x"b8d5c020ccf043fb1dde772067d54e254041ec4c8e137f5017158711e59e86933d1889cf4d9c6ad8ef57290cc00d99b7ba60da5c0db64a996f72af010acdd2b0",
                x"",
                b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,eastagile-123.sui,751",
                &mut ctx,
            );

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registrar::EInvalidImageMessage)]
    fun test_register_with_code_and_image_aborts_with_empty_raw_message() {
        let scenario = test_init();
        make_commitment(&mut scenario, option::none());

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                21,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            controller::register_with_code_and_image(
                &mut suins,
                SUI_REGISTRAR,
                &mut config,
                &auction,
                FIRST_LABEL,
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                REFERRAL_CODE,
                DISCOUNT_CODE,
                x"b8d5c020ccf043fb1dde772067d54e254041ec4c8e137f5017158711e59e86933d1889cf4d9c6ad8ef57290cc00d99b7ba60da5c0db64a996f72af010acdd2b0",
                x"64d1c3d80ac32235d4bf1c5499ac362fd28b88eba2984e81cc36924be09f5a2d",
                b"",
                &mut ctx,
            );

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_register_with_config_and_code_and_image() {
        let scenario = test_init();
        make_commitment(&mut scenario, option::none());
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                21,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            assert!(controller::balance(&suins) == 0, 0);
            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, FIRST_LABEL), 0);
            assert!(!registry::record_exists(&suins, utf8(FIRST_NODE)), 0);
            assert!(!test_scenario::has_most_recent_for_sender<RegistrationNFT>(&mut scenario), 0);
            assert!(!test_scenario::has_most_recent_for_address<Coin<SUI>>(SECOND_USER_ADDRESS), 0);

            controller::register_with_config_and_code_and_image(
                &mut suins,
                SUI_REGISTRAR,
                &mut config,
                &auction,
                FIRST_LABEL,
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                FIRST_RESOLVER_ADDRESS,
                &mut coin,
                REFERRAL_CODE,
                DISCOUNT_CODE,
                x"b8d5c020ccf043fb1dde772067d54e254041ec4c8e137f5017158711e59e86933d1889cf4d9c6ad8ef57290cc00d99b7ba60da5c0db64a996f72af010acdd2b0",
                x"64d1c3d80ac32235d4bf1c5499ac362fd28b88eba2984e81cc36924be09f5a2d",
                b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,eastagile-123.sui,751",
                &mut ctx,
            );
            assert!(coin::value(&coin) == 1300000, 0);
            coin::destroy_for_testing(coin);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let coin = test_scenario::take_from_address<Coin<SUI>>(&mut scenario, SECOND_USER_ADDRESS);
            let (name, url) = registrar::get_nft_fields(&nft);

            assert!(name == utf8(FIRST_NODE), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k"),
                0
            );
            assert!(coin::value(&coin) == 170000, 0);
            assert!(controller::balance(&suins) == 1700000 - 170000, 0);

            let (expiry, owner) = registrar::get_record_detail(&suins, SUI_REGISTRAR, FIRST_LABEL);
            assert!(expiry == 21 + 730, 0);
            assert!(owner== FIRST_USER_ADDRESS, 0);

            let (owner, resolver, ttl) = registry::get_record_by_key(&suins, utf8(FIRST_NODE));
            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(resolver == FIRST_RESOLVER_ADDRESS, 0);
            assert!(ttl == 0, 0);

            coin::destroy_for_testing(coin);
            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registrar::EInvalidImageMessage)]
    fun test_register_with_config_and_code_and_image_aborts_with_empty_signature() {
        let scenario = test_init();
        make_commitment(&mut scenario, option::none());
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                21,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            controller::register_with_config_and_code_and_image(
                &mut suins,
                SUI_REGISTRAR,
                &mut config,
                &auction,
                FIRST_LABEL,
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                FIRST_RESOLVER_ADDRESS,
                &mut coin,
                REFERRAL_CODE,
                DISCOUNT_CODE,
                x"",
                x"64d1c3d80ac32235d4bf1c5499ac362fd28b88eba2984e81cc36924be09f5a2d",
                b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,eastagile-123.sui,751",
                &mut ctx,
            );

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registrar::EInvalidImageMessage)]
    fun test_register_with_config_and_code_and_image_aborts_with_empty_hashed_message() {
        let scenario = test_init();
        make_commitment(&mut scenario, option::none());
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                21,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            controller::register_with_config_and_code_and_image(
                &mut suins,
                SUI_REGISTRAR,
                &mut config,
                &auction,
                FIRST_LABEL,
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                FIRST_RESOLVER_ADDRESS,
                &mut coin,
                REFERRAL_CODE,
                DISCOUNT_CODE,
                x"b8d5c020ccf043fb1dde772067d54e254041ec4c8e137f5017158711e59e86933d1889cf4d9c6ad8ef57290cc00d99b7ba60da5c0db64a996f72af010acdd2b0",
                x"",
                b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,eastagile-123.sui,751",
                &mut ctx,
            );

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registrar::EInvalidImageMessage)]
    fun test_register_with_config_and_code_and_image_aborts_with_empty_raw_message() {
        let scenario = test_init();
        make_commitment(&mut scenario, option::none());
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                21,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            controller::register_with_config_and_code_and_image(
                &mut suins,
                SUI_REGISTRAR,
                &mut config,
                &auction,
                FIRST_LABEL,
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                FIRST_RESOLVER_ADDRESS,
                &mut coin,
                REFERRAL_CODE,
                DISCOUNT_CODE,
                x"b8d5c020ccf043fb1dde772067d54e254041ec4c8e137f5017158711e59e86933d1889cf4d9c6ad8ef57290cc00d99b7ba60da5c0db64a996f72af010acdd2b0",
                x"64d1c3d80ac32235d4bf1c5499ac362fd28b88eba2984e81cc36924be09f5a2d",
                b"",
                &mut ctx,
            );

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_renew_with_image() {
        let scenario = test_init();
        register(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&nft);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            assert!(controller::balance(&suins) == 1000000, 0);
            assert!(name == utf8(b"eastagile-123.sui"), 0);
            assert!(url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"), 0);

            test_scenario::return_shared(suins);
            test_scenario::return_to_sender(&mut scenario, nft);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&scenario);
            let ctx = test_scenario::ctx(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(2000001, ctx);

            assert!(registrar::name_expires_at(&suins, SUI_REGISTRAR, FIRST_LABEL) == 416, 0);
            assert!(controller::balance(&suins) == 1000000, 0);

            controller::renew_with_image(
                &mut suins,
                SUI_REGISTRAR,
                &config,
                FIRST_LABEL,
                2,
                &mut coin,
                &mut nft,
                x"9d1b824b2c7c3649cc967465393cc00cfa3e4c8e542ef0175a0525f91cb80b8721370eb6ca3f36896e0b740f99ebd02ea3e50480b19ac66466045b3e4763b14f",
                x"8ae97b7af21e857a343b93f0ca8a132819aa4edd4bedcee3e3a37d8f9bb89821",
                b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,eastagile-123.sui,1146",
                ctx,
            );

            assert!(coin::value(&coin) == 1, 0);
            assert!(registrar::name_expires_at(&suins, SUI_REGISTRAR, FIRST_LABEL) == 1146, 0);

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
            test_scenario::return_to_sender(&mut scenario, nft);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&nft);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            assert!(controller::balance(&suins) == 3000000, 0);
            assert!(name == utf8(b"eastagile-123.sui"), 0);
            assert!(url == url::new_unsafe_from_bytes(b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k"), 0);

            test_scenario::return_shared(suins);
            test_scenario::return_to_sender(&mut scenario, nft);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registrar::EInvalidImageMessage)]
    fun test_renew_with_image_aborts_with_empty_signature() {
        let scenario = test_init();
        register(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&scenario);
            let ctx = test_scenario::ctx(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(2000001, ctx);

            controller::renew_with_image(
                &mut suins,
                SUI_REGISTRAR,
                &config,
                FIRST_LABEL,
                2,
                &mut coin,
                &mut nft,
                x"",
                x"8ae97b7af21e857a343b93f0ca8a132819aa4edd4bedcee3e3a37d8f9bb89821",
                b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,eastagile-123.sui,1146",
                ctx,
            );

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
            test_scenario::return_to_sender(&mut scenario, nft);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registrar::EInvalidImageMessage)]
    fun test_renew_with_image_aborts_with_empty_hashed_msg() {
        let scenario = test_init();
        register(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&scenario);
            let ctx = test_scenario::ctx(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(2000001, ctx);

            controller::renew_with_image(
                &mut suins,
                SUI_REGISTRAR,
                &config,
                FIRST_LABEL,
                2,
                &mut coin,
                &mut nft,
                x"a8ae97b7af21e87a343b93f0ca8a132819aa4edd4bedcee3e3a37d8f9bb89821",
                x"",
                b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,eastagile-123.sui,1146",
                ctx,
            );

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
            test_scenario::return_to_sender(&mut scenario, nft);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registrar::EInvalidImageMessage)]
    fun test_renew_with_image_aborts_with_empty_raw_msg() {
        let scenario = test_init();
        register(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&scenario);
            let ctx = test_scenario::ctx(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(2000001, ctx);

            controller::renew_with_image(
                &mut suins,
                SUI_REGISTRAR,
                &config,
                FIRST_LABEL,
                2,
                &mut coin,
                &mut nft,
                x"a8ae97b7af21e85a343b93f0ca8a132819aa4edd4bedcee3e3a37d8f9bb89821",
                x"a8ae97b7af21857a343b93f0ca8a132819aa4edd4bedcee3e3a37d8f9bb89821",
                b"",
                ctx,
            );

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
            test_scenario::return_to_sender(&mut scenario, nft);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registrar::ELabelExpired)]
    fun test_renew_with_image_aborts_if_being_called_too_late() {
        let scenario = test_init();
        register(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&scenario);
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                600,
                0
            );
            let coin = coin::mint_for_testing<SUI>(2000001, &mut ctx);

            assert!(registrar::name_expires_at(&suins, SUI_REGISTRAR, FIRST_LABEL) == 416, 0);

            controller::renew_with_image(
                &mut suins,
                SUI_REGISTRAR,
                &config,
                FIRST_LABEL,
                2,
                &mut coin,
                &mut nft,
                x"9d1b824b2c7c3649cc967465393cc00cfa3e4c8e542ef0175a0525f91cb80b8721370eb6ca3f36896e0b740f99ebd02ea3e50480b19ac66466045b3e4763b14f",
                x"8ae97b7af21e857a343b93f0ca8a132819aa4edd4bedcee3e3a37d8f9bb89821",
                b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,eastagile-123.sui,1146",
                &mut ctx,
            );

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
            test_scenario::return_to_sender(&mut scenario, nft);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_renew_with_image_works_if_being_called_in_grace_time() {
        let scenario = test_init();
        register(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&nft);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            assert!(controller::balance(&suins) == 1000000, 0);
            assert!(name == utf8(b"eastagile-123.sui"), 0);
            assert!(url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"), 0);

            test_scenario::return_shared(suins);
            test_scenario::return_to_sender(&mut scenario, nft);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&scenario);
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                450,
                0
            );
            let coin = coin::mint_for_testing<SUI>(2000001, &mut ctx);

            assert!(registrar::name_expires_at(&suins, SUI_REGISTRAR, FIRST_LABEL) == 416, 0);
            assert!(controller::balance(&suins) == 1000000, 0);

            controller::renew_with_image(
                &mut suins,
                SUI_REGISTRAR,
                &config,
                FIRST_LABEL,
                2,
                &mut coin,
                &mut nft,
                x"9d1b824b2c7c3649cc967465393cc00cfa3e4c8e542ef0175a0525f91cb80b8721370eb6ca3f36896e0b740f99ebd02ea3e50480b19ac66466045b3e4763b14f",
                x"8ae97b7af21e857a343b93f0ca8a132819aa4edd4bedcee3e3a37d8f9bb89821",
                b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,eastagile-123.sui,1146",
                &mut ctx,
            );

            assert!(coin::value(&coin) == 1, 0);
            assert!(registrar::name_expires_at(&suins, SUI_REGISTRAR, FIRST_LABEL) == 1146, 0);

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
            test_scenario::return_to_sender(&mut scenario, nft);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&nft);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            assert!(controller::balance(&suins) == 3000000, 0);
            assert!(name == utf8(b"eastagile-123.sui"), 0);
            assert!(url == url::new_unsafe_from_bytes(b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k"), 0);

            test_scenario::return_shared(suins);
            test_scenario::return_to_sender(&mut scenario, nft);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = controller::ELabelUnAvailable)]
    fun test_register_works_if_name_are_waiting_for_being_finalized_and_extra_time_not_passes() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        start_an_auction_util(&mut scenario, AUCTIONED_LABEL);
        let seal_bid = make_seal_bid(AUCTIONED_LABEL, FIRST_USER_ADDRESS, 1000, b"CnRGhPvfCu");
        place_bid_util(&mut scenario, seal_bid, 1100, FIRST_USER_ADDRESS);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                AUCTIONED_LABEL,
                1000,
                b"CnRGhPvfCu",
                FIRST_USER_ADDRESS,
                2
            );
            test_scenario::return_shared(auction);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AUCTION_END_AT + EXTRA_PERIOD,
                0
            );
            let commitment = controller::test_make_commitment(
                SUI_REGISTRAR,
                AUCTIONED_LABEL,
                FIRST_USER_ADDRESS,
                FIRST_SECRET
            );
            controller::commit(
                &mut suins,
                commitment,
                &mut ctx,
            );
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AUCTION_END_AT + EXTRA_PERIOD + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            controller::register(
                &mut suins,
                SUI_REGISTRAR,
                &mut config,
                &auction,
                AUCTIONED_LABEL,
                FIRST_USER_ADDRESS,
                1,
                FIRST_SECRET,
                &mut coin,
                &mut ctx,
            );

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_register_works_if_name_are_waiting_for_being_finalized_and_extra_time_passes() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        start_an_auction_util(&mut scenario, AUCTIONED_LABEL);
        let seal_bid = make_seal_bid(AUCTIONED_LABEL, FIRST_USER_ADDRESS, 1000, b"CnRGhPvfCu");
        place_bid_util(&mut scenario, seal_bid, 1100, FIRST_USER_ADDRESS);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            reveal_bid_util(
                &mut auction,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                AUCTIONED_LABEL,
                1000,
                b"CnRGhPvfCu",
                FIRST_USER_ADDRESS,
                2
            );
            test_scenario::return_shared(auction);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AUCTION_END_AT + BIDDING_PERIOD + REVEAL_PERIOD + EXTRA_PERIOD,
                0
            );
            let commitment = controller::test_make_commitment(
                SUI_REGISTRAR,
                AUCTIONED_LABEL,
                FIRST_USER_ADDRESS,
                FIRST_SECRET
            );
            controller::commit(
                &mut suins,
                commitment,
                &mut ctx,
            );
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                START_AUCTION_END_AT + BIDDING_PERIOD + REVEAL_PERIOD + EXTRA_PERIOD + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            controller::register(
                &mut suins,
                SUI_REGISTRAR,
                &mut config,
                &auction,
                AUCTIONED_LABEL,
                FIRST_USER_ADDRESS,
                1,
                FIRST_SECRET,
                &mut coin,
                &mut ctx,
            );

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&nft);

            assert!(controller::balance(&suins) == 1000000, 0);
            assert!(name == utf8(AUCTIONED_NODE), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );

            let (expiry, owner) = registrar::get_record_detail(&suins, SUI_REGISTRAR, AUCTIONED_LABEL);
            assert!(
                expiry ==
                    START_AUCTION_END_AT + BIDDING_PERIOD + REVEAL_PERIOD + EXTRA_PERIOD + 1 + 365,
                0
            );
            assert!(owner == FIRST_USER_ADDRESS, 0);

            let (owner, resolver, ttl) = registry::get_record_by_key(&suins, utf8(AUCTIONED_NODE));

            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(resolver == @0x0, 0);
            assert!(ttl == 0, 0);

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }
}
