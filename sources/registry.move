module suins::registry {
    use sui::event;
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::typed_id::{Self, TypedID};
    use sui::vec_set;

    const EInvalidNewOwner: u64 = 1;
    const EInvalidNewResolver: u64 = 2;
    const EInvalidNewTTL: u64 = 3;

    struct AdminCap has key { id: UID }

    struct OwnerChangedEvent has copy, drop {
        old_owner: address,
        new_owner: address,
        domain: vector<u8>,
    }

    struct ResolverChangedEvent has copy, drop {
        old_resolver: address,
        new_resolver: address,
        domain: vector<u8>,
    }

    struct TTLChangedEvent has copy, drop {
        old_ttl: u64,
        new_ttl: u64,
        domain: vector<u8>,
    }

    struct Record has key, store {
        id: UID,
        domain: vector<u8>,
        owner: address,
        resolver: address,
        ttl: u64,
    }

    struct Registry has key {
        id: UID,
        records: vec_set::VecSet<TypedID<Record>>,
    }

    public fun get_registry_len(registry: &Registry): u64 {
        vec_set::size(&registry.records)
    }

    public fun get_record_domain(record: &Record): vector<u8> {
        record.domain
    }

    public fun get_record_owner(record: &Record): address {
        record.owner
    }

    public fun get_record_resolver(record: &Record): address {
        record.resolver
    }

    public fun get_record_ttl(record: &Record): u64 {
        record.ttl
    }

    fun init(ctx: &mut TxContext) {
        transfer::transfer(AdminCap {
            id: object::new(ctx)
        }, tx_context::sender(ctx));

        transfer::share_object(Registry {
            id: object::new(ctx),
            records: vec_set::empty(),
        });
    }

    public entry fun mint(
        _: &AdminCap,
        registry: &mut Registry,
        domain: vector<u8>,
        owner: address,
        resolver: address,
        ttl: u64,
        ctx: &mut TxContext
    ) {
        let record = Record {
            id: object::new(ctx),
            domain,
            owner,
            resolver,
            ttl
        };
        vec_set::insert(&mut registry.records, typed_id::new(&record));
        transfer::transfer(record, owner);
    }

    public entry fun setOwner(registry: &mut Registry, record: Record, new_owner: address, ctx: &mut TxContext) {
        assert!(new_owner != tx_context::sender(ctx), EInvalidNewOwner);

        vec_set::remove(&mut registry.records, &typed_id::new(&record));
        let Record { id, domain, owner: _, resolver, ttl } = record;
        object::delete(id);

        transfer::transfer(Record {
            id: object::new(ctx),
            domain,
            owner: new_owner,
            resolver,
            ttl
        }, new_owner);
        event::emit(OwnerChangedEvent {
            old_owner: tx_context::sender(ctx),
            new_owner,
            domain
        })
    }

    public entry fun setResolver(record: &mut Record, new_resolver: address) {
        assert!(new_resolver != record.resolver, EInvalidNewResolver);

        let current_resolver = record.resolver;
        record.resolver = new_resolver;

        event::emit(ResolverChangedEvent {
            old_resolver: current_resolver,
            new_resolver,
            domain: record.domain,
        })
    }

    public entry fun setTTL(record: &mut Record, new_ttl: u64) {
        assert!(new_ttl != record.ttl, EInvalidNewTTL);

        let current_ttl = record.ttl;
        record.ttl = new_ttl;

        event::emit(TTLChangedEvent {
            old_ttl: current_ttl,
            new_ttl,
            domain: record.domain,
        })
    }

    #[test_only]
    /// Wrapper of module initializer for testing
    public fun test_init(ctx: &mut TxContext) {
        init(ctx)
    }
}
