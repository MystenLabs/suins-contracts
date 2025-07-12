#[test_only]
module suins_bbb::fakecoin;

use sui::{
    coin::{Self},
    url,
};

const DECIMALS: u8 = 9;
const TOTAL_SUPPLY: u64 = 100_000_000 * 1_000_000_000; // 100 million coins * 9 decimals

const SYMBOL: vector<u8> = b"FAKE";
const NAME: vector<u8> = b"FakeCoin";
const DESCRIPTION: vector<u8> = b"An example immutable coin";
const ICON_URL: vector<u8> = b"https://example.com/logo.png";

public struct FAKECOIN has drop {}

fun init(otw: FAKECOIN, ctx: &mut TxContext)
{
    // Create the coin
    let (mut treasury, metadata) = coin::create_currency(
        otw,
        DECIMALS,
        SYMBOL,
        NAME,
        DESCRIPTION,
        option::some(url::new_unsafe_from_bytes(ICON_URL)),
        ctx,
    );

    // Mint the supply and transfer it to the sender
    let recipient = tx_context::sender(ctx);
    coin::mint_and_transfer(&mut treasury, TOTAL_SUPPLY, recipient, ctx);

    // Make the metadata immutable
    transfer::public_freeze_object(metadata);

    // Fix the supply
    transfer::public_transfer(treasury, @0x0);
}

#[test_only]
public fun init_for_testing(ctx: &mut TxContext) {
    init(FAKECOIN {}, ctx);
}
