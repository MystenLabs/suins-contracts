// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

#[test_only]
module discord::discord_tests {
    use sui::test_scenario::{Self, Scenario};
    use discord::discord::{Self, Discord, DiscordCap};
    use discord::test_payloads::{Self as tp};

    const ADMIN_ADDRESS: address = @0xA001;

    fun test_init(): Scenario {
        let mut scenario_val = test_scenario::begin(ADMIN_ADDRESS);
        let scenario = &mut scenario_val;
        {
            discord::init_for_testing(scenario.ctx());
        };
        {
            scenario.next_tx(ADMIN_ADDRESS);
            let mut discord = scenario.take_shared<Discord>();
            // get admin cap
            let cap = test_scenario::take_from_sender<DiscordCap>(scenario);

            // prepare discord roles
            cap.add_discord_role(&mut discord, tp::get_nth_role(0), tp::get_nth_role_percentage(0));
            cap.add_discord_role(&mut discord, tp::get_nth_role(1), tp::get_nth_role_percentage(1));
            cap.add_discord_role(&mut discord, tp::get_nth_role(2), tp::get_nth_role_percentage(2));
            cap.add_discord_role(&mut discord, tp::get_nth_role(3), tp::get_nth_role_percentage(3));
            cap.add_discord_role(&mut discord, tp::get_nth_role(4), tp::get_nth_role_percentage(4));

            cap.set_public_key(&mut discord, tp::get_public_key());

            scenario.return_to_sender(cap);
            test_scenario::return_shared(discord);
        };
        scenario_val
    }

    fun prepare_data(scenario: &mut Scenario) {
        scenario.next_tx(tp::get_nth_user(0));
        let mut discord = scenario.take_shared<Discord>();

        discord.attach_roles(tp::get_nth_attach_roles_signature(0), tp::get_nth_discord_id(0), vector[tp::get_nth_role(0), tp::get_nth_role(1)]);
        discord.attach_roles(tp::get_nth_attach_roles_signature(2), tp::get_nth_discord_id(1), vector[tp::get_nth_role(2), tp::get_nth_role(3)]);

        discord.set_address(tp::get_nth_address_mapping_signature(0), tp::get_nth_discord_id(0), tp::get_nth_user(0));
        discord.set_address(tp::get_nth_address_mapping_signature(1), tp::get_nth_discord_id(1), tp::get_nth_user(1));
        test_scenario::return_shared(discord);
    }

    // test all the flows!
    #[test]
    fun test_e2e() {
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;
        // prepare data and data mappings!
        prepare_data(scenario);
        {
            scenario.next_tx(tp::get_nth_user(0));
            let mut discord = scenario.take_shared<Discord>();
            discord.claim_coupon_internal(tp::get_nth_discord_id(0), 50, scenario.ctx());
            test_scenario::return_shared(discord);
        };
        {
            scenario.next_tx(tp::get_nth_user(1));
            let mut discord = scenario.take_shared<Discord>();
            discord.claim_coupon_internal(tp::get_nth_discord_id(1), 100, scenario.ctx());

            test_scenario::return_shared(discord);
        };
        {
            scenario.next_tx(tp::get_nth_user(1));
            let mut discord = scenario.take_shared<Discord>();
            discord.claim_coupon_internal(tp::get_nth_discord_id(1), 40, scenario.ctx());
    

            test_scenario::return_shared(discord);
        };
        {
            scenario.next_tx(tp::get_nth_user(1));
            let discord = scenario.take_shared<Discord>();
            let member = discord.member(tp::get_nth_discord_id(1));
            assert!(member.available_points() == 10, 0);
            test_scenario::return_shared(discord);
        };

        scenario_val.end();
    }

    #[test, expected_failure(abort_code=::discord::discord::ESignatureNotMatch)]
    fun attach_roles_to_wrong_discord_id_failure() {
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;
        {
            scenario.next_tx(tp::get_nth_user(0));
            let mut discord = scenario.take_shared<Discord>();
            discord.attach_roles(tp::get_nth_attach_roles_signature(0), tp::get_nth_discord_id(1), vector[tp::get_nth_role(0), tp::get_nth_role(1)]);
            test_scenario::return_shared(discord);
        };
        scenario_val.end();
    }

    #[test, expected_failure(abort_code=::discord::discord::ESignatureNotMatch)]
    fun attach_invalid_roles_failure() {
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;
        {
            scenario.next_tx(tp::get_nth_user(0));
            let mut discord = scenario.take_shared<Discord>();
            discord.attach_roles(tp::get_nth_attach_roles_signature(0), tp::get_nth_discord_id(0), vector[tp::get_nth_role(1), tp::get_nth_role(2)]);
            test_scenario::return_shared(discord);
        };
        scenario_val.end();
    }

    #[test, expected_failure(abort_code=::discord::discord::ERoleAlreadyAssigned)]
    fun try_to_attach_role_twice_failure() {
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;
        {
            scenario.next_tx(tp::get_nth_user(0));
            let mut discord = scenario.take_shared<Discord>();

            discord.attach_roles(tp::get_nth_attach_roles_signature(0), tp::get_nth_discord_id(0), vector[tp::get_nth_role(0), tp::get_nth_role(1)]);
            discord.attach_roles(tp::get_nth_attach_roles_signature(1), tp::get_nth_discord_id(0), vector[tp::get_nth_role(1), tp::get_nth_role(3)]);
    
            test_scenario::return_shared(discord);
        };
        // let scenario = &mut scenario_val;
        scenario_val.end();
    }

    #[test, expected_failure(abort_code=::discord::discord::ERoleNotExists)]
    fun try_to_attach_non_existing_role_failure() {
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;
        {
            scenario.next_tx(tp::get_nth_user(0));
            let mut discord = scenario.take_shared<Discord>();

            discord.attach_roles(tp::get_nth_attach_roles_signature(3), tp::get_nth_discord_id(1), vector[5]);
            test_scenario::return_shared(discord);
        };
        // let scenario = &mut scenario_val;
        scenario_val.end();
    }

    #[test, expected_failure(abort_code=::discord::discord::ESignatureNotMatch)]
    fun try_to_attach_address_to_invalid_discord_id_failure() {
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;
        {
            scenario.next_tx(tp::get_nth_user(0));
            let mut discord = scenario.take_shared<Discord>();

            discord.set_address(tp::get_nth_address_mapping_signature(0), tp::get_nth_discord_id(0), tp::get_nth_user(1));
            test_scenario::return_shared(discord);
        };
        // let scenario = &mut scenario_val;
        scenario_val.end();
    }

    #[test, expected_failure(abort_code=::discord::discord::ESignatureNotMatch)]
    fun try_to_reuse_signature_failure() {
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;
        prepare_data(scenario);
        {
            scenario.next_tx(tp::get_nth_user(0));
            let mut discord = scenario.take_shared<Discord>();

            discord.set_address(tp::get_nth_address_mapping_signature(0), tp::get_nth_discord_id(0), tp::get_nth_user(0));
            test_scenario::return_shared(discord);
        };
        scenario_val.end();
    }

    #[test, expected_failure(abort_code=::discord::discord::ENotEnoughPoints)]
    fun claim_more_points_than_available_failure() {
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;
        prepare_data(scenario);
        {
            scenario.next_tx(tp::get_nth_user(0));
            let mut discord = scenario.take_shared<Discord>();
            discord.claim_coupon_internal(tp::get_nth_discord_id(0), 60, scenario.ctx());

            test_scenario::return_shared(discord);
        };
        scenario_val.end();
    }

    #[test, expected_failure(abort_code=::discord::discord::ENotEnoughPoints)]
    fun claim_more_points_in_two_steps_failure() {
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;
        prepare_data(scenario);
        {
            scenario.next_tx(tp::get_nth_user(0));
            let mut discord = scenario.take_shared<Discord>();
            discord.claim_coupon_internal(tp::get_nth_discord_id(0), 45, scenario.ctx());
            test_scenario::return_shared(discord);
        };
        {
            scenario.next_tx(tp::get_nth_user(0));
            let mut discord = scenario.take_shared<Discord>();
            discord.claim_coupon_internal(tp::get_nth_discord_id(0), 6, scenario.ctx());
        };
        abort 1337
    }


    #[test, expected_failure(abort_code=::discord::discord::EInvalidDiscount)]
    fun claim_with_invalid_percentage_failure() {
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;
        prepare_data(scenario);
        scenario.next_tx(tp::get_nth_user(1));
        let mut discord = scenario.take_shared<Discord>();
        discord.claim_coupon_internal(tp::get_nth_discord_id(1), 110, scenario.ctx());

        abort 1337
    }

    #[test, expected_failure(abort_code=::discord::discord::EAddressNoMapping)]
    fun claim_with_non_existing_user_failure() {
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;
        prepare_data(scenario);

        scenario.next_tx(tp::get_nth_user(1));
        let mut discord = scenario.take_shared<Discord>();
        discord.claim_coupon_internal(tp::get_nth_discord_id(0), 50, scenario.ctx());

        abort 1337
    }
}
