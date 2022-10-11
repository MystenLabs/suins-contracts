module suins::sui_controller {

    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin};
    use sui::ecdsa::keccak256;
    use sui::event;
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::sui::SUI;
    use sui::vec_map::{Self, VecMap};
    use suins::base_registry::{Registry, AdminCap};
    use suins::sui_registrar::{Self, SuiRegistrar};
    use std::string::{Self, String};
    use std::bcs;
    use std::vector;
    use sui::url;

    // TODO: remove later when timestamp is introduced
    // const MIN_COMMITMENT_AGE: u64 = 0;
    const MAX_COMMITMENT_AGE: u64 = 3;
    const REGISTRATION_FEE_PER_YEAR: u64 = 888;
    const BASE_NODE: vector<u8> = b"sui";

    // errors in the range of 301..400 indicate Sui Controller errors
    const EInvalidResolverAddress: u64 = 301;
    const ECommitmentNotExists: u64 = 302;
    const ECommitmentNotValid: u64 = 303;
    const ECommitmentTooOld: u64 = 304;
    const ENotEnoughFee: u64 = 305;
    const EInvalidDuration: u64 = 306;
    const EInvalidAddr: u64 = 307;
    const ELabelUnAvailable: u64 = 308;
    const EUnauthorized: u64 = 309;
    const ENoProfits: u64 = 310;
    const EInvalidLabel: u64 = 311;

    struct NameRegisteredEvent has copy, drop {
        node: String,
        label: String,
        owner: address,
        cost: u64,
        expiry: u64,
    }

    struct NameRenewedEvent has copy, drop {
        node: String,
        label: String,
        cost: u64,
        expiry: u64,
    }

    struct SuiController has key {
        id: UID,
        commitments: VecMap<vector<u8>, u64>,
        balance: Balance<SUI>,
    }

    fun init(ctx: &mut TxContext) {
        transfer::share_object(SuiController {
            id: object::new(ctx),
            commitments: vec_map::empty(),
            balance: balance::zero(),
        });
    }

    public fun valid(name: String): bool {
        string::length(&name) > 6
    }

    public fun available(registrar: &SuiRegistrar, label: String, ctx: &TxContext): bool {
        valid(label) && sui_registrar::available(registrar, label, ctx)
    }

    public entry fun renew(
        controller: &mut SuiController,
        registrar: &mut SuiRegistrar,
        label: vector<u8>,
        duration: u64,
        payment: &mut Coin<SUI>,
        ctx: &mut TxContext,
    ) {
        let no_year = duration / 365;
        if ((duration % 365) > 0) no_year = no_year + 1;
        let renew_fee = REGISTRATION_FEE_PER_YEAR * no_year;
        assert!(coin::value(payment) >= renew_fee, ENotEnoughFee);

        sui_registrar::renew(registrar, label, duration, ctx);

        let coin_balance = coin::balance_mut(payment);
        let paid = balance::split(coin_balance, renew_fee);
        balance::join(&mut controller.balance, paid);

        event::emit(NameRenewedEvent {
            node: string::utf8(BASE_NODE),
            label: string::utf8(label),
            cost: renew_fee,
            expiry: duration,
        })
    }

    public entry fun withdraw(_: &AdminCap, controller: &mut SuiController, ctx: &mut TxContext) {
        let amount = balance::value(&controller.balance);
        assert!(amount > 0, ENoProfits);

        let coin = coin::take(&mut controller.balance, amount, ctx);
        transfer::transfer(coin, tx_context::sender(ctx));
    }

    public entry fun make_commitment_and_commit(
        controller: &mut SuiController,
        commitment: vector<u8>,
        ctx: &mut TxContext,
    ) {
        vec_map::insert(&mut controller.commitments, commitment, tx_context::epoch(ctx));
    }

    public entry fun register(
        controller: &mut SuiController,
        registrar: &mut SuiRegistrar,
        registry: &mut Registry,
        label: vector<u8>,
        owner: address,
        duration: u64,
        secret: vector<u8>,
        url: vector<u8>,
        payment: &mut Coin<SUI>,
        ctx: &mut TxContext,
    ) {
        // TODO: duration in year only
        register_with_config(
            controller,
            registrar,
            registry,
            label,
            owner,
            duration,
            secret,
            @0x0,
            @0x0,
            url,
            payment,
            ctx
        );
    }

    // anyone can register a domain at any level
    public entry fun register_with_config(
        controller: &mut SuiController,
        registrar: &mut SuiRegistrar,
        registry: &mut Registry,
        label: vector<u8>,
        owner: address,
        duration: u64,
        secret: vector<u8>,
        resolver: address,
        addr: address,
        url: vector<u8>,
        payment: &mut Coin<SUI>,
        ctx: &mut TxContext,
    ) {
        if (!is_label_valid(string::utf8(label))) abort EInvalidLabel;

        let no_year = duration / 365;
        if ((duration % 365) > 0) no_year = no_year + 1;
        let registration_fee = REGISTRATION_FEE_PER_YEAR * no_year;
        assert!(coin::value(payment) >= registration_fee, ENotEnoughFee);

        let commitment = make_commitment(label, owner, secret);
        consume_commitment(controller, registrar, label, commitment, ctx);

        if (resolver != @0x0) {
            sui_registrar::register(registrar, registry, label, owner, duration, resolver, url::new_unsafe_from_bytes(url), ctx);
            // TODO: configure resolver
        } else {
            assert!(addr == @0x0, EInvalidAddr);
            sui_registrar::register(registrar, registry, label, owner, duration, resolver, url::new_unsafe_from_bytes(url), ctx);
        };
        event::emit(NameRegisteredEvent {
            node: string::utf8(BASE_NODE),
            label: string::utf8(label),
            owner,
            cost: registration_fee,
            expiry: tx_context::epoch(ctx) + duration,
        });
        let coin_balance = coin::balance_mut(payment);
        let paid = balance::split(coin_balance, registration_fee);
        balance::join(&mut controller.balance, paid);
    }

    fun consume_commitment(
        controller: &mut SuiController,
        registrar: &SuiRegistrar,
        label: vector<u8>,
        commitment: vector<u8>,
        ctx: &TxContext,
    ) {
        assert!(vec_map::contains(&controller.commitments, &commitment), ECommitmentNotExists);
        // TODO: remove later when timestamp is introduced
        // assert!(
        //     *vec_map::get(&controller.commitments, &commitment) + MIN_COMMITMENT_AGE <= tx_context::epoch(ctx),
        //     ECommitmentNotValid
        // );
        assert!(
            *vec_map::get(&controller.commitments, &commitment) + MAX_COMMITMENT_AGE > tx_context::epoch(ctx),
            ECommitmentTooOld
        );
        assert!(available(registrar, string::utf8(label), ctx), ELabelUnAvailable);
        vec_map::remove(&mut controller.commitments, &commitment);
    }

    fun is_label_valid(label: String): bool {
        // valid label cannot contain '.'
        // TODO: check for UTF8 characters that look the same as '.'
        string::index_of(&label, &string::utf8(b".")) == string::length(&label)
    }

    fun make_commitment(label: vector<u8>, owner: address, secret: vector<u8>): vector<u8> {
        let owner_bytes = bcs::to_bytes(&owner);
        vector::append(&mut label, owner_bytes);
        vector::append(&mut label, secret);
        keccak256(&label)
    }

    #[test_only]
    public fun test_make_commitment(label: vector<u8>, owner: address, secret: vector<u8>): vector<u8> {
        make_commitment(label, owner, secret)
    }

    #[test_only]
    public fun balance(controller: &SuiController): u64 {
        balance::value(&controller.balance)
    }

    #[test_only]
    public fun commitment_len(controller: &SuiController): u64 {
        vec_map::size(&controller.commitments)
    }
    #[test_only]
    /// Wrapper of module initializer for testing
    public fun test_init(ctx: &mut TxContext) { init(ctx) }
}
