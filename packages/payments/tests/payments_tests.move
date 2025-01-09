#[test_only]
module payments::payments_tests;

use payments::ns::NS;
use payments::payments::{
    new_payments_config,
    new_coin_type_data,
    handle_base_payment,
    handle_payment,
    PaymentsApp,
    PaymentsConfig
};
use payments::usdc::USDC;
use std::type_name;
use sui::clock::{Self, Clock};
use sui::coin::{Self, CoinMetadata};
use sui::sui::SUI;
use sui::test_scenario::{Self as ts, Scenario, ctx};
use sui::test_utils::{assert_eq, destroy};
use suins::constants;
use suins::core_config;
use suins::domain;
use suins::payment::{Self, PaymentIntent, Receipt};
use suins::payment_tests::setup_suins;
use suins::pricing_config::{Self, PricingConfig};
use suins::registry::{Self, Registry};
use suins::suins::{Self, SuiNS, AdminCap};
use suins::suins_registration;

public struct PaymentTestsCurrency has drop {}
public struct SPAM has drop {}

const SUINS_ADDRESS: address = @0xA001;

public fun setup(ctx: &mut TxContext): (SuiNS, AdminCap) {
    let mut suins = setup_suins(ctx);
    let admin_cap = suins::create_admin_cap_for_testing(ctx);
    admin_cap.authorize_app<PaymentsApp>(&mut suins);

    payments::usdc::test_init(ctx);
    payments::ns::test_init(ctx);

    (suins, admin_cap)
}

#[
    test,
    expected_failure(
        abort_code = ::payments::payments::EBaseCurrencySetupMissing,
    ),
]
fun base_currency_not_in_list_e() {
    let mut test = ts::begin(SUINS_ADDRESS);
    let (_suins, _admin_cap) = setup(test.ctx());

    test.next_tx(SUINS_ADDRESS);
    let usdc_metadata = test.take_from_sender<CoinMetadata<USDC>>();
    let usdc_type_data = new_coin_type_data<USDC>(
        &usdc_metadata,
        0,
        vector[],
    );
    let mut setups = vector[];
    setups.push_back(usdc_type_data);

    let _config = new_payments_config(
        setups,
        type_name::get<SPAM>(),
        60,
    );

    abort 1337
}

#[
    test,
    expected_failure(
        abort_code = ::payments::payments::EInsufficientPayment,
    ),
]
fun payment_insufficient_e() {
    let mut test = ts::begin(SUINS_ADDRESS);
    let (mut suins, admin_cap) = setup(test.ctx());

    test.next_tx(SUINS_ADDRESS);
    let usdc_metadata = test.take_from_sender<CoinMetadata<USDC>>();
    let usdc_type_data = new_coin_type_data<USDC>(
        &usdc_metadata,
        0,
        vector[],
    );
    let mut setups = vector[];
    setups.push_back(usdc_type_data);

    let config = new_payments_config(
        setups,
        type_name::get<USDC>(),
        60,
    );

    admin_cap.add_config<PaymentsConfig>(&mut suins, config);

    test.next_tx(SUINS_ADDRESS);
    let intent = payment::init_registration(
        &mut suins,
        std::string::utf8(b"helloworld.sui"),
    );

    // 20 is required for registration, only 10 is minted
    let _receipt = handle_base_payment<USDC>(
        &mut suins,
        intent,
        coin::mint_for_testing<USDC>(10, test.ctx()),
    );

    abort 1337
}

#[
    test,
    expected_failure(
        abort_code = ::payments::payments::EInvalidPaymentType,
    ),
]
fun invalid_payment_type_e() {
    let mut test = ts::begin(SUINS_ADDRESS);
    let (mut suins, admin_cap) = setup(test.ctx());

    test.next_tx(SUINS_ADDRESS);
    let usdc_metadata = test.take_from_sender<CoinMetadata<USDC>>();
    let usdc_type_data = new_coin_type_data<USDC>(
        &usdc_metadata,
        0,
        vector[],
    );
    let mut setups = vector[];
    setups.push_back(usdc_type_data);

    let config = new_payments_config(
        setups,
        type_name::get<USDC>(),
        60,
    );

    admin_cap.add_config<PaymentsConfig>(&mut suins, config);

    test.next_tx(SUINS_ADDRESS);
    let intent = payment::init_registration(
        &mut suins,
        std::string::utf8(b"helloworld.sui"),
    );

    // 20 is required for registration, paying with SPAM fails
    let _receipt = handle_base_payment<SPAM>(
        &mut suins,
        intent,
        coin::mint_for_testing<SPAM>(20, test.ctx()),
    );

    abort 1337
}

// #[
//     test,
//     expected_failure(
//         abort_code = ::payments::payments::EInvalidPaymentType,
//     ),
// ]
// fun cannot_use_oracle_base_payment_e() {
//     let mut test = ts::begin(SUINS_ADDRESS);
//     share_clock(&mut test);
//     let (mut suins, admin_cap) = setup(test.ctx());

//     test.next_tx(SUINS_ADDRESS);
//     let usdc_metadata = test.take_from_sender<CoinMetadata<USDC>>();
//     let usdc_type_data = new_coin_type_data<USDC>(
//         &usdc_metadata,
//         0,
//         vector[],
//     );
//     let mut setups = vector[];
//     setups.push_back(usdc_type_data);

//     let config = new_payments_config(
//         setups,
//         type_name::get<USDC>(),
//         60,
//     );

//     admin_cap.add_config<PaymentsConfig>(&mut suins, config);

//     test.next_tx(SUINS_ADDRESS);
//     let intent = payment::init_registration(
//         &mut suins,
//         std::string::utf8(b"helloworld.sui"),
//     );

//     let clock = test.take_shared<Clock>();

//     // 20 is required for registration, paying with SPAM fails
//     let _receipt = handle_payment<USDC>(
//         &mut suins,
//         intent,
//         coin::mint_for_testing<USDC>(20, test.ctx()),
//         &clock,
//         clock,
//         100,
//     );

//     abort 1337
// }

// fun share_clock(test: &mut Scenario) {
//     test.next_tx(SUINS_ADDRESS);
//     clock::create_for_testing(test.ctx()).share_for_testing();
// }
