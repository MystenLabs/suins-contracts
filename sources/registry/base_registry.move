module suins::base_registry {
    use sui::event;
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::url::{Self, Url};
    use sui::vec_map;
    use std::string;
    use std::option::Option;
    use std::option;

    // TODO: we don't have suins image atm, so temporarily use sui image instead
    const DEFAULT_URL: vector<u8> = b"ipfs://bafkreibngqhl3gaa7daob4i2vccziay2jjlp435cf66vhono7nrvww53ty";

    // errors in the range of 101..200 indicate Registry errors
    const EUnauthorized: u64 = 101;

    // https://examples.sui.io/patterns/capability.html
    struct AdminCap has key { id: UID }

    struct TransferEvent has copy, drop {
        node: string::String,
        owner: address,
    }

    struct NewOwnerEvent has copy, drop {
        node: string::String,
        owner: address,
    }

    struct NewResolverEvent has copy, drop {
        node: string::String,
        resolver: address,
    }

    struct NewTTLEvent has copy, drop {
        node: string::String,
        ttl: u64,
    }

    struct NewRecordEvent has copy, drop {
        node: string::String,
        owner: address,
        resolver: address,
        ttl: u64,
    }

    // send to owner of a domain, not store in registry
    struct RecordNFT has key {
        id: UID,
        node: string::String,
        owner: address,
        resolver: address,
        ttl: u64,
        // name and url fields have special meaning in sui explorer and extension
        // if url is a ipfs image, this image is showed on sui explorer and extension
        url: Url,
    }

    // objects of this type are stored in the registry's map
    struct Record has store, drop {
        node: string::String,
        owner: address,
        resolver: address,
        ttl: u64,
    }

    struct Registry has key {
        id: UID,
        records: vec_map::VecMap<string::String, Record>,
    }

    fun init(ctx: &mut TxContext) {
        transfer::transfer(AdminCap {
            id: object::new(ctx)
        }, tx_context::sender(ctx));

        transfer::share_object(Registry {
            id: object::new(ctx),
            records: vec_map::empty(),
        });
    }

    public(friend) fun get_registry_len(registry: &Registry): u64 {
        vec_map::size(&registry.records)
    }

    public(friend) fun get_recordNFT_node(record: &RecordNFT): string::String {
        record.node
    }

    public(friend) fun get_recordNFT_owner(record: &RecordNFT): address {
        record.owner
    }

    public(friend) fun get_recordNFT_resolver(record: &RecordNFT): address {
        record.resolver
    }

    public(friend) fun get_recordNFT_ttl(record: &RecordNFT): u64 {
        record.ttl
    }

    public(friend) fun get_record_node(record: &Record): string::String {
        record.node
    }

    public(friend) fun get_record_owner(record: &Record): address {
        record.owner
    }

    public(friend) fun get_record_resolver(record: &Record): address {
        record.resolver
    }

    public(friend) fun get_record_ttl(record: &Record): u64 {
        record.ttl
    }

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
        if (vec_map::contains(&registry.records, &node)) {
            // TODO: find a way to transfer RecordNFT to new owner if record existed
            set_record_(registry, node, owner, resolver, ttl);
            return
        };

        let record = Record {
            node,
            owner,
            resolver,
            ttl
        };
        vec_map::insert(&mut registry.records, record.node, record);

        if (option::is_none(&url)) option::fill(&mut url, url::new_unsafe_from_bytes(DEFAULT_URL));
        let recordNFT = RecordNFT {
            id: object::new(ctx),
            node,
            owner,
            resolver,
            ttl,
            url: option::extract(&mut url),
        };
        transfer::transfer(recordNFT, owner);
        event::emit(NewRecordEvent {
            node,
            owner,
            resolver,
            ttl,
        })
    }

    public entry fun set_owner(registry: &mut Registry, record: RecordNFT, owner: address) {
        set_owner_(registry, record.node, owner);
        record.owner = owner;
        transfer::transfer(record, owner);
    }

    public entry fun set_resolver(registry: &mut Registry, record: &mut RecordNFT, resolver: address) {
        set_resolver_(registry, record.node, resolver);
        record.resolver = resolver;
    }

    public entry fun set_TTL(registry: &mut Registry, record: &mut RecordNFT, ttl: u64) {
        set_TTL_(registry, record.node, ttl);
        record.ttl = ttl;
    }

    fun set_owner_(registry: &mut Registry, node: string::String, owner: address) {
        let record = vec_map::get_mut(&mut registry.records, &node);
        if (record.owner != owner) {
            record.owner = owner;
            event::emit(NewOwnerEvent { node, owner });
        };
    }

    fun set_resolver_(registry: &mut Registry, node: string::String, resolver: address) {
        let record = vec_map::get_mut(&mut registry.records, &node);
        if (record.resolver != resolver) {
            record.resolver = resolver;
            event::emit(NewResolverEvent { node, resolver });
        };
    }

    fun set_TTL_(registry: &mut Registry, node: string::String, ttl: u64) {
        let record = vec_map::get_mut(&mut registry.records, &node);
        if (record.ttl != ttl) {
            record.ttl = ttl;
            event::emit(NewTTLEvent { node, ttl });
        };
    }

    fun set_record_(registry: &mut Registry, node: string::String, owner: address, resolver: address, ttl: u64) {
        let record = vec_map::get_mut(&mut registry.records, &node);
        if (record.owner != owner) {
            record.owner = owner;
            event::emit(NewOwnerEvent { node, owner });
        };

        if (record.resolver != resolver) {
            record.resolver = resolver;
            event::emit(NewResolverEvent { node, resolver });
        };

        if (record.ttl != ttl) {
            record.ttl = ttl;
            event::emit(NewTTLEvent { node, ttl });
        };
    }


    #[test_only]
    public(friend) fun get_record_at_index(registry: &mut Registry, index: u64): (&string::String, &Record) {
        vec_map::get_entry_by_idx(&registry.records, index)
    }

    #[test_only]
    friend suins::registry_tests;
    #[test_only]
    /// Wrapper of module initializer for testing
    public fun test_init(ctx: &mut TxContext) {
        init(ctx)
    }
}
