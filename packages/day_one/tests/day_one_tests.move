#[test_only]
module suins::day_one_tests {
    // use std::debug::{print};
    use std::string::{utf8, String};
    use sui::clock::{Self, Clock};
    use sui::test_scenario::{Self, Scenario, ctx};

    use suins::suins_registration::{Self as nft, SuinsRegistration};
    use suins::domain;
    use suins::registry;
    use suins::suins::{Self, SuiNS, AdminCap};

    use day_one::day_one::{Self, DayOne};
    use day_one::bogo::{Self, BogoApp};

    const SUINS_ADDRESS: address = @0xA001;
    const USER_ADDRESS: address =  @0xA002;

    fun test_init(): Scenario {
        let mut scenario_val = test_scenario::begin(SUINS_ADDRESS);
        let scenario = &mut scenario_val;
        {
            let mut suins = suins::init_for_testing(ctx(scenario));
            suins::authorize_app_for_testing<BogoApp>(&mut suins);
            suins::share_for_testing(suins);
            let clock = clock::create_for_testing(ctx(scenario));
            clock::share_for_testing(clock);
        };
        {
            test_scenario::next_tx(scenario, SUINS_ADDRESS);
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
            let mut suins = test_scenario::take_shared<SuiNS>(scenario);

            registry::init_for_testing(&admin_cap, &mut suins, ctx(scenario));

            test_scenario::return_shared(suins);
            test_scenario::return_to_sender(scenario, admin_cap);
        };
        scenario_val
    }

    #[test]
    fun test_e2e() {
        // an e2e scenario were we just purchase 3 domains normally using 3 registered ones.
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;
        test_scenario::next_tx(scenario, USER_ADDRESS);
        let clock = test_scenario::take_shared<Clock>(scenario);
        let (mut domain1, mut domain2, mut domain3, mut day_one) = prepare(ctx(scenario), &clock);
        let mut suins = test_scenario::take_shared<SuiNS>(scenario);

        let new_name_1 = bogo::claim(&mut day_one, &mut suins, &mut domain1, utf8(b"wow.sui"), &clock, ctx(scenario));
        let new_name_2 = bogo::claim(&mut day_one, &mut suins, &mut domain2, utf8(b"wow1.sui"), &clock, ctx(scenario));
        let new_name_3 = bogo::claim(&mut day_one, &mut suins, &mut domain3, utf8(b"wow11.sui"), &clock, ctx(scenario));

        // we can verify that day one got activated here.
        assert!(day_one::is_active(&day_one), 0);

        burn_domain(new_name_1);
        burn_domain(new_name_2);
        burn_domain(new_name_3);
        // clean up all these domains.
        cleanup(domain1, domain2, domain3, day_one);

        test_scenario::return_shared(suins);
        test_scenario::return_shared(clock);
        test_scenario::end(scenario_val);
    }


    #[test]
    #[expected_failure(abort_code = bogo::EDomainAlreadyUsed)]
    fun failure_test_domain_already_used() {
        // tries to reuse the same SuinsRegistration for a second time.
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;
        test_scenario::next_tx(scenario, USER_ADDRESS);
        let clock = test_scenario::take_shared<Clock>(scenario);
        let (mut domain1, domain2, domain3, mut day_one) = prepare(ctx(scenario), &clock);
        let mut suins = test_scenario::take_shared<SuiNS>(scenario);

        let new_name_1 = bogo::claim(&mut day_one, &mut suins, &mut domain1, utf8(b"wow.sui"), &clock, ctx(scenario));
        let new_name_2 = bogo::claim(&mut day_one, &mut suins, &mut domain1, utf8(b"wop.sui"), &clock, ctx(scenario));
        burn_domain(new_name_1);
        burn_domain(new_name_2);

        cleanup(domain1, domain2, domain3, day_one);
        test_scenario::return_shared(suins);
        test_scenario::return_shared(clock);
        test_scenario::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = bogo::EDomainAlreadyUsed)]
    fun failure_test_free_minted_domain_use() {
      // an e2e scenario were we just purchase 3 domains normally using 3 registered ones.
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;
        test_scenario::next_tx(scenario, USER_ADDRESS);
        let clock = test_scenario::take_shared<Clock>(scenario);
        let (mut domain1, domain2, domain3, mut day_one) = prepare(ctx(scenario), &clock);
        let mut suins = test_scenario::take_shared<SuiNS>(scenario);

        let mut new_name_1 = bogo::claim(&mut day_one, &mut suins, &mut domain1, utf8(b"wow.sui"), &clock, ctx(scenario));
        let new_name_2 = bogo::claim(&mut day_one, &mut suins, &mut new_name_1, utf8(b"wop.sui"), &clock, ctx(scenario));

        burn_domain(new_name_1);
        burn_domain(new_name_2);

        // clean up all these domains.
        cleanup(domain1, domain2, domain3, day_one);

        test_scenario::return_shared(suins);
        test_scenario::return_shared(clock);
        test_scenario::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = bogo::ESizeMissMatch)]
    fun failure_test_length_missmatch() {
      // Tries to register a 4 letter domain while presenting a 3 letter one.
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;
        test_scenario::next_tx(scenario, USER_ADDRESS);
        let clock = test_scenario::take_shared<Clock>(scenario);
        let (mut domain1, domain2, domain3, mut day_one) = prepare(ctx(scenario), &clock);
        let mut suins = test_scenario::take_shared<SuiNS>(scenario);

        let new_name_1 = bogo::claim(&mut day_one, &mut suins, &mut domain1, utf8(b"wow1.sui"), &clock, ctx(scenario));
        burn_domain(new_name_1);

        // clean up all these domains.
        cleanup(domain1, domain2, domain3, day_one);

        test_scenario::return_shared(suins);
        test_scenario::return_shared(clock);
        test_scenario::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = bogo::ENotPurchasedInAuction)]
    fun failure_test_domain_not_bought_in_auction() {
        // tries to use a fresh domain to get another one for free.
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;
        test_scenario::next_tx(scenario, USER_ADDRESS);
        let mut clock = test_scenario::take_shared<Clock>(scenario);
        let (domain1, domain2, domain3, mut day_one) = prepare(ctx(scenario), &clock);
        let mut suins = test_scenario::take_shared<SuiNS>(scenario);    

        // increment the clock by a lot.
        clock::increment_for_testing(&mut clock, bogo::last_valid_expiration());

        let mut fresh_domain = new_domain(utf8(b"exp.sui"), 1, &clock, ctx(scenario));
        let new_name_1 = bogo::claim(&mut day_one, &mut suins, &mut fresh_domain, utf8(b"wow.sui"), &clock, ctx(scenario));

        burn_domain(new_name_1);
        burn_domain(fresh_domain);

        // clean up all these domains.
        cleanup(domain1, domain2, domain3, day_one);

        test_scenario::return_shared(suins);
        test_scenario::return_shared(clock);
        test_scenario::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = bogo::ESizeMissMatch)]
    fun failure_test_length_missmatch_2() {
        // Tries to claim a 3 letter name using a 4 letter domain.
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;
        test_scenario::next_tx(scenario, USER_ADDRESS);
        let clock = test_scenario::take_shared<Clock>(scenario);
        let (domain1, mut domain2, domain3, mut day_one) = prepare(ctx(scenario), &clock);
        let mut suins = test_scenario::take_shared<SuiNS>(scenario);

        // using a 4 digit domain and trying to get a 3 digit one.
        let new_name_1 = bogo::claim(&mut day_one, &mut suins, &mut domain2, utf8(b"wow.sui"), &clock, ctx(scenario));
        burn_domain(new_name_1);
        
        // clean up all these domains.
        cleanup(domain1, domain2, domain3, day_one);

        test_scenario::return_shared(suins);
        test_scenario::return_shared(clock);
        test_scenario::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = bogo::ESizeMissMatch)]
    fun failure_test_length_missmatch_3() {
        // tries to get a 4 digit name using a 5 digit one.
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;
        test_scenario::next_tx(scenario, USER_ADDRESS);
        let clock = test_scenario::take_shared<Clock>(scenario);
        let (domain1, domain2, mut domain3, mut day_one) = prepare(ctx(scenario), &clock);
        let mut suins = test_scenario::take_shared<SuiNS>(scenario);

        let new_name_1 = bogo::claim(&mut day_one, &mut suins, &mut domain3, utf8(b"woww.sui"), &clock, ctx(scenario));
        burn_domain(new_name_1);
        
        // clean up all these domains.
        cleanup(domain1, domain2, domain3, day_one);

        test_scenario::return_shared(suins);
        test_scenario::return_shared(clock);
        test_scenario::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = bogo::ESizeMissMatch)]
    fun failure_test_length_missmatch_4() {
        // tries to get an 8 digit name using a 3 digit one.
        // protects the user from mistakes.
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;
        test_scenario::next_tx(scenario, USER_ADDRESS);
        let clock = test_scenario::take_shared<Clock>(scenario);
        let (mut domain1, domain2, domain3, mut day_one) = prepare(ctx(scenario), &clock);
        let mut suins = test_scenario::take_shared<SuiNS>(scenario);

        let new_name_1 = bogo::claim(&mut day_one, &mut suins, &mut domain1, utf8(b"wowowowo.sui"), &clock, ctx(scenario));
        burn_domain(new_name_1);
        
        // clean up all these domains.
        cleanup(domain1, domain2, domain3, day_one);

        test_scenario::return_shared(suins);
        test_scenario::return_shared(clock);
        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_acceptable_length_missmatch() {
        // We allow purchasing a domain of size 5+ if we pass a 5 length domain.
        // we only care about 3 & 4 digits.
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;
        test_scenario::next_tx(scenario, USER_ADDRESS);
        let clock = test_scenario::take_shared<Clock>(scenario);
        let (domain1, domain2, mut domain3, mut day_one) = prepare(ctx(scenario), &clock);
        let mut suins = test_scenario::take_shared<SuiNS>(scenario);
        let new_name_1 = bogo::claim(&mut day_one, &mut suins, &mut domain3, utf8(b"wowwowowo.sui"), &clock, ctx(scenario));
        burn_domain(new_name_1);
        
        // clean up all these domains.
        cleanup(domain1, domain2, domain3, day_one);

        test_scenario::return_shared(suins);
        test_scenario::return_shared(clock);
        test_scenario::end(scenario_val);
    }


    // === Helpers ===

    // destroys all the created objects
    fun cleanup(
        domain1: SuinsRegistration, 
        domain2: SuinsRegistration, 
        domain3: SuinsRegistration, 
        day_one: DayOne
    ){
        day_one::burn_for_testing(day_one);
        burn_domain(domain1);
        burn_domain(domain2);
        burn_domain(domain3);
    }

    // Helper function. Registers 3 domains and returns 2 day_ones to play with;
    fun prepare(ctx: &mut TxContext, clock: &Clock): 
        (SuinsRegistration, SuinsRegistration, SuinsRegistration, DayOne){

        let domain1 = new_domain(utf8(b"tes.sui"), 1, clock, ctx);
        let domain2 = new_domain(utf8(b"test.sui"), 1, clock, ctx);
        let domain3 = new_domain(utf8(b"test1.sui"), 1, clock, ctx);

        let day_one = day_one::mint_for_testing(ctx);

        (domain1, domain2, domain3, day_one)

    }

    fun new_domain(
        domain_name: String,
        no_years: u8,
        clock: &Clock,
        ctx: &mut TxContext,
    ): SuinsRegistration {
        nft::new_for_testing(
            domain::new(domain_name),
            no_years,
            clock,
            ctx,
        )
    }

    fun burn_domain(nft: SuinsRegistration) {
        nft::burn_for_testing(nft)
    }

}
