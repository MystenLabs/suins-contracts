/// Its job is to charge payment, add validation and apply referral and discount code
/// when registering and extend experation of domanin names.
/// The real logic of mint a NFT and store the record in blockchain is done in Registrar and Registry contract.
/// Domain name registration can only occur using the Controller and Auction contracts.
/// During auction period, only domains with 7 to 63 characters can be registered via the Controller,
/// but after the auction has ended, all domains can be registered.
module suins::controller {

    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin};
    use sui::ecdsa_k1::keccak256;
    use sui::event;
    use sui::object::{Self, UID, ID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::sui::SUI;
    use sui::vec_map::{Self, VecMap};
    use suins::base_registry::{Registry, AdminCap};
    use suins::base_registrar::{Self, BaseRegistrar};
    use suins::configuration::{Self, Configuration};
    use suins::emoji::validate_label_with_emoji;
    use suins::coin_util;
    use suins::auction::{Self, Auction};
    use std::string::{Self, String, utf8};
    use std::ascii;
    use std::bcs;
    use std::vector;
    use std::option::{Self, Option};

    // TODO: remove later when timestamp is introduced
    // const MIN_COMMITMENT_AGE: u64 = 0;
    const MAX_COMMITMENT_AGE: u64 = 3;
    const FEE_PER_YEAR: u64 = 1000000;

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
    const ERegistrationIsDisabled: u64 = 312;

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
        commitments: VecMap<vector<u8>, u64>,
        balance: Balance<SUI>,
        default_addr_resolver: address,
        /// To turn off registration
        disable: bool,

    }

    /// #### Notice
    /// The admin uses this function to set default resolver address,
    /// which is the default value when registering without config.
    ///
    /// #### Dev
    /// The `default_addr_resolver` property of Controller share object is updated.
    ///
    /// #### Params
    /// `resolver`: address of new default resolver.
    public entry fun set_default_resolver(_: &AdminCap, controller: &mut BaseController, resolver: address) {
        controller.default_addr_resolver = resolver;
        event::emit(DefaultResolverChangedEvent { resolver })
    }

    /// #### Notice
    /// This function is the first step in the commit/reveal process, which is implemented to prevent front-running.
    ///
    /// #### Dev
    /// This also removes outdated commentments.
    ///
    /// #### Params
    /// `commitment`: hash from `make_commitment`
    public entry fun commit(
        controller: &mut BaseController,
        commitment: vector<u8>,
        ctx: &mut TxContext,
    ) {
        remove_outdated_commitments(controller, ctx);
        vec_map::insert(&mut controller.commitments, commitment, tx_context::epoch(ctx));
    }

    /// #### Notice
    /// This function is the second step in the commit/reveal process, which is implemented to prevent front-running.
    /// It acts as a gatekeeper for the `Registrar::Controller`, responsible for node validation and charging payment.
    ///
    /// #### Dev
    /// This function uses default resolver address.
    ///
    /// #### Params
    /// `label`: label of the node being registered, the node has the form `label`.sui
    /// `owner`: owner address of created NFT
    /// `no_years`: in years
    /// `secret`: the value used to create commitment in the first step
    ///
    /// Panic
    /// Panic if new registration is disabled
    /// or `label` contains characters that are not allowed
    /// or `label is waiting to be finalized in auction
    /// or label length isn't outside of the permitted range
    /// or `payment` doesn't have enough coins
    /// or either `referral_code` or `discount_code` is invalid
    public entry fun register(
        controller: &mut BaseController,
        registrar: &mut BaseRegistrar,
        registry: &mut Registry,
        config: &mut Configuration,
        auction: &Auction,
        label: vector<u8>,
        owner: address,
        no_years: u64,
        secret: vector<u8>,
        payment: &mut Coin<SUI>,
        ctx: &mut TxContext,
    ) {
        let resolver = controller.default_addr_resolver;
        register_internal(
            controller,
            registrar,
            registry,
            config,
            auction,
            label,
            owner,
            no_years,
            secret,
            resolver,
            payment,
            option::none(),
            option::none(),
            ctx,
        );
    }

    /// #### Notice
    /// Similar to the `register` function, with an added `resolver` parameter.
    ///
    /// #### Dev
    /// Use `resolver` parameter for resolver address.
    ///
    /// #### Params
    /// `resolver`: address of the resolver
    public entry fun register_with_config(
        controller: &mut BaseController,
        registrar: &mut BaseRegistrar,
        registry: &mut Registry,
        config: &mut Configuration,
        auction: &Auction,
        label: vector<u8>,
        owner: address,
        no_years: u64,
        secret: vector<u8>,
        resolver: address,
        payment: &mut Coin<SUI>,
        ctx: &mut TxContext,
    ) {
        register_internal(
            controller,
            registrar,
            registry,
            config,
            auction,
            label,
            owner,
            no_years,
            secret,
            resolver,
            payment,
            option::none(),
            option::none(),
            ctx
        );
    }

    /// #### Notice
    /// Similar to the `register` function, with added `referral_code` and `discount_code` parameters.
    /// Can use one or two codes at the same time.
    /// `discount_code` is applied first before `referral_code` if use both.
    ///
    /// #### Dev
    /// Use empty string for unused code, however, at least one code must be used.
    /// Remove `discount_code` after this function returns.
    ///
    /// #### Params
    /// `referral_code`: referral code to be used
    /// `discount_code`: discount code to be used
    public entry fun register_with_code(
        controller: &mut BaseController,
        registrar: &mut BaseRegistrar,
        registry: &mut Registry,
        config: &mut Configuration,
        auction: &Auction,
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
        // doesn't have a format for codes right now, so any non-empty code is considered valid
        assert!(referral_len > 0 || discount_len > 0, EInvalidCode);

        let referral = option::none();
        let discount = option::none();
        if (referral_len > 0) referral = option::some(ascii::string(referral_code));
        if (discount_len > 0) discount = option::some(ascii::string(discount_code));

        let resolver = controller.default_addr_resolver;
        register_internal(
            controller,
            registrar,
            registry,
            config,
            auction,
            label,
            owner,
            no_years,
            secret,
            resolver,
            payment,
            referral,
            discount,
            ctx,
        );
    }

    /// #### Notice
    /// Similar to the `register_with_config` function, with added `referral_code` and `discount_code` parameters.
    /// Can use one or two codes at the same time.
    /// `discount_code` is applied first before `referral_code` if use both.
    ///
    /// #### Dev
    /// Use empty string for unused code, however, at least one code must be used.
    /// Remove `discount_code` after this function returns.
    ///
    /// #### Params
    /// `referral_code`: referral code to be used
    /// `discount_code`: discount code to be used
    public entry fun register_with_config_and_code(
        controller: &mut BaseController,
        registrar: &mut BaseRegistrar,
        registry: &mut Registry,
        config: &mut Configuration,
        auction: &Auction,
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
        // TODO: duplicate with `register_with_code`, consider moving this block to a separate function
        let referral_len = vector::length(&referral_code);
        let discount_len = vector::length(&discount_code);
        assert!(referral_len > 0 || discount_len > 0, EInvalidCode);

        let referral = option::none();
        let discount = option::none();
        if (referral_len > 0) referral = option::some(ascii::string(referral_code));
        if (discount_len > 0) discount = option::some(ascii::string(discount_code));

        register_internal(
            controller,
            registrar,
            registry,
            config,
            auction,
            label,
            owner,
            no_years,
            secret,
            resolver,
            payment,
            referral,
            discount,
            ctx,
        );
    }

    /// #### Notice
    /// Anyone can use this function to extend expiration of a node. The TLD comes from BaseRegistrar::tld.
    /// It acts as a gatekeeper for the `Registrar::Renew`, responsible for charging payment.
    ///
    /// #### Params
    /// `label`: label of the node being registered, the node has the form `label`.sui
    /// `no_years`: in years
    ///
    /// Panic
    /// Panic if node doesn't exist
    /// or `payment` doesn't have enough coins
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
        coin_util::user_transfer_to_contract(payment, renew_fee, &mut controller.balance);

        let duration = no_years * 365;
        base_registrar::renew(registrar, label, duration, ctx);

        event::emit(NameRenewedEvent {
            node: base_registrar::get_base_node(registrar),
            label: string::utf8(label),
            cost: renew_fee,
            duration,
        })
    }

    /// #### Notice
    /// Admin use this function to withdraw the payment.
    ///
    /// Panics
    /// Panics if no profits has been created.
    public entry fun withdraw(_: &AdminCap, controller: &mut BaseController, ctx: &mut TxContext) {
        let amount = balance::value(&controller.balance);
        assert!(amount > 0, ENoProfits);

        coin_util::contract_transfer_to_address(&mut controller.balance, amount, tx_context::sender(ctx), ctx);
    }

    // === Private Functions ===

    fun init(ctx: &mut TxContext) {
        transfer::share_object(BaseController {
            id: object::new(ctx),
            commitments: vec_map::empty(),
            balance: balance::zero(),
            // cannot get the ID of name_resolver in `init`, admin need to update this by calling `set_default_resolver`
            default_addr_resolver: @0x0,
            disable: false,
        });
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
        let payback_amount = original_fee - remaining_fee;
        coin_util::user_transfer_to_address(payment, payback_amount, partner, ctx);

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
        auction: &Auction,
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
        assert!(!controller.disable, ERegistrationIsDisabled);
        let emoji_config = configuration::get_emoji_config(config);
        let label_str = utf8(label);

        if (tx_context::epoch(ctx) <= auction::auction_close_at(auction)) {
            validate_label_with_emoji(emoji_config, label, 7, 63)
        } else {
            assert!(auction::is_auction_label_available_for_controller(auction, label_str, ctx), ELabelUnAvailable);
            validate_label_with_emoji(emoji_config, label, 3, 63)
        };
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
        coin_util::user_transfer_to_contract(payment, registration_fee, &mut controller.balance);

        event::emit(NameRegisteredEvent {
            node: base_registrar::get_base_node(registrar),
            label: label_str,
            owner,
            cost: FEE_PER_YEAR * no_years,
            expiry: tx_context::epoch(ctx) + duration,
            nft_id,
            resolver,
            referral_code,
            discount_code,
        });
    }

    fun remove_outdated_commitments(controller: &mut BaseController, ctx: &mut TxContext) {
        // TODO: need to update logic when timestamp is introduced
        let len = vec_map::size(&controller.commitments);
        let index = 0;
        while (index < len && len > 0 ) {
            let (_, created_at) = vec_map::get_entry_by_idx(&controller.commitments, index);
            if (*created_at + MAX_COMMITMENT_AGE < tx_context::epoch(ctx)) {
                vec_map::remove_entry_by_idx(&mut controller.commitments, index);
                len = len - 1;
            } else index = index + 1;
        };
    }

    fun consume_commitment(
        controller: &mut BaseController,
        registrar: &BaseRegistrar,
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
        assert!(base_registrar::available(registrar, string::utf8(label), ctx), ELabelUnAvailable);
        vec_map::remove(&mut controller.commitments, &commitment);
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
        vec_map::size(&controller.commitments)
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

    public entry fun set_disable(_: &AdminCap, controller: &mut BaseController, new_value: bool) {
        controller.disable = new_value;
    }

    #[test_only]
    /// Wrapper of module initializer for testing
    public fun test_init(ctx: &mut TxContext) {
        transfer::share_object(BaseController {
            id: object::new(ctx),
            commitments: vec_map::empty(),
            balance: balance::zero(),
            // cannot get the ID of name_resolver in `init`, admin need to update this by calling `set_default_resolver`
            default_addr_resolver: @0x0,
            disable: false,
        });
    }
}
