#[test_only]
module suins::controller_tests {

    use sui::coin::{Self, Coin};
    use sui::test_scenario::{Self, Scenario};
    use sui::tx_context;
    use sui::sui::SUI;
    use suins::controller::{Self, BaseController};
    use suins::base_registrar::{Self, BaseRegistrar, TLDsList};
    use suins::base_registry::{Self, Registry, AdminCap};
    use std::string;
    use suins::configuration::{Self, Configuration};
    use std::option::Option;
    use std::option;

    const SUINS_ADDRESS: address = @0xA001;
    const FIRST_USER_ADDRESS: address = @0xB001;
    const SECOND_USER_ADDRESS: address = @0xB002;
    const FIRST_RESOLVER_ADDRESS: address = @0xC001;
    const FIRST_LABEL: vector<u8> = b"eastagile-123";
    const SECOND_LABEL: vector<u8> = b"suinameservice";
    const THIRD_LABEL: vector<u8> = b"thirdsuinameservice";
    const FIRST_SECRET: vector<u8> = b"oKz=QdYd)]ryKB%";
    const SECOND_SECRET: vector<u8> = b"a9f8d4a8daeda2f35f02";
    const FIRST_INVALID_LABEL: vector<u8> = b"east.agile";
    const SECOND_INVALID_LABEL: vector<u8> = b"ea";
    const THIRD_INVALID_LABEL: vector<u8> = b"zkaoxpcbarubhtxkunajudxezneyczueajbggrynkwbepxjqjxrigrtgglhfjpax";
    const FOURTH_INVALID_LABEL: vector<u8> = b"-eastagile";
    const FIFTH_INVALID_LABEL: vector<u8> = b"east/?agile";
    const REFERRAL_CODE: vector<u8> = b"X43kS8";

    fun test_init(): Scenario {
        let scenario = test_scenario::begin(SUINS_ADDRESS);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            base_registry::test_init(ctx);
            base_registrar::test_init(ctx);
            controller::test_init(ctx);
            configuration::test_init(ctx);
        };
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let tlds_list = test_scenario::take_shared<TLDsList>(&mut scenario);
            let config = test_scenario::take_shared<Configuration>(&mut scenario);
            base_registrar::new_tld(&admin_cap, &mut tlds_list,b"sui", test_scenario::ctx(&mut scenario));
            base_registrar::new_tld(&admin_cap, &mut tlds_list,b"addr.reverse", test_scenario::ctx(&mut scenario));
            base_registrar::new_tld(&admin_cap, &mut tlds_list,b"move", test_scenario::ctx(&mut scenario));
            configuration::new_referral_code(&admin_cap, &mut config, REFERRAL_CODE, 10, FIRST_USER_ADDRESS);
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
            controller::make_commitment_and_commit(
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
            let controller =
                test_scenario::take_shared<BaseController>(scenario);
            let registrar =
                test_scenario::take_shared<BaseRegistrar>(scenario);
            let registry =
                test_scenario::take_shared<Registry>(scenario);
            let image =
                test_scenario::take_shared<Configuration>(scenario);
            // simulate user wait for next epoch to call `register`
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                51,
                0
            );
            let coin = coin::mint_for_testing<SUI>(1000001, &mut ctx);
            assert!(!base_registrar::record_exists(&registrar, string::utf8(FIRST_LABEL)), 0);

            controller::register_with_config(
                &mut controller,
                &mut registrar,
                &mut registry,
                &image,
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
            test_scenario::return_shared(image);
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
            let controller =
                test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar =
                test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let registry =
                test_scenario::take_shared<Registry>(&mut scenario);
            let image =
                test_scenario::take_shared<Configuration>(&mut scenario);

            // simulate user wait for next epoch to call `register`
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                51,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);
            assert!(!base_registrar::record_exists(&registrar, string::utf8(FIRST_LABEL)), 0);

            controller::register(
                &mut controller,
                &mut registrar,
                &mut registry,
                &image,
                FIRST_LABEL,
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
            test_scenario::return_shared(image);
            test_scenario::return_shared(registry);

        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            assert!(controller::commitment_len(&controller) == 0, 0);
            assert!(base_registrar::record_exists(&registrar, string::utf8(FIRST_LABEL)), 0);
            test_scenario::return_shared(controller);
            test_scenario::return_shared(registrar);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = controller::ECommitmentNotExists)]
    fun test_register_abort_with_wrong_label() {
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
            let image =
                test_scenario::take_shared<Configuration>(&mut scenario);

            // simulate user wait for next epoch to call `register`
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                51,
                0
            );
            let coin = coin::mint_for_testing<SUI>(1000001, &mut ctx);
            assert!(!base_registrar::record_exists(&registrar, string::utf8(FIRST_LABEL)), 0);

            controller::register(
                &mut controller,
                &mut registrar,
                &mut registry,
                &image,
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
            test_scenario::return_shared(image);

        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = controller::ECommitmentNotExists)]
    fun test_register_abort_with_wrong_secret() {
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
            let image =
                test_scenario::take_shared<Configuration>(&mut scenario);

            // simulate user wait for next epoch to call `register`
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                51,
                0
            );
            let coin = coin::mint_for_testing<SUI>(1000001, &mut ctx);
            assert!(!base_registrar::record_exists(&registrar, string::utf8(FIRST_LABEL)), 0);

            controller::register(
                &mut controller,
                &mut registrar,
                &mut registry,
                &image,
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
            test_scenario::return_shared(image);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = controller::ECommitmentNotExists)]
    fun test_register_abort_with_wrong_owner() {
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
            let image =
                test_scenario::take_shared<Configuration>(&mut scenario);
            // simulate user wait for next epoch to call `register`
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                51,
                0
            );
            let coin = coin::mint_for_testing<SUI>(1000001, &mut ctx);
            assert!(!base_registrar::record_exists(&registrar, string::utf8(FIRST_LABEL)), 0);

            controller::register(
                &mut controller,
                &mut registrar,
                &mut registry,
                &image,
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
            test_scenario::return_shared(image);
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
            let controller =
                test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar =
                test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let registry =
                test_scenario::take_shared<Registry>(&mut scenario);
            let image =
                test_scenario::take_shared<Configuration>(&mut scenario);

            // simulate user call `register` in the same epoch as `make_commitment_and_commit`
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                600,
                0
            );
            let coin = coin::mint_for_testing<SUI>(1000000, &mut ctx);

            controller::register(
                &mut controller,
                &mut registrar,
                &mut registry,
                &image,
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
            test_scenario::return_shared(image);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            assert!(controller::commitment_len(&controller) == 0, 0);
            test_scenario::return_shared(controller);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = controller::ENotEnoughFee)]
    fun test_register_abort_if_not_enough_fee() {
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
            let image =
                test_scenario::take_shared<Configuration>(&mut scenario);

            // simulate user wait for next epoch to call `register`
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                52,
                0
            );
            let coin = coin::mint_for_testing<SUI>(5, &mut ctx);

            controller::register(
                &mut controller,
                &mut registrar,
                &mut registry,
                &image,
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
            test_scenario::return_shared(image);
            test_scenario::return_shared(registry);
        };
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = controller::ELabelUnAvailable)]
    fun test_register_abort_if_label_was_registered() {
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
            let image =
                test_scenario::take_shared<Configuration>(&mut scenario);

            // simulate user wait for next epoch to call `register`
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                51,
                0
            );
            let coin = coin::mint_for_testing<SUI>(1000001, &mut ctx);

            controller::register(
                &mut controller,
                &mut registrar,
                &mut registry,
                &image,
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
            test_scenario::return_shared(image);
        };

        make_commitment(&mut scenario, option::none());
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let controller =
                test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar =
                test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let registry =
                test_scenario::take_shared<Registry>(&mut scenario);
            let image =
                test_scenario::take_shared<Configuration>(&mut scenario);

            // simulate user wait for next epoch to call `register`
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                51,
                0
            );
            let coin = coin::mint_for_testing<SUI>(1000001, &mut ctx);

            controller::register(
                &mut controller,
                &mut registrar,
                &mut registry,
                &image,
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
            test_scenario::return_shared(image);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_register_with_config() {
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
            let image =
                test_scenario::take_shared<Configuration>(&mut scenario);
            // simulate user wait for next epoch to call `register`
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                51,
                0
            );
            let coin = coin::mint_for_testing<SUI>(4000001, &mut ctx);
            assert!(!base_registrar::record_exists(&registrar, string::utf8(FIRST_LABEL)), 0);
            controller::register_with_config(
                &mut controller,
                &mut registrar,
                &mut registry,
                &image,
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
            test_scenario::return_shared(image);
            test_scenario::return_shared(registry);
        };

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            assert!(controller::commitment_len(&controller) == 0, 0);
            assert!(base_registrar::record_exists(&registrar, string::utf8(FIRST_LABEL)), 0);
            test_scenario::return_shared(controller);
            test_scenario::return_shared(registrar);
        };

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            assert!(!test_scenario::has_most_recent_for_sender<Coin<SUI>>(&mut scenario), 0);
        };

        // withdraw
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            assert!(controller::balance(&controller) == 2000000, 0);
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

    #[test, expected_failure(abort_code = controller::EInvalidLabel)]
    fun test_register_with_config_abort_with_too_short_label() {
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
            let image =
                test_scenario::take_shared<Configuration>(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(10001, test_scenario::ctx(&mut scenario));

            controller::register_with_config(
                &mut controller,
                &mut registrar,
                &mut registry,
                &image,
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
            test_scenario::return_shared(image);
            test_scenario::return_shared(registry);
        };

        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = controller::EInvalidLabel)]
    fun test_register_with_config_abort_with_too_long_label() {
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
            let image =
                test_scenario::take_shared<Configuration>(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(10001, test_scenario::ctx(&mut scenario));

            controller::register_with_config(
                &mut controller,
                &mut registrar,
                &mut registry,
                &image,
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
            test_scenario::return_shared(image);
            test_scenario::return_shared(registry);
        };

        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = controller::EInvalidLabel)]
    fun test_register_with_config_abort_if_label_starts_with_hyphen() {
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
            let image =
                test_scenario::take_shared<Configuration>(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(10001, test_scenario::ctx(&mut scenario));

            controller::register_with_config(
                &mut controller,
                &mut registrar,
                &mut registry,
                &image,
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
            test_scenario::return_shared(image);
            test_scenario::return_shared(registry);
        };

        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = controller::EInvalidLabel)]
    fun test_register_with_config_abort_with_invalid_label() {
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
            let image =
                test_scenario::take_shared<Configuration>(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(10001, test_scenario::ctx(&mut scenario));

            controller::register_with_config(
                &mut controller,
                &mut registrar,
                &mut registry,
                &image,
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
            test_scenario::return_shared(image);
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

    #[test, expected_failure(abort_code = controller::EInvalidLabel)]
    fun test_register_abort_if_label_is_invalid() {
        let scenario = test_init();

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar = test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            assert!(controller::commitment_len(&controller) == 0, 0);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                50,
                0
            );

            let commitment = controller::test_make_commitment(&registrar, FIRST_INVALID_LABEL, FIRST_USER_ADDRESS, FIRST_SECRET);
            controller::make_commitment_and_commit(
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
            let controller =
                test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar =
                test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let registry =
                test_scenario::take_shared<Registry>(&mut scenario);
            let image =
                test_scenario::take_shared<Configuration>(&mut scenario);

            // simulate user wait for next epoch to call `register`
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
                &image,
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
            test_scenario::return_shared(image);
            test_scenario::return_shared(registry);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_renew() {
        let scenario = test_init();
        register(&mut scenario);

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let controller =
                test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar =
                test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let ctx = test_scenario::ctx(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(2000001, ctx);
            assert!(base_registrar::name_expires(&registrar, string::utf8(FIRST_LABEL)) == 416, 0);

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
        test_scenario::end(scenario);
    }

    #[test, expected_failure(abort_code = base_registrar::ELabelNotExists)]
    fun test_renew_abort_if_label_not_exists() {
        let scenario = test_init();

        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let controller =
                test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar =
                test_scenario::take_shared<BaseRegistrar>(&mut scenario);
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
            let controller =
                test_scenario::take_shared<BaseController>(&mut scenario);
            
            let registrar =
                test_scenario::take_shared<BaseRegistrar>(&mut scenario);
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
            let controller =
                test_scenario::take_shared<BaseController>(&mut scenario);
            
            let registrar =
                test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let ctx = test_scenario::ctx(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(4, ctx);
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

    #[test]
    fun test_set_default_resolver() {
        let scenario = test_init();

        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let controller = test_scenario::take_shared<BaseController>(&mut scenario);
            let resolver = controller::get_default_resolver(&controller);
            assert!(resolver == @0x0, 0);
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
            let resolver = controller::get_default_resolver(&controller);
            assert!(resolver == FIRST_RESOLVER_ADDRESS, 0);
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
            assert!(controller::commitment_len(&controller) == 0, 0);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                10,
                0
            );

            let commitment = controller::test_make_commitment(&registrar, FIRST_LABEL, FIRST_USER_ADDRESS, FIRST_SECRET);
            controller::make_commitment_and_commit(
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
            controller::make_commitment_and_commit(
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
            controller::make_commitment_and_commit(
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
            controller::make_commitment_and_commit(
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
            let controller =
                test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar =
                test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let registry =
                test_scenario::take_shared<Registry>(&mut scenario);
            let image =
                test_scenario::take_shared<Configuration>(&mut scenario);
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
                &image,
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
            test_scenario::return_shared(image);
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
            let controller =
                test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar =
                test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let registry =
                test_scenario::take_shared<Registry>(&mut scenario);
            let image =
                test_scenario::take_shared<Configuration>(&mut scenario);

            // simulate user wait for next epoch to call `register`
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                51,
                0
            );
            let coin = coin::mint_for_testing<SUI>(3000000, &mut ctx);
            assert!(!base_registrar::record_exists(&registrar, string::utf8(FIRST_LABEL)), 0);
            controller::register_with_referral_code(
                &mut controller,
                &mut registrar,
                &mut registry,
                &image,
                FIRST_LABEL,
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                &mut coin,
                REFERRAL_CODE,
                &mut ctx,
            );
            assert!(coin::value(&coin) == 1000000, 0);
            coin::destroy_for_testing(coin);
            test_scenario::return_shared(controller);
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(image);
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
            let controller =
                test_scenario::take_shared<BaseController>(&mut scenario);
            let registrar =
                test_scenario::take_shared<BaseRegistrar>(&mut scenario);
            let registry =
                test_scenario::take_shared<Registry>(&mut scenario);
            let image =
                test_scenario::take_shared<Configuration>(&mut scenario);
            // simulate user wait for next epoch to call `register`
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                51,
                0
            );
            let coin = coin::mint_for_testing<SUI>(4000000, &mut ctx);
            assert!(!base_registrar::record_exists(&registrar, string::utf8(FIRST_LABEL)), 0);
            controller::register_with_config_and_referral_code(
                &mut controller,
                &mut registrar,
                &mut registry,
                &image,
                FIRST_LABEL,
                FIRST_USER_ADDRESS,
                2,
                FIRST_SECRET,
                FIRST_RESOLVER_ADDRESS,
                &mut coin,
                REFERRAL_CODE,
                &mut ctx,
            );
            assert!(coin::value(&coin) == 2000000, 0);
            coin::destroy_for_testing(coin);
            test_scenario::return_shared(controller);
            test_scenario::return_shared(registrar);
            test_scenario::return_shared(image);
            test_scenario::return_shared(registry);

        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_apply_discount() {
        let scenario = test_init();
        test_scenario::next_tx(&mut scenario, SECOND_USER_ADDRESS);
        {
            let config =
                test_scenario::take_shared<Configuration>(&mut scenario);
            // simulate user wait for next epoch to call `register`
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                51,
                0
            );
            let coin = coin::mint_for_testing<SUI>(4000000, &mut ctx);
            controller::apply_referral_code_test(&config, &mut coin,4000000, REFERRAL_CODE, &mut ctx);
            assert!(coin::value(&coin) == 3600000, 0);
            coin::destroy_for_testing(coin);

            let coin = coin::mint_for_testing<SUI>(909, &mut ctx);
            controller::apply_referral_code_test(&config, &mut coin, 909, REFERRAL_CODE, &mut ctx);
            assert!(coin::value(&coin) == 810, 0);
            coin::destroy_for_testing(coin);

            test_scenario::return_shared(config);
        };
        test_scenario::end(scenario);
    }
}
