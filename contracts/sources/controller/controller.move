/// Its job is to charge payment, add validation and apply referral and discount code
/// when registering and extend experation of domanin names.
/// The real logic of mint a NFT and store the record in blockchain is done in Registrar and SuiNS contract.
/// Domain name registration can only occur using the Controller and Auction contracts.
/// During auction period, only domains with 7 to 63 characters can be registered via the Controller,
/// but after the auction has ended, all domains can be registered.
module suins::controller {

    use sui::balance;
    use sui::coin::{Self, Coin};
    use sui::hash::keccak256;
    use sui::event;
    use sui::linked_table::{Self, LinkedTable};
    use sui::object::ID;
    use sui::tx_context::{Self, TxContext};
    use sui::sui::SUI;
    use suins::registry::AdminCap;
    use suins::registrar::{Self, RegistrationNFT};
    use suins::configuration::{Self, Configuration};
    use suins::emoji;
    use suins::coin_util;
    use suins::entity::{Self, SuiNS};
    use std::string::{Self, String, utf8};
    use std::ascii;
    use std::bcs;
    use std::vector;
    use std::option::{Self, Option};
    use sui::url::Url;
    use suins::remove_later;
    use sui::clock::Clock;
    use sui::clock;

    const MAX_COMMITMENT_AGE_IN_MS: u64 = 259_200_000;
    const MIN_COMMITMENT_AGE_IN_MS: u64 = 120_000;
    const MAX_OUTDATED_COMMITMENTS_TO_REMOVE: u64 = 50;
    const SUI_TLD: vector<u8> = b"sui";

    // errors in the range of 301..400 indicate Sui Controller errors
    const ECommitmentNotExists: u64 = 302;
    const ECommitmentNotValid: u64 = 303;
    const ECommitmentTooOld: u64 = 304;
    const ENotEnoughFee: u64 = 305;
    const EInvalidDuration: u64 = 306;
    const ELabelUnavailable: u64 = 308;
    const ENoProfits: u64 = 310;
    const EInvalidCode: u64 = 311;
    const ERegistrationIsDisabled: u64 = 312;
    const EInvalidDomain: u64 = 314;
    const ECommitmentTooSoon: u64 = 315;
    const EAuctionNotEndYet: u64 = 316;
    const EInvalidNoYears: u64 = 317;

    struct NameRegisteredEvent has copy, drop {
        tld: String,
        label: String,
        owner: address,
        cost: u64,
        expired_at: u64,
        nft_id: ID,
        referral_code: Option<ascii::String>,
        discount_code: Option<ascii::String>,
        url: Url,
        data: String,
    }

    struct NameRenewedEvent has copy, drop {
        tld: String,
        label: String,
        cost: u64,
        duration: u64,
    }

    struct CommitmentAddedEvent has copy, drop {
        commitment: vector<u8>,
        timestamp_ms: u64,
    }

    /// #### Notice
    /// This function is the first step in the commit/reveal process, which is implemented to prevent front-running.
    ///
    /// #### Dev
    /// This also removes outdated commitments.
    ///
    /// #### Params
    /// `commitment`: hash from `make_commitment`
    public entry fun commit(suins: &mut SuiNS, commitment: vector<u8>, clock: &Clock) {
        let commitments = entity::controller_commitments_mut(suins);
        remove_outdated_commitments(commitments, clock);

        linked_table::push_back(commitments, commitment, clock::timestamp_ms(clock));
        event::emit(CommitmentAddedEvent {
            commitment,
            timestamp_ms: clock::timestamp_ms(clock)
        });
    }

    /// #### Notice
    /// This function is the second step in the commit/reveal process, which is implemented to prevent front-running.
    /// It acts as a gatekeeper for the `Registrar::Controller`, responsible for label validation and charging payment.
    ///
    /// #### Params
    /// `label`: label of the domain name being registered, the domain name has the form `label`.sui
    /// `owner`: owner address of created NFT
    /// `no_years`: in years
    /// `secret`: the value used to create commitment in the first step
    ///
    /// Panic
    /// Panic if new registration is disabled
    /// or `label` contains characters that are not allowed
    /// or `label` is waiting to be finalized in auction
    /// or label length isn't outside of the permitted range
    /// or `payment` doesn't have enough coins
    /// or either `referral_code` or `discount_code` is invalid
    public entry fun register(
        suins: &mut SuiNS,
        config: &mut Configuration,
        label: String, // `label` is 1 level
        owner: address,
        no_years: u64,
        secret: vector<u8>,
        payment: &mut Coin<SUI>,
        clock: &Clock,
        ctx: &mut TxContext,
    ) {
        register_internal(
            suins,
            config,
            label,
            owner,
            no_years,
            secret,
            payment,
            option::none(),
            option::none(),
            vector[],
            vector[],
            vector[],
            clock,
            ctx,
        );
    }

    /// #### Notice
    /// This function is the second step in the commit/reveal process, which is implemented to prevent front-running.
    /// It acts as a gatekeeper for the `Registrar::Controller`, responsible for label validation and charging payment.
    ///
    /// #### Dev
    /// Use `tld` to identify the registrar object.
    ///
    /// #### Params
    /// `label`: label of the domain name being registered, the domain name has the form `label`.sui
    /// `owner`: owner address of created NFT
    /// `no_years`: in years
    /// `secret`: the value used to create commitment in the first step
    /// `signature`: secp256k1 of `hashed_msg`
    /// `hashed_msg`: sha256 of `raw_msg`
    /// `raw_msg`: the data to verify and update image url, with format: <ipfs_url>,<owner>,<expired_at>.
    /// Note: `owner` is a 40 hexadecimal string without `0x` prefix
    ///
    /// Panic
    /// Panic if new registration is disabled
    /// or `label` contains characters that are not allowed
    /// or `label` is waiting to be finalized in auction
    /// or label length isn't outside of the permitted range
    /// or `payment` doesn't have enough coins
    /// or either `referral_code` or `discount_code` is invalid
    public entry fun register_with_image(
        suins: &mut SuiNS,
        config: &mut Configuration,
        label: String, // `label` is 1 level
        owner: address,
        no_years: u64,
        secret: vector<u8>,
        payment: &mut Coin<SUI>,
        signature: vector<u8>,
        hashed_msg: vector<u8>,
        raw_msg: vector<u8>,
        clock: &Clock,
        ctx: &mut TxContext,
    ) {
        registrar::assert_image_msg_not_empty(&signature, &hashed_msg, &raw_msg);

        register_internal(
            suins,
            config,
            label,
            owner,
            no_years,
            secret,
            payment,
            option::none(),
            option::none(),
            signature,
            hashed_msg,
            raw_msg,
            clock,
            ctx,
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
    /// Use `tld` to identify the registrar object.
    ///
    /// #### Params
    /// `referral_code`: referral code to be used
    /// `discount_code`: discount code to be used
    public entry fun register_with_code(
        suins: &mut SuiNS,
        config: &mut Configuration,
        label: String, // `label` is 1 level
        owner: address,
        no_years: u64,
        secret: vector<u8>,
        payment: &mut Coin<SUI>,
        referral_code: vector<u8>,
        discount_code: vector<u8>,
        clock: &Clock,
        ctx: &mut TxContext,
    ) {
        let (referral_code, discount_code) = validate_codes(referral_code, discount_code);

        register_internal(
            suins,
            config,
            label,
            owner,
            no_years,
            secret,
            payment,
            referral_code,
            discount_code,
            vector[],
            vector[],
            vector[],
            clock,
            ctx,
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
    /// `signature`: secp256k1 of `hashed_msg`
    /// `hashed_msg`: sha256 of `raw_msg`
    /// `raw_msg`: the data to verify and update image url, with format: <ipfs_url>,<owner>,<expired_at>.
    /// Note: `owner` is a 40 hexadecimal string without `0x` prefix
    public entry fun register_with_code_and_image(
        suins: &mut SuiNS,
        config: &mut Configuration,
        label: String, // `label` is 1 level
        owner: address,
        no_years: u64,
        secret: vector<u8>,
        payment: &mut Coin<SUI>,
        referral_code: vector<u8>,
        discount_code: vector<u8>,
        signature: vector<u8>,
        hashed_msg: vector<u8>,
        raw_msg: vector<u8>,
        clock: &Clock,
        ctx: &mut TxContext,
    ) {
        registrar::assert_image_msg_not_empty(&signature, &hashed_msg, &raw_msg);
        let (referral_code, discount_code) = validate_codes(referral_code, discount_code);

        register_internal(
            suins,
            config,
            label,
            owner,
            no_years,
            secret,
            payment,
            referral_code,
            discount_code,
            signature,
            hashed_msg,
            raw_msg,
            clock,
            ctx,
        );
    }

    /// #### Notice
    /// Anyone can use this function to extend expiration of a node. The TLD comes from BaseRegistrar::tld.
    /// It acts as a gatekeeper for the `Registrar::Renew`, responsible for charging payment.
    ///
    /// #### Params
    /// `label`: label of the domain name being registered, the domain name has the form `label`.sui
    /// `no_years`: in years
    ///
    /// Panic
    /// Panic if domain name doesn't exist
    /// or `payment` doesn't have enough coins
    public entry fun renew(
        suins: &mut SuiNS,
        config: &Configuration,
        label: String,
        no_years: u64,
        payment: &mut Coin<SUI>,
        ctx: &mut TxContext,
    ) {
        renew_internal(suins, config, label, no_years, payment, ctx)
    }

    /// #### Notice
    /// Anyone can use this function to extend expiration of a domain name. The TLD comes from BaseRegistrar::tld.
    /// It acts as a gatekeeper for the `Registrar::renew`, responsible for charging payment.
    /// The image url of the `nft` is updated.
    ///
    /// #### Params
    /// `label`: label of the domain name being registered, the domain name has the form `label`.sui
    /// `no_years`: in years
    ///
    /// Panic
    /// Panic if domain name doesn't exist
    /// or `payment` doesn't have enough coins
    /// or `signature` is empty
    /// or `hashed_msg` is empty
    /// or `msg` is empty
    public entry fun renew_with_image(
        suins: &mut SuiNS,
        config: &Configuration,
        label: String,
        no_years: u64,
        payment: &mut Coin<SUI>,
        nft: &mut RegistrationNFT,
        signature: vector<u8>,
        hashed_msg: vector<u8>,
        raw_msg: vector<u8>,
        ctx: &mut TxContext,
    ) {
        // NFT and imag_msg are validated in `update_image_url`
        renew_internal(suins, config, label, no_years, payment, ctx);
        registrar::update_image_url(suins, utf8(SUI_TLD), config, nft, signature, hashed_msg, raw_msg, ctx);
    }

    /// #### Notice
    /// Admin use this function to withdraw the payment.
    ///
    /// Panics
    /// Panics if no profits has been created.
    public entry fun withdraw(_: &AdminCap, suins: &mut SuiNS, ctx: &mut TxContext) {
        let amount = balance::value(entity::controller_balance(suins));
        assert!(amount > 0, ENoProfits);

        coin_util::suins_transfer_to_address(suins, amount, tx_context::sender(ctx), ctx);
    }

    public entry fun new_reserved_domains(
        _: &AdminCap,
        suins: &mut SuiNS,
        config: &Configuration,
        domains: vector<u8>,
        owner: address,
        ctx: &mut TxContext
    ) {
        if (owner == @0x0) owner = tx_context::sender(ctx);
        let domains = remove_later::deserialize_reserve_domains(domains);
        let len = vector::length(&domains);
        let index = 0;
        let dot = utf8(b".");
        let emoji_config = configuration::emoji_config(config);
        while (index < len) {
            let domain = vector::borrow(&domains, index);
            index = index + 1;

            let index_of_dot = string::index_of(domain, &dot);
            assert!(index_of_dot != string::length(domain), EInvalidDomain);
            // TODO: validate domain name
            let label = string::sub_string(domain, 0, index_of_dot);
            emoji::validate_label_with_emoji(
                emoji_config,
                label,
                configuration::min_domain_length(),
                configuration::max_domain_length()
            );
            let tld = string::sub_string(domain, index_of_dot + 1, string::length(domain));
            registrar::register_internal(
                suins,
                tld,
                config,
                label,
                owner,
                365,
                ctx,
            );
        };
    }

    // === Private Functions ===

    fun renew_internal(
        suins: &mut SuiNS,
        config: &Configuration,
        label: String,
        no_years: u64,
        payment: &mut Coin<SUI>,
        ctx: &mut TxContext
    ) {
        assert!(0 < no_years && no_years <= 5, EInvalidNoYears);
        let emoji_config = configuration::emoji_config(config);
        let renew_fee = configuration::price_for_label(config, emoji::len_of_label(emoji_config, *string::bytes(&label)), no_years);
        assert!(coin::value(payment) >= renew_fee, ENotEnoughFee);
        coin_util::user_transfer_to_suins(suins, payment, renew_fee);

        let duration = no_years * 365;
        registrar::renew(suins, utf8(SUI_TLD), label, duration, ctx);

        event::emit(NameRenewedEvent {
            tld: utf8(SUI_TLD),
            label,
            cost: renew_fee,
            duration,
        });
    }

    fun register_internal(
        suins: &mut SuiNS,
        config: &mut Configuration,
        label: String, // label has only 1 level
        owner: address,
        no_years: u64,
        secret: vector<u8>,
        payment: &mut Coin<SUI>,
        referral_code: Option<ascii::String>,
        discount_code: Option<ascii::String>,
        signature: vector<u8>,
        hashed_msg: vector<u8>,
        raw_msg: vector<u8>,
        clock: &Clock,
        ctx: &mut TxContext,
    ) {
        assert!(0 < no_years && no_years <= 5, EInvalidNoYears);
        assert!(configuration::is_enable_controller(config), ERegistrationIsDisabled);
        assert!(tx_context::epoch(ctx) > entity::controller_auction_house_finalized_at(suins), EAuctionNotEndYet);

        let emoji_config = configuration::emoji_config(config);
        let len_of_label =
            emoji::validate_label_with_emoji(
                emoji_config,
                label,
                configuration::min_domain_length(),
                configuration::max_domain_length()
            );

        let commitment = make_commitment(*string::bytes(&label), owner, secret);
        consume_commitment(suins, label, commitment, clock, ctx);

        let registration_fee = configuration::price_for_label(config, len_of_label, no_years);
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

        let tld = utf8(SUI_TLD);
        let duration = no_years * 365;
        let (nft_id, url, additional_data) = registrar::register_with_image_internal(
            suins,
            tld,
            config,
            label,
            owner,
            duration,
            signature,
            hashed_msg,
            raw_msg,
            ctx
        );

        event::emit(NameRegisteredEvent {
            tld,
            label,
            owner,
            // TODO: reduce cost when using discount code
            cost: configuration::price_for_label(config, len_of_label, no_years),
            expired_at: tx_context::epoch(ctx) + duration,
            nft_id,
            referral_code,
            discount_code,
            url,
            data: additional_data,
        });

        coin_util::user_transfer_to_suins(suins, payment, registration_fee);
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
        let remaining_fee = (original_fee / 100) * (100 - rate as u64);
        let payback_amount = original_fee - remaining_fee;
        coin_util::user_transfer_to_address(payment, payback_amount, partner, ctx);

        remaining_fee
    }

    // returns remaining_fee after being discounted
    fun apply_discount_code(
        config: &mut Configuration,
        original_fee: u64,
        referral_code: &ascii::String,
        ctx: &mut TxContext,
    ): u64 {
        let rate = configuration::use_discount_code(config, referral_code, ctx);
        (original_fee / 100) * (100 - rate as u64)
    }

    fun remove_outdated_commitments(commitments: &mut LinkedTable<vector<u8>, u64>, clock: &Clock) {
        let front_element = linked_table::front(commitments);
        let i = 0;

        while (option::is_some(front_element) && i < MAX_OUTDATED_COMMITMENTS_TO_REMOVE) {
            i = i + 1;

            let created_at = linked_table::borrow(commitments, *option::borrow(front_element));
            if (*created_at + MAX_COMMITMENT_AGE_IN_MS <= clock::timestamp_ms(clock)) {
                linked_table::pop_front(commitments);
                front_element = linked_table::front(commitments);
            } else break;
        };
    }

    fun consume_commitment(
        suins: &mut SuiNS,
        label: String,
        commitment: vector<u8>,
        clock: &Clock,
        ctx: &TxContext,
    ) {
        let commitments = entity::controller_commitments_mut(suins);
        assert!(linked_table::contains(commitments, commitment), ECommitmentNotExists);
        assert!(
            *linked_table::borrow(commitments, commitment) + MIN_COMMITMENT_AGE_IN_MS <= clock::timestamp_ms(clock),
            ECommitmentTooSoon
        );
        assert!(
            *linked_table::borrow(commitments, commitment) + MAX_COMMITMENT_AGE_IN_MS > clock::timestamp_ms(clock),
            ECommitmentTooOld
        );
        linked_table::remove(commitments, commitment);
        assert!(registrar::is_available(suins, utf8(SUI_TLD), label, ctx), ELabelUnavailable);
    }

    fun make_commitment(label: vector<u8>, owner: address, secret: vector<u8>): vector<u8> {
        let domain_name = label;
        vector::append(&mut domain_name, b".");
        vector::append(&mut domain_name, SUI_TLD);

        let owner_bytes = bcs::to_bytes(&owner);
        vector::append(&mut domain_name, owner_bytes);
        vector::append(&mut domain_name, secret);
        keccak256(&domain_name)
    }

    fun validate_codes(
        referral_code: vector<u8>,
        discount_code: vector<u8>
    ): (Option<ascii::String>, Option<ascii::String>) {
        let referral_len = vector::length(&referral_code);
        let discount_len = vector::length(&discount_code);
        // doesn't have a format for codes right now, so any non-empty code is considered valid
        assert!(referral_len > 0 || discount_len > 0, EInvalidCode);

        let referral = option::none();
        let discount = option::none();
        if (referral_len > 0) referral = option::some(ascii::string(referral_code));
        if (discount_len > 0) discount = option::some(ascii::string(discount_code));

        (referral, discount)
    }

    #[test_only]
    public fun max_commitment_age_in_ms(): u64 {
        MAX_COMMITMENT_AGE_IN_MS
    }

    #[test_only]
    public fun test_make_commitment(
        _tld: vector<u8>,
        label: vector<u8>,
        owner: address,
        secret: vector<u8>
    ): vector<u8> {
        make_commitment(label, owner, secret)
    }

    #[test_only]
    public fun get_balance(suins: &SuiNS): u64 {
        let contract_balance = entity::controller_balance(suins);
        balance::value(contract_balance)
    }

    #[test_only]
    public fun commitment_len(suins: &SuiNS): u64 {
        let commitments = entity::controller_commitments(suins);
        linked_table::length(commitments)
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
}
