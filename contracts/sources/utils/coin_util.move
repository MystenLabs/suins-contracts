module suins::coin_util {

    use sui::balance;
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::tx_context::TxContext;
    use sui::transfer;
    use suins::entity::{Self, SuiNS};
    use suins::auction::Auction;
    use sui::balance::Balance;

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

    public(friend) fun user_transfer_to_contract(payment: &mut Coin<SUI>, amount: u64, contract: &mut SuiNS) {
        let coin_balance = coin::balance_mut(payment);
        let paid = balance::split(coin_balance, amount);
        balance::join(entity::controller_balance_mut(contract), paid);
    }

    public(friend) fun user_transfer_to_contract_2(payment: &mut Coin<SUI>, amount: u64, receiver: &mut Balance<SUI>) {
        let coin_balance = coin::balance_mut(payment);
        let paid = balance::split(coin_balance, amount);
        balance::join(receiver, paid);
    }

    public(friend) fun contract_transfer_to_address(
        contract: &mut SuiNS,
        amount: u64,
        receiver: address,
        ctx: &mut TxContext
    ) {
        let coin = coin::take(entity::controller_balance_mut(contract), amount, ctx);
        transfer::transfer(coin, receiver);
    }
}
