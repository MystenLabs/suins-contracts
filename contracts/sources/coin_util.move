/// A set of helper functions for transferring coins between accounts and the SuiNS.
module suins::coin_util {

    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::tx_context::TxContext;
    use sui::transfer;
    use suins::suins::{Self, SuiNS};
    use sui::event;

    friend suins::auction;
    friend suins::controller;

    struct PaymentTranferredEvent has copy, drop {
        to: address,
        amount: u64,
    }

    public(friend) fun user_transfer_to_address(
        user_payment: &mut Coin<SUI>,
        amount: u64,
        receiver: address,
        ctx: &mut TxContext
    ) {
        if (amount == 0) return;
        let paid = coin::split(user_payment, amount, ctx);
        transfer::public_transfer(paid, receiver);

        event::emit(PaymentTranferredEvent {
            to: receiver,
            amount,
        })
    }

    public(friend) fun user_transfer_to_suins(suins: &mut SuiNS, user_payment: &mut Coin<SUI>, amount: u64) {
        if (amount == 0) return;
        let coin_balance = coin::balance_mut(user_payment);
        let paid = balance::split(coin_balance, amount);
        balance::join(suins::controller_balance_mut(suins), paid);

        event::emit(PaymentTranferredEvent {
            to: @suins,
            amount,
        })
    }

    public(friend) fun user_transfer_to_auction(auction: &mut Balance<SUI>, user_payment: &mut Coin<SUI>, amount: u64) {
        if (amount == 0) return;
        let coin_balance = coin::balance_mut(user_payment);
        let paid = balance::split(coin_balance, amount);
        balance::join(auction, paid);

        event::emit(PaymentTranferredEvent {
            to: @suins,
            amount,
        })
    }

    public(friend) fun suins_transfer_to_address(
        suins: &mut SuiNS,
        amount: u64,
        user_addr: address,
        ctx: &mut TxContext
    ) {
        if (amount == 0) return;
        let coin = coin::take(suins::controller_balance_mut(suins), amount, ctx);
        transfer::public_transfer(coin, user_addr);

        event::emit(PaymentTranferredEvent {
            to: user_addr,
            amount,
        })
    }

    public(friend) fun auction_transfer_to_address(
        auction: &mut Balance<SUI>,
        amount: u64,
        user_addr: address,
        ctx: &mut TxContext
    ) {
        if (amount == 0) return;
        let coin = coin::take(auction, amount, ctx);
        transfer::public_transfer(coin, user_addr);

        event::emit(PaymentTranferredEvent {
            to: user_addr,
            amount,
        })
    }

    public(friend) fun auction_transfer_to_suins(suins: &mut SuiNS, auction: &mut Balance<SUI>, amount: u64) {
        if (amount == 0) return;
        let paid = balance::split(auction, amount);
        balance::join(suins::controller_balance_mut(suins), paid);

        event::emit(PaymentTranferredEvent {
            to: @suins,
            amount,
        })
    }
}
