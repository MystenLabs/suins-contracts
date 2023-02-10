/// Base structure for all kind of registrars except reverse one.
/// Call `new_tld` to setup new registrar.
/// All functions that involves payment charging in this module aren't supposed to be called directly,
/// users must call the corresponding functions in `Controller`.
module suins::base_registrar {
    use sui::event;
    use sui::object::{Self, ID, UID};
    use sui::transfer;
    use sui::tx_context::{TxContext, epoch};
    use sui::url::Url;
    use sui::table::{Self, Table};
    use std::string::{Self, String};
    use std::option;
    use std::vector;
    use suins::base_registry::{Self, Registry, AdminCap};
    use suins::configuration::{Self, Configuration};

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

    struct NameRenewedEvent has copy, drop {
        label: String,
        expiry: u64,
    }

    struct NameReclaimedEvent has copy, drop {
        node: String,
        owner: address,
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
        assert!(duration > 0, EInvalidDuration);
        // TODO: label is already validated in Controller, consider removing this
        let label = string::try_utf8(label);
        assert!(option::is_some(&label), EInvalidLabel);
        let label = option::extract(&mut label);
        assert!(available(registrar, label, ctx), ELabelUnAvailable);

        let detail = RegistrationDetail { expiry: epoch(ctx) + duration };
        table::add(&mut registrar.expiries, label, detail);

        let node = label;
        string::append_utf8(&mut node, b".");
        string::append(&mut node, registrar.tld);

        // TODO: no longer store image urls in contract. Now get it from caller and verify it
        let url = configuration::get_url(config, duration, epoch(ctx));
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
