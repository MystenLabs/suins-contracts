#[test_only]
module payments::ns;

use sui::coin;

public struct NS has drop {}

fun init(witness: NS, ctx: &mut TxContext) {
    let (treasury_cap, metadata) = coin::create_currency<NS>(
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
    init(NS {}, ctx);
}
