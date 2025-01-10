// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

#[test_only]
module payments::payments_tests;

use payments::payments::PaymentsApp;
use sui::coin;
use suins::payment_tests::setup_suins;
use suins::suins::{Self, SuiNS, AdminCap};

public struct PaymentTestsCurrency has drop {}

public fun setup(ctx: &mut TxContext): (SuiNS, AdminCap) {
    let mut suins = setup_suins(ctx);
    let admin_cap = suins::create_admin_cap_for_testing(ctx);

    // let config =

    admin_cap.authorize_app<PaymentsApp>(&mut suins);
    (suins, admin_cap)
}
