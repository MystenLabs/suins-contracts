// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
#[allow(deprecated_usage)]
#[test_only]
module suins_auction::auction_tests
{
    use std::type_name::TypeName;
    use sui::{
        balance::Balance,
        clock::{Self, Clock}, 
        coin::{Self, Coin}, 
        sui::SUI, 
        test_scenario::{Self, Scenario}
    };
    use suins::{
        suins,
        constants::mist_per_sui,
        domain,
        suins_registration::SuinsRegistration,
    };
    use suins_auction::{
        auction::{
            Self,
            AuctionTable,
            AdminCap,
        },
        offer::{Self, OfferTable},
        decryption,
    };
    use suins::register::Register;
    use suins::registry;
    use suins::controller::ControllerV2;
    use suins::suins::{AdminCap as AdminCapSuiNs, SuiNS};
    use suins::register_utils::register_util;
    use std::type_name;

    const DOMAIN_OWNER: address = @0xA001;
    const FIRST_ADDRESS: address = @0xB001;
    const SECOND_ADDRESS: address = @0xB002;
    const FIRST_DOMAIN_NAME: vector<u8> = b"tes-t2.sui";
    const SECOND_DOMAIN_NAME: vector<u8> = b"tesq.sui";
    const START_TIME: u64 = 100;
    const AUCTION_ACTIVE_TIME: u64 = 3700;
    const END_TIME: u64 = START_TIME + AUCTION_ACTIVE_TIME;
    const SUI_LOW_BID: u64 = 5;
    const SUI_MIN_BID: u64 = 10;
    const SUI_FIRST_BID: u64 = 20;
    const SUI_SECOND_BID: u64 = 30;
    const MS: u64 = 1000;
    const TICK_INCREMENT: u64 = 10 * MS;

    public struct TestCoin {}

    /// Helper function to set up the test environment
    fun setup_test(): (Scenario, Clock) {
        let mut scenario_val = test_scenario::begin(DOMAIN_OWNER);
        let scenario = &mut scenario_val;

        let clock = clock::create_for_testing(test_scenario::ctx(scenario));

        // Initialize
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let ctx = test_scenario::ctx(scenario);
            auction::init_for_testing(ctx);
        };

        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let mut suins = suins::init_for_testing(scenario.ctx());
            suins.authorize_app_for_testing<Register>();
            suins.authorize_app_for_testing<ControllerV2>();
            suins.share_for_testing();
            let clock = clock::create_for_testing(scenario.ctx());
            clock.share_for_testing();
        };
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let admin_cap = scenario.take_from_sender<AdminCapSuiNs>();
            let mut suins = scenario.take_shared<SuiNS>();

            registry::init_for_testing(&admin_cap, &mut suins, scenario.ctx());

            test_scenario::return_shared(suins);
            scenario.return_to_sender(admin_cap);
        };

        (scenario_val, clock)
    }

    /// Helper function to generate a new domain registration
    fun generate_domain(
        scenario: &mut Scenario,
        owner: address,
        domain_name: vector<u8>,
    ) {
        let nft = register_util<SUI>(
            scenario,
            domain_name.to_string(),
            1,
            50 * mist_per_sui(),
            0,
        );
        transfer::public_transfer(nft, owner);
    }

    /// Helper function to create a new auction
    fun create_auction<T>(
        scenario: &mut Scenario,
        owner: address,
        start_time: u64,
        end_time: u64,
        min_bid: u64,
        clock: &Clock,
    ) {
        test_scenario::next_tx(scenario, owner);
        {
            // Take the objects
            let mut auction_table = test_scenario::take_shared<AuctionTable>(scenario);
            let registration = test_scenario::take_from_sender<SuinsRegistration>(scenario);
            let ctx = test_scenario::ctx(scenario);

            // Create the auction
            auction::create_auction<T>(
                &mut auction_table,
                start_time,
                end_time,
                min_bid * mist_per_sui(),
                option::none(),
                registration,
                clock,
                ctx
            );

            // Clean up
            test_scenario::return_shared(auction_table);
        };
    }

    /// Helper function to place a bid in an auction
    fun place_bid<T>(
        scenario: &mut Scenario,
        bidder: address,
        domain_name: vector<u8>,
        amount: u64,
        clock: &Clock,
    ) {
        test_scenario::next_tx(scenario, bidder);
        {
            // Take the objects
            let mut auction_table = test_scenario::take_shared<AuctionTable>(scenario);
            let ctx = test_scenario::ctx(scenario);

            // Create test SUI coins for bidding
            let payment = coin::mint_for_testing<T>(amount * mist_per_sui(), ctx);

            // Place the bid
            auction::place_bid<T>(
                &mut auction_table,
                domain_name.to_string(),
                payment,
                clock,
                ctx
            );

            // Clean up
            test_scenario::return_shared(auction_table);
        };
    }

    /// Helper function to finalize an auction
    fun finalize_auction<T>(
        scenario: &mut Scenario,
        domain_name: vector<u8>,
        clock: &Clock,
    ) {
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let mut auction_table = test_scenario::take_shared<AuctionTable>(scenario);
            let mut suins = test_scenario::take_shared<SuiNS>(scenario);
            let ctx = test_scenario::ctx(scenario);

            auction::finalize_auction<T>(
                &mut suins,
                &mut auction_table,
                domain_name.to_string(),
                option::none(),
                option::none(),
                clock,
                ctx
            );

            test_scenario::return_shared(auction_table);
            test_scenario::return_shared(suins);
        };
    }

    #[test]
    fun auction_scenario_sui_test() {
        let (mut scenario_val, mut clock) = setup_test();
        let scenario = &mut scenario_val;

        generate_domain(scenario, DOMAIN_OWNER, FIRST_DOMAIN_NAME);

        // Increment the clock to the start time
        clock.increment_for_testing(START_TIME * MS);

        create_auction<SUI>(
            scenario,
            DOMAIN_OWNER,
            START_TIME,
            END_TIME,
            SUI_MIN_BID,
            &clock,
        );

        // Increment the clock to near the end of auction (within bid extension window)
        // We want to be within 300 seconds of end_time to trigger extension
        clock.increment_for_testing((AUCTION_ACTIVE_TIME - 50) * MS);

        // First address places a bid, auction time is extended
        place_bid<SUI>(scenario, FIRST_ADDRESS, FIRST_DOMAIN_NAME, SUI_FIRST_BID, &clock);

        // Tx to check auction state
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let auction_table = test_scenario::take_shared<AuctionTable>(scenario);
            let table = auction::get_auction_table_bag(&auction_table);
            assert!(table.contains(FIRST_DOMAIN_NAME), 0);
            assert!(table.length() == 1, 0);
            let auction = auction::get_auction<SUI>(table, FIRST_DOMAIN_NAME);
            assert!(auction::get_owner(auction) == DOMAIN_OWNER, 0);
            assert!(auction::get_start_time(auction) == START_TIME, 0);
            assert!(auction::get_end_time(auction) == END_TIME + 250, 0); // auction extended by 5 minutes from (END_TIME - 50)
            assert!(auction::get_min_bid(auction) == SUI_MIN_BID * mist_per_sui(), 0);
            assert!(auction::get_highest_bidder(auction) == FIRST_ADDRESS, 0);
            assert!(auction::get_highest_bid_balance(auction).value() == SUI_FIRST_BID * mist_per_sui(), 0);
            assert!(auction::get_suins_registration(auction).domain() == domain::new(FIRST_DOMAIN_NAME.to_string()), 0);
            test_scenario::return_shared(auction_table);
        };

        // Second address places a bid, auction time is not extended since clock was not incremented
        place_bid<SUI>(scenario, SECOND_ADDRESS, FIRST_DOMAIN_NAME, SUI_SECOND_BID, &clock);

        // Tx to check auction and accounts state
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let auction_table = test_scenario::take_shared<AuctionTable>(scenario);
            let table = auction::get_auction_table_bag(&auction_table);
            assert!(table.contains(FIRST_DOMAIN_NAME), 0);
            assert!(table.length() == 1, 0);
            let auction = auction::get_auction<SUI>(table, FIRST_DOMAIN_NAME);
            assert!(auction::get_owner(auction) == DOMAIN_OWNER, 0);
            assert!(auction::get_start_time(auction) == START_TIME, 0);
            assert!(auction::get_end_time(auction) == END_TIME + 250, 0);
            assert!(auction::get_min_bid(auction) == SUI_MIN_BID * mist_per_sui(), 0);
            assert!(auction::get_highest_bidder(auction) == SECOND_ADDRESS, 0);
            assert!(auction::get_highest_bid_balance(auction).value() == SUI_SECOND_BID * mist_per_sui(), 0);
            assert!(auction::get_suins_registration(auction).domain() == domain::new(FIRST_DOMAIN_NAME.to_string()), 0);
            test_scenario::return_shared(auction_table);

            let first_bid = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_ADDRESS);
            assert!(coin::value(&first_bid) == SUI_FIRST_BID * mist_per_sui(), 0);
            test_scenario::return_to_address(FIRST_ADDRESS, first_bid);
        };

        // Increment the clock to over end auction time
        clock.increment_for_testing((AUCTION_ACTIVE_TIME + 300) * MS);

        // Finalize the auction
        finalize_auction<SUI>(scenario, FIRST_DOMAIN_NAME, &clock);

        // Tx to check auction and accounts state
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let auction_table = test_scenario::take_shared<AuctionTable>(scenario);
            let table = auction::get_auction_table_bag(&auction_table);
            assert!(table.length() == 0, 0);

            let first_bid = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_ADDRESS);
            assert!(coin::value(&first_bid) == SUI_FIRST_BID * mist_per_sui(), 0);
            test_scenario::return_to_address(FIRST_ADDRESS, first_bid);

            let winning_bid = test_scenario::take_from_address<Coin<SUI>>(scenario, DOMAIN_OWNER);
            assert!(coin::value(&winning_bid) == SUI_SECOND_BID * mist_per_sui() * 97_500 / 100_000, 0); // substract 2.5% service fee
            test_scenario::return_to_address(DOMAIN_OWNER, winning_bid);

            let fees = auction::get_auction_table_fees(&auction_table);
            let sui_type_name = type_name::with_defining_ids<SUI>();
            let fee_balance = fees.borrow<TypeName, Balance<SUI>>(sui_type_name);
            assert!(fee_balance.value() == SUI_SECOND_BID * mist_per_sui() * 2_500 / 100_000, 0);

            test_scenario::return_shared(auction_table);

            let registration = test_scenario::take_from_address<SuinsRegistration>(scenario, SECOND_ADDRESS);
            assert!(registration.domain() == domain::new(FIRST_DOMAIN_NAME.to_string()), 0);
            test_scenario::return_to_address(SECOND_ADDRESS, registration);
        };

        // Final cleanup
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario_val);
    }

    #[test]
    fun auction_scenario_other_test() {
        let (mut scenario_val, mut clock) = setup_test();
        let scenario = &mut scenario_val;

        generate_domain(scenario, DOMAIN_OWNER, FIRST_DOMAIN_NAME);

        // Increment the clock to the start time
        clock.increment_for_testing(START_TIME * MS);

        // Allow token
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
            let mut auction_table = test_scenario::take_shared<AuctionTable>(scenario);
            let mut offer_table = test_scenario::take_shared<OfferTable>(scenario);

            auction::add_allowed_token<TestCoin>(&admin_cap, &mut auction_table, &mut offer_table);

            transfer::public_transfer(admin_cap, DOMAIN_OWNER);
            test_scenario::return_shared(auction_table);
            test_scenario::return_shared(offer_table);
        };

        create_auction<TestCoin>(
            scenario,
            DOMAIN_OWNER,
            START_TIME,
            END_TIME + 300,
            SUI_MIN_BID,
            &clock,
        );

        // Disallow the token, other operations still work
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
            let mut auction_table = test_scenario::take_shared<AuctionTable>(scenario);
            let mut offer_table = test_scenario::take_shared<OfferTable>(scenario);

            auction::remove_allowed_token<TestCoin>(&admin_cap, &mut auction_table, &mut offer_table);

            transfer::public_transfer(admin_cap, DOMAIN_OWNER);
            test_scenario::return_shared(auction_table);
            test_scenario::return_shared(offer_table);
        };

        // Increment the clock to auction active
        clock.increment_for_testing(TICK_INCREMENT);

        // First address places a bid, auction time is NOT extended
        place_bid<TestCoin>(scenario, FIRST_ADDRESS, FIRST_DOMAIN_NAME, SUI_FIRST_BID, &clock);

        // Tx to check auction state
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let auction_table = test_scenario::take_shared<AuctionTable>(scenario);
            let table = auction::get_auction_table_bag(&auction_table);
            assert!(table.contains(FIRST_DOMAIN_NAME), 0);
            assert!(table.length() == 1, 0);
            let auction = auction::get_auction<TestCoin>(table, FIRST_DOMAIN_NAME);
            assert!(auction::get_owner(auction) == DOMAIN_OWNER, 0);
            assert!(auction::get_start_time(auction) == START_TIME, 0);
            assert!(auction::get_end_time(auction) == END_TIME + 300, 0); // auction extended by 5 minutes
            assert!(auction::get_min_bid(auction) == SUI_MIN_BID * mist_per_sui(), 0);
            assert!(auction::get_highest_bidder(auction) == FIRST_ADDRESS, 0);
            assert!(auction::get_highest_bid_balance(auction).value() == SUI_FIRST_BID * mist_per_sui(), 0);
            assert!(auction::get_suins_registration(auction).domain() == domain::new(FIRST_DOMAIN_NAME.to_string()), 0);
            test_scenario::return_shared(auction_table);
        };

        // Increment the clock to over end auction time
        clock.increment_for_testing((AUCTION_ACTIVE_TIME + 300) * MS);

        // Finalize the auction
        finalize_auction<TestCoin>(scenario, FIRST_DOMAIN_NAME, &clock);

        // Tx to check auction and accounts state
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let auction_table = test_scenario::take_shared<AuctionTable>(scenario);
            let table = auction::get_auction_table_bag(&auction_table);
            assert!(table.length() == 0, 0);

            let winning_bid = test_scenario::take_from_address<Coin<TestCoin>>(scenario, DOMAIN_OWNER);
            assert!(coin::value(&winning_bid) == SUI_FIRST_BID * mist_per_sui() * 97_500 / 100_000, 0); // substract 2.5% service fee
            test_scenario::return_to_address(DOMAIN_OWNER, winning_bid);

            let fees = auction::get_auction_table_fees(&auction_table);
            let test_coin_type_name = type_name::with_defining_ids<TestCoin>();
            let fee_balance = fees.borrow<TypeName, Balance<TestCoin>>(test_coin_type_name);
            assert!(fee_balance.value() == SUI_FIRST_BID * mist_per_sui() * 2_500 / 100_000, 0);

            test_scenario::return_shared(auction_table);

            let registration = test_scenario::take_from_address<SuinsRegistration>(scenario, FIRST_ADDRESS);
            assert!(registration.domain() == domain::new(FIRST_DOMAIN_NAME.to_string()), 0);
            test_scenario::return_to_address(FIRST_ADDRESS, registration);
        };

        // Final cleanup
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario_val);
    }

    #[test]
    fun auction_scenario_reserve_price_test() {
        use seal::key_server::{create_and_transfer_v1, KeyServer, destroy_for_testing as ks_destroy};

        let (mut scenario_val, mut clock) = setup_test();
        let scenario = &mut scenario_val;

        generate_domain(scenario, DOMAIN_OWNER, FIRST_DOMAIN_NAME);

        // Increment the clock to the start time
        clock.increment_for_testing(START_TIME * MS);

        // Setup key servers.
        let pk0 =
            x"a58bfa576a8efe2e2730bc664b3dbe70257d8e35106e4af7353d007dba092d722314a0aeb6bca5eed735466bbf471aef01e4da8d2efac13112c51d1411f6992b8604656ea2cf6a33ec10ce8468de20e1d7ecbfed8688a281d462f72a41602161";
        create_and_transfer_v1(
            b"mysten0".to_string(),
            b"https://mysten-labs.com".to_string(),
            0,
            pk0,
            scenario.ctx(),
        );
        scenario.next_tx(DOMAIN_OWNER);
        let s0: KeyServer = scenario.take_from_sender();

        let pk1 =
            x"a9ce55cfa7009c3116ea29341151f3c40809b816f4ad29baa4f95c1bb23085ef02a46cf1ae5bd570d99b0c6e9faf525306224609300b09e422ae2722a17d2a969777d53db7b52092e4d12014da84bffb1e845c2510e26b3c259ede9e42603cd6";
        create_and_transfer_v1(
            b"mysten1".to_string(),
            b"https://mysten-labs.com".to_string(),
            0,
            pk1,
            scenario.ctx(),
        );
        scenario.next_tx(DOMAIN_OWNER);
        let s1: KeyServer = scenario.take_from_sender();

        let pk2 =
            x"93b3220f4f3a46fb33074b590cda666c0ebc75c7157d2e6492c62b4aebc452c29f581361a836d1abcbe1386268a5685103d12dec04aadccaebfa46d4c92e2f2c0381b52d6f2474490d02280a9e9d8c889a3fce2753055e06033f39af86676651";
        create_and_transfer_v1(
            b"mysten2".to_string(),
            b"https://mysten-labs.com".to_string(),
            0,
            pk2,
            scenario.ctx(),
        );
        scenario.next_tx(DOMAIN_OWNER);
        let s2: KeyServer = scenario.take_from_sender();

        // Set Seal config
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
            let mut auction_table = test_scenario::take_shared<AuctionTable>(scenario);

            auction::set_seal_config(
                &admin_cap,
                &mut auction_table,
                vector[s0.id(), s1.id(), s2.id()],
                vector[pk0, pk1, pk2],
                2
            );

            transfer::public_transfer(admin_cap, DOMAIN_OWNER);
            test_scenario::return_shared(auction_table);
        };

        // Encrypted data
        // encoded_reserve_price = x"00c817a804000000";
        // let reserve_price = 2 * SUI_MIN_BID * mist_per_sui();
        // let encoded_reserve_price = sui::bcs::to_bytes(&reserve_price);
        // id = x"64000000000000007465732d74322e737569";
        let id = decryption::get_encryption_id(START_TIME, FIRST_DOMAIN_NAME);
        // cargo run --bin seal-cli encrypt-hmac --message 0x00c817a804000000 --aad 0x000000000000000000000000000000000000000000000000000000000000a001 --package-id 0x1 --id 0x64000000000000007465732d74322e737569 --threshold 2 a58bfa576a8efe2e2730bc664b3dbe70257d8e35106e4af7353d007dba092d722314a0aeb6bca5eed735466bbf471aef01e4da8d2efac13112c51d1411f6992b8604656ea2cf6a33ec10ce8468de20e1d7ecbfed8688a281d462f72a41602161 a9ce55cfa7009c3116ea29341151f3c40809b816f4ad29baa4f95c1bb23085ef02a46cf1ae5bd570d99b0c6e9faf525306224609300b09e422ae2722a17d2a969777d53db7b52092e4d12014da84bffb1e845c2510e26b3c259ede9e42603cd6 93b3220f4f3a46fb33074b590cda666c0ebc75c7157d2e6492c62b4aebc452c29f581361a836d1abcbe1386268a5685103d12dec04aadccaebfa46d4c92e2f2c0381b52d6f2474490d02280a9e9d8c889a3fce2753055e06033f39af86676651 -- 0xbfd1d3ac3d6c37f03afe4d7c244e677f9b01fcbff79dae3394640a7944e5f5ab 0x8fac4aefdc1ae21c00f745605297041e0f39667844068e3757d587c8039d1e3f 0x9a0e57f118b817d7f60599157cad12d788a8562ee5dd1b098b7c25b25bd83f56
        // cargo run --bin seal-cli symmetric-decrypt --key 0x1c6f5a425f2821e10dc41b0d2ccb35afc808133e5488575f02085952531b36bf 0000000000000000000000000000000000000000000000000000000000000000011264000000000000007465732d74322e73756903bfd1d3ac3d6c37f03afe4d7c244e677f9b01fcbff79dae3394640a7944e5f5ab018fac4aefdc1ae21c00f745605297041e0f39667844068e3757d587c8039d1e3f029a0e57f118b817d7f60599157cad12d788a8562ee5dd1b098b7c25b25bd83f56030200a31c3d160d925b7ae42df403a9a9e15b303dae12ff0a44645ab9cca1343adf18a8bb8fdefa39856ddec304a14f061a720e76b9c41241308095a354b939b51cffcac0589a293260dc028fb4fb12a6c63ee3c8e8bdf74be725420cfa8404a6895703c85ccd9c91e704a87bd2e112bdfa71f428bc9622558d4baace8ccc5ce34de88299ffb7d83b5e7f1bb0e2bf5c0018fd2463066e0ac85b0667b8f6b8d886e681cfda6d6d06921e087b314c016a5475d801a008a83816770c767aeadc529ca007c6dee061fb65cadaca7cfbf0f29408682f2c9e1e8a0a874ebf1521f787cdea80be0108082c5c130d22f1cf0120000000000000000000000000000000000000000000000000000000000000a0015da95c0d4eee207717e0e54e5719cd8174254facd5590716c7037e544018e48d
        let encrypted_object =
            x"0000000000000000000000000000000000000000000000000000000000000000011264000000000000007465732d74322e73756903bfd1d3ac3d6c37f03afe4d7c244e677f9b01fcbff79dae3394640a7944e5f5ab018fac4aefdc1ae21c00f745605297041e0f39667844068e3757d587c8039d1e3f029a0e57f118b817d7f60599157cad12d788a8562ee5dd1b098b7c25b25bd83f56030200a31c3d160d925b7ae42df403a9a9e15b303dae12ff0a44645ab9cca1343adf18a8bb8fdefa39856ddec304a14f061a720e76b9c41241308095a354b939b51cffcac0589a293260dc028fb4fb12a6c63ee3c8e8bdf74be725420cfa8404a6895703c85ccd9c91e704a87bd2e112bdfa71f428bc9622558d4baace8ccc5ce34de88299ffb7d83b5e7f1bb0e2bf5c0018fd2463066e0ac85b0667b8f6b8d886e681cfda6d6d06921e087b314c016a5475d801a008a83816770c767aeadc529ca007c6dee061fb65cadaca7cfbf0f29408682f2c9e1e8a0a874ebf1521f787cdea80be0108082c5c130d22f1cf0120000000000000000000000000000000000000000000000000000000000000a0015da95c0d4eee207717e0e54e5719cd8174254facd5590716c7037e544018e48d";

        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            // Take the objects
            let mut auction_table = test_scenario::take_shared<AuctionTable>(scenario);
            let registration = test_scenario::take_from_sender<SuinsRegistration>(scenario);
            let ctx = test_scenario::ctx(scenario);

            // Create the auction
            auction::create_auction<SUI>(
                &mut auction_table,
                START_TIME,
                END_TIME,
                SUI_MIN_BID * mist_per_sui(),
                option::some(encrypted_object),
                registration,
                &clock,
                ctx
            );

            // Clean up
            test_scenario::return_shared(auction_table);
        };

        // Increment the clock to auction active
        clock.increment_for_testing(TICK_INCREMENT);

        // First address places a bid which is above the reserve price
        place_bid<SUI>(scenario, FIRST_ADDRESS, FIRST_DOMAIN_NAME, 2 * SUI_MIN_BID, &clock);

        // Increment the clock to over end auction time
        clock.increment_for_testing((AUCTION_ACTIVE_TIME + 300) * MS);

        // The derived keys. These should have been retrieved from key servers. They can also be computed from the cli:
        // cargo run --bin seal-cli extract --package-id 0x1 --id 0x64000000000000007465732d74322e737569 --master-key 3c185eb32f1ab43a013c7d84659ec7b59791ca76764af4ee8d387bf05621f0c7
        let dk0 =
            x"a36305c6aac5d3f853a446d0984f5e8c0bbc4c67ca5941931a8e7ac8289f30f7171f0ccd4b37d80219725c3ed056b2d4";
        // cargo run --bin seal-cli extract --package-id 0x1 --id 0x64000000000000007465732d74322e737569 --master-key 09ba20939b2300c5ffa42e71809d3dc405b1e68259704b3cb8e04c36b0033e24
        let dk1 =
            x"8ce614ff6838c7fbf9c4886b24ee85ac2d96573a1436789d23dd6c96c2668ebaa20536f6cd7aa13a794d92930bbd3827";

        // Finalize the auction
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let mut auction_table = test_scenario::take_shared<AuctionTable>(scenario);
            let mut suins = test_scenario::take_shared<SuiNS>(scenario);
            let ctx = test_scenario::ctx(scenario);

            // seal_approve should not error
            auction::seal_approve<SUI>(id, &auction_table, &clock);

            auction::finalize_auction<SUI>(
                &mut suins,
                &mut auction_table,
                FIRST_DOMAIN_NAME.to_string(),
                option::some(vector[dk0, dk1]),
                option::some(vector[s0.id(), s1.id()]),
                &clock,
                ctx
            );

            test_scenario::return_shared(auction_table);
            test_scenario::return_shared(suins);
        };

        // Tx to check auction and accounts state
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let auction_table = test_scenario::take_shared<AuctionTable>(scenario);
            let table = auction::get_auction_table_bag(&auction_table);
            assert!(table.length() == 0, 0);

            let winning_bid = test_scenario::take_from_address<Coin<SUI>>(scenario, DOMAIN_OWNER);
            assert!(coin::value(&winning_bid) == 2 * SUI_MIN_BID * mist_per_sui() * 97_500 / 100_000, 0); // substract 2.5% service fee
            test_scenario::return_to_address(DOMAIN_OWNER, winning_bid);

            let fees = auction::get_auction_table_fees(&auction_table);
            let sui_type_name = type_name::with_defining_ids<SUI>();
            let fee_balance = fees.borrow<TypeName, Balance<SUI>>(sui_type_name);
            assert!(fee_balance.value() == 2 * SUI_MIN_BID * mist_per_sui() * 2_500 / 100_000, 0);

            test_scenario::return_shared(auction_table);

            let registration = test_scenario::take_from_address<SuinsRegistration>(scenario, FIRST_ADDRESS);
            assert!(registration.domain() == domain::new(FIRST_DOMAIN_NAME.to_string()), 0);
            test_scenario::return_to_address(FIRST_ADDRESS, registration);
        };

        // Final cleanup
        ks_destroy(s0);
        ks_destroy(s1);
        ks_destroy(s2);
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario_val);
    }

    #[test]
    fun auction_scenario_reserve_price_no_winner_test() {
        use seal::key_server::{create_and_transfer_v1, KeyServer, destroy_for_testing as ks_destroy};

        let (mut scenario_val, mut clock) = setup_test();
        let scenario = &mut scenario_val;

        generate_domain(scenario, DOMAIN_OWNER, FIRST_DOMAIN_NAME);

        // Increment the clock to the start time
        clock.increment_for_testing(START_TIME * MS);

        // Setup key servers.
        let pk0 =
            x"a58bfa576a8efe2e2730bc664b3dbe70257d8e35106e4af7353d007dba092d722314a0aeb6bca5eed735466bbf471aef01e4da8d2efac13112c51d1411f6992b8604656ea2cf6a33ec10ce8468de20e1d7ecbfed8688a281d462f72a41602161";
        create_and_transfer_v1(
            b"mysten0".to_string(),
            b"https://mysten-labs.com".to_string(),
            0,
            pk0,
            scenario.ctx(),
        );
        scenario.next_tx(DOMAIN_OWNER);
        let s0: KeyServer = scenario.take_from_sender();

        let pk1 =
            x"a9ce55cfa7009c3116ea29341151f3c40809b816f4ad29baa4f95c1bb23085ef02a46cf1ae5bd570d99b0c6e9faf525306224609300b09e422ae2722a17d2a969777d53db7b52092e4d12014da84bffb1e845c2510e26b3c259ede9e42603cd6";
        create_and_transfer_v1(
            b"mysten1".to_string(),
            b"https://mysten-labs.com".to_string(),
            0,
            pk1,
            scenario.ctx(),
        );
        scenario.next_tx(DOMAIN_OWNER);
        let s1: KeyServer = scenario.take_from_sender();

        let pk2 =
            x"93b3220f4f3a46fb33074b590cda666c0ebc75c7157d2e6492c62b4aebc452c29f581361a836d1abcbe1386268a5685103d12dec04aadccaebfa46d4c92e2f2c0381b52d6f2474490d02280a9e9d8c889a3fce2753055e06033f39af86676651";
        create_and_transfer_v1(
            b"mysten2".to_string(),
            b"https://mysten-labs.com".to_string(),
            0,
            pk2,
            scenario.ctx(),
        );
        scenario.next_tx(DOMAIN_OWNER);
        let s2: KeyServer = scenario.take_from_sender();

        // Set Seal config
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
            let mut auction_table = test_scenario::take_shared<AuctionTable>(scenario);

            auction::set_seal_config(
                &admin_cap,
                &mut auction_table,
                vector[s0.id(), s1.id(), s2.id()],
                vector[pk0, pk1, pk2],
                2
            );

            transfer::public_transfer(admin_cap, DOMAIN_OWNER);
            test_scenario::return_shared(auction_table);
        };

        // Encrypted data
        // encoded_reserve_price = x"00c817a804000000";
        // let reserve_price = 2 * SUI_MIN_BID * mist_per_sui();
        // let encoded_reserve_price = sui::bcs::to_bytes(&reserve_price);
        // id = x"64000000000000007465732d74322e737569";
        // let id = suins_auction::decryption::get_encryption_id(START_TIME, FIRST_DOMAIN_NAME);
        // cargo run --bin seal-cli encrypt-hmac --message 0x00c817a804000000 --aad 0x000000000000000000000000000000000000000000000000000000000000a001 --package-id 0x1 --id 0x64000000000000007465732d74322e737569 --threshold 2 a58bfa576a8efe2e2730bc664b3dbe70257d8e35106e4af7353d007dba092d722314a0aeb6bca5eed735466bbf471aef01e4da8d2efac13112c51d1411f6992b8604656ea2cf6a33ec10ce8468de20e1d7ecbfed8688a281d462f72a41602161 a9ce55cfa7009c3116ea29341151f3c40809b816f4ad29baa4f95c1bb23085ef02a46cf1ae5bd570d99b0c6e9faf525306224609300b09e422ae2722a17d2a969777d53db7b52092e4d12014da84bffb1e845c2510e26b3c259ede9e42603cd6 93b3220f4f3a46fb33074b590cda666c0ebc75c7157d2e6492c62b4aebc452c29f581361a836d1abcbe1386268a5685103d12dec04aadccaebfa46d4c92e2f2c0381b52d6f2474490d02280a9e9d8c889a3fce2753055e06033f39af86676651 -- 0xbfd1d3ac3d6c37f03afe4d7c244e677f9b01fcbff79dae3394640a7944e5f5ab 0x8fac4aefdc1ae21c00f745605297041e0f39667844068e3757d587c8039d1e3f 0x9a0e57f118b817d7f60599157cad12d788a8562ee5dd1b098b7c25b25bd83f56
        // cargo run --bin seal-cli symmetric-decrypt --key 0x5a037551048952c0f31f655243cbeb6e7d627c3892666f607879c165eb6daf29 0000000000000000000000000000000000000000000000000000000000000000011264000000000000007465732d74322e73756903bfd1d3ac3d6c37f03afe4d7c244e677f9b01fcbff79dae3394640a7944e5f5ab018fac4aefdc1ae21c00f745605297041e0f39667844068e3757d587c8039d1e3f029a0e57f118b817d7f60599157cad12d788a8562ee5dd1b098b7c25b25bd83f56030200abef5d30709b490025bd3f62a91a248c95b285750e6a2fed204daeafa732e5e1eea2eae0dc5ba7d33b953a6c4ae617440ddbe9fc8218fc506bce611e2eef7b911707017ab21f95ff17b158acc057aa764892ae864415ca961cdc00e7119ae54603a467ae9212e40c753073344042ddec55b6c86dbaa485ea020c29aa67979e5b2e70b7e2d962ca783a44780ddd60e9965c2596bb3a23eb0b06dbbb263331140c8297d273e999496aa94875bba2e6a987171e1a87ba6a9ed68a97d24ebf0c60fdfb05ade79391c611bccc47313f79996ee8713d39413fd8e7435610effc43a89a860108d95573e5f13042f30120000000000000000000000000000000000000000000000000000000000000a0018e7c1898d73d195bde76ff7e6910d12979ed23702f83ac6bbc67679c76772b83
        let encrypted_object =
            x"0000000000000000000000000000000000000000000000000000000000000000011264000000000000007465732d74322e73756903bfd1d3ac3d6c37f03afe4d7c244e677f9b01fcbff79dae3394640a7944e5f5ab018fac4aefdc1ae21c00f745605297041e0f39667844068e3757d587c8039d1e3f029a0e57f118b817d7f60599157cad12d788a8562ee5dd1b098b7c25b25bd83f56030200abef5d30709b490025bd3f62a91a248c95b285750e6a2fed204daeafa732e5e1eea2eae0dc5ba7d33b953a6c4ae617440ddbe9fc8218fc506bce611e2eef7b911707017ab21f95ff17b158acc057aa764892ae864415ca961cdc00e7119ae54603a467ae9212e40c753073344042ddec55b6c86dbaa485ea020c29aa67979e5b2e70b7e2d962ca783a44780ddd60e9965c2596bb3a23eb0b06dbbb263331140c8297d273e999496aa94875bba2e6a987171e1a87ba6a9ed68a97d24ebf0c60fdfb05ade79391c611bccc47313f79996ee8713d39413fd8e7435610effc43a89a860108d95573e5f13042f30120000000000000000000000000000000000000000000000000000000000000a0018e7c1898d73d195bde76ff7e6910d12979ed23702f83ac6bbc67679c76772b83";

        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            // Take the objects
            let mut auction_table = test_scenario::take_shared<AuctionTable>(scenario);
            let registration = test_scenario::take_from_sender<SuinsRegistration>(scenario);
            let ctx = test_scenario::ctx(scenario);

            // Create the auction
            auction::create_auction<SUI>(
                &mut auction_table,
                START_TIME,
                END_TIME,
                SUI_MIN_BID * mist_per_sui(),
                option::some(encrypted_object),
                registration,
                &clock,
                ctx
            );

            // Clean up
            test_scenario::return_shared(auction_table);
        };

        // Increment the clock to auction active
        clock.increment_for_testing(TICK_INCREMENT);

        // First address places a bid which is below the reserve price
        place_bid<SUI>(scenario, FIRST_ADDRESS, FIRST_DOMAIN_NAME, SUI_MIN_BID, &clock);

        // Increment the clock to over end auction time
        clock.increment_for_testing((AUCTION_ACTIVE_TIME + 300) * MS);

        // The derived keys. These should have been retrieved from key servers. They can also be computed from the cli:
        // cargo run --bin seal-cli extract --package-id 0x1 --id 0x64000000000000007465732d74322e737569 --master-key 3c185eb32f1ab43a013c7d84659ec7b59791ca76764af4ee8d387bf05621f0c7
        let dk0 =
            x"a36305c6aac5d3f853a446d0984f5e8c0bbc4c67ca5941931a8e7ac8289f30f7171f0ccd4b37d80219725c3ed056b2d4";
        // cargo run --bin seal-cli extract --package-id 0x1 --id 0x64000000000000007465732d74322e737569 --master-key 09ba20939b2300c5ffa42e71809d3dc405b1e68259704b3cb8e04c36b0033e24
        let dk1 =
            x"8ce614ff6838c7fbf9c4886b24ee85ac2d96573a1436789d23dd6c96c2668ebaa20536f6cd7aa13a794d92930bbd3827";

        // Finalize the auction
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let mut auction_table = test_scenario::take_shared<AuctionTable>(scenario);
            let mut suins = test_scenario::take_shared<SuiNS>(scenario);
            let ctx = test_scenario::ctx(scenario);

            auction::finalize_auction<SUI>(
                &mut suins,
                &mut auction_table,
                FIRST_DOMAIN_NAME.to_string(),
                option::some(vector[dk0, dk1]),
                option::some(vector[s0.id(), s1.id()]),
                &clock,
                ctx
            );

            test_scenario::return_shared(auction_table);
            test_scenario::return_shared(suins);
        };

        // Tx to check auction and accounts state
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let auction_table = test_scenario::take_shared<AuctionTable>(scenario);
            let table = auction::get_auction_table_bag(&auction_table);
            assert!(table.length() == 0, 0);
            test_scenario::return_shared(auction_table);

            let winning_bid = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_ADDRESS);
            assert!(coin::value(&winning_bid) == SUI_MIN_BID * mist_per_sui(), 0);
            test_scenario::return_to_address(FIRST_ADDRESS, winning_bid);

            let registration = test_scenario::take_from_address<SuinsRegistration>(scenario, DOMAIN_OWNER);
            assert!(registration.domain() == domain::new(FIRST_DOMAIN_NAME.to_string()), 0);
            test_scenario::return_to_address(DOMAIN_OWNER, registration);
        };

        // Final cleanup
        ks_destroy(s0);
        ks_destroy(s1);
        ks_destroy(s2);
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario_val);
    }

    #[test]
    fun finalize_auction_with_expired_domain() {
        let (mut scenario_val, mut clock) = setup_test();
        let scenario = &mut scenario_val;

        generate_domain(scenario, DOMAIN_OWNER, FIRST_DOMAIN_NAME);

        clock.increment_for_testing(START_TIME * MS);

        // Create an auction
        create_auction<SUI>(
            scenario,
            DOMAIN_OWNER,
            START_TIME,
            END_TIME,
            SUI_MIN_BID,
            &clock,
        );

        // Increment the clock to auction active
        clock.increment_for_testing(TICK_INCREMENT);

        // First address places a bid
        place_bid<SUI>(scenario, FIRST_ADDRESS, FIRST_DOMAIN_NAME, SUI_FIRST_BID, &clock);
      
        let one_year_seconds = 365 * 24 * 60 * 60;
        clock.increment_for_testing(one_year_seconds * MS);

        // Finalize the auction
        finalize_auction<SUI>(scenario, FIRST_DOMAIN_NAME, &clock);

        // Verify the domain went back to owner (not the bidder) because it expired
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let auction_table = test_scenario::take_shared<AuctionTable>(scenario);
            let table = auction::get_auction_table_bag(&auction_table);
            assert!(table.length() == 0, 0);

            // The bidder should get their money back
            let refunded_bid = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_ADDRESS);
            assert!(coin::value(&refunded_bid) == SUI_FIRST_BID * mist_per_sui(), 0);
            test_scenario::return_to_address(FIRST_ADDRESS, refunded_bid);

            // The domain owner should have the domain back (not get payment)
            let registration = test_scenario::take_from_address<SuinsRegistration>(scenario, DOMAIN_OWNER);
            assert!(registration.domain() == domain::new(FIRST_DOMAIN_NAME.to_string()), 0);
            test_scenario::return_to_address(DOMAIN_OWNER, registration);

            test_scenario::return_shared(auction_table);
        };

        // Final cleanup
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EEncryptionNoAccess)]
    fun try_auction_scenario_reserve_price_policy_error() {
        use seal::key_server::{create_and_transfer_v1, KeyServer};

        let (mut scenario_val, mut clock) = setup_test();
        let scenario = &mut scenario_val;

        generate_domain(scenario, DOMAIN_OWNER, FIRST_DOMAIN_NAME);

        // Increment the clock to the start time
        clock.increment_for_testing(START_TIME * MS);

        // Setup key servers.
        let pk0 =
            x"a58bfa576a8efe2e2730bc664b3dbe70257d8e35106e4af7353d007dba092d722314a0aeb6bca5eed735466bbf471aef01e4da8d2efac13112c51d1411f6992b8604656ea2cf6a33ec10ce8468de20e1d7ecbfed8688a281d462f72a41602161";
        create_and_transfer_v1(
            b"mysten0".to_string(),
            b"https://mysten-labs.com".to_string(),
            0,
            pk0,
            scenario.ctx(),
        );
        scenario.next_tx(DOMAIN_OWNER);
        let s0: KeyServer = scenario.take_from_sender();

        let pk1 =
            x"a9ce55cfa7009c3116ea29341151f3c40809b816f4ad29baa4f95c1bb23085ef02a46cf1ae5bd570d99b0c6e9faf525306224609300b09e422ae2722a17d2a969777d53db7b52092e4d12014da84bffb1e845c2510e26b3c259ede9e42603cd6";
        create_and_transfer_v1(
            b"mysten1".to_string(),
            b"https://mysten-labs.com".to_string(),
            0,
            pk1,
            scenario.ctx(),
        );
        scenario.next_tx(DOMAIN_OWNER);
        let s1: KeyServer = scenario.take_from_sender();

        let pk2 =
            x"93b3220f4f3a46fb33074b590cda666c0ebc75c7157d2e6492c62b4aebc452c29f581361a836d1abcbe1386268a5685103d12dec04aadccaebfa46d4c92e2f2c0381b52d6f2474490d02280a9e9d8c889a3fce2753055e06033f39af86676651";
        create_and_transfer_v1(
            b"mysten2".to_string(),
            b"https://mysten-labs.com".to_string(),
            0,
            pk2,
            scenario.ctx(),
        );
        scenario.next_tx(DOMAIN_OWNER);
        let s2: KeyServer = scenario.take_from_sender();

        // Set Seal config
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
            let mut auction_table = test_scenario::take_shared<AuctionTable>(scenario);

            auction::set_seal_config(
                &admin_cap,
                &mut auction_table,
                vector[s0.id(), s1.id(), s2.id()],
                vector[pk0, pk1, pk2],
                2
            );

            transfer::public_transfer(admin_cap, DOMAIN_OWNER);
            test_scenario::return_shared(auction_table);
        };

        // Encrypted data
        // encoded_reserve_price = x"00c817a804000000";
        // let reserve_price = 2 * SUI_MIN_BID * mist_per_sui();
        // let encoded_reserve_price = sui::bcs::to_bytes(&reserve_price);
        // id = x"64000000000000007465732d74322e737569";
        let id = decryption::get_encryption_id(START_TIME, FIRST_DOMAIN_NAME);
        // cargo run --bin seal-cli encrypt-hmac --message 0x00c817a804000000 --aad 0x000000000000000000000000000000000000000000000000000000000000a001 --package-id 0x1 --id 0x64000000000000007465732d74322e737569 --threshold 2 a58bfa576a8efe2e2730bc664b3dbe70257d8e35106e4af7353d007dba092d722314a0aeb6bca5eed735466bbf471aef01e4da8d2efac13112c51d1411f6992b8604656ea2cf6a33ec10ce8468de20e1d7ecbfed8688a281d462f72a41602161 a9ce55cfa7009c3116ea29341151f3c40809b816f4ad29baa4f95c1bb23085ef02a46cf1ae5bd570d99b0c6e9faf525306224609300b09e422ae2722a17d2a969777d53db7b52092e4d12014da84bffb1e845c2510e26b3c259ede9e42603cd6 93b3220f4f3a46fb33074b590cda666c0ebc75c7157d2e6492c62b4aebc452c29f581361a836d1abcbe1386268a5685103d12dec04aadccaebfa46d4c92e2f2c0381b52d6f2474490d02280a9e9d8c889a3fce2753055e06033f39af86676651 -- 0xbfd1d3ac3d6c37f03afe4d7c244e677f9b01fcbff79dae3394640a7944e5f5ab 0x8fac4aefdc1ae21c00f745605297041e0f39667844068e3757d587c8039d1e3f 0x9a0e57f118b817d7f60599157cad12d788a8562ee5dd1b098b7c25b25bd83f56
        // cargo run --bin seal-cli symmetric-decrypt --key 0xb7d6c43a294aeb41d18530d283a273f7e43c567c7377260944094bf82f9ba854 0000000000000000000000000000000000000000000000000000000000000000011264000000000000007465732d74322e73756903bfd1d3ac3d6c37f03afe4d7c244e677f9b01fcbff79dae3394640a7944e5f5ab018fac4aefdc1ae21c00f745605297041e0f39667844068e3757d587c8039d1e3f029a0e57f118b817d7f60599157cad12d788a8562ee5dd1b098b7c25b25bd83f560302008443118fda35d1dc632e8335296c5e2d0303c0a0d4468320ecde888c7fabe46e397a1531533c189c81c9cba8ceb2d44b014bb71945db95cdcd4967e9ead2930913e1539a4e4e32fb438a8104b7bb2537e039c383693b8ac191d16efeea1489330362fd617641ed5dcbd3e75b1b5bb25d39864f003dfe632456e9c708151391552f306981724d6c84482cbb984771b5c586317ed854bfd503b36bfe47c7a69df58a66dfb3c383879fe2120da465676ce6eb60aa999490ed85e1cd1c9f2f87caf56cd846cd7be8e706dbaed6311dd560af50b5f512ff467dffd1925e6bb0a8779a2a0108a1917ddb046241710120000000000000000000000000000000000000000000000000000000000000a0019a70443ac3861ccf68debf267d3ab279267141c61e09f78af61fa34e479f7d65
        let encrypted_object =
            x"0000000000000000000000000000000000000000000000000000000000000000011264000000000000007465732d74322e73756903bfd1d3ac3d6c37f03afe4d7c244e677f9b01fcbff79dae3394640a7944e5f5ab018fac4aefdc1ae21c00f745605297041e0f39667844068e3757d587c8039d1e3f029a0e57f118b817d7f60599157cad12d788a8562ee5dd1b098b7c25b25bd83f560302008443118fda35d1dc632e8335296c5e2d0303c0a0d4468320ecde888c7fabe46e397a1531533c189c81c9cba8ceb2d44b014bb71945db95cdcd4967e9ead2930913e1539a4e4e32fb438a8104b7bb2537e039c383693b8ac191d16efeea1489330362fd617641ed5dcbd3e75b1b5bb25d39864f003dfe632456e9c708151391552f306981724d6c84482cbb984771b5c586317ed854bfd503b36bfe47c7a69df58a66dfb3c383879fe2120da465676ce6eb60aa999490ed85e1cd1c9f2f87caf56cd846cd7be8e706dbaed6311dd560af50b5f512ff467dffd1925e6bb0a8779a2a0108a1917ddb046241710120000000000000000000000000000000000000000000000000000000000000a0019a70443ac3861ccf68debf267d3ab279267141c61e09f78af61fa34e479f7d65";

        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            // Take the objects
            let mut auction_table = test_scenario::take_shared<AuctionTable>(scenario);
            let registration = test_scenario::take_from_sender<SuinsRegistration>(scenario);
            let ctx = test_scenario::ctx(scenario);

            // Create the auction
            auction::create_auction<SUI>(
                &mut auction_table,
                START_TIME,
                END_TIME,
                SUI_MIN_BID * mist_per_sui(),
                option::some(encrypted_object),
                registration,
                &clock,
                ctx
            );

            // Clean up
            test_scenario::return_shared(auction_table);
        };

        // seal_approve will error since auction has not ended yet
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let auction_table = test_scenario::take_shared<AuctionTable>(scenario);

            auction::seal_approve<SUI>(id, &auction_table, &clock);

            test_scenario::return_shared(auction_table);
        };

        abort
    }

    #[test, expected_failure(abort_code = auction::ETokenNotAllowed)]
    fun try_create_auction_not_allowed_token() {
        let (mut scenario_val, mut clock) = setup_test();
        let scenario = &mut scenario_val;

        generate_domain(scenario, DOMAIN_OWNER, FIRST_DOMAIN_NAME);

        // Increment the clock to the start time
        clock.increment_for_testing(START_TIME * MS);

        create_auction<TestCoin>(
            scenario,
            DOMAIN_OWNER,
            START_TIME,
            END_TIME + 300,
            SUI_MIN_BID,
            &clock,
        );

        abort
    }

    #[test, expected_failure(abort_code = auction::ENotOwner)]
    fun try_cancel_auction_not_owner() {
        let (mut scenario_val, mut clock) = setup_test();
        let scenario = &mut scenario_val;

        generate_domain(scenario, DOMAIN_OWNER, FIRST_DOMAIN_NAME);

        // Increment the clock to the start time
        clock.increment_for_testing(START_TIME * MS);

        create_auction<SUI>(
            scenario,
            DOMAIN_OWNER,
            START_TIME,
            END_TIME,
            SUI_MIN_BID,
            &clock,
        );

        test_scenario::next_tx(scenario, FIRST_ADDRESS);
        {
            let mut auction_table = test_scenario::take_shared<AuctionTable>(scenario);
            let ctx = test_scenario::ctx(scenario);
            let registration = auction::cancel_auction<SUI>(&mut auction_table,
                FIRST_DOMAIN_NAME.to_string(),
                &clock,
                ctx);
            test_scenario::return_to_address(FIRST_ADDRESS, registration);
            test_scenario::return_shared(auction_table);
        };

        abort
    }

    #[test, expected_failure(abort_code = auction::ETooEarly)]
    fun try_place_bid_too_early() {
        let (mut scenario_val, mut clock) = setup_test();
        let scenario = &mut scenario_val;

        generate_domain(scenario, DOMAIN_OWNER, FIRST_DOMAIN_NAME);

        create_auction<SUI>(
            scenario,
            DOMAIN_OWNER,
            START_TIME,
            END_TIME,
            SUI_MIN_BID,
            &clock,
        );

        // Increment the clock to auction active
        clock.increment_for_testing(TICK_INCREMENT);

        // First address places a bid
        place_bid<SUI>(scenario, FIRST_ADDRESS, FIRST_DOMAIN_NAME, SUI_FIRST_BID, &clock);

        abort
    }

    #[test, expected_failure(abort_code = auction::ETooLate)]
    fun try_place_bid_too_late() {
        let (mut scenario_val, mut clock) = setup_test();
        let scenario = &mut scenario_val;

        generate_domain(scenario, DOMAIN_OWNER, FIRST_DOMAIN_NAME);

        create_auction<SUI>(
            scenario,
            DOMAIN_OWNER,
            START_TIME,
            END_TIME,
            SUI_MIN_BID,
            &clock,
        );

        // Increment the clock to auction ended
        clock.increment_for_testing(END_TIME * MS + TICK_INCREMENT);

        // First address places a bid
        place_bid<SUI>(scenario, FIRST_ADDRESS, FIRST_DOMAIN_NAME, SUI_FIRST_BID, &clock);

        abort
    }

    #[test, expected_failure(abort_code = auction::EWrongTime)]
    fun try_create_auction_wrong_time() {
        let (mut scenario_val, clock) = setup_test();
        let scenario = &mut scenario_val;

        generate_domain(scenario, DOMAIN_OWNER, FIRST_DOMAIN_NAME);

        create_auction<SUI>(
            scenario,
            DOMAIN_OWNER,
            END_TIME,
            START_TIME,
            SUI_MIN_BID,
            &clock,
        );

        abort
    }

    #[test, expected_failure(abort_code = auction::ETooEarly)]
    fun try_create_auction_end_time_in_past() {
        let (mut scenario_val, mut clock) = setup_test();
        let scenario = &mut scenario_val;

        generate_domain(scenario, DOMAIN_OWNER, FIRST_DOMAIN_NAME);

        // Increment the clock to a point where end_time will be in the past
        clock.increment_for_testing(START_TIME * MS);

        create_auction<SUI>(
            scenario,
            DOMAIN_OWNER,
            START_TIME - 1,
            START_TIME, // end_time equals now
            SUI_MIN_BID,
            &clock,
        );

        abort
    }

    #[test, expected_failure(abort_code = auction::ETimeTooShort)]
    fun try_create_auction_duration_too_short() {
        let (mut scenario_val, clock) = setup_test();
        let scenario = &mut scenario_val;

        generate_domain(scenario, DOMAIN_OWNER, FIRST_DOMAIN_NAME);

        create_auction<SUI>(
            scenario,
            DOMAIN_OWNER,
            START_TIME,
            START_TIME + 3599, // Duration just under the 3600 minimum
            SUI_MIN_BID,
            &clock,
        );

        abort
    }

    #[test, expected_failure(abort_code = auction::ETimeTooLong)]
    fun try_create_auction_duration_too_long() {
        let (mut scenario_val, clock) = setup_test();
        let scenario = &mut scenario_val;

        generate_domain(scenario, DOMAIN_OWNER, FIRST_DOMAIN_NAME);

        create_auction<SUI>(
            scenario,
            DOMAIN_OWNER,
            START_TIME,
            START_TIME + 30 * 24 * 60 * 60  + 1, // Duration just over the 30 day maximum
            SUI_MIN_BID,
            &clock,
        );

        abort
    }

    #[test, expected_failure(abort_code = auction::EStartTooLate)]
    fun try_create_auction_start_too_late() {
        let (mut scenario_val, clock) = setup_test();
        let scenario = &mut scenario_val;

        generate_domain(scenario, DOMAIN_OWNER, FIRST_DOMAIN_NAME);

        create_auction<SUI>(
            scenario,
            DOMAIN_OWNER,
            30 * 24 * 60 * 60 + 1, // start_time is just over the 30 day maximum
            30 * 24 * 60 * 60 + 1 + 3600,
            SUI_MIN_BID,
            &clock,
        );

        abort
    }

    #[test, expected_failure(abort_code = auction::EDomainWillExpire)]
    fun try_create_auction_domain_will_expire() {
        let (mut scenario_val, mut clock) = setup_test();
        let scenario = &mut scenario_val;

        generate_domain(scenario, DOMAIN_OWNER, FIRST_DOMAIN_NAME);

        // Advance clock to near the domain expiration (1 year - 10000 seconds)
        // This leaves 10,000 seconds until domain expires
        let one_year_seconds = 365 * 24 * 60 * 60;
        let time_advance = one_year_seconds - 10000;
        clock.increment_for_testing(time_advance * MS);


        create_auction<SUI>(
            scenario,
            DOMAIN_OWNER,
            time_advance,
            time_advance + 7200, // domain expires with less than 1 hour time after auction ends
            SUI_MIN_BID,
            &clock,
        );

        abort
    }

    #[test, expected_failure(abort_code = auction::EBidTooLow)]
    fun try_place_bid_lower_than_minimum() {
        let (mut scenario_val, mut clock) = setup_test();
        let scenario = &mut scenario_val;

        generate_domain(scenario, DOMAIN_OWNER, FIRST_DOMAIN_NAME);

        // Increment the clock to the start time
        clock.increment_for_testing(START_TIME * MS);

        create_auction<SUI>(
            scenario,
            DOMAIN_OWNER,
            START_TIME,
            END_TIME,
            SUI_MIN_BID,
            &clock,
        );

        // Increment the clock to auction active
        clock.increment_for_testing(TICK_INCREMENT);

        // First address places a bid
        place_bid<SUI>(scenario, FIRST_ADDRESS, FIRST_DOMAIN_NAME, SUI_LOW_BID, &clock);

        abort
    }

    #[test, expected_failure(abort_code = auction::EBidTooLow)]
    fun try_place_bid_lower_than_previous() {
        let (mut scenario_val, mut clock) = setup_test();
        let scenario = &mut scenario_val;

        generate_domain(scenario, DOMAIN_OWNER, FIRST_DOMAIN_NAME);

        // Increment the clock to the start time
        clock.increment_for_testing(START_TIME * MS);

        create_auction<SUI>(
            scenario,
            DOMAIN_OWNER,
            START_TIME,
            END_TIME,
            SUI_MIN_BID,
            &clock,
        );

        // Increment the clock to auction active
        clock.increment_for_testing(TICK_INCREMENT);

        // First address places a bid
        place_bid<SUI>(scenario, FIRST_ADDRESS, FIRST_DOMAIN_NAME, SUI_SECOND_BID, &clock);

        // Second address places a bid
        place_bid<SUI>(scenario, SECOND_ADDRESS, FIRST_DOMAIN_NAME, SUI_FIRST_BID, &clock);

        abort
    }

    #[test, expected_failure(abort_code = auction::EBidTooLow)]
    fun try_place_bid_lower_than_min_bid_increase_percentage() {
        let (mut scenario_val, mut clock) = setup_test();
        let scenario = &mut scenario_val;

        generate_domain(scenario, DOMAIN_OWNER, FIRST_DOMAIN_NAME);

        // Increment the clock to the start time
        clock.increment_for_testing(START_TIME * MS);

        create_auction<SUI>(
            scenario,
            DOMAIN_OWNER,
            START_TIME,
            END_TIME,
            SUI_MIN_BID,
            &clock,
        );

        // Increment the clock to auction active
        clock.increment_for_testing(TICK_INCREMENT);

        // First address places a bid
        place_bid<SUI>(scenario, FIRST_ADDRESS, FIRST_DOMAIN_NAME, 200, &clock);

        // Second address places a bid that is not large enough (0.5% larger not 1% larger)
        place_bid<SUI>(scenario, SECOND_ADDRESS, FIRST_DOMAIN_NAME, 201, &clock);

        abort
    }

    #[test, expected_failure(abort_code = auction::ENotEnded)]
    fun try_finalize_auction_not_ended() {
        let (mut scenario_val, mut clock) = setup_test();
        let scenario = &mut scenario_val;

        generate_domain(scenario, DOMAIN_OWNER, FIRST_DOMAIN_NAME);

        // Increment the clock to the start time
        clock.increment_for_testing(START_TIME * MS);

        create_auction<SUI>(
            scenario,
            DOMAIN_OWNER,
            START_TIME,
            END_TIME,
            SUI_MIN_BID,
            &clock,
        );

        // Increment the clock to auction active
        clock.increment_for_testing(TICK_INCREMENT);

        // Finalize the auction
        finalize_auction<SUI>(scenario, FIRST_DOMAIN_NAME, &clock);

        abort
    }

    #[test]
    fun cancel_auction_successfully() {
        let (mut scenario_val, mut clock) = setup_test();
        let scenario = &mut scenario_val;

        generate_domain(scenario, DOMAIN_OWNER, FIRST_DOMAIN_NAME);

        // Increment the clock to the start time
        clock.increment_for_testing(START_TIME * MS);

        create_auction<SUI>(
            scenario,
            DOMAIN_OWNER,
            START_TIME,
            END_TIME,
            SUI_MIN_BID,
            &clock,
        );

        // Cancel the auction (no bids have been placed)
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let mut auction_table = test_scenario::take_shared<AuctionTable>(scenario);
            let ctx = test_scenario::ctx(scenario);
            let registration = auction::cancel_auction<SUI>(
                &mut auction_table,
                FIRST_DOMAIN_NAME.to_string(),
                &clock,
                ctx
            );
            transfer::public_transfer(registration, DOMAIN_OWNER);
            test_scenario::return_shared(auction_table);
        };

        // Verify auction is removed and owner has the domain back
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let auction_table = test_scenario::take_shared<AuctionTable>(scenario);
            let table = auction::get_auction_table_bag(&auction_table);
            assert!(table.length() == 0, 0);
            test_scenario::return_shared(auction_table);

            let registration = test_scenario::take_from_address<SuinsRegistration>(scenario, DOMAIN_OWNER);
            assert!(registration.domain() == domain::new(FIRST_DOMAIN_NAME.to_string()), 0);
            test_scenario::return_to_address(DOMAIN_OWNER, registration);
        };

        // Final cleanup
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EEnded)]
    fun try_cancel_ended_auction() {
        let (mut scenario_val, mut clock) = setup_test();
        let scenario = &mut scenario_val;
        
        generate_domain(scenario, DOMAIN_OWNER, FIRST_DOMAIN_NAME);

        // Increment the clock to the start time
        clock.increment_for_testing(START_TIME * MS);

        create_auction<SUI>(
            scenario,
            DOMAIN_OWNER,
            START_TIME,
            END_TIME,
            SUI_MIN_BID,
            &clock,
        );

        // Increment the clock to auction ended
        clock.increment_for_testing(END_TIME * MS + TICK_INCREMENT);

        // Tx to check auction and accounts state
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let mut auction_table = test_scenario::take_shared<AuctionTable>(scenario);
            let ctx = test_scenario::ctx(scenario);
            let registration = auction::cancel_auction<SUI>(&mut auction_table,
                FIRST_DOMAIN_NAME.to_string(),
                &clock,
                ctx);
            test_scenario::return_to_address(FIRST_ADDRESS, registration);
            test_scenario::return_shared(auction_table);
        };

        abort
    }

    #[test, expected_failure(abort_code = auction::EAlreadyHasBid)]
    fun try_cancel_auction_with_bid() {
        let (mut scenario_val, mut clock) = setup_test();
        let scenario = &mut scenario_val;

        generate_domain(scenario, DOMAIN_OWNER, FIRST_DOMAIN_NAME);

        // Increment the clock to the start time
        clock.increment_for_testing(START_TIME * MS);

        create_auction<SUI>(
            scenario,
            DOMAIN_OWNER,
            START_TIME,
            END_TIME,
            SUI_MIN_BID,
            &clock,
        );

        // Increment the clock to auction active
        clock.increment_for_testing(TICK_INCREMENT);

        // First address places a bid
        place_bid<SUI>(scenario, FIRST_ADDRESS, FIRST_DOMAIN_NAME, SUI_FIRST_BID, &clock);

        // Try to cancel the auction (should fail because there's a bid)
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let mut auction_table = test_scenario::take_shared<AuctionTable>(scenario);
            let ctx = test_scenario::ctx(scenario);
            let registration = auction::cancel_auction<SUI>(
                &mut auction_table,
                FIRST_DOMAIN_NAME.to_string(),
                &clock,
                ctx
            );
            transfer::public_transfer(registration, DOMAIN_OWNER);
            test_scenario::return_shared(auction_table);
        };

        abort
    }

    #[test, expected_failure(abort_code = auction::ENotAuctioned)]
    fun try_place_bid_not_auctioned_domain() {
        let (mut scenario_val, mut clock) = setup_test();
        let scenario = &mut scenario_val;

        
        generate_domain(scenario, DOMAIN_OWNER, FIRST_DOMAIN_NAME);

        // Increment the clock to the start time
        clock.increment_for_testing(START_TIME * MS);

        create_auction<SUI>(
            scenario,
            DOMAIN_OWNER,
            START_TIME,
            END_TIME,
            SUI_MIN_BID,
            &clock,
        );

        // Increment the clock to auction active
        clock.increment_for_testing(TICK_INCREMENT);

        // First address places a bid
        place_bid<SUI>(scenario, FIRST_ADDRESS, SECOND_DOMAIN_NAME, SUI_SECOND_BID, &clock);

        abort
    }

    #[test]
    fun place_offer_and_accept_scenario_sui_test() {
        let (mut scenario_val, clock) = setup_test();
        let scenario = &mut scenario_val;

        generate_domain(scenario, DOMAIN_OWNER, FIRST_DOMAIN_NAME);

        // Place an offer
        test_scenario::next_tx(scenario, FIRST_ADDRESS);
        {
            let mut offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let ctx = test_scenario::ctx(scenario);

            // Create test SUI coins for the offer
            let payment = coin::mint_for_testing<SUI>(SUI_FIRST_BID * mist_per_sui(), ctx);

            // Place the offer
            offer::place_offer(
                &mut offer_table,
                FIRST_DOMAIN_NAME.to_string(),
                payment,
                option::none(), &clock, ctx
            );

            // Clean up
            test_scenario::return_shared(offer_table);
        };

        // Verify the offer was placed correctly
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let table = offer::get_offer_table(&offer_table);
            let offers = table.borrow(FIRST_DOMAIN_NAME);
            assert!(offers.contains(FIRST_ADDRESS), 0);
            let offer = offers.borrow(FIRST_ADDRESS);
            assert!(offer::get_offer_balance(offer).value() == SUI_FIRST_BID * mist_per_sui(), 0);
            assert!(offer::get_offer_counter_offer<SUI>(offer) == 0, 0);
            test_scenario::return_shared(offer_table);
        };

        // Accept the offer
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let mut offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let mut suins = scenario.take_shared<SuiNS>();
            let registration = test_scenario::take_from_sender<SuinsRegistration>(scenario);
            let ctx = test_scenario::ctx(scenario);

            // Accept the offer
            let payment = offer::accept_offer<SUI>(
                &mut suins,
                &mut offer_table,
                registration,
                FIRST_ADDRESS,
                &clock,
                ctx
            );

            // Verify payment amount
            assert!(coin::value(&payment) == SUI_FIRST_BID * mist_per_sui() * 97_500 / 100_000, 0); // substract 2.5% service fee
            coin::burn_for_testing(payment);

            // Verify service fee was collected
            let fees = offer::get_offer_table_fees(&offer_table);
            let sui_type_name = type_name::with_defining_ids<SUI>();
            let fee_balance = fees.borrow<TypeName, Balance<SUI>>(sui_type_name);
            assert!(fee_balance.value() == SUI_FIRST_BID * mist_per_sui() * 2_500 / 100_000, 0);

            // Clean up
            test_scenario::return_shared(offer_table);
            test_scenario::return_shared(suins);
        };

        // Final cleanup
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario_val);
    }

    #[test]
    fun place_offer_and_accept_scenario_other_test() {
        let (mut scenario_val, clock) = setup_test();
        let scenario = &mut scenario_val;

        generate_domain(scenario, DOMAIN_OWNER, FIRST_DOMAIN_NAME);

        // Allow token
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
            let mut auction_table = test_scenario::take_shared<AuctionTable>(scenario);
            let mut offer_table = test_scenario::take_shared<OfferTable>(scenario);

            auction::add_allowed_token<TestCoin>(&admin_cap, &mut auction_table, &mut offer_table);

            transfer::public_transfer(admin_cap, DOMAIN_OWNER);
            test_scenario::return_shared(auction_table);
            test_scenario::return_shared(offer_table);
        };

        // Place an offer
        test_scenario::next_tx(scenario, FIRST_ADDRESS);
        {
            let mut offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let ctx = test_scenario::ctx(scenario);

            // Create test SUI coins for the offer
            let payment = coin::mint_for_testing<TestCoin>(SUI_FIRST_BID * mist_per_sui(), ctx);

            // Place the offer
            offer::place_offer(
                &mut offer_table,
                FIRST_DOMAIN_NAME.to_string(),
                payment,
                option::none(), &clock, ctx
            );

            // Clean up
            test_scenario::return_shared(offer_table);
        };

        // Disallow the token, other operations still work
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
            let mut auction_table = test_scenario::take_shared<AuctionTable>(scenario);
            let mut offer_table = test_scenario::take_shared<OfferTable>(scenario);

            auction::remove_allowed_token<TestCoin>(&admin_cap, &mut auction_table, &mut offer_table);

            transfer::public_transfer(admin_cap, DOMAIN_OWNER);
            test_scenario::return_shared(auction_table);
            test_scenario::return_shared(offer_table);
        };

        // Verify the offer was placed correctly
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let table = offer::get_offer_table(&offer_table);
            let offers = table.borrow(FIRST_DOMAIN_NAME);
            assert!(offers.contains(FIRST_ADDRESS), 0);
            let offer = offers.borrow(FIRST_ADDRESS);
            assert!(offer::get_offer_balance(offer).value() == SUI_FIRST_BID * mist_per_sui(), 0);
            assert!(offer::get_offer_counter_offer<TestCoin>(offer) == 0, 0);
            test_scenario::return_shared(offer_table);
        };

        // Accept the offer
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let mut offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let mut suins = scenario.take_shared<SuiNS>();
            let registration = test_scenario::take_from_sender<SuinsRegistration>(scenario);
            let ctx = test_scenario::ctx(scenario);

            // Accept the offer
            let payment = offer::accept_offer<TestCoin>(
                &mut suins,
                &mut offer_table,
                registration,
                FIRST_ADDRESS,
                &clock,
                ctx
            );

            // Verify payment amount
            assert!(coin::value(&payment) == SUI_FIRST_BID * mist_per_sui() * 97_500 / 100_000, 0); // substract 2.5% service fee
            coin::burn_for_testing(payment);

            // Verify service fee was collected
            let fees = offer::get_offer_table_fees(&offer_table);
            let sui_type_name = type_name::with_defining_ids<TestCoin>();
            let fee_balance = fees.borrow<TypeName, Balance<TestCoin>>(sui_type_name);
            assert!(fee_balance.value() == SUI_FIRST_BID * mist_per_sui() * 2_500 / 100_000, 0);

            // Clean up
            test_scenario::return_shared(offer_table);
            test_scenario::return_shared(suins);
        };


        // Final cleanup
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario_val);
    }

    #[test]
    fun place_offer_and_accept_before_expires_at_scenario_sui_test() {
        let (mut scenario_val, mut clock) = setup_test();
        let scenario = &mut scenario_val;

        clock.increment_for_testing(1 * MS);

        generate_domain(scenario, DOMAIN_OWNER, FIRST_DOMAIN_NAME);

        // Place an offer
        test_scenario::next_tx(scenario, FIRST_ADDRESS);
        {
            let mut offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let ctx = test_scenario::ctx(scenario);

            // Create test SUI coins for the offer
            let payment = coin::mint_for_testing<SUI>(SUI_FIRST_BID * mist_per_sui(), ctx);

            // Place the offer
            offer::place_offer(
                &mut offer_table,
                FIRST_DOMAIN_NAME.to_string(),
                payment,
                option::some(123),
                &clock,
                ctx
            );

            // Clean up
            test_scenario::return_shared(offer_table);
        };

        // Verify the offer was placed correctly
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let table = offer::get_offer_table(&offer_table);
            let offers = table.borrow(FIRST_DOMAIN_NAME);
            assert!(offers.contains(FIRST_ADDRESS), 0);
            let offer = offers.borrow(FIRST_ADDRESS);
            assert!(offer::get_offer_expires_at(offer) == &option::some(123), 0);
            assert!(offer::get_offer_balance(offer).value() == SUI_FIRST_BID * mist_per_sui(), 0);
            assert!(offer::get_offer_counter_offer<SUI>(offer) == 0, 0);
            test_scenario::return_shared(offer_table);
        };

        // Accept the offer
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let mut offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let mut suins = scenario.take_shared<SuiNS>();
            let registration = test_scenario::take_from_sender<SuinsRegistration>(scenario);
            let ctx = test_scenario::ctx(scenario);

            // Accept the offer
            let payment = offer::accept_offer<SUI>(
                &mut suins,
                &mut offer_table,
                registration,
                FIRST_ADDRESS,
                &clock,
                ctx
            );

            // Verify payment amount
            assert!(coin::value(&payment) == SUI_FIRST_BID * mist_per_sui() * 97_500 / 100_000, 0); // substract 2.5% service fee
            coin::burn_for_testing(payment);

            // Verify service fee was collected
            let fees = offer::get_offer_table_fees(&offer_table);
            let sui_type_name = type_name::with_defining_ids<SUI>();
            let fee_balance = fees.borrow<TypeName, Balance<SUI>>(sui_type_name);
            assert!(fee_balance.value() == SUI_FIRST_BID * mist_per_sui() * 2_500 / 100_000, 0);

            // Clean up
            test_scenario::return_shared(offer_table);
            test_scenario::return_shared(suins);
        };

        // Final cleanup
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = offer::EInvalidExpiresAt)]
    fun try_place_offer_after_expires_at() {
        let (mut scenario_val, mut clock) = setup_test();
        let scenario = &mut scenario_val;

        clock.increment_for_testing(1 * MS);

        generate_domain(scenario, DOMAIN_OWNER, FIRST_DOMAIN_NAME);

        // Place an offer
        test_scenario::next_tx(scenario, FIRST_ADDRESS);
        {
            let mut offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let ctx = test_scenario::ctx(scenario);

            // Create test SUI coins for the offer
            let payment = coin::mint_for_testing<SUI>(SUI_FIRST_BID * mist_per_sui(), ctx);

            // Place the offer
            offer::place_offer(
                &mut offer_table,
                FIRST_DOMAIN_NAME.to_string(),
                payment,
                option::some(1),
                &clock,
                ctx
            );

            // Clean up
            test_scenario::return_shared(offer_table);
        };

        abort
    }

    #[test, expected_failure(abort_code = offer::EOfferExpired)]
    fun try_accept_offer_after_expires_at() {
        let (mut scenario_val, mut clock) = setup_test();
        let scenario = &mut scenario_val;

        clock.increment_for_testing(1 * MS);

        generate_domain(scenario, DOMAIN_OWNER, FIRST_DOMAIN_NAME);

        // Place an offer
        test_scenario::next_tx(scenario, FIRST_ADDRESS);
        {
            let mut offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let ctx = test_scenario::ctx(scenario);

            // Create test SUI coins for the offer
            let payment = coin::mint_for_testing<SUI>(SUI_FIRST_BID * mist_per_sui(), ctx);

            // Place the offer
            offer::place_offer(
                &mut offer_table,
                FIRST_DOMAIN_NAME.to_string(),
                payment,
                option::some(123),
                &clock,
                ctx
            );

            // Clean up
            test_scenario::return_shared(offer_table);
        };

        clock.increment_for_testing(124 * MS);

        // Accept the offer
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let mut offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let mut suins = scenario.take_shared<SuiNS>();
            let registration = test_scenario::take_from_sender<SuinsRegistration>(scenario);
            let ctx = test_scenario::ctx(scenario);

            // Accept the offer
            let payment = offer::accept_offer<SUI>(
                &mut suins,
                &mut offer_table,
                registration,
                FIRST_ADDRESS,
                &clock,
                ctx
            );

            // Verify payment amount
            assert!(coin::value(&payment) == SUI_FIRST_BID * mist_per_sui() * 97_500 / 100_000, 0); // substract 2.5% service fee
            coin::burn_for_testing(payment);

            // Verify service fee was collected
            let fees = offer::get_offer_table_fees(&offer_table);
            let sui_type_name = type_name::with_defining_ids<SUI>();
            let fee_balance = fees.borrow<TypeName, Balance<SUI>>(sui_type_name);
            assert!(fee_balance.value() == SUI_FIRST_BID * mist_per_sui() * 2_500 / 100_000, 0);

            // Clean up
            test_scenario::return_shared(offer_table);
            test_scenario::return_shared(suins);
        };

        abort
    }

    #[test, expected_failure(abort_code = offer::ETokenNotAllowed)]
    fun try_place_offer_not_allowed_token() {
        let (mut scenario_val, clock) = setup_test();
        let scenario = &mut scenario_val;

        generate_domain(scenario, DOMAIN_OWNER, FIRST_DOMAIN_NAME);

        // Place an offer
        test_scenario::next_tx(scenario, FIRST_ADDRESS);
        {
            let mut offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let ctx = test_scenario::ctx(scenario);

            // Create test SUI coins for the offer
            let payment = coin::mint_for_testing<TestCoin>(SUI_FIRST_BID * mist_per_sui(), ctx);

            // Place the offer
            offer::place_offer(
                &mut offer_table,
                FIRST_DOMAIN_NAME.to_string(),
                payment,
                option::none(), &clock, ctx
            );

            // Clean up
            test_scenario::return_shared(offer_table);
        };

        abort
    }

    #[test]
    fun place_offer_counteroffer_and_accept_scenario_test() {
        let (mut scenario_val, clock) = setup_test();
        let scenario = &mut scenario_val;

        generate_domain(scenario, DOMAIN_OWNER, FIRST_DOMAIN_NAME);

        // Place an offer
        test_scenario::next_tx(scenario, FIRST_ADDRESS);
        {
            let mut offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let ctx = test_scenario::ctx(scenario);

            // Create test SUI coins for the offer
            let payment = coin::mint_for_testing<SUI>(SUI_FIRST_BID * mist_per_sui(), ctx);

            // Place the offer
            offer::place_offer(
                &mut offer_table,
                FIRST_DOMAIN_NAME.to_string(),
                payment,
                option::none(), &clock, ctx
            );

            // Clean up
            test_scenario::return_shared(offer_table);
        };

        // Verify the offer was placed correctly
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let table = offer::get_offer_table(&offer_table);
            let offers = table.borrow(FIRST_DOMAIN_NAME);
            assert!(offers.contains(FIRST_ADDRESS), 0);
            let offer = offers.borrow(FIRST_ADDRESS);
            assert!(offer::get_offer_balance(offer).value() == SUI_FIRST_BID * mist_per_sui(), 0);
            assert!(offer::get_offer_counter_offer<SUI>(offer) == 0, 0);
            test_scenario::return_shared(offer_table);
        };

        // Make a counter offer
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let mut offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let registration = test_scenario::take_from_sender<SuinsRegistration>(scenario);
            let ctx = test_scenario::ctx(scenario);

            // Make counter offer
            offer::make_counter_offer<SUI>(
                &mut offer_table,
                &registration,
                FIRST_ADDRESS,
                SUI_SECOND_BID * mist_per_sui(),
                ctx
            );

            // Return objects
            test_scenario::return_to_sender(scenario, registration);
            test_scenario::return_shared(offer_table);
        };

        // Verify counter offer
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let table = offer::get_offer_table(&offer_table);
            assert!(table.length() == 1);
            let offers = table.borrow(FIRST_DOMAIN_NAME);
            let offer = offers.borrow(FIRST_ADDRESS);
            assert!(offer::get_offer_counter_offer<SUI>(offer) == SUI_SECOND_BID * mist_per_sui(), 0);
            test_scenario::return_shared(offer_table);
        };

        // Accept counter offer
        test_scenario::next_tx(scenario, FIRST_ADDRESS);
        {
            let mut offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let ctx = test_scenario::ctx(scenario);

            // Create additional payment for counter offer
            let additional_payment = coin::mint_for_testing<SUI>(
                (SUI_SECOND_BID - SUI_FIRST_BID) * mist_per_sui(),
                ctx
            );

            // Accept counter offer
            offer::accept_counter_offer(
                &mut offer_table,
                FIRST_DOMAIN_NAME.to_string(),
                additional_payment,
                ctx
            );

            // Clean up
            test_scenario::return_shared(offer_table);
        };

        // Accept the offer
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let mut offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let mut suins = scenario.take_shared<SuiNS>();
            let registration = test_scenario::take_from_sender<SuinsRegistration>(scenario);
            let ctx = test_scenario::ctx(scenario);

            // Accept the offer
            let payment = offer::accept_offer<SUI>(
                &mut suins,
                &mut offer_table,
                registration,
                FIRST_ADDRESS,
                &clock,
                ctx
            );

            // Verify payment amount
            assert!(coin::value(&payment) == SUI_SECOND_BID * mist_per_sui() * 97_500 / 100_000, 0); // substract 2.5% service fee
            coin::burn_for_testing(payment);

            // Verify service fee was collected
            let fees = offer::get_offer_table_fees(&offer_table);
            let sui_type_name = type_name::with_defining_ids<SUI>();
            let fee_balance = fees.borrow<TypeName, Balance<SUI>>(sui_type_name);
            assert!(fee_balance.value() == SUI_SECOND_BID * mist_per_sui() * 2_500 / 100_000, 0);

            // Clean up
            test_scenario::return_shared(offer_table);
            test_scenario::return_shared(suins);
        };

        // Tx to check offers and accounts state
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let table = offer::get_offer_table(&offer_table);
            assert!(table.length() == 0, 0);
            test_scenario::return_shared(offer_table);
        };

        // Verify domain ownership transferred
        test_scenario::next_tx(scenario, FIRST_ADDRESS);
        {
            let registration = test_scenario::take_from_sender<SuinsRegistration>(scenario);
            assert!(registration.domain() == domain::new(FIRST_DOMAIN_NAME.to_string()), 0);
            registration.burn_for_testing();
        };

        // Final cleanup
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario_val);
    }

    #[test]
    fun place_offer_and_cancel_scenario_test() {
        let (mut scenario_val, clock) = setup_test();
        let scenario = &mut scenario_val;

        // Place an offer
        test_scenario::next_tx(scenario, FIRST_ADDRESS);
        {
            let mut offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let ctx = test_scenario::ctx(scenario);

            // Create test SUI coins for the offer
            let payment = coin::mint_for_testing<SUI>(SUI_FIRST_BID * mist_per_sui(), ctx);

            // Place the offer
            offer::place_offer(
                &mut offer_table,
                FIRST_DOMAIN_NAME.to_string(),
                payment,
                option::none(), &clock, ctx
            );

            // Clean up
            test_scenario::return_shared(offer_table);
        };

        // Place another offer
        test_scenario::next_tx(scenario, SECOND_ADDRESS);
        {
            let mut offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let ctx = test_scenario::ctx(scenario);

            // Create test SUI coins for the offer
            let payment = coin::mint_for_testing<SUI>(SUI_SECOND_BID * mist_per_sui(), ctx);

            // Place the offer
            offer::place_offer(
                &mut offer_table,
                SECOND_DOMAIN_NAME.to_string(),
                payment,
                option::none(), &clock, ctx
            );

            // Clean up
            test_scenario::return_shared(offer_table);
        };

        // Verify the offers were placed correctly
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let table = offer::get_offer_table(&offer_table);
            assert!(table.length() == 2);
            let offers = table.borrow(FIRST_DOMAIN_NAME);
            assert!(offers.contains(FIRST_ADDRESS), 0);
            let offer = offers.borrow(FIRST_ADDRESS);
            assert!(offer::get_offer_balance(offer).value() == SUI_FIRST_BID * mist_per_sui(), 0);
            assert!(offer::get_offer_counter_offer<SUI>(offer) == 0, 0);
            let offers = table.borrow(SECOND_DOMAIN_NAME);
            assert!(offers.contains(SECOND_ADDRESS), 0);
            let offer = offers.borrow(SECOND_ADDRESS);
            assert!(offer::get_offer_balance(offer).value() == SUI_SECOND_BID * mist_per_sui(), 0);
            assert!(offer::get_offer_counter_offer<SUI>(offer) == 0, 0);
            test_scenario::return_shared(offer_table);
        };

        // Cancel the offer
        test_scenario::next_tx(scenario, FIRST_ADDRESS);
        {
            let mut offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let ctx = test_scenario::ctx(scenario);

            // Cancel the offer
            let payment = offer::cancel_offer<SUI>(
                &mut offer_table,
                FIRST_DOMAIN_NAME.to_string(),
                ctx
            );

            // Verify payment amount
            assert!(coin::value(&payment) == SUI_FIRST_BID * mist_per_sui(), 0);
            coin::burn_for_testing(payment);

            // Clean up
            test_scenario::return_shared(offer_table);
        };

        // Verify first offer was removed
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let table = offer::get_offer_table(&offer_table);
            assert!(table.length() == 1, 0);
            let offers = table.borrow(SECOND_DOMAIN_NAME);
            assert!(offers.contains(SECOND_ADDRESS), 0);
            let offer = offers.borrow(SECOND_ADDRESS);
            assert!(offer::get_offer_balance(offer).value() == SUI_SECOND_BID * mist_per_sui(), 0);
            assert!(offer::get_offer_counter_offer<SUI>(offer) == 0, 0);
            test_scenario::return_shared(offer_table);
        };

        // Final cleanup
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario_val);
    }

    #[test]
    fun place_offer_and_decline_scenario_test() {
        let (mut scenario_val, clock) = setup_test();
        let scenario = &mut scenario_val;

        generate_domain(scenario, DOMAIN_OWNER, FIRST_DOMAIN_NAME);

        // Place an offer
        test_scenario::next_tx(scenario, FIRST_ADDRESS);
        {
            let mut offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let ctx = test_scenario::ctx(scenario);

            // Create test SUI coins for the offer
            let payment = coin::mint_for_testing<SUI>(SUI_FIRST_BID * mist_per_sui(), ctx);

            // Place the offer
            offer::place_offer(
                &mut offer_table,
                FIRST_DOMAIN_NAME.to_string(),
                payment,
                option::none(), &clock, ctx
            );

            // Clean up
            test_scenario::return_shared(offer_table);
        };

        // Place another offer on same domain
        test_scenario::next_tx(scenario, SECOND_ADDRESS);
        {
            let mut offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let ctx = test_scenario::ctx(scenario);

            // Create test SUI coins for the offer
            let payment = coin::mint_for_testing<SUI>(SUI_SECOND_BID * mist_per_sui(), ctx);

            // Place the offer
            offer::place_offer(
                &mut offer_table,
                FIRST_DOMAIN_NAME.to_string(),
                payment,
                option::none(), &clock, ctx
            );

            // Clean up
            test_scenario::return_shared(offer_table);
        };

        // Verify the offers were placed correctly
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let table = offer::get_offer_table(&offer_table);
            assert!(table.length() == 1);
            let offers = table.borrow(FIRST_DOMAIN_NAME);
            assert!(offers.contains(FIRST_ADDRESS), 0);
            let offer = offers.borrow(FIRST_ADDRESS);
            assert!(offer::get_offer_balance(offer).value() == SUI_FIRST_BID * mist_per_sui(), 0);
            assert!(offer::get_offer_counter_offer<SUI>(offer) == 0, 0);
            assert!(offers.contains(SECOND_ADDRESS), 0);
            let offer = offers.borrow(SECOND_ADDRESS);
            assert!(offer::get_offer_balance(offer).value() == SUI_SECOND_BID * mist_per_sui(), 0);
            assert!(offer::get_offer_counter_offer<SUI>(offer) == 0, 0);
            test_scenario::return_shared(offer_table);
        };

        // Decline the second offer
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let mut offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let registration = test_scenario::take_from_sender<SuinsRegistration>(scenario);
            let ctx = test_scenario::ctx(scenario);

            // Decline the offer
            offer::decline_offer<SUI>(
                &mut offer_table,
                &registration,
                SECOND_ADDRESS,
                ctx
            );

            // Return objects
            test_scenario::return_to_sender(scenario, registration);
            test_scenario::return_shared(offer_table);
        };

        // Verify second offer was removed
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let table = offer::get_offer_table(&offer_table);
            assert!(table.length() == 1, 0);
            let offers = table.borrow(FIRST_DOMAIN_NAME);
            assert!(offers.contains(FIRST_ADDRESS), 0);
            let offer = offers.borrow(FIRST_ADDRESS);
            assert!(offer::get_offer_balance(offer).value() == SUI_FIRST_BID * mist_per_sui(), 0);
            assert!(offer::get_offer_counter_offer<SUI>(offer) == 0, 0);
            test_scenario::return_shared(offer_table);
        };

        // Verify second address got their payment back
        test_scenario::next_tx(scenario, SECOND_ADDRESS);
        {
            let payment = test_scenario::take_from_sender<Coin<SUI>>(scenario);
            assert!(coin::value(&payment) == SUI_SECOND_BID * mist_per_sui(), 0);
            coin::burn_for_testing(payment);
        };

        // Final cleanup
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = offer::EAlreadyOffered)]
    fun try_place_offer_aleady_offered() {
        let (mut scenario_val, clock) = setup_test();
        let scenario = &mut scenario_val;

        // Place an offer
        test_scenario::next_tx(scenario, FIRST_ADDRESS);
        {
            let mut offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let ctx = test_scenario::ctx(scenario);

            // Create test SUI coins for the offer
            let payment = coin::mint_for_testing<SUI>(SUI_FIRST_BID * mist_per_sui(), ctx);

            // Place the offer
            offer::place_offer(
                &mut offer_table,
                FIRST_DOMAIN_NAME.to_string(),
                payment,
                option::none(), &clock, ctx
            );

            // Clean up
            test_scenario::return_shared(offer_table);
        };

        // Try to place an offer
        test_scenario::next_tx(scenario, FIRST_ADDRESS);
        {
            let mut offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let ctx = test_scenario::ctx(scenario);

            // Create test SUI coins for the offer
            let payment = coin::mint_for_testing<SUI>(SUI_SECOND_BID * mist_per_sui(), ctx);

            // Place the offer
            offer::place_offer(
                &mut offer_table,
                FIRST_DOMAIN_NAME.to_string(),
                payment,
                option::none(), &clock, ctx
            );

            // Clean up
            test_scenario::return_shared(offer_table);
        };

        abort
    }

    #[test, expected_failure(abort_code = offer::ECounterOfferTooLow)]
    fun try_make_too_low_counteroffer() {
        let (mut scenario_val, clock) = setup_test();
        let scenario = &mut scenario_val;

        generate_domain(scenario, DOMAIN_OWNER, FIRST_DOMAIN_NAME);

        // Place an offer
        test_scenario::next_tx(scenario, FIRST_ADDRESS);
        {
            let mut offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let ctx = test_scenario::ctx(scenario);

            // Create test SUI coins for the offer
            let payment = coin::mint_for_testing<SUI>(SUI_FIRST_BID * mist_per_sui(), ctx);

            // Place the offer
            offer::place_offer(
                &mut offer_table,
                FIRST_DOMAIN_NAME.to_string(),
                payment,
                option::none(), &clock, ctx
            );

            // Clean up
            test_scenario::return_shared(offer_table);
        };

        // Make a counter offer
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let mut offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let registration = test_scenario::take_from_sender<SuinsRegistration>(scenario);
            let ctx = test_scenario::ctx(scenario);

            // Make counter offer
            offer::make_counter_offer<SUI>(
                &mut offer_table,
                &registration,
                FIRST_ADDRESS,
                SUI_LOW_BID * mist_per_sui(),
                ctx
            );

            // Return objects
            test_scenario::return_to_sender(scenario, registration);
            test_scenario::return_shared(offer_table);
        };

        abort
    }

    #[test, expected_failure(abort_code = offer::ENoCounterOffer)]
    fun try_accept_non_existent_counteroffer() {
        let (mut scenario_val, clock) = setup_test();
        let scenario = &mut scenario_val;

        // Place an offer
        test_scenario::next_tx(scenario, FIRST_ADDRESS);
        {
            let mut offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let ctx = test_scenario::ctx(scenario);

            // Create test SUI coins for the offer
            let payment = coin::mint_for_testing<SUI>(SUI_FIRST_BID * mist_per_sui(), ctx);

            // Place the offer
            offer::place_offer(
                &mut offer_table,
                FIRST_DOMAIN_NAME.to_string(),
                payment,
                option::none(), &clock, ctx
            );

            // Clean up
            test_scenario::return_shared(offer_table);
        };

        // Accept non existent counter offer
        test_scenario::next_tx(scenario, FIRST_ADDRESS);
        {
            let mut offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let ctx = test_scenario::ctx(scenario);

            // Create additional payment for counter offer
            let additional_payment = coin::mint_for_testing<SUI>(
                (SUI_SECOND_BID - SUI_FIRST_BID) * mist_per_sui(),
                ctx
            );

            // Accept counter offer
            offer::accept_counter_offer(
                &mut offer_table,
                FIRST_DOMAIN_NAME.to_string(),
                additional_payment,
                ctx
            );

            // Clean up
            test_scenario::return_shared(offer_table);
        };

        abort
    }

    #[test, expected_failure(abort_code = offer::EWrongCoinValue)]
    fun try_accept_counteroffer_wrong_payment() {
        let (mut scenario_val, clock) = setup_test();
        let scenario = &mut scenario_val;

        generate_domain(scenario, DOMAIN_OWNER, FIRST_DOMAIN_NAME);

        // Place an offer
        test_scenario::next_tx(scenario, FIRST_ADDRESS);
        {
            let mut offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let ctx = test_scenario::ctx(scenario);

            // Create test SUI coins for the offer
            let payment = coin::mint_for_testing<SUI>(SUI_FIRST_BID * mist_per_sui(), ctx);

            // Place the offer
            offer::place_offer(
                &mut offer_table,
                FIRST_DOMAIN_NAME.to_string(),
                payment,
                option::none(), &clock, ctx
            );

            // Clean up
            test_scenario::return_shared(offer_table);
        };

        // Make a counter offer
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let mut offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let registration = test_scenario::take_from_sender<SuinsRegistration>(scenario);
            let ctx = test_scenario::ctx(scenario);

            // Make counter offer
            offer::make_counter_offer<SUI>(
                &mut offer_table,
                &registration,
                FIRST_ADDRESS,
                SUI_SECOND_BID * mist_per_sui(),
                ctx
            );

            // Return objects
            test_scenario::return_to_sender(scenario, registration);
            test_scenario::return_shared(offer_table);
        };

        // Accept counter offer
        test_scenario::next_tx(scenario, FIRST_ADDRESS);
        {
            let mut offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let ctx = test_scenario::ctx(scenario);

            // Create additional payment for counter offer
            let additional_payment = coin::mint_for_testing<SUI>(
                (SUI_SECOND_BID - SUI_LOW_BID) * mist_per_sui(),
                ctx
            );

            // Accept counter offer
            offer::accept_counter_offer(
                &mut offer_table,
                FIRST_DOMAIN_NAME.to_string(),
                additional_payment,
                ctx
            );

            // Clean up
            test_scenario::return_shared(offer_table);
        };

        abort
    }

    #[test, expected_failure(abort_code = offer::EDomainNotOffered)]
    fun try_make_counteroffer_on_non_existent_offer() {
        let (mut scenario_val, _clock) = setup_test();
        let scenario = &mut scenario_val;

        generate_domain(scenario, DOMAIN_OWNER, FIRST_DOMAIN_NAME);

        // Make a counter offer
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let mut offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let registration = test_scenario::take_from_sender<SuinsRegistration>(scenario);
            let ctx = test_scenario::ctx(scenario);

            // Make counter offer
            offer::make_counter_offer<SUI>(
                &mut offer_table,
                &registration,
                FIRST_ADDRESS,
                SUI_SECOND_BID * mist_per_sui(),
                ctx
            );

            // Return objects
            test_scenario::return_to_sender(scenario, registration);
            test_scenario::return_shared(offer_table);
        };

        abort
    }

    #[test, expected_failure(abort_code = offer::EAddressNotOffered)]
    fun try_accept_counteroffer_wrong_caller() {
        let (mut scenario_val, clock) = setup_test();
        let scenario = &mut scenario_val;

        generate_domain(scenario, DOMAIN_OWNER, FIRST_DOMAIN_NAME);

        // Place an offer
        test_scenario::next_tx(scenario, FIRST_ADDRESS);
        {
            let mut offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let ctx = test_scenario::ctx(scenario);

            // Create test SUI coins for the offer
            let payment = coin::mint_for_testing<SUI>(SUI_FIRST_BID * mist_per_sui(), ctx);

            // Place the offer
            offer::place_offer(
                &mut offer_table,
                FIRST_DOMAIN_NAME.to_string(),
                payment,
                option::none(), &clock, ctx
            );

            // Clean up
            test_scenario::return_shared(offer_table);
        };

        // Make a counter offer
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let mut offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let registration = test_scenario::take_from_sender<SuinsRegistration>(scenario);
            let ctx = test_scenario::ctx(scenario);

            // Make counter offer
            offer::make_counter_offer<SUI>(
                &mut offer_table,
                &registration,
                FIRST_ADDRESS,
                SUI_SECOND_BID * mist_per_sui(),
                ctx
            );

            // Return objects
            test_scenario::return_to_sender(scenario, registration);
            test_scenario::return_shared(offer_table);
        };

        // Accept counter offer
        test_scenario::next_tx(scenario, SECOND_ADDRESS);
        {
            let mut offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let ctx = test_scenario::ctx(scenario);

            // Create additional payment for counter offer
            let additional_payment = coin::mint_for_testing<SUI>(
                (SUI_SECOND_BID - SUI_FIRST_BID) * mist_per_sui(),
                ctx
            );

            // Accept counter offer
            offer::accept_counter_offer(
                &mut offer_table,
                FIRST_DOMAIN_NAME.to_string(),
                additional_payment,
                ctx
            );

            // Clean up
            test_scenario::return_shared(offer_table);
        };

        abort
    }

    #[test, expected_failure(abort_code = auction::ENotUpgrade)]
    fun try_call_with_wrong_auction_table_version() {
        let (mut scenario_val, _clock) = setup_test();
        let scenario = &mut scenario_val;

        generate_domain(scenario, DOMAIN_OWNER, FIRST_DOMAIN_NAME);

        // Migrate
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
            let mut offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let mut auction_table = test_scenario::take_shared<AuctionTable>(scenario);

            auction::migrate(&admin_cap, &mut auction_table, &mut offer_table);

            // Clean up
            test_scenario::return_shared(auction_table);
            test_scenario::return_shared(offer_table);
            test_scenario::return_to_sender(scenario, admin_cap);
        };

        abort
    }

    #[test]
    fun set_seal_config_test() {
        let (mut scenario_val, clock) = setup_test();
        let scenario = &mut scenario_val;

        // Set first config
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
            let mut auction_table = test_scenario::take_shared<AuctionTable>(scenario);

            auction::set_seal_config(&admin_cap, &mut auction_table, vector[@0xa], vector[vector[0, 1]], 1);

            let key_servers = auction_table.get_auction_table_key_servers();
            assert!(key_servers == &vector[@0xa], 0);

            let public_keys = auction_table.get_auction_table_public_keys();
            assert!(public_keys == &vector[vector[0, 1]], 0);

            let threshold = auction_table.get_auction_table_threshold();
            assert!(threshold == &1, 0);

            transfer::public_transfer(admin_cap, DOMAIN_OWNER);
            test_scenario::return_shared(auction_table);
        };

        // Override config
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
            let mut auction_table = test_scenario::take_shared<AuctionTable>(scenario);

            auction::set_seal_config(
                &admin_cap,
                &mut auction_table,
                vector[@0xb, @0xc],
                vector[vector[1, 2], vector[2, 3]],
                2
            );

            let key_servers = auction_table.get_auction_table_key_servers();
            assert!(key_servers == &vector[@0xb, @0xc], 0);

            let public_keys = auction_table.get_auction_table_public_keys();
            assert!(public_keys == &vector[vector[1, 2], vector[2, 3]], 0);

            let threshold = auction_table.get_auction_table_threshold();
            assert!(threshold == &2, 0);

            transfer::public_transfer(admin_cap, DOMAIN_OWNER);
            test_scenario::return_shared(auction_table);
        };

        // Final cleanup
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EInvalidThreshold)]
    fun try_set_seal_config_invalid_threshold() {
        let (mut scenario_val, _clock) = setup_test();
        let scenario = &mut scenario_val;

        // Set first config
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
            let mut auction_table = test_scenario::take_shared<AuctionTable>(scenario);

            auction::set_seal_config(&admin_cap, &mut auction_table, vector[@0xa], vector[vector[0, 1]], 2);

            transfer::public_transfer(admin_cap, DOMAIN_OWNER);
            test_scenario::return_shared(auction_table);
        };

        abort
    }

    #[test, expected_failure(abort_code = auction::EInvalidKeyLengths)]
    fun try_set_seal_config_invalid_key_lengths() {
        let (mut scenario_val, _clock) = setup_test();
        let scenario = &mut scenario_val;

        // Set first config
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
            let mut auction_table = test_scenario::take_shared<AuctionTable>(scenario);

            auction::set_seal_config(&admin_cap, &mut auction_table, vector[@0xa, @0xb], vector[vector[0, 1]], 1);

            transfer::public_transfer(admin_cap, DOMAIN_OWNER);
            test_scenario::return_shared(auction_table);
        };

        abort
    }

    #[test]
    fun set_service_fee_test() {
        let (mut scenario_val, clock) = setup_test();
        let scenario = &mut scenario_val;

        // Set first service fee
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
            let mut auction_table = test_scenario::take_shared<AuctionTable>(scenario);
            let mut offer_table = test_scenario::take_shared<OfferTable>(scenario);

            auction::set_service_fee(&admin_cap, &mut auction_table, &mut offer_table, 5_000); // 5%

            let auction_fee = auction::get_auction_table_service_fee(&auction_table);
            assert!(auction_fee == 5_000, 0);

            let offer_fee = offer::get_offer_table_service_fee(&offer_table);
            assert!(offer_fee == 5_000, 0);

            transfer::public_transfer(admin_cap, DOMAIN_OWNER);
            test_scenario::return_shared(auction_table);
            test_scenario::return_shared(offer_table);
        };

        // Override service fee
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
            let mut auction_table = test_scenario::take_shared<AuctionTable>(scenario);
            let mut offer_table = test_scenario::take_shared<OfferTable>(scenario);

            auction::set_service_fee(&admin_cap, &mut auction_table, &mut offer_table, 1_000); // 1%

            let auction_fee = auction::get_auction_table_service_fee(&auction_table);
            assert!(auction_fee == 1_000, 0);

            let offer_fee = offer::get_offer_table_service_fee(&offer_table);
            assert!(offer_fee == 1_000, 0);

            transfer::public_transfer(admin_cap, DOMAIN_OWNER);
            test_scenario::return_shared(auction_table);
            test_scenario::return_shared(offer_table);
        };

        // Final cleanup
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EInvalidServiceFee)]
    fun try_set_service_fee_invalid() {
        let (mut scenario_val, _clock) = setup_test();
        let scenario = &mut scenario_val;

        // Try to set service fee >= 100%
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
            let mut auction_table = test_scenario::take_shared<AuctionTable>(scenario);
            let mut offer_table = test_scenario::take_shared<OfferTable>(scenario);

            auction::set_service_fee(&admin_cap, &mut auction_table, &mut offer_table, 100_000); // 100%

            transfer::public_transfer(admin_cap, DOMAIN_OWNER);
            test_scenario::return_shared(auction_table);
            test_scenario::return_shared(offer_table);
        };

        abort
    }

    #[test]
    fun withdraw_fees_test() {
        let (mut scenario_val, mut clock) = setup_test();
        let scenario = &mut scenario_val;

        // Create auction for first domain
        generate_domain(scenario, DOMAIN_OWNER, FIRST_DOMAIN_NAME);
        clock.increment_for_testing(START_TIME * MS);
        create_auction<SUI>(scenario, DOMAIN_OWNER, START_TIME, END_TIME, SUI_MIN_BID, &clock);
        clock.increment_for_testing(TICK_INCREMENT);
        place_bid<SUI>(scenario, SECOND_ADDRESS, FIRST_DOMAIN_NAME, SUI_SECOND_BID, &clock);
        clock.increment_for_testing((AUCTION_ACTIVE_TIME + 300) * MS);
        finalize_auction<SUI>(scenario, FIRST_DOMAIN_NAME, &clock);

        // Place offer on same domain
        test_scenario::next_tx(scenario, FIRST_ADDRESS);
        {
            let mut offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let ctx = test_scenario::ctx(scenario);
            let offer_coin = coin::mint_for_testing<SUI>(SUI_FIRST_BID * mist_per_sui(), ctx);

            offer::place_offer<SUI>(
                &mut offer_table,
                FIRST_DOMAIN_NAME.to_string(),
                offer_coin,
                option::none(), &clock, ctx
            );

            test_scenario::return_shared(offer_table);
        };

        // Accept offer on same domain
        test_scenario::next_tx(scenario, SECOND_ADDRESS);
        {
            let mut offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let mut suins = scenario.take_shared<SuiNS>();
            let registration = test_scenario::take_from_sender<SuinsRegistration>(scenario);
            let ctx = test_scenario::ctx(scenario);

            let payment = offer::accept_offer<SUI>(
                &mut suins,
                &mut offer_table,
                registration,
                FIRST_ADDRESS,
                &clock,
                ctx
            );

            // Verify payment after fee deduction
            assert!(coin::value(&payment) == SUI_FIRST_BID * mist_per_sui() * 97_500 / 100_000, 0);
            coin::burn_for_testing(payment);

            test_scenario::return_shared(offer_table);
            test_scenario::return_shared(suins);
        };

        // Withdraw all fees
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
            let mut auction_table = test_scenario::take_shared<AuctionTable>(scenario);
            let mut offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let ctx = test_scenario::ctx(scenario);

            // Withdraw fees from both tables
            let fees_coin = auction::withdraw_fees<SUI>(
                &admin_cap,
                &mut auction_table,
                &mut offer_table,
                ctx
            );

            let expected_total_fee = (SUI_SECOND_BID + SUI_FIRST_BID) * mist_per_sui() * 2_500 / 100_000;
            assert!(coin::value(&fees_coin) == expected_total_fee, 0);

            // Verify fees bags are now empty for SUI
            let auction_fees = auction::get_auction_table_fees(&auction_table);
            let offer_fees = offer::get_offer_table_fees(&offer_table);
            let sui_type_name = type_name::with_defining_ids<SUI>();

            assert!(!auction_fees.contains(sui_type_name), 1);
            assert!(!offer_fees.contains(sui_type_name), 2);

            coin::burn_for_testing(fees_coin);
            transfer::public_transfer(admin_cap, DOMAIN_OWNER);
            test_scenario::return_shared(auction_table);
            test_scenario::return_shared(offer_table);
        };

        // Final cleanup
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario_val);
    }

    #[test]
    fun allowed_token_test() {
        let (mut scenario_val, clock) = setup_test();
        let scenario = &mut scenario_val;

        // Allow token
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
            let mut auction_table = test_scenario::take_shared<AuctionTable>(scenario);
            let mut offer_table = test_scenario::take_shared<OfferTable>(scenario);

            auction::add_allowed_token<TestCoin>(&admin_cap, &mut auction_table, &mut offer_table);

            let allowed_tokens = auction_table.get_auction_table_allowed_tokens();
            let test_coin_type_name = type_name::with_defining_ids<TestCoin>();

            assert!(allowed_tokens.contains(test_coin_type_name), 0);
            assert!(allowed_tokens.borrow(test_coin_type_name) == true, 1);

            transfer::public_transfer(admin_cap, DOMAIN_OWNER);
            test_scenario::return_shared(auction_table);
            test_scenario::return_shared(offer_table);
        };

        // Disallow the token
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
            let mut auction_table = test_scenario::take_shared<AuctionTable>(scenario);
            let mut offer_table = test_scenario::take_shared<OfferTable>(scenario);

            auction::remove_allowed_token<TestCoin>(&admin_cap, &mut auction_table, &mut offer_table);

            let allowed_tokens = auction_table.get_auction_table_allowed_tokens();
            let test_coin_type_name = type_name::with_defining_ids<TestCoin>();

            assert!(!allowed_tokens.contains(test_coin_type_name), 0);

            transfer::public_transfer(admin_cap, DOMAIN_OWNER);
            test_scenario::return_shared(auction_table);
            test_scenario::return_shared(offer_table);
        };

        // Final cleanup
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario_val);
    }

    #[test]
    fun listing_scenario_sui_test() {
        let (mut scenario_val, clock) = setup_test();
        let scenario = &mut scenario_val;

        generate_domain(scenario, DOMAIN_OWNER, FIRST_DOMAIN_NAME);

        // Create a listing with a fixed price
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let mut offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let registration = test_scenario::take_from_sender<SuinsRegistration>(scenario);
            let ctx = test_scenario::ctx(scenario);

            offer::create_listing<SUI>(
                &mut offer_table,
                SUI_FIRST_BID * mist_per_sui(),
                option::none(),
                registration,
                &clock,
                ctx
            );

            test_scenario::return_shared(offer_table);
        };

        // Verify listing was created
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let listings = offer::get_offer_table_listings(&offer_table);
            assert!(listings.contains(FIRST_DOMAIN_NAME), 0);
            assert!(listings.length() == 1, 0);
            test_scenario::return_shared(offer_table);
        };

        // Buy the listing
        test_scenario::next_tx(scenario, FIRST_ADDRESS);
        {
            let mut offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let mut suins = scenario.take_shared<SuiNS>();
            let ctx = test_scenario::ctx(scenario);
            let payment = coin::mint_for_testing<SUI>(SUI_FIRST_BID * mist_per_sui(), ctx);

            let registration = offer::buy_listing<SUI>(
                &mut suins,
                &mut offer_table,
                FIRST_DOMAIN_NAME.to_string(),
                payment,
                &clock,
                ctx
            );

            transfer::public_transfer(registration, FIRST_ADDRESS);
            test_scenario::return_shared(offer_table);
            test_scenario::return_shared(suins);
        };

        // Verify listing was purchased
        test_scenario::next_tx(scenario, FIRST_ADDRESS);
        {
            let offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let listings = offer::get_offer_table_listings(&offer_table);
            assert!(listings.length() == 0, 0);

            // Verify domain owner received payment minus service fee
            let payment_received = test_scenario::take_from_address<Coin<SUI>>(scenario, DOMAIN_OWNER);
            assert!(coin::value(&payment_received) == SUI_FIRST_BID * mist_per_sui() * 97_500 / 100_000, 0);
            test_scenario::return_to_address(DOMAIN_OWNER, payment_received);

            // Verify service fee was collected
            let fees = offer::get_offer_table_fees(&offer_table);
            let sui_type_name = type_name::with_defining_ids<SUI>();
            let fee_balance = fees.borrow<TypeName, Balance<SUI>>(sui_type_name);
            assert!(fee_balance.value() == SUI_FIRST_BID * mist_per_sui() * 2_500 / 100_000, 0);

            test_scenario::return_shared(offer_table);

            // Verify buyer received the domain
            let registration = test_scenario::take_from_address<SuinsRegistration>(scenario, FIRST_ADDRESS);
            assert!(registration.domain() == domain::new(FIRST_DOMAIN_NAME.to_string()), 0);
            test_scenario::return_to_address(FIRST_ADDRESS, registration);
        };

        // Final cleanup
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario_val);
    }

    #[test]
    fun listing_scenario_other_test() {
        let (mut scenario_val, clock) = setup_test();
        let scenario = &mut scenario_val;

        generate_domain(scenario, DOMAIN_OWNER, FIRST_DOMAIN_NAME);

        // Allow token
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
            let mut auction_table = test_scenario::take_shared<AuctionTable>(scenario);
            let mut offer_table = test_scenario::take_shared<OfferTable>(scenario);

            auction::add_allowed_token<TestCoin>(&admin_cap, &mut auction_table, &mut offer_table);

            transfer::public_transfer(admin_cap, DOMAIN_OWNER);
            test_scenario::return_shared(auction_table);
            test_scenario::return_shared(offer_table);
        };

        // Create a listing with TestCoin
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let mut offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let registration = test_scenario::take_from_sender<SuinsRegistration>(scenario);
            let ctx = test_scenario::ctx(scenario);

            offer::create_listing<TestCoin>(
                &mut offer_table,
                SUI_FIRST_BID * mist_per_sui(),
                option::none(),
                registration,
                &clock,
                ctx
            );

            test_scenario::return_shared(offer_table);
        };

        // Disallow the token, existing listing still works
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
            let mut auction_table = test_scenario::take_shared<AuctionTable>(scenario);
            let mut offer_table = test_scenario::take_shared<OfferTable>(scenario);

            auction::remove_allowed_token<TestCoin>(&admin_cap, &mut auction_table, &mut offer_table);

            transfer::public_transfer(admin_cap, DOMAIN_OWNER);
            test_scenario::return_shared(auction_table);
            test_scenario::return_shared(offer_table);
        };

        // Verify listing was created
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let listings = offer::get_offer_table_listings(&offer_table);
            assert!(listings.contains(FIRST_DOMAIN_NAME), 0);
            assert!(listings.length() == 1, 0);
            test_scenario::return_shared(offer_table);
        };

        // Buy the listing with TestCoin
        test_scenario::next_tx(scenario, FIRST_ADDRESS);
        {
            let mut offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let mut suins = scenario.take_shared<SuiNS>();
            let ctx = test_scenario::ctx(scenario);
            let payment = coin::mint_for_testing<TestCoin>(SUI_FIRST_BID * mist_per_sui(), ctx);

            let registration = offer::buy_listing<TestCoin>(
                &mut suins,
                &mut offer_table,
                FIRST_DOMAIN_NAME.to_string(),
                payment,
                &clock,
                ctx
            );

            transfer::public_transfer(registration, FIRST_ADDRESS);
            test_scenario::return_shared(offer_table);
            test_scenario::return_shared(suins);
        };

        // Verify listing was purchased
        test_scenario::next_tx(scenario, FIRST_ADDRESS);
        {
            let offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let listings = offer::get_offer_table_listings(&offer_table);
            assert!(listings.length() == 0, 0);

            // Verify domain owner received payment minus service fee
            let payment_received = test_scenario::take_from_address<Coin<TestCoin>>(scenario, DOMAIN_OWNER);
            assert!(coin::value(&payment_received) == SUI_FIRST_BID * mist_per_sui() * 97_500 / 100_000, 0);
            test_scenario::return_to_address(DOMAIN_OWNER, payment_received);

            // Verify service fee was collected in TestCoin
            let fees = offer::get_offer_table_fees(&offer_table);
            let test_coin_type_name = type_name::with_defining_ids<TestCoin>();
            let fee_balance = fees.borrow<TypeName, Balance<TestCoin>>(test_coin_type_name);
            assert!(fee_balance.value() == SUI_FIRST_BID * mist_per_sui() * 2_500 / 100_000, 0);

            test_scenario::return_shared(offer_table);

            // Verify buyer received the domain
            let registration = test_scenario::take_from_address<SuinsRegistration>(scenario, FIRST_ADDRESS);
            assert!(registration.domain() == domain::new(FIRST_DOMAIN_NAME.to_string()), 0);
            test_scenario::return_to_address(FIRST_ADDRESS, registration);
        };

        // Final cleanup
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario_val);
    }

    #[test]
    fun create_listing_and_buy_before_expires_at() {
        let (mut scenario_val, mut clock) = setup_test();
        let scenario = &mut scenario_val;

        clock.increment_for_testing(1 * MS);

        generate_domain(scenario, DOMAIN_OWNER, FIRST_DOMAIN_NAME);

        // Create a listing with expiration
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let mut offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let registration = test_scenario::take_from_sender<SuinsRegistration>(scenario);
            let ctx = test_scenario::ctx(scenario);

            offer::create_listing<SUI>(
                &mut offer_table,
                SUI_FIRST_BID * mist_per_sui(),
                option::some(123),
                registration,
                &clock,
                ctx
            );

            test_scenario::return_shared(offer_table);
        };

        // Buy the listing before it expires
        test_scenario::next_tx(scenario, FIRST_ADDRESS);
        {
            let mut offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let mut suins = scenario.take_shared<SuiNS>();
            let ctx = test_scenario::ctx(scenario);
            let payment = coin::mint_for_testing<SUI>(SUI_FIRST_BID * mist_per_sui(), ctx);

            let registration = offer::buy_listing<SUI>(
                &mut suins,
                &mut offer_table,
                FIRST_DOMAIN_NAME.to_string(),
                payment,
                &clock,
                ctx
            );

            transfer::public_transfer(registration, FIRST_ADDRESS);
            test_scenario::return_shared(offer_table);
            test_scenario::return_shared(suins);
        };

        // Verify listing was purchased
        test_scenario::next_tx(scenario, FIRST_ADDRESS);
        {
            let offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let listings = offer::get_offer_table_listings(&offer_table);
            assert!(listings.length() == 0, 0);
            test_scenario::return_shared(offer_table);

            // Verify buyer received the domain
            let registration = test_scenario::take_from_address<SuinsRegistration>(scenario, FIRST_ADDRESS);
            assert!(registration.domain() == domain::new(FIRST_DOMAIN_NAME.to_string()), 0);
            test_scenario::return_to_address(FIRST_ADDRESS, registration);
        };

        // Final cleanup
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = offer::EInvalidExpiresAt)]
    fun try_create_listing_after_expires_at() {
        let (mut scenario_val, mut clock) = setup_test();
        let scenario = &mut scenario_val;

        clock.increment_for_testing(1 * MS);

        generate_domain(scenario, DOMAIN_OWNER, FIRST_DOMAIN_NAME);

        // Try to create a listing with expires_at in the past
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let mut offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let registration = test_scenario::take_from_sender<SuinsRegistration>(scenario);
            let ctx = test_scenario::ctx(scenario);

            offer::create_listing<SUI>(
                &mut offer_table,
                SUI_FIRST_BID * mist_per_sui(),
                option::some(1),
                registration,
                &clock,
                ctx
            );

            test_scenario::return_shared(offer_table);
        };

        abort
    }

    #[test, expected_failure(abort_code = offer::EListingExpired)]
    fun try_buy_listing_after_expires_at() {
        let (mut scenario_val, mut clock) = setup_test();
        let scenario = &mut scenario_val;

        clock.increment_for_testing(1 * MS);

        generate_domain(scenario, DOMAIN_OWNER, FIRST_DOMAIN_NAME);

        // Create a listing with expiration
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let mut offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let registration = test_scenario::take_from_sender<SuinsRegistration>(scenario);
            let ctx = test_scenario::ctx(scenario);

            offer::create_listing<SUI>(
                &mut offer_table,
                SUI_FIRST_BID * mist_per_sui(),
                option::some(123),
                registration,
                &clock,
                ctx
            );

            test_scenario::return_shared(offer_table);
        };

        // Advance clock past expiration
        clock.increment_for_testing(124 * MS);

        // Try to buy the listing after it expired
        test_scenario::next_tx(scenario, FIRST_ADDRESS);
        {
            let mut offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let mut suins = scenario.take_shared<SuiNS>();
            let ctx = test_scenario::ctx(scenario);
            let payment = coin::mint_for_testing<SUI>(SUI_FIRST_BID * mist_per_sui(), ctx);

            let registration = offer::buy_listing<SUI>(
                &mut suins,
                &mut offer_table,
                FIRST_DOMAIN_NAME.to_string(),
                payment,
                &clock,
                ctx
            );

            transfer::public_transfer(registration, FIRST_ADDRESS);
            test_scenario::return_shared(offer_table);
            test_scenario::return_shared(suins);
        };

        abort
    }

    #[test, expected_failure(abort_code = offer::ETokenNotAllowed)]
    fun try_create_listing_not_allowed_token() {
        let (mut scenario_val, clock) = setup_test();
        let scenario = &mut scenario_val;

        generate_domain(scenario, DOMAIN_OWNER, FIRST_DOMAIN_NAME);

        // Try to create a listing with TestCoin (not allowed)
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let mut offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let registration = test_scenario::take_from_sender<SuinsRegistration>(scenario);
            let ctx = test_scenario::ctx(scenario);

            // Try to create listing with TestCoin (not allowed)
            offer::create_listing<TestCoin>(
                &mut offer_table,
                SUI_FIRST_BID * mist_per_sui(),
                option::none(),
                registration,
                &clock,
                ctx
            );

            // Clean up
            test_scenario::return_shared(offer_table);
        };

        abort
    }

    #[test]
    fun create_listing_and_cancel_scenario_test() {
        let (mut scenario_val, clock) = setup_test();
        let scenario = &mut scenario_val;

        generate_domain(scenario, DOMAIN_OWNER, FIRST_DOMAIN_NAME);

        // Create listing
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let mut offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let registration = test_scenario::take_from_sender<SuinsRegistration>(scenario);
            let ctx = test_scenario::ctx(scenario);

            offer::create_listing<SUI>(
                &mut offer_table,
                SUI_FIRST_BID * mist_per_sui(),
                option::none(),
                registration,
                &clock,
                ctx
            );

            test_scenario::return_shared(offer_table);
        };

        // Verify listing exists
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let listings = offer::get_offer_table_listings(&offer_table);
            assert!(listings.length() == 1, 0);
            assert!(listings.contains(FIRST_DOMAIN_NAME), 0);
            test_scenario::return_shared(offer_table);
        };

        // Cancel the listing
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let mut offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let ctx = test_scenario::ctx(scenario);

            let registration = offer::cancel_listing<SUI>(
                &mut offer_table,
                FIRST_DOMAIN_NAME.to_string(),
                ctx
            );

            // Verify we got the domain back
            let domain = registration.domain();
            assert!(domain.to_string() == FIRST_DOMAIN_NAME.to_string(), 0);

            // Return the registration
            test_scenario::return_to_sender(scenario, registration);
            test_scenario::return_shared(offer_table);
        };

        // Verify no listing remains
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let listings = offer::get_offer_table_listings(&offer_table);
            assert!(listings.length() == 0, 0);
            assert!(!listings.contains(FIRST_DOMAIN_NAME), 0);
            test_scenario::return_shared(offer_table);
        };

        // Final cleanup
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = offer::ENotListingOwner)]
    fun try_cancel_listing_not_owner() {
        let (mut scenario_val, clock) = setup_test();
        let scenario = &mut scenario_val;

        generate_domain(scenario, DOMAIN_OWNER, FIRST_DOMAIN_NAME);

        // Create a listing as DOMAIN_OWNER
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let mut offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let registration = test_scenario::take_from_sender<SuinsRegistration>(scenario);
            let ctx = test_scenario::ctx(scenario);

            offer::create_listing<SUI>(
                &mut offer_table,
                SUI_FIRST_BID * mist_per_sui(),
                option::none(),
                registration,
                &clock,
                ctx
            );

            test_scenario::return_shared(offer_table);
        };

        // Try to cancel as FIRST_ADDRESS
        test_scenario::next_tx(scenario, FIRST_ADDRESS);
        {
            let mut offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let ctx = test_scenario::ctx(scenario);

            let registration = offer::cancel_listing<SUI>(
                &mut offer_table,
                FIRST_DOMAIN_NAME.to_string(),
                ctx
            );

            test_scenario::return_to_address(FIRST_ADDRESS, registration);
            test_scenario::return_shared(offer_table);
        };

        abort
    }

    #[test, expected_failure(abort_code = offer::EWrongCoinValue)]
    fun try_buy_listing_wrong_payment() {
        let (mut scenario_val, clock) = setup_test();
        let scenario = &mut scenario_val;

        generate_domain(scenario, DOMAIN_OWNER, FIRST_DOMAIN_NAME);

        // Create a listing as DOMAIN_OWNER
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let mut offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let registration = test_scenario::take_from_sender<SuinsRegistration>(scenario);
            let ctx = test_scenario::ctx(scenario);

            offer::create_listing<SUI>(
                &mut offer_table,
                SUI_FIRST_BID * mist_per_sui(),
                option::none(),
                registration,
                &clock,
                ctx
            );

            test_scenario::return_shared(offer_table);
        };

        // Try to buy with wrong payment amount (too low) - should fail
        test_scenario::next_tx(scenario, FIRST_ADDRESS);
        {
            let mut offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let mut suins = test_scenario::take_shared<SuiNS>(scenario);
            let ctx = test_scenario::ctx(scenario);

            // Create payment with wrong amount (too low)
            let payment = coin::mint_for_testing<SUI>(SUI_LOW_BID * mist_per_sui(), ctx);

            let registration = offer::buy_listing<SUI>(
                &mut suins,
                &mut offer_table,
                FIRST_DOMAIN_NAME.to_string(),
                payment,
                &clock,
                ctx
            );

            test_scenario::return_to_sender(scenario, registration);
            test_scenario::return_shared(offer_table);
            test_scenario::return_shared(suins);
        };

        abort
    }

    #[test, expected_failure(abort_code = offer::ENotListed)]
    fun try_buy_listing_not_listed() {
        let (mut scenario_val, clock) = setup_test();
        let scenario = &mut scenario_val;

        // Try to buy a listing that doesn't exist - should fail
        test_scenario::next_tx(scenario, FIRST_ADDRESS);
        {
            let mut offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let mut suins = test_scenario::take_shared<SuiNS>(scenario);
            let ctx = test_scenario::ctx(scenario);

            // Create payment
            let payment = coin::mint_for_testing<SUI>(SUI_FIRST_BID * mist_per_sui(), ctx);

            let registration = offer::buy_listing<SUI>(
                &mut suins,
                &mut offer_table,
                FIRST_DOMAIN_NAME.to_string(),
                payment,
                &clock,
                ctx
            );

            test_scenario::return_to_sender(scenario, registration);
            test_scenario::return_shared(offer_table);
            test_scenario::return_shared(suins);
        };

        abort
    }
}