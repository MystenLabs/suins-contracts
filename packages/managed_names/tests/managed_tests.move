// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

module managed_names::managed_tests {
    use std::option;
    use std::string::{String, utf8};

    use sui::test_scenario::{Self as ts, Scenario, ctx};
    use sui::clock::{Self, Clock};
    use sui::transfer;
    use sui::object;

    use suins::suins_registration::{Self, new_for_testing, SuinsRegistration};
    use suins::suins::{Self, SuiNS};
    use suins::domain;

    use managed_names::managed::{Self, ManagedNamesApp, ReturnPromise};

    const USER: address = @0x1;
    const USER_TWO: address = @0x2;
    const USER_THREE: address = @0x3;

    #[test]
    fun e2e() {
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;

        let domain_name = utf8(b"example.sui");

        attach_name(get_nft(domain_name, USER, scenario), vector[], USER, scenario);

        add_or_remove_addresses(domain_name, vector[USER_TWO], true, USER, scenario);

        simulate_borrowing(domain_name, USER_TWO, scenario);
        simulate_borrowing(domain_name, USER, scenario);

        let nft = remove_attached_name(domain_name, USER, scenario);
        transfer::public_transfer(nft, USER);
        
        scenario_val.end();
    }

    #[test]
    fun deattach_expired_to_attach_non_expired() {
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;

        let domain_name = utf8(b"example.sui");

        let first_nft = get_nft(domain_name, USER, scenario);
        let random_nft = get_nft(utf8(b"random.sui"), USER, scenario);

        let id = object::id(&first_nft);

        attach_name(first_nft, vector[USER_TWO], USER, scenario);
        simulate_borrowing(domain_name, USER_TWO, scenario);
        
        // advance clock so that its expired.
        advance_clock_post_expiration_of_nft(&random_nft, scenario);

        let re_registered_nft = get_nft(domain_name, USER_THREE, scenario);
        attach_name(re_registered_nft, vector[], USER_THREE, scenario);

        // Since we attached the re-registered version for the name,
        // the original `owner` should have received back the expired NFT.
        {
            scenario.next_tx(USER);
            let mut nft_transferred_back = ts::most_recent_id_for_address<SuinsRegistration>(USER);

            assert!(option::is_some(&nft_transferred_back), 0);
            assert!(option::extract(&mut nft_transferred_back) == id, 0);
        
        };

        suins_registration::burn_for_testing(random_nft);
        
        scenario_val.end();
    }

    #[test, expected_failure(abort_code=managed_names::managed::EExpiredNFT)]
    fun attach_expired_failure() {
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;

        let domain_name = utf8(b"example.sui");
        let nft = get_nft(domain_name, USER, scenario);

        advance_clock_post_expiration_of_nft(&nft, scenario);
 
        attach_name(nft, vector[], USER, scenario);

        abort 1337
    }

    #[test, expected_failure(abort_code=managed_names::managed::ENameNotExists)]
    fun borrow_non_existing_name_failure() {
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;
        let domain_name = utf8(b"example.sui");

        simulate_borrowing(domain_name, USER, scenario);
        abort 1337
    }

    #[test, expected_failure(abort_code=managed_names::managed::EInvalidReturnedNFT)]
    fun borrow_and_return_different_nft() {
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;
    
        let domain_name = utf8(b"example.sui");
        let domain_name_two = utf8(b"test.example.sui");

        let nft1 = get_nft(domain_name, USER, scenario);
        let nft2 = get_nft(domain_name_two, USER, scenario);

        attach_name(nft1, vector[], USER, scenario);
        let (_nft, promise) = simulate_borrow(domain_name, USER, scenario);
        simulate_return(nft2, promise, scenario);

        abort 1337
    }

    #[test, expected_failure(abort_code=managed_names::managed::ENotAuthorized)]
    fun try_to_borrow_as_unauthorized_user() {
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;
    
        let domain_name = utf8(b"example.sui");

        let nft1 = get_nft(domain_name, USER, scenario);
        attach_name(nft1, vector[], USER, scenario);
        let (_nft, _promise) = simulate_borrow(domain_name, USER_THREE, scenario);

        abort 1337
    }

    #[test, expected_failure(abort_code=managed_names::managed::ENotAuthorized)]
    fun try_to_remove_not_being_owner_but_being_authorized() {
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;
    
        let domain_name = utf8(b"example.sui");

        let nft = get_nft(domain_name, USER, scenario);
        attach_name(nft, vector[USER_TWO], USER, scenario);

        let _nft = remove_attached_name(domain_name, USER_TWO, scenario);

        abort 1337
    }

    #[test, expected_failure(abort_code=managed_names::managed::ENotAuthorized)]
    fun try_to_remove_not_being_owner_not_authorized() {
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;
    
        let domain_name = utf8(b"example.sui");

        let nft = get_nft(domain_name, USER, scenario);
        attach_name(nft, vector[], USER, scenario);

        let _nft = remove_attached_name(domain_name, USER_TWO, scenario);

        abort 1337
    }

    #[test, expected_failure(abort_code=managed_names::managed::ENotAuthorized)]
    fun remove_from_authorized_and_fail_to_borrow() {
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;

        let domain_name = utf8(b"example.sui");
        let nft = get_nft(domain_name, USER, scenario);

        // authorizes and allows user two.
        attach_name(nft, vector[USER_TWO], USER, scenario);
        // removes User Two from authorized list.
        add_or_remove_addresses(domain_name, vector[USER_TWO], false, USER, scenario);

        // tries to borrow as user Two.
        simulate_borrowing(domain_name, USER_TWO, scenario);

        abort 1337
    }

    #[test, expected_failure(abort_code=managed_names::managed::ENotAuthorized)]
    fun revoke_addresses_as_non_owner() {
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;

        let domain_name = utf8(b"example.sui");
        let nft = get_nft(domain_name, USER, scenario);

        attach_name(nft, vector[USER_TWO], USER, scenario);
        add_or_remove_addresses(domain_name, vector[USER_TWO], false, USER_TWO, scenario);

        abort 1337
    }

    #[test, expected_failure(abort_code=managed_names::managed::ENotAuthorized)]
    fun add_addresses_as_non_owner() {
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;

        let domain_name = utf8(b"example.sui");
        let nft = get_nft(domain_name, USER, scenario);
        
        attach_name(nft, vector[USER_TWO], USER, scenario);
        add_or_remove_addresses(domain_name, vector[USER_THREE], true, USER_TWO, scenario);

        abort 1337
    }

    #[test, expected_failure(abort_code=managed_names::managed::ENameNotExists)]
    fun remove_name_that_does_not_exist() {
        let mut scenario_val = test_init();
        let scenario = &mut scenario_val;

        let domain_name = utf8(b"example.sui");
        let _nft = remove_attached_name(domain_name, USER, scenario);

        abort 1337
    }

    /// == Helpers == 
    ///
    public fun test_init(): (Scenario) {
        let mut scenario = ts::begin(USER);
        {
            scenario.next_tx(USER);

            let clock = clock::create_for_testing(scenario.ctx());
            clock::share_for_testing(clock);

            let (mut suins, cap) = suins::new_for_testing(scenario.ctx());

            suins.authorize_app_for_testing<ManagedNamesApp>();

            managed::setup(&mut suins, &cap, ctx(&mut scenario));
            suins.share_for_testing();
        
            suins::burn_admin_cap_for_testing(cap);
        };

        scenario
    }

    public fun attach_name(nft: SuinsRegistration, addresses: vector<address>, addr: address, scenario: &mut Scenario) {
        scenario.next_tx(addr);
        let mut suins = scenario.take_shared<SuiNS>();
        let clock = scenario.take_shared<Clock>();

        managed::attach_managed_name(&mut suins, nft, &clock, addresses, scenario.ctx());

        ts::return_shared(clock);
        ts::return_shared(suins);
    }

    public fun remove_attached_name(domain_name: String, addr: address, scenario: &mut Scenario): SuinsRegistration {
        scenario.next_tx(addr);
        let mut suins = scenario.take_shared<SuiNS>();

        let nft = managed::remove_attached_name(&mut suins, domain_name, scenario.ctx());

        ts::return_shared(suins);
        nft
    }

    public fun add_or_remove_addresses(name: String, addresses: vector<address>, add: bool, addr: address, scenario: &mut Scenario) {
        scenario.next_tx(addr);
        let mut suins = scenario.take_shared<SuiNS>();
        let clock = scenario.take_shared<Clock>();

        if(add){
            managed::allow_addresses(&mut suins, name, addresses, scenario.ctx());
        }else {
            managed::revoke_addresses(&mut suins, name, addresses, scenario.ctx());
        };

        ts::return_shared(clock);
        ts::return_shared(suins);
    }

    public fun simulate_borrow(domain_name: String, addr: address, scenario: &mut Scenario): (SuinsRegistration, ReturnPromise) {
        scenario.next_tx(addr);
        let mut suins = scenario.take_shared<SuiNS>();

        let (name, promise) = managed::borrow_val(&mut suins, domain_name, scenario.ctx());
        
        assert!(name.domain() == domain::new(domain_name), 0);

        ts::return_shared(suins);

        (name, promise)
    }

    public fun simulate_return(nft: SuinsRegistration, promise: ReturnPromise, scenario: &mut Scenario) {
        scenario.next_tx(USER);
        let mut suins = scenario.take_shared<SuiNS>();

        managed::return_val(&mut suins, nft, promise);

        ts::return_shared(suins);
    }

    public fun simulate_borrowing(domain_name: String, addr: address, scenario: &mut Scenario) {

        let (name, promise) = simulate_borrow(domain_name, addr, scenario);
    
        simulate_return(name, promise, scenario);
    }

    public fun advance_clock_post_expiration_of_nft(nft: &SuinsRegistration, scenario: &mut Scenario) {
        scenario.next_tx(USER);
        let mut clock = scenario.take_shared<Clock>();
        // expire name
        clock.increment_for_testing(nft.expiration_timestamp_ms() + 1);
        ts::return_shared(clock);
    }

    // generates a SuinsRegistration NFT for testing
    public fun get_nft(name: String, addr: address, scenario: &mut Scenario): SuinsRegistration {
        scenario.next_tx(addr);
        let suins = scenario.take_shared<SuiNS>();
        let clock = scenario.take_shared<Clock>();
        let nft = new_for_testing(
            domain::new(name),
            1, 
            &clock,
            ctx(scenario)
        );
        ts::return_shared(clock);
        ts::return_shared(suins);
        nft
    }
}
