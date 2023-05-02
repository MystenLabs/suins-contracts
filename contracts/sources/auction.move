/// Implementation of auction module.
/// More information in: ../../../docs
module suins::auction {
    use std::option::{Self, Option, none, some};
    use std::string::{Self, String, utf8};

    use sui::tx_context::{Self, TxContext};
    use sui::balance::{Self, Balance};
    use sui::object::{Self, UID};
    use sui::table::{Self, Table};
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::transfer;
    use sui::linked_table::{Self, LinkedTable};
    use sui::dynamic_field as df;

    use suins::registrar;
    use suins::config::{Self, Config};
    use suins::suins::{Self, AdminCap, SuiNS};
    use suins::string_utils;
    use suins::constants;
    use suins::registrar::RegistrationNFT;
    use suins::controller;

    const AUCTION_HOUSE_PERIOD: u64 = 30;
    const BIDDING_PERIOD: u64 = 2;
    const TWO_DAYS_IN_MS: u64 = 172_800_000;
    const AUCTION_STATE_UNAVAILABLE: u8 = 1;
    const AUCTION_STATE_OPEN: u8 = 2;
    const AUCTION_STATE_BIDDING: u8 = 3;
    const AUCTION_STATE_OWNED: u8 = 4;
    const AUCTION_STATE_REOPENED: u8 = 5;

    const EAuctionHouseUnavailable: u64 = 801;
    const ELabelUnavailable: u64 = 802;
    const EBidExisted: u64 = 803;
    const EInvalidBidValue: u64 = 804;
    const EInvalidConfigParam: u64 = 805;
    const EWinnerAlreadyClaimed: u64 = 806;

    /// Authorization witness to call protected functions of suins.
    struct App has drop {}

    struct BidDetail has store, copy, drop {
        // Using the address to simplify the typing;
        // Basically the same thing as the ID.
        id: address,
        bidder: address,
        label: String,
        bid_value: u64,
    }

    /// Metadata of auction for a domain name
    struct AuctionEntry has store, drop {
        started_at_in_ms: u64,
        highest_bid: u64,
        winner: address,
        winning_bid_id: address,
        is_claimed: bool,
    }

    /// Key to use when attaching a AuctionHouse.
    struct AuctionHouseKey has copy, store, drop {}

    struct AuctionHouse has store {
        /// bid_details_by_bidder: {
        ///   0xabc: [bid1, bid2],
        ///   0x123: [bid3, bid4],
        /// }
        nfts: UID,
        bid_details_by_bidder: Table<address, LinkedTable<u64, BidDetail>>,
        // key: label
        entries: LinkedTable<String, AuctionEntry>,
        balance: Balance<SUI>,
        start_at: u64,
    }

    /// #### Notice
    /// The admin uses this function to establish configuration parameters.
    /// It is intended solely for use during the development phase.
    ///
    /// #### Params
    /// `start_at`: epoch at which all names are available for auction.
    ///
    /// Panics
    /// Panics if current epoch is less than or equal `start_at`
    public fun configure_auction(
        _: &AdminCap,
        suins: &mut SuiNS,
        start_at: u64,
        ctx: &mut TxContext
    ) {
        assert!(tx_context::epoch(ctx) <= start_at, EInvalidConfigParam);

        let auction_house = AuctionHouse {
            nfts: object::new(ctx),
            bid_details_by_bidder: table::new(ctx),
            entries: linked_table::new(ctx),
            balance: balance::zero(),
            start_at,
        };

        *controller::auction_house_finalized_at_mut(suins) = auction_house_close_at(&auction_house);
        df::add(suins::app_uid_mut(App {}, suins), AuctionHouseKey {}, auction_house);
    }

    /// #### Notice
    /// Bidders use this function to place a new bid.
    /// If there's no auction for `label`, starts a new auction.
    /// They transfer a payment of coins with a value equal to the bid value.
    ///
    /// Panics
    /// Panics if `label` is invalid
    /// or `label` has been registered
    /// or `bid_value` is too low,
    /// or not in auction period
    public fun place_bid(
        suins: &mut SuiNS,
        label: String,
        bid_value: u64,
        payment: &mut Coin<SUI>,
        ctx: &mut TxContext
    ) {
        string_utils::validate_label(label, constants::min_domain_length(), constants::max_domain_length());
        assert!(registrar::is_available(suins, constants::sui_tld(), label, ctx), ELabelUnavailable);
        let config = suins::get_config<Config>(suins);
        let min_price = config::calculate_price(config, (string::length(&label) as u8), 1);
        assert!(bid_value >= min_price, EInvalidBidValue);
        let auction_house = auction_house_mut(suins);
        assert!(
            auction_house.start_at <= tx_context::epoch(ctx) && tx_context::epoch(ctx) <= auction_house_close_at(
                auction_house
            ),
            EAuctionHouseUnavailable,
        );
        let state = state(auction_house, label, tx_context::epoch(ctx), ctx);
        assert!(
            state == AUCTION_STATE_OPEN || state == AUCTION_STATE_REOPENED || state == AUCTION_STATE_BIDDING,
            ELabelUnavailable
        );

        if (state == AUCTION_STATE_REOPENED) {
            // reset the entry of `label`
            let _ = linked_table::remove(&mut auction_house.entries, label);
        };
        if (state != AUCTION_STATE_BIDDING) {
            let entry = AuctionEntry {
                started_at_in_ms: tx_context::epoch_timestamp_ms(ctx),
                highest_bid: 0,
                winner: @0x0,
                winning_bid_id: @0x0,
                is_claimed: false,
            };
            linked_table::push_back(&mut auction_house.entries, label, entry);
            // first valid bid, this auction will have a winner
            let nft = registrar::register_with_image_internal(
                suins,
                constants::sui_tld(),
                label,
                tx_context::sender(ctx),
                365,
                ctx
            );
            // work around to be able to use `suins` in above statement
            auction_house = auction_house_mut(suins);
            df::add(&mut auction_house.nfts, label, nft);
        };

        let bid_detail = BidDetail {
            id: tx_context::fresh_object_address(ctx),
            bidder: tx_context::sender(ctx),
            bid_value,
            label: utf8(vector[]),
        };
        let bids_by_sender = table::borrow_mut(&mut auction_house.bid_details_by_bidder, tx_context::sender(ctx));
        // indexes is the increasing sequence of natural numbers
        let new_index =
            if (!linked_table::is_empty(bids_by_sender)) *option::borrow(linked_table::back(bids_by_sender)) + 1
            else 0;
        linked_table::push_back(bids_by_sender, new_index, bid_detail);

        let entry = linked_table::borrow_mut(&mut auction_house.entries, label);
        if (bid_detail.bid_value > entry.highest_bid) {
            entry.highest_bid = bid_value;
            entry.winner = tx_context::sender(ctx);
            entry.winning_bid_id = bid_detail.id;
            add_to_balance(&mut auction_house.balance, payment, bid_value);
        };
    }

    /// #### Notice
    /// Bidders use this function to claim the NFT or withdraw payment of their bids on `label`.
    /// He/she also get the NFT representing the ownership of `label`.sui domain name.
    /// If not the winner, he/she get back the payment that he/her deposited when place the bid.
    /// We allow bidders to have multiple bids on one domain, this function checks all of them.
    ///
    /// Panics
    /// Panics if auction state is not `FINALIZING`, `REOPENED` or `OWNED`
    /// or sender has never ever placed a bid
    /// or `label` hasn't been started
    /// or the auction has already been finalized and sender is the winner
    public fun finalize_auction(
        suins: &mut SuiNS,
        label: String,
        ctx: &mut TxContext
    ) {
        let auction_house = auction_house_mut(suins);
        assert!(
            auction_house.start_at + BIDDING_PERIOD <= tx_context::epoch(ctx),
            EAuctionHouseUnavailable,
        );
        let auction_state = state(auction_house, label, tx_context::epoch(ctx), ctx);
        assert!(
            auction_state == AUCTION_STATE_REOPENED || auction_state == AUCTION_STATE_OWNED,
            EAuctionHouseUnavailable
        );

        let entry = linked_table::borrow_mut(&mut auction_house.entries, label);
        assert!(!(entry.is_claimed && entry.winner == tx_context::sender(ctx)), EWinnerAlreadyClaimed);

        let bids_of_sender = table::borrow_mut(&mut auction_house.bid_details_by_bidder, tx_context::sender(ctx));
        // Refund all the bids
        let front_element = linked_table::front(bids_of_sender);
        while (option::is_some(front_element)) {
            let index = *option::borrow(front_element);
            if (linked_table::borrow(bids_of_sender, index).label != label) {
                front_element = linked_table::next(bids_of_sender, index);
                continue
            };

            // the bid at this `index` is either winning or losing bid, we handle both cases
            let prev_index = *linked_table::prev(bids_of_sender, index);
            let bid_detail = linked_table::remove(bids_of_sender, index);
            if (option::is_some(&prev_index)) front_element = linked_table::next(
                bids_of_sender,
                *option::borrow(&prev_index)
            )
            else front_element = linked_table::front(bids_of_sender);

            if (entry.winning_bid_id == bid_detail.id) {
                // can claim at anytime
                entry.is_claimed = true;
                handle_winning_bid(&mut auction_house.nfts, &bid_detail);
            } else {
                // not the winner
                send_to_address(
                    &mut auction_house.balance,
                    bid_detail.bid_value,
                    bid_detail.bidder,
                    ctx
                );
            };
        };
    }

    /// #### Notice
    /// Bidders use this function to withdraw all their losing bids.
    /// If there is any entry in which the sender is the winner and not yet finalized,
    /// skip that winning bid (For these bids, bidders have to call `finalize_auction` to get their NFT).
    ///
    /// Panics
    /// Panics if current epoch is less than or equal end_at
    /// or sender has never ever placed a bid
    public fun withdraw(auction_house: &mut AuctionHouse, ctx: &mut TxContext) {
        assert!(tx_context::epoch(ctx) > auction_house_close_at(auction_house), EAuctionHouseUnavailable);

        let bids_of_sender = table::borrow_mut(&mut auction_house.bid_details_by_bidder, tx_context::sender(ctx));
        let front_element = linked_table::front(bids_of_sender);

        while (option::is_some(front_element)) {
            let index = *option::borrow(front_element);
            let bid_detail = linked_table::borrow(bids_of_sender, index);

            if (linked_table::contains(&auction_house.entries, bid_detail.label)) {
                let entry = linked_table::borrow(&auction_house.entries, bid_detail.label);
                if (entry.winning_bid_id == bid_detail.id) {
                    front_element = linked_table::next(bids_of_sender, index);
                    continue
                };
            };
            send_to_address(
                &mut auction_house.balance,
                bid_detail.bid_value,
                bid_detail.bidder,
                ctx
            );

            // remove handled bids
            let prev_index = *linked_table::prev(bids_of_sender, index);
            linked_table::remove(bids_of_sender, index);
            if (option::is_some(&prev_index)) front_element = linked_table::next(
                bids_of_sender,
                *option::borrow(&prev_index)
            )
            else front_element = linked_table::front(bids_of_sender);
        };
    }

    /// #### Notice
    /// Admin uses this function to finalize and take the winning fee all auctions.
    public fun finalize_all_auctions_by_admin(
        _: &AdminCap,
        suins: &mut SuiNS,
        ctx: &mut TxContext
    ) {
        let auction_house = auction_house_mut(suins);
        assert!(auction_house_close_at(auction_house) < tx_context::epoch(ctx), EAuctionHouseUnavailable);

        let next_label = *linked_table::front(&auction_house.entries);
        while (option::is_some(&next_label)) {
            let label = *option::borrow(&next_label);
            let auction_state = state(auction_house, label, tx_context::epoch(ctx), ctx);
            let entry = linked_table::borrow_mut(&mut auction_house.entries, label);

            if (!entry.is_claimed && entry.winner != @0x0 && auction_state == AUCTION_STATE_OWNED) {
                let bids_of_winner = table::borrow_mut(&mut auction_house.bid_details_by_bidder, entry.winner);
                let front_element = linked_table::front(bids_of_winner);

                while (option::is_some(front_element)) {
                    let index = *option::borrow(front_element);
                    let bid_detail = linked_table::borrow(bids_of_winner, index);
                    if (entry.winning_bid_id == bid_detail.id) {
                        handle_winning_bid(&mut auction_house.nfts, bid_detail);

                        linked_table::remove(bids_of_winner, index);
                        entry.is_claimed = true;
                        break
                    };
                    front_element = linked_table::next(bids_of_winner, index);
                };
            };
            next_label = *linked_table::next(&auction_house.entries, label);
        };
    }

    // === Public Functions ===

    /// #### Notice
    /// Get metadata of an auction
    ///
    /// #### Params
    /// label label of the domain name being auctioned, the domain name has the form `label`.sui
    ///
    /// #### Return
    /// (`start_at`, `highest_bid`, `second_highest_bid`, `winner`, `is_finalized`)
    public fun get_entry(
        auction_house: &AuctionHouse,
        label: String,
    ): (Option<u64>, Option<u64>, Option<address>, Option<bool>) {
        if (linked_table::contains(&auction_house.entries, label)) {
            let entry = linked_table::borrow(&auction_house.entries, label);
            return (
                some(entry.started_at_in_ms),
                some(entry.highest_bid),
                some(entry.winner),
                some(entry.is_claimed),
            )
        };
        (none(), none(), none(), none())
    }

    /// #### Notice
    /// Get state of an auction
    /// State transitions for domain name can be found at `../../../docs/auction.md`
    ///
    /// #### Params
    /// label label of the domain name being auctioned, the domain name has the form `label`.sui
    ///
    /// #### Return
    /// either [
    ///   AUCTION_STATE_UNAVAILABLE | AUCTION_STATE_OPEN  | AUCTION_STATE_BIDDING |
    ///   AUCTION_STATE_OWNED | AUCTION_STATE_REOPENED
    /// ]
    public fun state(auction_house: &AuctionHouse, label: String, current_epoch: u64, ctx: &TxContext): u8 {
        if (current_epoch < auction_house.start_at) return AUCTION_STATE_UNAVAILABLE;

        if (linked_table::contains(&auction_house.entries, label)) {
            let entry = linked_table::borrow(&auction_house.entries, label);
            if (entry.started_at_in_ms + TWO_DAYS_IN_MS < tx_context::epoch_timestamp_ms(ctx)) {
                if (entry.highest_bid != 0) return AUCTION_STATE_OWNED;
                return if (current_epoch > auction_house_close_at(auction_house) - BIDDING_PERIOD)
                    AUCTION_STATE_UNAVAILABLE else AUCTION_STATE_REOPENED
            };
            return AUCTION_STATE_BIDDING
        };
        if (current_epoch > auction_house_close_at(auction_house) - BIDDING_PERIOD) return AUCTION_STATE_UNAVAILABLE;
        AUCTION_STATE_OPEN
    }

    // === Friend and Private Functions ===

    /// Last epoch to bid
    fun auction_house_close_at(auction: &AuctionHouse): u64 {
        auction.start_at + AUCTION_HOUSE_PERIOD - 1
    }

    fun handle_winning_bid(nfts: &mut UID, bid_detail: &BidDetail) {
        let nft = df::remove<String, RegistrationNFT>(nfts, bid_detail.label);
        transfer::public_transfer(nft, bid_detail.bidder);
        // TODO: transfer the winning value to somewhere
    }

    // === Transfers ===

    fun send_to_suins(
        suins: &mut SuiNS,
        balance: &mut Balance<SUI>,
        amount: u64,
    ) {
        if (amount > 0) {
            suins::app_add_balance(App {}, suins, balance::split(balance, amount))
        }
    }

    fun send_to_address(
        balance: &mut Balance<SUI>, amount: u64, receiver: address, ctx: &mut TxContext
    ) {
        if (amount > 0) {
            let coin = coin::take(balance, amount, ctx);
            transfer::public_transfer(coin, receiver);
        }
    }

    fun add_to_balance(
        balance: &mut Balance<SUI>,
        payment: &mut Coin<SUI>,
        amount: u64
    ) {
        if (amount > 0) {
            let coin_balance = coin::balance_mut(payment);
            let paid = balance::split(coin_balance, amount);
            balance::join(balance, paid);
        }
    }

    fun add_to_suins(
        suins: &mut SuiNS, payment: &mut Coin<SUI>, amount: u64, ctx: &mut TxContext
    ) {
        suins::app_add_balance(App {}, suins, coin::into_balance(coin::split(payment, amount, ctx)))
        // add_to_balance(suins::controller_balance_mut(suins), payment, amount)
    }

    fun auction_house_mut(suins: &mut SuiNS): &mut AuctionHouse {
        df::borrow_mut(suins::app_uid_mut(App {}, suins), AuctionHouseKey {})
    }

    // === Events ===

    struct NameRegisteredEvent has copy, drop {
        tld: String,
        label: String,
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
        created_at_in_ms: u64,
        sealed_bid: vector<u8>,
    }

    struct AuctionStartedEvent has copy, drop {
        label: String,
        start_at: u64,
    }
}
