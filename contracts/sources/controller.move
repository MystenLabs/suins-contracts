/// Its job is to charge payment, add validation and apply referral and discount code
/// when registering and extend experation of domanin names.
/// The real logic of mint a NFT and store the record in blockchain is done in Registrar and SuiNS contract.
/// Domain name registration can only occur using the Controller and Auction contracts.
/// During auction period, only domains with 7 to 63 characters can be registered via the Controller,
/// but after the auction has ended, all domains can be registered.
module suins::controller {
    use std::string::{Self, String, utf8};
    use std::ascii;
    use std::vector;
    use std::option::{Self, Option};

    use sui::url::Url;
    use sui::sui::SUI;
    use sui::coin::{Self, Coin};
    use sui::event;
    use sui::object::ID;
    use sui::tx_context::{Self, TxContext};
    use sui::clock::Clock;
    use sui::dynamic_field as df;

    use suins::config::{Self, Config};
    use suins::registrar::{Self, RegistrationNFT};
    use suins::suins::{Self, SuiNS, AdminCap};
    use suins::string_utils;
    use suins::constants;
    use suins::promotion::{Self, Promotion};

    // errors in the range of 301..400 indicate Sui Controller errors
    const ENotEnoughFee: u64 = 305;
    const EInvalidDuration: u64 = 306;
    const ELabelUnavailable: u64 = 308;
    const EInvalidCode: u64 = 311;
    const ERegistrationIsDisabled: u64 = 312;
    const EInvalidDomain: u64 = 314;
    const EAuctionNotEndYet: u64 = 316;
    const EInvalidNoYears: u64 = 317;

    friend suins::auction;

    struct Controller has store {
        /// set by `configure_auction`
        /// the last epoch when bidder can call `finalize_auction`
        auction_house_finalized_at: u64,
    }

    /// Controller witness.
    struct App has drop {}

    /// Key to use when attaching a Controller.
    struct ControllerKey has copy, store, drop {}

    /// Harmless function to create a new Controller and attach it to the SuiNS.
    /// Can only be performed once.
    public fun add_to_suins(suins: &mut SuiNS, _ctx: &mut TxContext) {
        df::add(suins::app_uid_mut(App {}, suins), ControllerKey {}, Controller {
            auction_house_finalized_at: constants::max_epoch_allowed(),
        })
    }

    /// #### Notice
    /// Responsible for label validation, registration and chargin payment
    ///
    /// #### Params
    /// `label`: label of the domain name being registered, the domain name has the form `label`.sui
    /// `owner`: owner address of created NFT
    /// `no_years`: in years
    ///
    /// Panic
    /// Panic if new registration is disabled
    /// or `label` contains characters that are not allowed
    /// or `label` is waiting to be finalized in auction
    /// or label length isn't outside of the permitted range
    /// or `payment` doesn't have enough coins
    // TODO: make this return the NFT so it can be used in a later PT in order to link an image
    public fun register(
        suins: &mut SuiNS,
        label: String, // `label` is 1 level
        owner: address,
        no_years: u8,
        payment: &mut Coin<SUI>,
        clock: &Clock,
        ctx: &mut TxContext,
    ) {
        register_internal(
            suins,
            label,
            owner,
            no_years,
            payment,
            option::none(),
            option::none(),
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
    public fun register_with_code(
        suins: &mut SuiNS,
        label: String, // `label` is 1 level
        owner: address,
        no_years: u8,
        payment: &mut Coin<SUI>,
        referral_code: vector<u8>,
        discount_code: vector<u8>,
        clock: &Clock,
        ctx: &mut TxContext,
    ) {
        let (referral_code, discount_code) = validate_codes(referral_code, discount_code);

        register_internal(
            suins,
            label,
            owner,
            no_years,
            payment,
            referral_code,
            discount_code,
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
    public fun renew(
        suins: &mut SuiNS,
        label: String,
        no_years: u8,
        payment: &mut Coin<SUI>,
        ctx: &mut TxContext,
    ) {
        renew_internal(suins, label, no_years, payment, ctx)
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
    public fun renew_with_image(
        suins: &mut SuiNS,
        label: String,
        no_years: u8,
        payment: &mut Coin<SUI>,
        nft: &mut RegistrationNFT,
        signature: vector<u8>,
        hashed_msg: vector<u8>,
        raw_msg: vector<u8>,
        ctx: &mut TxContext,
    ) {
        // NFT and imag_msg are validated in `update_image_url`
        renew_internal(suins, label, no_years, payment, ctx);
        registrar::update_image_url(suins, nft, signature, hashed_msg, raw_msg, ctx);
    }

    public fun new_reserved_domains(
        _: &AdminCap,
        suins: &mut SuiNS,
        domains: vector<String>,
        owner: address,
        ctx: &mut TxContext
    ) {
        if (owner == @0x0) owner = tx_context::sender(ctx);
        let len = vector::length(&domains);
        let index = 0;
        let dot = utf8(b".");
        while (index < len) {
            let domain = vector::borrow(&domains, index);
            index = index + 1;

            let index_of_dot = string::index_of(domain, &dot);
            assert!(index_of_dot != string::length(domain), EInvalidDomain);
            let label = string::sub_string(domain, 0, index_of_dot);
            string_utils::validate_label(
                label,
                constants::min_domain_length(),
                constants::max_domain_length()
            );
            let tld = string::sub_string(domain, index_of_dot + 1, string::length(domain));
            let nft = registrar::register_with_image_internal(
                suins,
                tld,
                label,
                owner,
                365,
                ctx,
            );
            sui::transfer::public_transfer(nft, owner);

            // TODO: come back
            // event::emit(NameRegisteredEvent {
            //     tld,
            //     label,
            //     owner,
            //     cost: 0,
            //     expired_at: tx_context::epoch(ctx) + 365,
            //     nft_id,
            //     referral_code: option::none(),
            //     discount_code: option::none(),
            //     url,
            //     data,
            // });
        };
    }

    // === Private Functions ===

    fun renew_internal(
        suins: &mut SuiNS,
        label: String,
        no_years: u8,
        payment: &mut Coin<SUI>,
        ctx: &mut TxContext
    ) {
        assert!(0 < no_years && no_years <= 5, EInvalidNoYears);
        let config = suins::get_config<Config>(suins);
        let renew_fee = config::calculate_price(
            config,
            (string::length(&label) as u8),
            no_years
        );
        assert!(coin::value(payment) >= renew_fee, ENotEnoughFee);
        suins::app_add_balance(App {}, suins, coin::into_balance(coin::split(payment, renew_fee, ctx)));

        let duration = (no_years as u64) * 365;
        registrar::renew(suins, constants::sui_tld(), label, duration, ctx);

        event::emit(NameRenewedEvent {
            tld: constants::sui_tld(),
            label,
            cost: renew_fee,
            duration,
        });
    }

    fun register_internal(
        suins: &mut SuiNS,
        label: String, // label has only 1 level
        owner: address,
        no_years: u8,
        payment: &mut Coin<SUI>,
        referral_code: Option<ascii::String>,
        discount_code: Option<ascii::String>,
        _clock: &Clock, // TODO use clock for duration of registration
        ctx: &mut TxContext,
    ) {
        assert!(0 < no_years && no_years <= 5, EInvalidNoYears);
        assert!(true, ERegistrationIsDisabled);
        assert!(tx_context::epoch(ctx) > auction_house_finalized_at(suins), EAuctionNotEndYet);

        string_utils::validate_label(
            label,
            constants::min_domain_length(),
            constants::max_domain_length()
        );

        assert!(registrar::is_available(suins, constants::sui_tld(), label, ctx), ELabelUnavailable);

        let len_of_label = (string::length(&label) as u8);
        let registration_fee = config::calculate_price(suins::get_config<Config>(suins), len_of_label, no_years);
        assert!(coin::value(payment) >= registration_fee, ENotEnoughFee);

        // can apply both discount and referral codes at the same time
        if (option::is_some(&discount_code)) {
            registration_fee =
                apply_discount_code(suins, registration_fee, option::borrow(&discount_code), ctx);
        };
        if (option::is_some(&referral_code)) {
            registration_fee =
                apply_referral_code(suins, payment, registration_fee, option::borrow(&referral_code), ctx);
        };

        let tld = constants::sui_tld();
        let duration = (no_years as u64) * 365;
        let nft = registrar::register_with_image_internal(
            suins,
            tld,
            label,
            owner,
            duration,
            ctx
        );
        sui::transfer::public_transfer(nft, owner);

        // TODO
        // event::emit(NameRegisteredEvent {
        //     tld,
        //     label,
        //     owner,
        //     // TODO: reduce cost when using discount code
        //     cost: config::calculate_price(config, len_of_label, no_years),
        //     expired_at: tx_context::epoch(ctx) + duration,
        //     nft_id,
        //     referral_code,
        //     discount_code,
        //     url,
        //     data: additional_data,
        // });

        suins::app_add_balance(App {}, suins, coin::into_balance(coin::split(payment, registration_fee, ctx)))
    }

    // returns remaining_fee
    fun apply_referral_code(
        suins: &SuiNS,
        payment: &mut Coin<SUI>,
        original_fee: u64,
        referral_code: &ascii::String,
        ctx: &mut TxContext
    ): u64 {
        let config = suins::get_config<Promotion>(suins);
        let (rate, partner) = promotion::use_referral_code(config, &std::string::from_ascii(*referral_code));
        let remaining_fee = (original_fee / 100) * (100 - rate as u64);
        let payback_amount = original_fee - remaining_fee;

        sui::pay::split_and_transfer(payment, payback_amount, partner, ctx);

        remaining_fee
    }

    // returns remaining_fee after being discounted
    fun apply_discount_code(
        suins: &mut SuiNS,
        original_fee: u64,
        referral_code: &ascii::String,
        ctx: &mut TxContext,
    ): u64 {
        let config = suins::app_get_config_mut<App, Promotion>(App {}, suins);
        let rate = promotion::use_discount_code(config, &std::string::from_ascii(*referral_code), ctx);
        (original_fee / 100) * (100 - rate as u64)
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
    public fun apply_referral_code_test(
        suins: &SuiNS,
        payment: &mut Coin<SUI>,
        original_fee: u64,
        referral_code: vector<u8>,
        ctx: &mut TxContext
    ): u64 {
        apply_referral_code(suins, payment, original_fee, &ascii::string(referral_code), ctx)
    }

    fun controller(suins: &SuiNS): &Controller {
        df::borrow(suins::uid(suins), ControllerKey {})
    }

    fun controller_mut(suins: &mut SuiNS): &mut Controller {
        df::borrow_mut(suins::app_uid_mut(App {}, suins), ControllerKey {})
    }

    fun auction_house_finalized_at(suins: &mut SuiNS): u64 {
        controller(suins).auction_house_finalized_at
    }

    public(friend) fun auction_house_finalized_at_mut(suins: &mut SuiNS): &mut u64 {
        &mut controller_mut(suins).auction_house_finalized_at
    }

    // === Events ===

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
}
