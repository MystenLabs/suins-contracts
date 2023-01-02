module suins::auction {

    use sui::object::UID;
    use sui::table::{Self, Table};
    use sui::tx_context::{Self, TxContext};
    use sui::sui::SUI;
    use sui::balance::{Self, Balance};
    use sui::transfer;
    use sui::object;
    use std::option::{Self, Option};
    use std::ascii::{Self, String};
    use sui::coin::Coin;
    use suins::coin_util;

    const EUnauthorized: u64 = 801;

    struct Bid has store {
        owner: address,
        bid_amount: u64,
    }

    struct Auction has key {
        id: UID,
        seal_bids: Table<String, Bid>,
        balance: Balance<SUI>,
    }

    fun init(ctx: &mut TxContext) {
        transfer::share_object(Auction {
            id: object::new(ctx),
            seal_bids: table::new(ctx),
            balance: balance::zero(),
        });
    }

    public entry fun new_bid(auction: &mut Auction, seal_bid: vector<u8>, bid_amount: u64, payment: &mut Coin<SUI>, ctx: &mut TxContext) {
        let seal_bid = ascii::string(seal_bid);
        let sender = tx_context::sender(ctx);
        if (table::contains(&auction.seal_bids, seal_bid)) {
            let current_bid =  table::borrow_mut(&mut auction.seal_bids, seal_bid);
            // TODO: do we allow people to increase bid amount of others
            assert!(current_bid.owner == sender, EUnauthorized);
            current_bid.bid_amount = current_bid.bid_amount + bid_amount;
        } else {
            let bid = Bid { owner: sender, bid_amount };
            table::add(&mut auction.seal_bids, seal_bid, bid);
        };
        coin_util::pay_fee(payment, bid_amount, &mut auction.balance);
    }

    public fun get_bid(auction: &Auction, seal_bid: vector<u8>): (Option<address>, Option<u64>) {
        let seal_bid = ascii::string(seal_bid);
        if (table::contains(&auction.seal_bids, seal_bid)) {
            let bid = table::borrow(&auction.seal_bids, seal_bid);
            return (option::some(bid.owner), option::some(bid.bid_amount))
        };
        (option::none(), option::none())
    }

    #[test_only]
    /// Wrapper of module initializer for testing
    public fun test_init(ctx: &mut TxContext) {
        transfer::share_object(Auction {
            id: object::new(ctx),
            seal_bids: table::new(ctx),
            balance: balance::zero(),
        });
    }
}
