module suins::auction {

    use sui::object::UID;
    use sui::table::{Self, Table};
    use sui::tx_context::{Self, TxContext};
    use sui::sui::SUI;
    use sui::balance::{Self, Balance};
    use sui::transfer;
    use sui::object;
    use std::option::{Self, Option};
    use sui::coin::Coin;
    use suins::coin_util;
    use sui::event;
    use std::string::{String, utf8};

    const START_AUCTION_FEE: u64 = 1000;
    const MIN_PRICE: u64 = 1000;
    const AUCTION_PERIOD: u64 = 3; // in epoch
    const REVEAL_PERIOD: u8 = 3; // in epoch
    const AUCTION_STATE_REVEAL: u8 = 1;
    const AUCTION_STATE_OWNED: u8 = 2;
    const AUCTION_STATE_AUCTION: u8 = 3;
    const AUCTION_STATE_OPEN: u8 = 4;

    const EUnauthorized: u64 = 801;
    const EInvalidPhase: u64 = 802;

    struct BidPublicDetail has store, drop {
        bidder: address,
        bid_amount: u64,
        // TODO: in epoch atm
        creation_date: u64,
    }

    struct Entry has store {
        registration_date: u64,
        highest_bid: u64,
        second_highest_bid: u64,
        winner: address,
    }

    struct Auction has key {
        id: UID,
        // key: seal hash
        seal_bids: Table<String, BidPublicDetail>,
        // key: domain
        entries: Table<String, Entry>,
        balance: Balance<SUI>,
    }

    struct StartAuctionRequestedEvent has copy, drop {
        hash: String,
        requestor: address,
    }

    struct NewBidEvent has copy, drop {
        sender: address,
        seal_bid: String,
        bid_amount: u64,
    }

    struct BidRevealedEvent has copy, drop {
        node: String,
        bidder: address,
        bid_amount: u64,
        status: u8,
    }

    fun init(ctx: &mut TxContext) {
        transfer::share_object(Auction {
            id: object::new(ctx),
            seal_bids: table::new(ctx),
            entries: table::new(ctx),
            balance: balance::zero(),
        });
    }

    public entry fun new_bid(auction: &mut Auction, seal_bid: vector<u8>, bid_amount: u64, payment: &mut Coin<SUI>, ctx: &mut TxContext) {
        let seal_bid = utf8(seal_bid);
        let sender = tx_context::sender(ctx);
        if (table::contains(&auction.seal_bids, seal_bid)) {
            let current_bid =  table::borrow_mut(&mut auction.seal_bids, seal_bid);
            assert!(current_bid.bidder == sender, EUnauthorized);
            current_bid.bid_amount = current_bid.bid_amount + bid_amount;
        } else {
            // TODO: add minPrice lower limit
            let bid = BidPublicDetail {
                bidder: sender,
                bid_amount,
                creation_date: tx_context::epoch(ctx)
            };
            table::add(&mut auction.seal_bids, seal_bid, bid);
        };
        event::emit(NewBidEvent { sender, seal_bid, bid_amount });
        coin_util::user_transfer_to_contract(payment, bid_amount, &mut auction.balance);
    }

    public entry fun unseal_bid(auction: &mut Auction, node: vector<u8>, _salt: vector<u8>, ctx: &mut TxContext) {
        // keccak256
        let seal_bid: String = utf8(b""); // hash from node, salt owner
        // get and remove the bid
        let bid_public_detail = table::remove(&mut auction.seal_bids, seal_bid);
        let node = utf8(node);
        // TODO: what to do if this node hasn't been started
        let entry = table::borrow_mut(&mut auction.entries, node);
        let state = entry_state(entry);

        if (state == AUCTION_STATE_OWNED) {
            // Too late! Bidder loses their bid. Get's his/her money back
            // TODO: contract charges a small amount as a punishment
            coin_util::contract_transfer_to_address(&mut auction.balance, bid_public_detail.bid_amount, bid_public_detail.bidder, ctx);
            event::emit(BidRevealedEvent {
                node,
                bidder: bid_public_detail.bidder,
                bid_amount: bid_public_detail.bid_amount,
                status: 2
            });
        } else if (state == AUCTION_STATE_AUCTION) {
            abort EInvalidPhase
        } else if (state == AUCTION_STATE_OPEN) {
            // TODO: what to do if state is OPEN
            abort 1
        }else if (bid_public_detail.creation_date > entry.registration_date + AUCTION_PERIOD) {
            // in REVEAL phase
            // Bid too late
            // TODO: contract charges a small amount as a punishment
            coin_util::contract_transfer_to_address(&mut auction.balance, bid_public_detail.bid_amount, bid_public_detail.bidder, ctx);
            // event::emit(BidRevealedEvent {
            //     node,
            //     bidder: bid_public_detail.bidder,
            //     bid_amount: bid_public_detail.bid_amount,
            //     status: 2
            // });
        } else if (bid_public_detail.bid_amount > entry.highest_bid) {
            // in REVEAL phase
            // new winner, refund previous highest paid
            coin_util::contract_transfer_to_address(&mut auction.balance, entry.highest_bid, entry.winner, ctx);
            // as vickery auction, previous highest_bid is value to be paid by winner
            entry.second_highest_bid = entry.highest_bid;
            entry.highest_bid = bid_public_detail.bid_amount;
            entry.winner = tx_context::sender(ctx);
        } else if (bid_public_detail.bid_amount > entry.second_highest_bid) {
            // not winner, but affects second place
            entry.second_highest_bid = bid_public_detail.bid_amount;
            coin_util::contract_transfer_to_address(&mut auction.balance, bid_public_detail.bid_amount, bid_public_detail.bidder, ctx);
        }
        // TODO: emit BidRevealedEvent
    }

    // State transitions for names:
    //   Open -> Auction (startAuction)
    //   Auction -> Reveal
    //   Reveal -> Owned
    //   Reveal -> Open (if nobody bid)
    //   Owned -> Open (releaseDeed or invalidateName)

    fun entry_state(_entry: &Entry): u8 {
        AUCTION_STATE_OWNED
    }

    public entry fun request_to_start_auction(auction: &mut Auction, hash: vector<u8>, payment: &mut Coin<SUI>, ctx: &mut TxContext) {
        coin_util::user_transfer_to_contract(payment, START_AUCTION_FEE, &mut auction.balance);
        event::emit(StartAuctionRequestedEvent {
            hash: utf8(hash),
            requestor: tx_context::sender(ctx)
        })
    }

    public fun get_bid(auction: &Auction, seal_bid: vector<u8>): (Option<address>, Option<u64>) {
        let seal_bid = utf8(seal_bid);
        if (table::contains(&auction.seal_bids, seal_bid)) {
            let bid = table::borrow(&auction.seal_bids, seal_bid);
            return (option::some(bid.bidder), option::some(bid.bid_amount))
        };
        (option::none(), option::none())
    }

    #[test_only]
    /// Wrapper of module initializer for testing
    public fun test_init(ctx: &mut TxContext) {
        transfer::share_object(Auction {
            id: object::new(ctx),
            seal_bids: table::new(ctx),
            entries: table::new(ctx),
            balance: balance::zero(),
        });
    }
}
