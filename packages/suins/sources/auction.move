// SuiNS 1st Party Auction Module - Step 1: Auction Data Structures

/*
This file defines the core data structures for the SuiNS 1st Party Auction module.
It is intended to be placed in suins-contracts/packages/suins/sources/auction.move.
*/

module suins::auction {
    use sui::table::{Self, Table};
    use sui::object_table::{Self, ObjectTable};
    use sui::coin::{Self,Coin};
    use sui::sui::SUI;
    use sui::clock::Clock;
    use sui::balance::{Self, Balance};
    use sui::event;
    use suins::suins_registration::SuinsRegistration;
    use suins::controller::set_target_address;
    use suins::suins::SuiNS;

    /// Error codes
    const ENotOwner: u64 = 0;
    const ETooEarly: u64 = 1;
    const ETooLate: u64 = 2;
    const EWrongTime: u64 = 3;
    const EBidTooLow: u64 = 4;
    const ENotEnded: u64 = 5;
    const EEnded: u64 = 6;
    const ENotAuctioned: u64 = 7;
    const EAlreadyOffered: u64 = 8;
    const EDomainNotOffered: u64 = 9;
    const EAddressNotOffered: u64 = 10;
    const ECounterOfferTooLow: u64 = 11;
    const EWrongCoinValue: u64 = 12;
    const ENoCounterOffer: u64 = 13;
    const ENotAdmin: u64 = 14;
    const ENotUpgrade: u64 = 15;
    const EDifferentVersions: u64 = 16;
    const EInvalidAuctionTableVersion: u64 = 17;
    const EInvalidOfferTableVersion: u64 = 18;

    // Constants
    const VERSION: u64 = 1;
    
    /// Admin Cap
    public struct AdminCap has key {
        id: UID,
    }
    
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
        version: u64,
        admin: ID,
        table: ObjectTable<vector<u8>, Auction>,
    }

    /// Table mapping domain to Offers and addresses that have made Offers
    public struct OfferTable has key, store {
        id: UID,
        version: u64,
        admin: ID,
        table: Table<vector<u8>, Table<address, Offer>>,
    }

    public struct Offer has store {
        balance: Balance<SUI>,
        counter_offer: u64,
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
        owner: address,
        buyer: address,
        value: u64,
    }

    /// Event for offer declined
    public struct OfferDeclinedEvent has copy, drop, store {
        domain_name: vector<u8>,
        owner: address,
        buyer: address,
        value: u64,
    }

    /// Event for counter offer
    public struct MakeCounterOfferEvent has copy, drop, store {
        domain_name: vector<u8>,
        owner: address,
        buyer: address,
        value: u64,
    }

    public struct AcceptCounterOfferEvent has copy, drop, store {
        domain_name: vector<u8>,
        buyer: address,
        value: u64,
    }

    public struct MigrateEvent has copy, drop, store {
        old_version: u64,
        new_version: u64,
    }


    fun init (ctx: &mut TxContext) {
        let admin_cap = AdminCap {
            id: object::new(ctx),
        };
        let admin_cap_id = object::id(&admin_cap);

        transfer::share_object(AuctionTable {
            id: object::new(ctx),
            version: VERSION,
            admin: admin_cap_id,
            table: object_table::new(ctx),
        });
        transfer::share_object(OfferTable {
            id: object::new(ctx),
            version: VERSION,
            admin: admin_cap_id,
            table: table::new(ctx),
        });
        transfer::transfer(admin_cap, ctx.sender());

    }

    entry fun migrate(admin_cap: &AdminCap, auction_table: &mut AuctionTable, offer_table: &mut OfferTable) {
        assert!(auction_table.version == offer_table.version, EDifferentVersions);     
        let admin_cap_id = object::id(admin_cap);
        assert!(auction_table.admin == admin_cap_id, ENotAdmin);
        assert!(auction_table.version < VERSION, ENotUpgrade);
        assert!(offer_table.admin == admin_cap_id, ENotAdmin);
        assert!(offer_table.version < VERSION, ENotUpgrade);   
        let old_version = auction_table.version;
        auction_table.version = VERSION;
        offer_table.version = VERSION;

        MigrateEvent{
            old_version,
            new_version: VERSION,
        };
    }

    /// Create a new auction for a domain
    public fun create_auction(
        auction_table: &mut AuctionTable,
        start_time: u64,
        end_time: u64,
        min_bid: u64,
        suins_registration: SuinsRegistration, 
        ctx: &mut TxContext
    ) {
        assert!(is_valid_auction_version(auction_table), EInvalidAuctionTableVersion);
        assert!(end_time > start_time, EWrongTime);
        let domain = suins_registration.domain();
        let domain_name = domain.to_string().into_bytes();
        let owner = tx_context::sender(ctx);
        let auction = Auction {
            id: object::new(ctx),
            owner,
            start_time,
            end_time,
            min_bid,
            highest_bidder: @0x0,
            highest_bid_balance: balance::zero<SUI>(),
            suins_registration,
        };
        let auction_id = object::id(&auction);
        auction_table.table.add(
            domain_name,
            auction,
        );

        event::emit(AuctionCreatedEvent {
            auction_id,
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
        assert!(is_valid_auction_version(auction_table), EInvalidAuctionTableVersion);
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
            auction_id: object::id(auction),
            domain_name,
            bidder,
            amount: bid_amount,
        });
    }
 
    /// Finalize an auction after it ends, transfer domain and funds
    public fun finalize_auction(
        suins: &mut SuiNS,
        auction_table: &mut AuctionTable,
        domain_name: vector<u8>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        assert!(is_valid_auction_version(auction_table), EInvalidAuctionTableVersion);
        assert!(auction_table.table.contains(domain_name), ENotAuctioned);

        let auction = auction_table.table.remove(domain_name);
        let auction_id = object::id(&auction);
        let Auction {
            id,
            owner,
            start_time: _,
            end_time,
            min_bid: _,
            highest_bidder,
            highest_bid_balance,
            suins_registration,
        } = auction;

        let now = clock.timestamp_ms() / 1000;
        assert!(now > end_time, ENotEnded);

        let highest_bid_value = balance::value(&highest_bid_balance);

        if (highest_bid_balance.value() > 0) {
            set_target_address(suins, &suins_registration, option::some(highest_bidder), clock);
            transfer::public_transfer(coin::from_balance(highest_bid_balance, ctx), owner);
            transfer::public_transfer(suins_registration, highest_bidder);
        } else {
            highest_bid_balance.destroy_zero();
            transfer::public_transfer(suins_registration, owner);
        };

        event::emit(AuctionFinalizedEvent {
            auction_id,
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
        assert!(is_valid_auction_version(auction_table), EInvalidAuctionTableVersion);
        assert!(auction_table.table.contains(domain_name), ENotAuctioned);

        let auction = auction_table.table.remove(domain_name);
        let auction_id = object::id(&auction);
        let Auction {
            id,
            owner,
            start_time: _,
            end_time ,
            min_bid: _,
            highest_bidder,
            highest_bid_balance,
            suins_registration,
        } =  auction;

        let caller = tx_context::sender(ctx);
        assert!(owner == caller, ENotOwner);

        let now = clock.timestamp_ms() / 1000;
        assert!(now < end_time, EEnded);

        if (highest_bid_balance.value() > 0) {
            transfer::public_transfer(coin::from_balance(highest_bid_balance, ctx), highest_bidder);
        } else {
            highest_bid_balance.destroy_zero();
        };

        object::delete(id);

        event::emit(AuctionCancelledEvent {
            auction_id,
            domain_name,
            owner: caller,
        });

        suins_registration
    }

    /// Place an offer on a domain 
    public fun place_offer(
        offer_table: &mut OfferTable,
        domain_name: vector<u8>,
        coin: Coin<SUI>,
        ctx: &mut TxContext
    ) 
    {
        assert!(is_valid_offer_version(offer_table), EInvalidOfferTableVersion);
        let coin_value = coin.value();
        let caller = tx_context::sender(ctx);
        let offer = Offer {
            balance: coin.into_balance(),
            counter_offer: 0,
        };
        if (offer_table.table.contains(domain_name)) {
            let offers = offer_table.table.borrow_mut(domain_name);
            assert!(!offers.contains(caller), EAlreadyOffered);
            offers.add(caller, offer);
        } else {
            let mut offers = table::new<address, Offer>(ctx);
            offers.add(caller, offer);
            offer_table.table.add(domain_name, offers);
        };

        event::emit(OfferPlacedEvent {
            domain_name,
            address: tx_context::sender(ctx),
            value: coin_value,
        });
    }

    /// Cancel an offer on a domain 
    public fun cancel_offer(
        offer_table: &mut OfferTable,
        domain_name: vector<u8>,
        ctx: &mut TxContext
    ) : Coin<SUI>
    {
        assert!(is_valid_offer_version(offer_table), EInvalidOfferTableVersion);

        let caller = tx_context::sender(ctx); 

        let Offer {
            balance,
            counter_offer: _,
        } =  offer_remove(offer_table, domain_name,caller);

        event::emit(OfferCancelledEvent {
            domain_name,
            address: caller, 
            value: balance.value(),
        });

        coin::from_balance(balance, ctx)
    }

    /// Accept an offer 
    public fun accept_offer(
        suins: &mut SuiNS,
        offer_table: &mut OfferTable,
        suins_registration: SuinsRegistration, 
        address: address,
        clock: &Clock,
        ctx: &mut TxContext
    ) : Coin<SUI>
    {
        assert!(is_valid_offer_version(offer_table), EInvalidOfferTableVersion);

        let domain = suins_registration.domain();
        let domain_name = domain.to_string().into_bytes();
        let Offer {
            balance,
            counter_offer: _,
        } =  offer_remove(offer_table, domain_name, address);

        set_target_address(suins, &suins_registration, option::some(address), clock);
        transfer::public_transfer(suins_registration, address);

        event::emit(OfferAcceptedEvent {
            domain_name,
            owner: tx_context::sender(ctx),
            buyer: address,
            value: balance.value(),
        });

        coin::from_balance(balance, ctx)
    }

    /// Decline an offer 
    public fun decline_offer(
        offer_table: &mut OfferTable,
        suins_registration: &SuinsRegistration, 
        address: address,
        ctx: &mut TxContext
    ) 
    {
        assert!(is_valid_offer_version(offer_table), EInvalidOfferTableVersion);

        let domain = suins_registration.domain();
        let domain_name = domain.to_string().into_bytes();
        let Offer {
            balance,
            counter_offer: _,
        } =  offer_remove(offer_table, domain_name, address);

        let value = balance::value<SUI>(&balance);
        transfer::public_transfer(coin::from_balance(balance, ctx), address);

        event::emit(OfferDeclinedEvent {
            domain_name,
            owner: tx_context::sender(ctx),
            buyer: address,
            value,
        });
    }

    /// Make a counter offer 
    public fun make_counter_offer(
        offer_table: &mut OfferTable,
        suins_registration: &SuinsRegistration, 
        address: address,
        counter_offer_value: u64,
        ctx: &mut TxContext
    )  
    {
        assert!(is_valid_offer_version(offer_table), EInvalidOfferTableVersion);

        let domain = suins_registration.domain();
        let domain_name = domain.to_string().into_bytes();
        let offer = offer_borrow_mut(offer_table, domain_name, address);
        assert!(counter_offer_value > offer.balance.value(), ECounterOfferTooLow);
        offer.counter_offer = counter_offer_value;

        event::emit(MakeCounterOfferEvent {
            domain_name,
            owner: tx_context::sender(ctx),
            buyer: address,
            value: counter_offer_value,
        });
    }

    /// Accept a counter offer
    public fun accept_counter_offer(
        offer_table: &mut OfferTable,
        domain_name: vector<u8>,
        coin: Coin<SUI>,
        ctx: &mut TxContext
    )
    {
        assert!(is_valid_offer_version(offer_table), EInvalidOfferTableVersion);

        let caller = tx_context::sender(ctx); 

        let offer = offer_borrow_mut(offer_table, domain_name,caller);
        assert!(offer.counter_offer != 0, ENoCounterOffer);
        let coin_value = coin::value(&coin);
        let balance_value = offer.balance.value();
        assert!(coin_value + balance_value == offer.counter_offer, EWrongCoinValue);
        offer.balance.join(coin::into_balance(coin));

        event::emit(AcceptCounterOfferEvent {
            domain_name,
            buyer: caller,
            value: offer.balance.value(),
        });
    }

    // Private functions 

    // Get mutable reference to offer from storage
    fun offer_borrow_mut(
        offer_table: &mut OfferTable,
        domain_name: vector<u8>,
        address: address,
    ):  &mut Offer  {
        let offers = domain_offers_borrow_mut(offer_table, domain_name, address);

        offers.borrow_mut(address)
    }

    // Remove offer from storage
    fun offer_remove(
        offer_table: &mut OfferTable,
        domain_name: vector<u8>,
        address: address,
    ):  Offer  {
        let offers = domain_offers_borrow_mut(offer_table, domain_name, address);
        let offer = offers.remove(address);
        
        if (offers.length() == 0) {
            let empty_table = offer_table.table.remove(domain_name);
            table::destroy_empty(empty_table);
        };

        offer
    }

    // Get mutable reference to offers
    fun domain_offers_borrow_mut(
        offer_table: &mut OfferTable,
        domain_name: vector<u8>,
        address: address,
    ): &mut Table<address, Offer> {
        assert!(offer_table.table.contains(domain_name), EDomainNotOffered);
        let offers = offer_table.table.borrow_mut(domain_name);
        assert!(offers.contains(address), EAddressNotOffered);

        offers
    }

    // Verify version
    fun is_valid_auction_version(auction_table: &AuctionTable): bool {
        auction_table.version == VERSION
    }

    fun is_valid_offer_version(offer_table: &OfferTable): bool {
        offer_table.version == VERSION
    }


    // Testing functions 

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(ctx);
    }

    #[test_only] 
    public fun get_auction_table(auction_table: &AuctionTable): &ObjectTable<vector<u8>, Auction> {
        &auction_table.table
    }

    #[test_only] 
    public fun get_auction(auction_table: &ObjectTable<vector<u8>, Auction>, domain_name: vector<u8>): &Auction {
        auction_table.borrow(domain_name)
    }

    #[test_only]
    public fun get_owner(auction: &Auction): address {
        auction.owner
    }

    #[test_only]
    public fun get_start_time(auction: &Auction): u64 {
        auction.start_time
    }

    #[test_only]
    public fun get_end_time(auction: &Auction): u64 {
        auction.end_time
    }

    #[test_only]
    public fun get_min_bid(auction: &Auction): u64 {
        auction.min_bid
    }

    #[test_only]
    public fun get_highest_bidder(auction: &Auction): address {
        auction.highest_bidder
    }

    #[test_only]
    public fun get_highest_bid_balance(auction: &Auction): &Balance<SUI> {
        &auction.highest_bid_balance
    }

    #[test_only]
    public fun get_suins_registration(auction: &Auction): &SuinsRegistration {
        &auction.suins_registration
    }

    #[test_only]
    public fun get_offer_table(offer_table: &OfferTable): &Table<vector<u8>, Table<address, Offer>> {
        &offer_table.table
    }

    #[test_only]
    public fun get_offer_balance(offer: &Offer): &Balance<SUI> {
        &offer.balance
    }

    #[test_only]
    public fun get_offer_counter_offer(offer: &Offer): u64 {
        offer.counter_offer
    }
}
