// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

#[test_only]
module suins_bbb::testns;

use sui::coin;

public struct TESTNS has drop {}

fun init(witness: TESTNS, ctx: &mut TxContext) {
    let (treasury_cap, metadata) = coin::create_currency<TESTNS>(
        witness,
        6,
        vector[],
        vector[],
        vector[],
        option::none(),
        ctx,
    );

    transfer::public_transfer(metadata, tx_context::sender(ctx));
    transfer::public_transfer(treasury_cap, tx_context::sender(ctx));
}

public fun test_init(ctx: &mut TxContext) {
    init(TESTNS {}, ctx);
}
