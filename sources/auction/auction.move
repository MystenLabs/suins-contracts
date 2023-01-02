module suins::auction {

    use sui::object::UID;
    use sui::table::{Self, Table};
    use std::ascii::String;
    use std::ascii;
    use sui::tx_context::TxContext;
    use sui::tx_context;
    use sui::sui::SUI;
    use sui::balance::Balance;
    use sui::coin;
    use sui::balance;
    use suins::coin_util;
    use sui::vec_set;
    use sui::vec_set::VecSet;

    struct Bid has store {
        seal: String,
        amount: u64,
    }

    struct Auction has key {
        id: UID,
        seal_bids: Table<address, VecSet<Bid>>,
        balance: Balance<SUI>,
    }

    public entry fun new_bid(auction: &mut Auction, seal_bid: vector<u8>, bid_amount: u64, ctx: &mut TxContext) {
        let seal_bid = ascii::string(seal_bid);
        let sender = tx_context::sender(ctx);
        if (table::contains(&auction.seal_bids, sender)) {
            let current_bids =  table::borrow(&auction.seal_bids, sender);
            if (vec_set::) {

            }
            let current_amount = current_bid.amount;

            if (bid_amount > cu)
        }
    }
}