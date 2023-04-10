/// Implementation of auction module.
/// More information in: ../../../docs
module suins::auction {

    use sui::object::{UID, ID};
    use sui::table::{Self, Table};
    use sui::tx_context::TxContext;
    use sui::sui::SUI;
    use sui::balance::{Self, Balance};
    use sui::transfer;
    use sui::object;
    use sui::hash::keccak256;
    use sui::coin::Coin;
    use sui::event;
    use sui::clock::{Self, Clock};
    use sui::linked_table::{Self, LinkedTable};
    use suins::registrar;
    use suins::registry::AdminCap;
    use suins::configuration::{Self, Configuration};
    use suins::coin_util;
    use suins::entity::SuiNS;
    use suins::emoji;
    use std::option::{Self, Option, none, some};
    use std::string::{Self, String, utf8};
    use std::vector;
    use std::bcs;
    use suins::converter;
    use suins::entity;
    use sui::tx_context;

    const MIN_PRICE: u64 = 1000;
    const SUI_TLD: vector<u8> = b"sui";
    // must always up-to-date with sui::sui::MIST_PER_SUI
    const BIDDING_PERIOD: u64 = 3;
    const REVEAL_PERIOD: u64 = 3;
    /// time period from end_at, so winner have time to claim their winning
    const EXTRA_PERIOD: u64 = 30;
    const AUCTION_STATE_NOT_AVAILABLE: u8 = 0;
    const AUCTION_STATE_OPEN: u8 = 1;
    const AUCTION_STATE_PENDING: u8 = 2;
    const AUCTION_STATE_BIDDING: u8 = 3;
    const AUCTION_STATE_REVEAL: u8 = 4;
    const AUCTION_STATE_FINALIZING: u8 = 5;
    const AUCTION_STATE_OWNED: u8 = 6;
    const AUCTION_STATE_REOPENED: u8 = 7;

    const EInvalidPhase: u64 = 802;
    const EBidExisted: u64 = 804;
    const EInvalidBid: u64 = 805;
    const EBidAlreadyStart: u64 = 806;
    const EInvalidBidMask: u64 = 807;
    const EInvalidBidValue: u64 = 807;
    const EInvalidConfigParam: u64 = 808;
    const EInvalidRegistrar: u64 = 809;
    const EAlreadyFinalized: u64 = 811;
    const EAlreadyUnsealed: u64 = 812;
    const ESealBidNotExists: u64 = 813;
    const EAuctionNotHasWinner: u64 = 814;
    const EInvalidBiddingFee: u64 = 815;
    const ELabelUnavailable: u64 = 816;

    struct BidDetail has store, copy, drop {
        uid: ID,
        bidder: address,
        // upper limit of the actual bid value to hide the real value
        bid_value_mask: u64,
        // 0 for unknowned value
        bid_value: u64,
        // empty for unknowned value
        // label for .sui node
        label: String,
        created_at_in_epoch: u64,
        created_at_in_ms: u64,
        sealed_bid: vector<u8>,
        is_unsealed: bool,
    }

    /// Metadata of auction for a domain name
    struct AuctionEntry has store, drop {
        started_at: u64,
        highest_bid: u64,
        second_highest_bid: u64,
        winner: address,
        second_highest_bidder: address,
        is_finalized: bool,
        /// the created_at property of the current winning bid
        /// if 2 bidders bid same value, we choose the one who called `new_bid` first
        winning_bid_created_at_in_ms: u64,
        /// object::id_from_address(@0x0) if winner hasn't been determined
        winning_bid_uid: ID,
    }

    struct AuctionHouse has key {
        id: UID,
        /// bid_details_by_bidder: {
        ///   0xabc: [bid1, bid2],
        ///   0x123: [bid3, bid4],
        /// }
        bid_details_by_bidder: Table<address, vector<BidDetail>>,
        // key: label
        entries: LinkedTable<String, AuctionEntry>,
        balance: Balance<SUI>,
        start_auction_start_at: u64,
        /// last epoch where auction for domains can be started
        /// the auction really ends at = start_auction_end_at + BIDDING_PERIOD + REVEAL_PERIOD + FINALIZING_PERIOD
        /// this property acts as a toggle flag to turn off auction, set this field to 0 to turn off auction
        start_auction_end_at: u64,
        bidding_fee: u64,
        start_an_auction_fee: u64,
    }

    struct NodeRegisteredEvent has copy, drop {
        label: String,
        tld: String,
        winner: address,
        amount: u64,
    }

    struct NewBidEvent has copy, drop {
        bidder: address,
        sealed_bid: vector<u8>,
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

    /// #### Notice
    /// The admin uses this function to establish configuration parameters.
    /// It is intended solely for use during the development phase.
    ///
    /// #### Dev
    /// The `open_at` and `close_at` properties of Auction share object are updated.
    ///
    /// #### Params
    /// `open_at`: epoch at which all names are available for auction.
    /// `close_at`: the last epoch at which all names remain available for auction.
    /// Once this epoch has passed, the entries that have a winner but haven't yet being finalized
    /// have an additional `EXTRA_CLAIM_PERIOD` epochs for the winner to finalize.
    ///
    /// Panics
    /// Panics if `open_at` is less than `close_at`
    /// or current epoch is less than or equal `open_at`
    public entry fun configure_auction(
        _: &AdminCap,
        auction_house: &mut AuctionHouse,
        suins: &mut SuiNS,
        start_auction_start_at: u64,
        start_auction_end_at: u64,
        ctx: &mut TxContext
    ) {
        assert!(start_auction_start_at < start_auction_end_at, EInvalidConfigParam);
        assert!(tx_context::epoch(ctx) <= start_auction_start_at, EInvalidConfigParam);

        auction_house.start_auction_start_at = start_auction_start_at;
        auction_house.start_auction_end_at = start_auction_end_at;
        *entity::controller_auction_house_finalized_at_mut(suins) = auction_close_at(auction_house) + EXTRA_PERIOD;
    }

    /// #### Notice
    /// This function initiates the auction process for a `.sui` node.
    /// However, the caller must still call `place_bid` to place his/her bid.
    /// When the auction starts, a new entry is created in the `PENDING` state.
    /// In the next epoch, it moves to the `BIDDING` state.
    /// The caller also transfers a payment of coins worth `FEE_PER_YEAR`.
    ///
    /// #### Dev
    /// New `Entry` record is created.
    /// If `Entry` record exists and in the `REOPENED` state, it is remove and reinitialize.
    ///
    /// #### Params
    /// `label`: label of the node being auctioned, the node has the form `label`.sui
    ///
    /// Panics
    /// Panics if current epoch is outside of auction time period
    /// or the node is already opened
    /// or the node is not eligible for auction.
    /// or the length of the label must be within the range of 3-6 characters.
    public entry fun start_an_auction(
        auction_house: &mut AuctionHouse,
        suins: &mut SuiNS,
        config: &Configuration,
        label: vector<u8>,
        payment: &mut Coin<SUI>,
        ctx: &mut TxContext
    ) {
        assert!(
            auction_house.start_auction_start_at <= tx_context::epoch(ctx) && tx_context::epoch(ctx) <= auction_house.start_auction_end_at,
            EInvalidPhase,
        );
        let emoji_config = configuration::emoji_config(config);
        emoji::validate_label_with_emoji(emoji_config, label, 3, 6);

        let state = state(auction_house, label, tx_context::epoch(ctx));
        assert!(state == AUCTION_STATE_OPEN || state == AUCTION_STATE_REOPENED, EInvalidPhase);

        let label = utf8(label);
        assert!(registrar::is_available(suins, utf8(SUI_TLD), label, ctx), ELabelUnavailable);
        
        if (state == AUCTION_STATE_REOPENED) {
            // added in below statement
            // TODO: reset fields instead of removing them
            let _ = linked_table::remove(&mut auction_house.entries, label);
        };
        let started_at = tx_context::epoch(ctx) + 1;
        let entry = AuctionEntry {
            started_at,
            highest_bid: 0,
            second_highest_bid: 0,
            winner: @0x0,
            second_highest_bidder: @0x0,
            is_finalized: false,
            winning_bid_created_at_in_ms: 0,
            winning_bid_uid: object::id_from_address(@0x0),
        };
        linked_table::push_back(&mut auction_house.entries, label, entry);
        event::emit(AuctionStartedEvent { label, start_at: started_at });

        coin_util::user_transfer_to_suins(payment, auction_house.start_an_auction_fee, suins)
    }

    /// #### Notice
    /// Bidders use this function to place a new bid.
    /// They transfer a payment of coins with a value equal to the bid value mask to hide the actual bid amount.
    ///
    /// #### Dev
    /// New bid detail is created.
    ///
    /// #### Params
    /// `sealed_bid`: return value of `make_seal_bid`
    /// `bid_value_mask`: upper bound of actual bid value
    ///
    /// Panics
    /// Panics if current epoch is less than end_at
    /// or `bid_value_mask` is less than `MIN_PRICE`
    /// or the sealed bid exists
    /// or payment doesn't have enough coin
    public entry fun place_bid(
        auction_house: &mut AuctionHouse,
        suins: &mut SuiNS,
        sealed_bid: vector<u8>,
        bid_value_mask: u64,
        payment: &mut Coin<SUI>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        assert!(
            auction_house.start_auction_start_at <= tx_context::epoch(ctx) && tx_context::epoch(ctx)
                <= auction_house.start_auction_end_at + BIDDING_PERIOD,
            EInvalidPhase,
        );
        assert!(bid_value_mask >= MIN_PRICE, EInvalidBid);

        if (!table::contains(&auction_house.bid_details_by_bidder, tx_context::sender(ctx))) {
            table::add(&mut auction_house.bid_details_by_bidder, tx_context::sender(ctx), vector[]);
        };

        let bids_by_sender = table::borrow_mut(&mut auction_house.bid_details_by_bidder, tx_context::sender(ctx));
        assert!(option::is_none(&seal_bid_exists(bids_by_sender, sealed_bid)), EBidExisted);

        let bidder = tx_context::sender(ctx);
        let bid = BidDetail {
            uid: converter::new_id(ctx),
            bidder,
            bid_value_mask,
            bid_value: 0,
            label: utf8(vector[]),
            created_at_in_epoch: tx_context::epoch(ctx),
            created_at_in_ms: clock::timestamp_ms(clock),
            sealed_bid,
            is_unsealed: false,
        };
        vector::push_back(bids_by_sender, bid);
        event::emit(NewBidEvent { bidder, sealed_bid, bid_value_mask });

        coin_util::user_transfer_to_auction(payment, bid_value_mask, &mut auction_house.balance);
        coin_util::user_transfer_to_suins(payment, auction_house.bidding_fee, suins);
    }

    /// #### Notice
    /// Bidders use this function to reveal the true parameters of their sealed bids.
    /// No payment is returned in this function.
    /// Bidders can retrieve their payment by using either the `finalize_auction` or `withdraw` function.
    ///
    /// #### Dev
    /// The `Entry` record represeting the `label` is updated with the new bid value if `value` is either the highest
    /// or second highest value.
    /// The `label` and `bid_value` properties of the bid detail are updated.
    ///
    /// #### Params
    /// `label`: label of the node being auctioned, the node has the form `label`.sui
    /// `value`: auctual value that bidder wants to spend
    /// `salt`: random string used when hashing the sealed bid
    ///
    /// Panics
    /// Panics if auction is not in `REVEAL` state
    /// or sender has never ever placed a bid
    /// or the parameters don't match any sealed bid
    /// or the sealed bid has already been unsealed
    /// or `label` hasn't been started
    public entry fun reveal_bid(
        auction_house: &mut AuctionHouse,
        label: vector<u8>,
        value: u64,
        salt: vector<u8>,
        ctx: &mut TxContext
    ) {
        assert!(
            auction_house.start_auction_start_at <= tx_context::epoch(ctx) && tx_context::epoch(ctx)
                <= auction_house.start_auction_end_at + BIDDING_PERIOD + REVEAL_PERIOD,
            EInvalidPhase,
        );
        // TODO: do we need to validate domain here?
        let auction_state = state(auction_house, label, tx_context::epoch(ctx));
        assert!(auction_state == AUCTION_STATE_REVEAL, EInvalidPhase);

        let seal_bid = make_seal_bid(label, tx_context::sender(ctx), value, salt); // hash from label, owner, value, salt
        let bids_by_sender = table::borrow_mut(&mut auction_house.bid_details_by_bidder, tx_context::sender(ctx));
        let index = seal_bid_exists(bids_by_sender, seal_bid);
        assert!(option::is_some(&index), ESealBidNotExists);

        let bid_detail = vector::borrow_mut(bids_by_sender, option::extract(&mut index));
        assert!(!bid_detail.is_unsealed, EAlreadyUnsealed);

        let label = utf8(label);
        bid_detail.bid_value = value;
        bid_detail.label = label;
        bid_detail.is_unsealed = true;

        event::emit(BidRevealedEvent {
            label,
            bidder: tx_context::sender(ctx),
            bid_value: value,
            created_at: bid_detail.created_at_in_epoch,
        });

        let entry = linked_table::borrow_mut(&mut auction_house.entries, *&label);
        if (
            bid_detail.bid_value_mask < value
                || value < MIN_PRICE
                || bid_detail.created_at_in_epoch < entry.started_at
                || entry.started_at + BIDDING_PERIOD <= bid_detail.created_at_in_epoch
        ) {
            // invalid bid
            // TODO: what to do now?
        } else if (value > entry.highest_bid) {
            // Vickrey auction, winner pays the second highest_bid
            new_winning_bid(entry, bid_detail);
        } else if (value == entry.highest_bid && bid_detail.created_at_in_ms < entry.winning_bid_created_at_in_ms) {
            // if same value and same created_at, we choose first one who reveals bid.
            new_winning_bid(entry, bid_detail);
        } else if (value > entry.second_highest_bid) {
            // not winner, but affects second place
            new_second_highest_bid(entry, value, tx_context::sender(ctx));
        } else {
            // bid doesn't affect auction
            // TODO: what to do now?
        };
    }

    /// #### Notice
    /// Bidders use this function to claim the NFT or withdraw payment of their bids on `label`.
    /// If being called by the winner, he/she retrieve the payment that are the difference between bid mask and bid value.
    /// He/she also get the NFT representing the ownership of `label`.sui node.
    /// If not the winner, he/she get back the payment that he/her deposited when place the bid.
    /// We allow bidders to have multiple bids on one domain, this function checks every of them.
    ///
    /// #### Dev
    /// All bid details that are considered in this function are removed.
    ///
    /// #### Params
    /// label label of the node beinng auctioned, the node has the form `label`.sui
    /// resolver address of the resolver share object that the winner wants to set for his/her new NFT
    ///
    /// Panics
    /// Panics if auction state is not `FINALIZING`, `REOPENED` or `OWNED`
    /// or sender has never ever placed a bid
    /// or `label` hasn't been started
    /// or the auction has already been finalized and sender is the winner
    public entry fun finalize_auction(
        auction_house: &mut AuctionHouse,
        suins: &mut SuiNS,
        config: &Configuration,
        label: vector<u8>,
        ctx: &mut TxContext
    ) {
        assert!(
            auction_house.start_auction_start_at <= tx_context::epoch(ctx) && tx_context::epoch(ctx)
                <= auction_close_at(auction_house) + EXTRA_PERIOD,
            EInvalidPhase,
        );
        let auction_state = state(auction_house, label, tx_context::epoch(ctx));
        // the reveal phase is over in all of these phases and have received bids
        assert!(
            auction_state == AUCTION_STATE_FINALIZING
                || auction_state == AUCTION_STATE_REOPENED
                || auction_state == AUCTION_STATE_OWNED,
            EInvalidPhase
        );

        let label_str = utf8(label);
        let entry = linked_table::borrow_mut(&mut auction_house.entries, label_str);
        assert!(!(entry.is_finalized && entry.winner == tx_context::sender(ctx)), EAlreadyFinalized);

        let bids_of_sender = table::borrow_mut(&mut auction_house.bid_details_by_bidder, tx_context::sender(ctx));
        // Refund all the bids
        let len = vector::length(bids_of_sender);
        let index = 0;
        while (index < len) {
            if (vector::borrow(bids_of_sender, index).label != label_str) {
                index = index + 1;
                continue
            };

            let bid_detail = vector::remove(bids_of_sender, index);
            len = len - 1;
            if (entry.winning_bid_uid == bid_detail.uid) {
                handle_winning_bid(&mut auction_house.balance, suins, entry, &bid_detail, ctx);
                entry.is_finalized = true;
            } else {
                // TODO: charge paymennt as punishmennt
                // not the winner
                coin_util::auction_transfer_to_address(
                    &mut auction_house.balance,
                    bid_detail.bid_value_mask,
                    bid_detail.bidder,
                    ctx
                );
            };
        };
        if (entry.winner != tx_context::sender(ctx)) return;

        registrar::register_internal(suins, SUI_TLD, config, label, entry.winner, 365, ctx);

        event::emit(NodeRegisteredEvent {
            label: label_str,
            tld: utf8(SUI_TLD),
            winner: entry.winner,
            amount: entry.second_highest_bid
        })
    }

    public entry fun finalize_all_auctions_by_admin(
        _: &AdminCap,
        auction_house: &mut AuctionHouse,
        suins: &mut SuiNS,
        config: &Configuration,
        ctx: &mut TxContext
    ) {
        assert!(
            auction_close_at(auction_house) < tx_context::epoch(ctx) && tx_context::epoch(ctx)
                <= auction_close_at(auction_house) + EXTRA_PERIOD,
            EInvalidPhase,
        );

        // TODO: copy the `option` because we need mutable reference to `entries` later
        let next_label = *linked_table::front(&auction_house.entries);
        while (option::is_some(&next_label)) {
            let label = *option::borrow(&next_label);
            let auction_state = state(auction_house, *string::bytes(&label), tx_context::epoch(ctx));
            let entry = linked_table::borrow_mut(&mut auction_house.entries, label);

            if (!entry.is_finalized && entry.winner != @0x0 && auction_state == AUCTION_STATE_FINALIZING) {
                let bids_of_winner = table::borrow_mut(&mut auction_house.bid_details_by_bidder, entry.winner);
                let len = vector::length(bids_of_winner);
                let index = 0;

                while (index < len) {
                    let bid_detail = vector::borrow(bids_of_winner, index);
                    // TODO: winner can have multiple bid with the same highest value,
                    // TODO: however, we are using the vector, the early bid comes first.
                    if (bid_detail.label == label && entry.winning_bid_uid == bid_detail.uid) {
                        handle_winning_bid(&mut auction_house.balance, suins, entry, bid_detail, ctx);

                        vector::remove(bids_of_winner, index);
                        entry.is_finalized = true;

                        registrar::register_internal(
                            suins,
                            SUI_TLD,
                            config,
                            *string::bytes(&label),
                            entry.winner,
                            365,
                            ctx
                        );
                        event::emit(NodeRegisteredEvent {
                            label,
                            tld: utf8(SUI_TLD),
                            winner: entry.winner,
                            amount: entry.second_highest_bid
                        });

                        break
                    };
                    index = index + 1;
                };
            };
            next_label = *linked_table::next(&auction_house.entries, label);
        };
        *entity::controller_auction_house_finalized_at_mut(suins) = tx_context::epoch(ctx);
    }

    /// #### Notice
    /// Bidders use this function to withdraw all their remaining bids.
    /// If there is any entry in which the sender is the winner and not yet finalized and still in `EXTRA_PERIOD`,
    /// skip that winning bid (For these bids, bidders have to call `finalize_auction` to get their extra payment and NFT).
    ///
    /// #### Dev
    /// The admin doesn't use this function to withdraw balance.
    /// All bid details that are considered are removed.
    ///
    /// Panics
    /// Panics if current epoch is less than or equal end_at
    /// or sender has never ever placed a bid
    public entry fun withdraw(auction_house: &mut AuctionHouse, ctx: &mut TxContext) {
        assert!(tx_context::epoch(ctx) > auction_close_at(auction_house), EInvalidPhase);

        let bid_details = table::borrow_mut(&mut auction_house.bid_details_by_bidder, tx_context::sender(ctx));
        let len = vector::length(bid_details);
        let index = 0;
        while (index < len) {
            let detail = vector::borrow(bid_details, index);
            if (linked_table::contains(&auction_house.entries, detail.label)) {
                let entry = linked_table::borrow(&auction_house.entries, detail.label);
                // TODO: has 2 bids with the same value that are the highest
                if (entry.winning_bid_uid == detail.uid) {
                    index = index + 1;
                    continue
                };
            };
            // TODO: transfer all balances at once
            coin_util::auction_transfer_to_address(
                &mut auction_house.balance,
                detail.bid_value_mask,
                detail.bidder,
                ctx
            );
            vector::remove(bid_details, index);
            len = len - 1;
        };
        // TODO: consider removing `tx_context::sender(ctx)` key from `bid_details_by_bidder` if `bid_details` is empty
    }

    public entry fun set_bidding_fee(_: &AdminCap, auction_house: &mut AuctionHouse, new_bidding_fee: u64) {
        assert!(
            configuration::mist_per_sui() <= new_bidding_fee
                && new_bidding_fee <= configuration::mist_per_sui() * 1_000_000,
            EInvalidBiddingFee
        );
        auction_house.bidding_fee = new_bidding_fee;
    }

    public entry fun set_start_an_auction_fee(_: &AdminCap, auction_house: &mut AuctionHouse, new_fee: u64) {
        assert!(
            configuration::mist_per_sui() <= new_fee
                && new_fee <= configuration::mist_per_sui() * 1_000_000,
            EInvalidBiddingFee
        );
        auction_house.start_an_auction_fee = new_fee;
    }

    // === Public Functions ===

    /// #### Notice
    /// Generate the sealed bid that is used when placing a new bid
    ///
    /// #### Params
    /// `label`: label of the node being auctioned, the node has the form `label`.sui
    /// `owner`: address of the bidder
    /// `value`: bid value
    /// `salt`: a random string
    ///
    /// #### Return
    /// Hashed string using keccak256
    public fun make_seal_bid(label: vector<u8>, owner: address, value: u64, salt: vector<u8>): vector<u8> {
        let owner = bcs::to_bytes(&owner);
        vector::append(&mut label, owner);
        let value = bcs::to_bytes(&value);
        vector::append(&mut label, value);
        vector::append(&mut label, salt);
        keccak256(&label)
    }

    /// #### Notice
    /// Get metadata of an auction
    ///
    /// #### Params
    /// label label of the node being auctioned, the node has the form `label`.sui
    ///
    /// #### Return
    /// (`start_at`, `highest_bid`, `second_highest_bid`, `winner`, `is_finalized`)
    public fun get_entry(
        auction_house: &AuctionHouse,
        label: vector<u8>
    ): (Option<u64>, Option<u64>, Option<u64>, Option<address>, Option<bool>) {
        let label = utf8(label);
        if (linked_table::contains(&auction_house.entries, label)) {
            let entry = linked_table::borrow(&auction_house.entries, label);
            return (
                some(entry.started_at),
                some(entry.highest_bid),
                some(entry.second_highest_bid),
                some(entry.winner),
                some(entry.is_finalized),
            )
        };
        (none(), none(), none(), none(), none())
    }

    /// #### Notice
    /// Get state of an auction
    /// State transitions for node can be found at `../../../docs/auction.md`
    ///
    /// #### Params
    /// label label of the node being auctioned, the node has the form `label`.sui
    ///
    /// #### Return
    /// either [
    ///   AUCTION_STATE_NOT_AVAILABLE | AUCTION_STATE_OPEN | AUCTION_STATE_PENDING | AUCTION_STATE_BIDDING |
    ///   AUCTION_STATE_REVEAL | AUCTION_STATE_FINALIZING | AUCTION_STATE_OWNED | AUCTION_STATE_REOPENED
    /// ]
    public fun state(auction_house: &AuctionHouse, label: vector<u8>, current_epoch: u64): u8 {
        if (
            current_epoch < auction_house.start_auction_start_at
                || current_epoch > auction_close_at(auction_house) + EXTRA_PERIOD
        ) return AUCTION_STATE_NOT_AVAILABLE;

        let label = utf8(label);
        if (linked_table::contains(&auction_house.entries, label)) {
            let entry = linked_table::borrow(&auction_house.entries, label);
            if (entry.is_finalized) return AUCTION_STATE_OWNED;

            if (current_epoch > auction_close_at(auction_house)) {
                if (entry.highest_bid != 0) return AUCTION_STATE_FINALIZING;
                return AUCTION_STATE_NOT_AVAILABLE
            } else {
                if (current_epoch == entry.started_at - 1) return AUCTION_STATE_PENDING;
                if (current_epoch < entry.started_at + BIDDING_PERIOD) return AUCTION_STATE_BIDDING;
                if (current_epoch < entry.started_at + BIDDING_PERIOD + REVEAL_PERIOD) return AUCTION_STATE_REVEAL;
                // TODO: because auction can be reopened, there is a case
                // TODO: where only 1 user places bid and his bid is invalid
                if (entry.highest_bid == 0) return AUCTION_STATE_REOPENED;
                return AUCTION_STATE_FINALIZING
            }
        } else if (current_epoch > auction_close_at(auction_house)) return AUCTION_STATE_NOT_AVAILABLE;
        AUCTION_STATE_OPEN
    }

    // === Friend and Private Functions ===

    public(friend) fun auction_close_at(auction: &AuctionHouse): u64 {
        auction.start_auction_end_at + BIDDING_PERIOD + REVEAL_PERIOD
    }

    fun new_winning_bid(entry: &mut AuctionEntry, winning_bid_detail: &BidDetail) {
        let new_second_highest_bid = entry.highest_bid;
        let new_second_highest_bidder = entry.winner;
        new_second_highest_bid(entry, new_second_highest_bid, new_second_highest_bidder);

        entry.highest_bid = winning_bid_detail.bid_value;
        entry.winner = winning_bid_detail.bidder;
        entry.winning_bid_created_at_in_ms = winning_bid_detail.created_at_in_ms;
        entry.winning_bid_uid = winning_bid_detail.uid;
    }

    fun new_second_highest_bid(
        entry: &mut AuctionEntry,
        new_second_highest_value: u64,
        new_second_highest_bidder: address
    ) {
        entry.second_highest_bid = new_second_highest_value;
        entry.second_highest_bidder = new_second_highest_bidder;
    }

    fun handle_winning_bid(
        auction_balance: &mut Balance<SUI>,
        suins: &mut SuiNS,
        entry: &AuctionEntry,
        bid_detail: &BidDetail,
        ctx: &mut TxContext
    ) {
        if (entry.second_highest_bid != 0 && entry.second_highest_bidder != @0x0) {
            coin_util::auction_transfer_to_address(
                auction_balance,
                bid_detail.bid_value_mask - entry.second_highest_bid,
                bid_detail.bidder,
                ctx
            );
            // it rounds down
            let second_highest_bidder_take = (entry.second_highest_bid / 100) * 5;
            coin_util::auction_transfer_to_suins(
                auction_balance,
                entry.second_highest_bid - second_highest_bidder_take,
                suins
            );
            coin_util::auction_transfer_to_address(
                auction_balance,
                second_highest_bidder_take,
                entry.second_highest_bidder,
                ctx,
            );
        } else {
            // winner is the only one who bided
            coin_util::auction_transfer_to_address(
                auction_balance,
                bid_detail.bid_value_mask - bid_detail.bid_value,
                bid_detail.bidder,
                ctx
            );
            coin_util::auction_transfer_to_suins(auction_balance, bid_detail.bid_value, suins);
        };
    }

    fun init(ctx: &mut TxContext) {
        transfer::share_object(AuctionHouse {
            id: object::new(ctx),
            bid_details_by_bidder: table::new(ctx),
            entries: linked_table::new(ctx),
            balance: balance::zero(),
            start_auction_start_at: entity::max_epoch_allowed(),
            start_auction_end_at: entity::max_epoch_allowed() - 1,
            bidding_fee: configuration::mist_per_sui(),
            start_an_auction_fee: 10 * configuration::mist_per_sui(),
        });
    }

    /// Return index of bid if exists
    fun seal_bid_exists(bids: &vector<BidDetail>, seal_bid: vector<u8>): Option<u64> {
        let len = vector::length(bids);
        let index = 0;

        while (index < len) {
            let detail = vector::borrow(bids, index);
            if (detail.sealed_bid == seal_bid) {
                return some(index)
            };
            index = index + 1;
        };
        none()
    }

    // === Testing ===

    #[test_only]
    public fun get_balance(auction: &AuctionHouse): u64 {
        balance::value(&auction.balance)
    }

    #[test_only]
    public fun get_bids_by_bidder(auction_house: &AuctionHouse, bidder: address): vector<BidDetail> {
        if (table::contains(&auction_house.bid_details_by_bidder, bidder)) {
            return *table::borrow(&auction_house.bid_details_by_bidder, bidder)
        };
        vector[]
    }

    #[test_only]
    public fun get_seal_bid_by_bidder(
        auction_house: &AuctionHouse,
        seal_bid: vector<u8>,
        bidder: address
    ): Option<u64> {
        if (table::contains(&auction_house.bid_details_by_bidder, bidder)) {
            let bids_by_bidder = table::borrow(&auction_house.bid_details_by_bidder, bidder);
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
        (bid_detail.bidder, bid_detail.bid_value_mask, bid_detail.created_at_in_epoch, bid_detail.is_unsealed)
    }

    #[test_only]
    /// Wrapper of module initializer for testing
    public fun test_init(ctx: &mut TxContext) {
        transfer::share_object(AuctionHouse {
            id: object::new(ctx),
            bid_details_by_bidder: table::new(ctx),
            entries: linked_table::new(ctx),
            balance: balance::zero(),
            start_auction_start_at: entity::max_epoch_allowed(),
            start_auction_end_at: entity::max_epoch_allowed() - 1,
            bidding_fee: configuration::mist_per_sui(),
            start_an_auction_fee: 10 * configuration::mist_per_sui(),
        });
    }
}
