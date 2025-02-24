/// This allows us to create a new token and mint the total tokens to the publisher.
/// This also wraps the `TreasuryCap`
///
/// After publishing this, we will burn the `UpgradeCap`.
/// This will validate that the supply of minted NS cannot change.
module token::ns;

use sui::coin::{Self, Coin, TreasuryCap};
use sui::dynamic_object_field as dof;
use sui::url;

const TOTAL_SUPPLY_TO_MINT: u64 = 500_000_000 * 1_000_000;
const DECIMALS: u8 = 6;
const SYMBOL: vector<u8> = b"NS";
const NAME: vector<u8> = b"SuiNS Token";
const DESCRIPTION: vector<u8> = b"The native token for the SuiNS Protocol.";
const ICON_URL: vector<u8> = b"https://token-image.suins.io/icon.svg";

/// The OTW for our token.
public struct NS has drop {}

public struct ProtectedTreasury has key {
    id: UID,
}

/// The dynamic object field key for the `TreasuryCap`.
/// That allows us to easily look-up the `TreasuryCap` from the `ProtectedTreasury` off-chain.
public struct TreasuryCapKey has copy, store, drop {}

#[allow(unused_function, lint(share_owned))]
fun init(otw: NS, ctx: &mut TxContext) {
    let (protected_treasury, coin) = create_coin(otw, TOTAL_SUPPLY_TO_MINT, ctx);

    transfer::share_object(protected_treasury);

    transfer::public_transfer(coin, ctx.sender());
}

/// Get the total supply of the NS token.
public fun total_supply(treasury: &ProtectedTreasury): u64 {
    treasury.borrow_cap().total_supply()
}

/// Borrows the `TreasuryCap` from the `ProtectedTreasury`.
fun borrow_cap(treasury: &ProtectedTreasury): &TreasuryCap<NS> {
    dof::borrow(&treasury.id, TreasuryCapKey {})
}

#[allow(lint(share_owned))]
/// Internal function to serve both the `init` case and
/// the `init_for_testing` case.
fun create_coin(otw: NS, amount: u64, ctx: &mut TxContext): (ProtectedTreasury, Coin<NS>) {
    let (mut cap, metadata) = coin::create_currency(
        otw,
        DECIMALS,
        SYMBOL,
        NAME,
        DESCRIPTION,
        option::some(url::new_unsafe_from_bytes(ICON_URL)),
        ctx,
    );

    let minted_coin = cap.mint(amount, ctx);

    transfer::public_freeze_object(metadata);

    // Wrap the `TreasuryCap` and share it.
    let mut protected_treasury = ProtectedTreasury {
        id: object::new(ctx),
    };

    dof::add(&mut protected_treasury.id, TreasuryCapKey {}, cap);

    (protected_treasury, minted_coin)
}

#[test_only]
public fun init_for_testing(amount: u64, ctx: &mut TxContext): Coin<NS> {
    let (treasury, coin) = create_coin(NS {}, amount, ctx);
    transfer::share_object(treasury);
    coin
}
