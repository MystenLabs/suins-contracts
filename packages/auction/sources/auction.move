// SuiNS 1st Party Auction Module - Step 1: Auction Data Structures

/*
This file defines the core data structures for the SuiNS 1st Party Auction module.
*/

module suins_auction::auction;

use seal::bf_hmac_encryption::{EncryptedObject, parse_encrypted_object};
use std::{string::String, type_name::{Self, TypeName}};
use sui::{
    bag::{Self, Bag},
    balance::{Self, Balance},
    clock::Clock,
    coin::Coin,
    event,
    object_bag::{Self, ObjectBag},
    sui::SUI,
    table::{Self, Table}
};
use suins::{controller::set_target_address, suins::SuiNS, suins_registration::SuinsRegistration};
use suins_auction::decryption::{decrypt_reserve_price, get_encryption_id};
use suins_auction::offer::{
    Self,
    OfferTable,
    subtract_fee,
};
use suins_auction::constants::{
    bid_extend_time,
    default_fee_percentage,
    max_percentage,
    version,
};

/// Error codes
const ENotOwner: u64 = 0;
const ETooEarly: u64 = 1;
const ETooLate: u64 = 2;
const EWrongTime: u64 = 3;
const EBidTooLow: u64 = 4;
const ENotEnded: u64 = 5;
const EEnded: u64 = 6;
const ENotAuctioned: u64 = 7;
const ENotUpgrade: u64 = 8;
const EDifferentVersions: u64 = 9;
const EInvalidAuctionTableVersion: u64 = 10;
const ECannotRemoveSui: u64 = 11;
const ETokenNotAllowed: u64 = 12;
const EInvalidEncryptionSender: u64 = 13;
const EInvalidEncryptionServers: u64 = 14;
const EInvalidEncryptionThreshold: u64 = 15;
const EInvalidEncryptionId: u64 = 16;
const EInvalidEncryptionPackageId: u64 = 17;
const EEncryptionNoAccess: u64 = 18;
const EEncryptionNoKeys: u64 = 19;
const EInvalidThreshold: u64 = 20;
const EInvalidKeyLengths: u64 = 21;
const EInvalidServiceFee: u64 = 22;

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
    reserve_price: Option<EncryptedObject>,
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
    /// The key servers that must be used for seal encryption.
    key_servers: vector<address>,
    /// The public keys for the key servers in the same order as `key_servers`.
    public_keys: vector<vector<u8>>,
    /// The threshold for the vote.
    threshold: u8,
    service_fee: u64,
    /// Accumulated service fees for each token type
    fees: Bag, // TypeName -> Balance<T>
}

/// Event for auction creation
public struct AuctionCreatedEvent has copy, drop {
    auction_id: ID,
    domain_name: String,
    owner: address,
    start_time: u64,
    end_time: u64,
    min_bid: u64,
    reserve_price: Option<vector<u8>>,
    token: TypeName,
}

/// Event for new bid
public struct BidPlacedEvent has copy, drop {
    auction_id: ID,
    domain_name: String,
    bidder: address,
    amount: u64,
    token: TypeName,
}

/// Event for auction finalization
public struct AuctionFinalizedEvent has copy, drop {
    auction_id: ID,
    domain_name: String,
    winner: address,
    amount: u64,
    reserve_price: u64,
    token: TypeName,
}

/// Event for auction cancellation
public struct AuctionCancelledEvent has copy, drop {
    auction_id: ID,
    domain_name: String,
    owner: address,
    token: TypeName,
}

/// Event for migrating contract
public struct MigrateEvent has copy, drop {
    old_version: u64,
    new_version: u64,
}

/// Event for set seal config
public struct SetSealConfig has copy, drop {
    key_servers: vector<address>,
    public_keys: vector<vector<u8>>,
    threshold: u8,
}

/// Event for set service fee
public struct SetServiceFee has copy, drop {
    service_fee: u64,
}

/// Event for add allowed token
public struct AddAllowedToken has copy, drop {
    token: TypeName,
}

/// Event for remove allowed token
public struct RemoveAllowedToken has copy, drop {
    token: TypeName,
}

/// Event for withdraw fees
public struct WithdrawFees has copy, drop {
    token: TypeName,
    amount: u64,
    recipient: address,
}

fun init(ctx: &mut TxContext) {
    let admin_cap = AdminCap {
        id: object::new(ctx),
    };

    let mut auction_table = AuctionTable {
        id: object::new(ctx),
        version: version(),
        bag: object_bag::new(ctx),
        allowed_tokens: table::new<TypeName, bool>(ctx),
        key_servers: vector[],
        public_keys: vector[],
        threshold: 0,
        service_fee: default_fee_percentage(),
        fees: bag::new(ctx),
    };
    let mut offer_table = offer::create(ctx);

    // Add SUI as allowed token
    add_allowed_token<SUI>(&admin_cap, &mut auction_table, &mut offer_table);

    transfer::share_object(auction_table);
    offer_table.share();
    transfer::transfer(admin_cap, ctx.sender());
}

entry fun migrate(_: &AdminCap, auction_table: &mut AuctionTable, offer_table: &mut OfferTable) {
    assert!(auction_table.version < version(), ENotUpgrade);
    assert!(offer_table.version() < version(), ENotUpgrade);
    assert!(auction_table.version == offer_table.version(), EDifferentVersions);

    let old_version = auction_table.version;
    auction_table.version = version();
    offer_table.set_version(version());

    MigrateEvent {
        old_version,
        new_version: version(),
    };
}

public fun set_seal_config(
    _: &AdminCap,
    auction_table: &mut AuctionTable,
    key_servers: vector<address>,
    public_keys: vector<vector<u8>>,
    threshold: u8,
) {
    assert!(auction_table.is_valid_auction_version(), EInvalidAuctionTableVersion);
    assert!(threshold <= key_servers.length() as u8, EInvalidThreshold);
    assert!(key_servers.length() == public_keys.length(), EInvalidKeyLengths);

    auction_table.key_servers = key_servers;
    auction_table.public_keys = public_keys;
    auction_table.threshold = threshold;

    event::emit(SetSealConfig {
        key_servers,
        public_keys,
        threshold,
    });
}

public fun set_service_fee(
    _: &AdminCap,
    auction_table: &mut AuctionTable,
    offer_table: &mut OfferTable,
    service_fee: u64,
) {
    assert!(auction_table.is_valid_auction_version(), EInvalidAuctionTableVersion);
    offer_table.check_offer_table_version();
    assert!(service_fee < max_percentage(), EInvalidServiceFee);

    auction_table.service_fee = service_fee;
    offer_table.set_service_fee(service_fee);

    event::emit(SetServiceFee {
        service_fee,
    });
}

public fun add_allowed_token<T>(
    _: &AdminCap,
    auction_table: &mut AuctionTable,
    offer_table: &mut OfferTable
) {
    assert!(auction_table.is_valid_auction_version(), EInvalidAuctionTableVersion);
    offer_table.check_offer_table_version();

    let token = type_name::with_defining_ids<T>();

    auction_table.allowed_tokens.add(token, true);
    offer_table.add_allowed_token(token);

    event::emit(AddAllowedToken {
        token,
    });
}

public fun remove_allowed_token<T>(
    _: &AdminCap,
    auction_table: &mut AuctionTable,
    offer_table: &mut OfferTable
) {
    assert!(auction_table.is_valid_auction_version(), EInvalidAuctionTableVersion);
    offer_table.check_offer_table_version();

    let token = type_name::with_defining_ids<T>();

    assert!(token != type_name::with_defining_ids<SUI>(), ECannotRemoveSui);

    auction_table.allowed_tokens.remove(token);
    offer_table.remove_allowed_token(token);

    event::emit(RemoveAllowedToken {
        token,
    });
}

/// Withdraw accumulated fees from both auction and offer tables
public fun withdraw_fees<T>(
    _: &AdminCap,
    auction_table: &mut AuctionTable,
    offer_table: &mut OfferTable,
    ctx: &mut TxContext
): Coin<T> {
    assert!(auction_table.is_valid_auction_version(), EInvalidAuctionTableVersion);
    offer_table.check_offer_table_version();

    let token = type_name::with_defining_ids<T>();
    let mut total_balance = balance::zero<T>();

    // Withdraw from auction table if exists
    if (auction_table.fees.contains(token)) {
        let auction_fee_balance = auction_table.fees.remove<TypeName, Balance<T>>(token);
        total_balance.join(auction_fee_balance);
    };

    // Withdraw from offer table if exists
    if (offer_table.fees().contains(token)) {
        let offer_fee_balance = offer_table.fees().remove<TypeName, Balance<T>>(token);
        total_balance.join(offer_fee_balance);
    };

    let amount = total_balance.value();

    event::emit(WithdrawFees {
        token,
        amount,
        recipient: ctx.sender(),
    });

    total_balance.into_coin(ctx)
}

/// Create a new auction for a domain with a specific token required
public fun create_auction<T>(
    auction_table: &mut AuctionTable,
    start_time: u64,
    end_time: u64,
    min_bid: u64,
    encrypted_reserve_price: Option<vector<u8>>,
    suins_registration: SuinsRegistration,
    ctx: &mut TxContext
) {
    assert!(auction_table.is_valid_auction_version(), EInvalidAuctionTableVersion);
    assert!(end_time > start_time, EWrongTime);

    let token = type_name::with_defining_ids<T>();

    assert!(auction_table.allowed_tokens.contains(token), ETokenNotAllowed);

    let domain = suins_registration.domain();
    let domain_name = domain.to_string();

    let mut reserve_price = option::none();
    if (encrypted_reserve_price.is_some()) {
        let mut encrypted_reserve_price_new = copy encrypted_reserve_price;
        let encrypted_reserve_price = parse_encrypted_object(encrypted_reserve_price_new.extract());

        // The same address as the sender needs to encrypt the data
        assert!(encrypted_reserve_price.aad().borrow() == ctx.sender().to_bytes(), EInvalidEncryptionSender);

        // All encrypted data must have been encrypted using the same key servers and the same threshold.
        assert!(encrypted_reserve_price.services() == auction_table.key_servers, EInvalidEncryptionServers);
        assert!(encrypted_reserve_price.threshold() == auction_table.threshold, EInvalidEncryptionThreshold);

        // Check that the encryption was created for this domain name
        assert!(encrypted_reserve_price.id() == get_encryption_id(start_time, domain_name.into_bytes()), EInvalidEncryptionId);
        assert!(encrypted_reserve_price.package_id() == @suins_auction, EInvalidEncryptionPackageId);

        reserve_price = option::some(encrypted_reserve_price);
    };

    let owner = ctx.sender();
    let auction = Auction {
        id: object::new(ctx),
        owner,
        start_time,
        end_time,
        min_bid,
        reserve_price,
        highest_bidder: @0x0,
        highest_bid_balance: balance::zero<T>(),
        suins_registration,
    };
    let auction_id = object::id(&auction);
    auction_table.bag.add(
        domain_name.into_bytes(),
        auction,
    );

    event::emit(AuctionCreatedEvent {
        auction_id,
        domain_name,
        owner,
        start_time,
        end_time,
        min_bid,
        reserve_price: encrypted_reserve_price,
        token,
    });
}

/// Place a bid on an active auction
public fun place_bid<T>(
    auction_table: &mut AuctionTable,
    domain_name: String,
    coin: Coin<T>,
    clock: &Clock,
    ctx: &mut TxContext
) {
    assert!(auction_table.is_valid_auction_version(), EInvalidAuctionTableVersion);
    assert!(auction_table.bag.contains(domain_name.into_bytes()), ENotAuctioned);

    let auction = auction_table.bag.borrow_mut<vector<u8>, Auction<T>>(domain_name.into_bytes());
    let now = clock.timestamp_ms() / 1000;
    assert!(now > auction.start_time, ETooEarly);
    assert!(now < auction.end_time, ETooLate);

    let bid_amount = coin.value();
    let highest_bid_value = auction.highest_bid_balance.value();
    assert!(bid_amount >= auction.min_bid && bid_amount > highest_bid_value, EBidTooLow);

    // If bid in last minutes, extend auction by minutes
    if (auction.end_time - now < bid_extend_time()) {
        auction.end_time = now + bid_extend_time();
    };

    if (highest_bid_value > 0) {
        let prev_balance = auction.highest_bid_balance.withdraw_all();
        transfer::public_transfer(prev_balance.into_coin(ctx), auction.highest_bidder);
    };

    let bidder = ctx.sender();
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
    domain_name: String,
    mut derived_keys: Option<vector<vector<u8>>>, // Needed if auction has reserve price
    mut key_servers: Option<vector<address>>,
    clock: &Clock,
    ctx: &mut TxContext
) {
    assert!(auction_table.is_valid_auction_version(), EInvalidAuctionTableVersion);
    assert!(auction_table.bag.contains(domain_name.into_bytes()), ENotAuctioned);

    let auction = auction_table.bag.remove<_, Auction<T>>(domain_name.into_bytes());
    let auction_id = object::id(&auction);
    let Auction<T> {
        id,
        owner,
        start_time,
        end_time,
        min_bid: _,
        mut reserve_price,
        highest_bidder,
        mut highest_bid_balance,
        suins_registration,
    } = auction;

    let now = clock.timestamp_ms() / 1000;
    assert!(now > end_time, ENotEnded);

    let mut actual_reserve_price = 0;
    if (reserve_price.is_some()) {
        assert!(derived_keys.is_some() && key_servers.is_some(), EEncryptionNoKeys);
        let derived_keys = derived_keys.extract();
        let key_servers = key_servers.extract();

        actual_reserve_price = decrypt_reserve_price(
            auction_table.key_servers,
            auction_table.public_keys,
            auction_table.threshold,
            start_time,
            domain_name.into_bytes(),
            reserve_price.extract(),
            &derived_keys,
            &key_servers
        );
    };

    let mut highest_bid_value = highest_bid_balance.value();

    if (highest_bid_value > 0) {
        // Highest big only wins if higher than the reserve price
        if (highest_bid_value >= actual_reserve_price) {
            // Deduct service fee
            let fee_amount = subtract_fee<T>(&mut auction_table.fees, &mut highest_bid_balance, auction_table.service_fee);

            highest_bid_value = highest_bid_value - fee_amount;

            set_target_address(suins, &suins_registration, option::some(highest_bidder), clock);
            transfer::public_transfer(highest_bid_balance.into_coin(ctx), owner);
            transfer::public_transfer(suins_registration, highest_bidder);
        } else {
            transfer::public_transfer(highest_bid_balance.into_coin(ctx), highest_bidder);
            transfer::public_transfer(suins_registration, owner);
        };
    } else {
        highest_bid_balance.destroy_zero();
        transfer::public_transfer(suins_registration, owner);
    };

    event::emit(AuctionFinalizedEvent {
        auction_id,
        domain_name,
        winner: highest_bidder,
        amount: highest_bid_value,
        reserve_price: actual_reserve_price,
        token: type_name::with_defining_ids<T>(),
    });

    object::delete(id);
}

/// Cancel an auction
public fun cancel_auction<T>(
    auction_table: &mut AuctionTable,
    domain_name: String,
    clock: &Clock,
    ctx: &mut TxContext
): SuinsRegistration {
    assert!(auction_table.is_valid_auction_version(), EInvalidAuctionTableVersion);
    assert!(auction_table.bag.contains(domain_name.into_bytes()), ENotAuctioned);

    let auction = auction_table.bag.remove<_, Auction<T>>(domain_name.into_bytes());
    let auction_id = object::id(&auction);
    let Auction<T> {
        id,
        owner,
        start_time: _,
        end_time,
        min_bid: _,
        reserve_price: _,
        highest_bidder,
        highest_bid_balance,
        suins_registration,
    } = auction;

    let caller = ctx.sender();
    assert!(owner == caller, ENotOwner);

    let now = clock.timestamp_ms() / 1000;
    assert!(now < end_time, EEnded);

    if (highest_bid_balance.value() > 0) {
        transfer::public_transfer(highest_bid_balance.into_coin(ctx), highest_bidder);
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

// Can be used by the owner to get a mutate reference for the SuinsRegistration in case it expires so it can update it directly
public fun get_suins_registration_from_auction<T>(
    auction: &mut Auction<T>,
    ctx: &mut TxContext
): &mut SuinsRegistration {
    let caller = ctx.sender();
    assert!(auction.owner == caller, ENotOwner);

    &mut auction.suins_registration
}

// The id is the domain name auctioned
entry fun seal_approve<T>(id: vector<u8>, auction_table: &AuctionTable, clock: &Clock) {
    check_policy<T>(id, auction_table, clock);
}

// Private functions

// Allow decryption if auction for the domain exists, if reserve price exists and if end time has passed
fun check_policy<T>(id: vector<u8>, auction_table: &AuctionTable, clock: &Clock) {
    assert!(auction_table.is_valid_auction_version(), EInvalidAuctionTableVersion);

    let mut bcs = sui::bcs::new(id);
    let start_time = bcs.peel_u64();
    let domain_name = bcs.into_remainder_bytes();

    assert!(auction_table.bag.contains(domain_name), EEncryptionNoAccess);

    let auction = auction_table.bag.borrow<vector<u8>, Auction<T>>(domain_name);

    assert!(auction.start_time == start_time, EEncryptionNoAccess);
    assert!(auction.reserve_price.is_some(), EEncryptionNoAccess);

    let now = clock.timestamp_ms() / 1000;
    assert!(now > auction.end_time, EEncryptionNoAccess);
}

// Verify version
fun is_valid_auction_version(auction_table: &AuctionTable): bool {
    auction_table.version == version()
}

// Testing functions

#[test_only]
public fun init_for_testing(ctx: &mut TxContext) {
    init(ctx);
}

#[test_only]
public fun get_auction_table_bag(auction_table: &AuctionTable): &ObjectBag {
    &auction_table.bag
}

#[test_only]
public fun get_auction_table_allowed_tokens(auction_table: &AuctionTable): &Table<TypeName, bool> {
    &auction_table.allowed_tokens
}

#[test_only]
public fun get_auction_table_key_servers(auction_table: &AuctionTable): &vector<address> {
    &auction_table.key_servers
}

#[test_only]
public fun get_auction_table_public_keys(auction_table: &AuctionTable): &vector<vector<u8>> {
    &auction_table.public_keys
}

#[test_only]
public fun get_auction_table_threshold(auction_table: &AuctionTable): &u8 {
    &auction_table.threshold
}

#[test_only]
public fun get_auction_table_fees(auction_table: &AuctionTable): &Bag {
    &auction_table.fees
}

#[test_only]
public fun get_auction_table_service_fee(auction_table: &AuctionTable): u64 {
    auction_table.service_fee
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
