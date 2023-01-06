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
    use std::vector;
    use std::bcs;
    use sui::ecdsa_k1::keccak256;
    use suins::base_registrar::BaseRegistrar;
    use suins::base_registry::Registry;
    use suins::configuration::Configuration;
    use suins::base_registrar;

    const START_AUCTION_FEE: u64 = 1000;
    const MIN_PRICE: u64 = 1000;
    const AUCTION_PERIOD: u64 = 3; // in epoch
    const REVEAL_PERIOD: u64 = 3; // in epoch
    const AUCTION_STATE_NOT_AVAILABLE: u8 = 0;
    const AUCTION_STATE_OPEN: u8 = 1;
    const AUCTION_STATE_AUCTION: u8 = 2;
    const AUCTION_STATE_REVEAL: u8 = 3;
    const AUCTION_STATE_OWNED: u8 = 4;

    const EUnauthorized: u64 = 801;
    const EInvalidPhase: u64 = 802;

    struct BidPublicDetail has store, drop {
        bidder: address,
        bid_amount: u64,
        // TODO: in epoch atm
        creation_date: u64,
    }

    struct Entry has store {
        start_date: u64,
        highest_bid: u64,
        second_highest_bid: u64,
        winner: address,
    }

    struct Auction has key {
        id: UID,
        // key: seal hash
        seal_bids: Table<vector<u8>, BidPublicDetail>,
        // key: domain hash
        entries: Table<vector<u8>, Entry>,
        balance: Balance<SUI>,
        auction_launch_date: u64,
        auction_launch_length: u64,
    }

    struct StartAuctionRequestedEvent has copy, drop {
        hash: String,
        requestor: address,
    }

    struct NodeRegisteredEvent has copy, drop {
        node: String,
        winner: address,
        amount: u64,
    }

    struct NewBidEvent has copy, drop {
        sender: address,
        seal_bid: vector<u8>,
        bid_amount: u64,
    }

    struct BidRevealedEvent has copy, drop {
        node: String,
        bidder: address,
        bid_amount: u64,
    }

    fun init(ctx: &mut TxContext) {
        transfer::share_object(Auction {
            id: object::new(ctx),
            seal_bids: table::new(ctx),
            entries: table::new(ctx),
            balance: balance::zero(),
        });
    }

    fun make_seal_bid(node: vector<u8>, owner: address, salt: vector<u8>): vector<u8> {
        let owner = bcs::to_bytes(&owner);
        vector::append(&mut node, owner);
        vector::append(&mut node, salt);
        keccak256(&node)
    }

    public entry fun new_bid(auction: &mut Auction, seal_bid: vector<u8>, bid_amount: u64, payment: &mut Coin<SUI>, ctx: &mut TxContext) {
        // TODO: current_epoch in [bidding_start, bidding_end]
        // TODO: want to hide bid amount, so don't allow to augment bid amount
        let sender = tx_context::sender(ctx);
        if (table::contains(&auction.seal_bids, seal_bid)) {
            let current_bid_detail =  table::borrow_mut(&mut auction.seal_bids, seal_bid);
            assert!(current_bid_detail.bidder == sender, EUnauthorized);
            current_bid_detail.bid_amount = current_bid_detail.bid_amount + bid_amount;
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

    // // Cancels an unrevealed bid
    // public entry fun cancel_bid(auction: &mut Auction, seal_bid: vector<u8>, ctx: &mut TxContext) {
    //     // TODO:
    // }

    // Cancels an unrevealed bid
    public entry fun finalize_auction(
        auction: &mut Auction,
        registrar: &mut BaseRegistrar,
        registry: &mut Registry,
        config: &Configuration,
        node: vector<u8>,
        ctx: &mut TxContext
    ) {
        // TODO: check registrar base_node
        let node_str = utf8(node);
        let entry = table::borrow_mut(&mut auction.entries, node_str);
        assert!(entry.winner == tx_context::sender(ctx), EUnauthorized);
        let state = state(entry);
        assert!(state == AUCTION_STATE_OWNED, EInvalidPhase);
        // TODO: where to find default_resolver_address
        base_registrar::register(registrar, registry, config, node, entry.winner, 1, @0x0, ctx);
        event::emit(NodeRegisteredEvent {
            node: node_str,
            winner: entry.winner,
            amount: entry.second_highest_bid
        })
    }

    public entry fun unseal_bid(auction: &mut Auction, node: vector<u8>, salt: vector<u8>, ctx: &mut TxContext) {
        // assert now > bidding_end
        // keccak256
        let seal_bid = make_seal_bid(node, tx_context::sender(ctx), salt); // hash from node, salt owner
        // get and remove the bid
        let bid_public_detail = table::remove(&mut auction.seal_bids, seal_bid);
        let node = utf8(node);
        // TODO: validate domain name
        // TODO: what to do if this node hasn't been started
        let entry = table::borrow_mut(&mut auction.entries, node);
        let state = state(entry);

        // TODO: what if node is reopened
        if (state == AUCTION_STATE_OWNED) {
            // Too late! Bidder loses their bid. Get's his/her money back
            // TODO: contract charges a small amount as a punishment
            coin_util::contract_transfer_to_address(&mut auction.balance, bid_public_detail.bid_amount, bid_public_detail.bidder, ctx);
        } else if (state == AUCTION_STATE_AUCTION) {
            abort EInvalidPhase
        } else if (state == AUCTION_STATE_OPEN) {
            // TODO: what to do if state is OPEN
            abort EInvalidPhase
        } else if (bid_public_detail.creation_date > entry.start_date + AUCTION_PERIOD) {
            // in REVEAL phase
            // Bid too late
            // TODO: contract charges a small amount as a punishment
            coin_util::contract_transfer_to_address(&mut auction.balance, bid_public_detail.bid_amount, bid_public_detail.bidder, ctx);
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
        };
        event::emit(BidRevealedEvent {
            node,
            bidder: bid_public_detail.bidder,
            bid_amount: bid_public_detail.bid_amount,
        })
    }

    // State transitions for names:
    // Open -> Auction (startAuction) -> Reveal -> Owned
    fun state(auction: &Auction, domain_hash: vector<u8>, ctx: &mut TxContext): u8 {
        let current_epoch = tx_context::epoch(ctx);
        if (current_epoch < auction.auction_launch_date) return AUCTION_STATE_NOT_AVAILABLE;
        if (table::contains(&auction.entries, domain_hash)) {
            let entry = table::borrow(&auction.entries, domain_hash);
            if (current_epoch < entry.start_date + AUCTION_PERIOD) return AUCTION_STATE_AUCTION;
            if (current_epoch < entry.start_date + AUCTION_PERIOD + REVEAL_PERIOD) return AUCTION_STATE_REVEAL;
            return AUCTION_STATE_OWNED;
        };
        AUCTION_STATE_OPEN
    }

    // domain_hash = keccak256(domain_name)
    public entry fun start_auction(auction: &mut Auction, domain_hash: vector<u8>, payment: &mut Coin<SUI>, ctx: &mut TxContext) {
        // let current_epoch = tx_context::epoch(ctx);
        // assert!(
        //     auction.auction_launch_date < current_epoch
        //         && current_epoch < auction.auction_launch_date + auction.auction_launch_length,
        //     EInvalidPhase
        // );
        coin_util::user_transfer_to_contract(payment, START_AUCTION_FEE, &mut auction.balance);
        event::emit(StartAuctionRequestedEvent {
            hash: utf8(hash),
            requestor: tx_context::sender(ctx)
        })
    }

    public fun get_bid(auction: &Auction, seal_bid: vector<u8>): (Option<address>, Option<u64>) {
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
