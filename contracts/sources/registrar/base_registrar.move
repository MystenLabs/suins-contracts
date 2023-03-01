/// Base structure for all kind of registrars except reverse one.
/// Call `new_tld` to setup new registrar.
/// All functions that involves payment charging in this module aren't supposed to be called directly,
/// users must call the corresponding functions in `Controller`.
module suins::base_registrar {
    use sui::event;
    use sui::object::{Self, ID, UID, uid_to_inner};
    use sui::transfer;
    use sui::tx_context::{TxContext, epoch, sender};
    use sui::url::Url;
    use std::string::{Self, String, utf8};
    use std::option;
    use std::vector;
    use suins::base_registry::{Self, AdminCap};
    use suins::configuration::{Self, Configuration};
    use sui::ecdsa_k1;
    use suins::remove_later;
    use sui::url;
    use std::hash::sha2_256;
    use suins::abc::{SuiNS, RegistrationRecord};
    use sui::table;
    use suins::abc;
    use sui::table::Table;

    friend suins::controller;
    friend suins::auction;

    // in terms of epoch
    const GRACE_PERIOD: u8 = 90;
    const MAX_TTL: u64 = 0x100000;
    const TLD: vector<u8> = b"tld";

    const EUnauthorized: u64 = 101;
    // errors in the range of 201..300 indicate Registrar errors
    const EInvalidLabel: u64 = 203;
    const ELabelUnAvailable: u64 = 204;
    const ELabelExpired: u64 = 205;
    const EInvalidDuration: u64 = 206;
    const ELabelNotExists: u64 = 207;
    const ETLDExists: u64 = 208;
    const EInvalidBaseNode: u64 = 209;
    const ESignatureNotMatch: u64 = 210;
    const EInvalidImageMessage: u64 = 211;
    const EHashedMessageNotMatch: u64 = 212;
    const ENFTExpired: u64 = 213;

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
        expiry: u64,
    }

    struct NameReclaimedEvent has copy, drop {
        node: String,
        owner: address,
    }

    struct ImageUpdatedEvent has copy, drop {
        sender: address,
        node: String,
        new_image: Url,
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
        new_tld: vector<u8>,
        ctx: &mut TxContext,
    ) {
        let registrars = abc::registrars_mut(suins);
        table::add(registrars, utf8(new_tld), table::new(ctx));
    }

    /// #### Notice
    /// The owner of the NFT uses this function to change the `owner` property of the
    /// corresponding name record stored in the `Registry`.
    ///
    /// #### Dev
    /// We identify the registrar object by `tld`
    ///
    /// #### Params
    /// `owner`: new owner address of name record.
    ///
    /// Panic
    /// Panic if the NFT no longer exists
    /// or the NFT expired.
    public entry fun reclaim_name(
        suins: &mut SuiNS,
        tld: vector<u8>,
        nft: &RegistrationNFT,
        owner: address,
        ctx: &mut TxContext,
    ) {
        let tld = utf8(tld);
        let registrar = abc::registrar(suins, tld);
        let label = assert_nft_not_expires(registrar, tld, nft, ctx);

        let registration = table::borrow(registrar, label);
        assert!(abc::registration_record_expiry(registration) >= epoch(ctx), ELabelExpired);

        base_registry::set_owner_internal(suins, nft.name, owner);
        event::emit(NameReclaimedEvent {
            node: nft.name,
            owner,
        })
    }

    /// #### Notice
    /// The owner of the NFT uses this function to update `url` field of his/her NFT.
    /// The `signature`, `raw_msg` and `raw_msg` are generated by our Backend only.
    ///
    /// #### Dev
    /// We identify the registrar object by `tld`
    ///
    /// #### Params
    /// `nft`: the NFT to be updated,
    /// `signature`: secp256k1 of `hashed_msg`
    /// `hashed_msg`: sha256 of `raw_msg`
    /// `raw_msg`: the data to verify and update image url, with format: <ipfs_url>,<owner>,<expiry>.
    ///
    /// Panic
    /// Panic if the NFT no longer invalid
    /// or `signature`, `hashed_msg` or `raw_msg` is empty
    /// or `hash_msg` doesn't match `raw_msg`
    /// or `signature` doesn't match `hashed_msg` and `public_key` stored in Configuration
    /// or the data in NFTs don't match `raw_msg`
    public entry fun update_image_url(
        suins: &mut SuiNS,
        tld: vector<u8>,
        config: &Configuration,
        nft: &mut RegistrationNFT,
        signature: vector<u8>,
        hashed_msg: vector<u8>,
        raw_msg: vector<u8>,
        ctx: &mut TxContext,
    ) {
        let tld = utf8(tld);
        let registrar = abc::registrar(suins, tld);
        let label = assert_nft_not_expires(registrar, tld, nft, ctx);

        assert_image_msg_not_empty(&signature, &hashed_msg, &raw_msg);
        assert_image_msg_match(config, signature, hashed_msg, raw_msg);

        let (ipfs, node_msg, expiry) = remove_later::deserialize_image_msg(raw_msg);

        assert!(node_msg == nft.name, EInvalidImageMessage);

        assert!(expiry == name_expires_at_internal(registrar, label), EInvalidImageMessage);

        nft.url = url::new_unsafe_from_bytes(*string::bytes(&ipfs));
        event::emit(ImageUpdatedEvent {
            sender: sender(ctx),
            node: nft.name,
            new_image: nft.url,
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
    public fun name_expires_at(suins: &SuiNS, tld: vector<u8>, label: vector<u8>): u64 {
        let tld = utf8(tld);
        let registrar = abc::registrar(suins, tld);
        let label = utf8(label);

        if (table::contains(registrar, label)) {
            let record = table::borrow(registrar, label);
            return abc::registration_record_expiry(record)
        };
        0
    }

    // === Friend and Private Functions ===

    /// label can have multiple levels, e.g. 'dn.suins' or 'suins'
    /// this function doesn't charge fee
    public(friend) fun register(
        suins: &mut SuiNS,
        tld: vector<u8>,
        config: &Configuration,
        label: vector<u8>,
        owner: address,
        duration: u64,
        resolver: address,
        ctx: &mut TxContext
    ): ID {
        let (nft_id, _url) = register_with_image(
            suins,
            tld,
            config,
            label,
            owner,
            duration,
            resolver,
            vector[],
            vector[],
            vector[],
            ctx
        );
        nft_id
    }

    public(friend) fun register_with_image(
        suins: &mut SuiNS,
        tld: vector<u8>,
        config: &Configuration,
        label: vector<u8>,
        owner: address,
        duration: u64,
        resolver: address,
        signature: vector<u8>,
        hashed_msg: vector<u8>,
        raw_msg: vector<u8>,
        ctx: &mut TxContext
    ): (ID, Url) {
        // the calling fuction is responsible for checking emptyness of msg
        assert!(duration > 0, EInvalidDuration);
        // TODO: label is already validated in Controller, consider removing this
        let label = string::try_utf8(label);
        assert!(option::is_some(&label), EInvalidLabel);

        let label = option::extract(&mut label);
        let tld = utf8(tld);
        let registrar = abc::registrar_mut(suins, tld);

        assert!(is_available_internal(registrar, label, ctx), ELabelUnAvailable);

        let expiry = epoch(ctx) + duration;
        let node = label;
        string::append_utf8(&mut node, b".");
        string::append(&mut node, tld);

        let url;
        if (vector::is_empty(&hashed_msg) || vector::is_empty(&raw_msg) || vector::is_empty(&signature))
            url = url::new_unsafe_from_bytes(vector[])
        else {
            assert_image_msg_match(config, signature, hashed_msg, raw_msg);

            let (ipfs, node_msg, expiry_msg) = remove_later::deserialize_image_msg(raw_msg);

            assert!(node_msg == node, EInvalidImageMessage);
            assert!(expiry_msg == expiry, EInvalidImageMessage);

            url = url::new_unsafe(string::to_ascii(ipfs));
        };

        let nft = RegistrationNFT {
            id: object::new(ctx),
            name: node,
            url,
        };
        let nft_id = object::uid_to_inner(&nft.id);
        let record = abc::new_registrtion_record(expiry, owner, nft_id);

        if (table::contains(registrar, label)) {
            // this `label` is available for registration again
            table::remove(registrar, label);
        };

        table::add(registrar, label, record);
        transfer::transfer(nft, owner);
        base_registry::set_record_internal(suins, node, owner, resolver, 0);

        (nft_id, url)
    }

    /// this function doesn't charge fee
    /// intended to be called by `Controller`
    public(friend) fun renew(suins: &mut SuiNS, tld: vector<u8>, label: vector<u8>, duration: u64, ctx: &TxContext): u64 {
        let tld = utf8(tld);
        let registrar = abc::registrar_mut(suins, tld);
        let label = string::utf8(label);
        let expiry = name_expires_at_internal(registrar, label);

        assert!(expiry > 0, ELabelNotExists);
        assert!(expiry + (GRACE_PERIOD as u64) >= epoch(ctx), ELabelExpired);

        let record: &mut RegistrationRecord = table::borrow_mut(registrar, label);
        let new_expiry = abc::registration_record_expiry(record) + duration;
        *abc::registration_record_expiry_mut(record) = new_expiry;

        event::emit(NameRenewedEvent { label, expiry: new_expiry });
        new_expiry
    }

    public(friend) fun assert_image_msg_not_empty(signature: &vector<u8>, hashed_msg: &vector<u8>, raw_msg: &vector<u8>) {
        assert!(
            !vector::is_empty(signature)
                && !vector::is_empty(hashed_msg)
                && !vector::is_empty(raw_msg),
            EInvalidImageMessage
        );
    }

    public(friend) fun assert_image_msg_match(
        config: &Configuration,
        signature: vector<u8>,
        hashed_msg: vector<u8>,
        raw_msg: vector<u8>
    ) {
        assert!(sha2_256(raw_msg) == hashed_msg, EHashedMessageNotMatch);
        assert!(
            ecdsa_k1::secp256k1_verify(&signature, configuration::public_key(config), &hashed_msg),
            ESignatureNotMatch
        );
    }

    /// #### Notice
    /// Check if node derived from `label` and `registrar.tld` is available for registration.
    /// `label` has an extra `GRACE_PERIOD` time after the expiration date,
    /// during which it's consisered unavailable.
    /// This `GRACE_PERIOD` is for the current owner to have time to renew.
    ///
    /// #### Params
    /// `label`: label to be checked
    ///
    /// #### Returns
    /// true if this node is available for registration
    /// false otherwise
    public(friend) fun is_available(suins: &SuiNS, tld: vector<u8>, label: String, ctx: &TxContext): bool {
        let tld = utf8(tld);
        let registrar = abc::registrar(suins, tld);
        is_available_internal(registrar, label, ctx)
    }

    /// Returns the label of NFT
    public(friend) fun assert_nft_not_expires(
        registrar: &Table<String, RegistrationRecord>,
        tld: String,
        nft: &RegistrationNFT,
        ctx: &mut TxContext,
    ): String {
        let label = get_label_part(&nft.name, &tld);
        let record = table::borrow(registrar, label);
        // TODO: delete NFT if it expired
        assert!(abc::registration_record_owner(record) == sender(ctx), ENFTExpired);
        assert!(abc::registration_record_nft_id(record) == uid_to_inner(&nft.id), ENFTExpired);

        let expiry = name_expires_at_internal(registrar, label);
        assert!(expiry != 0 && expiry >= epoch(ctx), ENFTExpired);

        label
    }

    fun name_expires_at_internal(registrar: &Table<String, RegistrationRecord>, label: String): u64 {
        if (table::contains(registrar, label)) {
            let record = table::borrow(registrar, label);
            return abc::registration_record_expiry(record)
        };
        0
    }

    fun is_available_internal(registrar: &Table<String, RegistrationRecord>, label: String, ctx: &TxContext): bool {
        let expiry = name_expires_at_internal(registrar, label);
        if (expiry != 0) {
            return expiry + (GRACE_PERIOD as u64) < epoch(ctx)
        };
        true
    }

    fun get_label_part(node: &String, tld: &String): String {
        let index_of_dot = string::index_of(node, tld);
        assert!(index_of_dot == string::length(node) - string::length(tld), EInvalidBaseNode);

        string::sub_string(node, 0, index_of_dot - 1)
    }

    // === Testing ===

    #[test_only]
    friend suins::base_registrar_tests;
    #[test_only]
    friend suins::controller_tests;

    #[test_only]
    public fun record_exists(suins: &SuiNS, tld: vector<u8>, label: vector<u8>): bool {
        let tld = utf8(tld);
        let label = utf8(label);
        let registrar = abc::registrar(suins, tld);

        table::contains(registrar, label)
    }

    #[test_only]
    public fun get_nft_fields(nft: &RegistrationNFT): (String, Url) {
        (nft.name, nft.url)
    }

    #[test_only]
    public fun assert_registrar_exists(suins: &SuiNS, tld: vector<u8>) {
        let tld = utf8(tld);
        abc::registrar(suins, tld);
    }

    #[test_only]
    public fun get_record_detail(suins: &SuiNS, tld: vector<u8>, label: vector<u8>): (u64, address) {
        let tld = utf8(tld);
        let registrar = abc::registrar(suins, tld);
        let label = utf8(label);

        let record = table::borrow(registrar, label);

        (abc::registration_record_expiry(record), abc::registration_record_owner(record))
    }

    #[test_only]
    public fun get_registrar(suins: &SuiNS, tld: vector<u8>): &Table<String, RegistrationRecord> {
        let tld = utf8(tld);
        abc::registrar(suins, tld)
    }

    #[test_only]
    public fun set_nft_domain(nft: &mut RegistrationNFT, new_domain: String) {
        nft.name = new_domain;
    }
}
