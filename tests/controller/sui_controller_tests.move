#[test_only]
module suins::sui_controller_tests {

    use sui::coin;
    use sui::test_scenario::{Self, Scenario};
    use sui::tx_context;
    use sui::sui::SUI;
    use suins::sui_controller::{Self, SuiController};
    use suins::sui_registrar::{Self, SuiRegistrar};
    use suins::base_registry::{Self, Registry};
    use std::string;

    const SUINS_ADDRESS: address = @0xA001;
    const FIRST_USER_ADDRESS: address = @0xB001;
    const SECOND_USER_ADDRESS: address = @0xB002;
    const FIRST_RESOLVER_ADDRESS: address = @0xC001;
    const FIRST_LABEL: vector<u8> = b"eastagile";
    const SECOND_LABEL: vector<u8> = b"suinameservice";
    const FIRST_SECRET: vector<u8> = b"oKz=QdYd)]ryKB%";
    const SECOND_SECRET: vector<u8> = b"a9f8d4a8daeda2f35f02";

    fun init(): Scenario {
        let scenario = test_scenario::begin(&SUINS_ADDRESS);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            base_registry::test_init(ctx);
            sui_registrar::test_init(ctx);
            sui_controller::test_init(ctx);
        };
        scenario
    }

    fun make_commitment(scenario: &mut Scenario) {
        test_scenario::next_tx(scenario, &FIRST_USER_ADDRESS);
        {
            let controller_wrapper = test_scenario::take_shared<SuiController>(scenario);
            let controller = test_scenario::borrow_mut(&mut controller_wrapper);
            let registrar_wrapper = test_scenario::take_shared<SuiRegistrar>(scenario);
            assert!(sui_controller::commitment_len(controller) == 0, 0);
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                50,
                0
            );

            let commitment = sui_controller::test_make_commitment(FIRST_LABEL, FIRST_USER_ADDRESS, FIRST_SECRET);
            sui_controller::make_commitment_and_commit(
                controller,
                commitment,
                &mut ctx,
            );
            assert!(sui_controller::commitment_len(controller) == 1, 0);

            test_scenario::return_shared(scenario, controller_wrapper);
            test_scenario::return_shared(scenario, registrar_wrapper);
        };
    }

    #[test]
    fun test_make_commitment() {
        let scenario = init();

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let controller_wrapper = test_scenario::take_shared<SuiController>(&mut scenario);
            let controller = test_scenario::borrow_mut(&mut controller_wrapper);

            assert!(sui_controller::commitment_len(controller) == 0, 0);

            test_scenario::return_shared(&mut scenario, controller_wrapper);
        };
        make_commitment(&mut scenario);
        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let controller_wrapper = test_scenario::take_shared<SuiController>(&mut scenario);
            let controller = test_scenario::borrow_mut(&mut controller_wrapper);

            assert!(sui_controller::commitment_len(controller) == 1, 0);

            test_scenario::return_shared(&mut scenario, controller_wrapper);
        };
    }

    #[test]
    fun test_register() {
        let scenario = init();
        make_commitment(&mut scenario);

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let controller_wrapper =
                test_scenario::take_shared<SuiController>(&mut scenario);
            let controller = test_scenario::borrow_mut(&mut controller_wrapper);
            let registrar_wrapper =
                test_scenario::take_shared<SuiRegistrar>(&mut scenario);
            let registrar = test_scenario::borrow_mut(&mut registrar_wrapper);
            let registry_wrapper =
                test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);

            // simulate user wait for next epoch to call `register`
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                51,
                0
            );
            let coin = coin::mint_for_testing<SUI>(20001, &mut ctx);
            assert!(!sui_registrar::record_exists(registrar, string::utf8(FIRST_LABEL)), 0);

            sui_controller::register(
                controller,
                registrar,
                registry,
                FIRST_LABEL,
                FIRST_USER_ADDRESS,
                365,
                FIRST_SECRET,
                &mut coin,
                &mut ctx,
            );

            assert!(coin::value(&coin) == 10001, 0);

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(&mut scenario, controller_wrapper);
            test_scenario::return_shared(&mut scenario, registrar_wrapper);
            test_scenario::return_shared(&mut scenario, registry_wrapper);

        };

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let controller_wrapper = test_scenario::take_shared<SuiController>(&mut scenario);
            let controller = test_scenario::borrow_mut(&mut controller_wrapper);
            let registrar_wrapper = test_scenario::take_shared<SuiRegistrar>(&mut scenario);
            let registrar = test_scenario::borrow_mut(&mut registrar_wrapper);

            assert!(sui_controller::commitment_len(controller) == 0, 0);
            assert!(sui_registrar::record_exists(registrar, string::utf8(FIRST_LABEL)), 0);

            test_scenario::return_shared(&mut scenario, controller_wrapper);
            test_scenario::return_shared(&mut scenario, registrar_wrapper);
        };
    }

    #[test]
    #[expected_failure(abort_code = 302)]
    fun test_register_abort_with_wrong_label() {
        let scenario = init();
        make_commitment(&mut scenario);

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let controller_wrapper =
                test_scenario::take_shared<SuiController>(&mut scenario);
            let controller = test_scenario::borrow_mut(&mut controller_wrapper);
            let registrar_wrapper =
                test_scenario::take_shared<SuiRegistrar>(&mut scenario);
            let registrar = test_scenario::borrow_mut(&mut registrar_wrapper);
            let registry_wrapper =
                test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);

            // simulate user wait for next epoch to call `register`
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                51,
                0
            );
            let coin = coin::mint_for_testing<SUI>(20001, &mut ctx);
            assert!(!sui_registrar::record_exists(registrar, string::utf8(FIRST_LABEL)), 0);

            sui_controller::register(
                controller,
                registrar,
                registry,
                SECOND_LABEL,
                FIRST_USER_ADDRESS,
                365,
                FIRST_SECRET,
                &mut coin,
                &mut ctx,
            );

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(&mut scenario, controller_wrapper);
            test_scenario::return_shared(&mut scenario, registrar_wrapper);
            test_scenario::return_shared(&mut scenario, registry_wrapper);

        };
    }

    #[test]
    #[expected_failure(abort_code = 302)]
    fun test_register_abort_with_wrong_secret() {
        let scenario = init();
        make_commitment(&mut scenario);

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let controller_wrapper =
                test_scenario::take_shared<SuiController>(&mut scenario);
            let controller = test_scenario::borrow_mut(&mut controller_wrapper);
            let registrar_wrapper =
                test_scenario::take_shared<SuiRegistrar>(&mut scenario);
            let registrar = test_scenario::borrow_mut(&mut registrar_wrapper);
            let registry_wrapper =
                test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);

            // simulate user wait for next epoch to call `register`
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                51,
                0
            );
            let coin = coin::mint_for_testing<SUI>(20001, &mut ctx);
            assert!(!sui_registrar::record_exists(registrar, string::utf8(FIRST_LABEL)), 0);

            sui_controller::register(
                controller,
                registrar,
                registry,
                SECOND_LABEL,
                FIRST_USER_ADDRESS,
                365,
                SECOND_SECRET,
                &mut coin,
                &mut ctx,
            );

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(&mut scenario, controller_wrapper);
            test_scenario::return_shared(&mut scenario, registrar_wrapper);
            test_scenario::return_shared(&mut scenario, registry_wrapper);

        };
    }

    #[test]
    #[expected_failure(abort_code = 302)]
    fun test_register_abort_with_wrong_owner() {
        let scenario = init();
        make_commitment(&mut scenario);

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let controller_wrapper =
                test_scenario::take_shared<SuiController>(&mut scenario);
            let controller = test_scenario::borrow_mut(&mut controller_wrapper);
            let registrar_wrapper =
                test_scenario::take_shared<SuiRegistrar>(&mut scenario);
            let registrar = test_scenario::borrow_mut(&mut registrar_wrapper);
            let registry_wrapper =
                test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);

            // simulate user wait for next epoch to call `register`
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                51,
                0
            );
            let coin = coin::mint_for_testing<SUI>(20001, &mut ctx);
            assert!(!sui_registrar::record_exists(registrar, string::utf8(FIRST_LABEL)), 0);

            sui_controller::register(
                controller,
                registrar,
                registry,
                SECOND_LABEL,
                SECOND_USER_ADDRESS,
                365,
                FIRST_SECRET,
                &mut coin,
                &mut ctx,
            );

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(&mut scenario, controller_wrapper);
            test_scenario::return_shared(&mut scenario, registrar_wrapper);
            test_scenario::return_shared(&mut scenario, registry_wrapper);

        };
    }

    // #[test]
    // #[expected_failure(abort_code = 303)]
    // fun test_register_abort_if_called_too_early() {
    //     let scenario = init();
    //     make_commitment(&mut scenario, @0x0, @0x0);
    //
    //     test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
    //     {
    //         let controller_wrapper =
    //             test_scenario::take_shared<SuiController>(&mut scenario);
    //         let controller = test_scenario::borrow_mut(&mut controller_wrapper);
    //         let registrar_wrapper =
    //             test_scenario::take_shared<SuiRegistrar>(&mut scenario);
    //         let registrar = test_scenario::borrow_mut(&mut registrar_wrapper);
    //         let registry_wrapper =
    //             test_scenario::take_shared<Registry>(&mut scenario);
    //         let registry = test_scenario::borrow_mut(&mut registry_wrapper);
    //         // simulate user call `register` in the same epoch as `make_commitment_and_commit`
    //         let ctx = tx_context::new(
    //             @0x0,
    //             x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
    //             50,
    //             0
    //         );
    //         let coin = coin::mint_for_testing<SUI>(10000, &mut ctx);
    //
    //         sui_controller::register(
    //             controller,
    //             registrar,
    //             registry,
    //             FIRST_LABEL,
    //             FIRST_USER_ADDRESS,
    //             365,
    //             option::none(),
    //             SECRET,
    //             &mut coin,
    //             &mut ctx,
    //         );
    //
    //         coin::destroy_for_testing(coin);
    //         test_scenario::return_shared(&mut scenario, controller_wrapper);
    //         test_scenario::return_shared(&mut scenario, registrar_wrapper);
    //         test_scenario::return_shared(&mut scenario, registry_wrapper);
    //     };
    //
    //     test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
    //     {
    //         let controller_wrapper = test_scenario::take_shared<SuiController>(&mut scenario);
    //         let controller = test_scenario::borrow_mut(&mut controller_wrapper);
    //
    //         assert!(sui_controller::commitment_len(controller) == 0, 0);
    //
    //         test_scenario::return_shared(&mut scenario, controller_wrapper);
    //     };
    // }

    #[test]
    #[expected_failure(abort_code = 304)]
    fun test_register_abort_if_called_too_late() {
        let scenario = init();
        make_commitment(&mut scenario);

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let controller_wrapper =
                test_scenario::take_shared<SuiController>(&mut scenario);
            let controller = test_scenario::borrow_mut(&mut controller_wrapper);
            let registrar_wrapper =
                test_scenario::take_shared<SuiRegistrar>(&mut scenario);
            let registrar = test_scenario::borrow_mut(&mut registrar_wrapper);
            let registry_wrapper =
                test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);
            // simulate user call `register` in the same epoch as `make_commitment_and_commit`
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                600,
                0
            );
            let coin = coin::mint_for_testing<SUI>(20000, &mut ctx);

            sui_controller::register(
                controller,
                registrar,
                registry,
                FIRST_LABEL,
                FIRST_USER_ADDRESS,
                365,
                FIRST_SECRET,
                &mut coin,
                &mut ctx,
            );

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(&mut scenario, controller_wrapper);
            test_scenario::return_shared(&mut scenario, registrar_wrapper);
            test_scenario::return_shared(&mut scenario, registry_wrapper);
        };

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let controller_wrapper = test_scenario::take_shared<SuiController>(&mut scenario);
            let controller = test_scenario::borrow_mut(&mut controller_wrapper);

            assert!(sui_controller::commitment_len(controller) == 0, 0);

            test_scenario::return_shared(&mut scenario, controller_wrapper);
        };
    }

    #[test]
    #[expected_failure(abort_code = 305)]
    fun test_register_abort_if_not_enough_fee() {
        let scenario = init();
        make_commitment(&mut scenario);

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let controller_wrapper =
                test_scenario::take_shared<SuiController>(&mut scenario);
            let controller = test_scenario::borrow_mut(&mut controller_wrapper);
            let registrar_wrapper =
                test_scenario::take_shared<SuiRegistrar>(&mut scenario);
            let registrar = test_scenario::borrow_mut(&mut registrar_wrapper);
            let registry_wrapper =
                test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);

            // simulate user wait for next epoch to call `register`
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                52,
                0
            );
            let coin = coin::mint_for_testing<SUI>(900, &mut ctx);

            sui_controller::register(
                controller,
                registrar,
                registry,
                FIRST_LABEL,
                FIRST_USER_ADDRESS,
                365,
                FIRST_SECRET,
                &mut coin,
                &mut ctx,
            );

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(&mut scenario, controller_wrapper);
            test_scenario::return_shared(&mut scenario, registrar_wrapper);
            test_scenario::return_shared(&mut scenario, registry_wrapper);
        };
    }

    #[test]
    fun register_with_config() {
        let scenario = init();
        make_commitment(&mut scenario);

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let controller_wrapper =
                test_scenario::take_shared<SuiController>(&mut scenario);
            let controller = test_scenario::borrow_mut(&mut controller_wrapper);
            let registrar_wrapper =
                test_scenario::take_shared<SuiRegistrar>(&mut scenario);
            let registrar = test_scenario::borrow_mut(&mut registrar_wrapper);
            let registry_wrapper =
                test_scenario::take_shared<Registry>(&mut scenario);
            let registry = test_scenario::borrow_mut(&mut registry_wrapper);

            // simulate user wait for next epoch to call `register`
            let ctx = tx_context::new(
                @0x0,
                x"3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532",
                51,
                0
            );
            let coin = coin::mint_for_testing<SUI>(10001, &mut ctx);
            assert!(!sui_registrar::record_exists(registrar, string::utf8(FIRST_LABEL)), 0);

            sui_controller::register_with_config(
                controller,
                registrar,
                registry,
                FIRST_LABEL,
                FIRST_USER_ADDRESS,
                365,
                FIRST_SECRET,
                FIRST_RESOLVER_ADDRESS,
                @0x0,
                &mut coin,
                &mut ctx,
            );

            assert!(coin::value(&coin) == 1, 0);

            coin::destroy_for_testing(coin);
            test_scenario::return_shared(&mut scenario, controller_wrapper);
            test_scenario::return_shared(&mut scenario, registrar_wrapper);
            test_scenario::return_shared(&mut scenario, registry_wrapper);

        };

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let controller_wrapper = test_scenario::take_shared<SuiController>(&mut scenario);
            let controller = test_scenario::borrow_mut(&mut controller_wrapper);
            let registrar_wrapper = test_scenario::take_shared<SuiRegistrar>(&mut scenario);
            let registrar = test_scenario::borrow_mut(&mut registrar_wrapper);

            assert!(sui_controller::commitment_len(controller) == 0, 0);
            assert!(sui_registrar::record_exists(registrar, string::utf8(FIRST_LABEL)), 0);

            test_scenario::return_shared(&mut scenario, controller_wrapper);
            test_scenario::return_shared(&mut scenario, registrar_wrapper);
        };
    }
}
