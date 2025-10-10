// SuiNS 1st Party Auction Module - Step 1: Auction Data Structures

/*
This file defines the core data structures for the SuiNS 1st Party Auction module.
It is intended to be placed in suins-contracts/packages/suins/sources/auction.move.
*/

module suins::auction {
    use sui::table::{Self, Table};
    use sui::bag::{Self, Bag};
    use sui::object_bag::{Self, ObjectBag};
    use sui::coin::{Self,Coin};
    use sui::sui::SUI;
    use sui::clock::Clock;
    use sui::balance::{Self, Balance};
    use sui::event;
    use suins::suins_registration::SuinsRegistration;
    use suins::controller::set_target_address;
    use suins::suins::SuiNS;
    use std::type_name::{Self, TypeName};

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
    const ENotUpgrade: u64 = 14;
    const EDifferentVersions: u64 = 15;
    const EInvalidAuctionTableVersion: u64 = 16;
    const EInvalidOfferTableVersion: u64 = 17;
    const ECannotRemoveSui: u64 = 18;
    const ETokenNotAllowed: u64 = 19;

    /// Constants
    const VERSION: u64 = 1;
    const BID_EXTEND_TIME: u64 = 5 * 60; // 5 minutes

    /// Authorization witness to call protected functions of suins.
    public struct AuctionWitness has drop {}

    /// Admin Cap
    public struct AdminCap has key, store {
        id: UID,
    }

    /// Core Auction struct
    public struct Auction<phantom T> has key, store {
        id: UID,
        owner: address,
        start_time: u64,
        end_time: u64,
        min_bid: u64,
        highest_bidder: address,
        highest_bid_balance: Balance<T>,
        suins_registration: SuinsRegistration,
    }

    /// Table mapping domain to Auction
    public struct AuctionTable has key {
        id: UID,
        version: u64,
        bag: ObjectBag, // vector<u8> -> Auction<T>
        allowed_tokens: Table<TypeName, bool>,
    }

    /// Table mapping domain to Offers and addresses that have made Offers
    public struct OfferTable has key {
        id: UID,
        version: u64,
        table: Table<vector<u8>, Bag>, // Bag: address -> Offer<T>
        allowed_tokens: Table<TypeName, bool>,
    }

    public struct Offer<phantom T> has store {
        balance: Balance<T>,
        counter_offer: u64,
    }

    /// Event for auction creation
    public struct AuctionCreatedEvent has copy, drop {
        auction_id: ID,
        domain_name: vector<u8>,
        owner: address,
        start_time: u64,
        end_time: u64,
        min_bid: u64,
        token: TypeName,
    }

    /// Event for new bid
    public struct BidPlacedEvent has copy, drop {
        auction_id: ID,
        domain_name: vector<u8>,
        bidder: address,
        amount: u64,
        token: TypeName,
    }

    /// Event for auction finalization
    public struct AuctionFinalizedEvent has copy, drop {
        auction_id: ID,
        domain_name: vector<u8>,
        winner: address,
        amount: u64,
        token: TypeName,
    }

    /// Event for auction cancellation
    public struct AuctionCancelledEvent has copy, drop {
        auction_id: ID,
        domain_name: vector<u8>,
        owner: address,
        token: TypeName,
    }

    /// Event for offer placement
    public struct OfferPlacedEvent has copy, drop {
        domain_name: vector<u8>,
        address: address,
        value: u64,
        token: TypeName,
    }

    /// Event for offer cancellation
    public struct OfferCancelledEvent has copy, drop {
        domain_name: vector<u8>,
        address: address,
        value: u64,
        token: TypeName,
    }

    /// Event for offer acceptance
    public struct OfferAcceptedEvent has copy, drop {
        domain_name: vector<u8>,
        owner: address,
        buyer: address,
        value: u64,
        token: TypeName,
    }

    /// Event for offer declined
    public struct OfferDeclinedEvent has copy, drop {
        domain_name: vector<u8>,
        owner: address,
        buyer: address,
        value: u64,
        token: TypeName,
    }

    /// Event for make counter offer
    public struct MakeCounterOfferEvent has copy, drop {
        domain_name: vector<u8>,
        owner: address,
        buyer: address,
        value: u64,
        token: TypeName,
    }

    /// Event for accept counter offer
    public struct AcceptCounterOfferEvent has copy, drop {
        domain_name: vector<u8>,
        buyer: address,
        value: u64,
        token: TypeName,
    }

    /// Event for migrating contract
    public struct MigrateEvent has copy, drop {
        old_version: u64,
        new_version: u64,
    }

    public struct AddAllowedToken has copy, drop {
        token: TypeName,
    }

    public struct RemoveAllowedToken has copy, drop {
        token: TypeName,
    }

    fun init (ctx: &mut TxContext) {
        let admin_cap = AdminCap {
            id: object::new(ctx),
        };

        let mut auction_table = AuctionTable {
            id: object::new(ctx),
            version: VERSION,
            bag: object_bag::new(ctx),
            allowed_tokens: table::new<TypeName, bool>(ctx),
        };
        let mut offer_table = OfferTable {
            id: object::new(ctx),
            version: VERSION,
            table: table::new(ctx),
            allowed_tokens: table::new<TypeName, bool>(ctx),
        };

        // Add SUI as allowed token
        add_allowed_token<SUI>(&admin_cap, &mut auction_table, &mut offer_table);

        transfer::share_object(auction_table);
        transfer::share_object(offer_table);
        transfer::transfer(admin_cap, ctx.sender());

    }

    entry fun migrate(_: &AdminCap, auction_table: &mut AuctionTable, offer_table: &mut OfferTable) {
        assert!(auction_table.version < VERSION, ENotUpgrade);
        assert!(offer_table.version < VERSION, ENotUpgrade);
        assert!(auction_table.version == offer_table.version, EDifferentVersions);

        let old_version = auction_table.version;
        auction_table.version = VERSION;
        offer_table.version = VERSION;

        MigrateEvent{
            old_version,
            new_version: VERSION,
        };
    }

    public fun add_allowed_token<T>(
        _: &AdminCap,
        auction_table: &mut AuctionTable,
        offer_table: &mut OfferTable
    ) {
        assert!(is_valid_auction_version(auction_table), EInvalidAuctionTableVersion);
        assert!(is_valid_offer_version(offer_table), EInvalidOfferTableVersion);

        let token = type_name::with_defining_ids<T>();

        auction_table.allowed_tokens.add(token, true);
        offer_table.allowed_tokens.add(token, true);

        event::emit(AddAllowedToken {
            token,
        });
    }

    public fun remove_allowed_token<T>(
        _: &AdminCap,
        auction_table: &mut AuctionTable,
        offer_table: &mut OfferTable
    ) {
        assert!(is_valid_auction_version(auction_table), EInvalidAuctionTableVersion);
        assert!(is_valid_offer_version(offer_table), EInvalidOfferTableVersion);

        let token = type_name::with_defining_ids<T>();

        assert!(token != type_name::with_defining_ids<SUI>(), ECannotRemoveSui);

        auction_table.allowed_tokens.remove(token);
        offer_table.allowed_tokens.remove(token);

        event::emit(RemoveAllowedToken {
            token,
        });
    }

    /// Create a new auction for a domain with a specific token required
    public fun create_auction<T>(
        auction_table: &mut AuctionTable,
        start_time: u64,
        end_time: u64,
        min_bid: u64,
        suins_registration: SuinsRegistration,
        ctx: &mut TxContext
    ) {
        assert!(is_valid_auction_version(auction_table), EInvalidAuctionTableVersion);
        assert!(end_time > start_time, EWrongTime);

        let token = type_name::with_defining_ids<T>();

        assert!(auction_table.allowed_tokens.contains(token), ETokenNotAllowed);

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
            highest_bid_balance: balance::zero<T>(),
            suins_registration,
        };
        let auction_id = object::id(&auction);
        auction_table.bag.add(
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
            token,
        });
    }

    /// Place a bid on an active auction
    public fun place_bid<T>(
        auction_table: &mut AuctionTable,
        domain_name: vector<u8>,
        coin: Coin<T>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        assert!(is_valid_auction_version(auction_table), EInvalidAuctionTableVersion);
        assert!(auction_table.bag.contains(domain_name), ENotAuctioned);

        let auction = auction_table.bag.borrow_mut<vector<u8>, Auction<T>>(domain_name);
        let now = clock.timestamp_ms() / 1000;
        assert!(now > auction.start_time, ETooEarly);
        assert!(now < auction.end_time, ETooLate);

        let bid_amount = coin.value();
        let highest_bid_value = auction.highest_bid_balance.value();
        assert!(bid_amount >= auction.min_bid && bid_amount > highest_bid_value, EBidTooLow);

        // If bid in last minutes, extend auction by minutes
        if (auction.end_time - now < BID_EXTEND_TIME) {
            auction.end_time = now + BID_EXTEND_TIME;
        };

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
            token: type_name::with_defining_ids<T>(),
        });
    }

    /// Finalize an auction after it ends, transfer domain and funds
    public fun finalize_auction<T>(
        suins: &mut SuiNS,
        auction_table: &mut AuctionTable,
        domain_name: vector<u8>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        assert!(is_valid_auction_version(auction_table), EInvalidAuctionTableVersion);
        assert!(auction_table.bag.contains(domain_name), ENotAuctioned);

        let auction = auction_table.bag.remove<vector<u8>, Auction<T>>(domain_name);
        let auction_id = object::id(&auction);
        let Auction<T> {
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
            token: type_name::with_defining_ids<T>(),
        });

        object::delete(id);
    }

    /// Cancel an auction 
    public fun cancel_auction<T>(
        auction_table: &mut AuctionTable,
        domain_name: vector<u8>,
        clock: &Clock,
        ctx: &mut TxContext
    ):  SuinsRegistration {
        assert!(is_valid_auction_version(auction_table), EInvalidAuctionTableVersion);
        assert!(auction_table.bag.contains(domain_name), ENotAuctioned);

        let auction = auction_table.bag.remove<vector<u8>, Auction<T>>(domain_name);
        let auction_id = object::id(&auction);
        let Auction<T> {
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
            token: type_name::with_defining_ids<T>(),
        });

        suins_registration
    }

    /// Place an offer on a domain 
    public fun place_offer<T>(
        offer_table: &mut OfferTable,
        domain_name: vector<u8>,
        coin: Coin<T>,
        ctx: &mut TxContext
    )
    {
        assert!(is_valid_offer_version(offer_table), EInvalidOfferTableVersion);

        let token = type_name::with_defining_ids<T>();

        assert!(offer_table.allowed_tokens.contains(token), ETokenNotAllowed);

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
            let mut offers = bag::new(ctx);
            offers.add(caller, offer);
            offer_table.table.add(domain_name, offers);
        };

        event::emit(OfferPlacedEvent {
            domain_name,
            address: tx_context::sender(ctx),
            value: coin_value,
            token,
        });
    }

    /// Cancel an offer on a domain 
    public fun cancel_offer<T>(
        offer_table: &mut OfferTable,
        domain_name: vector<u8>,
        ctx: &mut TxContext
    ) : Coin<T>
    {
        assert!(is_valid_offer_version(offer_table), EInvalidOfferTableVersion);

        let caller = tx_context::sender(ctx);

        let Offer {
            balance,
            counter_offer: _,
        } =  offer_remove<T>(offer_table, domain_name,caller);

        event::emit(OfferCancelledEvent {
            domain_name,
            address: caller,
            value: balance.value(),
            token: type_name::with_defining_ids<T>(),
        });

        coin::from_balance(balance, ctx)
    }

    /// Accept an offer 
    public fun accept_offer<T>(
        suins: &mut SuiNS,
        offer_table: &mut OfferTable,
        suins_registration: SuinsRegistration,
        address: address,
        clock: &Clock,
        ctx: &mut TxContext
    ) : Coin<T>
    {
        assert!(is_valid_offer_version(offer_table), EInvalidOfferTableVersion);

        let domain = suins_registration.domain();
        let domain_name = domain.to_string().into_bytes();
        let Offer {
            balance,
            counter_offer: _,
        } =  offer_remove<T>(offer_table, domain_name, address);

        set_target_address(suins, &suins_registration, option::some(address), clock);
        transfer::public_transfer(suins_registration, address);

        event::emit(OfferAcceptedEvent {
            domain_name,
            owner: tx_context::sender(ctx),
            buyer: address,
            value: balance.value(),
            token: type_name::with_defining_ids<T>(),
        });

        coin::from_balance(balance, ctx)
    }

    /// Decline an offer 
    public fun decline_offer<T>(
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
        } =  offer_remove<T>(offer_table, domain_name, address);

        let value = balance::value<T>(&balance);
        transfer::public_transfer(coin::from_balance(balance, ctx), address);

        event::emit(OfferDeclinedEvent {
            domain_name,
            owner: tx_context::sender(ctx),
            buyer: address,
            value,
            token: type_name::with_defining_ids<T>(),
        });
    }

    /// Make a counter offer 
    public fun make_counter_offer<T>(
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
        let offer = offer_borrow_mut<T>(offer_table, domain_name, address);
        assert!(counter_offer_value > offer.balance.value(), ECounterOfferTooLow);
        offer.counter_offer = counter_offer_value;

        event::emit(MakeCounterOfferEvent {
            domain_name,
            owner: tx_context::sender(ctx),
            buyer: address,
            value: counter_offer_value,
            token: type_name::with_defining_ids<T>(),
        });
    }

    /// Accept a counter offer
    public fun accept_counter_offer<T>(
        offer_table: &mut OfferTable,
        domain_name: vector<u8>,
        coin: Coin<T>,
        ctx: &mut TxContext
    )
    {
        assert!(is_valid_offer_version(offer_table), EInvalidOfferTableVersion);

        let caller = tx_context::sender(ctx);

        let offer = offer_borrow_mut<T>(offer_table, domain_name,caller);
        assert!(offer.counter_offer != 0, ENoCounterOffer);
        let coin_value = coin::value(&coin);
        let balance_value = offer.balance.value();
        assert!(coin_value + balance_value == offer.counter_offer, EWrongCoinValue);
        offer.balance.join(coin::into_balance(coin));

        event::emit(AcceptCounterOfferEvent {
            domain_name,
            buyer: caller,
            value: offer.balance.value(),
            token: type_name::with_defining_ids<T>(),
        });
    }

    // Can be used by the owner to get a mutate reference for the SuinsRegistration in case it expires so it can update it directly
    public fun get_suins_registration_from_auction<T>(auction: &mut Auction<T>, ctx: &mut TxContext): &mut SuinsRegistration {
        let caller = tx_context::sender(ctx);
        assert!(auction.owner == caller, ENotOwner);

        &mut auction.suins_registration
    }

    // Private functions 

    // Get mutable reference to offer from storage
    fun offer_borrow_mut<T>(
        offer_table: &mut OfferTable,
        domain_name: vector<u8>,
        address: address,
    ):  &mut Offer<T>  {
        let offers = domain_offers_borrow_mut(offer_table, domain_name, address);

        offers.borrow_mut(address)
    }

    // Remove offer from storage
    fun offer_remove<T>(
        offer_table: &mut OfferTable,
        domain_name: vector<u8>,
        address: address,
    ):  Offer<T>  {
        let offers = domain_offers_borrow_mut(offer_table, domain_name, address);
        let offer = offers.remove<address, Offer<T>>(address);

        if (offers.length() == 0) {
            let empty_table = offer_table.table.remove(domain_name);
            bag::destroy_empty(empty_table);
        };

        offer
    }

    // Get mutable reference to offers
    fun domain_offers_borrow_mut(
        offer_table: &mut OfferTable,
        domain_name: vector<u8>,
        address: address,
    ): &mut Bag {
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
    public fun get_auction_table(auction_table: &AuctionTable): &ObjectBag {
        &auction_table.bag
    }

    #[test_only]
    public fun get_auction<T>(auction_table: &ObjectBag, domain_name: vector<u8>): &Auction<T> {
        auction_table.borrow(domain_name)
    }

    #[test_only]
    public fun get_owner<T>(auction: &Auction<T>): address {
        auction.owner
    }

    #[test_only]
    public fun get_start_time<T>(auction: &Auction<T>): u64 {
        auction.start_time
    }

    #[test_only]
    public fun get_end_time<T>(auction: &Auction<T>): u64 {
        auction.end_time
    }

    #[test_only]
    public fun get_min_bid<T>(auction: &Auction<T>): u64 {
        auction.min_bid
    }

    #[test_only]
    public fun get_highest_bidder<T>(auction: &Auction<T>): address {
        auction.highest_bidder
    }

    #[test_only]
    public fun get_highest_bid_balance<T>(auction: &Auction<T>): &Balance<T> {
        &auction.highest_bid_balance
    }

    #[test_only]
    public fun get_suins_registration<T>(auction: &Auction<T>): &SuinsRegistration {
        &auction.suins_registration
    }

    #[test_only]
    public fun get_offer_table(offer_table: &OfferTable): &Table<vector<u8>, Bag> {
        &offer_table.table
    }

    #[test_only]
    public fun get_offer_balance<T>(offer: &Offer<T>): &Balance<T> {
        &offer.balance
    }

    #[test_only]
    public fun get_offer_counter_offer<T>(offer: &Offer<T>): u64 {
        offer.counter_offer
    }
}
