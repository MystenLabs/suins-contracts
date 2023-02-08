module suins::auction {

    use sui::object::UID;
    use sui::table::{Self, Table};
    use sui::tx_context::{Self, TxContext, epoch, sender};
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
    const FINALIZING_PERIOD: u64 = 30;
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
    const ESealBidNotExists: u64 = 813;

    friend suins::controller;

    struct BidDetail has store, copy, drop {
        bidder: address,
        // upper limit of the actual bid value to hide the real value
        bid_value_mask: u64,
        // 0 for unknowned value
        bid_value: u64,
        // empty for unknowned
        label: String,
        created_at: u64,
        seal_bid: vector<u8>,
        is_unsealed: bool,
    }

    /// Info of each auction this is ongoing or over
    struct AuctionEntry has store, drop {
        start_at: u64,
        highest_bid: u64,
        second_highest_bid: u64,
        winner: address,
        is_finalized: bool,
        /// the created_at property of the current winning bid
        /// if 2 bidders bid same value, we choose the one who called `new_bid` first
        bid_detail_created_at: u64,
    }

    struct Auction has key {
        id: UID,
        /// list of bids
        /// bid_details_by_bidder: {
        ///   0xabc: [bid1, bid2],
        ///   0x123: [bid3, bid4],
        /// }
        bid_details_by_bidder: Table<address, vector<BidDetail>>,
        // key: label
        entries: Table<String, AuctionEntry>,
        balance: Balance<SUI>,
        open_at: u64,
        /// last epoch where auction for domains can be started
        /// the auction really ends at = start_auction_end_at + BIDDING_PERIOD + REVEAL_PERIOD + FINALIZING_PERIOD
        close_at: u64,
    }

    struct LabelRegisteredEvent has copy, drop {
        label: String,
        winner: address,
        amount: u64,
    }

    struct NewBidEvent has copy, drop {
        bidder: address,
        seal_bid: vector<u8>,
        bid_value_mask: u64,
    }

    struct BidRevealedEvent has copy, drop {
        label: String,
        bidder: address,
        bid_value: u64,
        created_at: u64,
    }

    struct AuctionStartedEvent has copy, drop {
        label: String,
        start_at: u64,
    }

    public entry fun configurate_auction(_: &AdminCap, auction: &mut Auction, open_at: u64, close_at: u64, ctx: &mut TxContext) {
        // TODO: hard reset all entries and bids?
        // TODO: if do so, what to do with balance in there?
        assert!(open_at < close_at, EInvalidConfigParam);
        assert!(epoch(ctx) <= open_at, EInvalidConfigParam);
        auction.open_at = open_at;
        auction.close_at = close_at;
    }

    // used by bidder
    public entry fun withdraw(auction: &mut Auction, ctx: &mut TxContext) {
        assert!(epoch(ctx) > auction.close_at, EInvalidPhase);

        let bid_details = table::borrow_mut(&mut auction.bid_details_by_bidder, sender(ctx));
        let len = vector::length(bid_details);
        let index = 0;

        while (index < len) {
            let detail = vector::borrow(bid_details, index);

            if (table::contains(&auction.entries, detail.label)) {
                let entry = table::borrow(&auction.entries, detail.label);

                if (
                    !entry.is_finalized
                        && entry.winner == sender(ctx)
                        && auction.close_at + FINALIZING_PERIOD > epoch(ctx)
                        && detail.bid_value == entry.highest_bid // bidder can bid multiple times on same domain
                ) {
                    index = index + 1;
                    continue
                };
            };

            coin_util::contract_transfer_to_address(
                &mut auction.balance,
                detail.bid_value_mask,
                detail.bidder,
                ctx
            );
            vector::remove(bid_details, index);
            len = len - 1;
        };
        // TODO: remove `sender(ctx)` key from `bid_details_by_bidder` if `bid_details` is empty
    }

    // testing only
    public entry fun withdraw_with_epoch(auction: &mut Auction, epoch: u64, ctx: &mut TxContext) {
        assert!(epoch > auction.close_at, EInvalidPhase);

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

    public entry fun new_bid(auction: &mut Auction, seal_bid: vector<u8>, bid_value_mask: u64, payment: &mut Coin<SUI>, ctx: &mut TxContext) {
        let current_epoch = tx_context::epoch(ctx);
        assert!(
            auction.open_at <= current_epoch && current_epoch <= auction.close_at + 1,
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
            label: utf8(vector[]),
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
            auction.open_at <= current_epoch && current_epoch <= auction.close_at,
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
            label: utf8(vector[]),
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
        label: vector<u8>,
        resolver: address,
        ctx: &mut TxContext
    ) {
        // TODO: what to do with .move?
        assert!(base_registrar::get_base_node_bytes(registrar) == b"sui", EInvalidRegistrar);
        let auction_state = state(auction, label, ctx);
        assert!(
            auction_state == AUCTION_STATE_FINALIZING
                || auction_state == AUCTION_STATE_REOPENED
                || auction_state == AUCTION_STATE_OWNED,
            EInvalidPhase
        );

        let label_str = utf8(label);
        let entry = table::borrow_mut(&mut auction.entries, label_str);
        let bids_of_sender = table::borrow_mut(&mut auction.bid_details_by_bidder, tx_context::sender(ctx));

        // Refund all the bids
        // TODO: remove bids_of_sender if being empty
        let len = vector::length(bids_of_sender);
        let index = 0;
        while (index < len) {
            if (vector::borrow(bids_of_sender, index).label != label_str) {
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
                // send extra payment to winner
                if (entry.second_highest_bid != 0) {
                    coin_util::contract_transfer_to_address(
                        &mut auction.balance,
                        detail.bid_value_mask - entry.second_highest_bid,
                        detail.bidder,
                        ctx
                    );
                } else {
                    // winner is the only one who bided
                    coin_util::contract_transfer_to_address(
                        &mut auction.balance,
                        detail.bid_value_mask - detail.bid_value,
                        detail.bidder,
                        ctx
                    );
                }

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

        base_registrar::register(registrar, registry, config, label, entry.winner, 365, resolver, ctx);
        entry.is_finalized = true;

        // TODO: change event name
        event::emit(LabelRegisteredEvent {
            label: label_str,
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
        label: vector<u8>,
        epoch: u64,
        resolver: address,
        ctx: &mut TxContext
    ) {
        // TODO: what to do with .move?
        assert!(base_registrar::get_base_node_bytes(registrar) == b"sui", EInvalidRegistrar);
        let auction_state = state_with_epoch(auction, label, epoch, ctx);
        assert!(
            auction_state == AUCTION_STATE_FINALIZING
                || auction_state == AUCTION_STATE_REOPENED
                || auction_state == AUCTION_STATE_OWNED,
            EInvalidPhase
        );

        let label_str = utf8(label);
        let entry = table::borrow_mut(&mut auction.entries, label_str);
        let bids_of_sender = table::borrow_mut(&mut auction.bid_details_by_bidder, tx_context::sender(ctx));

        // Refund all the bids
        // TODO: remove bids_of_sender if being empty
        let len = vector::length(bids_of_sender);
        let index = 0;
        while (index < len) {
            if (vector::borrow(bids_of_sender, index).label != label_str) {
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

        base_registrar::register(registrar, registry, config, label, entry.winner, 365, resolver, ctx);
        entry.is_finalized = true;
        event::emit(LabelRegisteredEvent {
            label: label_str,
            winner: entry.winner,
            amount: entry.second_highest_bid
        })
    }

    // TODO: do we need to validate domain here?
    public entry fun unseal_bid(auction: &mut Auction, label: vector<u8>, value: u64, salt: vector<u8>, ctx: &mut TxContext) {
        let auction_state = state(auction, label, ctx);
        assert!(auction_state == AUCTION_STATE_REVEAL, EInvalidPhase);

        let seal_bid = make_seal_bid(label, sender(ctx), value, salt); // hash from label, owner, value, salt
        let bids_by_sender = table::borrow_mut(&mut auction.bid_details_by_bidder, sender(ctx));
        let index = seal_bid_exists(bids_by_sender, seal_bid);
        assert!(option::is_some(&index), ESealBidNotExists);

        let bid_detail = vector::borrow_mut(bids_by_sender, option::extract(&mut index));
        assert!(!bid_detail.is_unsealed, EAlreadyUnsealed);

        let label = utf8(label);
        event::emit(BidRevealedEvent {
            label,
            bidder: sender(ctx),
            bid_value: value,
            created_at: bid_detail.created_at,
        });

        let entry = table::borrow_mut(&mut auction.entries, *&label);
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
            entry.bid_detail_created_at = bid_detail.created_at;
        } else if (value == entry.highest_bid && bid_detail.created_at < entry.bid_detail_created_at) {
            // if same value and same created_at, we choose first one who reveals bid.
            // FIXME: test me
            // TODO: could be combined with the previous check
            entry.second_highest_bid = entry.highest_bid;
            entry.highest_bid = value;
            entry.winner = bid_detail.bidder;
            entry.bid_detail_created_at = bid_detail.created_at;
        } else if (value > entry.second_highest_bid) {
            // not winner, but affects second place
            entry.second_highest_bid = value;
        } else {
            // bid doesn't affect auction
        };
        bid_detail.bid_value = value;
        bid_detail.label = label;
        bid_detail.is_unsealed = true;
    }

    // TODO: testing only
    public entry fun unseal_bid_with_epoch(
        auction: &mut Auction,
        label: vector<u8>,
        value: u64,
        salt: vector<u8>,
        epoch: u64,
        ctx: &mut TxContext
    ) {
        let auction_state = state_with_epoch(auction, label, epoch, ctx);
        assert!(auction_state == AUCTION_STATE_REVEAL, EInvalidPhase);

        let seal_bid = make_seal_bid(label, sender(ctx), value, salt); // hash from label, owner, value, salt
        let bids_by_sender = table::borrow_mut(&mut auction.bid_details_by_bidder, sender(ctx));
        let index = seal_bid_exists(bids_by_sender, seal_bid);
        assert!(option::is_some(&index), ESealBidNotExists);

        let bid_detail = vector::borrow_mut(bids_by_sender, option::extract(&mut index));
        assert!(!bid_detail.is_unsealed, EAlreadyUnsealed);

        let label = utf8(label);
        event::emit(BidRevealedEvent {
            label,
            bidder: sender(ctx),
            bid_value: value,
            created_at: bid_detail.created_at,
        });

        let entry = table::borrow_mut(&mut auction.entries, *&label);
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
        bid_detail.label = label;
        bid_detail.is_unsealed = true;
    }

    // TODO: validate domain name
    public entry fun start_auction(
        auction: &mut Auction,
        config: &Configuration,
        label: vector<u8>,
        payment: &mut Coin<SUI>,
        ctx: &mut TxContext
    ) {
        let emoji_config = configuration::get_emoji_config(config);
        emoji::validate_label_with_emoji(emoji_config, label, 3, 6);

        let state = state(auction, label, ctx);
        assert!(state == AUCTION_STATE_OPEN || state == AUCTION_STATE_REOPENED, EInvalidPhase);

        let label = utf8(label);
        if (state == AUCTION_STATE_REOPENED) {
            let _ = table::remove(&mut auction.entries, label);
        };
        // current_epoch was validated in `state`
        let start_at = tx_context::epoch(ctx) + 1;
        let entry = AuctionEntry {
            start_at,
            highest_bid: 0,
            second_highest_bid: 0,
            winner: @0x0,
            is_finalized: false,
            bid_detail_created_at: 0,
        };
        table::add(&mut auction.entries, label, entry);
        coin_util::user_transfer_to_contract(payment, FEE_PER_YEAR, &mut auction.balance);
        event::emit(AuctionStartedEvent { label, start_at })
    }

    // TODO: testing only
    public entry fun start_auction_with_epoch(
        auction: &mut Auction,
        label: vector<u8>,
        payment: &mut Coin<SUI>,
        epoch: u64,
        ctx: &mut TxContext
    ) {
        let state = state_with_epoch(auction, label, epoch, ctx);
        assert!(state == AUCTION_STATE_OPEN || state == AUCTION_STATE_REOPENED, EInvalidPhase);

        let label = utf8(label);
        if (state == AUCTION_STATE_REOPENED) {
            let _ = table::remove(&mut auction.entries, label);
        };
        // current_epoch was validated in `state`
        let start_at = epoch + 1;
        let entry = AuctionEntry {
            start_at,
            highest_bid: 0,
            second_highest_bid: 0,
            winner: @0x0,
            is_finalized: false,
            bid_detail_created_at: 0,
        };
        table::add(&mut auction.entries, label, entry);
        coin_util::user_transfer_to_contract(payment, FEE_PER_YEAR, &mut auction.balance);
        event::emit(AuctionStartedEvent { label, start_at })
    }

    // TODO: For testing only
    public entry fun set_entry(auction: &mut Auction, label: vector<u8>, new_epoch: u64) {
        let label = utf8(label);
        let entry = table::borrow_mut(&mut auction.entries, label);
        entry.start_at = new_epoch;
    }

    // === Public Functions ===

    public fun make_seal_bid(label: vector<u8>, owner: address, value: u64, salt: vector<u8>): vector<u8> {
        let owner = bcs::to_bytes(&owner);
        vector::append(&mut label, owner);
        let value = bcs::to_bytes(&value);
        vector::append(&mut label, value);
        vector::append(&mut label, salt);
        keccak256(&label)
    }

    public fun get_entry(auction: &Auction, label: vector<u8>): (Option<u64>, Option<u64>, Option<u64>, Option<address>, Option<bool>) {
        let label = utf8(label);
        if (table::contains(&auction.entries, label)) {
            let entry = table::borrow(&auction.entries, label);
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

    public fun get_unsealed_labels_by_bidder(auction: &Auction, bidder: address): vector<String> {
        let result = vector[];
        if (table::contains(&auction.bid_details_by_bidder, bidder)) {
            let bids = table::borrow(&auction.bid_details_by_bidder, bidder);
            let len = vector::length(bids);
            let index = 0;

            while(index < len) {
                let detail = vector::borrow(bids, index);
                if (detail.is_unsealed) {
                    vector::push_back(&mut result, detail.label);
                };
                index = index + 1;
            };
        };
        result
    }

    public fun get_unsealed_created_at_by_bidder(auction: &Auction, bidder: address): vector<u64> {
        let result = vector[];
        if (table::contains(&auction.bid_details_by_bidder, bidder)) {
            let bids = table::borrow(&auction.bid_details_by_bidder, bidder);
            let len = vector::length(bids);
            let index = 0;

            while(index < len) {
                let detail = vector::borrow(bids, index);
                if (detail.is_unsealed) {
                    vector::push_back(&mut result, detail.created_at);
                };
                index = index + 1;
            };
        };
        result
    }

    public fun get_unsealed_value_by_bidder(auction: &Auction, bidder: address): vector<u64> {
        let result = vector[];
        if (table::contains(&auction.bid_details_by_bidder, bidder)) {
            let bids = table::borrow(&auction.bid_details_by_bidder, bidder);
            let len = vector::length(bids);
            let index = 0;

            while(index < len) {
                let detail = vector::borrow(bids, index);
                if (detail.is_unsealed) {
                    vector::push_back(&mut result, detail.bid_value);
                };
                index = index + 1;
            };
        };
        result
    }

    // State transitions for names:
    // Open -> Bidding (startAuction) -> Reveal -> Owned
    public fun state(auction: &Auction, label: vector<u8>, ctx: &mut TxContext): u8 {
        let current_epoch = epoch(ctx);
        let label = utf8(label);
        // TODO: test me
        if (current_epoch < auction.open_at || current_epoch > auction_end_at(auction)) return AUCTION_STATE_NOT_AVAILABLE;
        if (table::contains(&auction.entries, label)) {
            let entry = table::borrow(&auction.entries, label);
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
    public fun state_with_epoch(auction: &Auction, label: vector<u8>, epoch: u64, _ctx: &mut TxContext): u8 {
        let current_epoch = epoch;
        let label = utf8(label);
        if (current_epoch < auction.open_at || current_epoch > auction.close_at) return AUCTION_STATE_NOT_AVAILABLE;
        if (table::contains(&auction.entries, label)) {
            let entry = table::borrow(&auction.entries, label);
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

    // === Friend Functions ===

    public(friend) fun auction_end_at(auction: &Auction): u64 {
        auction.close_at + BIDDING_PERIOD + REVEAL_PERIOD
    }

    public(friend) fun is_label_available_for_controller(auction: &Auction, label: String, ctx: &TxContext): bool {
        if (auction.close_at + BIDDING_PERIOD + REVEAL_PERIOD > epoch(ctx)) return false;
        if (auction.close_at + BIDDING_PERIOD + REVEAL_PERIOD + FINALIZING_PERIOD <= epoch(ctx)) return true;
        if (table::contains(&auction.entries, label)) {
            let entry = table::borrow(&auction.entries, label);
            if (!entry.is_finalized) return false
        };
        true
    }

    // === Private Functions ===

    fun init(ctx: &mut TxContext) {
        transfer::share_object(Auction {
            id: object::new(ctx),
            bid_details_by_bidder: table::new(ctx),
            entries: table::new(ctx),
            balance: balance::zero(),
            open_at: 0,
            close_at: 0,
        });
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

    // === Testing ===

    #[test_only]
    public fun get_bids_by_bidder(auction: &Auction, bidder: address): vector<BidDetail> {
        if (table::contains(&auction.bid_details_by_bidder, bidder)) {
            return *table::borrow(&auction.bid_details_by_bidder, bidder)
        };
        vector[]
    }

    #[test_only]
    public fun get_seal_bid_by_bidder(auction: &Auction, seal_bid: vector<u8>, bidder: address): Option<u64> {
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
            open_at: 0,
            close_at: 0,
        });
    }
}
