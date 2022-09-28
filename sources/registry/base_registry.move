module suins::base_registry {
    use sui::event;
    use sui::object::{Self, UID, ID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::url::{Self, Url};
    use sui::vec_map;
    use std::option::{Self, Option};
    use std::string::{Self, String};

    friend suins::sui_registrar;

    // TODO: we don't have suins image atm, so temporarily use sui image instead
    const DEFAULT_URL: vector<u8> = b"ipfs://bafkreibngqhl3gaa7daob4i2vccziay2jjlp435cf66vhono7nrvww53ty";
    const MOVE_BASE_NODE: vector<u8> = b"move";
    const SUI_BASE_NODE: vector<u8> = b"sui";
    const MAX_TTL: u64 = 0x100000;

    // errors in the range of 101..200 indicate Registry errors
    const EUnauthorized: u64 = 101;

    // https://examples.sui.io/patterns/capability.html
    struct AdminCap has key { id: UID }

    struct TransferEvent has copy, drop {
        node: String,
        owner: address,
    }

    struct NewOwnerEvent has copy, drop {
        node: String,
        owner: address,
    }

    struct NewResolverEvent has copy, drop {
        node: String,
        resolver: address,
    }

    struct NewTTLEvent has copy, drop {
        node: String,
        ttl: u64,
    }

    struct NewRecordEvent has copy, drop {
        id: ID,
        node: String,
        owner: address,
        resolver: address,
        ttl: u64,
    }

    // send to owner of a domain, not store in registry
    struct RegistrationNFT has key, store {
        id: UID,
        // name and url fields have special meaning in sui explorer and extension
        // if url is a ipfs image, this image is showed on sui explorer and extension
        name: String,
        url: Url,
    }

    // objects of this type are stored in the registry's map
    struct Record has store, drop {
        node: String,
        owner: address,
        resolver: address,
        ttl: u64,
        // id of the issued RegistrationNFT
        nft_id: ID,
    }

    struct Registry has key {
        id: UID,
        records: vec_map::VecMap<String, Record>,
    }

    fun init(ctx: &mut TxContext) {
        let registry = Registry {
            id: object::new(ctx),
            records: vec_map::empty(),
        };
        // insert .sui TLD nodes
        new_record(
            &mut registry,
            string::utf8(SUI_BASE_NODE),
            tx_context::sender(ctx),
            @0x0,
            MAX_TTL,
            url::new_unsafe_from_bytes(DEFAULT_URL),
            ctx,
        );
        transfer::share_object(registry);
        transfer::transfer(AdminCap {
            id: object::new(ctx)
        }, tx_context::sender(ctx));
    }

    public fun owner(registry: &Registry, node: vector<u8>): address {
        if (record_exists(registry, &string::utf8(node))) {
            return vec_map::get(&registry.records, &string::utf8(node)).owner
        };
        @0x0
    }

    public fun resolver(registry: &Registry, node: vector<u8>): address{
        if (record_exists(registry, &string::utf8(node))) {
            return vec_map::get(&registry.records, &string::utf8(node)).resolver
        };
        @0x0
    }

    public fun ttl(registry: &Registry, node: vector<u8>): u64{
        if (record_exists(registry, &string::utf8(node))) {
            return vec_map::get(&registry.records, &string::utf8(node)).ttl
        };
        0
    }

    public fun record_exists(registry: &Registry, node: &String): bool{
        vec_map::contains(&registry.records, node)
    }

    public fun get_NFT_node(nft: &RegistrationNFT): String { nft.name }

    // only registrar is allowed to call this
    public(friend) fun set_record(
        _: & AdminCap,
        registry: &mut Registry,
        node: vector<u8>,
        owner: address,
        resolver: address,
        ttl: u64,
        url: Option<Url>,
        ctx: &mut TxContext
    ) {
        let node = string::utf8(node);
        let _result = set_owner_or_create_record(
            registry,
            node,
            owner,
            option::some(resolver),
            option::some(ttl),
            url,
            ctx
        );
        // TODO: transfer node's NFT to new owner if result == true
        set_resolver_and_TTL(registry, node, resolver, ttl);
    }

    public(friend) fun set_subnode_record(
        _: & AdminCap,
        registry: &mut Registry,
        node: String,
        label: vector<u8>,
        owner: address,
        resolver: address,
        ttl: u64,
        url: Option<Url>,
        ctx: &mut TxContext
    ) {
        let subnode = make_subnode(label, node);
        let _result = set_owner_or_create_record(
            registry,
            subnode,
            owner,
            option::some(resolver),
            option::some(ttl),
            url,
            ctx
        );
        // TODO: transfer subnode NFT to new owner if result == true
        set_resolver_and_TTL(registry, subnode, resolver, ttl);
    }

    // need to take ownership of RecordNFT to be able to check and delete it
    public entry fun set_owner(registry: &mut Registry, nft: RegistrationNFT, owner: address) {
        assert!(record_exists(registry, &nft.name), EUnauthorized);
        let record = vec_map::get_mut(&mut registry.records, &nft.name);
        if (record.owner != owner) {
            record.owner = owner;
            event::emit(TransferEvent { node: nft.name, owner });
        };
        transfer::transfer(nft, owner)
    }

    public entry fun set_subnode_owner(
        registry: &mut Registry,
        nft: &RegistrationNFT,
        label: vector<u8>,
        owner: address,
        ctx: &mut TxContext,
    ) {
        assert!(record_exists(registry, &nft.name), EUnauthorized);
        let subnode = make_subnode(label, nft.name);
        set_owner_or_create_record(
            registry,
            subnode,
            owner,
            option::none<address>(),
            option::none<u64>(),
            option::none<Url>(),
            ctx,
        );
        // TODO: transfer subnode NFT to new owner if result == true
    }

    public entry fun set_resolver(registry: &mut Registry, nft: &RegistrationNFT, resolver: address) {
        assert!(record_exists(registry, &nft.name), EUnauthorized);

        let record = vec_map::get_mut(&mut registry.records, &nft.name);
        if (record.resolver != resolver) {
            record.resolver = resolver;
            event::emit(NewResolverEvent { node: record.node, resolver });
        };
    }

    public entry fun set_TTL(registry: &mut Registry, nft: &RegistrationNFT, ttl: u64) {
        assert!(record_exists(registry, &nft.name), EUnauthorized);

        let record = vec_map::get_mut(&mut registry.records, &nft.name);
        if (record.ttl != ttl) {
            record.ttl = ttl;
            event::emit(NewTTLEvent { node: record.node, ttl });
        };
    }

    fun set_resolver_and_TTL(registry: &mut Registry, node: String, resolver: address, ttl: u64) {
        let record = vec_map::get_mut(&mut registry.records, &node);

        if (record.resolver != resolver) {
            record.resolver = resolver;
            event::emit(NewResolverEvent { node, resolver });
        };

        if (record.ttl != ttl) {
            record.ttl = ttl;
            event::emit(NewTTLEvent { node, ttl });
        };
    }

    // return value == true: node is in Registry, the NFT must be transfered to new owner if have one
    // return value == false: the NFT is expired and must be deleted if have one
    fun set_owner_or_create_record(
        registry: &mut Registry,
        node: String,
        owner: address,
        resolver: Option<address>,
        ttl: Option<u64>,
        url: Option<Url>,
        ctx: &mut TxContext
    ): bool {
        if (vec_map::contains(&registry.records, &node)) {
            let record = vec_map::get_mut(&mut registry.records, &node);
            record.owner = owner;
            return true
        };
        if (option::is_none(&resolver)) option::fill(&mut resolver, @0x0);
        if (option::is_none(&ttl)) option::fill(&mut ttl, 0);
        if (option::is_none(&url)) option::fill(&mut url, url::new_unsafe_from_bytes(DEFAULT_URL));
        new_record(
            registry,
            node,
            owner,
            option::extract(&mut resolver),
            option::extract(&mut ttl),
            option::extract(&mut url),
            ctx
        );
        false
    }

    fun new_record(
        registry: &mut Registry,
        node: String,
        owner: address,
        resolver: address,
        ttl: u64,
        url: Url,
        ctx: &mut TxContext
    ) {
        // create a new NFT and sent to owner
        let nft = RegistrationNFT {
            id: object::new(ctx),
            name: node,
            url,
        };
        let record = Record {
            node,
            owner,
            resolver,
            ttl,
            nft_id: object::id(&nft),
        };

        event::emit(NewRecordEvent {
            id: object::id(&nft),
            node,
            owner,
            resolver,
            ttl,
        });
        vec_map::insert(&mut registry.records, record.node, record);
        transfer::transfer(nft, owner);
    }

    fun make_subnode(label: vector<u8>, node: String): String {
        let subnode = string::utf8(label);
        string::append(&mut subnode, string::utf8(b"."));
        string::append(&mut subnode, node);
        subnode
    }

    #[test_only]
    public fun get_record_at_index(registry: &Registry, index: u64): (&String, &Record) {
        vec_map::get_entry_by_idx(&registry.records, index)
    }

    #[test_only]
    public fun delete_record_by_key(registry: &mut Registry, node: String): (String, Record) {
        vec_map::remove(&mut registry.records, &node)
    }

    #[test_only]
    friend suins::base_registry_tests;

    #[test_only]
    public fun get_registry_len(registry: &Registry): u64 { vec_map::size(&registry.records) }

    #[test_only]
    public fun get_record_node(record: &Record): String { record.node }

    #[test_only]
    public fun get_record_owner(record: &Record): address { record.owner }

    #[test_only]
    public fun get_record_resolver(record: &Record): address { record.resolver }

    #[test_only]
    public fun get_record_ttl(record: &Record): u64 { record.ttl }

    #[test_only]
    /// Wrapper of module initializer for testing
    public fun test_init(ctx: &mut TxContext) { init(ctx) }
}
