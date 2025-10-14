// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
#[allow(deprecated_usage)]
#[test_only]
module suins_auction::auction_tests
{
    use sui::{clock::{Self, Clock}, coin::{Self, Coin}, sui::SUI, test_scenario::{Self, Scenario}};
    use suins::suins;
    use suins_auction::{
        auction::{
            Self,
            AuctionTable,
            OfferTable,
            AdminCap,
        },
        constants::mist_per_sui,
        domain,
        suins_registration::SuinsRegistration,
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
    const AUCTION_ACTIVE_TIME: u64 = 100;
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
                domain_name,
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
                domain_name,
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

        // Generate a new domain
        generate_domain(scenario, DOMAIN_OWNER, FIRST_DOMAIN_NAME);

        // Increment the clock to the start time
        clock.increment_for_testing(START_TIME * MS);

        // Create an auction
        create_auction<SUI>(
            scenario,
            DOMAIN_OWNER,
            START_TIME,
            END_TIME,
            SUI_MIN_BID,
        );

        // Increment the clock to auction active
        clock.increment_for_testing(TICK_INCREMENT);

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
            assert!(auction::get_end_time(auction) == 410, 0); // auction extended by 5 minutes from now
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
            assert!(auction::get_end_time(auction) == 410, 0);
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
            test_scenario::return_shared(auction_table);

            let first_bid = test_scenario::take_from_address<Coin<SUI>>(scenario, FIRST_ADDRESS);
            assert!(coin::value(&first_bid) == SUI_FIRST_BID * mist_per_sui(), 0);
            test_scenario::return_to_address(FIRST_ADDRESS, first_bid);

            let winning_bid = test_scenario::take_from_address<Coin<SUI>>(scenario, DOMAIN_OWNER);
            assert!(coin::value(&winning_bid) == SUI_SECOND_BID * mist_per_sui(), 0);
            test_scenario::return_to_address(DOMAIN_OWNER, winning_bid);

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

        // Generate a new domain
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

        // Create an auction
        create_auction<TestCoin>(
            scenario,
            DOMAIN_OWNER,
            START_TIME,
            END_TIME + 300,
            SUI_MIN_BID,
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
            test_scenario::return_shared(auction_table);

            let winning_bid = test_scenario::take_from_address<Coin<TestCoin>>(scenario, DOMAIN_OWNER);
            assert!(coin::value(&winning_bid) == SUI_FIRST_BID * mist_per_sui(), 0);
            test_scenario::return_to_address(DOMAIN_OWNER, winning_bid);

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

        // Generate a new domain
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
        // cargo run --bin seal-cli encrypt-hmac --message 0x00c817a804000000 --aad 0x000000000000000000000000000000000000000000000000000000000000a001 --package-id 0x0 --id 0x64000000000000007465732d74322e737569 --threshold 2 a58bfa576a8efe2e2730bc664b3dbe70257d8e35106e4af7353d007dba092d722314a0aeb6bca5eed735466bbf471aef01e4da8d2efac13112c51d1411f6992b8604656ea2cf6a33ec10ce8468de20e1d7ecbfed8688a281d462f72a41602161 a9ce55cfa7009c3116ea29341151f3c40809b816f4ad29baa4f95c1bb23085ef02a46cf1ae5bd570d99b0c6e9faf525306224609300b09e422ae2722a17d2a969777d53db7b52092e4d12014da84bffb1e845c2510e26b3c259ede9e42603cd6 93b3220f4f3a46fb33074b590cda666c0ebc75c7157d2e6492c62b4aebc452c29f581361a836d1abcbe1386268a5685103d12dec04aadccaebfa46d4c92e2f2c0381b52d6f2474490d02280a9e9d8c889a3fce2753055e06033f39af86676651 -- 0xbfd1d3ac3d6c37f03afe4d7c244e677f9b01fcbff79dae3394640a7944e5f5ab 0x8fac4aefdc1ae21c00f745605297041e0f39667844068e3757d587c8039d1e3f 0x9a0e57f118b817d7f60599157cad12d788a8562ee5dd1b098b7c25b25bd83f56
        // cargo run --bin seal-cli symmetric-decrypt --key 0xff39846fabaaf439611c5bf6fab9824fb7c76ac6ac2bb7f1f2177e89ec9b9755 0000000000000000000000000000000000000000000000000000000000000000001264000000000000007465732d74322e73756903bfd1d3ac3d6c37f03afe4d7c244e677f9b01fcbff79dae3394640a7944e5f5ab018fac4aefdc1ae21c00f745605297041e0f39667844068e3757d587c8039d1e3f029a0e57f118b817d7f60599157cad12d788a8562ee5dd1b098b7c25b25bd83f560302008cf9d21e3012ef64fc4834ed37eb835fcb3b91889ee13b50f8e3a6ab5ed602fb6f0ad3a86e0246f2b9cbb78034963293021fc9df0cc086a9485ca59f2a19e3234eb7d603b4eca6541086965bdf858028e521d7e744cf6db435465f8929f0636a033b120e73ee469e9d09166778a2420e456b02fa755de2dfbc176e08469d52baa3069892d4f775449b755197f4e904756466d41c4107f8393f1a8a524853aef68d0ff4676f06b1dac62457e762ca4cf59e4df38e3365c14ec0c11fc3c2cd90d06f387c84acabdef7752c9d9dc4d9acf083b3e180daca491ac5d734c804c7781a120108c9e23076205b9a7a0120000000000000000000000000000000000000000000000000000000000000a001d5d0e42fb937d1916a6598c4a301fd959fa020558e5dc3506661f33a00541d8a
        let encrypted_object =
            x"0000000000000000000000000000000000000000000000000000000000000000001264000000000000007465732d74322e73756903bfd1d3ac3d6c37f03afe4d7c244e677f9b01fcbff79dae3394640a7944e5f5ab018fac4aefdc1ae21c00f745605297041e0f39667844068e3757d587c8039d1e3f029a0e57f118b817d7f60599157cad12d788a8562ee5dd1b098b7c25b25bd83f560302008cf9d21e3012ef64fc4834ed37eb835fcb3b91889ee13b50f8e3a6ab5ed602fb6f0ad3a86e0246f2b9cbb78034963293021fc9df0cc086a9485ca59f2a19e3234eb7d603b4eca6541086965bdf858028e521d7e744cf6db435465f8929f0636a033b120e73ee469e9d09166778a2420e456b02fa755de2dfbc176e08469d52baa3069892d4f775449b755197f4e904756466d41c4107f8393f1a8a524853aef68d0ff4676f06b1dac62457e762ca4cf59e4df38e3365c14ec0c11fc3c2cd90d06f387c84acabdef7752c9d9dc4d9acf083b3e180daca491ac5d734c804c7781a120108c9e23076205b9a7a0120000000000000000000000000000000000000000000000000000000000000a001d5d0e42fb937d1916a6598c4a301fd959fa020558e5dc3506661f33a00541d8a";

        // Create an auction
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
        // cargo run --bin seal-cli extract --package-id 0x0 --id 0x64000000000000007465732d74322e737569 --master-key 3c185eb32f1ab43a013c7d84659ec7b59791ca76764af4ee8d387bf05621f0c7
        let dk0 =
            x"b8ed40a65729135aade14d4aa727cbcaca29a222640fa392e67613a8e71942b7f7be36710ab422207e309b0f0f543349";
        // cargo run --bin seal-cli extract --package-id 0x0 --id 0x64000000000000007465732d74322e737569 --master-key 09ba20939b2300c5ffa42e71809d3dc405b1e68259704b3cb8e04c36b0033e24
        let dk1 =
            x"afbda1e9b2cae7141627832d72511a0cc9bba1a20e89323e39ee42a5eac18a5b54932759c8d2dfcf7bf5d64b0235defa";

        // Finalize the auction
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let mut auction_table = test_scenario::take_shared<AuctionTable>(scenario);
            let mut suins = test_scenario::take_shared<SuiNS>(scenario);
            let ctx = test_scenario::ctx(scenario);

            auction::finalize_auction<SUI>(
                &mut suins,
                &mut auction_table,
                FIRST_DOMAIN_NAME,
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

            let winning_bid = test_scenario::take_from_address<Coin<SUI>>(scenario, DOMAIN_OWNER);
            assert!(coin::value(&winning_bid) == 2 * SUI_MIN_BID * mist_per_sui(), 0);
            test_scenario::return_to_address(DOMAIN_OWNER, winning_bid);

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

        // Generate a new domain
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
        // cargo run --bin seal-cli encrypt-hmac --message 0x00c817a804000000 --aad 0x000000000000000000000000000000000000000000000000000000000000a001 --package-id 0x0 --id 0x64000000000000007465732d74322e737569 --threshold 2 a58bfa576a8efe2e2730bc664b3dbe70257d8e35106e4af7353d007dba092d722314a0aeb6bca5eed735466bbf471aef01e4da8d2efac13112c51d1411f6992b8604656ea2cf6a33ec10ce8468de20e1d7ecbfed8688a281d462f72a41602161 a9ce55cfa7009c3116ea29341151f3c40809b816f4ad29baa4f95c1bb23085ef02a46cf1ae5bd570d99b0c6e9faf525306224609300b09e422ae2722a17d2a969777d53db7b52092e4d12014da84bffb1e845c2510e26b3c259ede9e42603cd6 93b3220f4f3a46fb33074b590cda666c0ebc75c7157d2e6492c62b4aebc452c29f581361a836d1abcbe1386268a5685103d12dec04aadccaebfa46d4c92e2f2c0381b52d6f2474490d02280a9e9d8c889a3fce2753055e06033f39af86676651 -- 0xbfd1d3ac3d6c37f03afe4d7c244e677f9b01fcbff79dae3394640a7944e5f5ab 0x8fac4aefdc1ae21c00f745605297041e0f39667844068e3757d587c8039d1e3f 0x9a0e57f118b817d7f60599157cad12d788a8562ee5dd1b098b7c25b25bd83f56
        // cargo run --bin seal-cli symmetric-decrypt --key 0xff39846fabaaf439611c5bf6fab9824fb7c76ac6ac2bb7f1f2177e89ec9b9755 0000000000000000000000000000000000000000000000000000000000000000001264000000000000007465732d74322e73756903bfd1d3ac3d6c37f03afe4d7c244e677f9b01fcbff79dae3394640a7944e5f5ab018fac4aefdc1ae21c00f745605297041e0f39667844068e3757d587c8039d1e3f029a0e57f118b817d7f60599157cad12d788a8562ee5dd1b098b7c25b25bd83f560302008cf9d21e3012ef64fc4834ed37eb835fcb3b91889ee13b50f8e3a6ab5ed602fb6f0ad3a86e0246f2b9cbb78034963293021fc9df0cc086a9485ca59f2a19e3234eb7d603b4eca6541086965bdf858028e521d7e744cf6db435465f8929f0636a033b120e73ee469e9d09166778a2420e456b02fa755de2dfbc176e08469d52baa3069892d4f775449b755197f4e904756466d41c4107f8393f1a8a524853aef68d0ff4676f06b1dac62457e762ca4cf59e4df38e3365c14ec0c11fc3c2cd90d06f387c84acabdef7752c9d9dc4d9acf083b3e180daca491ac5d734c804c7781a120108c9e23076205b9a7a0120000000000000000000000000000000000000000000000000000000000000a001d5d0e42fb937d1916a6598c4a301fd959fa020558e5dc3506661f33a00541d8a
        let encrypted_object =
            x"0000000000000000000000000000000000000000000000000000000000000000001264000000000000007465732d74322e73756903bfd1d3ac3d6c37f03afe4d7c244e677f9b01fcbff79dae3394640a7944e5f5ab018fac4aefdc1ae21c00f745605297041e0f39667844068e3757d587c8039d1e3f029a0e57f118b817d7f60599157cad12d788a8562ee5dd1b098b7c25b25bd83f560302008cf9d21e3012ef64fc4834ed37eb835fcb3b91889ee13b50f8e3a6ab5ed602fb6f0ad3a86e0246f2b9cbb78034963293021fc9df0cc086a9485ca59f2a19e3234eb7d603b4eca6541086965bdf858028e521d7e744cf6db435465f8929f0636a033b120e73ee469e9d09166778a2420e456b02fa755de2dfbc176e08469d52baa3069892d4f775449b755197f4e904756466d41c4107f8393f1a8a524853aef68d0ff4676f06b1dac62457e762ca4cf59e4df38e3365c14ec0c11fc3c2cd90d06f387c84acabdef7752c9d9dc4d9acf083b3e180daca491ac5d734c804c7781a120108c9e23076205b9a7a0120000000000000000000000000000000000000000000000000000000000000a001d5d0e42fb937d1916a6598c4a301fd959fa020558e5dc3506661f33a00541d8a";

        // Create an auction
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
        // cargo run --bin seal-cli extract --package-id 0x0 --id 0x64000000000000007465732d74322e737569 --master-key 3c185eb32f1ab43a013c7d84659ec7b59791ca76764af4ee8d387bf05621f0c7
        let dk0 =
            x"b8ed40a65729135aade14d4aa727cbcaca29a222640fa392e67613a8e71942b7f7be36710ab422207e309b0f0f543349";
        // cargo run --bin seal-cli extract --package-id 0x0 --id 0x64000000000000007465732d74322e737569 --master-key 09ba20939b2300c5ffa42e71809d3dc405b1e68259704b3cb8e04c36b0033e24
        let dk1 =
            x"afbda1e9b2cae7141627832d72511a0cc9bba1a20e89323e39ee42a5eac18a5b54932759c8d2dfcf7bf5d64b0235defa";

        // Finalize the auction
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let mut auction_table = test_scenario::take_shared<AuctionTable>(scenario);
            let mut suins = test_scenario::take_shared<SuiNS>(scenario);
            let ctx = test_scenario::ctx(scenario);

            auction::finalize_auction<SUI>(
                &mut suins,
                &mut auction_table,
                FIRST_DOMAIN_NAME,
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

    #[test, expected_failure(abort_code = auction::ETokenNotAllowed)]
    fun try_create_auction_not_allowed_token() {
        let (mut scenario_val, mut clock) = setup_test();
        let scenario = &mut scenario_val;

        // Generate a new domain
        generate_domain(scenario, DOMAIN_OWNER, FIRST_DOMAIN_NAME);

        // Increment the clock to the start time
        clock.increment_for_testing(START_TIME * MS);

        // Create an auction
        create_auction<TestCoin>(
            scenario,
            DOMAIN_OWNER,
            START_TIME,
            END_TIME + 300,
            SUI_MIN_BID,
        );

        // Final cleanup
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::ENotOwner)]
    fun try_cancel_auction_not_owner() {
        let (mut scenario_val, mut clock) = setup_test();
        let scenario = &mut scenario_val;

        // Generate a new domain
        generate_domain(scenario, DOMAIN_OWNER, FIRST_DOMAIN_NAME);

        // Increment the clock to the start time
        clock.increment_for_testing(START_TIME * MS);

        // Create an auction
        create_auction<SUI>(
            scenario,
            DOMAIN_OWNER,
            START_TIME,
            END_TIME,
            SUI_MIN_BID,
        );

        // Tx to check auction and accounts state
        test_scenario::next_tx(scenario, FIRST_ADDRESS);
        {
            let mut auction_table = test_scenario::take_shared<AuctionTable>(scenario);
            let ctx = test_scenario::ctx(scenario);
            let registration = auction::cancel_auction<SUI>(&mut auction_table,
                FIRST_DOMAIN_NAME,
                &clock,
                ctx);
            test_scenario::return_to_address(FIRST_ADDRESS, registration);
            test_scenario::return_shared(auction_table);
        };

        // Final cleanup
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::ETooEarly)]
    fun try_place_bid_too_early() {
        let (mut scenario_val, mut clock) = setup_test();
        let scenario = &mut scenario_val;

        // Generate a new domain
        generate_domain(scenario, DOMAIN_OWNER, FIRST_DOMAIN_NAME);

        // Create an auction
        create_auction<SUI>(
            scenario,
            DOMAIN_OWNER,
            START_TIME,
            END_TIME,
            SUI_MIN_BID,
        );

        // Increment the clock to auction active
        clock.increment_for_testing(TICK_INCREMENT);

        // First address places a bid
        place_bid<SUI>(scenario, FIRST_ADDRESS, FIRST_DOMAIN_NAME, SUI_FIRST_BID, &clock);

        // Final cleanup
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::ETooLate)]
    fun try_place_bid_too_late() {
        let (mut scenario_val, mut clock) = setup_test();
        let scenario = &mut scenario_val;

        // Generate a new domain
        generate_domain(scenario, DOMAIN_OWNER, FIRST_DOMAIN_NAME);

        // Create an auction
        create_auction<SUI>(
            scenario,
            DOMAIN_OWNER,
            START_TIME,
            END_TIME,
            SUI_MIN_BID,
        );

        // Increment the clock to auction ended
        clock.increment_for_testing(END_TIME * MS + TICK_INCREMENT);

        // First address places a bid
        place_bid<SUI>(scenario, FIRST_ADDRESS, FIRST_DOMAIN_NAME, SUI_FIRST_BID, &clock);

        // Final cleanup
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EWrongTime)]
    fun try_create_auction_wrong_time() {
        let (mut scenario_val, clock) = setup_test();
        let scenario = &mut scenario_val;

        // Generate a new domain
        generate_domain(scenario, DOMAIN_OWNER, FIRST_DOMAIN_NAME);

        // Create an auction
        create_auction<SUI>(
            scenario,
            DOMAIN_OWNER,
            END_TIME,
            START_TIME,
            SUI_MIN_BID,
        );

        // Final cleanup
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EBidTooLow)]
    fun try_place_bid_lower_than_minimum() {
        let (mut scenario_val, mut clock) = setup_test();
        let scenario = &mut scenario_val;

        // Generate a new domain
        generate_domain(scenario, DOMAIN_OWNER, FIRST_DOMAIN_NAME);

        // Increment the clock to the start time
        clock.increment_for_testing(START_TIME * MS);

        // Create an auction
        create_auction<SUI>(
            scenario,
            DOMAIN_OWNER,
            START_TIME,
            END_TIME,
            SUI_MIN_BID,
        );

        // Increment the clock to auction active
        clock.increment_for_testing(TICK_INCREMENT);

        // First address places a bid
        place_bid<SUI>(scenario, FIRST_ADDRESS, FIRST_DOMAIN_NAME, SUI_LOW_BID, &clock);

        // Final cleanup
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EBidTooLow)]
    fun try_place_bid_lower_than_previous() {
        let (mut scenario_val, mut clock) = setup_test();
        let scenario = &mut scenario_val;

        // Generate a new domain
        generate_domain(scenario, DOMAIN_OWNER, FIRST_DOMAIN_NAME);

        // Increment the clock to the start time
        clock.increment_for_testing(START_TIME * MS);

        // Create an auction
        create_auction<SUI>(
            scenario,
            DOMAIN_OWNER,
            START_TIME,
            END_TIME,
            SUI_MIN_BID,
        );

        // Increment the clock to auction active
        clock.increment_for_testing(TICK_INCREMENT);

        // First address places a bid
        place_bid<SUI>(scenario, FIRST_ADDRESS, FIRST_DOMAIN_NAME, SUI_SECOND_BID, &clock);

        // Second address places a bid
        place_bid<SUI>(scenario, SECOND_ADDRESS, FIRST_DOMAIN_NAME, SUI_FIRST_BID, &clock);

        // Final cleanup
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::ENotEnded)]
    fun try_finalize_auction_not_ended() {
        let (mut scenario_val, mut clock) = setup_test();
        let scenario = &mut scenario_val;

        // Generate a new domain
        generate_domain(scenario, DOMAIN_OWNER, FIRST_DOMAIN_NAME);

        // Increment the clock to the start time
        clock.increment_for_testing(START_TIME * MS);

        // Create an auction
        create_auction<SUI>(
            scenario,
            DOMAIN_OWNER,
            START_TIME,
            END_TIME,
            SUI_MIN_BID,
        );

        // Increment the clock to auction active
        clock.increment_for_testing(TICK_INCREMENT);

        // Finalize the auction
        finalize_auction<SUI>(scenario, FIRST_DOMAIN_NAME, &clock);

        // Final cleanup
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EEnded)]
    fun try_cancel_ended_auction() {
        let (mut scenario_val, mut clock) = setup_test();
        let scenario = &mut scenario_val;

        // Generate a new domain
        generate_domain(scenario, DOMAIN_OWNER, FIRST_DOMAIN_NAME);

        // Increment the clock to the start time
        clock.increment_for_testing(START_TIME * MS);

        // Create an auction
        create_auction<SUI>(
            scenario,
            DOMAIN_OWNER,
            START_TIME,
            END_TIME,
            SUI_MIN_BID,
        );

        // Increment the clock to auction ended
        clock.increment_for_testing(END_TIME * MS + TICK_INCREMENT);

        // Tx to check auction and accounts state
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let mut auction_table = test_scenario::take_shared<AuctionTable>(scenario);
            let ctx = test_scenario::ctx(scenario);
            let registration = auction::cancel_auction<SUI>(&mut auction_table,
                FIRST_DOMAIN_NAME,
                &clock,
                ctx);
            test_scenario::return_to_address(FIRST_ADDRESS, registration);
            test_scenario::return_shared(auction_table);
        };

        // Final cleanup
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::ENotAuctioned)]
    fun try_place_bid_not_auctioned_domain() {
        let (mut scenario_val, mut clock) = setup_test();
        let scenario = &mut scenario_val;

        // Generate a new domain
        generate_domain(scenario, DOMAIN_OWNER, FIRST_DOMAIN_NAME);

        // Increment the clock to the start time
        clock.increment_for_testing(START_TIME * MS);

        // Create an auction
        create_auction<SUI>(
            scenario,
            DOMAIN_OWNER,
            START_TIME,
            END_TIME,
            SUI_MIN_BID,
        );

        // Increment the clock to auction active
        clock.increment_for_testing(TICK_INCREMENT);

        // First address places a bid
        place_bid<SUI>(scenario, FIRST_ADDRESS, SECOND_DOMAIN_NAME, SUI_SECOND_BID, &clock);

        // Final cleanup
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario_val);
    }

    #[test]
    fun place_offer_and_accept_scenario_sui_test() {
        let (mut scenario_val, clock) = setup_test();
        let scenario = &mut scenario_val;

        // Generate a new domain
        generate_domain(scenario, DOMAIN_OWNER, FIRST_DOMAIN_NAME);

        // Place an offer
        test_scenario::next_tx(scenario, FIRST_ADDRESS);
        {
            let mut offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let ctx = test_scenario::ctx(scenario);

            // Create test SUI coins for the offer
            let payment = coin::mint_for_testing<SUI>(SUI_FIRST_BID * mist_per_sui(), ctx);

            // Place the offer
            auction::place_offer(
                &mut offer_table,
                FIRST_DOMAIN_NAME,
                payment,
                ctx
            );

            // Clean up
            test_scenario::return_shared(offer_table);
        };

        // Verify the offer was placed correctly
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let table = auction::get_offer_table(&offer_table);
            let offers = table.borrow(FIRST_DOMAIN_NAME);
            assert!(offers.contains(FIRST_ADDRESS), 0);
            let offer = offers.borrow(FIRST_ADDRESS);
            assert!(auction::get_offer_balance(offer).value() == SUI_FIRST_BID * mist_per_sui(), 0);
            assert!(auction::get_offer_counter_offer<SUI>(offer) == 0, 0);
            test_scenario::return_shared(offer_table);
        };

        // Final cleanup
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario_val);
    }

    #[test]
    fun place_offer_and_accept_scenario_other_test() {
        let (mut scenario_val, clock) = setup_test();
        let scenario = &mut scenario_val;

        // Generate a new domain
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
            auction::place_offer(
                &mut offer_table,
                FIRST_DOMAIN_NAME,
                payment,
                ctx
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
            let table = auction::get_offer_table(&offer_table);
            let offers = table.borrow(FIRST_DOMAIN_NAME);
            assert!(offers.contains(FIRST_ADDRESS), 0);
            let offer = offers.borrow(FIRST_ADDRESS);
            assert!(auction::get_offer_balance(offer).value() == SUI_FIRST_BID * mist_per_sui(), 0);
            assert!(auction::get_offer_counter_offer<TestCoin>(offer) == 0, 0);
            test_scenario::return_shared(offer_table);
        };

        // Final cleanup
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::ETokenNotAllowed)]
    fun try_place_offer_not_allowed_token() {
        let (mut scenario_val, clock) = setup_test();
        let scenario = &mut scenario_val;

        // Generate a new domain
        generate_domain(scenario, DOMAIN_OWNER, FIRST_DOMAIN_NAME);

        // Place an offer
        test_scenario::next_tx(scenario, FIRST_ADDRESS);
        {
            let mut offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let ctx = test_scenario::ctx(scenario);

            // Create test SUI coins for the offer
            let payment = coin::mint_for_testing<TestCoin>(SUI_FIRST_BID * mist_per_sui(), ctx);

            // Place the offer
            auction::place_offer(
                &mut offer_table,
                FIRST_DOMAIN_NAME,
                payment,
                ctx
            );

            // Clean up
            test_scenario::return_shared(offer_table);
        };

        // Final cleanup
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario_val);
    }

    #[test]
    fun place_offer_counteroffer_and_accept_scenario_test() {
        let (mut scenario_val, clock) = setup_test();
        let scenario = &mut scenario_val;

        // Generate a new domain
        generate_domain(scenario, DOMAIN_OWNER, FIRST_DOMAIN_NAME);

        // Place an offer
        test_scenario::next_tx(scenario, FIRST_ADDRESS);
        {
            let mut offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let ctx = test_scenario::ctx(scenario);

            // Create test SUI coins for the offer
            let payment = coin::mint_for_testing<SUI>(SUI_FIRST_BID * mist_per_sui(), ctx);

            // Place the offer
            auction::place_offer(
                &mut offer_table,
                FIRST_DOMAIN_NAME,
                payment,
                ctx
            );

            // Clean up
            test_scenario::return_shared(offer_table);
        };

        // Verify the offer was placed correctly
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let table = auction::get_offer_table(&offer_table);
            let offers = table.borrow(FIRST_DOMAIN_NAME);
            assert!(offers.contains(FIRST_ADDRESS), 0);
            let offer = offers.borrow(FIRST_ADDRESS);
            assert!(auction::get_offer_balance(offer).value() == SUI_FIRST_BID * mist_per_sui(), 0);
            assert!(auction::get_offer_counter_offer<SUI>(offer) == 0, 0);
            test_scenario::return_shared(offer_table);
        };

        // Make a counter offer
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let mut offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let registration = test_scenario::take_from_sender<SuinsRegistration>(scenario);
            let ctx = test_scenario::ctx(scenario);

            // Make counter offer
            auction::make_counter_offer<SUI>(
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
            let table = auction::get_offer_table(&offer_table);
            assert!(table.length() == 1);
            let offers = table.borrow(FIRST_DOMAIN_NAME);
            let offer = offers.borrow(FIRST_ADDRESS);
            assert!(auction::get_offer_counter_offer<SUI>(offer) == SUI_SECOND_BID * mist_per_sui(), 0);
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
            auction::accept_counter_offer(
                &mut offer_table,
                FIRST_DOMAIN_NAME,
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
            let payment = auction::accept_offer<SUI>(
                &mut suins,
                &mut offer_table,
                registration,
                FIRST_ADDRESS,
                &clock,
                ctx
            );

            // Verify payment amount
            assert!(coin::value(&payment) == SUI_SECOND_BID * mist_per_sui(), 0);
            coin::burn_for_testing(payment);

            // Clean up
            test_scenario::return_shared(offer_table);
            test_scenario::return_shared(suins);
        };

        // Tx to check offers and accounts state
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let table = auction::get_offer_table(&offer_table);
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
            auction::place_offer(
                &mut offer_table,
                FIRST_DOMAIN_NAME,
                payment,
                ctx
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
            auction::place_offer(
                &mut offer_table,
                SECOND_DOMAIN_NAME,
                payment,
                ctx
            );

            // Clean up
            test_scenario::return_shared(offer_table);
        };

        // Verify the offers were placed correctly
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let table = auction::get_offer_table(&offer_table);
            assert!(table.length() == 2);
            let offers = table.borrow(FIRST_DOMAIN_NAME);
            assert!(offers.contains(FIRST_ADDRESS), 0);
            let offer = offers.borrow(FIRST_ADDRESS);
            assert!(auction::get_offer_balance(offer).value() == SUI_FIRST_BID * mist_per_sui(), 0);
            assert!(auction::get_offer_counter_offer<SUI>(offer) == 0, 0);
            let offers = table.borrow(SECOND_DOMAIN_NAME);
            assert!(offers.contains(SECOND_ADDRESS), 0);
            let offer = offers.borrow(SECOND_ADDRESS);
            assert!(auction::get_offer_balance(offer).value() == SUI_SECOND_BID * mist_per_sui(), 0);
            assert!(auction::get_offer_counter_offer<SUI>(offer) == 0, 0);
            test_scenario::return_shared(offer_table);
        };

        // Cancel the offer
        test_scenario::next_tx(scenario, FIRST_ADDRESS);
        {
            let mut offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let ctx = test_scenario::ctx(scenario);

            // Cancel the offer
            let payment = auction::cancel_offer<SUI>(
                &mut offer_table,
                FIRST_DOMAIN_NAME,
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
            let table = auction::get_offer_table(&offer_table);
            assert!(table.length() == 1, 0);
            let offers = table.borrow(SECOND_DOMAIN_NAME);
            assert!(offers.contains(SECOND_ADDRESS), 0);
            let offer = offers.borrow(SECOND_ADDRESS);
            assert!(auction::get_offer_balance(offer).value() == SUI_SECOND_BID * mist_per_sui(), 0);
            assert!(auction::get_offer_counter_offer<SUI>(offer) == 0, 0);
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

        // Generate a new domain
        generate_domain(scenario, DOMAIN_OWNER, FIRST_DOMAIN_NAME);

        // Place an offer
        test_scenario::next_tx(scenario, FIRST_ADDRESS);
        {
            let mut offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let ctx = test_scenario::ctx(scenario);

            // Create test SUI coins for the offer
            let payment = coin::mint_for_testing<SUI>(SUI_FIRST_BID * mist_per_sui(), ctx);

            // Place the offer
            auction::place_offer(
                &mut offer_table,
                FIRST_DOMAIN_NAME,
                payment,
                ctx
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
            auction::place_offer(
                &mut offer_table,
                FIRST_DOMAIN_NAME,
                payment,
                ctx
            );

            // Clean up
            test_scenario::return_shared(offer_table);
        };

        // Verify the offers were placed correctly
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let table = auction::get_offer_table(&offer_table);
            assert!(table.length() == 1);
            let offers = table.borrow(FIRST_DOMAIN_NAME);
            assert!(offers.contains(FIRST_ADDRESS), 0);
            let offer = offers.borrow(FIRST_ADDRESS);
            assert!(auction::get_offer_balance(offer).value() == SUI_FIRST_BID * mist_per_sui(), 0);
            assert!(auction::get_offer_counter_offer<SUI>(offer) == 0, 0);
            assert!(offers.contains(SECOND_ADDRESS), 0);
            let offer = offers.borrow(SECOND_ADDRESS);
            assert!(auction::get_offer_balance(offer).value() == SUI_SECOND_BID * mist_per_sui(), 0);
            assert!(auction::get_offer_counter_offer<SUI>(offer) == 0, 0);
            test_scenario::return_shared(offer_table);
        };

        // Decline the second offer
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let mut offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let registration = test_scenario::take_from_sender<SuinsRegistration>(scenario);
            let ctx = test_scenario::ctx(scenario);

            // Decline the offer
            auction::decline_offer<SUI>(
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
            let table = auction::get_offer_table(&offer_table);
            assert!(table.length() == 1, 0);
            let offers = table.borrow(FIRST_DOMAIN_NAME);
            assert!(offers.contains(FIRST_ADDRESS), 0);
            let offer = offers.borrow(FIRST_ADDRESS);
            assert!(auction::get_offer_balance(offer).value() == SUI_FIRST_BID * mist_per_sui(), 0);
            assert!(auction::get_offer_counter_offer<SUI>(offer) == 0, 0);
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

    #[test, expected_failure(abort_code = auction::EAlreadyOffered)]
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
            auction::place_offer(
                &mut offer_table,
                FIRST_DOMAIN_NAME,
                payment,
                ctx
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
            auction::place_offer(
                &mut offer_table,
                FIRST_DOMAIN_NAME,
                payment,
                ctx
            );

            // Clean up
            test_scenario::return_shared(offer_table);
        };

        // Final cleanup
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::ECounterOfferTooLow)]
    fun try_make_too_low_counteroffer() {
        let (mut scenario_val, clock) = setup_test();
        let scenario = &mut scenario_val;

        // Generate a new domain
        generate_domain(scenario, DOMAIN_OWNER, FIRST_DOMAIN_NAME);

        // Place an offer
        test_scenario::next_tx(scenario, FIRST_ADDRESS);
        {
            let mut offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let ctx = test_scenario::ctx(scenario);

            // Create test SUI coins for the offer
            let payment = coin::mint_for_testing<SUI>(SUI_FIRST_BID * mist_per_sui(), ctx);

            // Place the offer
            auction::place_offer(
                &mut offer_table,
                FIRST_DOMAIN_NAME,
                payment,
                ctx
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
            auction::make_counter_offer<SUI>(
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

        // Final cleanup
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::ENoCounterOffer)]
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
            auction::place_offer(
                &mut offer_table,
                FIRST_DOMAIN_NAME,
                payment,
                ctx
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
            auction::accept_counter_offer(
                &mut offer_table,
                FIRST_DOMAIN_NAME,
                additional_payment,
                ctx
            );

            // Clean up
            test_scenario::return_shared(offer_table);
        };

        // Final cleanup
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EWrongCoinValue)]
    fun try_accept_counteroffer_wrong_payment() {
        let (mut scenario_val, clock) = setup_test();
        let scenario = &mut scenario_val;

        // Generate a new domain
        generate_domain(scenario, DOMAIN_OWNER, FIRST_DOMAIN_NAME);

        // Place an offer
        test_scenario::next_tx(scenario, FIRST_ADDRESS);
        {
            let mut offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let ctx = test_scenario::ctx(scenario);

            // Create test SUI coins for the offer
            let payment = coin::mint_for_testing<SUI>(SUI_FIRST_BID * mist_per_sui(), ctx);

            // Place the offer
            auction::place_offer(
                &mut offer_table,
                FIRST_DOMAIN_NAME,
                payment,
                ctx
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
            auction::make_counter_offer<SUI>(
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
            auction::accept_counter_offer(
                &mut offer_table,
                FIRST_DOMAIN_NAME,
                additional_payment,
                ctx
            );

            // Clean up
            test_scenario::return_shared(offer_table);
        };

        // Final cleanup
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EDomainNotOffered)]
    fun try_make_counteroffer_on_non_existent_offer() {
        let (mut scenario_val, clock) = setup_test();
        let scenario = &mut scenario_val;

        // Generate a new domain
        generate_domain(scenario, DOMAIN_OWNER, FIRST_DOMAIN_NAME);

        // Make a counter offer
        test_scenario::next_tx(scenario, DOMAIN_OWNER);
        {
            let mut offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let registration = test_scenario::take_from_sender<SuinsRegistration>(scenario);
            let ctx = test_scenario::ctx(scenario);

            // Make counter offer
            auction::make_counter_offer<SUI>(
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

        // Final cleanup
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EAddressNotOffered)]
    fun try_accept_counteroffer_wrong_caller() {
        let (mut scenario_val, clock) = setup_test();
        let scenario = &mut scenario_val;

        // Generate a new domain
        generate_domain(scenario, DOMAIN_OWNER, FIRST_DOMAIN_NAME);

        // Place an offer
        test_scenario::next_tx(scenario, FIRST_ADDRESS);
        {
            let mut offer_table = test_scenario::take_shared<OfferTable>(scenario);
            let ctx = test_scenario::ctx(scenario);

            // Create test SUI coins for the offer
            let payment = coin::mint_for_testing<SUI>(SUI_FIRST_BID * mist_per_sui(), ctx);

            // Place the offer
            auction::place_offer(
                &mut offer_table,
                FIRST_DOMAIN_NAME,
                payment,
                ctx
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
            auction::make_counter_offer<SUI>(
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
            auction::accept_counter_offer(
                &mut offer_table,
                FIRST_DOMAIN_NAME,
                additional_payment,
                ctx
            );

            // Clean up
            test_scenario::return_shared(offer_table);
        };

        // Final cleanup
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::ENotUpgrade)]
    fun try_call_with_wrong_auction_table_version() {
        let (mut scenario_val, clock) = setup_test();
        let scenario = &mut scenario_val;

        // Generate a new domain
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

        // Final cleanup
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario_val);
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
        let (mut scenario_val, clock) = setup_test();
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

        // Final cleanup
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = auction::EInvalidKeyLengths)]
    fun try_set_seal_config_invalid_key_lengths() {
        let (mut scenario_val, clock) = setup_test();
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
}