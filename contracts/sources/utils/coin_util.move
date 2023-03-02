module suins::coin_util {

    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::tx_context::TxContext;
    use sui::transfer;
    use suins::entity::{Self, SuiNS};

    friend suins::auction;
    friend suins::controller;

    public(friend) fun user_transfer_to_address(
        payment: &mut Coin<SUI>,
        amount: u64,
        receiver: address,
        ctx: &mut TxContext
    ) {
        let paid = coin::split(payment, amount, ctx);
        transfer::transfer(paid, receiver);
    }

    public(friend) fun user_transfer_to_contract(user_payment: &mut Coin<SUI>, amount: u64, contract: &mut SuiNS) {
        let coin_balance = coin::balance_mut(user_payment);
        let paid = balance::split(coin_balance, amount);
        balance::join(entity::controller_balance_mut(contract), paid);
    }

    public(friend) fun user_transfer_to_auction(user_payment: &mut Coin<SUI>, amount: u64, auction: &mut Balance<SUI>) {
        let coin_balance = coin::balance_mut(user_payment);
        let paid = balance::split(coin_balance, amount);
        balance::join(auction, paid);
    }

    public(friend) fun contract_transfer_to_address(
        contract: &mut SuiNS,
        amount: u64,
        user_addr: address,
        ctx: &mut TxContext
    ) {
        let coin = coin::take(entity::controller_balance_mut(contract), amount, ctx);
        transfer::transfer(coin, user_addr);
    }

    public(friend) fun auction_transfer_to_address(
        auction: &mut Balance<SUI>,
        amount: u64,
        user_addr: address,
        ctx: &mut TxContext
    ) {
        let coin = coin::take(auction, amount, ctx);
        transfer::transfer(coin, user_addr);
    }
}
