module suins::base_registrar {
    use sui::event;
    use sui::object::{Self, ID, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::url::Url;
    use sui::table::{Self, Table};
    use std::string::{Self, String};
    use std::option;
    use std::vector;
    use suins::base_registry::{Self, Registry, AdminCap};
    use suins::configuration::{Self, Configuration};

    friend suins::controller;

    // in terms of epoch
    const GRACE_PERIOD: u8 = 90;
    const MAX_TTL: u64 = 0x100000;

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

    // send to owner of a domain, not store in registry
    struct RegistrationNFT has key, store {
        id: UID,
        // name and url fields have special meaning in sui explorer and extension
        // if url is a ipfs image, this image is showed on sui explorer and extension
        name: String,
        url: Url,
    }

    struct RegistrationDetail has store {
        expiry: u64,
    }
    
    struct BaseRegistrar has key {
        id: UID,
        base_node: String,
        // base_node represented in byte array
        base_node_bytes: vector<u8>,
        // key is label, e.g. 'eastagile', 'dn.eastagile'
        expiries: Table<String, RegistrationDetail>,
    }

    // list of all TLD managed by this registrar
    struct TLDsList has key {
        id: UID,
        tlds: vector<String>,
    }

    public entry fun new_tld(
        _: &AdminCap,
        tlds_list: &mut TLDsList,
        tld: vector<u8>,
        ctx: &mut TxContext,
    ) {
        let tld_str = string::utf8(tld);
        let len = vector::length(&tlds_list.tlds);
        let index = 0;
        while(index < len) {
            let existed_tld = vector::borrow(&tlds_list.tlds, index);
            assert!(*existed_tld != tld_str, ETLDExists);
            index = index + 1;
        };

        vector::push_back(&mut tlds_list.tlds, tld_str);
        transfer::share_object(BaseRegistrar {
            id: object::new(ctx),
            expiries: table::new(ctx),
            base_node: tld_str,
            base_node_bytes: tld,
        });
    }

    fun init(ctx: &mut TxContext) {
        transfer::share_object(TLDsList {
            id: object::new(ctx),
            tlds: vector::empty<String>(),
        });
    }

    public fun available(registrar: &BaseRegistrar, label: String, ctx: &TxContext): bool {
        let expiry = name_expires(registrar, label);
        if (expiry != 0 ) {
            return expiry + (GRACE_PERIOD as u64) < tx_context::epoch(ctx)
        };
        true
    }

    public fun name_expires(registrar: &BaseRegistrar, label: String): u64 {
        if (record_exists(registrar, label)) {
            // TODO: can return whole RegistrationDetail to not look up again
            return table::borrow(&registrar.expiries, label).expiry
        };
        0
    }

    // TODO: add an entry fun for domain owner to register a subdomain

    // label can be multiple levels, e.g. 'dn.eastagile' or 'eastagile'
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
        let label = string::try_utf8(label);
        assert!(option::is_some(&label), EInvalidLabel);
        let label = option::extract(&mut label);
        assert!(available(registrar, label, ctx), ELabelUnAvailable);
        assert!(duration > 0, EInvalidDuration);

        let url = configuration::get_url(config, duration, tx_context::epoch(ctx));
        let detail = RegistrationDetail {
            expiry: tx_context::epoch(ctx) + duration,
            owner,
        };
        table::add(&mut registrar.expiries, label, detail);
        let node = label;
        string::append_utf8(&mut node, b".");
        string::append(&mut node, registrar.base_node);

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

    public(friend) fun get_base_node(registrar: &BaseRegistrar): String {
        registrar.base_node
    }

    public(friend) fun get_base_node_bytes(registrar: &BaseRegistrar): vector<u8> {
        registrar.base_node_bytes
    }

    public(friend) fun renew(registrar: &mut BaseRegistrar, label: vector<u8>, duration: u64, ctx: &TxContext): u64 {
        let label = string::utf8(label);
        let expiry = name_expires(registrar, label);
        assert!(expiry > 0, ELabelNotExists);
        assert!(expiry + (GRACE_PERIOD as u64) >= tx_context::epoch(ctx), ELabelExpired);

        let detail = table::borrow_mut(&mut registrar.expiries, label);
        detail.expiry = detail.expiry + duration;

        event::emit(NameRenewedEvent { label, expiry: detail.expiry });
        detail.expiry
    }

    public entry fun reclaim_by_nft_owner(
        registrar: &BaseRegistrar,
        registry: &mut Registry,
        nft: &RegistrationNFT,
        owner: address,
        ctx: &mut TxContext,
    ) {
        let index_of_dot = string::index_of(&nft.name, &string::utf8(b"."));
        let base_node = string::sub_string(&nft.name, index_of_dot + 1, string::length(&nft.name));
        assert!(registrar.base_node == base_node, EInvalidBaseNode);

        let label = string::sub_string(&nft.name, 0, index_of_dot);
        if (!record_exists(registrar, label)) abort ELabelNotExists;
        let registration = table::borrow(&registrar.expiries, label);
        if (registration.expiry < tx_context::epoch(ctx)) abort ELabelExpired;

        // TODO: delete NFT if it expired
        base_registry::set_owner_internal(registry, nft.name, owner);
        event::emit(NameReclaimedEvent {
            node: nft.name,
            owner,
        })
    }

    public fun record_exists(registrar: &BaseRegistrar, label: String): bool {
        table::contains(&registrar.expiries, label)
    }

    #[test_only]
    friend suins::base_registrar_tests;

    #[test_only]
    public fun get_nft_fields(nft: &RegistrationNFT): (String, Url) {
        (nft.name, nft.url)
    }

    #[test_only]
    public fun get_tlds(tlds: &TLDsList): &vector<String> {
        &tlds.tlds
    }

    #[test_only]
    public fun get_registrar(registrar: &BaseRegistrar): (&String, &vector<u8>, &Table<String, RegistrationDetail>) {
        (&registrar.base_node, &registrar.base_node_bytes, &registrar.expiries)
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
        init(ctx)
    }
}
