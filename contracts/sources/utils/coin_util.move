module suins::coin_util {

    use sui::coin;
    use sui::balance::Balance;
    use sui::sui::SUI;
    use sui::tx_context::TxContext;
    use sui::transfer;
    use sui::coin::Coin;
    use sui::balance;

    friend suins::controller;

    public(friend) fun user_transfer_to_address(payment: &mut Coin<SUI>, amount: u64, receiver: address, ctx: &mut TxContext) {
        let paid = coin::split(payment, amount, ctx);
        transfer::transfer(paid, receiver);
    }

    public(friend) fun user_transfer_to_contract(payment: &mut Coin<SUI>, amount: u64, receiver: &mut Balance<SUI>) {
        let coin_balance = coin::balance_mut(payment);
        let paid = balance::split(coin_balance, amount);
        balance::join(receiver, paid);
    }

    public(friend) fun contract_transfer_to_address(balance: &mut Balance<SUI>, amount: u64, receiver: address, ctx: &mut TxContext) {
        let coin = coin::take(balance, amount, ctx);
        transfer::transfer(coin, receiver);
    }
}
