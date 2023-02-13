/// Base structure for all kind of registrars except reverse one.
/// Call `new_tld` to setup new registrar.
/// All functions that involves payment charging in this module aren't supposed to be called directly,
/// users must call the corresponding functions in `Controller`.
module suins::base_registrar {
    use sui::event;
    use sui::object::{Self, ID, UID};
    use sui::transfer;
    use sui::tx_context::{TxContext, epoch, sender};
    use sui::url::Url;
    use sui::table::{Self, Table};
    use std::string::{Self, String, utf8};
    use std::option;
    use std::vector;
    use suins::base_registry::{Self, Registry, AdminCap};
    use suins::configuration::{Self, Configuration};
    use sui::ecdsa_k1;
    use suins::remove_later;
    use suins::converter;
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
    struct RegistrationDetail has store {
        expiry: u64,
    }

    struct BaseRegistrar has key {
        id: UID,
        tld: String,
        /// base_node represented in byte array
        tld_bytes: vector<u8>,
        /// key is label, e.g. 'eastagile', 'dn.eastagile'
        /// Registration record, each has its own name record in `Registry
        expiries: Table<String, RegistrationDetail>,
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
            expiries: table::new(ctx),
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
        let label = get_label_part(&nft.name, &registrar.tld);
        assert!(table::contains(&registrar.expiries, label), ELabelNotExists);
        let registration = table::borrow(&registrar.expiries, label);
        assert!(registration.expiry >= epoch(ctx), ELabelExpired);

        // TODO: delete NFT if it expired
        base_registry::set_owner_internal(registry, nft.name, owner);
        event::emit(NameReclaimedEvent {
            node: nft.name,
            owner,
        })
    }

    public entry fun update_image_url(
        registrar: &BaseRegistrar,
        config: &Configuration,
        nft: &mut RegistrationNFT,
        signature: vector<u8>,
        hashed_msg: vector<u8>,
        raw_msg: vector<u8>,
        ctx: &mut TxContext,
    ) {
        assert!(sha2_256(raw_msg) == hashed_msg, EHashedMessageNotMatch);
        assert!(ecdsa_k1::secp256k1_verify(&signature, configuration::public_key(config), &hashed_msg), ESignatureNotMatch);

        let (ipfs, owner, expiry) = remove_later::deserialize_image_msg(raw_msg);

        let sender = converter::address_to_string(sender(ctx));
        assert!(owner == utf8(sender), EInvalidMessage);

        let label = get_label_part(&nft.name, &registrar.tld);
        // TODO: allow to update image of expired domain or not? => No
        // assert!(expiry >= epoch(ctx), ELabelExpired);

        assert!(expiry == name_expires_at(registrar, label), EInvalidMessage);
        assert!(expiry > 0, ELabelNotExists);

        nft.url = url::new_unsafe_from_bytes(*string::bytes(&ipfs));
        event::emit(ImageUpdatedEvent {
            sender: sender(ctx),
            node: nft.name,
            new_image: nft.url,
        })
    }

    // === Public Functions ===

    /// #### Notice
    /// Check if `label` is available for registration.
    /// `label` has an extra `GRACE_PERIOD` time after the expiration date,
    /// during which it's consisered unavailable.
    /// This `GRACE_PERIOD` is for the current owner to have time to renew.
    ///
    /// #### Params
    /// `label`: label to be checked
    public fun available(registrar: &BaseRegistrar, label: String, ctx: &TxContext): bool {
        let expiry = name_expires_at(registrar, label);
        if (expiry != 0) {
            return expiry + (GRACE_PERIOD as u64) < epoch(ctx)
        };
        true
    }

    /// #### Notice
    /// Returns the epoch after which the `label` is expired.
    ///
    /// #### Params
    /// `label`: label to be checked
    ///
    /// #### Return
    /// 0: if `label` expired
    /// otherwise: the expiration date
    public fun name_expires_at(registrar: &BaseRegistrar, label: String): u64 {
        if (table::contains(&registrar.expiries, label)) {
            return table::borrow(&registrar.expiries, label).expiry
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
        register_with_image(
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
        )
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
    ): ID {
        // this isn't necessary `cause it's validated in Controller
        // assert!(
        //     !vector::is_empty(&signature)
        //         && !vector::is_empty(&hashed_msg)
        //         && !vector::is_empty(&raw_msg),
        //     EInvalidMessage
        // );
        assert!(duration > 0, EInvalidDuration);
        // TODO: label is already validated in Controller, consider removing this
        let label = string::try_utf8(label);
        assert!(option::is_some(&label), EInvalidLabel);
        let label = option::extract(&mut label);
        assert!(available(registrar, label, ctx), ELabelUnAvailable);

        let expiry = epoch(ctx) + duration;
        let detail = RegistrationDetail { expiry };
        table::add(&mut registrar.expiries, label, detail);

        let node = label;
        string::append_utf8(&mut node, b".");
        string::append(&mut node, registrar.tld);

        let url;
        if (vector::is_empty(&hashed_msg) || vector::is_empty(&raw_msg) || vector::is_empty(&signature))
            url = url::new_unsafe_from_bytes(vector[])
        else {
            assert!(sha2_256(raw_msg) == hashed_msg, EHashedMessageNotMatch);
            assert!(ecdsa_k1::secp256k1_verify(&signature, configuration::public_key(config), &hashed_msg), ESignatureNotMatch);

            let (ipfs, owner_msg, expiry_msg) = remove_later::deserialize_image_msg(raw_msg);

            let owner = converter::address_to_string(owner);
            assert!(owner_msg == utf8(owner), EInvalidMessage);
            assert!(expiry_msg == expiry, EInvalidMessage);

            url = url::new_unsafe(string::to_ascii(ipfs));
        };

        let nft = RegistrationNFT {
            id: object::new(ctx),
            name: node,
            url,
        };
        let nft_id = object::uid_to_inner(&nft.id);

        transfer::transfer(nft, owner);
        base_registry::set_record_internal(registry, node, owner, resolver, 0);

        nft_id
    }

    /// this function doesn't charge fee
    /// meant to be called by `Controller`
    public(friend) fun renew(registrar: &mut BaseRegistrar, label: vector<u8>, duration: u64, ctx: &TxContext): u64 {
        // TODO: update the image
        // TODO: add msg and signature parameter
        let label = string::utf8(label);
        let expiry = name_expires_at(registrar, label);

        assert!(expiry > 0, ELabelNotExists);
        assert!(expiry + (GRACE_PERIOD as u64) >= epoch(ctx), ELabelExpired);

        let detail = table::borrow_mut(&mut registrar.expiries, label);
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
        table::contains(&registrar.expiries, label)
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
    public fun get_registrar(registrar: &BaseRegistrar): (&String, &vector<u8>, &Table<String, RegistrationDetail>) {
        (&registrar.tld, &registrar.tld_bytes, &registrar.expiries)
    }

    #[test_only]
    public fun get_registration_detail(detail: &RegistrationDetail): u64 {
        detail.expiry
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
