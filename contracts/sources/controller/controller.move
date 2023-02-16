module suins::controller {

    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin};
    use sui::hash::keccak256;
    use sui::event;
    use sui::linked_table::{Self, LinkedTable};
    use sui::object::{Self, UID, ID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::sui::SUI;
    use suins::base_registry::{Registry, AdminCap};
    use suins::base_registrar::{Self, BaseRegistrar};
    use suins::configuration::{Self, Configuration};
    use std::string::{Self, String};
    use std::bcs;
    use std::vector;
    use std::option::{Self, Option};
    use std::ascii;
    use suins::emoji::validate_label_with_emoji;

    // TODO: remove later when timestamp is introduced
    // const MIN_COMMITMENT_AGE: u64 = 0;
    const MAX_COMMITMENT_AGE: u64 = 3;
    const FEE_PER_YEAR: u64 = 1000000;
    const NO_OUTDATED_COMMITMENT_TO_REMOVE: u64 = 50;

    // errors in the range of 301..400 indicate Sui Controller errors
    const EInvalidResolverAddress: u64 = 301;
    const ECommitmentNotExists: u64 = 302;
    const ECommitmentNotValid: u64 = 303;
    const ECommitmentTooOld: u64 = 304;
    const ENotEnoughFee: u64 = 305;
    const EInvalidDuration: u64 = 306;
    const ELabelUnAvailable: u64 = 308;
    const ENoProfits: u64 = 310;
    const EInvalidCode: u64 = 311;

    struct NameRegisteredEvent has copy, drop {
        node: String,
        label: String,
        owner: address,
        cost: u64,
        expiry: u64,
        nft_id: ID,
        resolver: address,
        referral_code: Option<ascii::String>,
        discount_code: Option<ascii::String>,
    }

    struct DefaultResolverChangedEvent has copy, drop {
        resolver: address,
    }

    struct NameRenewedEvent has copy, drop {
        node: String,
        label: String,
        cost: u64,
        duration: u64,
    }

    struct BaseController has key {
        id: UID,
        commitments: LinkedTable<vector<u8>, u64>,
        balance: Balance<SUI>,
        default_addr_resolver: address,
    }

    fun init(ctx: &mut TxContext) {
        transfer::share_object(BaseController {
            id: object::new(ctx),
            commitments: linked_table::new(ctx),
            balance: balance::zero(),
            // cannot get the ID of name_resolver in `init`, admin need to update this by calling `set_default_resolver`
            default_addr_resolver: @0x0,
        });
    }

    public entry fun set_default_resolver(_: &AdminCap, controller: &mut BaseController, resolver: address) {
        controller.default_addr_resolver = resolver;
        event::emit(DefaultResolverChangedEvent { resolver })
    }

    public entry fun renew(
        controller: &mut BaseController,
        registrar: &mut BaseRegistrar,
        label: vector<u8>,
        no_years: u64,
        payment: &mut Coin<SUI>,
        ctx: &mut TxContext,
    ) {
        let renew_fee = FEE_PER_YEAR * no_years;
        assert!(coin::value(payment) >= renew_fee, ENotEnoughFee);
        let duration = no_years * 365;
        base_registrar::renew(registrar, label, duration, ctx);

        let coin_balance = coin::balance_mut(payment);
        let paid = balance::split(coin_balance, renew_fee);
        balance::join(&mut controller.balance, paid);

        event::emit(NameRenewedEvent {
            node: base_registrar::get_base_node(registrar),
            label: string::utf8(label),
            cost: renew_fee,
            duration,
        })
    }

    public entry fun withdraw(_: &AdminCap, controller: &mut BaseController, ctx: &mut TxContext) {
        let amount = balance::value(&controller.balance);
        assert!(amount > 0, ENoProfits);

        let coin = coin::take(&mut controller.balance, amount, ctx);
        transfer::transfer(coin, tx_context::sender(ctx));
    }

    public entry fun commit(
        controller: &mut BaseController,
        commitment: vector<u8>,
        ctx: &mut TxContext,
    ) {
        remove_outdated_commitment(controller, ctx);
        linked_table::push_back(&mut controller.commitments, commitment, tx_context::epoch(ctx));
    }

    // duration in years
    public entry fun register(
        controller: &mut BaseController,
        registrar: &mut BaseRegistrar,
        registry: &mut Registry,
        config: &mut Configuration,
        label: vector<u8>,
        owner: address,
        no_years: u64,
        secret: vector<u8>,
        payment: &mut Coin<SUI>,
        ctx: &mut TxContext,
    ) {
        let resolver = controller.default_addr_resolver;
        // TODO: duration in year only, currently in number of days
        register_internal(
            controller, registrar, registry, config, label, owner,
            no_years, secret, resolver, payment,
            option::none(), option::none(), ctx,
        );
    }

    // duration in years
    public entry fun register_with_code(
        controller: &mut BaseController,
        registrar: &mut BaseRegistrar,
        registry: &mut Registry,
        config: &mut Configuration,
        label: vector<u8>,
        owner: address,
        no_years: u64,
        secret: vector<u8>,
        payment: &mut Coin<SUI>,
        referral_code: vector<u8>,
        discount_code: vector<u8>,
        ctx: &mut TxContext,
    ) {
        let referral_len = vector::length(&referral_code);
        let discount_len = vector::length(&discount_code);
        assert!(referral_len > 0 || discount_len > 0, EInvalidCode);

        let referral = option::none();
        let discount = option::none();
        if (referral_len > 0) referral = option::some(ascii::string(referral_code));
        if (discount_len > 0) discount = option::some(ascii::string(discount_code));
        let resolver = controller.default_addr_resolver;
        register_internal(
            controller, registrar, registry, config, label,
            owner, no_years, secret, resolver,
            payment, referral, discount, ctx,
        );
    }

    // anyone can register a domain at any level
    // duration in years
    /**
     * @param {Code} resolver - address of custom resolver
     */
    public entry fun register_with_config(
        controller: &mut BaseController,
        registrar: &mut BaseRegistrar,
        registry: &mut Registry,
        config: &mut Configuration,
        label: vector<u8>,
        owner: address,
        no_years: u64,
        secret: vector<u8>,
        resolver: address,
        payment: &mut Coin<SUI>,
        ctx: &mut TxContext,
    ) {
        register_internal(
            controller, registrar, registry, config, label,
            owner, no_years, secret, resolver,
            payment, option::none(), option::none(), ctx
        );
    }

    // anyone can register a domain at any level
    // duration in years
    public entry fun register_with_config_and_code(
        controller: &mut BaseController,
        registrar: &mut BaseRegistrar,
        registry: &mut Registry,
        config: &mut Configuration,
        label: vector<u8>,
        owner: address,
        no_years: u64,
        secret: vector<u8>,
        resolver: address,
        payment: &mut Coin<SUI>,
        referral_code: vector<u8>,
        discount_code: vector<u8>,
        ctx: &mut TxContext,
    ) {
        let referral_len = vector::length(&referral_code);
        let discount_len = vector::length(&discount_code);
        assert!(referral_len > 0 || discount_len > 0, EInvalidCode);

        let referral = option::none();
        let discount = option::none();
        if (referral_len > 0) referral = option::some(ascii::string(referral_code));
        if (discount_len > 0) discount = option::some(ascii::string(discount_code));

        register_internal(
            controller, registrar, registry, config,
            label, owner, no_years, secret, resolver,
            payment, referral, discount, ctx,
        );
    }

    // returns remaining_fee
    fun apply_referral_code(
        config: &Configuration,
        payment: &mut Coin<SUI>,
        original_fee: u64,
        referral_code: &ascii::String,
        ctx: &mut TxContext
    ): u64 {
        let (rate, partner) = configuration::use_referral_code(config, referral_code);
        let remaining_fee = (original_fee / 100)  * (100 - rate as u64);
        let payback = original_fee - remaining_fee;
        let coin = coin::split(payment, payback, ctx);
        transfer::transfer(coin, partner);

        remaining_fee
    }

    // returns remaining_fee and discout owner address
    fun apply_discount_code(
        config: &mut Configuration,
        original_fee: u64,
        referral_code: &ascii::String,
        ctx: &mut TxContext,
    ): u64 {
        let rate = configuration::use_discount_code(config, referral_code, ctx);
        (original_fee / 100)  * (100 - rate as u64)
    }

    fun register_internal(
        controller: &mut BaseController,
        registrar: &mut BaseRegistrar,
        registry: &mut Registry,
        config: &mut Configuration,
        label: vector<u8>,
        owner: address,
        no_years: u64,
        secret: vector<u8>,
        resolver: address,
        payment: &mut Coin<SUI>,
        referral_code: Option<ascii::String>,
        discount_code: Option<ascii::String>,
        ctx: &mut TxContext,
    ) {
        let emoji_config = configuration::get_emoji_config(config);
        validate_label_with_emoji(emoji_config, label);

        let registration_fee = FEE_PER_YEAR * no_years;
        assert!(coin::value(payment) >= registration_fee, ENotEnoughFee);

        // can apply both discount and referral codes at the same time
        if (option::is_some(&discount_code)) {
            registration_fee =
                apply_discount_code(config, registration_fee, option::borrow(&discount_code), ctx);
        };
        if (option::is_some(&referral_code)) {
            registration_fee =
                apply_referral_code(config, payment, registration_fee, option::borrow(&referral_code), ctx);
        };
        let commitment = make_commitment(registrar, label, owner, secret);
        consume_commitment(controller, registrar, label, commitment, ctx);

        let duration = no_years * 365;
        let nft_id = base_registrar::register(registrar, registry, config, label, owner, duration, resolver, ctx);
        let coin_balance = coin::balance_mut(payment);
        let paid = balance::split(coin_balance, registration_fee);
        balance::join(&mut controller.balance, paid);

        event::emit(NameRegisteredEvent {
            node: base_registrar::get_base_node(registrar),
            label: string::utf8(label),
            owner,
            cost: FEE_PER_YEAR * no_years,
            expiry: tx_context::epoch(ctx) + duration,
            nft_id,
            resolver,
            referral_code,
            discount_code,
        });
    }

    fun remove_outdated_commitment(controller: &mut BaseController, ctx: &mut TxContext) {
        let front_element = linked_table::front(&controller.commitments);
        let i = 0;

        while (option::is_some(front_element) && i < NO_OUTDATED_COMMITMENT_TO_REMOVE) {
            i = i + 1;

            let created_at = linked_table::borrow(&controller.commitments, *option::borrow(front_element));
            if (*created_at + MAX_COMMITMENT_AGE <= tx_context::epoch(ctx)) {
                linked_table::pop_front(&mut controller.commitments);
                front_element = linked_table::front(&controller.commitments);
            } else break;
        };
    }

    fun consume_commitment(
        controller: &mut BaseController,
        registrar: &BaseRegistrar,
        label: vector<u8>,
        commitment: vector<u8>,
        ctx: &TxContext,
    ) {
        assert!(linked_table::contains(&controller.commitments, commitment), ECommitmentNotExists);
        // TODO: remove later when timestamp is introduced
        // assert!(
        //     *vec_map::get(&controller.commitments, &commitment) + MIN_COMMITMENT_AGE <= tx_context::epoch(ctx),
        //     ECommitmentNotValid
        // );
        assert!(
            *linked_table::borrow(&controller.commitments, commitment) + MAX_COMMITMENT_AGE > tx_context::epoch(ctx),
            ECommitmentTooOld
        );
        assert!(base_registrar::available(registrar, string::utf8(label), ctx), ELabelUnAvailable);
        linked_table::remove(&mut controller.commitments, commitment);
    }

    fun make_commitment(registrar: &BaseRegistrar, label: vector<u8>, owner: address, secret: vector<u8>): vector<u8> {
        let node = label;
        vector::append(&mut node, b".");
        vector::append(&mut node, base_registrar::get_base_node_bytes(registrar));

        let owner_bytes = bcs::to_bytes(&owner);
        vector::append(&mut node, owner_bytes);
        vector::append(&mut node, secret);
        keccak256(&node)
    }

    #[test_only]
    public fun test_make_commitment(registrar: &BaseRegistrar, label: vector<u8>, owner: address, secret: vector<u8>): vector<u8> {
        make_commitment(registrar, label, owner, secret)
    }

    #[test_only]
    public fun balance(controller: &BaseController): u64 {
        balance::value(&controller.balance)
    }

    #[test_only]
    public fun commitment_len(controller: &BaseController): u64 {
        linked_table::length(&controller.commitments)
    }

    #[test_only]
    public fun get_default_resolver(controller: &BaseController): address {
        controller.default_addr_resolver
    }

    #[test_only]
    public fun apply_referral_code_test(
        config: &Configuration,
        payment: &mut Coin<SUI>,
        original_fee: u64,
        referral_code: vector<u8>,
        ctx: &mut TxContext
    ): u64 {
        apply_referral_code(config, payment, original_fee, &ascii::string(referral_code), ctx)
    }

    #[test_only]
    /// Wrapper of module initializer for testing
    public fun test_init(ctx: &mut TxContext) {
        transfer::share_object(BaseController {
            id: object::new(ctx),
            commitments: linked_table::new(ctx),
            balance: balance::zero(),
            // cannot get the ID of name_resolver in `init`, admin need to update this by calling `set_default_resolver`
            default_addr_resolver: @0x0,
        });
    }
}
