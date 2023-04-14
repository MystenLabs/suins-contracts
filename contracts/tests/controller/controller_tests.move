#[test_only]
module suins::controller_tests {

    use sui::coin::{Self, Coin};
    use sui::test_scenario::{Self, Scenario};
    use sui::sui::SUI;
    use sui::url;
    use sui::dynamic_field;
    use suins::auction::{make_seal_bid, finalize_all_auctions_by_admin, AuctionHouse};
    use suins::auction;
    use suins::auction_tests::{start_an_auction_util, place_bid_util, reveal_bid_util, ctx_new};
    use suins::registrar::{Self, RegistrationNFT};
    use suins::registry::{Self, AdminCap};
    use suins::configuration::{Self, Configuration};
    use suins::entity::{Self, SuiNS};
    use suins::controller;
    use suins::emoji;
    use std::option::{Self, Option, some};
    use std::string::utf8;
    use std::vector;
    use suins::auction_tests;
    use sui::clock::{Self, Clock};

    const SUINS_ADDRESS: address = @0xA001;
    const FIRST_USER_ADDRESS: address = @0xB001;
    const SECOND_USER_ADDRESS: address = @0xB002;
    const FIRST_LABEL: vector<u8> = b"eastagile-123";
    const FIRST_DOMAIN_NAME: vector<u8> = b"eastagile-123.sui";
    const SECOND_LABEL: vector<u8> = b"suinameservice";
    const THIRD_LABEL: vector<u8> = b"thirdsuinameservice";
    const FIRST_SECRET: vector<u8> = b"oKz=QdYd)]ryKB%";
    const SECOND_SECRET: vector<u8> = b"a9f8d4a8daeda2f35f02";
    const FIRST_INVALID_LABEL: vector<u8> = b"east.agile";
    const SECOND_INVALID_LABEL: vector<u8> = b"ea";
    const THIRD_INVALID_LABEL: vector<u8> = b"zkaoxpcbarubhtxkunajudxezneyczueajbggrynkwbepxjqjxrigrtgglhfjpax";
    const AUCTIONED_LABEL: vector<u8> = b"suins";
    const AUCTIONED_DOMAIN_NAME: vector<u8> = b"suins.sui";
    const FOURTH_INVALID_LABEL: vector<u8> = b"-eastagile";
    const FIFTH_INVALID_LABEL: vector<u8> = b"east/?agile";
    const REFERRAL_CODE: vector<u8> = b"X43kS8";
    const DISCOUNT_CODE: vector<u8> = b"DC12345";
    const BIDDING_PERIOD: u64 = 3;
    const REVEAL_PERIOD: u64 = 3;
    const START_AUCTION_START_AT: u64 = 50;
    const START_AUCTION_END_AT: u64 = 120;
    const EXTRA_PERIOD_START_AT: u64 = 127;
    const EXTRA_PERIOD_END_AT: u64 = 156;
    const START_AN_AUCTION_AT: u64 = 110;
    const EXTRA_PERIOD: u64 = 30;
    const SUI_REGISTRAR: vector<u8> = b"sui";
    const MOVE_REGISTRAR: vector<u8> = b"move";
    const BIDDING_FEE: u64 = 1000000000;
    const START_AN_AUCTION_FEE: u64 = 10_000_000_000;
    const MIN_COMMITMENT_AGE_IN_MS: u64 = 300_000;
    const PRICE_OF_THREE_CHARACTER_DOMAIN: u64 = 1200 * 1_000_000_000;
    const PRICE_OF_FOUR_CHARACTER_DOMAIN: u64 = 200 * 1_000_000_000;
    const PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN: u64 = 50 * 1_000_000_000;
    const GRACE_PERIOD: u64 = 90;
    const DEFAULT_TX_HASH: vector<u8> = x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532";

    public fun test_init(): Scenario {
        let scenario = test_scenario::begin(SUINS_ADDRESS);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            registry::test_init(ctx);
            configuration::test_init(ctx);
            entity::test_init(ctx);
            auction::test_init(ctx);
            clock::share_for_testing(clock::create_for_testing(ctx));
        };
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            registrar::new_tld(&admin_cap, &mut suins, utf8(SUI_REGISTRAR), test_scenario::ctx(&mut scenario));
            registrar::new_tld(&admin_cap, &mut suins, utf8(MOVE_REGISTRAR), test_scenario::ctx(&mut scenario));
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

    public fun set_auction_config(scenario: &mut Scenario) {
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
            let auction = test_scenario::take_shared<AuctionHouse>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            auction::configure_auction(
                &admin_cap,
                &mut auction,
                &mut suins,
                START_AUCTION_START_AT,
                START_AUCTION_END_AT,
                test_scenario::ctx(scenario)
            );
            test_scenario::return_shared(suins);
            test_scenario::return_shared(auction);
            test_scenario::return_to_sender(scenario, admin_cap);
        };
    }

    public fun make_commitment(scenario: &mut Scenario, label: Option<vector<u8>>) {
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let no_of_commitments = controller::commitment_len(&suins);
            let clock = test_scenario::take_shared<Clock>(scenario);

            if (option::is_none(&label)) label = option::some(FIRST_LABEL);
            let commitment = controller::test_make_commitment(
                SUI_REGISTRAR,
                option::extract(&mut label),
                FIRST_USER_ADDRESS,
                FIRST_SECRET
            );

            controller::commit(&mut suins, commitment, &clock);
            assert!(controller::commitment_len(&suins) - no_of_commitments == 1, 0);

            test_scenario::return_shared(suins);
            test_scenario::return_shared(clock);
        };
    }

    public fun register(scenario: &mut Scenario) {
        make_commitment(scenario, option::none());
        // register
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let config = test_scenario::take_shared<Configuration>(scenario);
            let clock = test_scenario::take_shared<Clock>(scenario);
            // simulate user wait for next epoch to call `register`
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN + 1, &mut ctx);
            clock::increment_for_testing(&mut clock, MIN_COMMITMENT_AGE_IN_MS + 1);

            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, FIRST_LABEL), 0);
            assert!(!registry::record_exists(&suins, utf8(FIRST_DOMAIN_NAME)), 0);
            assert!(controller::get_balance(&suins) == 0, 0);
            assert!(!test_scenario::has_most_recent_for_sender<RegistrationNFT>(scenario), 0);

            controller::register(
                &mut suins,
                &mut config,
                utf8(FIRST_LABEL),
                FIRST_USER_ADDRESS,
                1,
                FIRST_SECRET,
                &mut coin,
                &clock,
                &mut ctx,
            );
            assert!(coin::value(&coin) == 1, 0);

            coin::burn_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(scenario);
            let (name, url) = registrar::get_nft_fields(&nft);
            registrar::assert_registrar_exists(&suins, SUI_REGISTRAR);

            assert!(controller::get_balance(&suins) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN, 0);
            assert!(name == utf8(FIRST_DOMAIN_NAME), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );

            let (expired_at, owner) = registrar::get_record_detail(&suins, SUI_REGISTRAR, FIRST_LABEL);
            assert!(expired_at == EXTRA_PERIOD_END_AT + 1 + 365, 0);
            assert!(owner == FIRST_USER_ADDRESS, 0);

            let (owner, linked_addr, ttl, name) = registry::get_name_record_all_fields(&suins, utf8(FIRST_DOMAIN_NAME));
            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(linked_addr == FIRST_USER_ADDRESS, 0);
            assert!(ttl == 0, 0);
            assert!(name == utf8(b""), 0);


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

    #[test, expected_failure(abort_code = controller::ECommitmentNotExists)]
    fun test_register_abort_with_difference_label() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        make_commitment(&mut scenario, option::none());
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            // simulate user wait for next epoch to call `register`
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(1000001, &mut ctx);

            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, SECOND_LABEL), 0);
            controller::register(
                &mut suins,
                &mut config,
                utf8(SECOND_LABEL),
                FIRST_USER_ADDRESS,
                1,
                FIRST_SECRET,
                &mut coin,
                &clock,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
            test_scenario::return_shared(clock);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = controller::ECommitmentNotExists)]
    fun test_register_abort_with_wrong_secret() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        make_commitment(&mut scenario, option::none());
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            // simulate user wait for next epoch to call `register`
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(1000001, &mut ctx);
            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, FIRST_LABEL), 0);

            controller::register(
                &mut suins,
                &mut config,
                utf8(SECOND_LABEL),
                FIRST_USER_ADDRESS,
                1,
                SECOND_SECRET,
                &mut coin,
                &clock,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(config);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = controller::ECommitmentNotExists)]
    fun test_register_abort_with_wrong_owner() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        make_commitment(&mut scenario, option::none());
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(1000001, &mut ctx);
            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, FIRST_LABEL), 0);

            controller::register(
                &mut suins,
                &mut config,
                utf8(SECOND_LABEL),
                SECOND_USER_ADDRESS,
                1,
                FIRST_SECRET,
                &mut coin,
                &clock,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = controller::ECommitmentTooOld)]
    fun test_register_abort_if_called_too_late() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        make_commitment(&mut scenario, option::none());
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);

            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let ctx = &mut ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1,
                10
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 3, ctx);
            clock::increment_for_testing(&mut clock, controller::max_commitment_age_in_ms() + 1);

            controller::register(
                &mut suins,
                &mut config,
                utf8(FIRST_LABEL),
                FIRST_USER_ADDRESS,
                1,
                FIRST_SECRET,
                &mut coin,
                &clock,
                ctx
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(config);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = controller::ENotEnoughFee)]
    fun test_register_abort_if_not_enough_fee() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        make_commitment(&mut scenario, option::none());
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            // simulate user wait for next epoch to call `register`
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(9999, &mut ctx);
            clock::increment_for_testing(&mut clock, MIN_COMMITMENT_AGE_IN_MS);

            controller::register(
                &mut suins,
                &mut config,
                utf8(FIRST_LABEL),
                FIRST_USER_ADDRESS,
                1,
                FIRST_SECRET,
                &mut coin,
                &clock,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = controller::ELabelUnavailable)]
    fun test_register_abort_if_label_was_registered_before() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        register(&mut scenario);
        make_commitment(&mut scenario, option::none());
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            // simulate user wait for next epoch to call `register`
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(1000001, &mut ctx);
            clock::increment_for_testing(&mut clock, MIN_COMMITMENT_AGE_IN_MS);

            assert!(controller::get_balance(&suins) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN, 0);
            controller::register(
                &mut suins,
                &mut config,
                utf8(FIRST_LABEL),
                FIRST_USER_ADDRESS,
                1,
                FIRST_SECRET,
                &mut coin,
                &clock,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(config);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_register_works_if_previous_registration_is_expired() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        register(&mut scenario);
        test_scenario::next_tx(&mut scenario, SECOND_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);

            let commitment = controller::test_make_commitment(
                SUI_REGISTRAR,
                FIRST_LABEL,
                SECOND_USER_ADDRESS,
                FIRST_SECRET
            );
            controller::commit(
                &mut suins,
                commitment,
                &clock,
            );

            test_scenario::return_shared(suins);
            test_scenario::return_shared(clock);
        };

        test_scenario::next_tx(&mut scenario, SECOND_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            // simulate user wait for next epoch to call `register`
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1 + 365 + GRACE_PERIOD + 1,
                20
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN, &mut ctx);
            clock::increment_for_testing(&mut clock, MIN_COMMITMENT_AGE_IN_MS);

            assert!(controller::get_balance(&suins) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN, 0);
            controller::register(
                &mut suins,
                &mut config,
                utf8(FIRST_LABEL),
                SECOND_USER_ADDRESS,
                1,
                FIRST_SECRET,
                &mut coin,
                &clock,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(config);
        };

        test_scenario::next_tx(&mut scenario, SECOND_USER_ADDRESS);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&nft);
            registrar::assert_registrar_exists(&suins, SUI_REGISTRAR);

            assert!(controller::get_balance(&suins) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 2, 0);
            assert!(name == utf8(FIRST_DOMAIN_NAME), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );

            let (expired_at, owner) = registrar::get_record_detail(&suins, SUI_REGISTRAR, FIRST_LABEL);
            assert!(expired_at == EXTRA_PERIOD_END_AT + 1 + 365 + GRACE_PERIOD + 1 + 365, 0);
            assert!(owner == SECOND_USER_ADDRESS, 0);

            let (owner, linked_addr, ttl, name) = registry::get_name_record_all_fields(&suins, utf8(FIRST_DOMAIN_NAME));
            assert!(owner == SECOND_USER_ADDRESS, 0);
            assert!(linked_addr == SECOND_USER_ADDRESS, 0);
            assert!(ttl == 0, 0);
            assert!(name == utf8(b""), 0);

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
        set_auction_config(&mut scenario);
        register(&mut scenario);
        test_scenario::next_tx(&mut scenario, SECOND_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);

            let commitment = controller::test_make_commitment(
                SUI_REGISTRAR,
                FIRST_LABEL,
                SECOND_USER_ADDRESS,
                FIRST_SECRET
            );
            controller::commit(
                &mut suins,
                commitment,
                &clock,
            );

            test_scenario::return_shared(suins);
            test_scenario::return_shared(clock);
        };

        test_scenario::next_tx(&mut scenario, SECOND_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            // simulate user wait for next epoch to call `register`
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1 + 365 + GRACE_PERIOD + 1,
                20
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN, &mut ctx);
            clock::increment_for_testing(&mut clock, MIN_COMMITMENT_AGE_IN_MS);
            assert!(controller::get_balance(&suins) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN, 0);

            controller::register(
                &mut suins,
                &mut config,
                utf8(FIRST_LABEL),
                SECOND_USER_ADDRESS,
                1,
                FIRST_SECRET,
                &mut coin,
                &clock,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(config);
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
    fun test_register() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        make_commitment(&mut scenario, option::none());
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 4, &mut ctx);
            clock::increment_for_testing(&mut clock, MIN_COMMITMENT_AGE_IN_MS);

            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, FIRST_LABEL), 0);
            assert!(!registry::record_exists(&suins, utf8(FIRST_DOMAIN_NAME)), 0);
            assert!(controller::get_balance(&suins) == 0, 0);
            assert!(!test_scenario::has_most_recent_for_sender<RegistrationNFT>(&mut scenario), 0);

            controller::register(
                &mut suins,
                &mut config,
                utf8(FIRST_LABEL),
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                &clock,
                &mut ctx,
            );
            assert!(coin::value(&coin) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 2, 0);

            coin::burn_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&nft);
            registrar::assert_registrar_exists(&suins, SUI_REGISTRAR);

            assert!(controller::get_balance(&suins) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 2, 0);
            assert!(name == utf8(FIRST_DOMAIN_NAME), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );

            let (expired_at, owner) = registrar::get_record_detail(&suins, SUI_REGISTRAR, FIRST_LABEL);
            assert!(expired_at == EXTRA_PERIOD_END_AT + 1 + 730, 0);
            assert!(owner == FIRST_USER_ADDRESS, 0);

            let (owner, linked_addr, ttl, name) = registry::get_name_record_all_fields(&suins, utf8(FIRST_DOMAIN_NAME));
            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(linked_addr == FIRST_USER_ADDRESS, 0);
            assert!(ttl == 0, 0);
            assert!(name == utf8(b""), 0);

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(suins);
        };

        // withdraw
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            assert!(controller::get_balance(&suins) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 2, 0);
            assert!(!test_scenario::has_most_recent_for_sender<Coin<SUI>>(&mut scenario), 0);

            controller::withdraw(&admin_cap, &mut suins, test_scenario::ctx(&mut scenario));
            assert!(controller::get_balance(&suins) == 0, 0);

            test_scenario::return_shared(suins);
            test_scenario::return_to_sender(&mut scenario, admin_cap);
        };

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            assert!(test_scenario::has_most_recent_for_sender<Coin<SUI>>(&mut scenario), 0);
            let coin = test_scenario::take_from_sender<Coin<SUI>>(&mut scenario);
            assert!(coin::value(&coin) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 2, 0);
            test_scenario::return_to_sender(&mut scenario, coin);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = controller::EAuctionNotEndYet)]
    fun test_register_with_config_aborts_with_too_short_label_and_auction_house_not_configured() {
        let scenario = test_init();
        make_commitment(&mut scenario, option::none());

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(10001, test_scenario::ctx(&mut scenario));

            controller::register(
                &mut suins,
                &mut config,
                utf8(SECOND_INVALID_LABEL),
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                &clock,
                test_scenario::ctx(&mut scenario),
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(config);
        };

        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = emoji::EInvalidLabel)]
    fun test_register_with_config_aborts_with_too_short_label() {
        let scenario = test_init();
        make_commitment(&mut scenario, option::none());
        set_auction_config(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(10001, test_scenario::ctx(&mut scenario));
            let ctx = &mut ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                START_AUCTION_END_AT + BIDDING_PERIOD + REVEAL_PERIOD + EXTRA_PERIOD + 10,
                0
            );

            controller::register(
                &mut suins,
                &mut config,
                utf8(SECOND_INVALID_LABEL),
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                &clock,
                ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(config);
        };

        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = controller::EAuctionNotEndYet)]
    fun test_register_with_config_aborts_with_too_long_label_and_auction_house_not_configured() {
        let scenario = test_init();
        make_commitment(&mut scenario, option::none());

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(1000001, test_scenario::ctx(&mut scenario));

            controller::register(
                &mut suins,
                &mut config,
                utf8(THIRD_INVALID_LABEL),
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                &clock,
                test_scenario::ctx(&mut scenario),
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(clock);
        };

        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = emoji::EInvalidLabel)]
    fun test_register_with_config_aborts_with_too_long_label() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        make_commitment(&mut scenario, option::none());
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(1000001, test_scenario::ctx(&mut scenario));
            let ctx = &mut ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                START_AUCTION_END_AT + BIDDING_PERIOD + REVEAL_PERIOD + EXTRA_PERIOD + 10,
                0
            );

            controller::register(
                &mut suins,
                &mut config,
                utf8(THIRD_INVALID_LABEL),
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                &clock,
                ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(clock);
        };

        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = controller::EAuctionNotEndYet)]
    fun test_register_aborts_if_label_starts_with_hyphen_and_auction_house_not_configured() {
        let scenario = test_init();
        make_commitment(&mut scenario, option::none());

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(10001, test_scenario::ctx(&mut scenario));

            controller::register(
                &mut suins,
                &mut config,
                utf8(FOURTH_INVALID_LABEL),
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                &clock,
                test_scenario::ctx(&mut scenario),
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(clock);
        };

        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = emoji::EInvalidLabel)]
    fun test_register_with_config_aborts_if_label_starts_with_hyphen() {
        let scenario = test_init();
        make_commitment(&mut scenario, option::none());
        set_auction_config(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(10001, test_scenario::ctx(&mut scenario));
            let ctx = &mut ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                START_AUCTION_END_AT + BIDDING_PERIOD + REVEAL_PERIOD + EXTRA_PERIOD + 10,
                0
            );

            controller::register(
                &mut suins,
                &mut config,
                utf8(FOURTH_INVALID_LABEL),
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                &clock,
                ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(clock);
        };

        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = controller::EAuctionNotEndYet)]
    fun test_register_with_config_abort_with_invalid_label_and_auction_house_not_being_configured() {
        let scenario = test_init();
        make_commitment(&mut scenario, option::none());

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(1000001, test_scenario::ctx(&mut scenario));

            controller::register(
                &mut suins,
                &mut config,
                utf8(FIFTH_INVALID_LABEL),
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                &clock,
                test_scenario::ctx(&mut scenario),
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(clock);
        };

        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = emoji::EInvalidLabel)]
    fun test_register_with_config_abort_with_invalid_label() {
        let scenario = test_init();
        make_commitment(&mut scenario, option::none());
        set_auction_config(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(1000001, test_scenario::ctx(&mut scenario));
            let ctx = &mut ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                START_AUCTION_END_AT + BIDDING_PERIOD + REVEAL_PERIOD + EXTRA_PERIOD + 10,
                0
            );
            controller::register(
                &mut suins,
                &mut config,
                utf8(FIFTH_INVALID_LABEL),
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                &clock,
                ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(clock);
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

    #[test]
    fun test_register_abort_if_label_is_reserved_for_auction_but_auction_ended() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        make_commitment(&mut scenario, option::some(AUCTIONED_LABEL));
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 3, test_scenario::ctx(&mut scenario));
            clock::increment_for_testing(&mut clock, controller::max_commitment_age_in_ms() - 1);

            controller::register(
                &mut suins,
                &mut config,
                utf8(AUCTIONED_LABEL),
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                &clock,
                &mut ctx_new(
                    SUINS_ADDRESS,
                    DEFAULT_TX_HASH,
                    EXTRA_PERIOD_END_AT + 1,
                    20
                ),
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&nft);

            registrar::assert_registrar_exists(&suins, SUI_REGISTRAR);
            assert!(name == utf8(AUCTIONED_DOMAIN_NAME), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );

            let (expired_at, owner) = registrar::get_record_detail(&suins, SUI_REGISTRAR, AUCTIONED_LABEL);
            assert!(expired_at == EXTRA_PERIOD_END_AT + 1 + 730, 0);
            assert!(owner == FIRST_USER_ADDRESS, 0);

            let (owner, linked_addr, ttl, name) = registry::get_name_record_all_fields(&suins, utf8(AUCTIONED_DOMAIN_NAME));
            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(linked_addr == FIRST_USER_ADDRESS, 0);
            assert!(ttl == 0, 0);
            assert!(name == utf8(b""), 0);

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = controller::EAuctionNotEndYet)]
    fun test_register_abort_if_label_is_reserved_for_auction() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        make_commitment(&mut scenario, option::some(AUCTIONED_LABEL));
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(10000001, test_scenario::ctx(&mut scenario));

            controller::register(
                &mut suins,
                &mut config,
                utf8(AUCTIONED_LABEL),
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                &clock,
                test_scenario::ctx(&mut scenario),
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };

        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = emoji::EInvalidLabel)]
    fun test_register_abort_if_label_is_invalid() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);

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
                &clock,
            );
            assert!(controller::commitment_len(&suins) == 1, 0);

            test_scenario::return_shared(suins);
            test_scenario::return_shared(clock);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1,
                0
            );
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(10001, &mut ctx);

            controller::register(
                &mut suins,
                &mut config,
                utf8(FIRST_INVALID_LABEL),
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                &clock,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_renew() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        register(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let ctx = test_scenario::ctx(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 2 + 1, ctx);

            assert!(registrar::name_expires_at(&suins, utf8(SUI_REGISTRAR), utf8(FIRST_LABEL)) == 522, 0);
            assert!(controller::get_balance(&suins) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN, 0);
            controller::renew(
                &mut suins,
                &config,
                utf8(FIRST_LABEL),
                2,
                &mut coin,
                ctx,
            );
            assert!(coin::value(&coin) == 1, 0);
            assert!(registrar::name_expires_at(&suins, utf8(SUI_REGISTRAR), utf8(FIRST_LABEL)) == 1252, 0);

            coin::burn_for_testing(coin);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            assert!(controller::get_balance(&suins) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 3, 0);
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
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let ctx = test_scenario::ctx(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN, ctx);

            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, FIRST_LABEL), 0);

            controller::renew(
                &mut suins,
                &config,
                utf8(FIRST_LABEL),
                1,
                &mut coin,
                ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registrar::ELabelExpired)]
    fun test_renew_abort_if_label_expired() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        register(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                1051,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN, &mut ctx);

            controller::renew(
                &mut suins,
                &config,
                utf8(FIRST_LABEL),
                1,
                &mut coin,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = controller::ENotEnoughFee)]
    fun test_renew_abort_if_not_enough_fee() {
        let scenario = test_init();

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let ctx = test_scenario::ctx(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(4, ctx);

            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, FIRST_LABEL), 0);

            controller::renew(
                &mut suins,
                &config,
                utf8(FIRST_LABEL),
                1,
                &mut coin,
                ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
        };
        test_scenario::end(scenario);
    }
    
    #[test]
    fun test_remove_outdated_commitment() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);

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
                &clock,
            );
            assert!(controller::commitment_len(&suins) == 1, 0);

            test_scenario::return_shared(suins);
            test_scenario::return_shared(clock);
        };
        // outdated commitment
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            clock::increment_for_testing(&mut clock, controller::max_commitment_age_in_ms());

            let commitment = controller::test_make_commitment(
                SUI_REGISTRAR,
                FIRST_LABEL,
                SECOND_USER_ADDRESS,
                FIRST_SECRET
            );
            controller::commit(
                &mut suins,
                commitment,
                &clock,
            );
            assert!(controller::commitment_len(&suins) == 1, 0);

            test_scenario::return_shared(suins);
            test_scenario::return_shared(clock);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            clock::increment_for_testing(&mut clock, controller::max_commitment_age_in_ms());

            let commitment = controller::test_make_commitment(
                SUI_REGISTRAR,
                FIRST_LABEL,
                FIRST_USER_ADDRESS,
                SECOND_SECRET
            );
            controller::commit(
                &mut suins,
                commitment,
                &clock,
            );
            assert!(controller::commitment_len(&suins) == 1, 0);

            test_scenario::return_shared(suins);
            test_scenario::return_shared(clock);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            clock::increment_for_testing(&mut clock, 2);

            let commitment = controller::test_make_commitment(
                SUI_REGISTRAR,
                SECOND_LABEL,
                FIRST_USER_ADDRESS,
                FIRST_SECRET
            );
            controller::commit(
                &mut suins,
                commitment,
                &clock,
            );
            assert!(controller::commitment_len(&suins) == 2, 0);

            test_scenario::return_shared(suins);
            test_scenario::return_shared(clock);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<AuctionHouse>(&mut scenario);
            // simulate user wait for next epoch to call `register`
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1,
                0
            );
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 2 + 1, &mut ctx);
            clock::increment_for_testing(&mut clock, MIN_COMMITMENT_AGE_IN_MS);

            assert!(controller::commitment_len(&suins) == 2, 0);
            controller::register(
                &mut suins,
                &mut config,
                utf8(SECOND_LABEL),
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                &clock,
                &mut ctx,
            );
            assert!(coin::value(&coin) == 1, 0);
            assert!(controller::commitment_len(&suins) == 1, 0);

            coin::burn_for_testing(coin);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_register_with_referral_code() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        make_commitment(&mut scenario, option::none());
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 3, &mut ctx);
            clock::increment_for_testing(&mut clock, MIN_COMMITMENT_AGE_IN_MS);

            assert!(controller::get_balance(&suins) == 0, 0);
            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, FIRST_LABEL), 0);
            assert!(!registry::record_exists(&suins, utf8(FIRST_DOMAIN_NAME)), 0);
            assert!(!test_scenario::has_most_recent_for_sender<RegistrationNFT>(&mut scenario), 0);
            assert!(!test_scenario::has_most_recent_for_address<Coin<SUI>>(SECOND_USER_ADDRESS), 0);

            controller::register_with_code(
                &mut suins,
                &mut config,
                utf8(FIRST_LABEL),
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                REFERRAL_CODE,
                b"",
                &clock,
                &mut ctx,
            );

            assert!(coin::value(&coin) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN, 0);

            coin::burn_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(clock);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&nft);
            let coin = test_scenario::take_from_address<Coin<SUI>>(&mut scenario, SECOND_USER_ADDRESS);

            registrar::assert_registrar_exists(&suins, SUI_REGISTRAR);
            assert!(name == utf8(FIRST_DOMAIN_NAME), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );
            assert!(coin::value(&coin) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 2 / 10, 0);
            assert!(controller::get_balance(&suins) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 2 * 9/ 10, 0);

            let (expired_at, owner) = registrar::get_record_detail(&suins, SUI_REGISTRAR, FIRST_LABEL);
            assert!(expired_at == EXTRA_PERIOD_END_AT + 1 + 730, 0);
            assert!(owner == FIRST_USER_ADDRESS, 0);

            let (owner, linked_addr, ttl, name) = registry::get_name_record_all_fields(&suins, utf8(FIRST_DOMAIN_NAME));
            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(linked_addr == FIRST_USER_ADDRESS, 0);
            assert!(ttl == 0, 0);
            assert!(name == utf8(b""), 0);

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_to_address(SECOND_USER_ADDRESS, coin);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_register_with_config_referral_code() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        make_commitment(&mut scenario, option::none());
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 4, &mut ctx);
            clock::increment_for_testing(&mut clock, MIN_COMMITMENT_AGE_IN_MS);

            assert!(controller::get_balance(&suins) == 0, 0);
            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, FIRST_LABEL), 0);
            assert!(!registry::record_exists(&suins, utf8(FIRST_DOMAIN_NAME)), 0);
            assert!(!test_scenario::has_most_recent_for_sender<RegistrationNFT>(&mut scenario), 0);
            assert!(!test_scenario::has_most_recent_for_address<Coin<SUI>>(SECOND_USER_ADDRESS), 0);

            controller::register_with_code(
                &mut suins,
                &mut config,
                utf8(FIRST_LABEL),
                FIRST_USER_ADDRESS,
                3,
                FIRST_SECRET,
                &mut coin,
                REFERRAL_CODE,
                b"",
                &clock,
                &mut ctx,
            );
            assert!(coin::value(&coin) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN, 0);
            coin::burn_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&nft);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let coin = test_scenario::take_from_address<Coin<SUI>>(&mut scenario, SECOND_USER_ADDRESS);

            registrar::assert_registrar_exists(&suins, SUI_REGISTRAR);

            assert!(name == utf8(FIRST_DOMAIN_NAME), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );
            assert!(coin::value(&coin) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 30 / 100, 0);
            assert!(controller::get_balance(&suins) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 270 / 100, 0);

            let (expired_at, owner) = registrar::get_record_detail(&suins, SUI_REGISTRAR, FIRST_LABEL);
            assert!(expired_at == EXTRA_PERIOD_END_AT + 1 + 1095, 0);
            assert!(owner == FIRST_USER_ADDRESS, 0);

            let (owner, linked_addr, ttl, _) = registry::get_name_record_all_fields(&suins, utf8(FIRST_DOMAIN_NAME));
            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(linked_addr == FIRST_USER_ADDRESS, 0);
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

            coin::burn_for_testing(coin2);
            coin::burn_for_testing(coin1);
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
        set_auction_config(&mut scenario);
        make_commitment(&mut scenario, option::none());
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<AuctionHouse>(&mut scenario);
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 3, &mut ctx);
            clock::increment_for_testing(&mut clock, MIN_COMMITMENT_AGE_IN_MS);

            assert!(controller::get_balance(&suins) == 0, 0);
            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, FIRST_LABEL), 0);
            assert!(!registry::record_exists(&suins, utf8(FIRST_DOMAIN_NAME)), 0);
            assert!(!test_scenario::has_most_recent_for_sender<RegistrationNFT>(&mut scenario), 0);
            assert!(!test_scenario::has_most_recent_for_address<Coin<SUI>>(SECOND_USER_ADDRESS), 0);

            controller::register_with_code(
                &mut suins,
                &mut config,
                utf8(FIRST_LABEL),
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                b"",
                DISCOUNT_CODE,
                &clock,
                &mut ctx,
            );

            assert!(coin::value(&coin) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 130 / 100, 0);

            coin::burn_for_testing(coin);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&nft);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            registrar::assert_registrar_exists(&suins, SUI_REGISTRAR);

            assert!(!test_scenario::has_most_recent_for_address<Coin<SUI>>(SECOND_USER_ADDRESS), 0);
            assert!(name == utf8(FIRST_DOMAIN_NAME), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );
            assert!(controller::get_balance(&suins) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 170 / 100, 0);

            let (expired_at, owner) = registrar::get_record_detail(&suins, SUI_REGISTRAR, FIRST_LABEL);
            assert!(expired_at == EXTRA_PERIOD_END_AT + 1 + 730, 0);
            assert!(owner == FIRST_USER_ADDRESS, 0);

            let (owner, linked_addr, ttl, _) = registry::get_name_record_all_fields(&suins, utf8(FIRST_DOMAIN_NAME));
            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(linked_addr == FIRST_USER_ADDRESS, 0);
            assert!(ttl == 0, 0);

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = configuration::EOwnerUnauthorized)]
    fun test_register_with_discount_code_abort_if_unauthorized() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        make_commitment(&mut scenario, option::none());
        test_scenario::next_tx(&mut scenario, SECOND_USER_ADDRESS);
        {
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let auction = test_scenario::take_shared<AuctionHouse>(&mut scenario);
            let ctx = ctx_new(
                SECOND_USER_ADDRESS,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 3, &mut ctx);
            clock::increment_for_testing(&mut clock, MIN_COMMITMENT_AGE_IN_MS);

            controller::register_with_code(
                &mut suins,
                &mut config,
                utf8(FIRST_LABEL),
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                b"",
                DISCOUNT_CODE,
                &clock,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = configuration::EDiscountCodeNotExists)]
    fun test_register_with_discount_code_abort_with_invalid_code() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        make_commitment(&mut scenario, option::none());
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 3, &mut ctx);
            clock::increment_for_testing(&mut clock, MIN_COMMITMENT_AGE_IN_MS);

            controller::register_with_code(
                &mut suins,
                &mut config,
                utf8(FIRST_LABEL),
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                b"",
                REFERRAL_CODE,
                &clock,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_register_with_config_and_discount_code() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        make_commitment(&mut scenario, option::none());
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<AuctionHouse>(&mut scenario);
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 3, &mut ctx);
            clock::increment_for_testing(&mut clock, MIN_COMMITMENT_AGE_IN_MS);

            assert!(controller::get_balance(&suins) == 0, 0);
            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, FIRST_LABEL), 0);
            assert!(!registry::record_exists(&suins, utf8(FIRST_DOMAIN_NAME)), 0);
            assert!(!test_scenario::has_most_recent_for_sender<RegistrationNFT>(&mut scenario), 0);
            assert!(!test_scenario::has_most_recent_for_address<Coin<SUI>>(SECOND_USER_ADDRESS), 0);

            controller::register_with_code(
                &mut suins,
                &mut config,
                utf8(FIRST_LABEL),
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                b"",
                DISCOUNT_CODE,
                &clock,
                &mut ctx,
            );
            assert!(coin::value(&coin) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN + (PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 30)/100 , 0);

            coin::burn_for_testing(coin);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(clock);
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
            assert!(name == utf8(FIRST_DOMAIN_NAME), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );
            assert!(controller::get_balance(&suins) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 170 / 100, 0);

            let (expired_at, owner) = registrar::get_record_detail(&suins, SUI_REGISTRAR, FIRST_LABEL);
            assert!(expired_at == EXTRA_PERIOD_END_AT + 1 + 730, 0);
            assert!(owner == FIRST_USER_ADDRESS, 0);

            let (owner, linked_addr, ttl, _) = registry::get_name_record_all_fields(&suins, utf8(FIRST_DOMAIN_NAME));
            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(linked_addr == FIRST_USER_ADDRESS, 0);
            assert!(ttl == 0, 0);

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = configuration::EOwnerUnauthorized)]
    fun test_register_with_config_and_discount_code_abort_if_unauthorized() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        make_commitment(&mut scenario, option::none());
        test_scenario::next_tx(&mut scenario, SECOND_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let ctx = ctx_new(
                SECOND_USER_ADDRESS,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 3, &mut ctx);
            clock::increment_for_testing(&mut clock, MIN_COMMITMENT_AGE_IN_MS);

            controller::register_with_code(
                &mut suins,
                &mut config,
                utf8(FIRST_LABEL),
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                b"",
                DISCOUNT_CODE,
                &clock,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(clock);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = configuration::EDiscountCodeNotExists)]
    fun test_register_with_config_and_discount_code_abort_with_invalid_code() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        make_commitment(&mut scenario, option::none());
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 3, &mut ctx);
            clock::increment_for_testing(&mut clock, MIN_COMMITMENT_AGE_IN_MS);

            controller::register_with_code(
                &mut suins,
                &mut config,
                utf8(FIRST_LABEL),
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                b"",
                REFERRAL_CODE,
                &clock,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = configuration::EDiscountCodeNotExists)]
    fun test_register_with_discount_code_abort_if_being_used_twice() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        make_commitment(&mut scenario, option::none());
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<AuctionHouse>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 3, &mut ctx);
            clock::increment_for_testing(&mut clock, MIN_COMMITMENT_AGE_IN_MS);

            controller::register_with_code(
                &mut suins,
                &mut config,
                utf8(FIRST_LABEL),
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                b"",
                DISCOUNT_CODE,
                &clock,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);

            let commitment = controller::test_make_commitment(
                SUI_REGISTRAR,
                SECOND_LABEL,
                FIRST_USER_ADDRESS,
                FIRST_SECRET
            );
            controller::commit(&mut suins, commitment, &clock, );

            test_scenario::return_shared(suins);
            test_scenario::return_shared(clock);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 3, &mut ctx);
            clock::increment_for_testing(&mut clock, MIN_COMMITMENT_AGE_IN_MS);

            controller::register_with_code(
                &mut suins,
                &mut config,
                utf8(SECOND_LABEL),
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                b"",
                DISCOUNT_CODE,
                &clock,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_register_with_referral_code_works_if_code_is_used_twice() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        make_commitment(&mut scenario, option::none());
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 3, &mut ctx);
            clock::increment_for_testing(&mut clock, MIN_COMMITMENT_AGE_IN_MS);

            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, FIRST_LABEL), 0);
            controller::register_with_code(
                &mut suins,
                &mut config,
                utf8(FIRST_LABEL),
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                REFERRAL_CODE,
                b"",
                &clock,
                &mut ctx,
            );
            assert!(coin::value(&coin) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN, 0);

            coin::burn_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let coin = test_scenario::take_from_address<Coin<SUI>>(&mut scenario, SECOND_USER_ADDRESS);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            assert!(coin::value(&coin) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN / 5, 0);
            assert!(controller::get_balance(&suins) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 9 / 5, 0);

            test_scenario::return_to_address(SECOND_USER_ADDRESS, coin);
            test_scenario::return_shared(suins);
        };
        make_commitment(&mut scenario, option::some(SECOND_LABEL));
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            // simulate user wait for next epoch to call `register`
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1,
                20
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 3, &mut ctx);
            clock::increment_for_testing(&mut clock, MIN_COMMITMENT_AGE_IN_MS);

            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, SECOND_LABEL), 0);
            controller::register_with_code(
                &mut suins,
                &mut config,
                utf8(SECOND_LABEL),
                FIRST_USER_ADDRESS,
                1,
                FIRST_SECRET,
                &mut coin,
                REFERRAL_CODE,
                b"",
                &clock,
                &mut ctx,
            );
            assert!(coin::value(&coin) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 2, 0);

            coin::burn_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let coin1 = test_scenario::take_from_address<Coin<SUI>>(&mut scenario, SECOND_USER_ADDRESS);
            let coin2 = test_scenario::take_from_address<Coin<SUI>>(&mut scenario, SECOND_USER_ADDRESS);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            assert!(coin::value(&coin1) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN / 10, 0);
            assert!(coin::value(&coin2) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN / 5, 0);
            assert!(controller::get_balance(&suins) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 27 / 10, 0);

            test_scenario::return_shared(suins);
            test_scenario::return_to_address(SECOND_USER_ADDRESS, coin1);
            test_scenario::return_to_address(SECOND_USER_ADDRESS, coin2);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = configuration::EReferralCodeNotExists)]
    fun test_register_with_referral_code_abort_with_wrong_referral_code() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        make_commitment(&mut scenario, option::none());
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let auction = test_scenario::take_shared<AuctionHouse>(&mut scenario);
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 2, &mut ctx);
            clock::increment_for_testing(&mut clock, MIN_COMMITMENT_AGE_IN_MS);

            controller::register_with_code(
                &mut suins,
                &mut config,
                utf8(FIRST_LABEL),
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                DISCOUNT_CODE,
                b"",
                &clock,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_register_with_emoji() {
        let scenario = test_init();
        let label = vector[104, 109, 109, 109, 49, 240, 159, 145, 180];
        let domain_name = vector[104, 109, 109, 109, 49, 240, 159, 145, 180, 46, 115, 117, 105];
        set_auction_config(&mut scenario);
        make_commitment(&mut scenario, option::some(label));
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            // simulate user wait for next epoch to call `register`
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 3, &mut ctx);
            clock::increment_for_testing(&mut clock, MIN_COMMITMENT_AGE_IN_MS);

            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, domain_name), 0);
            assert!(controller::get_balance(&suins) == 0, 0);
            assert!(controller::commitment_len(&suins) == 1, 0);
            assert!(!registry::record_exists(&suins, utf8(domain_name)), 0);
            assert!(!test_scenario::has_most_recent_for_sender<RegistrationNFT>(&mut scenario), 0);

            controller::register(
                &mut suins,
                &mut config,
                utf8(label),
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                &clock,
                &mut ctx,
            );
            assert!(coin::value(&coin) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN, 0);

            coin::burn_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&nft);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            registrar::assert_registrar_exists(&suins, SUI_REGISTRAR);

            assert!(controller::get_balance(&suins) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 2, 0);
            assert!(name == utf8(domain_name), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );

            let (expired_at, owner) = registrar::get_record_detail(&suins, SUI_REGISTRAR, label);
            assert!(expired_at == EXTRA_PERIOD_END_AT + 1 + 730, 0);
            assert!(owner == FIRST_USER_ADDRESS, 0);

            let (owner, linked_addr, ttl, _) = registry::get_name_record_all_fields(&suins, utf8(domain_name));
            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(linked_addr == FIRST_USER_ADDRESS, 0);
            assert!(ttl == 0, 0);

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_register_with_code_apply_both_types_of_code() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        make_commitment(&mut scenario, option::none());
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<AuctionHouse>(&mut scenario);
            // simulate user wait for next epoch to call `register`
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 3, &mut ctx);
            clock::increment_for_testing(&mut clock, MIN_COMMITMENT_AGE_IN_MS);

            assert!(controller::get_balance(&suins) == 0, 0);
            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, FIRST_LABEL), 0);
            assert!(!registry::record_exists(&suins, utf8(FIRST_DOMAIN_NAME)), 0);
            assert!(!test_scenario::has_most_recent_for_sender<RegistrationNFT>(&mut scenario), 0);
            assert!(!test_scenario::has_most_recent_for_address<Coin<SUI>>(SECOND_USER_ADDRESS), 0);

            controller::register_with_code(
                &mut suins,
                &mut config,
                utf8(FIRST_LABEL),
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                REFERRAL_CODE,
                DISCOUNT_CODE,
                &clock,
                &mut ctx,
            );
            assert!(coin::value(&coin) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 130 / 100, 0);

            coin::burn_for_testing(coin);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(clock);
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

            assert!(name == utf8(FIRST_DOMAIN_NAME), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );
            assert!(coin::value(&coin) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 17 / 100, 0);
            assert!(controller::get_balance(&suins) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 153 / 100, 0);

            let (expired_at, owner) = registrar::get_record_detail(&suins, SUI_REGISTRAR, FIRST_LABEL);
            assert!(expired_at == EXTRA_PERIOD_END_AT + 1 + 730, 0);
            assert!(owner == FIRST_USER_ADDRESS, 0);

            let (owner, linked_addr, ttl, _) = registry::get_name_record_all_fields(&suins, utf8(FIRST_DOMAIN_NAME));
            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(linked_addr == FIRST_USER_ADDRESS, 0);
            assert!(ttl == 0, 0);

            coin::burn_for_testing(coin);
            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = configuration::EReferralCodeNotExists)]
    fun test_register_with_code_if_use_wrong_referral_code() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        make_commitment(&mut scenario, option::none());
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<AuctionHouse>(&mut scenario);
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 3, &mut ctx);
            clock::increment_for_testing(&mut clock, MIN_COMMITMENT_AGE_IN_MS);

            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, FIRST_LABEL), 0);
            controller::register_with_code(
                &mut suins,
                &mut config,
                utf8(FIRST_LABEL),
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                DISCOUNT_CODE,
                DISCOUNT_CODE,
                &clock,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = configuration::EDiscountCodeNotExists)]
    fun test_register_with_code_if_use_wrong_discount_code() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        make_commitment(&mut scenario, option::none());
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 3, &mut ctx);
            clock::increment_for_testing(&mut clock, MIN_COMMITMENT_AGE_IN_MS);

            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, FIRST_LABEL), 0);
            controller::register_with_code(
                &mut suins,
                &mut config,
                utf8(FIRST_LABEL),
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                REFERRAL_CODE,
                REFERRAL_CODE,
                &clock,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_register_with_config_and_code_apply_both_types_of_code() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        make_commitment(&mut scenario, option::none());
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 3, &mut ctx);
            clock::increment_for_testing(&mut clock, MIN_COMMITMENT_AGE_IN_MS);

            assert!(controller::get_balance(&suins) == 0, 0);
            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, FIRST_LABEL), 0);
            assert!(!registry::record_exists(&suins, utf8(FIRST_DOMAIN_NAME)), 0);
            assert!(!test_scenario::has_most_recent_for_sender<RegistrationNFT>(&mut scenario), 0);
            assert!(!test_scenario::has_most_recent_for_address<Coin<SUI>>(SECOND_USER_ADDRESS), 0);

            controller::register_with_code(
                &mut suins,
                &mut config,
                utf8(FIRST_LABEL),
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                REFERRAL_CODE,
                DISCOUNT_CODE,
                &clock,
                &mut ctx,
            );
            assert!(coin::value(&coin) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 130 / 100, 0);
            coin::burn_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(clock);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&nft);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let coin = test_scenario::take_from_address<Coin<SUI>>(&mut scenario, SECOND_USER_ADDRESS);

            registrar::assert_registrar_exists(&suins, SUI_REGISTRAR);
            assert!(name == utf8(FIRST_DOMAIN_NAME), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );
            assert!(coin::value(&coin) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 170 / 1000, 0);
            assert!(controller::get_balance(&suins) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 153 / 100, 0);

            let (expired_at, owner) = registrar::get_record_detail(&suins, SUI_REGISTRAR, FIRST_LABEL);
            assert!(expired_at == EXTRA_PERIOD_END_AT + 1 + 730, 0);
            assert!(owner == FIRST_USER_ADDRESS, 0);

            let (owner, linked_addr, ttl, _) = registry::get_name_record_all_fields(&suins, utf8(FIRST_DOMAIN_NAME));
            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(linked_addr == FIRST_USER_ADDRESS, 0);
            assert!(ttl == 0, 0);

            coin::burn_for_testing(coin);
            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = configuration::EReferralCodeNotExists)]
    fun test_register_with_config_and_code_if_use_wrong_referral_code() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        make_commitment(&mut scenario, option::none());
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 3, &mut ctx);
            clock::increment_for_testing(&mut clock, MIN_COMMITMENT_AGE_IN_MS);

            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, FIRST_LABEL), 0);
            controller::register_with_code(
                &mut suins,
                &mut config,
                utf8(FIRST_LABEL),
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                DISCOUNT_CODE,
                DISCOUNT_CODE,
                &clock,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = configuration::EDiscountCodeNotExists)]
    fun test_register_with_config_and_code_if_use_wrong_discount_code() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        make_commitment(&mut scenario, option::none());
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 3, &mut ctx);
            clock::increment_for_testing(&mut clock, MIN_COMMITMENT_AGE_IN_MS);

            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, FIRST_LABEL), 0);
            controller::register_with_code(
                &mut suins,
                &mut config,
                utf8(FIRST_LABEL),
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                REFERRAL_CODE,
                REFERRAL_CODE,
                &clock,
                &mut ctx,
            );
            coin::burn_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = controller::EAuctionNotEndYet)]
    fun test_register_abort_if_register_short_domain_while_auction_not_start_yet() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        make_commitment(&mut scenario, option::none());
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                21,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            controller::register(
                &mut suins,
                &mut config,
                utf8(AUCTIONED_LABEL),
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                &clock,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = controller::EAuctionNotEndYet)]
    fun test_register_aborts_if_register_long_domain_while_auction_not_started_yet() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        make_commitment(&mut scenario, option::none());
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                21,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN, &mut ctx);
            clock::increment_for_testing(&mut clock, MIN_COMMITMENT_AGE_IN_MS);

            controller::register(
                &mut suins,
                &mut config,
                utf8(FIRST_LABEL),
                FIRST_USER_ADDRESS,
                1,
                FIRST_SECRET,
                &mut coin,
                &clock,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&nft);

            registrar::assert_registrar_exists(&suins, SUI_REGISTRAR);

            assert!(controller::get_balance(&suins) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN, 0);
            assert!(name == utf8(FIRST_DOMAIN_NAME), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );

            let (expired_at, owner) = registrar::get_record_detail(&suins, SUI_REGISTRAR, FIRST_LABEL);
            assert!(expired_at == 21 + 365, 0);
            assert!(owner == FIRST_USER_ADDRESS, 0);

            let (owner, linked_addr, ttl, _) = registry::get_name_record_all_fields(&suins, utf8(FIRST_DOMAIN_NAME));
            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(linked_addr == FIRST_USER_ADDRESS, 0);
            assert!(ttl == 0, 0);

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = controller::EAuctionNotEndYet)]
    fun test_register_abort_if_register_short_domain_while_auction_is_happening() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                71,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            controller::register(
                &mut suins,
                &mut config,
                utf8(AUCTIONED_LABEL),
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                &clock,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = controller::EAuctionNotEndYet)]
    fun test_register_aborts_if_register_long_domain_while_auction_is_happening() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        make_commitment(&mut scenario, some(FIRST_LABEL));
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                51,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN, &mut ctx);
            clock::increment_for_testing(&mut clock, MIN_COMMITMENT_AGE_IN_MS);

            controller::register(
                &mut suins,
                &mut config,
                utf8(FIRST_LABEL),
                FIRST_USER_ADDRESS,
                1,
                FIRST_SECRET,
                &mut coin,
                &clock,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&nft);

            registrar::assert_registrar_exists(&suins, SUI_REGISTRAR);

            assert!(controller::get_balance(&suins) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN, 0);
            assert!(name == utf8(FIRST_DOMAIN_NAME), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );

            let (expired_at, owner) = registrar::get_record_detail(&suins, SUI_REGISTRAR, FIRST_LABEL);
            assert!(expired_at == 51 + 365, 0);
            assert!(owner == FIRST_USER_ADDRESS, 0);

            let (owner, linked_addr, ttl, _) = registry::get_name_record_all_fields(&suins, utf8(FIRST_DOMAIN_NAME));
            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(linked_addr == FIRST_USER_ADDRESS, 0);
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
            let clock = test_scenario::take_shared<Clock>(&mut scenario);

            let commitment = controller::test_make_commitment(
                SUI_REGISTRAR,
                FIRST_LABEL,
                FIRST_USER_ADDRESS,
                FIRST_SECRET
            );
            controller::commit(
                &mut suins,
                commitment,
                &clock,
            );

            test_scenario::return_shared(suins);
            test_scenario::return_shared(clock);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                221,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN, &mut ctx);
            clock::increment_for_testing(&mut clock, MIN_COMMITMENT_AGE_IN_MS);

            controller::register(
                &mut suins,
                &mut config,
                utf8(FIRST_LABEL),
                FIRST_USER_ADDRESS,
                1,
                FIRST_SECRET,
                &mut coin,
                &clock,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(clock);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&nft);

            registrar::assert_registrar_exists(&suins, SUI_REGISTRAR);

            assert!(controller::get_balance(&suins) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN, 0);
            assert!(name == utf8(FIRST_DOMAIN_NAME), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );

            let (expired_at, owner) = registrar::get_record_detail(&suins, SUI_REGISTRAR, FIRST_LABEL);
            assert!(expired_at == 221 + 365, 0);
            assert!(owner == FIRST_USER_ADDRESS, 0);

            let (owner, linked_addr, ttl, _) = registry::get_name_record_all_fields(&suins, utf8(FIRST_DOMAIN_NAME));
            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(linked_addr == FIRST_USER_ADDRESS, 0);
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
            let clock = test_scenario::take_shared<Clock>(&mut scenario);

            let commitment = controller::test_make_commitment(
                SUI_REGISTRAR,
                AUCTIONED_LABEL,
                FIRST_USER_ADDRESS,
                FIRST_SECRET
            );
            controller::commit(
                &mut suins,
                commitment,
                &clock,
            );

            test_scenario::return_shared(suins);
            test_scenario::return_shared(clock);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                221,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN, &mut ctx);
            clock::increment_for_testing(&mut clock, MIN_COMMITMENT_AGE_IN_MS);

            controller::register(
                &mut suins,
                &mut config,
                utf8(AUCTIONED_LABEL),
                FIRST_USER_ADDRESS,
                1,
                FIRST_SECRET,
                &mut coin,
                &clock,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(clock);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&nft);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            registrar::assert_registrar_exists(&suins, SUI_REGISTRAR);

            assert!(controller::get_balance(&suins) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN, 0);
            assert!(name == utf8(AUCTIONED_DOMAIN_NAME), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );

            let (expired_at, owner) = registrar::get_record_detail(&suins, SUI_REGISTRAR, AUCTIONED_LABEL);
            assert!(expired_at == 221 + 365, 0);
            assert!(owner == FIRST_USER_ADDRESS, 0);

            let (owner, linked_addr, ttl, _) = registry::get_name_record_all_fields(&suins, utf8(AUCTIONED_DOMAIN_NAME));
            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(linked_addr == FIRST_USER_ADDRESS, 0);
            assert!(ttl == 0, 0);

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = controller::EAuctionNotEndYet)]
    fun test_register_work_if_name_not_wait_for_being_finalized_but_auction_house_not_end_yet() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);

            let commitment = controller::test_make_commitment(
                SUI_REGISTRAR,
                FIRST_LABEL,
                FIRST_USER_ADDRESS,
                FIRST_SECRET
            );
            controller::commit(
                &mut suins,
                commitment,
                &clock,
            );

            test_scenario::return_shared(suins);
            test_scenario::return_shared(clock);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                START_AUCTION_END_AT,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN, &mut ctx);
            clock::increment_for_testing(&mut clock, MIN_COMMITMENT_AGE_IN_MS);

            controller::register(
                &mut suins,
                &mut config,
                utf8(FIRST_LABEL),
                FIRST_USER_ADDRESS,
                1,
                FIRST_SECRET,
                &mut coin,
                &clock,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(clock);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&nft);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            registrar::assert_registrar_exists(&suins, SUI_REGISTRAR);

            assert!(controller::get_balance(&suins) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN, 0);
            assert!(name == utf8(FIRST_DOMAIN_NAME), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );

            let (expired_at, owner) = registrar::get_record_detail(&suins, SUI_REGISTRAR, FIRST_LABEL);
            assert!(expired_at == 121 + 365, 0);
            assert!(owner == FIRST_USER_ADDRESS, 0);

            let (owner, linked_addr, ttl, _) = registry::get_name_record_all_fields(&suins, utf8(FIRST_DOMAIN_NAME));
            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(linked_addr == FIRST_USER_ADDRESS, 0);
            assert!(ttl == 0, 0);

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = controller::EAuctionNotEndYet)]
    fun test_register_abort_if_name_are_waiting_for_being_finalized() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        start_an_auction_util(&mut scenario, AUCTIONED_LABEL);
        let seal_bid = make_seal_bid(AUCTIONED_LABEL, FIRST_USER_ADDRESS, 1000 * configuration::mist_per_sui(), FIRST_SECRET);
        place_bid_util(&mut scenario, seal_bid, 1100 * configuration::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::none(), 10);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                AUCTIONED_LABEL,
                1000 * configuration::mist_per_sui(),
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );
            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);

            let commitment = controller::test_make_commitment(
                SUI_REGISTRAR,
                FIRST_LABEL,
                FIRST_USER_ADDRESS,
                FIRST_SECRET
            );
            controller::commit(
                &mut suins,
                commitment,
                &clock,
            );
            test_scenario::return_shared(suins);
            test_scenario::return_shared(clock);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                START_AUCTION_END_AT + BIDDING_PERIOD + REVEAL_PERIOD + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            controller::register(
                &mut suins,
                &mut config,
                utf8(AUCTIONED_LABEL),
                FIRST_USER_ADDRESS,
                1,
                FIRST_SECRET,
                &mut coin,
                &clock,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(clock);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = controller::EAuctionNotEndYet)]
    fun test_register_abort_if_name_are_waiting_for_being_finalized_2() {
        let scenario = test_init();
        set_auction_config(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);

            let commitment = controller::test_make_commitment(
                SUI_REGISTRAR,
                FIRST_LABEL,
                FIRST_USER_ADDRESS,
                FIRST_SECRET
            );
            controller::commit(
                &mut suins,
                commitment,
                &clock,
            );

            test_scenario::return_shared(suins);
            test_scenario::return_shared(clock);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                START_AUCTION_END_AT + 2,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            controller::register(
                &mut suins,
                &mut config,
                utf8(AUCTIONED_LABEL),
                FIRST_USER_ADDRESS,
                1,
                FIRST_SECRET,
                &mut coin,
                &clock,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_register_works_if_auctioned_label_not_have_a_winner_and_extra_time_passes() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        start_an_auction_util(&mut scenario, AUCTIONED_LABEL);

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
            let clock = test_scenario::take_shared<Clock>(&mut scenario);

            assert!(controller::get_balance(&suins) == START_AN_AUCTION_FEE, 0);
            let commitment = controller::test_make_commitment(
                SUI_REGISTRAR,
                AUCTIONED_LABEL,
                FIRST_USER_ADDRESS,
                FIRST_SECRET
            );
            controller::commit(
                &mut suins,
                commitment,
                &clock,
            );

            test_scenario::return_shared(suins);
            test_scenario::return_shared(clock);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let auction = test_scenario::take_shared<AuctionHouse>(&mut scenario);
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                START_AUCTION_END_AT + EXTRA_PERIOD + BIDDING_PERIOD + REVEAL_PERIOD + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN, &mut ctx);
            clock::increment_for_testing(&mut clock, MIN_COMMITMENT_AGE_IN_MS);

            controller::register(
                &mut suins,
                &mut config,
                utf8(AUCTIONED_LABEL),
                FIRST_USER_ADDRESS,
                1,
                FIRST_SECRET,
                &mut coin,
                &clock,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&nft);
            registrar::assert_registrar_exists(&suins, SUI_REGISTRAR);

            assert!(controller::get_balance(&suins) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN + START_AN_AUCTION_FEE, 0);
            assert!(name == utf8(AUCTIONED_DOMAIN_NAME), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );

            let (expired_at, owner) = registrar::get_record_detail(&suins, SUI_REGISTRAR, AUCTIONED_LABEL);
            assert!(expired_at == START_AUCTION_END_AT + EXTRA_PERIOD + BIDDING_PERIOD + REVEAL_PERIOD + 1 + 365, 0);
            assert!(owner == FIRST_USER_ADDRESS, 0);

            let (owner, linked_addr, ttl, _) = registry::get_name_record_all_fields(&suins, utf8(AUCTIONED_DOMAIN_NAME));
            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(linked_addr == FIRST_USER_ADDRESS, 0);
            assert!(ttl == 0, 0);

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = controller::EAuctionNotEndYet)]
    fun test_register_works_if_auctioned_label_not_have_a_winner_and_auction_house_not_end() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        start_an_auction_util(&mut scenario, AUCTIONED_LABEL);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);

            let commitment = controller::test_make_commitment(
                SUI_REGISTRAR,
                AUCTIONED_LABEL,
                FIRST_USER_ADDRESS,
                FIRST_SECRET
            );
            controller::commit(
                &mut suins,
                commitment,
                &clock,
            );

            test_scenario::return_shared(suins);
            test_scenario::return_shared(clock);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                START_AUCTION_END_AT + BIDDING_PERIOD + REVEAL_PERIOD + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            controller::register(
                &mut suins,
                &mut config,
                utf8(AUCTIONED_LABEL),
                FIRST_USER_ADDRESS,
                1,
                FIRST_SECRET,
                &mut coin,
                &clock,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
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
            let clock = test_scenario::take_shared<Clock>(&mut scenario);

            let commitment = controller::test_make_commitment(
                SUI_REGISTRAR,
                AUCTIONED_LABEL,
                FIRST_USER_ADDRESS,
                FIRST_SECRET
            );

            controller::commit(
                &mut suins,
                commitment,
                &clock,
            );

            test_scenario::return_shared(suins);
            test_scenario::return_shared(clock);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                221,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            controller::register(
                &mut suins,
                &mut config,
                utf8(AUCTIONED_LABEL),
                FIRST_USER_ADDRESS,
                1,
                FIRST_SECRET,
                &mut coin,
                &clock,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&nft);

            assert!(controller::get_balance(&suins) == 1000000, 0);
            assert!(name == utf8(AUCTIONED_DOMAIN_NAME), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );

            let (expired_at, owner) = registrar::get_record_detail(&suins, SUI_REGISTRAR, FIRST_LABEL);
            assert!(expired_at == 221 + 365, 0);
            assert!(owner == FIRST_USER_ADDRESS, 0);

            let (owner, linked_addr, ttl, _) = registry::get_name_record_all_fields(&suins, utf8(AUCTIONED_DOMAIN_NAME));
            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(linked_addr == @0x0, 0);
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
            let clock = test_scenario::take_shared<Clock>(&mut scenario);

            let commitment = controller::test_make_commitment(
                SUI_REGISTRAR,
                AUCTIONED_LABEL,
                FIRST_USER_ADDRESS,
                FIRST_SECRET
            );

            controller::commit(
                &mut suins,
                commitment,
                &clock,
            );

            test_scenario::return_shared(suins);
            test_scenario::return_shared(clock);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                221,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            controller::register(
                &mut suins,
                &mut config,
                utf8(AUCTIONED_LABEL),
                FIRST_USER_ADDRESS,
                1,
                FIRST_SECRET,
                &mut coin,
                &clock,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(clock);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&nft);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            registrar::assert_registrar_exists(&suins, SUI_REGISTRAR);

            assert!(controller::get_balance(&suins) == 1000000, 0);
            assert!(name == utf8(AUCTIONED_DOMAIN_NAME), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b""),
                0
            );

            let (expired_at, owner) = registrar::get_record_detail(&suins, SUI_REGISTRAR, FIRST_DOMAIN_NAME);
            assert!(expired_at == 221 + 365, 0);
            assert!(owner == FIRST_USER_ADDRESS, 0);

            let (owner, linked_addr, ttl, _) = registry::get_name_record_all_fields(&suins, utf8(AUCTIONED_DOMAIN_NAME));
            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(linked_addr == @0x0, 0);
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
            let clock = test_scenario::take_shared<Clock>(&mut scenario);

            let commitment = controller::test_make_commitment(
                SUI_REGISTRAR,
                AUCTIONED_LABEL,
                FIRST_USER_ADDRESS,
                FIRST_SECRET
            );
            controller::commit(
                &mut suins,
                commitment,
                &clock,
            );

            test_scenario::return_shared(suins);
            test_scenario::return_shared(clock);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                221,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN, &mut ctx);
            clock::increment_for_testing(&mut clock, MIN_COMMITMENT_AGE_IN_MS);

            controller::register(
                &mut suins,
                &mut config,
                utf8(AUCTIONED_LABEL),
                FIRST_USER_ADDRESS,
                1,
                FIRST_SECRET,
                &mut coin,
                &clock,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&nft);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            registrar::assert_registrar_exists(&suins, SUI_REGISTRAR);

            assert!(controller::get_balance(&suins) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN, 0);
            assert!(name == utf8(AUCTIONED_DOMAIN_NAME), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );

            let (expired_at, owner) = registrar::get_record_detail(&suins, SUI_REGISTRAR, AUCTIONED_LABEL);
            assert!(expired_at == 221 + 365, 0);
            assert!(owner == FIRST_USER_ADDRESS, 0);

            let (owner, linked_addr, ttl, _) = registry::get_name_record_all_fields(&suins, utf8(AUCTIONED_DOMAIN_NAME));
            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(linked_addr == FIRST_USER_ADDRESS, 0);
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
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let i: u8 = 0;

            while (i < 70) {
                let secret = FIRST_SECRET;
                vector::push_back(&mut secret, i);
                let commitment = controller::test_make_commitment(
                    SUI_REGISTRAR,
                    FIRST_LABEL,
                    FIRST_USER_ADDRESS,
                    secret
                );
                controller::commit(
                    &mut suins,
                    commitment,
                    &clock,
                );

                i = i + 1;
            };

            assert!(controller::commitment_len(&suins) == 70, 0);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(clock);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            clock::increment_for_testing(&mut clock, controller::max_commitment_age_in_ms() + 1);

            let commitment = controller::test_make_commitment(
                SUI_REGISTRAR,
                b"label-1",
                FIRST_USER_ADDRESS,
                FIRST_SECRET
            );
            controller::commit(
                &mut suins,
                commitment,
                &clock,
            );

            test_scenario::return_shared(suins);
            test_scenario::return_shared(clock);
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
            let clock = test_scenario::take_shared<Clock>(&mut scenario);

            let commitment = controller::test_make_commitment(
                SUI_REGISTRAR,
                b"label-2",
                FIRST_USER_ADDRESS,
                FIRST_SECRET
            );
            controller::commit(
                &mut suins,
                commitment,
                &clock,
            );

            test_scenario::return_shared(suins);
            test_scenario::return_shared(clock);
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
            let clock = test_scenario::take_shared<Clock>(&mut scenario);

            let commitment = controller::test_make_commitment(
                SUI_REGISTRAR,
                b"label-3",
                FIRST_USER_ADDRESS,
                FIRST_SECRET
            );
            controller::commit(
                &mut suins,
                commitment,
                &clock,
            );

            test_scenario::return_shared(suins);
            test_scenario::return_shared(clock);
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
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let i: u8 = 0;

            while (i < 40) {
                let secret = FIRST_SECRET;
                vector::push_back(&mut secret, i);
                let commitment = controller::test_make_commitment(
                    SUI_REGISTRAR,
                    FIRST_LABEL,
                    FIRST_USER_ADDRESS,
                    secret
                );
                controller::commit(
                    &mut suins,
                    commitment,
                    &clock,
                );

                i = i + 1;
            };
            assert!(controller::commitment_len(&suins) == 40, 0);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(clock);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            clock::increment_for_testing(&mut clock, controller::max_commitment_age_in_ms() + 1);

            let commitment = controller::test_make_commitment(
                SUI_REGISTRAR,
                b"label-2",
                FIRST_USER_ADDRESS,
                FIRST_SECRET
            );
            controller::commit(
                &mut suins,
                commitment,
                &clock,
            );

            test_scenario::return_shared(suins);
            test_scenario::return_shared(clock);
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
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                21,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            controller::register_with_image(
                &mut suins,
                &mut config,
                utf8(FIRST_LABEL),
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                x"",
                x"9e60301bec6f4b857eeaae141f3eb1373468500587d2798941b09e96ab390dc3",
                b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,000000000000000000000000000000000000b001,375,abc",
                &clock,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
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
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                21,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            controller::register_with_image(
                &mut suins,
                &mut config,
                utf8(FIRST_LABEL),
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                x"1ade6c7ae5e0e2a1a4396b51c9c9df854504232e6dbf70ceb15b45ba5ab974a05045cc6fa92ed5f0a8ecd17c8e55947b867834222dc69d68b0749dd46d6902a4",
                x"",
                b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,000000000000000000000000000000000000b001,375,abc",
                &clock,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
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
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                21,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            controller::register_with_image(
                &mut suins,
                &mut config,
                utf8(FIRST_LABEL),
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                x"6aab9920d59442c5478c3f5b29db45518b40a3d76f1b396b70c902b557e93b206b0ce9ab84ce44277d84055da9dd10ff77c490ba8473cd86ead37be874b9662f",
                x"127552ffa7fb7c3718ee61851c49eba03ef7d0dc0933c7c5802cdd98226f6006",
                b"",
                &clock,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_register_with_image() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        make_commitment(&mut scenario, option::none());
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 3, &mut ctx);
            clock::increment_for_testing(&mut clock, MIN_COMMITMENT_AGE_IN_MS);

            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, FIRST_LABEL), 0);
            assert!(controller::get_balance(&suins) == 0, 0);
            assert!(controller::commitment_len(&suins) == 1, 0);
            assert!(!registry::record_exists(&suins, utf8(FIRST_DOMAIN_NAME)), 0);
            assert!(!test_scenario::has_most_recent_for_sender<RegistrationNFT>(&mut scenario), 0);

            controller::register_with_image(
                &mut suins,
                &mut config,
                utf8(FIRST_LABEL),
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                x"0d6a93a4e9b85e15dd05db3d581915f0d293a8f76f6b4b4ead065abe07e3687b2b86c5c53366f87f060dacb3af5b371ed111253a5dfcb23e912e51b34f7436f8",
                x"547d3b38ff08ca64d972bc96e86844d089523139f0f3b574321049e2d657829f",
                b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,eastagile-123.sui,887,aa",
                &clock,
                &mut ctx,
            );
            assert!(coin::value(&coin) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN, 0);
            assert!(controller::commitment_len(&suins) == 0, 0);

            coin::burn_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&nft);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            registrar::assert_registrar_exists(&suins, SUI_REGISTRAR);

            assert!(controller::get_balance(&suins) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 2, 0);
            assert!(name == utf8(FIRST_DOMAIN_NAME), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k"),
                0
            );

            let (expired_at, owner) = registrar::get_record_detail(&suins, SUI_REGISTRAR, FIRST_LABEL);
            assert!(expired_at == EXTRA_PERIOD_END_AT + 1 + 730, 0);
            assert!(owner == FIRST_USER_ADDRESS, 0);

            let (owner, linked_addr, ttl, _) = registry::get_name_record_all_fields(&suins, utf8(FIRST_DOMAIN_NAME));
            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(linked_addr == FIRST_USER_ADDRESS, 0);
            assert!(ttl == 0, 0);

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_register_with_image_2() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        make_commitment(&mut scenario, option::none());
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(4 * PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN, &mut ctx);
            clock::increment_for_testing(&mut clock, MIN_COMMITMENT_AGE_IN_MS);

            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, FIRST_LABEL), 0);
            assert!(!registry::record_exists(&suins, utf8(FIRST_DOMAIN_NAME)), 0);
            assert!(controller::get_balance(&suins) == 0, 0);
            assert!(!test_scenario::has_most_recent_for_sender<RegistrationNFT>(&mut scenario), 0);

            controller::register_with_image(
                &mut suins,
                &mut config,
                utf8(FIRST_LABEL),
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                x"cc70c9155c5d36beecd3fcecfb4bd2f65d53eb08f93bd303a773d70f6e93e8634e7b74f128c070be1f6c091f65dca3372bc7f8012747b081696b940b4cdae0d3",
                x"63697795a4e8cfa81a970e9995d52516db980885dfa483174c3044bca395a039",
                b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,eastagile-123.sui,887,;;;;",
                &clock,
                &mut ctx,
            );
            assert!(coin::value(&coin) == 2 * PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN, 0);

            coin::burn_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(clock);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&nft);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            registrar::assert_registrar_exists(&suins, SUI_REGISTRAR);

            assert!(controller::get_balance(&suins) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 2, 0);
            assert!(name == utf8(FIRST_DOMAIN_NAME), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k"),
                0
            );

            let (expired_at, owner) = registrar::get_record_detail(&suins, SUI_REGISTRAR, FIRST_LABEL);
            assert!(expired_at == EXTRA_PERIOD_END_AT + 1 + 730, 0);
            assert!(owner == FIRST_USER_ADDRESS, 0);

            let (owner, linked_addr, ttl, _) = registry::get_name_record_all_fields(&suins, utf8(FIRST_DOMAIN_NAME));
            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(linked_addr == FIRST_USER_ADDRESS, 0);
            assert!(ttl == 0, 0);

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(suins);
        };

        // withdraw
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            assert!(controller::get_balance(&suins) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 2, 0);
            assert!(!test_scenario::has_most_recent_for_sender<Coin<SUI>>(&mut scenario), 0);

            controller::withdraw(&admin_cap, &mut suins, test_scenario::ctx(&mut scenario));
            assert!(controller::get_balance(&suins) == 0, 0);

            test_scenario::return_shared(suins);
            test_scenario::return_to_sender(&mut scenario, admin_cap);
        };

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            assert!(test_scenario::has_most_recent_for_sender<Coin<SUI>>(&mut scenario), 0);
            let coin = test_scenario::take_from_sender<Coin<SUI>>(&mut scenario);
            assert!(coin::value(&coin) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 2, 0);
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
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                21,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            controller::register_with_image(
                &mut suins,
                &mut config,
                utf8(FIRST_LABEL),
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                x"b8d5c020ccf043fb1dde772067d54e254041ec4c8e137f5017158711e59e86933d1889cf4d9c6ad8ef57290cc00d99b7ba60da5c0db64a996f72af010acdd2b0",
                x"64d1c3d80ac32235d4bf1c5499ac362fd28b88eba2984e81cc36924be09f5a2d",
                b"",
                &clock,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(clock);
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
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                21,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            controller::register_with_image(
                &mut suins,
                &mut config,
                utf8(FIRST_LABEL),
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                x"",
                x"64d1c3d80ac32235d4bf1c5499ac362fd28b88eba2984e81cc36924be09f5a2d",
                b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,eastagile-123.sui,751",
                &clock,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(clock);
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
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                21,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            controller::register_with_image(
                &mut suins,
                &mut config,
                utf8(FIRST_LABEL),
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                x"b8d5c020ccf043fb1dde772067d54e254041ec4c8e137f5017158711e59e86933d1889cf4d9c6ad8ef57290cc00d99b7ba60da5c0db64a996f72af010acdd2b0",
                x"",
                b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,eastagile-123.sui,751",
                &clock,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_register_with_code_and_image() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        make_commitment(&mut scenario, option::none());
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<AuctionHouse>(&mut scenario);
            // simulate user wait for next epoch to call `register`
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 3, &mut ctx);
            clock::increment_for_testing(&mut clock, MIN_COMMITMENT_AGE_IN_MS);

            assert!(controller::get_balance(&suins) == 0, 0);
            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, FIRST_LABEL), 0);
            assert!(!registry::record_exists(&suins, utf8(FIRST_DOMAIN_NAME)), 0);
            assert!(!test_scenario::has_most_recent_for_sender<RegistrationNFT>(&mut scenario), 0);
            assert!(!test_scenario::has_most_recent_for_address<Coin<SUI>>(SECOND_USER_ADDRESS), 0);

            controller::register_with_code_and_image(
                &mut suins,
                &mut config,
                utf8(FIRST_LABEL),
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                REFERRAL_CODE,
                DISCOUNT_CODE,
                x"ebecdc69840277c9b016a129e62f677bb5a9237f94ff799efdbee1480e5e6b3a33db1218aa6c0aeed021637cd675e66433c23ee8f5d044d25bfa2ac14b9cec5f",
                x"fd2b1aeb87181c42c17e09fa64cbbe5c660aa33e5cd2e02685ebc323bae2a2ed",
                b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,eastagile-123.sui,887,hmm",
                &clock,
                &mut ctx,
            );
            assert!(coin::value(&coin) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 130 / 100, 0);

            coin::burn_for_testing(coin);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&nft);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let coin = test_scenario::take_from_address<Coin<SUI>>(&mut scenario, SECOND_USER_ADDRESS);

            registrar::assert_registrar_exists(&suins, SUI_REGISTRAR);

            assert!(name == utf8(FIRST_DOMAIN_NAME), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k"),
                0
            );
            assert!(coin::value(&coin) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 17 / 100, 0);
            assert!(controller::get_balance(&suins) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 153 / 100, 0);

            let (expired_at, owner) = registrar::get_record_detail(&suins, SUI_REGISTRAR, FIRST_LABEL);
            assert!(expired_at == EXTRA_PERIOD_END_AT + 1 + 730, 0);
            assert!(owner == FIRST_USER_ADDRESS, 0);

            let (owner, linked_addr, ttl, _) = registry::get_name_record_all_fields(&suins, utf8(FIRST_DOMAIN_NAME));
            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(linked_addr == FIRST_USER_ADDRESS, 0);
            assert!(ttl == 0, 0);

            coin::burn_for_testing(coin);
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
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                21,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            controller::register_with_code_and_image(
                &mut suins,
                &mut config,
                utf8(FIRST_LABEL),
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                REFERRAL_CODE,
                DISCOUNT_CODE,
                x"",
                x"64d1c3d80ac32235d4bf1c5499ac362fd28b88eba2984e81cc36924be09f5a2d",
                b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,eastagile-123.sui,751",
                &clock,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
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
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                21,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            controller::register_with_code_and_image(
                &mut suins,
                &mut config,
                utf8(FIRST_LABEL),
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                REFERRAL_CODE,
                DISCOUNT_CODE,
                x"b8d5c020ccf043fb1dde772067d54e254041ec4c8e137f5017158711e59e86933d1889cf4d9c6ad8ef57290cc00d99b7ba60da5c0db64a996f72af010acdd2b0",
                x"",
                b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,eastagile-123.sui,751",
                &clock,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
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
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                21,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            controller::register_with_code_and_image(
                &mut suins,
                &mut config,
                utf8(FIRST_LABEL),
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                REFERRAL_CODE,
                DISCOUNT_CODE,
                x"b8d5c020ccf043fb1dde772067d54e254041ec4c8e137f5017158711e59e86933d1889cf4d9c6ad8ef57290cc00d99b7ba60da5c0db64a996f72af010acdd2b0",
                x"64d1c3d80ac32235d4bf1c5499ac362fd28b88eba2984e81cc36924be09f5a2d",
                b"",
                &clock,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_register_with_code_and_image_2() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        make_commitment(&mut scenario, option::none());
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 3, &mut ctx);
            clock::increment_for_testing(&mut clock, MIN_COMMITMENT_AGE_IN_MS);

            assert!(controller::get_balance(&suins) == 0, 0);
            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, FIRST_LABEL), 0);
            assert!(!registry::record_exists(&suins, utf8(FIRST_DOMAIN_NAME)), 0);
            assert!(!test_scenario::has_most_recent_for_sender<RegistrationNFT>(&mut scenario), 0);
            assert!(!test_scenario::has_most_recent_for_address<Coin<SUI>>(SECOND_USER_ADDRESS), 0);

            controller::register_with_code_and_image(
                &mut suins,
                &mut config,
                utf8(FIRST_LABEL),
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                REFERRAL_CODE,
                DISCOUNT_CODE,
                x"4ebb3791b70b6a5e44c98b74cf72e6264b0b379b362dc74ba38efc2a9f89e1ab56cb4e6acdfb14614524ae4d467c2e5c1483fa59644f0bebdb0ff528bfe8b4a3",
                x"882aeea454ae963709536e1329977a06b8d7268b1e8a7271f3ef77d8c06601fa",
                b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,eastagile-123.sui,887,817",
                &clock,
                &mut ctx,
            );
            assert!(coin::value(&coin) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 130 / 100, 0);
            coin::burn_for_testing(coin);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(config);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let coin = test_scenario::take_from_address<Coin<SUI>>(&mut scenario, SECOND_USER_ADDRESS);
            let (name, url) = registrar::get_nft_fields(&nft);

            assert!(name == utf8(FIRST_DOMAIN_NAME), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k"),
                0
            );
            assert!(coin::value(&coin) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 17 / 100, 0);
            assert!(controller::get_balance(&suins) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 153 / 100, 0);

            let (expired_at, owner) = registrar::get_record_detail(&suins, SUI_REGISTRAR, FIRST_LABEL);
            assert!(expired_at == EXTRA_PERIOD_END_AT + 1 + 730, 0);
            assert!(owner == FIRST_USER_ADDRESS, 0);

            let (owner, linked_addr, ttl, _) = registry::get_name_record_all_fields(&suins, utf8(FIRST_DOMAIN_NAME));
            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(linked_addr == FIRST_USER_ADDRESS, 0);
            assert!(ttl == 0, 0);

            coin::burn_for_testing(coin);
            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registrar::EInvalidImageMessage)]
    fun test_register_with_code_and_image_aborts_with_empty_signature_2() {
        let scenario = test_init();
        make_commitment(&mut scenario, option::none());
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                DEFAULT_TX_HASH,
                21,
                0
            );
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            controller::register_with_code_and_image(
                &mut suins,
                &mut config,
                utf8(FIRST_LABEL),
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                REFERRAL_CODE,
                DISCOUNT_CODE,
                x"",
                x"64d1c3d80ac32235d4bf1c5499ac362fd28b88eba2984e81cc36924be09f5a2d",
                b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,eastagile-123.sui,751",
                &clock,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(clock);
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
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                DEFAULT_TX_HASH,
                21,
                0
            );
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            controller::register_with_code_and_image(
                &mut suins,
                &mut config,
                utf8(FIRST_LABEL),
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                REFERRAL_CODE,
                DISCOUNT_CODE,
                x"b8d5c020ccf043fb1dde772067d54e254041ec4c8e137f5017158711e59e86933d1889cf4d9c6ad8ef57290cc00d99b7ba60da5c0db64a996f72af010acdd2b0",
                x"",
                b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,eastagile-123.sui,751",
                &clock,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(clock);
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
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                DEFAULT_TX_HASH,
                21,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            controller::register_with_code_and_image(
                &mut suins,
                &mut config,
                utf8(FIRST_LABEL),
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                REFERRAL_CODE,
                DISCOUNT_CODE,
                x"b8d5c020ccf043fb1dde772067d54e254041ec4c8e137f5017158711e59e86933d1889cf4d9c6ad8ef57290cc00d99b7ba60da5c0db64a996f72af010acdd2b0",
                x"64d1c3d80ac32235d4bf1c5499ac362fd28b88eba2984e81cc36924be09f5a2d",
                b"",
                &clock,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_renew_with_image() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        register(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&nft);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            assert!(controller::get_balance(&suins) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN, 0);
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
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 2 + 1, ctx);

            assert!(registrar::name_expires_at(&suins, utf8(SUI_REGISTRAR), utf8(FIRST_LABEL)) == 522, 0);
            assert!(controller::get_balance(&suins) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN, 0);
            controller::renew_with_image(
                &mut suins,
                &config,
                utf8(FIRST_LABEL),
                2,
                &mut coin,
                &mut nft,
                x"9fadcda7144b6f0f56cf48338d1ea8d63135bab9e528bb77aae32db9727e51a402436f33733c43ae254c66d17b9814331d59b6eab749409f5a964261b534c099",
                x"b6b240d5417941ee88363f2d792d85b8d4a7cb5778c1a37d62d62354e838f9e4",
                b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,eastagile-123.sui,1252,everywhere",
                ctx,
            );
            assert!(coin::value(&coin) == 1, 0);
            assert!(registrar::name_expires_at(&suins, utf8(SUI_REGISTRAR), utf8(FIRST_LABEL)) == 1252, 0);

            coin::burn_for_testing(coin);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
            test_scenario::return_to_sender(&mut scenario, nft);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&nft);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            assert!(controller::get_balance(&suins) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 3, 0);
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
        set_auction_config(&mut scenario);
        register(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&scenario);
            let ctx = test_scenario::ctx(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 2, ctx);

            controller::renew_with_image(
                &mut suins,
                &config,
                utf8(FIRST_LABEL),
                2,
                &mut coin,
                &mut nft,
                x"",
                x"8ae97b7af21e857a343b93f0ca8a132819aa4edd4bedcee3e3a37d8f9bb89821",
                b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,eastagile-123.sui,1146",
                ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
            test_scenario::return_to_sender(&mut scenario, nft);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registrar::EInvalidImageMessage)]
    fun test_renew_with_image_aborts_with_empty_hashed_msg() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        register(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&scenario);
            let ctx = test_scenario::ctx(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 2, ctx);

            controller::renew_with_image(
                &mut suins,
                &config,
                utf8(FIRST_LABEL),
                2,
                &mut coin,
                &mut nft,
                x"a8ae97b7af21e87a343b93f0ca8a132819aa4edd4bedcee3e3a37d8f9bb89821",
                x"",
                b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,eastagile-123.sui,1252",
                ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
            test_scenario::return_to_sender(&mut scenario, nft);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registrar::EInvalidImageMessage)]
    fun test_renew_with_image_aborts_with_empty_raw_msg() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        register(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&scenario);
            let ctx = test_scenario::ctx(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 2, ctx);

            controller::renew_with_image(
                &mut suins,
                &config,
                utf8(FIRST_LABEL),
                2,
                &mut coin,
                &mut nft,
                x"a8ae97b7af21e85a343b93f0ca8a132819aa4edd4bedcee3e3a37d8f9bb89821",
                x"a8ae97b7af21857a343b93f0ca8a132819aa4edd4bedcee3e3a37d8f9bb89821",
                b"",
                ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
            test_scenario::return_to_sender(&mut scenario, nft);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registrar::ELabelExpired)]
    fun test_renew_with_image_aborts_if_being_called_too_late() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        register(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&scenario);
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                DEFAULT_TX_HASH,
                522 + GRACE_PERIOD + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 2, &mut ctx);

            assert!(registrar::name_expires_at(&suins, utf8(SUI_REGISTRAR), utf8(FIRST_LABEL)) == 522, 0);
            controller::renew_with_image(
                &mut suins,
                &config,
                utf8(FIRST_LABEL),
                2,
                &mut coin,
                &mut nft,
                x"441b360b920f87e1a35cd5a41618b35aac5718b0086eaa7073d06a50f982aeb035414cae99bfee52524de9c9904ee15f2e67baab5274d4b1775b2bcd684254cb",
                x"f9495c8390e0eac1c7046aeab762f715100bd483826c15670804c616e66b8e21",
                b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,eastagile-123.sui,1252,12",
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
            test_scenario::return_to_sender(&mut scenario, nft);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_renew_with_image_works_if_being_called_in_grace_time() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        register(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&nft);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            assert!(controller::get_balance(&suins) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN, 0);
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
            let ctx = ctx_new(
                FIRST_USER_ADDRESS,
                DEFAULT_TX_HASH,
                450,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 2 + 1, &mut ctx);

            assert!(registrar::name_expires_at(&suins, utf8(SUI_REGISTRAR), utf8(FIRST_LABEL)) == EXTRA_PERIOD_END_AT + 1 + 365, 0);
            assert!(controller::get_balance(&suins) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN, 0);

            controller::renew_with_image(
                &mut suins,
                &config,
                utf8(FIRST_LABEL),
                2,
                &mut coin,
                &mut nft,
                x"06d7f8f36614b8692040f449b9b24fcfee9b25afab03e330a0482720288eeb182865d9ec9e2c1da0fef215b15d8e621f9ca2ac3722f74a92d1e2e58bf9e937fc",
                x"6ade03578ba11ed7bc483a529a2a38f205e9b38d22fef9bc36c1e7dedce78cc0",
                b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k,eastagile-123.sui,1252,abc",
                &mut ctx,
            );

            assert!(coin::value(&coin) == 1, 0);
            assert!(registrar::name_expires_at(&suins, utf8(SUI_REGISTRAR), utf8(FIRST_LABEL)) == 1252, 0);

            coin::burn_for_testing(coin);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
            test_scenario::return_to_sender(&mut scenario, nft);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&nft);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            assert!(controller::get_balance(&suins) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 3, 0);
            assert!(name == utf8(b"eastagile-123.sui"), 0);
            assert!(url == url::new_unsafe_from_bytes(b"QmQdesiADN2mPnebRz3pvkGMKcb8Qhyb1ayW2ybvAueJ7k"), 0);

            test_scenario::return_shared(suins);
            test_scenario::return_to_sender(&mut scenario, nft);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = controller::EAuctionNotEndYet)]
    fun test_register_aborts_if_name_are_waiting_for_being_finalized_and_auction_house_not_end() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        start_an_auction_util(&mut scenario, AUCTIONED_LABEL);
        let seal_bid = make_seal_bid(AUCTIONED_LABEL, FIRST_USER_ADDRESS, 1000 * configuration::mist_per_sui(), FIRST_SECRET);
        place_bid_util(&mut scenario, seal_bid, 1100 * configuration::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::none(), 10);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                AUCTIONED_LABEL,
                1000 * configuration::mist_per_sui(),
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );
            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);

            let commitment = controller::test_make_commitment(
                SUI_REGISTRAR,
                AUCTIONED_LABEL,
                FIRST_USER_ADDRESS,
                FIRST_SECRET
            );
            controller::commit(
                &mut suins,
                commitment,
                &clock,
            );

            test_scenario::return_shared(suins);
            test_scenario::return_shared(clock);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                START_AUCTION_END_AT + EXTRA_PERIOD - 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            controller::register(
                &mut suins,
                &mut config,
                utf8(AUCTIONED_LABEL),
                FIRST_USER_ADDRESS,
                1,
                FIRST_SECRET,
                &mut coin,
                &clock,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_register_works_if_name_are_waiting_for_being_finalized_and_extra_time_passes() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        start_an_auction_util(&mut scenario, AUCTIONED_LABEL);
        let seal_bid = make_seal_bid(AUCTIONED_LABEL, FIRST_USER_ADDRESS, 1000 * configuration::mist_per_sui(), FIRST_SECRET);
        place_bid_util(&mut scenario, seal_bid, 1100 * configuration::mist_per_sui(), FIRST_USER_ADDRESS, 0, option::none(), 10);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            reveal_bid_util(
                &mut auction,
                &config,
                START_AN_AUCTION_AT + 1 + BIDDING_PERIOD,
                AUCTIONED_LABEL,
                1000 * configuration::mist_per_sui(),
                FIRST_SECRET,
                FIRST_USER_ADDRESS,
                2
            );
            test_scenario::return_shared(config);
            test_scenario::return_shared(auction);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);

            assert!(controller::get_balance(&suins) == START_AN_AUCTION_FEE + BIDDING_FEE, 0);
            let commitment = controller::test_make_commitment(
                SUI_REGISTRAR,
                AUCTIONED_LABEL,
                FIRST_USER_ADDRESS,
                FIRST_SECRET
            );
            controller::commit(
                &mut suins,
                commitment,
                &clock,
            );
            test_scenario::return_shared(suins);
            test_scenario::return_shared(clock);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                START_AUCTION_END_AT + BIDDING_PERIOD + REVEAL_PERIOD + EXTRA_PERIOD + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN, &mut ctx);
            clock::increment_for_testing(&mut clock, MIN_COMMITMENT_AGE_IN_MS);

            controller::register(
                &mut suins,
                &mut config,
                utf8(AUCTIONED_LABEL),
                FIRST_USER_ADDRESS,
                1,
                FIRST_SECRET,
                &mut coin,
                &clock,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(clock);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&nft);

            assert!(controller::get_balance(&suins) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN + START_AN_AUCTION_FEE + BIDDING_FEE, 0);
            assert!(name == utf8(AUCTIONED_DOMAIN_NAME), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );

            let (expired_at, owner) = registrar::get_record_detail(&suins, SUI_REGISTRAR, AUCTIONED_LABEL);
            assert!(
                expired_at ==
                    START_AUCTION_END_AT + BIDDING_PERIOD + REVEAL_PERIOD + EXTRA_PERIOD + 1 + 365,
                0
            );
            assert!(owner == FIRST_USER_ADDRESS, 0);

            let (owner, linked_addr, ttl, _) = registry::get_name_record_all_fields(&suins, utf8(AUCTIONED_DOMAIN_NAME));

            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(linked_addr == FIRST_USER_ADDRESS, 0);
            assert!(ttl == 0, 0);

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = controller::EAuctionNotEndYet)]
    fun test_register_label_aborts_if_in_extra_period_and_admin_calls_finalize_all_but_in_same_epoch() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        start_an_auction_util(&mut scenario, AUCTIONED_LABEL);
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);

            assert!(controller::get_balance(&suins) == START_AN_AUCTION_FEE, 0);
            finalize_all_auctions_by_admin(
                &admin_cap,
                &mut auction,
                &mut suins,
                &config,
                &mut auction_tests::ctx_util(SUINS_ADDRESS, EXTRA_PERIOD_START_AT + 1, 20),
            );
            assert!(controller::get_balance(&suins) == START_AN_AUCTION_FEE, 0);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_to_sender(&mut scenario, admin_cap);
            test_scenario::return_shared(config);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);

            let commitment = controller::test_make_commitment(
                SUI_REGISTRAR,
                AUCTIONED_LABEL,
                FIRST_USER_ADDRESS,
                FIRST_SECRET
            );
            controller::commit(
                &mut suins,
                commitment,
                &clock,
            );

            test_scenario::return_shared(suins);
            test_scenario::return_shared(clock);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_START_AT + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            controller::register(
                &mut suins,
                &mut config,
                utf8(AUCTIONED_LABEL),
                FIRST_USER_ADDRESS,
                1,
                FIRST_SECRET,
                &mut coin,
                &clock,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(clock);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_register_label_works_if_in_extra_period_and_admin_calls_finalize_all_in_previous_epoch() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        start_an_auction_util(&mut scenario, AUCTIONED_LABEL);
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let auction = test_scenario::take_shared<AuctionHouse>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);

            assert!(controller::get_balance(&suins) == START_AN_AUCTION_FEE, 0);
            finalize_all_auctions_by_admin(
                &admin_cap,
                &mut auction,
                &mut suins,
                &config,
                &mut auction_tests::ctx_util(SUINS_ADDRESS, EXTRA_PERIOD_START_AT + 1, 20),
            );
            assert!(controller::get_balance(&suins) == START_AN_AUCTION_FEE, 0);

            test_scenario::return_shared(auction);
            test_scenario::return_shared(suins);
            test_scenario::return_to_sender(&mut scenario, admin_cap);
            test_scenario::return_shared(config);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);

            let commitment = controller::test_make_commitment(
                SUI_REGISTRAR,
                AUCTIONED_LABEL,
                FIRST_USER_ADDRESS,
                FIRST_SECRET
            );
            controller::commit(
                &mut suins,
                commitment,
                &clock,
            );

            test_scenario::return_shared(suins);
            test_scenario::return_shared(clock);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_START_AT + 2,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 3, &mut ctx);
            clock::increment_for_testing(&mut clock, 300_001);

            assert!(!test_scenario::has_most_recent_for_sender<RegistrationNFT>(&mut scenario), 0);
            controller::register(
                &mut suins,
                &mut config,
                utf8(AUCTIONED_LABEL),
                FIRST_USER_ADDRESS,
                1,
                FIRST_SECRET,
                &mut coin,
                &clock,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(clock);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            assert!(test_scenario::has_most_recent_for_sender<RegistrationNFT>(&mut scenario), 0);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            let (name, url) = registrar::get_nft_fields(&nft);
            assert!(name == utf8(AUCTIONED_DOMAIN_NAME), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );

            let (expired_at, owner) = registrar::get_record_detail(&suins, SUI_REGISTRAR, AUCTIONED_LABEL);
            assert!(expired_at == EXTRA_PERIOD_START_AT + 2 + 365, 0);
            assert!(owner == FIRST_USER_ADDRESS, 0);

            let (owner, linked_addr, ttl, name) = registry::get_name_record_all_fields(&suins, utf8(AUCTIONED_DOMAIN_NAME));
            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(linked_addr == FIRST_USER_ADDRESS, 0);
            assert!(ttl == 0, 0);
            assert!(name == utf8(b""), 0);

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
    fun test_new_reserved_domains() {
        let scenario = test_init();
        let first_domain_name = b"abcde";
        let first_domain_name_sui = b"abcde.sui";
        let first_domain_name_move = b"abcde.move";
        let second_domain_name = b"abcdefghijk";
        let second_domain_name_sui = b"abcdefghijk.sui";
        let second_domain_name_move = b"abcdefghijk.move";

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let ctx = &mut ctx_new(
                SUINS_ADDRESS,
                DEFAULT_TX_HASH,
                50,
                2
            );

            assert!(registrar::is_available(&suins, utf8(SUI_REGISTRAR), utf8(first_domain_name), ctx), 0);
            assert!(registrar::is_available(&suins, utf8(MOVE_REGISTRAR), utf8(first_domain_name), ctx), 0);
            assert!(registrar::is_available(&suins, utf8(SUI_REGISTRAR), utf8(second_domain_name), ctx), 0);
            assert!(registrar::is_available(&suins, utf8(MOVE_REGISTRAR), utf8(second_domain_name), ctx), 0);

            assert!(!registry::record_exists(&suins, utf8(first_domain_name_sui)), 0);
            assert!(!registry::record_exists(&suins, utf8(first_domain_name_move)), 0);
            assert!(!registry::record_exists(&suins, utf8(second_domain_name_sui)), 0);
            assert!(!registry::record_exists(&suins, utf8(second_domain_name_move)), 0);

            controller::new_reserved_domains(
                &admin_cap,
                &mut suins,
                &config,
                b"abcde.sui;abcde.move;abcdefghijk.sui;",
                @0x0,
                ctx
            );

            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
            test_scenario::return_to_sender(&mut scenario, admin_cap);
        };
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let ctx = &mut ctx_new(
                SUINS_ADDRESS,
                DEFAULT_TX_HASH,
                50,
                10
            );

            assert!(!registrar::is_available(&suins, utf8(SUI_REGISTRAR), utf8(first_domain_name), ctx), 0);
            assert!(!registrar::is_available(&suins, utf8(MOVE_REGISTRAR), utf8(first_domain_name), ctx), 0);
            assert!(!registrar::is_available(&suins, utf8(SUI_REGISTRAR), utf8(second_domain_name), ctx), 0);
            assert!(registrar::is_available(&suins, utf8(MOVE_REGISTRAR), utf8(second_domain_name), ctx), 0);

            let (expired_at, owner) = registrar::get_record_detail(&suins, SUI_REGISTRAR, first_domain_name);
            assert!(expired_at == 415, 0);
            assert!(owner == SUINS_ADDRESS, 0);
            let (expired_at, owner) = registrar::get_record_detail(&suins, MOVE_REGISTRAR, first_domain_name);
            assert!(expired_at == 415, 0);
            assert!(owner == SUINS_ADDRESS, 0);
            let (expired_at, owner) = registrar::get_record_detail(&suins, SUI_REGISTRAR, second_domain_name);
            assert!(expired_at == 415, 0);
            assert!(owner == SUINS_ADDRESS, 0);

            assert!(registry::record_exists(&suins, utf8(first_domain_name_sui)), 0);
            assert!(registry::record_exists(&suins, utf8(first_domain_name_move)), 0);
            assert!(registry::record_exists(&suins, utf8(second_domain_name_sui)), 0);
            assert!(!registry::record_exists(&suins, utf8(second_domain_name_move)), 0);

            let (owner, linked_addr, ttl, _) = registry::get_name_record_all_fields(&suins, utf8(first_domain_name_sui));
            assert!(owner == SUINS_ADDRESS, 0);
            assert!(linked_addr == SUINS_ADDRESS, 0);
            assert!(ttl == 0, 0);
            let (owner, linked_addr, ttl, _) = registry::get_name_record_all_fields(&suins, utf8(first_domain_name_move));
            assert!(owner == SUINS_ADDRESS, 0);
            assert!(linked_addr == SUINS_ADDRESS, 0);
            assert!(ttl == 0, 0);
            let (owner, linked_addr, ttl, _) = registry::get_name_record_all_fields(&suins, utf8(second_domain_name_sui));
            assert!(owner == SUINS_ADDRESS, 0);
            assert!(linked_addr == SUINS_ADDRESS, 0);
            assert!(ttl == 0, 0);

            let first_nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&first_nft);
            assert!(name == utf8(second_domain_name_sui), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );
            let second_nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&second_nft);
            assert!(name == utf8(first_domain_name_move), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );
            let third_nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&third_nft);
            assert!(name == utf8(first_domain_name_sui), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );

            test_scenario::return_to_sender(&mut scenario, third_nft);
            test_scenario::return_to_sender(&mut scenario, second_nft);
            test_scenario::return_to_sender(&mut scenario, first_nft);
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let ctx = &mut ctx_new(
                SUINS_ADDRESS,
                DEFAULT_TX_HASH,
                52,
                20
            );

            assert!(registrar::is_available(&suins, utf8(MOVE_REGISTRAR), utf8(second_domain_name), ctx), 0);
            assert!(!registry::record_exists(&suins, utf8(second_domain_name_move)), 0);

            controller::new_reserved_domains(&admin_cap, &mut suins, &config, b"abcdefghijk.move", @0x0B, ctx);

            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
            test_scenario::return_to_sender(&mut scenario, admin_cap);
        };
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let ctx = &mut ctx_new(
                SUINS_ADDRESS,
                DEFAULT_TX_HASH,
                50,
                30
            );

            assert!(!registrar::is_available(&suins, utf8(SUI_REGISTRAR), utf8(first_domain_name), ctx), 0);
            assert!(!registrar::is_available(&suins, utf8(MOVE_REGISTRAR), utf8(first_domain_name), ctx), 0);
            assert!(!registrar::is_available(&suins, utf8(SUI_REGISTRAR), utf8(second_domain_name), ctx), 0);
            assert!(!registrar::is_available(&suins, utf8(MOVE_REGISTRAR), utf8(second_domain_name), ctx), 0);

            let (expired_at, owner) = registrar::get_record_detail(&suins, SUI_REGISTRAR, first_domain_name);
            assert!(expired_at == 415, 0);
            assert!(owner == SUINS_ADDRESS, 0);
            let (expired_at, owner) = registrar::get_record_detail(&suins, MOVE_REGISTRAR, first_domain_name);
            assert!(expired_at == 415, 0);
            assert!(owner == SUINS_ADDRESS, 0);
            let (expired_at, owner) = registrar::get_record_detail(&suins, SUI_REGISTRAR, second_domain_name);
            assert!(expired_at == 415, 0);
            assert!(owner == SUINS_ADDRESS, 0);
            let (expired_at, owner) = registrar::get_record_detail(&suins, MOVE_REGISTRAR, second_domain_name);
            assert!(expired_at == 417, 0);
            assert!(owner == @0x0B, 0);

            assert!(registry::record_exists(&suins, utf8(first_domain_name_sui)), 0);
            assert!(registry::record_exists(&suins, utf8(first_domain_name_move)), 0);
            assert!(registry::record_exists(&suins, utf8(second_domain_name_sui)), 0);
            assert!(registry::record_exists(&suins, utf8(second_domain_name_move)), 0);

            let (owner, linked_addr, ttl, name) = registry::get_name_record_all_fields(&suins, utf8(first_domain_name_sui));
            assert!(owner == SUINS_ADDRESS, 0);
            assert!(linked_addr == SUINS_ADDRESS, 0);
            assert!(ttl == 0, 0);
            assert!(name == utf8(b""), 0);
            let (owner, linked_addr, ttl, name) = registry::get_name_record_all_fields(&suins, utf8(first_domain_name_move));
            assert!(owner == SUINS_ADDRESS, 0);
            assert!(linked_addr == SUINS_ADDRESS, 0);
            assert!(ttl == 0, 0);
            assert!(name == utf8(b""), 0);
            let (owner, linked_addr, ttl, name) = registry::get_name_record_all_fields(&suins, utf8(second_domain_name_sui));
            assert!(owner == SUINS_ADDRESS, 0);
            assert!(linked_addr == SUINS_ADDRESS, 0);
            assert!(ttl == 0, 0);
            assert!(name == utf8(b""), 0);
            let (owner, linked_addr, ttl, name) = registry::get_name_record_all_fields(&suins, utf8(second_domain_name_move));
            assert!(owner == @0x0B, 0);
            assert!(linked_addr == @0x0B, 0);
            assert!(ttl == 0, 0);
            assert!(name == utf8(b""), 0);

            let first_nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&first_nft);
            assert!(name == utf8(second_domain_name_sui), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );
            let second_nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&second_nft);
            assert!(name == utf8(first_domain_name_move), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );
            let third_nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&third_nft);
            assert!(name == utf8(first_domain_name_sui), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );

            test_scenario::return_to_sender(&mut scenario, first_nft);
            test_scenario::return_to_sender(&mut scenario, second_nft);
            test_scenario::return_to_sender(&mut scenario, third_nft);
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, @0x0B);
        {
            let first_nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&first_nft);
            assert!(name == utf8(second_domain_name_move), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );
            test_scenario::return_to_sender(&mut scenario, first_nft);
        };
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let ctx = &mut ctx_new(
                SUINS_ADDRESS,
                DEFAULT_TX_HASH,
                52,
                20
            );
            let emoji_label = vector[104, 109, 109, 109, 49, 240, 159, 145, 180];
            let emoji_domain_name = vector[104, 109, 109, 109, 49, 240, 159, 145, 180, 46, 115, 117, 105];

            assert!(registrar::is_available(&suins, utf8(SUI_REGISTRAR), utf8(emoji_label), ctx), 0);
            assert!(!registry::record_exists(&suins, utf8(emoji_domain_name)), 0);
            controller::new_reserved_domains(&admin_cap, &mut suins, &config, emoji_domain_name, @0x0C, ctx);

            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
            test_scenario::return_to_sender(&mut scenario, admin_cap);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registrar::ELabelUnavailable)]
    fun test_new_reserved_domains_aborts_with_dupdated_domain_names() {
        let scenario = test_init();
        let first_domain_name = b"abcde";
        let first_domain_name_sui = b"abcde.sui";

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let ctx = &mut ctx_new(
                SUINS_ADDRESS,
                DEFAULT_TX_HASH,
                50,
                2
            );

            assert!(registrar::is_available(&suins, utf8(SUI_REGISTRAR), utf8(first_domain_name), ctx), 0);
            assert!(!registry::record_exists(&suins, utf8(first_domain_name_sui)), 0);

            controller::new_reserved_domains(&admin_cap, &mut suins, &config, b"abcde.sui;abcde.sui;", @0x0, ctx);

            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
            test_scenario::return_to_sender(&mut scenario, admin_cap);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = dynamic_field::EFieldDoesNotExist)]
    fun test_new_reserved_domains_aborts_with_malformed_domains() {
        let scenario = test_init();

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let ctx = &mut ctx_new(
                SUINS_ADDRESS,
                DEFAULT_TX_HASH,
                50,
                2
            );

            controller::new_reserved_domains(&admin_cap, &mut suins, &config, b"abcde..sui;", @0x0, ctx);

            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
            test_scenario::return_to_sender(&mut scenario, admin_cap);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = dynamic_field::EFieldDoesNotExist)]
    fun test_new_reserved_domains_aborts_with_non_existence_tld() {
        let scenario = test_init();

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let ctx = &mut ctx_new(
                SUINS_ADDRESS,
                DEFAULT_TX_HASH,
                50,
                2
            );

            controller::new_reserved_domains(&admin_cap, &mut suins, &config, b"abcde.suins;", @0x0, ctx);

            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
            test_scenario::return_to_sender(&mut scenario, admin_cap);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = emoji::EInvalidLabel)]
    fun test_new_reserved_domains_aborts_with_leading_dash_character() {
        let scenario = test_init();

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let ctx = &mut ctx_new(
                SUINS_ADDRESS,
                DEFAULT_TX_HASH,
                50,
                2
            );

            controller::new_reserved_domains(&admin_cap, &mut suins, &config, b"-abcde.sui;", @0x0, ctx);

            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
            test_scenario::return_to_sender(&mut scenario, admin_cap);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = emoji::EInvalidLabel)]
    fun test_new_reserved_domains_aborts_with_trailing_dash_character() {
        let scenario = test_init();

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let ctx = &mut ctx_new(
                SUINS_ADDRESS,
                DEFAULT_TX_HASH,
                50,
                2
            );

            controller::new_reserved_domains(&admin_cap, &mut suins, &config, b"abcde-.move;", @0x0, ctx);

            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
            test_scenario::return_to_sender(&mut scenario, admin_cap);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = emoji::EInvalidEmojiSequence)]
    fun test_new_reserved_domains_aborts_with_invalid_emoji() {
        let scenario = test_init();
        let invalid_emoji_domain_name = vector[241, 159, 152, 135, 119, 109, 109, 49, 240, 159, 145, 180, 46, 115, 117, 105];

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let ctx = &mut ctx_new(
                SUINS_ADDRESS,
                DEFAULT_TX_HASH,
                50,
                2
            );

            controller::new_reserved_domains(&admin_cap, &mut suins, &config, invalid_emoji_domain_name, @0x0, ctx);

            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
            test_scenario::return_to_sender(&mut scenario, admin_cap);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = controller::ELabelUnavailable)]
    fun test_register_aborts_if_sui_name_is_reserved() {
        let scenario = test_init();
        let first_domain_name = b"abcde";
        set_auction_config(&mut scenario);
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let ctx = &mut ctx_new(
                SUINS_ADDRESS,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1,
                2
            );

            controller::new_reserved_domains(&admin_cap, &mut suins, &config, b"abcde.sui;", SUINS_ADDRESS, ctx);

            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
            test_scenario::return_to_sender(&mut scenario, admin_cap);
        };
        make_commitment(&mut scenario, option::some(first_domain_name));
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 2,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);
            clock::increment_for_testing(&mut clock, MIN_COMMITMENT_AGE_IN_MS);

            controller::register(
                &mut suins,
                &mut config,
                utf8(first_domain_name),
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                &clock,
                &mut ctx,
            );
            coin::burn_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = controller::ECommitmentTooOld)]
    fun test_register_aborts_if_commitment_is_outdated() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        make_commitment(&mut scenario, option::none());
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);
            clock::increment_for_testing(&mut clock, controller::max_commitment_age_in_ms());

            controller::register(
                &mut suins,
                &mut config,
                utf8(FIRST_LABEL),
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                &clock,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_register_works_if_commitment_not_outdated() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        make_commitment(&mut scenario, option::none());
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 2, &mut ctx);
            clock::increment_for_testing(&mut clock, controller::max_commitment_age_in_ms() - 1);

            assert!(!test_scenario::has_most_recent_for_sender<RegistrationNFT>(&mut scenario), 0);
            controller::register(
                &mut suins,
                &mut config,
                utf8(FIRST_LABEL),
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                &clock,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            assert!(test_scenario::has_most_recent_for_sender<RegistrationNFT>(&mut scenario), 0);
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
    fun test_register_works_if_commitment_not_outdated_2() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        make_commitment(&mut scenario, option::none());
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 2, &mut ctx);
            clock::increment_for_testing(&mut clock, controller::max_commitment_age_in_ms() - 1);

            assert!(!test_scenario::has_most_recent_for_sender<RegistrationNFT>(&mut scenario), 0);
            controller::register(
                &mut suins,
                &mut config,
                utf8(FIRST_LABEL),
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                &clock,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            assert!(test_scenario::has_most_recent_for_sender<RegistrationNFT>(&mut scenario), 0);
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

    #[test, expected_failure(abort_code = controller::ECommitmentTooSoon)]
    fun test_register_aborts_if_called_too_soon() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        make_commitment(&mut scenario, option::none());
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 3, test_scenario::ctx(&mut scenario));

            controller::register(
                &mut suins,
                &mut config,
                utf8(FIRST_LABEL),
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                &clock,
                &mut auction_tests::ctx_util(SUINS_ADDRESS, EXTRA_PERIOD_END_AT + 1, 20),
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = controller::EAuctionNotEndYet)]
    fun test_register_aborts_admin_not_call_set_auction_config() {
        let scenario = test_init();
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 3, test_scenario::ctx(&mut scenario));

            controller::register(
                &mut suins,
                &mut config,
                utf8(FIRST_LABEL),
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                &clock,
                &mut auction_tests::ctx_util(SUINS_ADDRESS, EXTRA_PERIOD_END_AT + 1, 20),
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = controller::EInvalidNoYears)]
    fun test_register_aborts_if_more_than_5_years() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        make_commitment(&mut scenario, option::none());
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let ctx = ctx_new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                EXTRA_PERIOD_END_AT + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 2, &mut ctx);
            clock::increment_for_testing(&mut clock, controller::max_commitment_age_in_ms() - 1);

            assert!(!test_scenario::has_most_recent_for_sender<RegistrationNFT>(&mut scenario), 0);
            controller::register(
                &mut suins,
                &mut config,
                utf8(FIRST_LABEL),
                FIRST_USER_ADDRESS,
                6,
                FIRST_SECRET,
                &mut coin,
                &clock,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = controller::EInvalidNoYears)]
    fun test_renew_aborts_if_more_than_5_years() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        register(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let ctx = test_scenario::ctx(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 7 + 1, ctx);

            controller::renew(
                &mut suins,
                &config,
                utf8(FIRST_LABEL),
                6,
                &mut coin,
                ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = registrar::EInvalidNewExpiredAt)]
    fun test_renew_aborts_if_more_than_5_years_2() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        register(&mut scenario);
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let ctx = test_scenario::ctx(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 7 + 1, ctx);

            controller::renew(
                &mut suins,
                &config,
                utf8(FIRST_LABEL),
                5,
                &mut coin,
                ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(suins);
            test_scenario::return_shared(config);
		};
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = emoji::EInvalidLabel)]
    fun test_register_aborts_if_domain_length_has_less_than_3_characters() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        make_commitment(&mut scenario, option::some(b"ab"));
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 3, &mut ctx);
            clock::increment_for_testing(&mut clock, MIN_COMMITMENT_AGE_IN_MS);

            controller::register(
                &mut suins,
                &mut config,
                utf8(b"ab"),
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                &clock,
                &mut ctx,
            );

            coin::burn_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_register_of_domain_name_with_3_characters() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        make_commitment(&mut scenario, option::some(b"abc"));
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_THREE_CHARACTER_DOMAIN * 3, &mut ctx);
            clock::increment_for_testing(&mut clock, MIN_COMMITMENT_AGE_IN_MS);

            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, FIRST_LABEL), 0);
            assert!(controller::get_balance(&suins) == 0, 0);
            assert!(controller::commitment_len(&suins) == 1, 0);
            assert!(!registry::record_exists(&suins, utf8(FIRST_DOMAIN_NAME)), 0);
            assert!(!test_scenario::has_most_recent_for_sender<RegistrationNFT>(&mut scenario), 0);

            controller::register(
                &mut suins,
                &mut config,
                utf8(b"abc"),
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                &clock,
                &mut ctx,
            );
            assert!(coin::value(&coin) == PRICE_OF_THREE_CHARACTER_DOMAIN, 0);
            assert!(controller::commitment_len(&suins) == 0, 0);

            coin::burn_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&nft);
            registrar::assert_registrar_exists(&suins, SUI_REGISTRAR);

            assert!(controller::get_balance(&suins) == PRICE_OF_THREE_CHARACTER_DOMAIN * 2, 0);
            assert!(name == utf8(b"abc.sui"), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );

            let (expiry, owner) = registrar::get_record_detail(&suins, SUI_REGISTRAR, b"abc");
            assert!(expiry == EXTRA_PERIOD_END_AT + 1 + 730, 0);
            assert!(owner == FIRST_USER_ADDRESS, 0);

            let (owner, linked_addr, ttl, name) = registry::get_name_record_all_fields(&suins, utf8(b"abc.sui"));
            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(linked_addr == FIRST_USER_ADDRESS, 0);
            assert!(ttl == 0, 0);
            assert!(name == utf8(b""), 0);

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_register_of_domain_name_with_4_characters() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        make_commitment(&mut scenario, option::some(b"abcd"));
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FOUR_CHARACTER_DOMAIN * 3, &mut ctx);
            clock::increment_for_testing(&mut clock, MIN_COMMITMENT_AGE_IN_MS);

            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, FIRST_LABEL), 0);
            assert!(controller::get_balance(&suins) == 0, 0);
            assert!(controller::commitment_len(&suins) == 1, 0);
            assert!(!registry::record_exists(&suins, utf8(FIRST_DOMAIN_NAME)), 0);
            assert!(!test_scenario::has_most_recent_for_sender<RegistrationNFT>(&mut scenario), 0);

            controller::register(
                &mut suins,
                &mut config,
                utf8(b"abcd"),
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                &clock,
                &mut ctx,
            );
            assert!(coin::value(&coin) == PRICE_OF_FOUR_CHARACTER_DOMAIN, 0);
            assert!(controller::commitment_len(&suins) == 0, 0);

            coin::burn_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&nft);
            registrar::assert_registrar_exists(&suins, SUI_REGISTRAR);

            assert!(controller::get_balance(&suins) == PRICE_OF_FOUR_CHARACTER_DOMAIN * 2, 0);
            assert!(name == utf8(b"abcd.sui"), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );

            let (expiry, owner) = registrar::get_record_detail(&suins, SUI_REGISTRAR, b"abcd");
            assert!(expiry == EXTRA_PERIOD_END_AT + 1 + 730, 0);
            assert!(owner == FIRST_USER_ADDRESS, 0);

            let (owner, linked_addr, ttl, name) = registry::get_name_record_all_fields(&suins, utf8(b"abcd.sui"));
            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(linked_addr == FIRST_USER_ADDRESS, 0);
            assert!(ttl == 0, 0);
            assert!(name == utf8(b""), 0);

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_register_of_domain_name_with_6_characters() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        make_commitment(&mut scenario, option::some(b"abcdef"));
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 3, &mut ctx);
            clock::increment_for_testing(&mut clock, MIN_COMMITMENT_AGE_IN_MS);

            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, FIRST_LABEL), 0);
            assert!(controller::get_balance(&suins) == 0, 0);
            assert!(controller::commitment_len(&suins) == 1, 0);
            assert!(!registry::record_exists(&suins, utf8(FIRST_DOMAIN_NAME)), 0);
            assert!(!test_scenario::has_most_recent_for_sender<RegistrationNFT>(&mut scenario), 0);

            controller::register(
                &mut suins,
                &mut config,
                utf8(b"abcdef"),
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                &clock,
                &mut ctx,
            );
            assert!(coin::value(&coin) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN, 0);
            assert!(controller::commitment_len(&suins) == 0, 0);

            coin::burn_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&nft);
            registrar::assert_registrar_exists(&suins, SUI_REGISTRAR);

            assert!(controller::get_balance(&suins) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN * 2, 0);
            assert!(name == utf8(b"abcdef.sui"), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );

            let (expiry, owner) = registrar::get_record_detail(&suins, SUI_REGISTRAR, b"abcdef");
            assert!(expiry == EXTRA_PERIOD_END_AT + 1 + 730, 0);
            assert!(owner == FIRST_USER_ADDRESS, 0);

            let (owner, linked_addr, ttl, name) = registry::get_name_record_all_fields(&suins, utf8(b"abcdef.sui"));
            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(linked_addr == FIRST_USER_ADDRESS, 0);
            assert!(ttl == 0, 0);
            assert!(name == utf8(b""), 0);

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_set_price_to_register_three_character_domain() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);

            configuration::set_price_of_three_character_domain(&admin_cap, &mut config, 1_000_000_000);

            test_scenario::return_to_sender(&mut scenario, admin_cap);
            test_scenario::return_shared(config);
        };
        make_commitment(&mut scenario, option::some(b"xyz"));
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_THREE_CHARACTER_DOMAIN * 3, &mut ctx);
            clock::increment_for_testing(&mut clock, MIN_COMMITMENT_AGE_IN_MS);

            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, FIRST_LABEL), 0);
            assert!(controller::get_balance(&suins) == 0, 0);
            assert!(controller::commitment_len(&suins) == 1, 0);
            assert!(!registry::record_exists(&suins, utf8(FIRST_DOMAIN_NAME)), 0);
            assert!(!test_scenario::has_most_recent_for_sender<RegistrationNFT>(&mut scenario), 0);

            controller::register(
                &mut suins,
                &mut config,
                utf8(b"xyz"),
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                &clock,
                &mut ctx,
            );
            assert!(coin::value(&coin) == PRICE_OF_THREE_CHARACTER_DOMAIN * 3 - 1_000_000_000 * 2, 0);
            assert!(controller::commitment_len(&suins) == 0, 0);

            coin::burn_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&nft);
            registrar::assert_registrar_exists(&suins, SUI_REGISTRAR);

            assert!(controller::get_balance(&suins) == 1_000_000_000 * 2, 0);
            assert!(name == utf8(b"xyz.sui"), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );

            let (expiry, owner) = registrar::get_record_detail(&suins, SUI_REGISTRAR, b"xyz");
            assert!(expiry == EXTRA_PERIOD_END_AT + 1 + 730, 0);
            assert!(owner == FIRST_USER_ADDRESS, 0);

            let (owner, linked_addr, ttl, name) = registry::get_name_record_all_fields(&suins, utf8(b"xyz.sui"));
            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(linked_addr == FIRST_USER_ADDRESS, 0);
            assert!(ttl == 0, 0);
            assert!(name == utf8(b""), 0);

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = configuration::EInvalidNewPrice)]
    fun test_set_price_to_register_three_character_domain_aborts_if_new_price_too_low() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);

            configuration::set_price_of_three_character_domain(&admin_cap, &mut config, 1_000_000_000 - 1);

            test_scenario::return_to_sender(&mut scenario, admin_cap);
            test_scenario::return_shared(config);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = configuration::EInvalidNewPrice)]
    fun test_set_price_to_register_three_character_domain_aborts_if_new_price_too_high() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);

            configuration::set_price_of_three_character_domain(&admin_cap, &mut config, 1_000_000 * 1_000_000_000 + 1);

            test_scenario::return_to_sender(&mut scenario, admin_cap);
            test_scenario::return_shared(config);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_set_price_to_register_four_character_domain() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);

            configuration::set_price_of_four_character_domain(&admin_cap, &mut config, 1_000_000_000);

            test_scenario::return_to_sender(&mut scenario, admin_cap);
            test_scenario::return_shared(config);
        };
        make_commitment(&mut scenario, option::some(b"xyzt"));
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let clock = test_scenario::take_shared<Clock>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let ctx = ctx_new(
                @0x0,
                DEFAULT_TX_HASH,
                EXTRA_PERIOD_END_AT + 1,
                0
            );
            let coin = coin::mint_for_testing<SUI>(PRICE_OF_FOUR_CHARACTER_DOMAIN * 3, &mut ctx);
            clock::increment_for_testing(&mut clock, MIN_COMMITMENT_AGE_IN_MS);

            assert!(!registrar::record_exists(&suins, SUI_REGISTRAR, FIRST_LABEL), 0);
            assert!(controller::get_balance(&suins) == 0, 0);
            assert!(controller::commitment_len(&suins) == 1, 0);
            assert!(!registry::record_exists(&suins, utf8(FIRST_DOMAIN_NAME)), 0);
            assert!(!test_scenario::has_most_recent_for_sender<RegistrationNFT>(&mut scenario), 0);

            controller::register(
                &mut suins,
                &mut config,
                utf8(b"xyzt"),
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                &clock,
                &mut ctx,
            );
            assert!(coin::value(&coin) == PRICE_OF_FOUR_CHARACTER_DOMAIN * 3 - 1_000_000_000 * 2, 0);
            assert!(controller::commitment_len(&suins) == 0, 0);

            coin::burn_for_testing(coin);
            test_scenario::return_shared(config);
            test_scenario::return_shared(clock);
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let (name, url) = registrar::get_nft_fields(&nft);
            registrar::assert_registrar_exists(&suins, SUI_REGISTRAR);

            assert!(controller::get_balance(&suins) == 1_000_000_000 * 2, 0);
            assert!(name == utf8(b"xyzt.sui"), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY"),
                0
            );

            let (expiry, owner) = registrar::get_record_detail(&suins, SUI_REGISTRAR, b"xyzt");
            assert!(expiry == EXTRA_PERIOD_END_AT + 1 + 730, 0);
            assert!(owner == FIRST_USER_ADDRESS, 0);

            let (owner, linked_addr, ttl, name) = registry::get_name_record_all_fields(&suins, utf8(b"xyzt.sui"));
            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(linked_addr == FIRST_USER_ADDRESS, 0);
            assert!(ttl == 0, 0);
            assert!(name == utf8(b""), 0);

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = configuration::EInvalidNewPrice)]
    fun test_set_price_to_register_four_character_domain_aborts_if_new_price_too_low() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);

            configuration::set_price_of_four_character_domain(&admin_cap, &mut config, 1_000_000_000 - 1);

            test_scenario::return_to_sender(&mut scenario, admin_cap);
            test_scenario::return_shared(config);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = configuration::EInvalidNewPrice)]
    fun test_set_price_to_register_four_character_domain_aborts_if_new_price_too_high() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);

            configuration::set_price_of_four_character_domain(&admin_cap, &mut config, 1_000_000 * 1_000_000_000 + 1);

            test_scenario::return_to_sender(&mut scenario, admin_cap);
            test_scenario::return_shared(config);
        };
        test_scenario::end(scenario);
    }
}
