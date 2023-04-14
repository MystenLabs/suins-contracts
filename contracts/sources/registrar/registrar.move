/// Base structure for all kind of registrars except reverse one.
/// Call `new_tld` to setup new registrar.
/// All functions that involves payment charging in this module aren't supposed to be called directly,
/// users must call the corresponding functions in `Controller`.
module suins::registrar {
    use sui::event;
    use sui::object::{Self, UID, uid_to_inner, ID};
    use sui::tx_context::TxContext;
    use sui::url::Url;
    use std::string::{Self, String, utf8};
    use std::vector;
    use suins::registry::{Self, AdminCap};
    use suins::configuration::{Self, Configuration};
    use sui::ecdsa_k1;
    use suins::remove_later;
    use sui::url;
    use std::hash::sha2_256;
    use suins::entity::{SuiNS, RegistrationRecord};
    use sui::table;
    use suins::entity;
    use sui::table::Table;
    use sui::tx_context;
    use sui::transfer;

    friend suins::controller;
    friend suins::auction;

    // in terms of epoch
    const GRACE_PERIOD: u8 = 90;
    const MAX_TTL: u64 = 0x100000;
    const TLD: vector<u8> = b"tld";

    const EUnauthorized: u64 = 101;
    // errors in the range of 201..300 indicate Registrar errors
    const ELabelUnavailable: u64 = 204;
    const ELabelExpired: u64 = 205;
    const EInvalidDuration: u64 = 206;
    const ELabelNotExists: u64 = 207;
    const ETLDExists: u64 = 208;
    const EInvalidTLD: u64 = 209;
    const ESignatureNotMatch: u64 = 210;
    const EInvalidImageMessage: u64 = 211;
    const EHashedMessageNotMatch: u64 = 212;
    const ENFTExpired: u64 = 213;
    const EInvalidNewExpiredAt: u64 = 214;

    /// NFT representing ownership of a domain
    struct RegistrationNFT has key, store {
        id: UID,
        /// name and url fields have special meaning in sui explorer and extension
        /// if url is a ipfs image, this image is showed on sui explorer and extension
        name: String,
        url: Url,
    }

    struct NameRenewedEvent has copy, drop {
        label: String,
        expired_at: u64,
    }

    struct NameReclaimedEvent has copy, drop {
        domain_name: String,
        owner: address,
    }

    struct ImageUpdatedEvent has copy, drop {
        sender: address,
        domain_name: String,
        new_image: Url,
        data: String,
    }

    /// #### Notice
    /// The admin uses this function to create a new `BaseRegistrar` share object
    /// that manages domains having the same top level domain.
    ///
    /// #### Params
    /// `new_tld`: the TLD that this new share object manages.
    ///
    /// Panic
    /// Panic if this TLD already exists.
    public entry fun new_tld(
        _: &AdminCap,
        suins: &mut SuiNS,
        new_tld: String,
        ctx: &mut TxContext,
    ) {
        let registrars = entity::registrars_mut(suins);
        table::add(registrars, new_tld, table::new(ctx));
    }

    /// #### Notice
    /// The owner of the NFT uses this function to change the `owner` property of the
    /// corresponding name record stored in the `Registry`.
    ///
    /// #### Dev
    /// Use `tld` to identify the registrar object.
    ///
    /// #### Params
    /// `owner`: new owner address of name record.
    ///
    /// Panic
    /// Panic if the NFT no longer exists
    /// or the NFT expired.
    public entry fun reclaim_name(
        nft: &RegistrationNFT,
        suins: &mut SuiNS,
        tld: String,
        owner: address,
        ctx: &mut TxContext,
    ) {
        let registrar = entity::registrar(suins, tld);
        let label = assert_nft_not_expires(registrar, tld, nft, ctx);

        let registration = table::borrow(registrar, label);
        assert!(entity::registration_record_expired_at(registration) >= tx_context::epoch(ctx), ELabelExpired);

        registry::set_owner_internal(suins, nft.name, owner);
        event::emit(NameReclaimedEvent {
            domain_name: nft.name,
            owner,
        })
    }

    /// #### Notice
    /// The owner of the NFT uses this function to update `url` field of his/her NFT.
    /// The `signature`, `raw_msg` and `raw_msg` are generated by our Backend only.
    ///
    /// #### Dev
    /// Use `tld` to identify the registrar object.
    ///
    /// #### Params
    /// `nft`: the NFT to be updated,
    /// `signature`: secp256k1 of `hashed_msg`
    /// `hashed_msg`: sha256 of `raw_msg`
    /// `raw_msg`: the data to verify and update image url, with format: <ipfs_url>,<owner>,<expired_at>.
    ///
    /// Panic
    /// Panic if the NFT no longer invalid
    /// or `signature`, `hashed_msg` or `raw_msg` is empty
    /// or `hash_msg` doesn't match `raw_msg`
    /// or `signature` doesn't match `hashed_msg` and `public_key` stored in Configuration
    /// or the data in NFTs don't match `raw_msg`
    public entry fun update_image_url(
        suins: &mut SuiNS,
        tld: String,
        config: &Configuration,
        nft: &mut RegistrationNFT,
        signature: vector<u8>,
        hashed_msg: vector<u8>,
        raw_msg: vector<u8>,
        ctx: &mut TxContext,
    ) {
        let registrar = entity::registrar(suins, tld);
        let label = assert_nft_not_expires(registrar, tld, nft, ctx);

        assert_image_msg_not_empty(&signature, &hashed_msg, &raw_msg);
        assert_image_msg_match(config, signature, hashed_msg, raw_msg);

        let (ipfs, domain_name_msg, expired_at, additional_data) = remove_later::deserialize_image_msg(raw_msg);

        assert!(domain_name_msg == nft.name, EInvalidImageMessage);

        assert!(expired_at == name_expires_at_internal(registrar, label), EInvalidImageMessage);

        nft.url = url::new_unsafe_from_bytes(*string::bytes(&ipfs));
        event::emit(ImageUpdatedEvent {
            sender: tx_context::sender(ctx),
            domain_name: nft.name,
            new_image: nft.url,
            data: additional_data,
        })
    }

    // === Public Functions ===

    /// #### Notice
    /// Returns the epoch after which the `label` is expired.
    ///
    /// #### Params
    /// `label`: label to be checked
    ///
    /// #### Returns
    /// 0: if `label` expired
    /// otherwise: the expiration date
    public fun name_expires_at(suins: &SuiNS, tld: String, label: String): u64 {
        let registrar = entity::registrar(suins, tld);

        if (table::contains(registrar, label)) {
            let record = table::borrow(registrar, label);
            return entity::registration_record_expired_at(record)
        };
        0
    }

    public fun assert_image_msg_not_empty(signature: &vector<u8>, hashed_msg: &vector<u8>, raw_msg: &vector<u8>) {
        assert!(
            !vector::is_empty(signature)
                && !vector::is_empty(hashed_msg)
                && !vector::is_empty(raw_msg),
            EInvalidImageMessage
        );
    }

    public fun assert_image_msg_match(
        config: &Configuration,
        signature: vector<u8>,
        hashed_msg: vector<u8>,
        raw_msg: vector<u8>
    ) {
        assert!(sha2_256(raw_msg) == hashed_msg, EHashedMessageNotMatch);
        assert!(
            ecdsa_k1::secp256k1_verify(&signature, configuration::public_key(config), &raw_msg, 1),
            ESignatureNotMatch
        );
    }

    /// #### Notice
    /// Check if domain name derived from `label` and `registrar.tld` is available for registration.
    /// `label` has an extra `GRACE_PERIOD` time after the expiration date,
    /// during which it's consisered unavailable.
    /// This `GRACE_PERIOD` is for the current owner to have time to renew.
    ///
    /// #### Params
    /// `label`: label to be checked
    ///
    /// #### Returns
    /// true if this domain name is available for registration
    /// false otherwise
    public fun is_available(suins: &SuiNS, tld: String, label: String, ctx: &TxContext): bool {
        let registrar = entity::registrar(suins, tld);
        is_available_internal(registrar, label, ctx)
    }

    /// Returns the label of NFT
    public fun assert_nft_not_expires(
        registrar: &Table<String, RegistrationRecord>,
        tld: String,
        nft: &RegistrationNFT,
        ctx: &mut TxContext,
    ): String {
        let label = get_label(&nft.name, &tld);
        let record = table::borrow(registrar, label);
        // TODO: delete NFT if it expired
        assert!(entity::registration_record_owner(record) == tx_context::sender(ctx), ENFTExpired);
        assert!(entity::registration_record_nft_id(record) == uid_to_inner(&nft.id), ENFTExpired);

        let expired_at = name_expires_at_internal(registrar, label);
        assert!(expired_at != 0 && expired_at >= tx_context::epoch(ctx), ENFTExpired);

        label
    }

    // === Friend and Private Functions ===

    /// this function doesn't charge fee
    public(friend) fun register_internal(
        suins: &mut SuiNS,
        tld: String,
        config: &Configuration,
        label: String,
        owner: address,
        duration: u64,
        ctx: &mut TxContext
    ): ID {
        let (nft_id, _, _) = register_with_image_internal(
            suins,
            tld,
            config,
            label,
            owner,
            duration,
            vector[],
            vector[],
            vector[],
            ctx
        );
        nft_id
    }

    public(friend) fun register_with_image_internal(
        suins: &mut SuiNS,
        tld: String,
        config: &Configuration,
        label: String,
        owner: address,
        duration: u64,
        signature: vector<u8>,
        hashed_msg: vector<u8>,
        raw_msg: vector<u8>,
        ctx: &mut TxContext
    ): (ID, Url, String) {
        // the calling fuction is responsible for checking emptyness of msg
        assert!(duration > 0, EInvalidDuration);

        let registrar = entity::registrar_mut(suins, tld);
        assert!(is_available_internal(registrar, label, ctx), ELabelUnavailable);

        let expired_at = tx_context::epoch(ctx) + duration;
        let domain_name = label;
        string::append_utf8(&mut domain_name, b".");
        string::append(&mut domain_name, tld);

        let url;
        let additional_data = utf8(vector[]);
        if (vector::is_empty(&hashed_msg) || vector::is_empty(&raw_msg) || vector::is_empty(&signature))
            url = url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY")
        else {
            assert_image_msg_match(config, signature, hashed_msg, raw_msg);

            let (ipfs, domain_name_msg, expired_at_msg, data) = remove_later::deserialize_image_msg(raw_msg);
            assert!(domain_name_msg == domain_name, EInvalidImageMessage);
            assert!(expired_at_msg == expired_at, EInvalidImageMessage);

            url = url::new_unsafe(string::to_ascii(ipfs));
            additional_data = data
        };

        let nft = RegistrationNFT {
            id: object::new(ctx),
            name: domain_name,
            url,
        };
        let nft_id = object::uid_to_inner(&nft.id);
        let record = entity::new_registration_record(expired_at, owner, nft_id);

        if (table::contains(registrar, label)) {
            // this `label` is available for registration again
            table::remove(registrar, label);
        };

        table::add(registrar, label, record);
        transfer::transfer(nft, owner);
        registry::set_record_internal(suins, domain_name, owner, 0, ctx);

        (nft_id, url, additional_data)
    }

    /// this function doesn't charge fee
    /// intended to be called by `Controller`
    public(friend) fun renew(suins: &mut SuiNS, tld: String, label: String, duration: u64, ctx: &TxContext): u64 {
        let registrar = entity::registrar_mut(suins, tld);
        let expired_at = name_expires_at_internal(registrar, label);

        assert!(expired_at > 0, ELabelNotExists);
        assert!(expired_at + (GRACE_PERIOD as u64) >= tx_context::epoch(ctx), ELabelExpired);

        let record: &mut RegistrationRecord = table::borrow_mut(registrar, label);
        let new_expired_at = entity::registration_record_expired_at(record) + duration;

        assert!(new_expired_at - tx_context::epoch(ctx) <= 1825, EInvalidNewExpiredAt);
        *entity::registration_record_expired_at_mut(record) = new_expired_at;

        event::emit(NameRenewedEvent { label, expired_at: new_expired_at });
        new_expired_at
    }

    fun name_expires_at_internal(registrar: &Table<String, RegistrationRecord>, label: String): u64 {
        if (table::contains(registrar, label)) {
            let record = table::borrow(registrar, label);
            return entity::registration_record_expired_at(record)
        };
        0
    }

    fun is_available_internal(registrar: &Table<String, RegistrationRecord>, label: String, ctx: &TxContext): bool {
        let expired_at = name_expires_at_internal(registrar, label);
        if (expired_at != 0) {
            return expired_at + (GRACE_PERIOD as u64) < tx_context::epoch(ctx)
        };
        true
    }

    fun get_label(domain_name: &String, tld: &String): String {
        let dot_tld = utf8(b".");
        string::append(&mut dot_tld, *tld);

        let index_of_dot = string::index_of(domain_name, &dot_tld);
        assert!(index_of_dot == string::length(domain_name) - string::length(&dot_tld), EInvalidTLD);

        string::sub_string(domain_name, 0, index_of_dot)
    }

    // === Testing ===

    #[test_only]
    friend suins::registrar_tests;
    #[test_only]
    friend suins::controller_tests;

    #[test_only]
    public fun record_exists(suins: &SuiNS, tld: vector<u8>, label: vector<u8>): bool {
        let tld = utf8(tld);
        let label = utf8(label);
        let registrar = entity::registrar(suins, tld);

        table::contains(registrar, label)
    }

    #[test_only]
    public fun get_nft_fields(nft: &RegistrationNFT): (String, Url) {
        (nft.name, nft.url)
    }

    #[test_only]
    public fun assert_registrar_exists(suins: &SuiNS, tld: vector<u8>) {
        let tld = utf8(tld);
        entity::registrar(suins, tld);
    }

    #[test_only]
    public fun get_record_detail(suins: &SuiNS, tld: vector<u8>, label: vector<u8>): (u64, address) {
        let tld = utf8(tld);
        let registrar = entity::registrar(suins, tld);
        let record = table::borrow(registrar, utf8(label));

        (entity::registration_record_expired_at(record), entity::registration_record_owner(record))
    }

    #[test_only]
    public fun get_registrar(suins: &SuiNS, tld: vector<u8>): &Table<String, RegistrationRecord> {
        let tld = utf8(tld);
        entity::registrar(suins, tld)
    }

    #[test_only]
    public fun set_nft_domain(nft: &mut RegistrationNFT, new_domain: String) {
        nft.name = new_domain;
    }
}
