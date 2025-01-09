#[test_only]
module payments::usdc;

use sui::coin;

public struct USDC has drop {}

fun init(witness: USDC, ctx: &mut TxContext) {
    let (treasury_cap, metadata) = coin::create_currency<USDC>(
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
    init(USDC {}, ctx);
}
