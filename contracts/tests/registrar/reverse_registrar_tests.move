#[test_only]
module suins::reverse_registrar_tests {

    use sui::test_scenario::{Self, Scenario};
    use suins::registry::{Self, AdminCap};
    use suins::reverse_registrar;
    use suins::registrar;
    use suins::entity::SuiNS;
    use suins::entity;
    use std::string;

    const SUINS_ADDRESS: address = @0xA001;
    const FIRST_USER_ADDRESS: address = @0xB001;
    const SECOND_USER_ADDRESS: address = @0xB002;
    const FIRST_RESOLVER_ADDRESS: address = @0xC001;
    const SECOND_RESOLVER_ADDRESS: address = @0xC002;
    const FIRST_DOMAIN_NAME: vector<u8> = b"000000000000000000000000000000000000000000000000000000000000b001.addr.reverse";
    const SECOND_DOMAIN_NAME: vector<u8> = b"000000000000000000000000000000000000000000000000000000000000b002.addr.reverse";

    fun test_init(): Scenario {
        let scenario = test_scenario::begin(SUINS_ADDRESS);
        {
            let ctx = test_scenario::ctx(&mut scenario);
            registry::test_init(ctx);
            entity::test_init(ctx);
        };
        test_scenario::next_tx(&mut scenario, SUINS_ADDRESS);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&mut scenario);
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);

            registrar::new_tld(&admin_cap, &mut suins, b"sui", test_scenario::ctx(&mut scenario));
            registrar::new_tld(&admin_cap, &mut suins, b"addr.reverse", test_scenario::ctx(&mut scenario));
            registrar::new_tld(&admin_cap, &mut suins, b"move", test_scenario::ctx(&mut scenario));

            test_scenario::return_shared(suins);
            test_scenario::return_to_sender(&mut scenario, admin_cap);
        };
        scenario
    }


    #[test]
    fun test_claim() {
        let scenario = test_init();
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            reverse_registrar::claim(
                &mut suins,
                FIRST_USER_ADDRESS,
                test_scenario::ctx(&mut scenario),
            );
            test_scenario::return_shared(suins);
        };
        test_scenario::next_tx(&mut scenario, FIRST_USER_ADDRESS);
        {
            let suins = test_scenario::take_shared<SuiNS>(&mut scenario);
            let (owner, addr, ttl, name) = registry::get_name_record_all_fields(&suins, FIRST_DOMAIN_NAME);
            assert!(owner == FIRST_USER_ADDRESS, 0);
            assert!(addr == @0x0, 0);
            assert!(ttl == 0, 0);
            assert!(name == string::utf8(b""), 0);

            test_scenario::return_shared(suins);
        };
        test_scenario::end(scenario);
    }
}
