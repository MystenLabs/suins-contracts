/// Implementation of auction module.
/// More information in: ../../../docs
module suins::auction {
    use std::vector;
    use std::option::{Self, Option, none, some};
    use std::string::{Self, String};

    use sui::tx_context::{Self, TxContext};
    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin};
    use sui::clock::{Self, Clock};
    use sui::event;
    use sui::object::{Self, UID};
    use sui::sui::SUI;
    use sui::linked_table::{Self, LinkedTable};

    use suins::config::{Self, Config};
    use suins::suins::{Self, AdminCap, SuiNS};
    use suins::registration_nft::RegistrationNFT;
    use suins::registry::{Self, Registry};
    use suins::domain::{Self, Domain};
    use suins::controller;

    /// One year is the default duration for a domain.
    const DEFAULT_DURATION: u8 = 1;

    const AUCTION_BIDDING_PERIOD_MS: u64 = 2 * 24 * 60 * 60 * 1000; // 2 days
    const AUCTION_MIN_QUIET_PERIOD_MS: u64 = 10 * 60 * 1000; // 10 minutes of quiet time

    const AUCTION_HOUSE_PERIOD: u64 = 30;
    const BIDDING_PERIOD: u64 = 2;
    const TWO_DAYS_IN_MS: u64 = 172_800_000;
    const AUCTION_STATE_UNAVAILABLE: u8 = 1;
    const AUCTION_STATE_OPEN: u8 = 2;
    const AUCTION_STATE_BIDDING: u8 = 3;
    const AUCTION_STATE_OWNED: u8 = 4;
    const AUCTION_STATE_REOPENED: u8 = 5;

    const EAuctionHouseUnavailable: u64 = 0;
    const ELabelUnavailable: u64 = 1;
    const EBidExisted: u64 = 2;
    /// The bid value is too low (compared to min_bid or previous bid).
    const EInvalidBidValue: u64 = 3;
    const EInvalidConfigParam: u64 = 4;
    const EWinnerAlreadyClaimed: u64 = 5;
    /// Trying to start an action but it's already started.
    const EAuctionStarted: u64 = 6;
    /// Placing a bid in a not started
    const EAuctionNotStarted: u64 = 7;

    /// Authorization witness to call protected functions of suins.
    struct App has drop {}

    /// The Auction application.
    struct Auction has store {
        domain: Domain,
        // min_bid: u64,
        start_timestamp_ms: u64,
        end_timestamp_ms: u64,
        winner: address,
        bids: LinkedTable<address, Balance<SUI>>,
        nft: Option<RegistrationNFT>,
    }

    /// The AuctionHouse application.
    struct AuctionHouse has key, store {
        id: UID,
        balance: Balance<SUI>,
        auctions: LinkedTable<Domain, Auction>,
        start_at: u64,
    }

    fun init(ctx: &mut TxContext) {
        sui::transfer::share_object(AuctionHouse {
            id: object::new(ctx),
            balance: balance::zero(),
            auctions: linked_table::new(ctx),
            start_at: 0,
        });
    }

    /// Start an auction if it's not started yet; and make the first bid.
    public fun start_auction_and_place_bid(
        self: &mut AuctionHouse,
        suins: &mut SuiNS,
        domain_name: String,
        bid_value: u64,
        payment: &mut Coin<SUI>,
        clock: &Clock,
        ctx: &mut TxContext,
    ) {
        let domain = domain::new(domain_name);

        // make sure the domain is a .sui domain and not a subdomain
        controller::assert_valid_user_registerable_domain(&domain);

        assert!(!linked_table::contains(&self.auctions, domain), EAuctionStarted);

        // The minnimum price only applies to newly created auctions
        let config = suins::get_config<Config>(suins);
        let label = vector::borrow(domain::labels(&domain), 0);
        let min_price = config::calculate_price(config, (string::length(label) as u8), 1);
        let bid = balance::split(coin::balance_mut(payment), bid_value);
        assert!(balance::value(&bid) >= min_price, EInvalidBidValue);

        let auction = start_new_auction(suins, domain, bid, clock, ctx);
        linked_table::push_back(&mut self.auctions, domain, auction)
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
        self: &mut AuctionHouse,
        domain_name: String,
        bid_value: u64,
        payment: &mut Coin<SUI>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let domain = domain::new(domain_name);
        let bid = balance::split(coin::balance_mut(payment), bid_value);

        assert!(!linked_table::contains(&self.auctions, domain), EAuctionNotStarted);

        // Check to see if there isn't an existing auction going on for this domain
        bid_on_existing_auction(self, domain, bid, clock, ctx);
    }

    fun start_new_auction(
        suins: &mut SuiNS,
        domain: Domain,
        bid: Balance<SUI>,
        clock: &Clock,
        ctx: &mut TxContext
    ): Auction {
        let registry = suins::app_registry_mut<App, Registry>(App {}, suins);
        let nft = registry::add_record(registry, domain, 1, clock, ctx);
        let starting_bid = balance::value(&bid);
        let bids = linked_table::new(ctx);

        // Insert the user's bid into the table
        linked_table::push_front(
            &mut bids,
            tx_context::sender(ctx),
            bid,
        );

        let auction = Auction {
            domain,
            start_timestamp_ms: clock::timestamp_ms(clock),
            end_timestamp_ms: clock::timestamp_ms(clock) + AUCTION_BIDDING_PERIOD_MS,
            winner: tx_context::sender(ctx),
            bids,
            nft: some(nft),
        };

        event::emit(AuctionStartedEvent {
            domain,
            start_timestamp_ms: auction.start_timestamp_ms,
            end_timestamp_ms: auction.end_timestamp_ms,
            starting_bid,
            bidder: auction.winner,
        });

        auction
    }

    fun bid_on_existing_auction(
        self: &mut AuctionHouse,
        domain: Domain,
        bid: Balance<SUI>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let auction = linked_table::borrow_mut(&mut self.auctions, domain);
        let bidder = tx_context::sender(ctx);

        // Ensure that the auction is not over
        assert!(clock::timestamp_ms(clock) <= auction.end_timestamp_ms, 0);
        // Ensure the bidder isn't already the winner
        assert!(bidder != auction.winner, 0);

        // get the current highest bid and ensure that the new bid is greater than the current winning bid
        let current_winning_bid = balance::value(linked_table::borrow(&auction.bids, auction.winner));
        let bid_amount = balance::value(&bid);
        assert!(bid_amount > current_winning_bid, 0);

        linked_table::push_front(&mut auction.bids, bidder, bid);
        auction.winner = bidder;

        event::emit(BidEvent {
            domain,
            bid: bid_amount,
            bidder,
        });

        // If there is less than `AUCTION_MIN_QUIET_PERIOD_MS` time left on the auction
        // then extend the auction so that there is `AUCTION_MIN_QUIET_PERIOD_MS` left.
        // Auctions can't be finished until there is at least `AUCTION_MIN_QUIET_PERIOD_MS`
        // time where there are no bids.
        if (auction.end_timestamp_ms - clock::timestamp_ms(clock) < AUCTION_MIN_QUIET_PERIOD_MS) {
            auction.end_timestamp_ms = clock::timestamp_ms(clock) + AUCTION_MIN_QUIET_PERIOD_MS;

            event::emit(AuctionExtendedEvent {
                domain,
                end_timestamp_ms: auction.end_timestamp_ms,
            });
        };
    }

    /// #### Notice
    /// Bidders use this function to withdraw their bid from a particular auction
    ///
    /// Panics
    /// sender has never placed a bid or they are the winner of the bid
    public fun withdraw(
        self: &mut AuctionHouse,
        domain_name: String,
        ctx: &mut TxContext
    ): Coin<SUI> {
        let domain = domain::new(domain_name);
        let auction = linked_table::borrow_mut(&mut self.auctions, domain);

        // Ensure the sender isn't the winner, winners cannot withdraw their bids
        assert!(tx_context::sender(ctx) != auction.winner, 0);
        let bid = linked_table::remove(&mut auction.bids, tx_context::sender(ctx));

        coin::from_balance(bid, ctx)
    }

    /// #### Notice
    /// Auction winner can come and claim the NFT
    ///
    /// Panics
    /// sender is not the winner
    public fun claim(
        self: &mut AuctionHouse,
        domain_name: String,
        clock: &Clock,
        ctx: &mut TxContext
    ): RegistrationNFT {
        let domain = domain::new(domain_name);
        let auction = linked_table::borrow_mut(&mut self.auctions, domain);

        // Ensure that the auction is over
        assert!(clock::timestamp_ms(clock) > auction.end_timestamp_ms, 0);

        // Ensure the sender is the winner
        assert!(tx_context::sender(ctx) == auction.winner, 0);

        // Extract the NFT and their bid, returning the NFT to the user
        // and sending the proceeds of the auction to suins
        let nft = option::extract(&mut auction.nft);
        let bid = linked_table::remove(&mut auction.bids, tx_context::sender(ctx));

        balance::join(&mut self.balance, bid);
        nft
    }

    /// #### Notice
    /// Admin uses this function to finalize and take the winning fee all auctions.
    public fun finalize_all_auctions_by_admin(
        _: &AdminCap,
        self: &mut AuctionHouse,
        ctx: &mut TxContext
    ) {
        assert!(auction_house_close_at(self) < tx_context::epoch(ctx), EAuctionHouseUnavailable);
        // TODO?
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
        _auction_house: &AuctionHouse,
        _label: String,
    ): (Option<u64>, Option<u64>, Option<address>, Option<bool>) {
        // if (linked_table::contains(&auction_house.entries, label)) {
        //     let entry = linked_table::borrow(&auction_house.entries, label);
        //     return (
        //         some(entry.started_at_in_ms),
        //         some(entry.highest_bid),
        //         some(entry.winner),
        //         some(entry.is_claimed),
        //     )
        // };
        (none(), none(), none(), none())
    }

    // === Friend and Private Functions ===

    /// Last epoch to bid
    fun auction_house_close_at(auction: &AuctionHouse): u64 {
        auction.start_at + AUCTION_HOUSE_PERIOD - 1
    }

    // === Events ===

    struct AuctionStartedEvent has copy, drop {
        domain: Domain,
        start_timestamp_ms: u64,
        end_timestamp_ms: u64,
        starting_bid: u64,
        bidder: address,
    }

    struct BidEvent has copy, drop {
        domain: Domain,
        bid: u64,
        bidder: address,
    }

    struct AuctionExtendedEvent has copy, drop {
        domain: Domain,
        end_timestamp_ms: u64,
    }
}
