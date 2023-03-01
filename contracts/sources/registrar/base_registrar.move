/// Base structure for all kind of registrars except reverse one.
/// Call `new_tld` to setup new registrar.
/// All functions that involves payment charging in this module aren't supposed to be called directly,
/// users must call the corresponding functions in `Controller`.
module suins::base_registrar {
    use sui::dynamic_field as field;
    use sui::event;
    use sui::object::{Self, ID, UID, uid_to_inner};
    use sui::transfer;
    use sui::tx_context::{TxContext, epoch, sender};
    use sui::url::Url;
    use std::string::{Self, String};
    use std::option;
    use std::vector;
    use suins::base_registry::{Self, Registry, AdminCap};
    use suins::configuration::{Self, Configuration};
    use sui::ecdsa_k1;
    use suins::remove_later;
    use sui::url;
    use std::hash::sha2_256;

    friend suins::controller;
    friend suins::auction;

    // in terms of epoch
    const GRACE_PERIOD: u8 = 90;
    const MAX_TTL: u64 = 0x100000;

    // TODO: move all error code to a single file
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
    const EInvalidMessage: u64 = 211;
    const EHashedMessageNotMatch: u64 = 212;
    const ENFTExpired: u64 = 213;

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

    /// NFT representing ownership of a domain
    struct RegistrationNFT has key, store {
        id: UID,
        /// name and url fields have special meaning in sui explorer and extension
        /// if url is a ipfs image, this image is showed on sui explorer and extension
        name: String,
        url: Url,
    }

    // TODO: this struct has only 1 field, consider removing it
    // TODO: we don't know the address of owner in SC
    struct RegistrationDetail has store, drop {
        expiry: u64,
        owner: address,
        nft_id: ID,
    }

    /// Mapping domain name to registration record (instance of `RegistrationDetail`).
    /// Each record is a dynamic field of this share object,.
    struct BaseRegistrar has key {
        id: UID,
        tld: String,
        /// base_node represented in byte array
        tld_bytes: vector<u8>,
    }

    /// list of all TLD managed by this registrar
    struct TLDList has key {
        id: UID,
        tlds: vector<String>,
    }

    /// #### Notice
    /// The admin uses this function to create a new `BaseRegistrar` share object
    /// that manages domains having the same top level domain.
    ///
    ///
    /// #### Params
    /// `new_tld`: the TLD that this new share object manages.
    ///
    /// Panic
    /// Panic if this TLD already exists.
    public entry fun new_tld(
        _: &AdminCap,
        tld_list: &mut TLDList,
        new_tld: vector<u8>,
        ctx: &mut TxContext,
    ) {
        let tld_str = string::utf8(new_tld);
        let len = vector::length(&tld_list.tlds);
        let index = 0;

        while (index < len) {
            let existed_tld = vector::borrow(&tld_list.tlds, index);
            assert!(*existed_tld != tld_str, ETLDExists);
            index = index + 1;
        };

        vector::push_back(&mut tld_list.tlds, tld_str);
        transfer::share_object(BaseRegistrar {
            id: object::new(ctx),
            tld: tld_str,
            tld_bytes: new_tld,
        });
    }

    /// #### Notice
    /// The owner of the NFT uses this function to change the `owner` property of the
    /// corresponding name record stored in the `Registry`.
    ///
    /// #### Params
    /// `owner`: new owner address of name record.
    ///
    /// Panic
    /// Panic if the NFT no longer exists
    /// or the NFT expired.
    public entry fun reclaim_name(
        registrar: &BaseRegistrar,
        registry: &mut Registry,
        nft: &RegistrationNFT,
        owner: address,
        ctx: &mut TxContext,
    ) {
        validate_nft(registrar, nft, ctx);

        let label = get_label_part(&nft.name, &registrar.tld);
        let registration = field::borrow<String, RegistrationDetail>(&registrar.id, label);
        assert!(registration.expiry >= epoch(ctx), ELabelExpired);

        base_registry::set_owner_internal(registry, nft.name, owner);
        event::emit(NameReclaimedEvent {
            node: nft.name,
            owner,
        })
    }

    /// #### Notice
    /// The owner of the NFT uses this function to update `url` field of his/her NFT.
    /// The `signature`, `raw_msg` and `raw_msg` are generated by our Backend only.
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
        registrar: &BaseRegistrar,
        config: &Configuration,
        nft: &mut RegistrationNFT,
        signature: vector<u8>,
        hashed_msg: vector<u8>,
        raw_msg: vector<u8>,
        ctx: &mut TxContext,
    ) {
        // TODO: move to a separate module
        assert!(
            !vector::is_empty(&signature)
                && !vector::is_empty(&hashed_msg)
                && !vector::is_empty(&raw_msg),
            EInvalidMessage
        );
        validate_nft(registrar, nft, ctx);
        assert!(sha2_256(raw_msg) == hashed_msg, EHashedMessageNotMatch);
        assert!(
            ecdsa_k1::secp256k1_verify(&signature, configuration::public_key(config), &hashed_msg),
            ESignatureNotMatch
        );

        let (ipfs, node_msg, expiry) = remove_later::deserialize_image_msg(raw_msg);

        assert!(node_msg == nft.name, EInvalidMessage);

        let label = get_label_part(&nft.name, &registrar.tld);

        assert!(expiry == name_expires_at(registrar, label), EInvalidMessage);

        nft.url = url::new_unsafe_from_bytes(*string::bytes(&ipfs));
        event::emit(ImageUpdatedEvent {
            sender: sender(ctx),
            node: nft.name,
            new_image: nft.url,
        })
    }

    // === Public Functions ===

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
    public fun is_available(registrar: &BaseRegistrar, label: String, ctx: &TxContext): bool {
        let expiry = name_expires_at(registrar, label);
        if (expiry != 0) {
            return expiry + (GRACE_PERIOD as u64) < epoch(ctx)
        };
        true
    }

    /// #### Notice
    /// Check if node derived from `label` and `registrar.tld` is expired.
    ///
    /// #### Params
    /// `label`: label to be checked
    ///
    /// #### Returns:
    /// true if this node expired
    /// false if it's not
    public fun is_expired(registrar: &BaseRegistrar, label: String, ctx: &TxContext): bool {
        let expiry = name_expires_at(registrar, label);
        if (expiry != 0) {
            return expiry < epoch(ctx)
        };
        true
    }

    // TODO: every functions that take RegistrationNFT must call this
    /// #### Notice
    /// Validate if `nft` is valid or not.
    ///
    /// #### Params
    /// `nft`: NFT to be checked
    ///
    /// Panic
    /// Panic if the NFT is longer stored in SC
    /// or the the data of the NFT mismatches the data stored in SC
    /// or the NFTs expired.
    public fun validate_nft(registrar: &BaseRegistrar, nft: &RegistrationNFT, ctx: &mut TxContext) {
        let label = get_label_part(&nft.name, &registrar.tld);
        let detail = field::borrow<String, RegistrationDetail>(&registrar.id, label);
        // TODO: delete NFT if it expired
        assert!(detail.owner == sender(ctx), ENFTExpired);
        assert!(detail.nft_id == uid_to_inner(&nft.id), ENFTExpired);
        assert!(!is_expired(registrar, label, ctx), ENFTExpired);
    }

    /// #### Notice
    /// Returns the epoch after which the `label` is expired.
    ///
    /// #### Params
    /// `label`: label to be checked
    ///
    /// #### Returns
    /// 0: if `label` expired
    /// otherwise: the expiration date
    public fun name_expires_at(registrar: &BaseRegistrar, label: String): u64 {
        if (field::exists_with_type<String, RegistrationDetail>(&registrar.id, label)) {
            return field::borrow<String, RegistrationDetail>(&registrar.id, label).expiry
        };
        0
    }

    public fun base_node(registrar: &BaseRegistrar): String {
        registrar.tld
    }

    public fun base_node_bytes(registrar: &BaseRegistrar): vector<u8> {
        registrar.tld_bytes
    }

    // === Friend and Private Functions ===

    /// label can have multiple levels, e.g. 'dn.suins' or 'suins'
    /// this function doesn't charge fee
    public(friend) fun register(
        registrar: &mut BaseRegistrar,
        registry: &mut Registry,
        config: &Configuration,
        label: vector<u8>,
        owner: address,
        duration: u64,
        resolver: address,
        ctx: &mut TxContext
    ): ID {
        let (nft_id, _url) = register_with_image(
            registrar,
            registry,
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
        registrar: &mut BaseRegistrar,
        registry: &mut Registry,
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
        assert!(is_available(registrar, label, ctx), ELabelUnAvailable);

        let expiry = epoch(ctx) + duration;
        let node = label;
        string::append_utf8(&mut node, b".");
        string::append(&mut node, registrar.tld);

        let url;
        if (vector::is_empty(&hashed_msg) || vector::is_empty(&raw_msg) || vector::is_empty(&signature))
            url = url::new_unsafe_from_bytes(b"ipfs://QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY")
        else {
            assert!(sha2_256(raw_msg) == hashed_msg, EHashedMessageNotMatch);
            assert!(
                ecdsa_k1::secp256k1_verify(&signature, configuration::public_key(config), &hashed_msg),
                ESignatureNotMatch
            );

            let (ipfs, node_msg, expiry_msg) = remove_later::deserialize_image_msg(raw_msg);

            assert!(node_msg == node, EInvalidMessage);
            assert!(expiry_msg == expiry, EInvalidMessage);

            url = url::new_unsafe(string::to_ascii(ipfs));
        };

        let nft = RegistrationNFT {
            id: object::new(ctx),
            name: node,
            url,
        };
        let nft_id = object::uid_to_inner(&nft.id);
        let detail = RegistrationDetail { expiry, owner, nft_id };

        if (field::exists_with_type<String, RegistrationDetail>(&registrar.id, label)) {
            // this `label` is available for registration again
            field::remove<String, RegistrationDetail>(&mut registrar.id, label);
        };

        field::add(&mut registrar.id, label, detail);
        transfer::transfer(nft, owner);
        base_registry::set_record_internal(registry, node, owner, resolver, 0);

        (nft_id, url)
    }

    /// this function doesn't charge fee
    /// intended to be called by `Controller`
    public(friend) fun renew(registrar: &mut BaseRegistrar, label: vector<u8>, duration: u64, ctx: &TxContext): u64 {
        let label = string::utf8(label);
        let expiry = name_expires_at(registrar, label);

        assert!(expiry > 0, ELabelNotExists);
        assert!(expiry + (GRACE_PERIOD as u64) >= epoch(ctx), ELabelExpired);

        let detail: &mut RegistrationDetail = field::borrow_mut(&mut registrar.id, label);
        detail.expiry = detail.expiry + duration;

        event::emit(NameRenewedEvent { label, expiry: detail.expiry });
        detail.expiry
    }

    fun get_label_part(node: &String, tld: &String): String {
        let index_of_dot = string::index_of(node, tld);
        assert!(index_of_dot == string::length(node) - string::length(tld), EInvalidBaseNode);

        string::sub_string(node, 0, index_of_dot - 1)
    }

    fun init(ctx: &mut TxContext) {
        transfer::share_object(TLDList {
            id: object::new(ctx),
            tlds: vector::empty<String>(),
        });
    }

    // === Testing ===

    #[test_only]
    friend suins::base_registrar_tests;

    #[test_only]
    public fun record_exists(registrar: &BaseRegistrar, label: String): bool {
        field::exists_with_type<String, RegistrationDetail>(&registrar.id, label)
    }

    #[test_only]
    public fun get_nft_fields(nft: &RegistrationNFT): (String, Url) {
        (nft.name, nft.url)
    }

    #[test_only]
    public fun get_tlds(tlds: &TLDList): &vector<String> {
        &tlds.tlds
    }

    #[test_only]
    public fun get_registrar(registrar: &BaseRegistrar): (&String, &vector<u8>, &UID) {
        (&registrar.tld, &registrar.tld_bytes, &registrar.id)
    }

    #[test_only]
    public fun get_registration_expiry(detail: &RegistrationDetail): u64 {
        detail.expiry
    }

    #[test_only]
    public fun get_registration_owner(detail: &RegistrationDetail): address {
        detail.owner
    }

    #[test_only]
    public fun set_nft_domain(nft: &mut RegistrationNFT, new_domain: String) {
        nft.name = new_domain;
    }

    #[test_only]
    /// Wrapper of module initializer for testing
    public fun test_init(ctx: &mut TxContext) {
        transfer::share_object(TLDList {
            id: object::new(ctx),
            tlds: vector::empty<String>(),
        });
    }
}
