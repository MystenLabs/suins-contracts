// SuiNS 1st Party Auction Module - Step 1: Auction Data Structures

/*
This file defines the core data structures for the SuiNS 1st Party Auction module.
It is intended to be placed in suins-contracts/packages/suins/sources/auction.move.
*/

module suins::auction {
    use sui::table::{Self, Table};
    use sui::object_table::{Self, ObjectTable};
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
    const EWrongTime: u64 = 3;
    const EBidTooLow: u64 = 4;
    const ENoBids: u64 = 5;
    const ENotEnded: u64 = 6;
    const ENotAuctioned: u64 = 7;
    const EAlreadyOffered: u64 = 8;
    const EDomainNotOffered: u64 = 9;
    const EAddressNotOffered: u64 = 10;
    const EAddressNotPresent: u64 = 11;

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
        table: ObjectTable<vector<u8>, Auction>,
    }

    /// Table mapping domain to Offers and addresses that have made Offers
    public struct OfferTable has key, store {
        id: UID,
        table: Table<vector<u8>, Table<address, Balance<SUI>>>,
        addresses: Table<vector<u8>, vector<address>>,
    }

    /// Event for auction creation
    public struct AuctionCreatedEvent has copy, drop, store {
        auction_id: ID,
        domain_name: vector<u8>,
        owner: address,
        start_time: u64,
        end_time: u64,
        min_bid: u64,
    }

    /// Event for new bid
    public struct BidPlacedEvent has copy, drop, store {
        auction_id: ID,
        domain_name: vector<u8>,
        bidder: address,
        amount: u64,
    }

    /// Event for auction finalization
    public struct AuctionFinalizedEvent has copy, drop, store {
        auction_id: ID,
        domain_name: vector<u8>,
        winner: address,
        amount: u64,
    }

    /// Event for auction cancellation
    public struct AuctionCancelledEvent has copy, drop, store {
        auction_id: ID,
        domain_name: vector<u8>,
        owner: address,
    }

    /// Event for offer placement
    public struct OfferPlacedEvent has copy, drop, store {
        domain_name: vector<u8>,
        address: address,
        value: u64,
    }

    /// Event for offer cancellation
    public struct OfferCancelledEvent has copy, drop, store {
        domain_name: vector<u8>,
        address: address,
        value: u64,
    }

    /// Event for offer acceptance
    public struct OfferAcceptedEvent has copy, drop, store {
        domain_name: vector<u8>,
        seller: address,
        buyer: address,
        value: u64,
    }

    fun init (ctx: &mut TxContext) {
        transfer::share_object(AuctionTable {
            id: object::new(ctx),
            table: object_table::new(ctx),
        });
        transfer::share_object(OfferTable {
            id: object::new(ctx),
            table: table::new(ctx),
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
        assert!(end_time > start_time, EWrongTime);
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
            auction_id: object::id(auction_table),
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
        assert!(now > auction.start_time, ETooEarly);
        assert!(now < auction.end_time, ETooLate);

        let bid_amount = coin.value();
        let highest_bid_value = auction.highest_bid_balance.value();
        assert!(bid_amount >= auction.min_bid && bid_amount > highest_bid_value, EBidTooLow);

        if (highest_bid_value > 0) {
            let prev_balance = auction.highest_bid_balance.withdraw_all();
            transfer::public_transfer(coin::from_balance(prev_balance, ctx), auction.highest_bidder);
        };

        let bidder = tx_context::sender(ctx);
        auction.highest_bidder = bidder;
        auction.highest_bid_balance.join(coin.into_balance());

        event::emit(BidPlacedEvent {
            auction_id: object::id(auction_table),
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

        let now = clock.timestamp_ms() / 1000;
        assert!(now > end_time, ENotEnded);

        let highest_bid_value = balance::value(&highest_bid_balance);
        assert!(highest_bid_value > 0, ENoBids);

        transfer::public_transfer(suins_registration, highest_bidder);
        if (highest_bid_balance.value() > 0) {
            transfer::public_transfer(coin::from_balance(highest_bid_balance, ctx), owner);
        } else {
            highest_bid_balance.destroy_zero();
        };

        event::emit(AuctionFinalizedEvent {
            auction_id: object::id(auction_table),
            domain_name,
            winner: highest_bidder,
            amount: highest_bid_value,
        });

        object::delete(id);
    }

    /// Cancel an auction 
    public fun cancel_auction(
        auction_table: &mut AuctionTable,
        domain_name: vector<u8>,
        clock: &Clock,
        ctx: &mut TxContext
    ):  SuinsRegistration {
        assert!(auction_table.table.contains(domain_name), ENotAuctioned);

        let Auction {
            id,
            owner,
            start_time: _,
            end_time ,
            min_bid: _,
            highest_bidder,
            highest_bid_balance,
            suins_registration,
        } =  auction_table.table.remove(domain_name);

        let caller = tx_context::sender(ctx);
        assert!(owner == caller, ENotOwner);

        let now = clock.timestamp_ms() / 1000;
        assert!(now < end_time, ENotEnded);

        if (highest_bid_balance.value() > 0) {
            transfer::public_transfer(coin::from_balance(highest_bid_balance, ctx), highest_bidder);
        } else {
            highest_bid_balance.destroy_zero();
        };

        object::delete(id);

        event::emit(AuctionCancelledEvent {
            auction_id: object::id(auction_table),
            domain_name,
            owner: caller,
        });

        suins_registration
    }

    /// Place an offer on a domain not in auction
    public fun place_offer(
        offer_table: &mut OfferTable,
        domain_name: vector<u8>,
        coin: Coin<SUI>,
        ctx: &mut TxContext
    ) 
    {
        let coin_value = coin.value();
        let caller = tx_context::sender(ctx);
        if (offer_table.table.contains(domain_name)) {
            let offers = offer_table.table.borrow_mut(domain_name);
            assert!(!offers.contains(caller), EAlreadyOffered);
            offers.add(caller, coin.into_balance());

            let addresses = offer_table.addresses.borrow_mut(domain_name);
            addresses.push_back(caller);
        } else {
            let mut offers = table::new<address, Balance<SUI>>(ctx);
            offers.add(caller, coin.into_balance());
            offer_table.table.add(domain_name, offers);

            let mut addresses = vector::empty<address>();
            addresses.push_back(caller);
            offer_table.addresses.add(domain_name, addresses);
        };

        event::emit(OfferPlacedEvent {
            domain_name,
            address: tx_context::sender(ctx),
            value: coin_value,
        });
    }

    /// Cancel an offer on a domain not in auction
    public fun cancel_offer(
        offer_table: &mut OfferTable,
        domain_name: vector<u8>,
        ctx: &mut TxContext
    ) : Coin<SUI>
    {
        assert!(offer_table.table.contains(domain_name), EDomainNotOffered);
        let offers = offer_table.table.borrow_mut(domain_name);
        let caller = tx_context::sender(ctx);
        assert!(offers.contains(caller), EAddressNotOffered);
        let (coin, _) = remove_offer(offer_table, domain_name, caller, ctx);

        event::emit(OfferCancelledEvent {
            domain_name,
            address: caller,
            value: coin.value(),
        });

        coin
    }

    /// Accept an offer on a domain not in auction
    public fun accept_offer(
        offer_table: &mut OfferTable,
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

        let (coin, empty_storage) = remove_offer(offer_table, domain_name, address, ctx);
        transfer::public_transfer(suins_registration, address);

        if (!empty_storage) {
            clear_offer_tables(offer_table, domain_name, ctx);
        };

        event::emit(OfferAcceptedEvent {
            domain_name,
            seller: tx_context::sender(ctx),
            buyer: address,
            value: coin.value(),
        });

        coin
    }

    // Private functions 

    // Remove an offer from storage
    fun remove_offer(
        offer_table: &mut OfferTable,
        domain_name: vector<u8>,
        address: address,
        ctx: &mut TxContext
    ): (Coin<SUI>, bool) {
        assert!(offer_table.addresses.contains(domain_name),EAddressNotOffered);
        let addresses = offer_table.addresses.borrow_mut(domain_name);
        let (present, index) = addresses.index_of(&address);
        assert!(present, EAddressNotPresent);
        addresses.remove(index);
        let addresses_empty = addresses.length() == 0;
        if (addresses_empty) {
            let addresses = offer_table.addresses.remove(domain_name);
            addresses.destroy_empty();
        };

        assert!(offer_table.table.contains(domain_name), EDomainNotOffered);
        let offers = offer_table.table.borrow_mut(domain_name);
        let balance = offers.remove(address);
        let offers_empty = offers.length() == 0;
        if (offers_empty) {
            let offers = offer_table.table.remove(domain_name);
            offers.destroy_empty();
        };

        (coin::from_balance(balance, ctx), addresses_empty && offers_empty)
    }


    // Clear offer tables
    fun clear_offer_tables(
        offer_table: &mut OfferTable,
        domain_name: vector<u8>,
        ctx: &mut TxContext
    ) {
        assert!(offer_table.addresses.contains(domain_name),EAddressNotOffered);
        assert!(offer_table.table.contains(domain_name), EDomainNotOffered);

        let mut addresses = offer_table.addresses.remove(domain_name); 
        let mut offers = offer_table.table.remove(domain_name);
        let len = vector::length(&addresses);
        let mut i = 0;
        while (i < len) {
            let addr = addresses.remove(i);
            let balance = offers.remove(addr);
            transfer::public_transfer(coin::from_balance<SUI>(balance, ctx), addr);
            i = i + 1;
        };
        addresses.destroy_empty();
        offers.destroy_empty();
    }

    // Testing functions 

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(ctx);
    }
}
