// SuiNS 1st Party Auction Module - Step 1: Auction Data Structures

/*
This file defines the core data structures for the SuiNS 1st Party Auction module.
It is intended to be placed in suins-contracts/packages/suins/sources/auction.move.
*/

module suins::auction {
    use sui::table::{Self, Table};
    use sui::coin::Coin;
    use sui::sui::SUI;
    use sui::clock::Clock;
    use sui::balance::{Self, Balance};
    use sui::event;
    use suins::suins_registration::SuinsRegistration;
    use sui::coin;

    /// Error codes
    const ENotOwner: u64 = 0;
    const ETooEarly: u64 = 1;
    const ETooLate: u64 = 2;
    const EBidTooLow: u64 = 3;
    const ENoBids: u64 = 4;
    const ENotEnded: u64 = 5;
    const ENotAuctioned: u64 = 6;
    const EAlreadyOffered: u64 = 7;
    const EDomainNotOffered: u64 = 8;
    const EAddressNotOffered: u64 = 9;
    const EAddressNotPresent: u64 = 10;

    /// Core Auction struct
    public struct Auction has key, store {
        id: UID,
        owner: address,
        start_time: u64,
        end_time: u64,
        min_bid: u64,
        highest_bidder: address,
        highest_bid_balance: Balance<SUI>,
        suins_registration: SuinsRegistration, 
    }

    /// Table mapping domain to Auction
    public struct AuctionTable has key, store {
        id: UID,
        table: Table<vector<u8>, Auction>,
    }

    /// Table mapping domain to Offers
    public struct OfferTable has key, store {
        id: UID,
        table: Table<vector<u8>, Table<address, Balance<SUI>>>,
    }

    public struct OfferAddresses has key, store {
        id: UID,
        addresses: Table<vector<u8>, vector<address>>,
    }

    /// Event for auction creation
    public struct AuctionCreatedEvent has copy, drop, store {
        domain_name: vector<u8>,
        owner: address,
        start_time: u64,
        end_time: u64,
        min_bid: u64,
    }
    /// Event for new bid
    public struct BidPlacedEvent has copy, drop, store {
        domain_name: vector<u8>,
        bidder: address,
        amount: u64,
    }
    /// Event for auction finalization
    public struct AuctionFinalizedEvent has copy, drop, store {
        domain_name: vector<u8>,
        winner: address,
        amount: u64,
    }
    /// Event for auction cancellation
    public struct AuctionCancelledEvent has copy, drop, store {
        domain_name: vector<u8>,
        owner: address,
    }

    fun init (ctx: &mut TxContext) {
        transfer::share_object(AuctionTable {
            id: object::new(ctx),
            table: table::new(ctx),
        });
        transfer::share_object(OfferTable {
            id: object::new(ctx),
            table: table::new(ctx),
        });
        transfer::share_object(OfferAddresses {
            id: object::new(ctx),
            addresses: table::new(ctx),
        });
    }

    /// Create a new auction for a domain
    public entry fun create_auction(
        auction_table: &mut AuctionTable,
        start_time: u64,
        end_time: u64,
        min_bid: u64,
        suins_registration: SuinsRegistration, 
        ctx: &mut TxContext
    ) {
        let domain = suins_registration.domain();
        let domain_name = domain.to_string().into_bytes();
        let owner = tx_context::sender(ctx);
        auction_table.table.add(
            domain_name,
            Auction {
                id: object::new(ctx),
                owner,
                start_time,
                end_time,
                min_bid,
                highest_bidder: @0x0,
                highest_bid_balance: balance::zero<SUI>(),
                suins_registration,
            }
        );

        event::emit(AuctionCreatedEvent {
            domain_name,
            owner,
            start_time,
            end_time,
            min_bid,
        });
    }

    /// Place a bid on an active auction
    public fun place_bid(
        auction_table: &mut AuctionTable,
        domain_name: vector<u8>,
        coin: Coin<SUI>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        assert!(auction_table.table.contains(domain_name), ENotAuctioned);

        let auction = auction_table.table.borrow_mut(domain_name);
        let now = clock.timestamp_ms() / 1000;
        if (now < auction.start_time) { abort ETooEarly };
        if (now > auction.end_time) { abort ETooLate };

        let bid_amount = coin.value();
        let highest_bid_value = auction.highest_bid_balance.value();
        if (bid_amount < auction.min_bid || bid_amount <= highest_bid_value) { abort EBidTooLow };

        if (highest_bid_value > 0) {
            let prev_balance = auction.highest_bid_balance.withdraw_all();
            transfer::public_transfer(coin::from_balance(prev_balance, ctx), auction.highest_bidder);
        };

        let bidder = tx_context::sender(ctx);
        auction.highest_bidder = bidder;
        auction.highest_bid_balance.join(coin.into_balance());

        event::emit(BidPlacedEvent {
            domain_name,
            bidder,
            amount: bid_amount,
        });
    }
 
    /// Finalize an auction after it ends, transfer domain and funds
    public entry fun finalize_auction(
        auction_table: &mut AuctionTable,
        domain_name: vector<u8>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        assert!(auction_table.table.contains(domain_name), ENotAuctioned);

        let Auction {
            id,
            owner,
            start_time: _,
            end_time,
            min_bid: _,
            highest_bidder,
            highest_bid_balance,
            suins_registration,
        } =  auction_table.table.remove(domain_name);

        let caller = tx_context::sender(ctx);
        if (owner != caller) { abort ENotOwner };

        let now = clock.timestamp_ms() / 1000;
        if (now < end_time) { abort ENotEnded };

        let highest_bid_value = balance::value(&highest_bid_balance);
        if (highest_bid_value == 0) { abort ENoBids };


        transfer::public_transfer(suins_registration, highest_bidder);
        transfer::public_transfer(coin::from_balance(highest_bid_balance, ctx), owner);

        event::emit(AuctionFinalizedEvent {
            domain_name,
            winner: highest_bidder,
            amount: highest_bid_value,
        });

        // Delete the auction object
        object::delete(id);
    }

    /// Cancel an auction (only by owner, only if no bids)
    public entry fun cancel_auction(
        auction_table: &mut AuctionTable,
        domain_name: vector<u8>,
        ctx: &mut TxContext
    ) {
        assert!(auction_table.table.contains(domain_name), ENotAuctioned);

        let Auction {
            id,
            owner,
            start_time: _,
            end_time: _,
            min_bid: _,
            highest_bidder: _,
            highest_bid_balance,
            suins_registration,
        } =  auction_table.table.remove(domain_name);

        let caller = tx_context::sender(ctx);
        if (owner != caller) { abort ENotOwner };

        let highest_bid_value = balance::value(&highest_bid_balance);
        if (highest_bid_value > 0) { abort ENoBids };

        balance::destroy_zero(highest_bid_balance);
        transfer::public_transfer(suins_registration, caller);

        object::delete(id);

        event::emit(AuctionCancelledEvent {
            domain_name,
            owner: caller,
        });
    }

    /// Place an offer on a domain not in auction
    public fun place_offer(
        offer_table: &mut OfferTable,
        offer_addresses: &mut OfferAddresses,
        domain_name: vector<u8>,
        coin: Coin<SUI>,
        ctx: &mut TxContext
    ) 
    {
        if (offer_table.table.contains(domain_name)) {
            let offers = offer_table.table.borrow_mut(domain_name);
            assert!(!offers.contains(tx_context::sender(ctx)), EAlreadyOffered);
            offers.add(tx_context::sender(ctx), coin.into_balance());
        } else {
            let mut offers = table::new<address, Balance<SUI>>(ctx);
            offers.add(tx_context::sender(ctx), coin.into_balance());
            offer_table.table.add(domain_name, offers);
        };
        let mut addresses = offer_addresses.addresses.borrow_mut(domain_name);
        addresses.push_back(tx_context::sender(ctx));
    }

    /// Cancel an offer on a domain not in auction
    public fun cancel_offer(
        offer_table: &mut OfferTable,
        offer_addresses: &mut OfferAddresses,
        domain_name: vector<u8>,
        ctx: &mut TxContext
    ) : Coin<SUI>
    {
        assert!(offer_table.table.contains(domain_name), EDomainNotOffered);
        let offers = offer_table.table.borrow_mut(domain_name);
        let caller = tx_context::sender(ctx);
        assert!(offers.contains(caller), EAddressNotOffered);
        remove_offer_address(offer_addresses, domain_name, &caller);
        let coin = remove_offer_balance(offer_table, domain_name, caller, ctx);
        coin
    }

    /// Accept an offer on a domain not in auction
    public fun accept_offer(
        offer_table: &mut OfferTable,
        offer_addresses: &mut OfferAddresses,
        suins_registration: SuinsRegistration, 
        address: address,
        ctx: &mut TxContext
    ) : Coin<SUI>
    {
        let domain = suins_registration.domain();
        let domain_name = domain.to_string().into_bytes();
        assert!(offer_table.table.contains(domain_name), EDomainNotOffered);

        let offers = offer_table.table.borrow(domain_name);
        assert!(offers.contains(address), EAddressNotOffered);

        remove_offer_address(offer_addresses, domain_name, &address);
        let coin = remove_offer_balance(offer_table, domain_name, address, ctx);
        transfer::public_transfer(suins_registration, address);

        clear_offer_tables(offer_table, offer_addresses, domain_name, ctx);

        coin
    }

    // Private functions 

    // Remove an address from the offer addresses table
    fun remove_offer_address(
        offer_addresses: &mut OfferAddresses,
        domain_name: vector<u8>,
        address: &address
    ) {
        let addresses = offer_addresses.addresses.borrow_mut(domain_name);
        let (present, index) = addresses.index_of(address);
        assert!(present, EAddressNotPresent);
        addresses.remove(index);
    }

    // Remove an address from the offer table
    fun remove_offer_balance(
        offer_table: &mut OfferTable,
        domain_name: vector<u8>,
        address: address,
        ctx: &mut TxContext
    ): Coin<SUI> {
        let offers = offer_table.table.borrow_mut(domain_name);
        let balance = offers.remove(address);
        coin::from_balance(balance, ctx)
    }


    // Clear offer tables
    fun clear_offer_tables(
        offer_table: &mut OfferTable,
        offer_addresses: &mut OfferAddresses,
        domain_name: vector<u8>,
        ctx: &mut TxContext
    ) {
        let mut addresses = offer_addresses.addresses.remove(domain_name); 
        let mut offers = offer_table.table.remove(domain_name);
        let len = vector::length(&addresses);
        let mut i = 0;
        while (i < len) {
            let addr = addresses.remove(i);
            let balance = offers.remove(addr);
            transfer::public_transfer(coin::from_balance<SUI>(balance, ctx), addr);
            i = i + 1;
        };
        offers.destroy_empty();
    }
}
