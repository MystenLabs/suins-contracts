module suins::coin_util {

    use sui::coin;
    use sui::balance::Balance;
    use sui::sui::SUI;
    use sui::tx_context::TxContext;
    use sui::transfer;

    friend suins::auction;

    public(friend) fun transfer(balance: &mut Balance<SUI>, amount: u64, receiver: address, ctx: &mut TxContext) {
        let coin = coin::take(balance, amount, ctx);
        transfer::transfer(coin, receiver);
    }
}
