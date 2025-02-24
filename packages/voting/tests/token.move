/// This module will be completely removed.
/// This is only added to simulate a demo token,
/// and allow for testing the voting module.
///
/// It also exposes a faucet that mints tokens for testing on demand with a
/// simple PTB.
///
/// This will be replaced with the actual "NS" token.
#[test_only]
module suins_voting::token;

use sui::coin::{Self, Coin, TreasuryCap};

public struct TOKEN has drop {}

public struct FaucetForTesting has key {
    id: UID,
    treasury: TreasuryCap<TOKEN>,
}

fun init(witness: TOKEN, ctx: &mut TxContext) {
    let (treasury, metadata) = coin::create_currency(
        witness,
        6,
        b"TEST_TOKEN",
        b"",
        b"",
        option::none(),
        ctx,
    );
    transfer::public_freeze_object(metadata);

    transfer::share_object(FaucetForTesting {
        id: object::new(ctx),
        treasury,
    });
}

public fun mint(
    faucet: &mut FaucetForTesting,
    amount: u64,
    ctx: &mut TxContext,
) {
    transfer::public_transfer(faucet.treasury.mint(amount, ctx), ctx.sender());
}

#[test_only]
public fun mint_for_testing(amount: u64, ctx: &mut TxContext): Coin<TOKEN> {
    coin::mint_for_testing<TOKEN>(amount, ctx)
}
