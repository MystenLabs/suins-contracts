#[test_only]
module suins::sui_controller_tests {

    use sui::test_scenario::{Self, Scenario};
    use suins::sui_controller::{Self, SuiController};

    const SUINS_ADDRESS: address = @0xA001;
    const FIRST_USER_ADDRESS: address = @0xB001;
    const FIRST_RESOLVER_ADDRESS: address = @0xC001;

    fun init(): Scenario {
        let scenario = test_scenario::begin(&SUINS_ADDRESS);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            sui_controller::test_init(ctx);
        };
        scenario
    }

    #[test]
    fun test_make_commitment() {
        let scenario = init();

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let controller_wrapper = test_scenario::take_shared<SuiController>(&mut scenario);
            let controller = test_scenario::borrow_mut(&mut controller_wrapper);

            assert!(sui_controller::len(controller) == 0, 0);

            test_scenario::return_shared(&mut scenario, controller_wrapper);
        };

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let controller_wrapper = test_scenario::take_shared<SuiController>(&mut scenario);
            let controller = test_scenario::borrow_mut(&mut controller_wrapper);

            let name = b"eastagile";
            let secret = b"oKz=QdYd)]ryKB%";
            sui_controller::make_commitment(
                controller,
                name,
                FIRST_USER_ADDRESS,
                secret,
                test_scenario::ctx(&mut scenario),
            );

            test_scenario::return_shared(&mut scenario, controller_wrapper);
        };

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let controller_wrapper = test_scenario::take_shared<SuiController>(&mut scenario);
            let controller = test_scenario::borrow_mut(&mut controller_wrapper);

            assert!(sui_controller::len(controller) == 1, 0);

            test_scenario::return_shared(&mut scenario, controller_wrapper);
        };
    }

    #[test]
    #[expected_failure(abort_code = 301)]
    fun test_make_commitment_with_config_abort_if_only_resolver_zero() {
        let scenario = init();

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let controller_wrapper = test_scenario::take_shared<SuiController>(&mut scenario);
            let controller = test_scenario::borrow_mut(&mut controller_wrapper);

            assert!(sui_controller::len(controller) == 0, 0);

            test_scenario::return_shared(&mut scenario, controller_wrapper);
        };

        test_scenario::next_tx(&mut scenario, &FIRST_USER_ADDRESS);
        {
            let controller_wrapper = test_scenario::take_shared<SuiController>(&mut scenario);
            let controller = test_scenario::borrow_mut(&mut controller_wrapper);

            let name = b"eastagile";
            let secret = b"oKz=QdYd)]ryKB%";
            sui_controller::make_commitment_with_config(
                controller,
                name,
                FIRST_USER_ADDRESS,
                secret,
                @0x0,
                @0x1,
                test_scenario::ctx(&mut scenario),
            );

            test_scenario::return_shared(&mut scenario, controller_wrapper);
        };
    }
}