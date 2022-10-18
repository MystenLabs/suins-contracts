module suins::sui_registrar {
    use sui::event;
    use sui::object::{Self, ID, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::url::Url;
    use sui::vec_map::{Self, VecMap};
    use suins::base_registry::{Self, Registry, AdminCap};
    use std::string::{Self, String};
    use std::option;

    friend suins::sui_controller;

    const BASE_NODE: vector<u8> = b"sui";
    // in terms of epoch
    const GRACE_PERIOD: u8 = 90;

    // errors in the range of 201..300 indicate Registrar errors
    const EInvalidLabel: u64 = 203;
    const ELabelUnAvailable: u64 = 204;
    const ELabelExpired: u64 = 205;
    const EInvalidDuration: u64 = 206;
    const ELabelNotExists: u64 = 207;

    struct NameRegisteredEvent has copy, drop {
        nft_id: ID,
        resolver: address,
        node: String,
        label: String,
        owner: address,
        expiry: u64,
    }

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

    struct SuiRegistrar has key {
        id: UID,
        // key is label, e.g. 'eastagile', 'dn.eastagile'
        expiries: VecMap<String, RegistrationDetail>,
    }

    fun init(ctx: &mut TxContext) {
        transfer::share_object(SuiRegistrar {
            id: object::new(ctx),
            expiries: vec_map::empty(),
        });
    }

    public fun available(registrar: &SuiRegistrar, label: String, ctx: &TxContext): bool {
        let expiry = name_expires(registrar, label);
        if (expiry != 0 ) {
            return expiry + (GRACE_PERIOD as u64) < tx_context::epoch(ctx)
        };
        true
    }

    public fun name_expires(registrar: &SuiRegistrar, label: String): u64 {
        if (record_exists(registrar, label)) {
            // TODO: can return whole RegistrationDetail to not look up again
            return vec_map::get(&registrar.expiries, &label).expiry
        };
        0
    }

    // TODO: add an entry fun for domain owner to register a subdomain

    // label can be multiple levels, e.g. 'dn.eastagile' or 'eastagile'
    public(friend) fun register(
        registrar: &mut SuiRegistrar,
        registry: &mut Registry,
        label: vector<u8>,
        owner: address,
        duration: u64,
        resolver: address,
        url: Url,
        ctx: &mut TxContext
    ) {
        let nft_id = register_internal(registrar, registry, label, owner, duration, resolver, true, url, ctx);
        event::emit(NameRegisteredEvent {
            nft_id,
            resolver,
            node: string::utf8(BASE_NODE),
            label: string::utf8(label),
            owner,
            expiry: tx_context::epoch(ctx) + duration,
        })
    }

    public(friend) fun register_only(
        registrar: &mut SuiRegistrar,
        registry: &mut Registry,
        label: vector<u8>,
        owner: address,
        duration: u64,
        resolver: address,
        url: Url,
        ctx: &mut TxContext
    ) {
        let nft_id = register_internal(registrar, registry, label, owner, duration, resolver, false, url, ctx);
        event::emit(NameRegisteredEvent {
            nft_id,
            resolver,
            node: string::utf8(BASE_NODE),
            label: string::utf8(label),
            owner,
            expiry: tx_context::epoch(ctx) + duration,
        })
    }

    public(friend) fun renew(registrar: &mut SuiRegistrar, label: vector<u8>, duration: u64, ctx: &TxContext): u64 {
        let label = string::utf8(label);
        let expiry = name_expires(registrar, label);
        assert!(expiry > 0, ELabelNotExists);
        assert!(expiry + (GRACE_PERIOD as u64) >= tx_context::epoch(ctx), ELabelExpired);

        let detail = vec_map::get_mut(&mut registrar.expiries, &label);
        detail.expiry = detail.expiry + duration;

        event::emit(NameRenewedEvent { label, expiry: detail.expiry });
        detail.expiry
    }

    public entry fun set_resolver(_: &AdminCap, registry: &mut Registry, resolver: address, ctx: &mut TxContext) {
        base_registry::set_resolver(registry, BASE_NODE, resolver, ctx);
    }

    // check for expiry
    public entry fun reclaim(
        registry: &mut Registry,
        label: vector<u8>,
        base_node: vector<u8>,
        owner: address,
        ctx: &mut TxContext
    ) {
        base_registry::authorised(registry, base_node, ctx);

        let node = base_registry::make_node(label, string::utf8(BASE_NODE));
        base_registry::set_owner_internal(registry, node, owner);
        event::emit(NameReclaimedEvent {
            node: string::utf8(base_node),
            owner,
        })
    }

    public entry fun reclaim_by_nft_owner(
        registry: &mut Registry,
        nft: &RegistrationNFT,
        owner: address,
    ) {
        // TODO: check if nft is expired or not
        base_registry::set_owner_internal(registry, nft.name, owner);
        event::emit(NameReclaimedEvent {
            node: nft.name,
            owner,
        })
    }

    fun register_internal(
        registrar: &mut SuiRegistrar,
        registry: &mut Registry,
        label: vector<u8>,
        owner: address,
        duration: u64,
        resolver: address,
        update_registry: bool,
        url: Url,
        ctx: &mut TxContext
    ): ID {
        let label = string::try_utf8(label);
        assert!(option::is_some(&label), EInvalidLabel);
        let label = option::extract(&mut label);
        assert!(available(registrar, label, ctx), ELabelUnAvailable);
        assert!(duration > 0, EInvalidDuration);

        let detail = RegistrationDetail {
            expiry: tx_context::epoch(ctx) + duration,
        };
        vec_map::insert(&mut registrar.expiries, label, detail);

        let node = label;
        string::append_utf8(&mut node, b".");
        string::append_utf8(&mut node, BASE_NODE);

        let nft = RegistrationNFT {
            id: object::new(ctx),
            name: node,
            url,
        };
        let nft_id = object::uid_to_inner(&nft.id);
        transfer::transfer(nft, owner);

        if (update_registry) base_registry::set_node_record_internal(registry, node, owner, resolver, 0);
        nft_id
    }

    public fun record_exists(registrar: &SuiRegistrar, label: String): bool {
        vec_map::contains(&registrar.expiries, &label)
    }

    fun is_owner(registry: &Registry, base_node: vector<u8>, ctx: &TxContext): bool {
        let owner = base_registry::owner(registry, base_node);
        let spender = tx_context::sender(ctx);
        spender == owner
    }

    #[test_only]
    friend suins::sui_registrar_tests;

    #[test_only]
    public fun get_nft_fields(nft: &RegistrationNFT): (String, Url) {
        (nft.name, nft.url)
    }

    #[test_only]
    /// Wrapper of module initializer for testing
    public fun test_init(ctx: &mut TxContext) {
        init(ctx)
    }
}
