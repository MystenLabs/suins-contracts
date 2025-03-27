// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

#[test_only]
module suins_payments::payments_tests;

use std::{string::utf8, type_name};
use sui::{coin::{Self, CoinMetadata}, test_scenario::{Self as ts, ctx}, test_utils::destroy};
use suins::{payment, payment_tests::setup_suins, suins::{Self, SuiNS, AdminCap}};
use suins_payments::{
    payments::{
        new_payments_config,
        new_coin_type_data,
        handle_base_payment,
        PaymentsApp,
        PaymentsConfig
    },
    testns::TESTNS,
    testusdc::TESTUSDC
};

public struct PaymentTestsCurrency has drop {}
public struct SPAM has drop {}

const SUINS_ADDRESS: address = @0xA001;

public fun setup(ctx: &mut TxContext): (SuiNS, AdminCap) {
    let mut suins = setup_suins(ctx);
    let admin_cap = suins::create_admin_cap_for_testing(ctx);
    admin_cap.authorize_app<PaymentsApp>(&mut suins);

    suins_payments::testusdc::test_init(ctx);
    suins_payments::testns::test_init(ctx);

    (suins, admin_cap)
}

#[test, expected_failure(abort_code = ::suins_payments::payments::EBaseCurrencySetupMissing)]
fun base_currency_not_in_list_e() {
    let mut test = ts::begin(SUINS_ADDRESS);
    let (_suins, _admin_cap) = setup(test.ctx());

    test.next_tx(SUINS_ADDRESS);
    let usdc_metadata = test.take_from_sender<CoinMetadata<TESTUSDC>>();
    let usdc_type_data = new_coin_type_data<TESTUSDC>(
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

#[test, expected_failure(abort_code = ::suins_payments::payments::EInsufficientPayment)]
fun payment_insufficient_e() {
    let mut test = ts::begin(SUINS_ADDRESS);
    let (mut suins, admin_cap) = setup(test.ctx());

    test.next_tx(SUINS_ADDRESS);
    let usdc_metadata = test.take_from_sender<CoinMetadata<TESTUSDC>>();
    let usdc_type_data = new_coin_type_data<TESTUSDC>(
        &usdc_metadata,
        0,
        vector[],
    );
    let mut setups = vector[];
    setups.push_back(usdc_type_data);

    let config = new_payments_config(
        setups,
        type_name::get<TESTUSDC>(),
        60,
    );

    admin_cap.add_config<PaymentsConfig>(&mut suins, config);

    test.next_tx(SUINS_ADDRESS);
    let intent = payment::init_registration(
        &mut suins,
        utf8(b"helloworld.sui"),
    );

    // 20 is required for registration, only 10 is minted
    let _receipt = handle_base_payment<TESTUSDC>(
        &mut suins,
        intent,
        coin::mint_for_testing<TESTUSDC>(10, test.ctx()),
    );

    abort 1337
}

#[test, expected_failure(abort_code = ::suins_payments::payments::EInvalidPaymentType)]
fun invalid_payment_type_e() {
    let mut test = ts::begin(SUINS_ADDRESS);
    let (mut suins, admin_cap) = setup(test.ctx());

    test.next_tx(SUINS_ADDRESS);
    let usdc_metadata = test.take_from_sender<CoinMetadata<TESTUSDC>>();
    let usdc_type_data = new_coin_type_data<TESTUSDC>(
        &usdc_metadata,
        0,
        vector[],
    );
    let mut setups = vector[];
    setups.push_back(usdc_type_data);

    let config = new_payments_config(
        setups,
        type_name::get<TESTUSDC>(),
        60,
    );

    admin_cap.add_config<PaymentsConfig>(&mut suins, config);

    test.next_tx(SUINS_ADDRESS);
    let intent = payment::init_registration(
        &mut suins,
        utf8(b"helloworld.sui"),
    );

    // 20 is required for registration, paying with SPAM fails
    let _receipt = handle_base_payment<SPAM>(
        &mut suins,
        intent,
        coin::mint_for_testing<SPAM>(20, test.ctx()),
    );

    abort 1337
}

#[test]
fun test_add_payment_config() {
    let mut test = ts::begin(SUINS_ADDRESS);
    let (mut suins, admin_cap) = setup(test.ctx());

    test.next_tx(SUINS_ADDRESS);
    let usdc_metadata = test.take_from_sender<CoinMetadata<TESTUSDC>>();
    let usdc_type_data = new_coin_type_data<TESTUSDC>(
        &usdc_metadata,
        0,
        vector[],
    );
    let ns_metadata = test.take_from_sender<CoinMetadata<TESTNS>>();
    let ns_type_data = new_coin_type_data<TESTNS>(
        &ns_metadata,
        25,
        vector[],
    );
    let mut setups = vector[];
    setups.push_back(usdc_type_data);
    setups.push_back(ns_type_data);

    let config = new_payments_config(
        setups,
        type_name::get<TESTUSDC>(),
        60,
    );

    admin_cap.add_config<PaymentsConfig>(&mut suins, config);

    test.next_tx(SUINS_ADDRESS);
    let intent = payment::init_registration(
        &mut suins,
        utf8(b"helloworld.sui"),
    );

    // 20 is required for registration, paying with 20 usdc is successful
    let receipt = handle_base_payment<TESTUSDC>(
        &mut suins,
        intent,
        coin::mint_for_testing<TESTUSDC>(20, test.ctx()),
    );

    test.return_to_sender(usdc_metadata);
    test.return_to_sender(ns_metadata);

    destroy(receipt);
    destroy(admin_cap);
    destroy(suins);
    test.end();
}
