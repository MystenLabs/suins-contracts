module suins::base_registry {
    use sui::event;
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::table::{Self, Table};
    use sui::tx_context::{Self, TxContext};
    use std::string::{Self, String};

    friend suins::base_registrar;
    friend suins::reverse_registrar;
    friend suins::controller;
    friend suins::resolver;

    const MAX_TTL: u64 = 0x100000;

    // errors in the range of 101..200 indicate Registry errors
    const EUnauthorized: u64 = 101;

    // https://examples.sui.io/patterns/capability.html
    struct AdminCap has key, store { id: UID }

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
        node: String,
        owner: address,
        resolver: address,
        ttl: u64,
    }

    // objects of this type are stored in the registry's map
    struct Record has store, copy, drop {
        owner: address,
        resolver: address,
        ttl: u64,
    }

    struct Registry has key {
        id: UID,
        records: Table<String, Record>,
    }

    fun init(ctx: &mut TxContext) {
        transfer::share_object(Registry {
            id: object::new(ctx),
            records: table::new(ctx),
        });
        transfer::transfer(AdminCap {
            id: object::new(ctx)
        }, tx_context::sender(ctx));
    }

    public fun owner(registry: &Registry, node: vector<u8>): address {
        table::borrow(&registry.records, string::utf8(node)).owner
    }

    public fun resolver(registry: &Registry, node: vector<u8>): address {
        table::borrow(&registry.records, string::utf8(node)).resolver
    }

    public fun ttl(registry: &Registry, node: vector<u8>): u64 {
        table::borrow(&registry.records, string::utf8(node)).ttl
    }

    // returns (owner, resolver, ttl)
    public fun get_record_by_key(registry: &Registry, key: String): (address, address, u64) {
        let record = table::borrow(&registry.records, key);
        (record.owner, record.resolver, record.ttl)
    }

    // TODO: subdomain
    /// Change ownner of subdomain, can only be called by node's owner
    public entry fun set_subnode_owner(
        registry: &mut Registry,
        node: vector<u8>,
        label: vector<u8>,
        owner: address,
        ctx: &mut TxContext,
    ) {
        // required both node and subnode to exist
        authorised(registry, node, ctx);

        let subnode = make_node(label, string::utf8(node));
        set_owner_internal(registry, subnode, owner);
        event::emit(NewOwnerEvent { node: subnode, owner });
    }

    public entry fun set_owner(registry: &mut Registry, node: vector<u8>, owner: address, ctx: &mut TxContext) {
        authorised(registry, node, ctx);

        let node = string::utf8(node);
        set_owner_internal(registry, node, owner);
        event::emit(NewOwnerEvent { node, owner });
    }

    public entry fun set_resolver(registry: &mut Registry, node: vector<u8>, resolver: address, ctx: &mut TxContext) {
        authorised(registry, node, ctx);

        let node = string::utf8(node);
        let record = table::borrow_mut(&mut registry.records, node);
        record.resolver = resolver;
        event::emit(NewResolverEvent { node, resolver });
    }

    public entry fun set_TTL(registry: &mut Registry, node: vector<u8>, ttl: u64, ctx: &mut TxContext) {
        authorised(registry, node, ctx);

        let node = string::utf8(node);
        let record = table::borrow_mut(&mut registry.records, node);
        record.ttl = ttl;
        event::emit(NewTTLEvent { node, ttl });
    }

    public(friend) fun set_owner_internal(registry: &mut Registry, node: String, owner: address) {
        let record = table::borrow_mut(&mut registry.records, node);
        record.owner = owner;
    }

    public(friend) fun make_node(label: vector<u8>, base_node: String): String {
        let node = string::utf8(label);
        string::append_utf8(&mut node, b".");
        string::append(&mut node, base_node);
        node
    }

    // this func is meant to be call by registrar, no need to check for owner
    public(friend) fun set_record_internal(
        registry: &mut Registry,
        node: String,
        owner: address,
        resolver: address,
        ttl: u64,
    ) {
        if (table::contains(&registry.records, node)) {
            let record = table::borrow_mut(&mut registry.records, node);
            record.owner = owner;
            record.resolver = resolver;
            record.ttl = ttl;
        } else new_record(registry, node, owner, resolver, ttl);
    }

    public(friend) fun authorised(registry: &Registry, node: vector<u8>, ctx: &TxContext) {
        let owner = owner(registry, node);
        assert!(tx_context::sender(ctx) == owner, EUnauthorized);
    }

    fun new_record(
        registry: &mut Registry,
        node: String,
        owner: address,
        resolver: address,
        ttl: u64,
    ) {
        let record = Record {
            owner,
            resolver,
            ttl,
        };
        table::add(&mut registry.records, node, record)
    }

    #[test_only]
    friend suins::base_registry_tests;
    #[test_only]
    friend suins::resolver_tests;

    #[test_only]
    public fun get_records_len(registry: &Registry): u64 { table::length(&registry.records) }

    #[test_only]
    public fun get_record_owner(record: &Record): address { record.owner }

    #[test_only]
    public fun get_record_resolver(record: &Record): address { record.resolver }

    #[test_only]
    public fun get_record_ttl(record: &Record): u64 { record.ttl }

    #[test_only]
    public fun new_record_test(registry: &mut Registry, node: String, owner: address) {
        new_record(registry, node, owner, @0x0, 0);
    }

    #[test_only]
    public fun record_exists(registry: &Registry, node: String): bool {
        table::contains(&registry.records, node)
    }

    #[test_only]
    /// Wrapper of module initializer for testing
    public fun test_init(ctx: &mut TxContext) {
        // mimic logic in `init`
        transfer::share_object(Registry {
            id: object::new(ctx),
            records: table::new(ctx),
        });
        transfer::transfer(AdminCap {
            id: object::new(ctx)
        }, tx_context::sender(ctx));
    }
}
