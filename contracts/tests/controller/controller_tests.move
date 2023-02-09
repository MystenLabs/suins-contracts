#[test_only]
module suins::controller_tests {

    use sui::coin::{Self, Coin};
    use sui::test_scenario::{Self, Scenario};
    use sui::tx_context;
    use sui::sui::SUI;
    use suins::controller::{Self, BaseController};
    use suins::base_registrar::{Self, BaseRegistrar, TLDsList, RegistrationNFT};
    use suins::base_registry::{Self, Registry, AdminCap};
    use suins::emoji;
    use suins::configuration::{Self, Configuration};
    use std::string;
    use std::option::{Self, Option, some};
    use std::string::utf8;
    use sui::url;
    use sui::table;
    use suins::auction::{Auction, make_seal_bid};
    use suins::auction;
    use suins::auction_tests::{start_auction_util, new_bid_util, unseal_bid_util};

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

    fun test_init(): Scenario {
        let scenario = test_scenario::begin(SUINS_ADDRESS);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            base_registry::test_init(ctx);
            base_registrar::test_init(ctx);
            controller::test_init(ctx);
            configuration::test_init(ctx);
            auction::test_init(ctx);
        };
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let tlds_list = test_scenario::take_shared<TLDsList>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            base_registrar::new_tld(&admin_cap, &mut tlds_list,b"sui", test_scenario::ctx(&mut scenario));
            configuration::new_referral_code(&admin_cap, &mut config, REFERRAL_CODE, 10, SECOND_USER_ADDRESS);
            configuration::new_discount_code(&admin_cap, &mut config, DISCOUNT_CODE, 15, FIRST_USER_ADDRESS);
            test_scenario::return_shared(tlds_list);
            test_scenario::return_shared(config);
            test_scenario::return_to_sender(&mut scenario, admin_cap);
        };
        scenario
    }

    fun make_commitment(scenario: &mut Scenario, label: Option<vector<u8>>) {
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let controller = test_scenario::take_shared<BaseController>(scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(scenario);
            let no_of_commitments = controller::commitment_len(&controller);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                50,
                0
            );
            if (option::is_none(&label)) label = option::some(FIRST_LABEL);
            let commitment = controller::test_make_commitment(&registrar, option::extract(&mut label), FIRST_USER_ADDRESS, FIRST_SECRET);
            controller::commit(
                &mut controller,
                commitment,
                &mut ctx,
            );
            assert!(controller::commitment_len(&controller) - no_of_commitments == 1, 0);

            test_scenario::return_shared(controller);
            test_scenario::return_shared(registrar);
        };
    }

    fun register(scenario: &mut Scenario) {
        make_commitment(scenario, option::none());

        // register
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let controller = test_scenario::take_shared<BaseController>(scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(scenario);
            let registry = test_scenario::take_shared<Registry>(scenario);
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
            let (_, _, expiries) = base_registrar::get_registrar(&registrar);

            assert!(!base_registrar::record_exists(&registrar, utf8(FIRST_LABEL)), 0);
            assert!(!base_registry::record_exists(&registry, utf8(FIRST_NODE)), 0);
            assert!(controller::balance(&controller) == 0, 0);
            assert!(table::length(expiries) == 0, 0);
            assert!(!test_scenario::has_most_recent_for_sender<RegistrationNFT>(scenario), 0);

            controller::register_with_config(
                &mut controller,
                &mut registrar,
                &mut registry,
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
            test_scenario::return_shared(controller);
            test_scenario::return_shared(config);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(registry);
        };

        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        {
            let controller = test_scenario::take_shared<BaseController>(scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(scenario);
            let (name, url) = base_registrar::get_nft_fields(&nft);
            let (_, _, expiries) = base_registrar::get_registrar(&registrar);
            let registry = test_scenario::take_shared<Registry>(scenario);

            assert!(controller::balance(&controller) == 1000000, 0);
            assert!(name == utf8(FIRST_NODE), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmWjyuoBW7gSxAqvkTYSNbXnNka6iUHNqs3ier9bN3g7Y2"),
                0
            ); // 2024
            assert!(table::length(expiries) == 1, 0);
            assert!(base_registry::get_records_len(&registry) == 1, 0);

            let detail = table::borrow(expiries, utf8(FIRST_LABEL));
            let (owner, resolver, ttl) = base_registry::get_record_by_key(&registry, utf8(FIRST_NODE));

            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(resolver == FIRST_RESOLVER_ADDRESS, 0);
            assert!(ttl == 0, 0);
            assert!(base_registrar::get_registration_detail(detail) == 51 + 365, 0);

            test_scenario::return_to_sender(scenario, nft);
            test_scenario::return_shared(controller);
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(registry);
        };
    }

    #[test]
    fun test_make_commitment() {
        let scenario = test_init();

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            assert!(controller::commitment_len(&controller) == 0, 0);
            test_scenario::return_shared(controller);
        };
        make_commitment(&mut scenario, option::none());
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            assert!(controller::commitment_len(&controller) == 1, 0);
            test_scenario::return_shared(controller);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_register() {
        let scenario = test_init();
        make_commitment(&mut scenario, option::none());

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                21,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            assert!(!base_registrar::record_exists(&registrar, utf8(FIRST_LABEL)), 0);
            assert!(controller::balance(&controller) == 0, 0);
            assert!(controller::commitment_len(&controller) == 1, 0);
            assert!(!base_registry::record_exists(&registry, utf8(FIRST_NODE)), 0);
            assert!(!test_scenario::has_most_recent_for_sender<RegistrationNFT>(&mut scenario), 0);

            controller::register(
                &mut controller,
                &mut registrar,
                &mut registry,
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
            assert!(controller::commitment_len(&controller) == 0, 0);

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(controller);
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(config);
            test_scenario::return_shared(registry);
            test_scenario::return_shared(auction);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let (name, url) = base_registrar::get_nft_fields(&nft);
            let (_, _, expiries) = base_registrar::get_registrar(&registrar);
            let registry = test_scenario::take_shared<Registry>(&mut scenario);

            assert!(controller::balance(&controller) == 2000000, 0);
            assert!(name == utf8(FIRST_NODE), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaWNLR6C3QsSHcPwNoFA59DPXCKdx1t8hmyyKRqBbjYB3"),
                0
            ); // 2025
            assert!(table::length(expiries) == 1, 0);
            assert!(base_registry::get_records_len(&registry) == 1, 0);

            let detail = table::borrow(expiries, utf8(FIRST_LABEL));
            let (owner, resolver, ttl) = base_registry::get_record_by_key(&registry, utf8(FIRST_NODE));

            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(resolver == @0x0, 0);
            assert!(ttl == 0, 0);
            assert!(base_registrar::get_registration_detail(detail) == 21 + 730, 0);

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(controller);
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(registry);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = controller::ECommitmentNotExists)]
    fun test_register_abort_with_difference_label() {
        let scenario = test_init();
        make_commitment(&mut scenario, option::none());

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
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

            assert!(!base_registrar::record_exists(&registrar, utf8(SECOND_LABEL)), 0);

            controller::register(
                &mut controller,
                &mut registrar,
                &mut registry,
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
            test_scenario::return_shared(controller);
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(registry);
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
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
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
            assert!(!base_registrar::record_exists(&registrar, utf8(FIRST_LABEL)), 0);

            controller::register(
                &mut controller,
                &mut registrar,
                &mut registry,
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
            test_scenario::return_shared(controller);
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(registry);
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
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                51,
                0
            );
            let coin = coin::mint_for_testing<SUI>(1000001, &mut ctx);
            assert!(!base_registrar::record_exists(&registrar, utf8(FIRST_LABEL)), 0);

            controller::register(
                &mut controller,
                &mut registrar,
                &mut registry,
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
            test_scenario::return_shared(controller);
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(config);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(registry);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = controller::ECommitmentTooOld)]
    fun test_register_abort_if_called_too_late() {
        let scenario = test_init();
        make_commitment(&mut scenario, option::none());

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
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
                &mut controller,
                &mut registrar,
                &mut registry,
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
            test_scenario::return_shared(controller);
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(registry);
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
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
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
                &mut controller,
                &mut registrar,
                &mut registry,
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
            test_scenario::return_shared(controller);
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(config);
            test_scenario::return_shared(registry);
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
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
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
            assert!(controller::balance(&controller) == 1000000, 0);

            controller::register(
                &mut controller,
                &mut registrar,
                &mut registry,
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
            test_scenario::return_shared(controller);
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(registry);
            test_scenario::return_shared(config);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_register_with_config() {
        let scenario = test_init();
        make_commitment(&mut scenario, option::none());

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                51,
                0
            );
            let coin = coin::mint_for_testing<SUI>(4000001, &mut ctx);

            assert!(!base_registrar::record_exists(&registrar, utf8(FIRST_LABEL)), 0);
            assert!(!base_registry::record_exists(&registry, utf8(FIRST_NODE)), 0);
            assert!(controller::balance(&controller) == 0, 0);
            assert!(!test_scenario::has_most_recent_for_sender<RegistrationNFT>(&mut scenario), 0);

            controller::register_with_config(
                &mut controller,
                &mut registrar,
                &mut registry,
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
            test_scenario::return_shared(controller);
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(config);
            test_scenario::return_shared(registry);
            test_scenario::return_shared(auction);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let (name, url) = base_registrar::get_nft_fields(&nft);
            let (_, _, expiries) = base_registrar::get_registrar(&registrar);
            let registry = test_scenario::take_shared<Registry>(&mut scenario);

            assert!(controller::balance(&controller) == 2000000, 0);
            assert!(name == utf8(FIRST_NODE), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaWNLR6C3QsSHcPwNoFA59DPXCKdx1t8hmyyKRqBbjYB3"),
                0
            ); // 2025
            assert!(table::length(expiries) == 1, 0);
            assert!(base_registry::get_records_len(&registry) == 1, 0);

            let detail = table::borrow(expiries, utf8(FIRST_LABEL));
            let (owner, resolver, ttl) = base_registry::get_record_by_key(&registry, utf8(FIRST_NODE));

            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(resolver == FIRST_RESOLVER_ADDRESS, 0);
            assert!(ttl == 0, 0);
            assert!(base_registrar::get_registration_detail(detail) == 51 + 730, 0);

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(controller);
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(registry);
        };

        // withdraw
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);

            assert!(controller::balance(&controller) == 2000000, 0);
            assert!(!test_scenario::has_most_recent_for_sender<Coin<SUI>>(&mut scenario), 0);

            controller::withdraw(&admin_cap, &mut controller, test_scenario::ctx(&mut scenario));
            assert!(controller::balance(&controller) == 0, 0);

            test_scenario::return_shared(controller);
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
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(10001, test_scenario::ctx(&mut scenario));

            controller::register_with_config(
                &mut controller,
                &mut registrar,
                &mut registry,
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
            test_scenario::return_shared(controller);
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
            test_scenario::return_shared(registry);
        };

        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = emoji::EInvalidLabel)]
    fun test_register_with_config_abort_with_too_long_label() {
        let scenario = test_init();
        make_commitment(&mut scenario, option::none());

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(1000001, test_scenario::ctx(&mut scenario));

            controller::register_with_config(
                &mut controller,
                &mut registrar,
                &mut registry,
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
            test_scenario::return_shared(controller);
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(config);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(registry);
        };

        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = emoji::EInvalidLabel)]
    fun test_register_with_config_abort_if_label_starts_with_hyphen() {
        let scenario = test_init();
        make_commitment(&mut scenario, option::none());

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(10001, test_scenario::ctx(&mut scenario));

            controller::register_with_config(
                &mut controller,
                &mut registrar,
                &mut registry,
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
            test_scenario::return_shared(controller);
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
            test_scenario::return_shared(registry);
        };

        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = emoji::EInvalidLabel)]
    fun test_register_with_config_abort_with_invalid_label() {
        let scenario = test_init();
        make_commitment(&mut scenario, option::none());

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(1000001, test_scenario::ctx(&mut scenario));

            controller::register_with_config(
                &mut controller,
                &mut registrar,
                &mut registry,
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
            test_scenario::return_shared(controller);
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(config);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(registry);
        };

        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = controller::ENoProfits)]
    fun test_withdraw_abort_if_no_profits() {
        let scenario = test_init();

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);

            controller::withdraw(&admin_cap, &mut controller, test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(controller);
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
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(1000001, test_scenario::ctx(&mut scenario));

            controller::register(
                &mut controller,
                &mut registrar,
                &mut registry,
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
            test_scenario::return_shared(controller);
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(config);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(registry);
        };

        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = emoji::EInvalidLabel)]
    fun test_register_abort_if_label_is_invalid() {
        let scenario = test_init();

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                50,
                0
            );

            assert!(controller::commitment_len(&controller) == 0, 0);

            let commitment = controller::test_make_commitment(&registrar, FIRST_INVALID_LABEL, FIRST_USER_ADDRESS, FIRST_SECRET);
            controller::commit(
                &mut controller,
                commitment,
                &mut ctx,
            );
            assert!(controller::commitment_len(&controller) == 1, 0);

            test_scenario::return_shared(controller);
            test_scenario::return_shared(registrar);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
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
                &mut controller,
                &mut registrar,
                &mut registry,
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
            test_scenario::return_shared(controller);
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(config);
            test_scenario::return_shared(registry);
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
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let ctx = test_scenario::ctx(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(2000001, ctx);

            assert!(base_registrar::name_expires(&registrar, string::utf8(FIRST_LABEL)) == 416, 0);
            assert!(controller::balance(&controller) == 1000000, 0);

            controller::renew(
                &mut controller,
                &mut registrar,
                FIRST_LABEL,
                2,
                &mut coin,
                ctx,
            );

            assert!(coin::value(&coin) == 1, 0);
            assert!(base_registrar::name_expires(&registrar, string::utf8(FIRST_LABEL)) == 1146, 0);

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(controller);
            test_scenario::return_shared(registrar);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);

            assert!(controller::balance(&controller) == 3000000, 0);

            test_scenario::return_shared(controller);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = base_registrar::ELabelNotExists)]
    fun test_renew_abort_if_label_not_exists() {
        let scenario = test_init();

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let ctx = test_scenario::ctx(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(1000001, ctx);

            assert!(!base_registrar::record_exists(&registrar, string::utf8(FIRST_LABEL)), 0);

            controller::renew(
                &mut controller,
                &mut registrar,
                FIRST_LABEL,
                1,
                &mut coin,
                ctx,
            );

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(controller);
            test_scenario::return_shared(registrar);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = base_registrar::ELabelExpired)]
    fun test_renew_abort_if_label_expired() {
        let scenario = test_init();
        register(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                1051,
                0
            );
            let coin = coin::mint_for_testing<SUI>(10000001, &mut ctx);

            controller::renew(
                &mut controller,
                &mut registrar,
                FIRST_LABEL,
                1,
                &mut coin,
                &mut ctx,
            );

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(controller);
            test_scenario::return_shared(registrar);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = controller::ENotEnoughFee)]
    fun test_renew_abort_if_not_enough_fee() {
        let scenario = test_init();

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let ctx = test_scenario::ctx(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(4, ctx);

            assert!(!base_registrar::record_exists(&registrar, utf8(FIRST_LABEL)), 0);

            controller::renew(
                &mut controller,
                &mut registrar,
                FIRST_LABEL,
                1,
                &mut coin,
                ctx,
            );

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(controller);
            test_scenario::return_shared(registrar);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_set_default_resolver() {
        let scenario = test_init();

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);

            assert!(controller::get_default_resolver(&controller) == @0x0, 0);

            test_scenario::return_shared(controller);
        };

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);

            controller::set_default_resolver(&admin_cap, &mut controller, FIRST_RESOLVER_ADDRESS);

            test_scenario::return_shared(controller);
            test_scenario::return_to_sender(&mut scenario, admin_cap);
        };

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);

            assert!(controller::get_default_resolver(&controller) == FIRST_RESOLVER_ADDRESS, 0);

            test_scenario::return_shared(controller);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_remove_outdated_commitment() {
        let scenario = test_init();
        // outdated commitment
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                10,
                0
            );

            assert!(controller::commitment_len(&controller) == 0, 0);

            let commitment = controller::test_make_commitment(&registrar, FIRST_LABEL, FIRST_USER_ADDRESS, FIRST_SECRET);
            controller::commit(
                &mut controller,
                commitment,
                &mut ctx,
            );

            assert!(controller::commitment_len(&controller) == 1, 0);

            test_scenario::return_shared(controller);
            test_scenario::return_shared(registrar);
        };

        // outdated commitment
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                30,
                0
            );

            let commitment = controller::test_make_commitment(&registrar, FIRST_LABEL, SECOND_USER_ADDRESS, FIRST_SECRET);
            controller::commit(
                &mut controller,
                commitment,
                &mut ctx,
            );
            assert!(controller::commitment_len(&controller) == 1, 0);

            test_scenario::return_shared(controller);
            test_scenario::return_shared(registrar);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                48,
                0
            );

            let commitment = controller::test_make_commitment(&registrar, FIRST_LABEL, FIRST_USER_ADDRESS, SECOND_SECRET);
            controller::commit(
                &mut controller,
                commitment,
                &mut ctx,
            );
            assert!(controller::commitment_len(&controller) == 1, 0);

            test_scenario::return_shared(controller);
            test_scenario::return_shared(registrar);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                50,
                0
            );

            let commitment = controller::test_make_commitment(&registrar, SECOND_LABEL, FIRST_USER_ADDRESS, FIRST_SECRET);
            controller::commit(
                &mut controller,
                commitment,
                &mut ctx,
            );
            assert!(controller::commitment_len(&controller) == 2, 0);

            test_scenario::return_shared(controller);
            test_scenario::return_shared(registrar);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
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

            assert!(controller::commitment_len(&controller) == 2, 0);

            controller::register(
                &mut controller,
                &mut registrar,
                &mut registry,
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
            assert!(controller::commitment_len(&controller) == 1, 0);

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(controller);
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
            test_scenario::return_shared(registry);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_register_with_referral_code() {
        let scenario = test_init();
        make_commitment(&mut scenario, option::none());

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                51,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            assert!(controller::balance(&controller) == 0, 0);
            assert!(!base_registrar::record_exists(&registrar, utf8(FIRST_LABEL)), 0);
            assert!(!base_registry::record_exists(&registry, utf8(FIRST_NODE)), 0);
            assert!(!test_scenario::has_most_recent_for_sender<RegistrationNFT>(&mut scenario), 0);
            assert!(!test_scenario::has_most_recent_for_address<Coin<SUI>>(SECOND_USER_ADDRESS), 0);

            controller::register_with_code(
                &mut controller,
                &mut registrar,
                &mut registry,
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
            test_scenario::return_shared(controller);
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(config);
            test_scenario::return_shared(registry);
            test_scenario::return_shared(auction);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let (name, url) = base_registrar::get_nft_fields(&nft);
            let (_, _, expiries) = base_registrar::get_registrar(&registrar);
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
            let coin = test_scenario::take_from_address<Coin<SUI>>(&mut scenario, SECOND_USER_ADDRESS);

            assert!(name == utf8(FIRST_NODE), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaWNLR6C3QsSHcPwNoFA59DPXCKdx1t8hmyyKRqBbjYB3"),
                0
            ); // 2025
            assert!(table::length(expiries) == 1, 0);
            assert!(base_registry::get_records_len(&registry) == 1, 0);
            assert!(coin::value(&coin) == 200000, 0);
            assert!(controller::balance(&controller) == 1800000, 0);

            let detail = table::borrow(expiries, utf8(FIRST_LABEL));
            let (owner, resolver, ttl) = base_registry::get_record_by_key(&registry, utf8(FIRST_NODE));

            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(resolver == @0x0, 0);
            assert!(ttl == 0, 0);
            assert!(base_registrar::get_registration_detail(detail) == 51 + 730, 0);

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_to_address(SECOND_USER_ADDRESS, coin);
            test_scenario::return_shared(controller);
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(registry);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_register_with_config_referral_code() {
        let scenario = test_init();
        make_commitment(&mut scenario, option::none());

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                51,
                0
            );
            let coin = coin::mint_for_testing<SUI>(4000000, &mut ctx);

            assert!(controller::balance(&controller) == 0, 0);
            assert!(!base_registrar::record_exists(&registrar, utf8(FIRST_LABEL)), 0);
            assert!(!base_registry::record_exists(&registry, utf8(FIRST_NODE)), 0);
            assert!(!test_scenario::has_most_recent_for_sender<RegistrationNFT>(&mut scenario), 0);
            assert!(!test_scenario::has_most_recent_for_address<Coin<SUI>>(SECOND_USER_ADDRESS), 0);

            controller::register_with_config_and_code(
                &mut controller,
                &mut registrar,
                &mut registry,
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
            test_scenario::return_shared(controller);
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(config);
            test_scenario::return_shared(registry);
            test_scenario::return_shared(auction);

        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let (name, url) = base_registrar::get_nft_fields(&nft);
            let (_, _, expiries) = base_registrar::get_registrar(&registrar);
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
            let coin = test_scenario::take_from_address<Coin<SUI>>(&mut scenario, SECOND_USER_ADDRESS);

            assert!(name == utf8(FIRST_NODE), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmRF7kbi4igtGcX6enEuthQRhvQZejc7ZKBhMimFJtTS8D"),
                0
            ); // 2025
            assert!(table::length(expiries) == 1, 0);
            assert!(base_registry::get_records_len(&registry) == 1, 0);
            assert!(coin::value(&coin) == 300000, 0);
            assert!(controller::balance(&controller) == 2700000, 0);

            let detail = table::borrow(expiries, utf8(FIRST_LABEL));
            let (owner, resolver, ttl) = base_registry::get_record_by_key(&registry, utf8(FIRST_NODE));

            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(resolver == FIRST_RESOLVER_ADDRESS, 0);
            assert!(ttl == 0, 0);
            assert!(base_registrar::get_registration_detail(detail) == 51 + 1095, 0);

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_to_address(SECOND_USER_ADDRESS, coin);
            test_scenario::return_shared(controller);
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(registry);
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
            controller::apply_referral_code_test(&config, &mut coin1,4000000, REFERRAL_CODE, ctx);
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
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                51,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            assert!(controller::balance(&controller) == 0, 0);
            assert!(!base_registrar::record_exists(&registrar, utf8(FIRST_LABEL)), 0);
            assert!(!base_registry::record_exists(&registry, utf8(FIRST_NODE)), 0);
            assert!(!test_scenario::has_most_recent_for_sender<RegistrationNFT>(&mut scenario), 0);
            assert!(!test_scenario::has_most_recent_for_address<Coin<SUI>>(SECOND_USER_ADDRESS), 0);

            controller::register_with_code(
                &mut controller,
                &mut registrar,
                &mut registry,
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
            test_scenario::return_shared(controller);
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
            test_scenario::return_shared(registry);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let (name, url) = base_registrar::get_nft_fields(&nft);
            let (_, _, expiries) = base_registrar::get_registrar(&registrar);
            let registry = test_scenario::take_shared<Registry>(&mut scenario);

            assert!(!test_scenario::has_most_recent_for_address<Coin<SUI>>(SECOND_USER_ADDRESS), 0);
            assert!(name == utf8(FIRST_NODE), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaWNLR6C3QsSHcPwNoFA59DPXCKdx1t8hmyyKRqBbjYB3"),
                0
            ); // 2025
            assert!(table::length(expiries) == 1, 0);
            assert!(base_registry::get_records_len(&registry) == 1, 0);
            assert!(controller::balance(&controller) == 1700000, 0);

            let detail = table::borrow(expiries, utf8(FIRST_LABEL));
            let (owner, resolver, ttl) = base_registry::get_record_by_key(&registry, utf8(FIRST_NODE));

            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(resolver == @0x0, 0);
            assert!(ttl == 0, 0);
            assert!(base_registrar::get_registration_detail(detail) == 51 + 730, 0);

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(controller);
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(registry);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = configuration::EOwnerUnauthorized)]
    fun test_register_with_discount_code_abort_if_unauthorized() {
        let scenario = test_init();
        make_commitment(&mut scenario, option::none());

        test_scenario::next_tx(&mut scenario, SECOND_USER_ADDRESS);
        {
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
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
                &mut controller,
                &mut registrar,
                &mut registry,
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
            test_scenario::return_shared(controller);
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
            test_scenario::return_shared(registry);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = configuration::EDiscountCodeNotExists)]
    fun test_register_with_discount_code_abort_with_invalid_code() {
        let scenario = test_init();
        make_commitment(&mut scenario, option::none());

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
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
                &mut controller,
                &mut registrar,
                &mut registry,
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
            test_scenario::return_shared(controller);
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(config);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(registry);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_register_with_config_and_discount_code() {
        let scenario = test_init();
        make_commitment(&mut scenario, option::none());

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                51,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            assert!(controller::balance(&controller) == 0, 0);
            assert!(!base_registrar::record_exists(&registrar, utf8(FIRST_LABEL)), 0);
            assert!(!base_registry::record_exists(&registry, utf8(FIRST_NODE)), 0);
            assert!(!test_scenario::has_most_recent_for_sender<RegistrationNFT>(&mut scenario), 0);
            assert!(!test_scenario::has_most_recent_for_address<Coin<SUI>>(SECOND_USER_ADDRESS), 0);

            controller::register_with_config_and_code(
                &mut controller,
                &mut registrar,
                &mut registry,
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
            test_scenario::return_shared(controller);
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
            test_scenario::return_shared(registry);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let (name, url) = base_registrar::get_nft_fields(&nft);
            let (_, _, expiries) = base_registrar::get_registrar(&registrar);
            let registry = test_scenario::take_shared<Registry>(&mut scenario);

            assert!(!test_scenario::has_most_recent_for_address<Coin<SUI>>(SECOND_USER_ADDRESS), 0);
            assert!(name == utf8(FIRST_NODE), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaWNLR6C3QsSHcPwNoFA59DPXCKdx1t8hmyyKRqBbjYB3"),
                0
            ); // 2025
            assert!(table::length(expiries) == 1, 0);
            assert!(base_registry::get_records_len(&registry) == 1, 0);
            assert!(controller::balance(&controller) == 1700000, 0);

            let detail = table::borrow(expiries, utf8(FIRST_LABEL));
            let (owner, resolver, ttl) = base_registry::get_record_by_key(&registry, utf8(FIRST_NODE));

            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(resolver == FIRST_RESOLVER_ADDRESS, 0);
            assert!(ttl == 0, 0);
            assert!(base_registrar::get_registration_detail(detail) == 51 + 730, 0);

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(controller);
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(registry);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = configuration::EOwnerUnauthorized)]
    fun test_register_with_config_and_discount_code_abort_if_unauthorized() {
        let scenario = test_init();
        make_commitment(&mut scenario, option::none());

        test_scenario::next_tx(&mut scenario, SECOND_USER_ADDRESS);
        {
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
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
                &mut controller,
                &mut registrar,
                &mut registry,
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
            test_scenario::return_shared(controller);
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(config);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(registry);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = configuration::EDiscountCodeNotExists)]
    fun test_register_with_config_and_discount_code_abort_with_invalid_code() {
        let scenario = test_init();
        make_commitment(&mut scenario, option::none());

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
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
                &mut controller,
                &mut registrar,
                &mut registry,
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
            test_scenario::return_shared(controller);
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(config);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(registry);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = configuration::EDiscountCodeNotExists)]
    fun test_register_with_discount_code_abort_if_being_used_twice() {
        let scenario = test_init();
        make_commitment(&mut scenario, option::none());

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
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
                &mut controller,
                &mut registrar,
                &mut registry,
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
            test_scenario::return_shared(controller);
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
            test_scenario::return_shared(registry);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
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
                &mut controller,
                &mut registrar,
                &mut registry,
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
            test_scenario::return_shared(controller);
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(config);
            test_scenario::return_shared(registry);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_register_with_referral_code_ok_if_being_used_twice() {
        let scenario = test_init();
        make_commitment(&mut scenario, option::none());
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                51,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            assert!(!base_registrar::record_exists(&registrar, utf8(FIRST_LABEL)), 0);

            controller::register_with_code(
                &mut controller,
                &mut registrar,
                &mut registry,
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
            test_scenario::return_shared(controller);
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(config);
            test_scenario::return_shared(registry);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let coin = test_scenario::take_from_address<Coin<SUI>>(&mut scenario, SECOND_USER_ADDRESS);
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);

            assert!(coin::value(&coin) == 200000, 0);
            assert!(controller::balance(&controller) == 1800000, 0);

            test_scenario::return_to_address(SECOND_USER_ADDRESS, coin);
            test_scenario::return_shared(controller);
        };
        make_commitment(&mut scenario, option::some(SECOND_LABEL));
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
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

            assert!(!base_registrar::record_exists(&registrar, utf8(SECOND_LABEL)), 0);
            controller::register_with_code(
                &mut controller,
                &mut registrar,
                &mut registry,
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
            test_scenario::return_shared(controller);
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(config);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(registry);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let coin1 = test_scenario::take_from_address<Coin<SUI>>(&mut scenario, SECOND_USER_ADDRESS);
            let coin2 = test_scenario::take_from_address<Coin<SUI>>(&mut scenario, SECOND_USER_ADDRESS);
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);

            assert!(coin::value(&coin1) == 100000, 0);
            assert!(coin::value(&coin2) == 200000, 0);
            assert!(controller::balance(&controller) == 2700000, 0);

            test_scenario::return_shared(controller);
            test_scenario::return_to_address(SECOND_USER_ADDRESS, coin2);
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
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
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
                &mut controller,
                &mut registrar,
                &mut registry,
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
            test_scenario::return_shared(controller);
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
            test_scenario::return_shared(registry);
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
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
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

            assert!(!base_registrar::record_exists(&registrar, utf8(FIRST_LABEL)), 0);
            assert!(controller::balance(&controller) == 0, 0);
            assert!(controller::commitment_len(&controller) == 1, 0);
            assert!(!base_registry::record_exists(&registry, utf8(FIRST_NODE)), 0);
            assert!(!test_scenario::has_most_recent_for_sender<RegistrationNFT>(&mut scenario), 0);

            controller::register(
                &mut controller,
                &mut registrar,
                &mut registry,
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
            test_scenario::return_shared(controller);
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(config);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(registry);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let (name, url) = base_registrar::get_nft_fields(&nft);
            let (_, _, expiries) = base_registrar::get_registrar(&registrar);
            let registry = test_scenario::take_shared<Registry>(&mut scenario);

            assert!(controller::balance(&controller) == 2000000, 0);
            assert!(name == utf8(FIRST_NODE), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaWNLR6C3QsSHcPwNoFA59DPXCKdx1t8hmyyKRqBbjYB3"),
                0
            ); // 2024
            assert!(table::length(expiries) == 1, 0);
            assert!(base_registry::get_records_len(&registry) == 1, 0);

            let detail = table::borrow(expiries, utf8(FIRST_LABEL));
            let (owner, resolver, ttl) = base_registry::get_record_by_key(&registry, utf8(FIRST_NODE));

            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(resolver == FIRST_RESOLVER_ADDRESS, 0);
            assert!(ttl == 0, 0);
            assert!(base_registrar::get_registration_detail(detail) == 51 + 730, 0);

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(controller);
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(registry);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_register_with_code_apply_both_types_of_code() {
        let scenario = test_init();
        make_commitment(&mut scenario, option::none());
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
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

            assert!(controller::balance(&controller) == 0, 0);
            assert!(!base_registrar::record_exists(&registrar, utf8(FIRST_LABEL)), 0);
            assert!(!base_registry::record_exists(&registry, utf8(FIRST_NODE)), 0);
            assert!(!test_scenario::has_most_recent_for_sender<RegistrationNFT>(&mut scenario), 0);
            assert!(!test_scenario::has_most_recent_for_address<Coin<SUI>>(SECOND_USER_ADDRESS), 0);

            controller::register_with_code(
                &mut controller,
                &mut registrar,
                &mut registry,
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
            test_scenario::return_shared(controller);
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(config);
            test_scenario::return_shared(registry);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let (name, url) = base_registrar::get_nft_fields(&nft);
            let (_, _, expiries) = base_registrar::get_registrar(&registrar);
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
            let coin = test_scenario::take_from_address<Coin<SUI>>(&mut scenario, SECOND_USER_ADDRESS);

            assert!(name == utf8(FIRST_NODE), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaWNLR6C3QsSHcPwNoFA59DPXCKdx1t8hmyyKRqBbjYB3"),
                0
            ); // 2025
            assert!(table::length(expiries) == 1, 0);
            assert!(base_registry::get_records_len(&registry) == 1, 0);
            assert!(coin::value(&coin) == 170000, 0);
            assert!(controller::balance(&controller) == 1700000 - 170000, 0);

            let detail = table::borrow(expiries, utf8(FIRST_LABEL));
            let (owner, resolver, ttl) = base_registry::get_record_by_key(&registry, utf8(FIRST_NODE));

            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(resolver == @0x0, 0);
            assert!(ttl == 0, 0);
            assert!(base_registrar::get_registration_detail(detail) == 51 + 730, 0);

            coin::destroy_for_testing(coin);
            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(controller);
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(registry);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = configuration::EReferralCodeNotExists)]
    fun test_register_with_code_if_use_wrong_referral_code() {
        let scenario = test_init();
        make_commitment(&mut scenario, option::none());
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                51,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            assert!(!base_registrar::record_exists(&registrar, utf8(FIRST_LABEL)), 0);
            controller::register_with_code(
                &mut controller,
                &mut registrar,
                &mut registry,
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
            test_scenario::return_shared(controller);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(config);
            test_scenario::return_shared(registry);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = configuration::EDiscountCodeNotExists)]
    fun test_register_with_code_if_use_wrong_discount_code() {
        let scenario = test_init();
        make_commitment(&mut scenario, option::none());
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                51,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            assert!(!base_registrar::record_exists(&registrar, string::utf8(FIRST_LABEL)), 0);
            controller::register_with_code(
                &mut controller,
                &mut registrar,
                &mut registry,
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
            test_scenario::return_shared(controller);
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(config);
            test_scenario::return_shared(registry);
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
            let controller =
                test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar =
                test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let registry =
                test_scenario::take_shared<Registry>(&mut scenario);
            let config =
                test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                51,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            assert!(controller::balance(&controller) == 0, 0);
            assert!(!base_registrar::record_exists(&registrar, utf8(FIRST_LABEL)), 0);
            assert!(!base_registry::record_exists(&registry, utf8(FIRST_NODE)), 0);
            assert!(!test_scenario::has_most_recent_for_sender<RegistrationNFT>(&mut scenario), 0);
            assert!(!test_scenario::has_most_recent_for_address<Coin<SUI>>(SECOND_USER_ADDRESS), 0);

            controller::register_with_config_and_code(
                &mut controller,
                &mut registrar,
                &mut registry,
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
            test_scenario::return_shared(controller);
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(config);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(registry);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let (name, url) = base_registrar::get_nft_fields(&nft);
            let (_, _, expiries) = base_registrar::get_registrar(&registrar);
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
            let coin = test_scenario::take_from_address<Coin<SUI>>(&mut scenario, SECOND_USER_ADDRESS);

            assert!(name == utf8(FIRST_NODE), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmaWNLR6C3QsSHcPwNoFA59DPXCKdx1t8hmyyKRqBbjYB3"),
                0
            ); // 2025
            assert!(table::length(expiries) == 1, 0);
            assert!(base_registry::get_records_len(&registry) == 1, 0);
            assert!(coin::value(&coin) == 170000, 0);
            assert!(controller::balance(&controller) == 1700000 - 170000, 0);

            let detail = table::borrow(expiries, utf8(FIRST_LABEL));
            let (owner, resolver, ttl) = base_registry::get_record_by_key(&registry, utf8(FIRST_NODE));

            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(resolver == FIRST_RESOLVER_ADDRESS, 0);
            assert!(ttl == 0, 0);
            assert!(base_registrar::get_registration_detail(detail) == 51 + 730, 0);

            coin::destroy_for_testing(coin);
            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(controller);
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(registry);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = configuration::EReferralCodeNotExists)]
    fun test_register_with_config_and_code_if_use_wrong_referral_code() {
        let scenario = test_init();
        make_commitment(&mut scenario, option::none());
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                51,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            assert!(!base_registrar::record_exists(&registrar, utf8(FIRST_LABEL)), 0);
            controller::register_with_config_and_code(
                &mut controller,
                &mut registrar,
                &mut registry,
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
            test_scenario::return_shared(controller);
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(config);
            test_scenario::return_shared(auction);
            test_scenario::return_shared(registry);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = configuration::EDiscountCodeNotExists)]
    fun test_register_with_config_and_code_if_use_wrong_discount_code() {
        let scenario = test_init();
        make_commitment(&mut scenario, option::none());
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            let auction = test_scenario::take_shared<Auction>(&mut scenario);
            let ctx = tx_context::new(
                FIRST_USER_ADDRESS,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                51,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);

            assert!(!base_registrar::record_exists(&registrar, utf8(FIRST_LABEL)), 0);
            controller::register_with_config_and_code(
                &mut controller,
                &mut registrar,
                &mut registry,
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
            test_scenario::return_shared(controller);
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(config);
            test_scenario::return_shared(registry);
            test_scenario::return_shared(auction);
        };
        test_scenario::end(scenario);
    }

    fun set_auction_config(scenario: &mut Scenario) {
        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
            let auction = test_scenario::take_shared<Auction>(scenario);

            auction::configurate_auction(&admin_cap, &mut auction, 50, 110, test_scenario::ctx(scenario));

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
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
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
                &mut controller,
                &mut registrar,
                &mut registry,
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
            test_scenario::return_shared(controller);
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(config);
            test_scenario::return_shared(registry);
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
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
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
                &mut controller,
                &mut registrar,
                &mut registry,
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
            test_scenario::return_shared(controller);
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(config);
            test_scenario::return_shared(registry);
            test_scenario::return_shared(auction);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let (name, url) = base_registrar::get_nft_fields(&nft);
            let (_, _, expiries) = base_registrar::get_registrar(&registrar);
            let registry = test_scenario::take_shared<Registry>(&mut scenario);

            assert!(controller::balance(&controller) == 1000000, 0);
            assert!(name == utf8(FIRST_NODE), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmWjyuoBW7gSxAqvkTYSNbXnNka6iUHNqs3ier9bN3g7Y2"),
                0
            ); // 2024
            assert!(table::length(expiries) == 1, 0);
            assert!(base_registry::get_records_len(&registry) == 1, 0);

            let detail = table::borrow(expiries, utf8(FIRST_LABEL));
            let (owner, resolver, ttl) = base_registry::get_record_by_key(&registry, utf8(FIRST_NODE));

            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(resolver == @0x0, 0);
            assert!(ttl == 0, 0);
            assert!(base_registrar::get_registration_detail(detail) == 21 + 365, 0);

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(controller);
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(registry);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = emoji::EInvalidLabel)]
    fun test_register_abort_if_register_short_domain_while_auction_is_happening() {
        let scenario = test_init();
        set_auction_config(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
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
                &mut controller,
                &mut registrar,
                &mut registry,
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
            test_scenario::return_shared(controller);
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(config);
            test_scenario::return_shared(registry);
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
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
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
                &mut controller,
                &mut registrar,
                &mut registry,
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
            test_scenario::return_shared(controller);
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(config);
            test_scenario::return_shared(registry);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let (name, url) = base_registrar::get_nft_fields(&nft);
            let (_, _, expiries) = base_registrar::get_registrar(&registrar);
            let registry = test_scenario::take_shared<Registry>(&mut scenario);

            assert!(controller::balance(&controller) == 1000000, 0);
            assert!(name == utf8(FIRST_NODE), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmWjyuoBW7gSxAqvkTYSNbXnNka6iUHNqs3ier9bN3g7Y2"),
                0
            ); // 2024
            assert!(table::length(expiries) == 1, 0);
            assert!(base_registry::get_records_len(&registry) == 1, 0);

            let detail = table::borrow(expiries, utf8(FIRST_LABEL));
            let (owner, resolver, ttl) = base_registry::get_record_by_key(&registry, utf8(FIRST_NODE));

            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(resolver == @0x0, 0);
            assert!(ttl == 0, 0);
            assert!(base_registrar::get_registration_detail(detail) == 51 + 365, 0);

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(controller);
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(registry);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_register_work_for_long_domain_if_auction_is_over() {
        let scenario = test_init();
        set_auction_config(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                220,
                0
            );
            let commitment = controller::test_make_commitment(
                &registrar,
                FIRST_LABEL,
                FIRST_USER_ADDRESS,
                FIRST_SECRET
            );

            controller::commit(
                &mut controller,
                commitment,
                &mut ctx,
            );

            test_scenario::return_shared(controller);
            test_scenario::return_shared(registrar);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
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
                &mut controller,
                &mut registrar,
                &mut registry,
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
            test_scenario::return_shared(controller);
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(config);
            test_scenario::return_shared(registry);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let (name, url) = base_registrar::get_nft_fields(&nft);
            let (_, _, expiries) = base_registrar::get_registrar(&registrar);
            let registry = test_scenario::take_shared<Registry>(&mut scenario);

            assert!(controller::balance(&controller) == 1000000, 0);
            assert!(name == utf8(FIRST_NODE), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmWjyuoBW7gSxAqvkTYSNbXnNka6iUHNqs3ier9bN3g7Y2"),
                0
            ); // 2024
            assert!(table::length(expiries) == 1, 0);
            assert!(base_registry::get_records_len(&registry) == 1, 0);

            let detail = table::borrow(expiries, utf8(FIRST_LABEL));
            let (owner, resolver, ttl) = base_registry::get_record_by_key(&registry, utf8(FIRST_NODE));

            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(resolver == @0x0, 0);
            assert!(ttl == 0, 0);
            assert!(base_registrar::get_registration_detail(detail) == 221 + 365, 0);

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(controller);
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(registry);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_register_work_for_short_domain_if_auction_is_over() {
        let scenario = test_init();
        set_auction_config(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                220,
                0
            );
            let commitment = controller::test_make_commitment(
                &registrar,
                AUCTIONED_LABEL,
                FIRST_USER_ADDRESS,
                FIRST_SECRET
            );

            controller::commit(
                &mut controller,
                commitment,
                &mut ctx,
            );

            test_scenario::return_shared(controller);
            test_scenario::return_shared(registrar);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
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
                &mut controller,
                &mut registrar,
                &mut registry,
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
            test_scenario::return_shared(controller);
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(config);
            test_scenario::return_shared(registry);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let (name, url) = base_registrar::get_nft_fields(&nft);
            let (_, _, expiries) = base_registrar::get_registrar(&registrar);
            let registry = test_scenario::take_shared<Registry>(&mut scenario);

            assert!(controller::balance(&controller) == 1000000, 0);
            assert!(name == utf8(AUCTIONED_NODE), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmWjyuoBW7gSxAqvkTYSNbXnNka6iUHNqs3ier9bN3g7Y2"),
                0
            ); // 2024
            assert!(table::length(expiries) == 1, 0);
            assert!(base_registry::get_records_len(&registry) == 1, 0);

            let detail = table::borrow(expiries, utf8(AUCTIONED_LABEL));
            let (owner, resolver, ttl) = base_registry::get_record_by_key(&registry, utf8(AUCTIONED_NODE));

            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(resolver == @0x0, 0);
            assert!(ttl == 0, 0);
            assert!(base_registrar::get_registration_detail(detail) == 221 + 365, 0);

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(controller);
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(registry);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_register_work_if_name_not_wait_for_being_finalized() {
        let scenario = test_init();
        set_auction_config(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                120,
                0
            );
            let commitment = controller::test_make_commitment(
                &registrar,
                FIRST_LABEL,
                FIRST_USER_ADDRESS,
                FIRST_SECRET
            );

            controller::commit(
                &mut controller,
                commitment,
                &mut ctx,
            );

            test_scenario::return_shared(controller);
            test_scenario::return_shared(registrar);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
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
                &mut controller,
                &mut registrar,
                &mut registry,
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
            test_scenario::return_shared(controller);
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(config);
            test_scenario::return_shared(registry);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let (name, url) = base_registrar::get_nft_fields(&nft);
            let (_, _, expiries) = base_registrar::get_registrar(&registrar);
            let registry = test_scenario::take_shared<Registry>(&mut scenario);

            assert!(controller::balance(&controller) == 1000000, 0);
            assert!(name == utf8(FIRST_NODE), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmWjyuoBW7gSxAqvkTYSNbXnNka6iUHNqs3ier9bN3g7Y2"),
                0
            ); // 2024
            assert!(table::length(expiries) == 1, 0);
            assert!(base_registry::get_records_len(&registry) == 1, 0);

            let detail = table::borrow(expiries, utf8(FIRST_LABEL));
            let (owner, resolver, ttl) = base_registry::get_record_by_key(&registry, utf8(FIRST_NODE));

            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(resolver == @0x0, 0);
            assert!(ttl == 0, 0);
            assert!(base_registrar::get_registration_detail(detail) == 121 + 365, 0);

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(controller);
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(registry);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = controller::ELabelUnAvailable)]
    fun test_register_abort_if_name_are_waiting_for_being_finalized() {
        let scenario = test_init();
        set_auction_config(&mut scenario);
        start_auction_util(&mut scenario, AUCTIONED_LABEL);
        let seal_bid = make_seal_bid(AUCTIONED_LABEL, FIRST_USER_ADDRESS, 1000, b"CnRGhPvfCu");
        new_bid_util(&mut scenario, seal_bid, 1100, FIRST_USER_ADDRESS);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let auction = test_scenario::take_shared<Auction>(&mut scenario);

            unseal_bid_util(
                &mut auction,
                110 + 1 + BIDDING_PERIOD,
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
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                120,
                0
            );
            let commitment = controller::test_make_commitment(
                &registrar,
                FIRST_LABEL,
                FIRST_USER_ADDRESS,
                FIRST_SECRET
            );

            controller::commit(
                &mut controller,
                commitment,
                &mut ctx,
            );

            test_scenario::return_shared(controller);
            test_scenario::return_shared(registrar);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
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
                &mut controller,
                &mut registrar,
                &mut registry,
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
            test_scenario::return_shared(controller);
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(config);
            test_scenario::return_shared(registry);
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
             let controller = test_scenario::take_shared<BaseController>(&mut scenario);
             let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);

             controller::set_disable(&admin_cap, &mut controller, true);

             test_scenario::return_to_sender(&mut scenario, admin_cap);
             test_scenario::return_shared(controller);
         };
         test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
         {
             let controller = test_scenario::take_shared<BaseController>(&mut scenario);
             let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
             let ctx = tx_context::new(
                 @0x0,
                 x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                 220,
                 0
             );
             let commitment = controller::test_make_commitment(
                 &registrar,
                 AUCTIONED_LABEL,
                 FIRST_USER_ADDRESS,
                 FIRST_SECRET
             );

             controller::commit(
                 &mut controller,
                 commitment,
                 &mut ctx,
             );

             test_scenario::return_shared(controller);
             test_scenario::return_shared(registrar);
         };
         test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
         {
             let controller = test_scenario::take_shared<BaseController>(&mut scenario);
             let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
             let registry = test_scenario::take_shared<Registry>(&mut scenario);
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
                 &mut controller,
                 &mut registrar,
                 &mut registry,
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
             test_scenario::return_shared(controller);
             test_scenario::return_shared(registrar);
             test_scenario::return_shared(config);
             test_scenario::return_shared(registry);
             test_scenario::return_shared(auction);
         };
         test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
         {
             let controller = test_scenario::take_shared<BaseController>(&mut scenario);
             let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
             let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
             let (name, url) = base_registrar::get_nft_fields(&nft);
             let (_, _, expiries) = base_registrar::get_registrar(&registrar);
             let registry = test_scenario::take_shared<Registry>(&mut scenario);

             assert!(controller::balance(&controller) == 1000000, 0);
             assert!(name == utf8(AUCTIONED_NODE), 0);
             assert!(
                 url == url::new_unsafe_from_bytes(b"ipfs://QmWjyuoBW7gSxAqvkTYSNbXnNka6iUHNqs3ier9bN3g7Y2"),
                 0
             ); // 2024
             assert!(table::length(expiries) == 1, 0);
             assert!(base_registry::get_records_len(&registry) == 1, 0);

             let detail = table::borrow(expiries, utf8(AUCTIONED_LABEL));
             let (owner, resolver, ttl) = base_registry::get_record_by_key(&registry, utf8(AUCTIONED_NODE));

             assert!(owner == FIRST_USER_ADDRESS, 0);
             assert!(resolver == @0x0, 0);
             assert!(ttl == 0, 0);
             assert!(base_registrar::get_registration_detail(detail) == 221 + 365, 0);

             test_scenario::return_to_sender(&mut scenario, nft);
             test_scenario::return_shared(controller);
             test_scenario::return_shared(registrar);
             test_scenario::return_shared(registry);
         };
         test_scenario::end(scenario);
     }

    #[test]
    fun test_register_abort_if_registration_is_enabled_again() {
        let scenario = test_init();
        set_auction_config(&mut scenario);

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);

            controller::set_disable(&admin_cap, &mut controller, true);

            test_scenario::return_to_sender(&mut scenario, admin_cap);
            test_scenario::return_shared(controller);
        };
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);

            controller::set_disable(&admin_cap, &mut controller, false);

            test_scenario::return_to_sender(&mut scenario, admin_cap);
            test_scenario::return_shared(controller);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                220,
                0
            );
            let commitment = controller::test_make_commitment(
                &registrar,
                AUCTIONED_LABEL,
                FIRST_USER_ADDRESS,
                FIRST_SECRET
            );

            controller::commit(
                &mut controller,
                commitment,
                &mut ctx,
            );

            test_scenario::return_shared(controller);
            test_scenario::return_shared(registrar);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let registry = test_scenario::take_shared<Registry>(&mut scenario);
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
                &mut controller,
                &mut registrar,
                &mut registry,
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
            test_scenario::return_shared(controller);
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(config);
            test_scenario::return_shared(registry);
            test_scenario::return_shared(auction);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let nft = test_scenario::take_from_sender<RegistrationNFT>(&mut scenario);
            let (name, url) = base_registrar::get_nft_fields(&nft);
            let (_, _, expiries) = base_registrar::get_registrar(&registrar);
            let registry = test_scenario::take_shared<Registry>(&mut scenario);

            assert!(controller::balance(&controller) == 1000000, 0);
            assert!(name == utf8(AUCTIONED_NODE), 0);
            assert!(
                url == url::new_unsafe_from_bytes(b"ipfs://QmWjyuoBW7gSxAqvkTYSNbXnNka6iUHNqs3ier9bN3g7Y2"),
                0
            ); // 2024
            assert!(table::length(expiries) == 1, 0);
            assert!(base_registry::get_records_len(&registry) == 1, 0);

            let detail = table::borrow(expiries, utf8(AUCTIONED_LABEL));
            let (owner, resolver, ttl) = base_registry::get_record_by_key(&registry, utf8(AUCTIONED_NODE));

            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(resolver == @0x0, 0);
            assert!(ttl == 0, 0);
            assert!(base_registrar::get_registration_detail(detail) == 221 + 365, 0);

            test_scenario::return_to_sender(&mut scenario, nft);
            test_scenario::return_shared(controller);
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(registry);
        };
        test_scenario::end(scenario);
    }

}
