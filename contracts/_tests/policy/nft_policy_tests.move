#[test_only]
module suins::nft_policy_tests {
    use kiosk::royalty_rule;

    use std::option;

    use sui::kiosk_test_utils::{Self as test};
    use sui::transfer;
    use sui::test_scenario::{Self, ctx, Scenario};
    use sui::kiosk::{Self, KioskOwnerCap, Kiosk};
    use sui::sui::SUI;
    use sui::coin;
    use sui::object::ID;
    use sui::transfer_policy::{Self, TransferRequest, TransferPolicy, TransferPolicyCap};
    use sui::package::{Self, Publisher};

    use suins::nft_policy;
    use suins::registrar::{Self, RegistrationNFT};
    use suins::controller_tests;
    use suins::suins::{Self, SuiNS};

    const SUINS_ADDRESS: address = @0xA001;
    const FIRST_USER_ADDRESS: address = @0xB001;
    const SECOND_USER_ADDRESS: address = @0xB002;
    const AMT: u64 = 10_000;
    const DEFAULT_ROYALTY_FEE: u64 = 250;
    const SUI_REGISTRAR: vector<u8> = b"sui";
    const PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN: u64 = 50 * 1_000_000_000;

    fun init_kiosk(scenario: &mut Scenario, kiosk_owner: address) {
        test_scenario::next_tx(scenario, kiosk_owner);
        let (kiosk, owner_cap) = test::get_kiosk(ctx(scenario));
        transfer::public_share_object(kiosk);
        transfer::public_transfer(owner_cap, kiosk_owner);
    }

    fun place_nft_into_kiosk(scenario: &mut Scenario, kiosk_owner: address) {
        test_scenario::next_tx(scenario, kiosk_owner);
        let nft = test_scenario::take_from_sender<RegistrationNFT>(scenario);
        let nft_id = registrar::get_nft_id(&nft);
        let owner_cap = test_scenario::take_from_sender<KioskOwnerCap>(scenario);
        let kiosk = test_scenario::take_shared<Kiosk>(scenario);

        kiosk::place<RegistrationNFT>(&mut kiosk, &owner_cap, nft);
        kiosk::list<RegistrationNFT>(&mut kiosk, &owner_cap, nft_id, AMT);

        test_scenario::return_shared(kiosk);
        test_scenario::return_to_sender(scenario, owner_cap);
    }

    fun purchase_from_kiosk(
        scenario: &mut Scenario,
        buyer: address,
        nft_id: ID
    ): (RegistrationNFT, TransferRequest<RegistrationNFT>) {
        test_scenario::next_tx(scenario, buyer);
        let kiosk = test_scenario::take_shared<Kiosk>(scenario);
        let payment = coin::mint_for_testing<SUI>(AMT, ctx(scenario));

        let (nft, request) = kiosk::purchase<RegistrationNFT>(&mut kiosk, nft_id, payment);

        test_scenario::return_shared(kiosk);

        (nft, request)
    }

    fun pay_royalty(
        scenario: &mut Scenario,
        request: &mut TransferRequest<RegistrationNFT>,
        paid_amount: u64,
    ) {
        let suins = test_scenario::take_shared<SuiNS>(scenario);
        let policy = test_scenario::take_shared<TransferPolicy<RegistrationNFT>>(scenario);
        let payment = coin::mint_for_testing<SUI>(paid_amount, ctx(scenario));

        assert!(suins::balance(&suins) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN, 0);
        royalty_rule::pay(&mut policy, request, &mut payment, ctx(scenario));
        assert!(suins::balance(&suins) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN, 0);

        coin::burn_for_testing(payment);
        test_scenario::return_shared(suins);
        test_scenario::return_shared(policy);
    }

    fun confirm_request(
        scenario: &mut Scenario,
        buyer: address,
        request: TransferRequest<RegistrationNFT>,
    ) {
        test_scenario::next_tx(scenario, buyer);
        let policy = test_scenario::take_shared<TransferPolicy<RegistrationNFT>>(scenario);
        transfer_policy::confirm_request(&policy, request);
        test_scenario::return_shared(policy);
    }

    fun transfer_ends(publisher: Publisher, nft: RegistrationNFT, buyer: address) {
        transfer::public_transfer(nft, buyer);
        package::burn_publisher(publisher);
    }

    fun register_new_domain(scenario: &mut Scenario): ID {
        controller_tests::set_auction_config(scenario);
        controller_tests::register(scenario)
    }

    fun assert_royalty_fee(scenario: &mut Scenario, royalty_fee: u64) {
        test_scenario::next_tx(scenario, FIRST_USER_ADDRESS);
        let suins = test_scenario::take_shared<SuiNS>(scenario);
        assert!(suins::balance(&suins) == PRICE_OF_FIVE_AND_ABOVE_CHARACTER_DOMAIN, 0);

        let kiosk = test_scenario::take_shared<Kiosk>(scenario);
        let owner_cap = test_scenario::take_from_sender<KioskOwnerCap>(scenario);
        let coin = kiosk::withdraw(&mut kiosk, &owner_cap, option::none(), ctx(scenario));
        assert!(coin::value(&coin) == AMT, 0);

        coin::burn_for_testing(coin);
        test_scenario::return_shared(suins);
        test_scenario::return_shared(kiosk);
        test_scenario::return_to_sender(scenario, owner_cap);

        test_scenario::next_tx(scenario, SUINS_ADDRESS);
        let policy = test_scenario::take_shared<TransferPolicy<RegistrationNFT>>(scenario);
        let policy_cap = test_scenario::take_from_sender<TransferPolicyCap<RegistrationNFT>>(scenario);
        let coin = transfer_policy::withdraw(&mut policy, &policy_cap, option::none(), ctx(scenario));
        assert!(coin::value(&coin) == royalty_fee, 0);

        coin::burn_for_testing(coin);
        test_scenario::return_shared(policy);
        test_scenario::return_to_sender(scenario, policy_cap);
    }

    #[test]
    fun test_royalty() {
        let scenario_val = controller_tests::test_init();
        let scenario = &mut scenario_val;

        let publisher = package::test_claim(nft_policy::new_rule_for_testing(), ctx(scenario));
        nft_policy::init_policy(&publisher, ctx(scenario));
        let nft_id = register_new_domain(scenario);
        init_kiosk(scenario, FIRST_USER_ADDRESS);
        place_nft_into_kiosk(scenario, FIRST_USER_ADDRESS);
        let (nft, request) = purchase_from_kiosk(scenario, SECOND_USER_ADDRESS, nft_id);
        pay_royalty(scenario, &mut request, DEFAULT_ROYALTY_FEE);
        confirm_request(scenario, SECOND_USER_ADDRESS, request);
        transfer_ends(publisher, nft, SECOND_USER_ADDRESS);

        assert_royalty_fee(scenario, DEFAULT_ROYALTY_FEE);
        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = transfer_policy::EPolicyNotSatisfied)]
    fun test_royalty_aborts_if_royalty_fee_not_paid() {
        let scenario_val = controller_tests::test_init();
        let scenario = &mut scenario_val;

        let publisher = package::test_claim(nft_policy::new_rule_for_testing(), ctx(scenario));
        nft_policy::init_policy(&publisher, ctx(scenario));
        let nft_id = register_new_domain(scenario);
        init_kiosk(scenario, FIRST_USER_ADDRESS);
        place_nft_into_kiosk(scenario, FIRST_USER_ADDRESS);
        let (nft, request) = purchase_from_kiosk(scenario, SECOND_USER_ADDRESS, nft_id);
        confirm_request(scenario, SECOND_USER_ADDRESS, request);
        transfer_ends(publisher, nft, SECOND_USER_ADDRESS);

        test_scenario::end(scenario_val);
    }

    #[test, expected_failure(abort_code = royalty_rule::EInsufficientAmount)]
    fun test_royalty_aborts_if_not_enough_fee() {
        let scenario_val = controller_tests::test_init();
        let scenario = &mut scenario_val;

        let publisher = package::test_claim(nft_policy::new_rule_for_testing(), ctx(scenario));
        nft_policy::init_policy(&publisher, ctx(scenario));
        let nft_id = register_new_domain(scenario);
        init_kiosk(scenario, FIRST_USER_ADDRESS);
        place_nft_into_kiosk(scenario, FIRST_USER_ADDRESS);
        let (nft, request) = purchase_from_kiosk(scenario, SECOND_USER_ADDRESS, nft_id);
        pay_royalty(scenario, &mut request, DEFAULT_ROYALTY_FEE - 1);
        confirm_request(scenario, SECOND_USER_ADDRESS, request);
        transfer_ends(publisher, nft, SECOND_USER_ADDRESS);

        assert_royalty_fee(scenario, DEFAULT_ROYALTY_FEE);

        test_scenario::end(scenario_val);
    }
}
