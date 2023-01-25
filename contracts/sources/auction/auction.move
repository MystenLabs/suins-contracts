module suins::auction {

    use sui::object::UID;
    use sui::table::{Self, Table};
    use sui::tx_context::{Self, TxContext};
    use sui::sui::SUI;
    use sui::balance::{Self, Balance};
    use sui::transfer;
    use sui::object;
    use sui::ecdsa_k1::keccak256;
    use sui::coin::Coin;
    use sui::event;
    use std::option::{Self, Option, none, some};
    use std::string::{String, utf8};
    use std::vector;
    use std::bcs;
    use suins::base_registrar::{Self, BaseRegistrar};
    use suins::base_registry::{Registry, AdminCap};
    use suins::configuration::Configuration;
    use suins::coin_util;
    use suins::emoji;
    use suins::configuration;

    const MIN_PRICE: u64 = 1000;
    const FEE_PER_YEAR: u64 = 10000;
    const BIDDING_PERIOD: u64 = 1;
    const REVEAL_PERIOD: u64 = 1;
    const AUCTION_STATE_NOT_AVAILABLE: u8 = 0;
    const AUCTION_STATE_OPEN: u8 = 1;
    const AUCTION_STATE_PENDING: u8 = 2;
    const AUCTION_STATE_BIDDING: u8 = 3;
    const AUCTION_STATE_REVEAL: u8 = 4;
    const AUCTION_STATE_FINALIZING: u8 = 5;
    const AUCTION_STATE_OWNED: u8 = 6;
    const AUCTION_STATE_REOPENED: u8 = 7;

    const EUnauthorized: u64 = 801;
    const EInvalidPhase: u64 = 802;
    const EAuctionNotAvailable: u64 = 803;
    const EBidExisted: u64 = 804;
    const EInvalidBid: u64 = 805;
    const EBidAlreadyStart: u64 = 806;
    const EInvalidBidMask: u64 = 807;
    const EInvalidBidValue: u64 = 807;
    const EInvalidConfigParam: u64 = 808;
    const EInvalidRegistrar: u64 = 809;
    const EShouldNotHappen: u64 = 810;
    const EAlreadyFinalized: u64 = 811;
    const EAlreadyUnsealed: u64 = 812;

    struct BidDetail has store, copy, drop {
        bidder: address,
        // upper limit of the actual bid value to hide the real value
        bid_value_mask: u64,
        // 0 for unknowned value
        bid_value: u64,
        // empty for unknowned
        node: String,
        created_at: u64,
        seal_bid: vector<u8>,
        is_unsealed: bool,
    }

    // info of each auction this is ongoing or over
    struct AuctionEntry has store, drop {
        start_at: u64,
        highest_bid: u64,
        second_highest_bid: u64,
        winner: address,
        is_finalized: bool,
    }

    struct Auction has key {
        id: UID,
        // key: seal hash
        // bid_detail_by_seal_bid: Table<vector<u8>, BidDetail>,
        bid_details_by_bidder: Table<address, vector<BidDetail>>,
        /// list of bids that are unsealed
        /// unsealed_bids: {
        ///   suins.sui: {
        ///     0xabc: [bid1, bid2],
        ///   },
        /// }
        // unsealed_bids: Table<String, Table<address, VecSet<BidDetail>>>,
        // key: node
        entries: Table<String, AuctionEntry>,
        balance: Balance<SUI>,
        auction_start_at: u64,
        auction_end_at: u64,
    }

    struct NodeRegisteredEvent has copy, drop {
        node: String,
        winner: address,
        amount: u64,
    }

    struct NewBidEvent has copy, drop {
        bidder: address,
        seal_bid: vector<u8>,
        bid_value_mask: u64,
    }

    struct BidRevealedEvent has copy, drop {
        node: String,
        bidder: address,
        bid_value: u64,
    }

    struct AuctionStartedEvent has copy, drop {
        node: String,
        start_at: u64,
    }

    fun init(ctx: &mut TxContext) {
        transfer::share_object(Auction {
            id: object::new(ctx),
            // bid_detail_by_seal_bid: table::new(ctx),
            bid_details_by_bidder: table::new(ctx),
            // unsealed_bids: table::new(ctx),
            entries: table::new(ctx),
            balance: balance::zero(),
            auction_start_at: 0,
            auction_end_at: 0,
        });
    }

    public entry fun config_auction(_: &AdminCap, auction: &mut Auction, start_at: u64, end_at: u64, ctx: &mut TxContext) {
        assert!(start_at < end_at, EInvalidConfigParam);
        assert!(tx_context::epoch(ctx) <= start_at, EInvalidConfigParam);
        auction.auction_start_at = start_at;
        auction.auction_end_at = end_at;
    }

    // used by bidder
    // TODO: do we allow winner to withdraw?
    // TODO: noway to check winner right now
    public entry fun withdraw(auction: &mut Auction, ctx: &mut TxContext) {
        assert!(tx_context::epoch(ctx) > auction.auction_end_at, EInvalidPhase);

        let sender = tx_context::sender(ctx);
        let bid_details = table::remove(&mut auction.bid_details_by_bidder, sender);
        let len = vector::length(&bid_details);
        let index = 0;

        while(index < len) {
            let detail = vector::borrow(&bid_details, index);
            coin_util::contract_transfer_to_address(&mut auction.balance, detail.bid_value_mask, detail.bidder, ctx);
            index = index + 1;
        };
    }

    // testing only
    public entry fun withdraw_with_epoch(auction: &mut Auction, epoch: u64, ctx: &mut TxContext) {
        assert!(epoch > auction.auction_end_at, EInvalidPhase);

        let sender = tx_context::sender(ctx);
        let bid_details = table::remove(&mut auction.bid_details_by_bidder, sender);
        let len = vector::length(&bid_details);
        let index = 0;

        while(index < len) {
            let detail = vector::borrow(&bid_details, index);
            coin_util::contract_transfer_to_address(&mut auction.balance, detail.bid_value_mask, detail.bidder, ctx);
            index = index + 1;
        };
    }

    /// Return index of bid if exists
    fun seal_bid_exists(bids: &vector<BidDetail>, seal_bid: vector<u8>): Option<u64> {
        let len = vector::length(bids);
        let index = 0;

        while(index < len) {
            let detail = vector::borrow(bids, index);
            if (detail.seal_bid == seal_bid) {
                return some(index)
            };
            index = index + 1;
        };
        none()
    }

    public entry fun new_bid(auction: &mut Auction, seal_bid: vector<u8>, bid_value_mask: u64, payment: &mut Coin<SUI>, ctx: &mut TxContext) {
        let current_epoch = tx_context::epoch(ctx);
        assert!(
            auction.auction_start_at <= current_epoch && current_epoch <= auction.auction_end_at,
            EAuctionNotAvailable,
        );
        assert!(bid_value_mask >= MIN_PRICE, EInvalidBid);

        if (!table::contains(&auction.bid_details_by_bidder, tx_context::sender(ctx))) {
            table::add(&mut auction.bid_details_by_bidder, tx_context::sender(ctx), vector[]);
        };

        let bids_by_sender = table::borrow_mut(&mut auction.bid_details_by_bidder, tx_context::sender(ctx));
        assert!(option::is_none(&seal_bid_exists(bids_by_sender, seal_bid)), EBidExisted);

        let bidder = tx_context::sender(ctx);
        let bid = BidDetail {
            bidder,
            bid_value_mask,
            bid_value: 0,
            node: utf8(vector[]),
            created_at: current_epoch,
            seal_bid,
            is_unsealed: false,
        };
        vector::push_back(bids_by_sender, bid);

        event::emit(NewBidEvent { bidder, seal_bid, bid_value_mask });
        coin_util::user_transfer_to_contract(payment, bid_value_mask, &mut auction.balance);
    }

    public entry fun new_bid_with_epoch(
        auction: &mut Auction,
        seal_bid: vector<u8>,
        bid_value_mask: u64,
        payment: &mut Coin<SUI>,
        epoch: u64,
        ctx: &mut TxContext
    ) {
        let current_epoch = epoch;
        assert!(
            auction.auction_start_at <= current_epoch && current_epoch <= auction.auction_end_at,
            EAuctionNotAvailable,
        );
        assert!(bid_value_mask >= MIN_PRICE, EInvalidBid);

        if (!table::contains(&auction.bid_details_by_bidder, tx_context::sender(ctx))) {
            table::add(&mut auction.bid_details_by_bidder, tx_context::sender(ctx), vector[]);
        };

        let bids_by_sender = table::borrow_mut(&mut auction.bid_details_by_bidder, tx_context::sender(ctx));
        assert!(option::is_none(&seal_bid_exists(bids_by_sender, seal_bid)), EBidExisted);

        let bidder = tx_context::sender(ctx);
        let bid = BidDetail {
            bidder,
            bid_value_mask,
            bid_value: 0,
            node: utf8(vector[]),
            created_at: current_epoch,
            seal_bid,
            is_unsealed: false,
        };
        vector::push_back(bids_by_sender, bid);

        event::emit(NewBidEvent { bidder, seal_bid, bid_value_mask });
        coin_util::user_transfer_to_contract(payment, bid_value_mask, &mut auction.balance);
    }

    public entry fun finalize_auction(
        auction: &mut Auction,
        registrar: &mut BaseRegistrar,
        registry: &mut Registry,
        config: &Configuration,
        node: vector<u8>,
        resolver: address,
        ctx: &mut TxContext
    ) {
        // TODO: what to do with .move?
        assert!(base_registrar::get_base_node_bytes(registrar) == b"sui", EInvalidRegistrar);
        let auction_state = state(auction, node, ctx);
        assert!(
            auction_state == AUCTION_STATE_FINALIZING
                || auction_state == AUCTION_STATE_REOPENED
                || auction_state == AUCTION_STATE_OWNED,
            EInvalidPhase
        );

        let node_str = utf8(node);
        let entry = table::borrow_mut(&mut auction.entries, node_str);
        let bids_of_sender = table::borrow_mut(&mut auction.bid_details_by_bidder, tx_context::sender(ctx));

        // Refund all the bids
        // TODO: remove bids_of_sender if being empty
        let len = vector::length(bids_of_sender);
        let index = 0;
        while (index < len) {
            if (vector::borrow(bids_of_sender, index).node != node_str) {
                index = index + 1;
                continue
            };

            let detail = vector::remove(bids_of_sender, index);
            len = len - 1;
            if (
                entry.winner == detail.bidder
                    && entry.highest_bid == detail.bid_value
                    && detail.bid_value_mask - detail.bid_value > 0
            ) {
                // send extra money to winner
                coin_util::contract_transfer_to_address(
                    &mut auction.balance,
                    detail.bid_value_mask - detail.bid_value,
                    detail.bidder,
                    ctx
                );
            } else {
                coin_util::contract_transfer_to_address(
                    &mut auction.balance,
                    detail.bid_value_mask,
                    detail.bidder,
                    ctx
                );
            };
        };
        if (entry.winner != tx_context::sender(ctx)) return;
        // winner cannot claim twice
        assert!(!entry.is_finalized, EAlreadyFinalized);

        base_registrar::register(registrar, registry, config, node, entry.winner, 365, resolver, ctx);
        entry.is_finalized = true;
        event::emit(NodeRegisteredEvent {
            node: node_str,
            winner: entry.winner,
            amount: entry.second_highest_bid
        })
    }

    // TODO: testing only
    public entry fun finalize_auction_with_epoch(
        auction: &mut Auction,
        registrar: &mut BaseRegistrar,
        registry: &mut Registry,
        config: &Configuration,
        node: vector<u8>,
        epoch: u64,
        resolver: address,
        ctx: &mut TxContext
    ) {
        // TODO: what to do with .move?
        assert!(base_registrar::get_base_node_bytes(registrar) == b"sui", EInvalidRegistrar);
        let auction_state = state_with_epoch(auction, node, epoch, ctx);
        assert!(
            auction_state == AUCTION_STATE_FINALIZING
                || auction_state == AUCTION_STATE_REOPENED
                || auction_state == AUCTION_STATE_OWNED,
            EInvalidPhase
        );

        let node_str = utf8(node);
        let entry = table::borrow_mut(&mut auction.entries, node_str);
        let bids_of_sender = table::borrow_mut(&mut auction.bid_details_by_bidder, tx_context::sender(ctx));

        // Refund all the bids
        // TODO: remove bids_of_sender if being empty
        let len = vector::length(bids_of_sender);
        let index = 0;
        while (index < len) {
            if (vector::borrow(bids_of_sender, index).node != node_str) {
                index = index + 1;
                continue
            };

            let detail = vector::remove(bids_of_sender, index);
            len = len - 1;
            if (
                entry.winner == detail.bidder
                    && entry.highest_bid == detail.bid_value
                    && detail.bid_value_mask - detail.bid_value > 0
            ) {
                // send extra money to winner
                coin_util::contract_transfer_to_address(
                    &mut auction.balance,
                    detail.bid_value_mask - detail.bid_value,
                    detail.bidder,
                    ctx
                );
            } else {
                coin_util::contract_transfer_to_address(
                    &mut auction.balance,
                    detail.bid_value_mask,
                    detail.bidder,
                    ctx
                );
            };
        };
        if (entry.winner != tx_context::sender(ctx)) return;
        // winner cannot claim twice
        assert!(!entry.is_finalized, EAlreadyFinalized);

        base_registrar::register(registrar, registry, config, node, entry.winner, 365, resolver, ctx);
        entry.is_finalized = true;
        event::emit(NodeRegisteredEvent {
            node: node_str,
            winner: entry.winner,
            amount: entry.second_highest_bid
        })
    }

    // TODO: do we need to validate domain here?
    public entry fun unseal_bid(auction: &mut Auction, node: vector<u8>, value: u64, salt: vector<u8>, ctx: &mut TxContext) {
        let auction_state = state(auction, node, ctx);
        assert!(auction_state == AUCTION_STATE_REVEAL, EInvalidPhase);

        let seal_bid = make_seal_bid(node, tx_context::sender(ctx), value, salt); // hash from node, owner, value, salt
        let bids_by_sender = table::borrow_mut(&mut auction.bid_details_by_bidder, tx_context::sender(ctx));
        let index = seal_bid_exists(bids_by_sender, seal_bid);
        assert!(option::is_some(&index), EInvalidBid);

        let bid_detail = vector::borrow_mut(bids_by_sender, option::extract(&mut index));
        assert!(!bid_detail.is_unsealed, EAlreadyUnsealed);

        let node = utf8(node);
        event::emit(BidRevealedEvent {
            node,
            bidder: tx_context::sender(ctx),
            bid_value: value,
        });

        let entry = table::borrow_mut(&mut auction.entries, *&node);
        if (
            bid_detail.bid_value_mask < value
                || value < MIN_PRICE
                || bid_detail.created_at < entry.start_at
                || entry.start_at + BIDDING_PERIOD <= bid_detail.created_at
        ) {
            // invalid bid
        } else if (value > entry.highest_bid) {
            // vickery auction, winner pay the second highest_bid
            entry.second_highest_bid = entry.highest_bid;
            entry.highest_bid = value;
            entry.winner = bid_detail.bidder;
        } else if (value > entry.second_highest_bid) {
            // not winner, but affects second place
            entry.second_highest_bid = value;
        } else {
            // bid doesn't affect auction
        };
        bid_detail.bid_value = value;
        bid_detail.node = node;
        bid_detail.is_unsealed = true;
    }

    // TODO: validate domain name
    public entry fun start_auction(
        auction: &mut Auction,
        config: &Configuration,
        node: vector<u8>,
        payment: &mut Coin<SUI>,
        ctx: &mut TxContext
    ) {
        let emoji_config = configuration::get_emoji_config(config);
        emoji::validate_label_with_emoji(emoji_config, node, 3, 6);

        let state = state(auction, node, ctx);
        assert!(state == AUCTION_STATE_OPEN || state == AUCTION_STATE_REOPENED, EInvalidPhase);

        let node = utf8(node);
        if (state == AUCTION_STATE_REOPENED) {
            let _ = table::remove(&mut auction.entries, node);
        };
        // current_epoch was validated in `state`
        let start_at = tx_context::epoch(ctx) + 1;
        let entry = AuctionEntry {
            start_at,
            highest_bid: 0,
            second_highest_bid: 0,
            winner: @0x0,
            is_finalized: false,
        };
        table::add(&mut auction.entries, node, entry);
        coin_util::user_transfer_to_contract(payment, FEE_PER_YEAR, &mut auction.balance);
        event::emit(AuctionStartedEvent { node, start_at })
    }

    // TODO: testing only
    public entry fun start_auction_with_epoch(
        auction: &mut Auction,
        node: vector<u8>,
        payment: &mut Coin<SUI>,
        epoch: u64,
        ctx: &mut TxContext
    ) {
        let state = state_with_epoch(auction, node, epoch, ctx);
        assert!(state == AUCTION_STATE_OPEN || state == AUCTION_STATE_REOPENED, EInvalidPhase);

        let node = utf8(node);
        if (state == AUCTION_STATE_REOPENED) {
            let _ = table::remove(&mut auction.entries, node);
        };
        // current_epoch was validated in `state`
        let start_at = epoch + 1;
        let entry = AuctionEntry {
            start_at,
            highest_bid: 0,
            second_highest_bid: 0,
            winner: @0x0,
            is_finalized: false,
        };
        table::add(&mut auction.entries, node, entry);
        coin_util::user_transfer_to_contract(payment, FEE_PER_YEAR, &mut auction.balance);
        event::emit(AuctionStartedEvent { node, start_at })
    }

    public fun make_seal_bid(node: vector<u8>, owner: address, value: u64, salt: vector<u8>): vector<u8> {
        let owner = bcs::to_bytes(&owner);
        vector::append(&mut node, owner);
        let value = bcs::to_bytes(&value);
        vector::append(&mut node, value);
        vector::append(&mut node, salt);
        keccak256(&node)
    }

    public fun get_entry(auction: &Auction, node: vector<u8>): (Option<u64>, Option<u64>, Option<u64>, Option<address>, Option<bool>) {
        let node = utf8(node);
        if (table::contains(&auction.entries, node)) {
            let entry = table::borrow(&auction.entries, node);
            return (
                option::some(entry.start_at),
                option::some(entry.highest_bid),
                option::some(entry.second_highest_bid),
                option::some(entry.winner),
                option::some(entry.is_finalized),
            )
        };
        (option::none(), option::none(), option::none(), option::none(), option::none())
    }

    public fun get_bid(auction: &Auction, seal_bid: vector<u8>, bidder: address): Option<u64> {
        if (table::contains(&auction.bid_details_by_bidder, bidder)) {
            let bids_by_bidder = table::borrow(&auction.bid_details_by_bidder, bidder);
            let index = seal_bid_exists(bids_by_bidder, seal_bid);
            if (option::is_some(&index)) {
                let bid = vector::borrow(bids_by_bidder, option::extract(&mut index));
                return option::some(bid.bid_value_mask)
            }
        };
        option::none()
    }

    // State transitions for names:
    // Open -> Bidding (startAuction) -> Reveal -> Owned
    public fun state(auction: &Auction, node: vector<u8>, ctx: &mut TxContext): u8 {
        let current_epoch = tx_context::epoch(ctx);
        let node = utf8(node);
        if (current_epoch < auction.auction_start_at || current_epoch > auction.auction_end_at) return AUCTION_STATE_NOT_AVAILABLE;
        if (table::contains(&auction.entries, node)) {
            let entry = table::borrow(&auction.entries, node);
            if (entry.is_finalized) return AUCTION_STATE_OWNED;
            if (current_epoch == entry.start_at - 1) return AUCTION_STATE_PENDING;
            if (current_epoch < entry.start_at + BIDDING_PERIOD) return AUCTION_STATE_BIDDING;
            if (current_epoch < entry.start_at + BIDDING_PERIOD + REVEAL_PERIOD) return AUCTION_STATE_REVEAL;
            // TODO: because auction can be reopened, there is a case
            // TODO: where only 1 user places bid and his bid is invalid
            if (entry.highest_bid == 0) return AUCTION_STATE_REOPENED;
            return AUCTION_STATE_FINALIZING
        };
        AUCTION_STATE_OPEN
    }

    // TODO: testing only
    public fun state_with_epoch(auction: &Auction, node: vector<u8>, epoch: u64, _ctx: &mut TxContext): u8 {
        let current_epoch = epoch;
        let node = utf8(node);
        if (current_epoch < auction.auction_start_at || current_epoch > auction.auction_end_at) return AUCTION_STATE_NOT_AVAILABLE;
        if (table::contains(&auction.entries, node)) {
            let entry = table::borrow(&auction.entries, node);
            if (entry.is_finalized) return AUCTION_STATE_OWNED;
            if (current_epoch == entry.start_at - 1) return AUCTION_STATE_PENDING;
            if (current_epoch < entry.start_at + BIDDING_PERIOD) return AUCTION_STATE_BIDDING;
            if (current_epoch < entry.start_at + BIDDING_PERIOD + REVEAL_PERIOD) return AUCTION_STATE_REVEAL;
            // TODO: because auction can be reopened, there is a case
            // TODO: where only 1 user places bid and his bid is invalid
            if (entry.highest_bid == 0) return AUCTION_STATE_REOPENED;
            return AUCTION_STATE_FINALIZING
        };
        AUCTION_STATE_OPEN
    }

    // TODO: For testing only
    public entry fun set_entry(auction: &mut Auction, node: vector<u8>, new_epoch: u64) {
        let node = utf8(node);
        let entry = table::borrow_mut(&mut auction.entries, node);
        entry.start_at = new_epoch;
    }

    #[test_only]
    public fun get_bids_by_addr(auction: &Auction, bidder: address): vector<BidDetail> {
        if (table::contains(&auction.bid_details_by_bidder, bidder)) {
            return *table::borrow(&auction.bid_details_by_bidder, bidder)
        };
        vector[]
    }

    #[test_only]
    public fun get_bid_detail_fields(bid_detail: &BidDetail): (address, u64, u64, bool) {
        (bid_detail.bidder, bid_detail.bid_value_mask, bid_detail.created_at, bid_detail.is_unsealed)
    }

    #[test_only]
    /// Wrapper of module initializer for testing
    public fun test_init(ctx: &mut TxContext) {
        transfer::share_object(Auction {
            id: object::new(ctx),
            bid_details_by_bidder: table::new(ctx),
            entries: table::new(ctx),
            balance: balance::zero(),
            auction_start_at: 100,
            auction_end_at: 200,
        });
    }
}
