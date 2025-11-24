module suins_auction::offer;

use std::{string::String, type_name::{Self, TypeName}};
use sui::{
    bag::{Self, Bag},
    balance::Balance,
    clock::Clock,
    coin::{Self, Coin},
    event,
    table::{Self, Table}
};
use suins::{controller::set_target_address, suins::SuiNS, suins_registration::SuinsRegistration};
use suins_auction::constants::{
    default_fee_percentage,
    error_token_not_allowed,
    max_percentage,
    version as package_version,
};

const EAlreadyOffered: u64 = 8;
const EDomainNotOffered: u64 = 9;
const EAddressNotOffered: u64 = 10;
const ECounterOfferTooLow: u64 = 11;
const EWrongCoinValue: u64 = 12;
const ENoCounterOffer: u64 = 13;
const EInvalidOfferTableVersion: u64 = 17;

/// Table mapping domain to Offers and addresses that have made Offers
public struct OfferTable has key {
    id: UID,
    version: u64,
    table: Table<vector<u8>, Bag>,
    // Bag: address -> Offer<T>
    allowed_tokens: Table<TypeName, bool>,
    service_fee: u64,
    /// Accumulated service fees for each token type
    fees: Bag, // TypeName -> Balance<T>
}

public struct Offer<phantom T> has store {
    balance: Balance<T>,
    counter_offer: u64,
}

/// Event for offer placement
public struct OfferPlacedEvent has copy, drop {
    domain_name: String,
    address: address,
    value: u64,
    token: TypeName,
}

/// Event for offer cancellation
public struct OfferCancelledEvent has copy, drop {
    domain_name: String,
    address: address,
    value: u64,
    token: TypeName,
}

/// Event for offer acceptance
public struct OfferAcceptedEvent has copy, drop {
    domain_name: String,
    owner: address,
    buyer: address,
    value: u64,
    token: TypeName,
}

/// Event for offer declined
public struct OfferDeclinedEvent has copy, drop {
    domain_name: String,
    owner: address,
    buyer: address,
    value: u64,
    token: TypeName,
}

/// Event for make counter offer
public struct MakeCounterOfferEvent has copy, drop {
    domain_name: String,
    owner: address,
    buyer: address,
    value: u64,
    token: TypeName,
}

/// Event for accept counter offer
public struct AcceptCounterOfferEvent has copy, drop {
    domain_name: String,
    buyer: address,
    value: u64,
    token: TypeName,
}

/// Place an offer on a domain
public fun place_offer<T>(
    offer_table: &mut OfferTable,
    domain_name: String,
    coin: Coin<T>,
    ctx: &mut TxContext
)
{
    offer_table.check_offer_table_version();

    let token = type_name::with_defining_ids<T>();

    assert!(offer_table.allowed_tokens.contains(token), error_token_not_allowed());

    let coin_value = coin.value();
    let caller = ctx.sender();
    let offer = Offer {
        balance: coin.into_balance(),
        counter_offer: 0,
    };

    let domain_name_bytes = domain_name.into_bytes();

    if (offer_table.table.contains(domain_name_bytes)) {
        let offers = offer_table.table.borrow_mut(domain_name_bytes);
        assert!(!offers.contains(caller), EAlreadyOffered);
        offers.add(caller, offer);
    } else {
        let mut offers = bag::new(ctx);
        offers.add(caller, offer);
        offer_table.table.add(domain_name_bytes, offers);
    };

    event::emit(OfferPlacedEvent {
        domain_name,
        address: ctx.sender(),
        value: coin_value,
        token,
    });
}

/// Cancel an offer on a domain
public fun cancel_offer<T>(
    offer_table: &mut OfferTable,
    domain_name: String,
    ctx: &mut TxContext
): Coin<T>
{
    offer_table.check_offer_table_version();

    let caller = ctx.sender();

    let Offer {
        balance,
        counter_offer: _,
    } = offer_remove<T>(offer_table, domain_name, caller);

    event::emit(OfferCancelledEvent {
        domain_name,
        address: caller,
        value: balance.value(),
        token: type_name::with_defining_ids<T>(),
    });

    balance.into_coin(ctx)
}

/// Accept an offer
public fun accept_offer<T>(
    suins: &mut SuiNS,
    offer_table: &mut OfferTable,
    suins_registration: SuinsRegistration,
    address: address,
    clock: &Clock,
    ctx: &mut TxContext
): Coin<T>
{
    offer_table.check_offer_table_version();

    let domain = suins_registration.domain();
    let domain_name = domain.to_string();
    let Offer {
        mut balance,
        counter_offer: _,
    } = offer_remove<T>(offer_table, domain_name, address);

    // Deduct service fee
    let balance_value = balance.value();
    subtract_fee<T>(&mut offer_table.fees, &mut balance, offer_table.service_fee);

    set_target_address(suins, &suins_registration, option::some(address), clock);
    transfer::public_transfer(suins_registration, address);

    event::emit(OfferAcceptedEvent {
        domain_name,
        owner: ctx.sender(),
        buyer: address,
        value: balance_value,
        token: type_name::with_defining_ids<T>(),
    });

    balance.into_coin(ctx)
}

/// Decline an offer
public fun decline_offer<T>(
    offer_table: &mut OfferTable,
    suins_registration: &SuinsRegistration,
    address: address,
    ctx: &mut TxContext
)
{
    offer_table.check_offer_table_version();

    let domain = suins_registration.domain();
    let domain_name = domain.to_string();
    let Offer {
        balance,
        counter_offer: _,
    } = offer_remove<T>(offer_table, domain_name, address);

    let value = balance.value<T>();
    transfer::public_transfer(balance.into_coin(ctx), address);

    event::emit(OfferDeclinedEvent {
        domain_name,
        owner: ctx.sender(),
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
    offer_table.check_offer_table_version();

    let domain = suins_registration.domain();
    let domain_name = domain.to_string();
    let offer = offer_borrow_mut<T>(offer_table, domain_name, address);
    assert!(counter_offer_value > offer.balance.value(), ECounterOfferTooLow);
    offer.counter_offer = counter_offer_value;

    event::emit(MakeCounterOfferEvent {
        domain_name,
        owner: ctx.sender(),
        buyer: address,
        value: counter_offer_value,
        token: type_name::with_defining_ids<T>(),
    });
}

/// Accept a counter offer
public fun accept_counter_offer<T>(
    offer_table: &mut OfferTable,
    domain_name: String,
    coin: Coin<T>,
    ctx: &mut TxContext
)
{
    offer_table.check_offer_table_version();

    let caller = ctx.sender();

    let offer = offer_borrow_mut<T>(offer_table, domain_name, caller);
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

// Public package function

public(package) fun create(ctx: &mut TxContext): OfferTable {
    OfferTable {
        id: object::new(ctx),
        version: package_version(),
        table: table::new(ctx),
        allowed_tokens: table::new<TypeName, bool>(ctx),
        service_fee: default_fee_percentage(),
        fees: bag::new(ctx),
    }
}

public(package) fun share(offer_table: OfferTable) {
    transfer::share_object(offer_table);
}

// Subtract service fee from balance and store it in the fees bag
public(package) fun subtract_fee<T>(fees: &mut Bag, balance: &mut Balance<T>, service_fee: u64): u64 {
    let balance_value = balance.value();
    let fee_amount = (balance_value * service_fee) / max_percentage();

    if (fee_amount > 0) {
        let fee_balance = balance.split(fee_amount);
        let token = type_name::with_defining_ids<T>();

        if (fees.contains(token)) {
            let existing_fee = fees.borrow_mut<TypeName, Balance<T>>(token);
            existing_fee.join(fee_balance);
        } else {
            fees.add(token, fee_balance);
        };
    };

    fee_amount
}

public(package) fun check_offer_table_version(offer_table: &OfferTable) {
    assert!(offer_table.version == package_version(), EInvalidOfferTableVersion);
}

public(package) fun version(offer_table: &OfferTable): u64 {
    offer_table.version
}

public(package) fun fees(offer_table: &mut OfferTable): &mut Bag {
    &mut offer_table.fees
}

public(package) fun set_version(offer_table: &mut OfferTable, new_version: u64) {
    offer_table.version = new_version;
}

public(package) fun set_service_fee(offer_table: &mut OfferTable, new_service_fee: u64) {
    offer_table.service_fee = new_service_fee;
}

public(package) fun add_allowed_token(offer_table: &mut OfferTable, token: TypeName) {
    offer_table.allowed_tokens.add(token, true);
}

public(package) fun remove_allowed_token(offer_table: &mut OfferTable, token: TypeName) {
    offer_table.allowed_tokens.remove(token);
}

// Private functions

// Get mutable reference to offer from storage
fun offer_borrow_mut<T>(
    offer_table: &mut OfferTable,
    domain_name: String,
    address: address,
): &mut Offer<T> {
    let offers = domain_offers_borrow_mut(offer_table, domain_name.into_bytes(), address);

    offers.borrow_mut(address)
}

// Remove offer from storage
fun offer_remove<T>(
    offer_table: &mut OfferTable,
    domain_name: String,
    address: address,
): Offer<T> {
    let offers = domain_offers_borrow_mut(offer_table, domain_name.into_bytes(), address);
    let offer = offers.remove<address, Offer<T>>(address);

    if (offers.length() == 0) {
        let empty_table = offer_table.table.remove(domain_name.into_bytes());
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

#[test_only]
public fun get_offer_table(offer_table: &OfferTable): &Table<vector<u8>, Bag> {
    &offer_table.table
}

#[test_only]
public fun get_offer_table_fees(offer_table: &OfferTable): &Bag {
    &offer_table.fees
}

#[test_only]
public fun get_offer_table_service_fee(offer_table: &OfferTable): u64 {
    offer_table.service_fee
}

#[test_only]
public fun get_offer_balance<T>(offer: &Offer<T>): &Balance<T> {
    &offer.balance
}

#[test_only]
public fun get_offer_counter_offer<T>(offer: &Offer<T>): u64 {
    offer.counter_offer
}
