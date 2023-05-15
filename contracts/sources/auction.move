/// Implementation of auction module.
/// More information in: ../../../docs
module suins::auction {
    use std::option::{Self, Option, none, some, is_some};
    use std::string::{Self, String};

    use sui::tx_context::{Self, TxContext};
    use sui::balance::{Self, Balance};
    use sui::transfer;
    use sui::coin::{Self, Coin};
    use sui::clock::{Self, Clock};
    use sui::event;
    use sui::object::{Self, UID};
    use sui::sui::SUI;
    use sui::linked_table::{Self, LinkedTable};

    use suins::config::{Self, Config};
    use suins::suins::{Self, AdminCap, SuiNS};
    use suins::registration_nft::{Self as nft, RegistrationNFT};
    use suins::registry::{Self, Registry};
    use suins::domain::{Self, Domain};

    /// One year is the default duration for a domain.
    const DEFAULT_DURATION: u8 = 1;
    /// The auction bidding period is 2 days.
    const AUCTION_BIDDING_PERIOD_MS: u64 = 2 * 24 * 60 * 60 * 1000;
    /// The auction quiet period is 10 minutes.
    const AUCTION_MIN_QUIET_PERIOD_MS: u64 = 10 * 60 * 1000;

    // === Abort codes ===

    /// The bid value is too low (compared to min_bid or previous bid).
    const EInvalidBidValue: u64 = 0;
    /// Trying to start an action but it's already started.
    const EAuctionStarted: u64 = 1;
    /// Placing a bid in a not started
    const EAuctionNotStarted: u64 = 7;
    const EAuctionNotEndedYet: u64 = 8;
    const EAuctionEnded: u64 = 9;
    const ENotWinner: u64 = 10;
    const EWinnerCannotPlaceBid: u64 = 11;
    const EBidAmountTooLow: u64 = 12;
    const ENoProfits: u64 = 13;

    /// Authorization witness to call protected functions of suins.
    struct App has drop {}

    /// The AuctionHouse application.
    struct AuctionHouse has key, store {
        id: UID,
        balance: Balance<SUI>,
        auctions: LinkedTable<Domain, Auction>,
    }

    /// The Auction application.
    struct Auction has store {
        domain: Domain,
        start_timestamp_ms: u64,
        end_timestamp_ms: u64,
        winner: address,
        current_bid: Coin<SUI>,
        nft: RegistrationNFT,
    }

    fun init(ctx: &mut TxContext) {
        sui::transfer::share_object(AuctionHouse {
            id: object::new(ctx),
            balance: balance::zero(),
            auctions: linked_table::new(ctx),
        });
    }

    /// Start an auction if it's not started yet; and make the first bid.
    public fun start_auction_and_place_bid(
        self: &mut AuctionHouse,
        suins: &mut SuiNS,
        domain_name: String,
        bid: Coin<SUI>,
        clock: &Clock,
        ctx: &mut TxContext,
    ) {
        suins::assert_app_is_authorized<App>(suins);

        let domain = domain::new(domain_name);

        // make sure the domain is a .sui domain and not a subdomain
        config::assert_valid_user_registerable_domain(&domain);

        assert!(!linked_table::contains(&self.auctions, domain), EAuctionStarted);

        // The minimum price only applies to newly created auctions
        let config = suins::get_config<Config>(suins);
        let label = domain::sld(&domain);
        let min_price = config::calculate_price(config, (string::length(label) as u8), DEFAULT_DURATION);
        assert!(coin::value(&bid) >= min_price, EInvalidBidValue);

        let registry = suins::app_registry_mut<App, Registry>(App {}, suins);
        let nft = registry::add_record(registry, domain, DEFAULT_DURATION, clock, ctx);
        let starting_bid = coin::value(&bid);

        let auction = Auction {
            domain,
            start_timestamp_ms: clock::timestamp_ms(clock),
            end_timestamp_ms: clock::timestamp_ms(clock) + AUCTION_BIDDING_PERIOD_MS,
            winner: tx_context::sender(ctx),
            current_bid: bid,
            nft,
        };

        event::emit(AuctionStartedEvent {
            domain,
            start_timestamp_ms: auction.start_timestamp_ms,
            end_timestamp_ms: auction.end_timestamp_ms,
            starting_bid,
            bidder: auction.winner,
        });

        linked_table::push_front(&mut self.auctions, domain, auction)
    }

    /// #### Notice
    /// Bidders use this function to place a new bid.
    ///
    /// Panics
    /// Panics if `domain` is invalid
    /// or there isn't an auction for `domain`
    /// or `bid` is too low,
    public fun place_bid(
        self: &mut AuctionHouse,
        domain_name: String,
        bid: Coin<SUI>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let domain = domain::new(domain_name);
        let bidder = tx_context::sender(ctx);

        assert!(linked_table::contains(&self.auctions, domain), EAuctionNotStarted);

        let Auction {
            domain,
            start_timestamp_ms,
            end_timestamp_ms,
            winner,
            current_bid,
            nft,
        } = linked_table::remove(&mut self.auctions, domain);

        // Ensure that the auction is not over
        assert!(clock::timestamp_ms(clock) <= end_timestamp_ms, EAuctionEnded);
        // Ensure the bidder isn't already the winner
        assert!(bidder != winner, EWinnerCannotPlaceBid);

        // get the current highest bid and ensure that the new bid is greater than the current winning bid
        let current_winning_bid = coin::value(&current_bid);
        let bid_amount = coin::value(&bid);
        assert!(bid_amount > current_winning_bid, EBidAmountTooLow);

        // Return the previous winner their bid
        sui::transfer::public_transfer(current_bid, winner);

        event::emit(BidEvent {
            domain,
            bid: bid_amount,
            bidder,
        });

        // If there is less than `AUCTION_MIN_QUIET_PERIOD_MS` time left on the auction
        // then extend the auction so that there is `AUCTION_MIN_QUIET_PERIOD_MS` left.
        // Auctions can't be finished until there is at least `AUCTION_MIN_QUIET_PERIOD_MS`
        // time where there are no bids.
        if (end_timestamp_ms - clock::timestamp_ms(clock) < AUCTION_MIN_QUIET_PERIOD_MS) {
            let new_end_timestamp_ms = clock::timestamp_ms(clock) + AUCTION_MIN_QUIET_PERIOD_MS;

            // Only extend the auction if the new auction end time is before
            // the NFT's expiration timestamp
            if (new_end_timestamp_ms < nft::expiration_timestamp_ms(&nft)) {
                end_timestamp_ms = new_end_timestamp_ms;

                event::emit(AuctionExtendedEvent {
                    domain,
                    end_timestamp_ms: end_timestamp_ms,
                });
            }
        };

        let auction = Auction {
            domain,
            start_timestamp_ms,
            end_timestamp_ms,
            winner: tx_context::sender(ctx),
            current_bid: bid,
            nft,
        };

        linked_table::push_front(&mut self.auctions, domain, auction);
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

        let Auction {
            domain: _,
            start_timestamp_ms,
            end_timestamp_ms,
            winner,
            current_bid,
            nft,
        } = linked_table::remove(&mut self.auctions, domain);

        // Ensure that the auction is over
        assert!(clock::timestamp_ms(clock) > end_timestamp_ms, EAuctionNotEndedYet);

        // Ensure the sender is the winner
        assert!(tx_context::sender(ctx) == winner, ENotWinner);

        event::emit(AuctionFinalizedEvent {
            domain,
            start_timestamp_ms,
            end_timestamp_ms,
            winning_bid: coin::value(&current_bid),
            winner,
        });

        // Extract the NFT and their bid, returning the NFT to the user
        // and sending the proceeds of the auction to suins
        balance::join(&mut self.balance, coin::into_balance(current_bid));
        nft
    }

    // === Public Functions ===

    /// #### Notice
    /// Get metadata of an auction
    ///
    /// #### Params
    /// The domain name being auctioned.
    ///
    /// #### Return
    /// (`start_timestamp_ms`, `end_timestamp_ms`, `winner`, `highest_amount`)
    public fun get_auction_metadata(
        self: &AuctionHouse,
        domain_name: String,
    ): (Option<u64>, Option<u64>, Option<address>, Option<u64>) {
        let domain = domain::new(domain_name);

        if (linked_table::contains(&self.auctions, domain)) {
            let auction = linked_table::borrow(&self.auctions, domain);
            let highest_amount = coin::value(&auction.current_bid);
            return (
                some(auction.start_timestamp_ms),
                some(auction.end_timestamp_ms),
                some(auction.winner),
                some(highest_amount)
            )
        };
        (none(), none(), none(), none())
    }

    public fun collect_winning_auction_fund(
        self: &mut AuctionHouse,
        domain_name: String,
        clock: &Clock,
        ctx: &mut TxContext,
    ) {
        let domain = domain::new(domain_name);
        let auction = linked_table::borrow_mut(&mut self.auctions, domain);
        // Ensure that the auction is over
        assert!(clock::timestamp_ms(clock) > auction.end_timestamp_ms, EAuctionNotEndedYet);

        let amount = coin::value(&mut auction.current_bid);
        balance::join(&mut self.balance, coin::into_balance(coin::split(&mut auction.current_bid, amount, ctx)));
    }

    // === Admin Functions ===

    public fun admin_withdraw_funds(
        _: &AdminCap,
        self: &mut AuctionHouse,
        ctx: &mut TxContext,
    ): Coin<SUI> {
        let amount = balance::value(&self.balance);
        assert!(amount > 0, ENoProfits);
        coin::take(&mut self.balance, amount, ctx)
    }

    /// Admin functionality used to finalize a single auction.
    ///
    /// An `operation_limit` limit must be provided which controls how many
    /// individual operations to perform. This allows the admin to be able to
    /// make forward progress in finalizing auctions even in the presence of
    /// thousands of bids.
    ///
    /// This will attempt to do as much as possible of the following
    /// based on the provided `operation_limit`:
    /// - claim the winning bid and place in `AuctionHouse.balance`
    /// - push the `RegistrationNFT` to the winner
    /// - push loosing bids back to their respective account owners
    ///
    /// Once all of the above has been done the auction is destroyed,
    /// freeing on-chain storage.
    public fun admin_finalize_auction(
        admin: &AdminCap,
        self: &mut AuctionHouse,
        domain: String,
        clock: &Clock,
    ) {
        let domain = domain::new(domain);
        admin_finalize_auction_internal(admin, self, domain, clock);
    }

    fun admin_finalize_auction_internal(
        _: &AdminCap,
        self: &mut AuctionHouse,
        domain: Domain,
        clock: &Clock,
    ) {
        let Auction {
            domain: _,
            start_timestamp_ms,
            end_timestamp_ms,
            winner,
            current_bid,
            nft,
        } = linked_table::remove(&mut self.auctions, domain);

        // Ensure that the auction is over
        assert!(clock::timestamp_ms(clock) > end_timestamp_ms, EAuctionNotEndedYet);

        event::emit(AuctionFinalizedEvent {
            domain,
            start_timestamp_ms,
            end_timestamp_ms,
            winning_bid: coin::value(&current_bid),
            winner,
        });

        balance::join(&mut self.balance, coin::into_balance(current_bid));
        transfer::public_transfer(nft, winner);
    }

    /// Admin functionality used to finalize an arbitrary number of auctions.
    ///
    /// An `operation_limit` limit must be provided which controls how many
    /// individual operations to perform. This allows the admin to be able to
    /// make forward progress in finalizing auctions even in the presence of
    /// thousands of auctions/bids.
    public fun admin_try_finalize_auctions(
        admin: &AdminCap,
        self: &mut AuctionHouse,
        operation_limit: u64,
        clock: &Clock,
    ) {
        let next_domain = *linked_table::back(&self.auctions);

        while (is_some(&next_domain)) {
            if (operation_limit == 0) {
                return
            };
            operation_limit = operation_limit - 1;

            let domain = option::extract(&mut next_domain);
            next_domain = *linked_table::prev(&self.auctions, domain);

            let auction = linked_table::borrow(&self.auctions, domain);

            // If the auction has ended, then try to finalize it
            if (clock::timestamp_ms(clock) > auction.end_timestamp_ms) {
                admin_finalize_auction_internal(
                    admin,
                    self,
                    domain,
                    clock
                );
            };
        };
    }

    // === Events ===

    struct AuctionStartedEvent has copy, drop {
        domain: Domain,
        start_timestamp_ms: u64,
        end_timestamp_ms: u64,
        starting_bid: u64,
        bidder: address,
    }

    struct AuctionFinalizedEvent has copy, drop {
        domain: Domain,
        start_timestamp_ms: u64,
        end_timestamp_ms: u64,
        winning_bid: u64,
        winner: address,
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

    // === Testing ===

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        sui::transfer::share_object(AuctionHouse {
            id: object::new(ctx),
            balance: balance::zero(),
            auctions: linked_table::new(ctx),
        });
    }

    #[test_only]
    public fun total_balance(self: &AuctionHouse): u64 {
        balance::value(&self.balance)
    }
}
