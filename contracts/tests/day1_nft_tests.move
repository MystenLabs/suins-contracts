#[test_only]
module suins::day1_nft_tests {
    // use std::debug::{print};
    use std::string::{utf8, String};
    use sui::tx_context::{Self, TxContext};
    use sui::clock::{Self, Clock};
    use sui::test_scenario::{Self, Scenario, ctx};

    use suins::day1_nft::{Self, SuinsDay1, Day1AuthToken};
    use suins::suins_registration::{Self as nft, SuinsRegistration};
    use suins::domain;
    use suins::constants;
    use suins::registry;
    use suins::suins::{Self, SuiNS, AdminCap};

    const SUINS_ADDRESS: address = @0xA001;
    const USER_ADDRESS: address =  @0xA002;
    const ATTACH_DOMAINS_PERIOD_MS: u64 = 1 * 24 * 60 * 60 * 1000;

    fun test_init(): Scenario {
        let scenario_val = test_scenario::begin(SUINS_ADDRESS);
        let scenario = &mut scenario_val;
        {
            let suins = suins::init_for_testing(ctx(scenario));
            suins::authorize_app_for_testing<Day1AuthToken>(&mut suins);
            suins::share_for_testing(suins);
            let clock = clock::create_for_testing(ctx(scenario));
            clock::share_for_testing(clock);
        };
        {
            test_scenario::next_tx(scenario, SUINS_ADDRESS);
            let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
            let suins = test_scenario::take_shared<SuiNS>(scenario);

            registry::init_for_testing(&admin_cap, &mut suins, ctx(scenario));

            test_scenario::return_shared(suins);
            test_scenario::return_to_sender(scenario, admin_cap);
        };
        scenario_val
    }

    #[test]
    fun test_e2e() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;

        test_scenario::next_tx(scenario, USER_ADDRESS);
        let (_ctx, clock, domain1, domain2, domain3, day1_nft, day1_nft_2) = prepare();

        let suins = test_scenario::take_shared<SuiNS>(scenario);

        day1_nft::attach_domain(&mut day1_nft, &mut domain1, &clock);
        day1_nft::attach_domain(&mut day1_nft, &mut domain2, &clock);
        day1_nft::attach_domain(&mut day1_nft, &mut domain3, &clock);

        assert!(day1_nft::free_three_char_names(&day1_nft) == 1, 0);
        assert!(day1_nft::free_four_char_names(&day1_nft) == 1, 0);
        assert!(day1_nft::free_five_char_names(&day1_nft) == 1, 0);

        day1_nft::activate(&mut day1_nft);

        assert!(!!day1_nft::is_activated(&day1_nft), 0);

        let new_registration = day1_nft::claim(&mut day1_nft, &mut suins, utf8(b"wow.sui"), &clock, ctx(scenario));

        // verify that the free char names are reduced (consumed domain);
        assert!(day1_nft::free_three_char_names(&day1_nft) == 0, 0);

        cleanup(domain1, domain2, domain3, day1_nft, day1_nft_2, clock);

        burn_domain(new_registration);

        test_scenario::return_shared(suins);
        test_scenario::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = day1_nft::ENotEnoughFreeClaims)]
    fun test_not_enough_free_claims_fail() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;

        test_scenario::next_tx(scenario, USER_ADDRESS);
        let (_ctx, clock, domain1, domain2, domain3, day1_nft, day1_nft_2) = prepare();

        let suins = test_scenario::take_shared<SuiNS>(scenario);

        day1_nft::activate(&mut day1_nft);

        assert!(!!day1_nft::is_activated(&day1_nft), 0);
        let new_registration = day1_nft::claim(&mut day1_nft, &mut suins, utf8(b"wow.sui"), &clock, ctx(scenario));

        cleanup(domain1, domain2, domain3, day1_nft, day1_nft_2, clock);
        burn_domain(new_registration);
        test_scenario::return_shared(suins);
        test_scenario::end(scenario_val);
    }
    #[test]
    #[expected_failure(abort_code = day1_nft::ENotEnoughFreeClaims)]
    fun test_not_enough_free_claims_for_specific_size_fail() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;

        test_scenario::next_tx(scenario, USER_ADDRESS);
        let (_ctx, clock, domain1, domain2, domain3, day1_nft, day1_nft_2) = prepare();

        let suins = test_scenario::take_shared<SuiNS>(scenario);
        day1_nft::attach_domain(&mut day1_nft, &mut domain1, &clock);
        day1_nft::activate(&mut day1_nft);

        // tries to claim a free domain of 4 digits, while we have only attached a 3 digit one.
        let new_registration = day1_nft::claim(&mut day1_nft, &mut suins, utf8(b"wow2.sui"), &clock, ctx(scenario));

        cleanup(domain1, domain2, domain3, day1_nft, day1_nft_2, clock);
        burn_domain(new_registration);
        test_scenario::return_shared(suins);
        test_scenario::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = day1_nft::EPromoDomainUsed)]
    fun test_try_to_attach_promo_domain_fail() {
        let scenario_val = test_init();
        let scenario = &mut scenario_val;

        test_scenario::next_tx(scenario, USER_ADDRESS);
        let (_ctx, clock, domain1, domain2, domain3, day1_nft, day1_nft_2) = prepare();

        let suins = test_scenario::take_shared<SuiNS>(scenario);
        day1_nft::attach_domain(&mut day1_nft, &mut domain1, &clock);
        day1_nft::activate(&mut day1_nft);

        // tries to claim a free domain of 4 digits, while we have only attached a 3 digit one.
        let new_registration = day1_nft::claim(&mut day1_nft, &mut suins, utf8(b"wow.sui"), &clock, ctx(scenario));

        day1_nft::attach_domain(&mut day1_nft_2, &mut new_registration, &clock);

        cleanup(domain1, domain2, domain3, day1_nft, day1_nft_2, clock);
        burn_domain(new_registration);
        test_scenario::return_shared(suins);
        test_scenario::end(scenario_val);
    }

    #[test]
    #[expected_failure(abort_code = day1_nft::EAlreadyActivated)]
    fun activate_twice_fail() {
        let (_ctx, clock, domain1, domain2, domain3, day1_nft, day1_nft_2) = prepare();

        day1_nft::activate(&mut day1_nft);
        day1_nft::activate(&mut day1_nft);

        assert!(!!day1_nft::is_activated(&day1_nft), 0);
        cleanup(domain1, domain2, domain3, day1_nft, day1_nft_2, clock);
    }

    #[test]
    #[expected_failure(abort_code = day1_nft::EDomainAlreadyUsed)]
    fun use_domain_twice_fail() {
        let (_ctx, clock, domain1, domain2, domain3, day1_nft, day1_nft_2) = prepare();

        day1_nft::attach_domain(&mut day1_nft, &mut domain1, &clock);
        day1_nft::attach_domain(&mut day1_nft, &mut domain1, &clock);

        assert!(!!day1_nft::is_activated(&day1_nft), 0);
        cleanup(domain1, domain2, domain3, day1_nft, day1_nft_2, clock);
    }
    #[test]
    #[expected_failure(abort_code = day1_nft::EDomainAlreadyUsed)]
    fun use_domain_twice_on_separate_day1_nft_fail() {
        let (_ctx, clock, domain1, domain2, domain3, day1_nft, day1_nft_2) = prepare();

        day1_nft::attach_domain(&mut day1_nft, &mut domain1, &clock);
        day1_nft::attach_domain(&mut day1_nft_2, &mut domain1, &clock);

        assert!(!!day1_nft::is_activated(&day1_nft), 0);
        cleanup(domain1, domain2, domain3, day1_nft, day1_nft_2, clock);
    }

    #[test]
    #[expected_failure(abort_code = day1_nft::EAttachingExpired)]
    fun try_to_attach_after_expiration_fail() {
        let (_ctx, clock, domain1, domain2, domain3, day1_nft, day1_nft_2) = prepare();

        day1_nft::attach_domain(&mut day1_nft, &mut domain1, &clock);
        clock::increment_for_testing(&mut clock, ATTACH_DOMAINS_PERIOD_MS + 1);
        day1_nft::attach_domain(&mut day1_nft, &mut domain2, &clock);

        cleanup(domain1, domain2, domain3, day1_nft, day1_nft_2, clock);
    }

    #[test]
    #[expected_failure(abort_code = day1_nft::EAlreadyActivated)]
    fun try_to_attach_after_activation_fail() {
        let (_ctx, clock, domain1, domain2, domain3, day1_nft, day1_nft_2) = prepare();

        day1_nft::attach_domain(&mut day1_nft, &mut domain1, &clock);
        day1_nft::activate(&mut day1_nft);
        day1_nft::attach_domain(&mut day1_nft, &mut domain2, &clock);

        cleanup(domain1, domain2, domain3, day1_nft, day1_nft_2, clock);
    }

    #[test]
    #[expected_failure(abort_code = day1_nft::EDomainExpired)]
    fun try_to_attach_expired_domain() {
        let (_ctx, clock, domain1, domain2, domain3, day1_nft, day1_nft_2) = prepare();

        clock::increment_for_testing(&mut clock, constants::year_ms() + 1);
        day1_nft::attach_domain(&mut day1_nft, &mut domain2, &clock);

        cleanup(domain1, domain2, domain3, day1_nft, day1_nft_2, clock);
    }

    // === Helpers ===

    // destroys all the created objects
    fun cleanup(
        domain1: SuinsRegistration, 
        domain2: SuinsRegistration, 
        domain3: SuinsRegistration, 
        day1_nft: SuinsDay1,
        day1_nft_2: SuinsDay1, 
        clock: Clock
    ){
        day1_nft::burn_for_testing(day1_nft);
        day1_nft::burn_for_testing(day1_nft_2);
        burn_domain(domain1);
        burn_domain(domain2);
        burn_domain(domain3);
        clock::destroy_for_testing(clock);
    }

    // Helper function. Registers 3 domains and returns 2 day1_nfts to play with;
    fun prepare(): 
        (TxContext, Clock, SuinsRegistration, SuinsRegistration, SuinsRegistration, SuinsDay1, SuinsDay1){
        let ctx = tx_context::dummy();
        let clock = clock::create_for_testing(&mut ctx);

        let domain1 = new_domain(utf8(b"tes.sui"), 1, &clock, &mut ctx);
        let domain2 = new_domain(utf8(b"test.sui"), 1, &clock, &mut ctx);
        let domain3 = new_domain(utf8(b"test1.sui"), 1, &clock, &mut ctx);

        let day1_nft = day1_nft::mint_for_testing(&mut ctx);
        let day1_nft_2 = day1_nft::mint_for_testing(&mut ctx);

        (ctx, clock, domain1, domain2, domain3, day1_nft, day1_nft_2)

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
