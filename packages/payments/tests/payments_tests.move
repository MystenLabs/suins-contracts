#[test_only]
module payments::payments_tests;

use payments::ns::NS;
use payments::payments::{
    new_payments_config,
    new_coin_type_data,
    PaymentsApp,
    CoinTypeData,
    PaymentsConfig
};
use payments::usdc::USDC;
use std::type_name::{Self, TypeName};
use sui::clock;
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
