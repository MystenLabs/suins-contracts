module suins::coin_util {

    use sui::coin;
    use sui::balance::Balance;
    use sui::sui::SUI;
    use sui::tx_context::TxContext;
    use sui::transfer;
    use sui::coin::Coin;
    use sui::balance;

    friend suins::auction;
    friend suins::controller;

    public(friend) fun transfer(payment: &mut Coin<SUI>, amount: u64, receiver: address, ctx: &mut TxContext) {
        let coin = coin::split(payment, amount, ctx);
        transfer::transfer(coin, receiver);
    }

    public(friend) fun pay_fee(payment: &mut Coin<SUI>, amount: u64, receiver: &mut Balance<SUI>) {
        let coin_balance = coin::balance_mut(payment);
        let paid = balance::split(coin_balance, amount);
        balance::join(receiver, paid);
    }
}
