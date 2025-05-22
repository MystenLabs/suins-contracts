// SuiNS 1st Party Auction Module - Step 1: Auction Data Structures

/*
This file defines the core data structures for the SuiNS 1st Party Auction module.
It is intended to be placed in suins-contracts/packages/suins/sources/auction.move.
*/

module suins::auction {
    use sui::object::{Self, UID};
    use sui::address::Address;
    use suins::domain::Domain;
    use sui::table::Table;
    use sui::tx_context::TxContext;
    use sui::coin::Coin;
    use sui::sui::SUI;
    use sui::error;
    use sui::clock::Clock;
    use sui::option::{Self, Option};
    use sui::table;
    use sui::object;
    use sui::tx_context;
    use sui::tx_context::TxContext;
    use sui::transfer;
    use sui::balance;
    use sui::event;
    use suins::suins::SuiNS;
    use suins::registry::Registry;
    use suins::suins_registration::SuinsRegistration;
    use sui::coin;
    use sui::option;

    /// Status constants for an auction
    const AUCTION_STATUS_ACTIVE: u8 = 0;
    const AUCTION_STATUS_ENDED: u8 = 1;
    const AUCTION_STATUS_CANCELLED: u8 = 2;

    /// Core Auction struct
    public struct Auction has key, store {
        id: UID,
        domain: Domain,
        owner: address,
        start_time: u64,
        end_time: u64,
        min_bid: u64,
        highest_bid: u64,
        highest_bidder: address,
        highest_bid_coin: option::Option<Coin<SUI>>,
        status: u8, // 0 = Active, 1 = Ended, 2 = Cancelled
        old_nft: option::Option<SuinsRegistration>, // Store the old NFT
    }

    /// Table mapping domain to Auction
    public struct AuctionTable has key, store {
        id: UID,
        table: Table<Domain, Auction>,
    }

    /// Initializes a new AuctionTable (to be called during deployment/init)
    public fun init_auction_table(ctx: &mut TxContext): AuctionTable {
        AuctionTable {
            id: object::new(ctx),
            table: Table::new(ctx),
        }
    }

    /// Error codes
    const ENotOwner: u64 = 0;
    const EAlreadyAuctioned: u64 = 1;
    const ENotActive: u64 = 2;
    const ETooEarly: u64 = 3;
    const ETooLate: u64 = 4;
    const EBidTooLow: u64 = 5;
    const ENoBids: u64 = 6;
    const ENotEnded: u64 = 7;
    const EAlreadyFinalized: u64 = 8;

    /// Event for auction creation
    public struct AuctionCreatedEvent has copy, drop, store {
        domain: Domain,
        owner: address,
        start_time: u64,
        end_time: u64,
        min_bid: u64,
    }
    /// Event for new bid
    public struct BidPlacedEvent has copy, drop, store {
        domain: Domain,
        bidder: address,
        amount: u64,
    }
    /// Event for auction finalization
    public struct AuctionFinalizedEvent has copy, drop, store {
        domain: Domain,
        winner: address,
        amount: u64,
    }
    /// Event for auction cancellation
    public struct AuctionCancelledEvent has copy, drop, store {
        domain: Domain,
        owner: address,
    }

    /// Create a new auction for a domain
    public entry fun create_auction(
        auction_table: &mut AuctionTable,
        domain: Domain,
        owner: address,
        start_time: u64,
        end_time: u64,
        min_bid: u64,
        old_nft: SuinsRegistration, // Accept the old NFT
        ctx: &mut TxContext
    ) {
        // Only allow if not already auctioned
        if (table::contains(&auction_table.table, &domain)) {
            abort EAlreadyAuctioned;
        };
        table::insert(
            &mut auction_table.table,
            domain,
            Auction {
                id: object::new(ctx),
                domain: domain,
                owner,
                start_time,
                end_time,
                min_bid,
                highest_bid: 0,
                highest_bidder: address::ZERO(),
                highest_bid_coin: option::none(),
                status: 0,
                old_nft: option::some(old_nft),
            }
        );
        event::emit(AuctionCreatedEvent {
            domain,
            owner,
            start_time,
            end_time,
            min_bid,
        });
    }

    /// Place a bid on an active auction
    public entry fun place_bid(
        auction_table: &mut AuctionTable,
        domain: Domain,
        bidder: address,
        bid_amount: u64,
        coin: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        let auction = table::borrow_mut(&mut auction_table.table, &domain);
        if (auction.status != 0) { abort ENotActive; }
        mut now = tx_context::timestamp_ms(ctx) / 1000;
        if (now < auction.start_time) { abort ETooEarly; }
        if (now > auction.end_time) { abort ETooLate; }
        if (bid_amount < auction.min_bid || bid_amount <= auction.highest_bid) { abort EBidTooLow; }
        // Refund previous highest bidder
        if (option::is_some(&auction.highest_bid_coin)) {
            let prev_coin = option::extract(&mut auction.highest_bid_coin);
            coin::transfer(prev_coin, auction.highest_bidder);
        }
        auction.highest_bid = bid_amount;
        auction.highest_bidder = bidder;
        auction.highest_bid_coin = option::some(coin);
        event::emit(BidPlacedEvent {
            domain,
            bidder,
            amount: bid_amount,
        });
    }

    fun transfer_domain_ownership(
        auction: &mut Auction,
        winner: address
    ) {
        // Transfer the old NFT to the winner
        assert!(option::is_some(&auction.old_nft), 0); // Should always be present
        let nft = option::extract(&mut auction.old_nft);
        transfer::transfer(nft, winner);
    }

    /// Finalize an auction after it ends, transfer domain and funds
    public entry fun finalize_auction(
        auction_table: &mut AuctionTable,
        suins: &mut SuiNS,
        registry: &mut Registry,
        domain: Domain,
        ctx: &mut TxContext
    ) {
        let mut auction = table::borrow_mut(&mut auction_table.table, &domain);
        if (auction.status != 0) { abort ENotActive; }
        let now = tx_context::timestamp_ms(ctx) / 1000;
        if (now < auction.end_time) { abort ENotEnded; }
        auction.status = 1; // Ended
        // --- SuiNS Ownership Transfer ---
        transfer_domain_ownership(&mut auction, auction.highest_bidder);
        // --- Transfer funds to seller ---
        if (option::is_some(&auction.highest_bid_coin)) {
            let winning_coin = option::extract(&mut auction.highest_bid_coin);
            coin::transfer(winning_coin, auction.owner);
        }
        event::emit(AuctionFinalizedEvent {
            domain,
            winner: auction.highest_bidder,
            amount: auction.highest_bid,
        });
    }

    /// Cancel an auction (only by owner, only if no bids)
    public entry fun cancel_auction(
        auction_table: &mut AuctionTable,
        domain: Domain,
        caller: address,
        ctx: &mut TxContext
    ) {
        let mut auction = table::borrow_mut(&mut auction_table.table, &domain);
        if (auction.status != 0) { abort ENotActive; }
        if (auction.owner != caller) { abort ENotOwner; }
        if (auction.highest_bid > 0) { abort ENoBids; }
        auction.status = 2; // Cancelled
        event::emit(AuctionCancelledEvent {
            domain,
            owner: caller,
        });
        // Optionally: remove from table or keep for record
    }

    // Additional storage and helper structs can be added as needed in later steps.
    // Next: implement auction lifecycle functions (create_auction, place_bid, finalize_auction, etc.)
    // Note: Integration with SuiNS for domain transfer and secure bid refund is still required.
    // Next steps: Integrate with NameRecord/SuinsRegistration for ownership transfer on finalize, and escrow/refund logic for bids.
    // Add unit tests and further validation as needed.
}
