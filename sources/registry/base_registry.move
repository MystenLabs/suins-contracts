module suins::base_registry {
    use sui::event;
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::url::{Self, Url};
    use sui::vec_map;
    use std::string;

    const MAX_TTL: u64 = 0x10000;
    const DEFAULT_TTL: u64 = 0;
    const DEFAULT_NAME: vector<u8> = b"suins.io";
    // TODO: we don't have suins image atm, so temporarily use sui image instead
    const DEFAULT_URL: vector<u8> = b"ipfs://bafkreibngqhl3gaa7daob4i2vccziay2jjlp435cf66vhono7nrvww53ty";

    // https://examples.sui.io/patterns/capability.html
    struct AdminCap has key { id: UID }

    struct OwnerChangedEvent has copy, drop {
        old_owner: address,
        new_owner: address,
        node: string::String,
    }

    struct ResolverChangedEvent has copy, drop {
        old_resolver: address,
        new_resolver: address,
        node: string::String,
    }

    struct TTLChangedEvent has copy, drop {
        old_ttl: u64,
        new_ttl: u64,
        node: string::String,
    }

    struct NewRecordCreatedEvent has copy, drop {
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
        name: string::String,
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

    public fun get_registry_len(registry: & Registry): u64 {
        vec_map::size(&registry.records)
    }

    public fun get_record_node(record: & RecordNFT): string::String {
        record.node
    }

    public fun get_record_owner(record: & RecordNFT): address {
        record.owner
    }

    public fun get_record_resolver(record: & RecordNFT): address {
        record.resolver
    }

    public fun get_record_ttl(record: & RecordNFT): u64 {
        record.ttl
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

    // only registrar is allowed to call this
    public(friend) fun mint(
        _: & AdminCap,
        registry: &mut Registry,
        node: vector<u8>,
        owner: address,
        resolver: address,
        ttl: u64,
        ctx: &mut TxContext
    ) {
        let record = Record {
            node: string::utf8(node),
            owner,
            resolver,
            ttl
        };
        let recordNFT = RecordNFT {
            id: object::new(ctx),
            node: record.node,
            owner,
            resolver,
            ttl,
            name: string::utf8(DEFAULT_NAME),
            url: url::new_unsafe_from_bytes(DEFAULT_URL)
        };
        let event = NewRecordCreatedEvent {
            node: record.node,
            owner,
            resolver,
            ttl,
        };
        vec_map::insert(&mut registry.records, record.node, record);
        transfer::transfer(recordNFT, owner);
        event::emit(event);
    }

    public(friend) fun setOwner(registry: &mut Registry, record: RecordNFT, new_owner: address, ctx: &mut TxContext) {
        vec_map::remove(&mut registry.records, &record.node);
        let RecordNFT { id, node, owner: _, resolver, ttl, name: _, url: _ } = record;
        object::delete(id);

        transfer::transfer(RecordNFT {
            id: object::new(ctx),
            node,
            owner: new_owner,
            resolver,
            ttl,
            name: string::utf8(DEFAULT_NAME),
            url: url::new_unsafe_from_bytes(DEFAULT_URL),
        }, new_owner);
        event::emit(OwnerChangedEvent {
            old_owner: tx_context::sender(ctx),
            new_owner,
            node
        })
    }

    public(friend) fun setResolver(record: &mut RecordNFT, new_resolver: address) {
        let current_resolver = record.resolver;
        record.resolver = new_resolver;

        event::emit(ResolverChangedEvent {
            old_resolver: current_resolver,
            new_resolver,
            node: record.node,
        })
    }

    public entry fun setTTL(record: &mut RecordNFT, new_ttl: u64) {
        let current_ttl = record.ttl;
        record.ttl = new_ttl;

        event::emit(TTLChangedEvent {
            old_ttl: current_ttl,
            new_ttl,
            node: record.node,
        })
    }

    #[test_only]
    friend suins::registry_tests;
    #[test_only]
    /// Wrapper of module initializer for testing
    public fun test_init(ctx: &mut TxContext) {
        init(ctx)
    }
}
