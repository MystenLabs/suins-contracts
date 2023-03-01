module suins::coin_util {

    use sui::coin;
    use sui::balance::Balance;
    use sui::sui::SUI;
    use sui::tx_context::TxContext;
    use sui::transfer;
    use sui::coin::Coin;
    use sui::balance;
    use suins::abc::SuiNS;
    use suins::abc;

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
        balance::join(abc::controller_balance_mut(contract), paid);
    }

    public(friend) fun contract_transfer_to_address(
        contract: &mut SuiNS,
        amount: u64,
        receiver: address,
        ctx: &mut TxContext
    ) {
        let coin = coin::take(abc::controller_balance_mut(contract), amount, ctx);
        transfer::transfer(coin, receiver);
    }
}
