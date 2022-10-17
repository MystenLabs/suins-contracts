module suins::reverse_registrar {

    use sui::event;
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::vec_map::{Self, VecMap};
    use suins::base_registry::{Self, Registry, AdminCap};

    // errors in the range of 501..600 indicate Address Resolver errors
    const EUnauthorized: u64 = 101;
    const EInvalidResolver: u64 = 501;

    struct ReverseClaimedEvent has copy, drop {
        addr: address,
        resolver: address,
    }

    struct DefaultResolverChangedEvent has copy, drop {
        resolver: address,
    }

    struct ReverseRegistrar has key {
        id: UID,
        default_resolver: address,
        // map from user address to resolver address
        records: VecMap<address, address>,
    }

    fun init(ctx: &mut TxContext) {
        transfer::share_object(ReverseRegistrar {
            id: object::new(ctx),
            default_resolver: tx_context::sender(ctx),
            records: vec_map::empty(),
        });
    }

    public entry fun set_default_resolver(_: &AdminCap, registrar: &mut ReverseRegistrar, resolver: address) {
        assert!(resolver != @0x0, EInvalidResolver);
        registrar.default_resolver = resolver;
        event::emit(DefaultResolverChangedEvent { resolver })
    }

    public entry fun claim(registrar: &mut ReverseRegistrar, registry: &mut Registry, ctx: &mut TxContext) {
        let resolver = *&registrar.default_resolver;
        claim_for_addr(registrar, registry, tx_context::sender(ctx), resolver, ctx)
    }

    public entry fun claim_with_resolver(
        registrar: &mut ReverseRegistrar,
        registry: &mut Registry,
        resolver: address,
        ctx: &mut TxContext
    ) {
        claim_for_addr(registrar, registry, tx_context::sender(ctx), resolver, ctx)
    }

    public entry fun claim_for_addr(
        registrar: &mut ReverseRegistrar,
        registry: &mut Registry,
        addr: address,
        resolver: address,
        ctx: &mut TxContext
    ) {
        assert!(resolver != @0x0, EInvalidResolver);
        authorised(registry, addr, ctx);

        if (vec_map::contains(&registrar.records, &addr)) {
            vec_map::remove(&mut registrar.records, &addr);
        };
        vec_map::insert(&mut registrar.records, addr, resolver);
        event::emit(ReverseClaimedEvent { addr, resolver })
    }

    fun authorised(registry: &Registry, addr: address, ctx: &TxContext) {
        let sender = tx_context::sender(ctx);
        if (sender != addr && !base_registry::is_approval_for_all(registry, sender, addr)) abort EUnauthorized;
    }

    #[test_only]
    public fun get_records_len(registrar: &ReverseRegistrar): u64 {
        vec_map::size(&registrar.records)
    }

    #[test_only]
    public fun get_default_resolver(registrar: &ReverseRegistrar): address {
        registrar.default_resolver
    }

    #[test_only]
    public fun get_record_at_index(registrar: &ReverseRegistrar, index: u64): (&address, &address) {
        vec_map::get_entry_by_idx(&registrar.records, index)
    }

    #[test_only]
    /// Wrapper of module initializer for testing
    public fun test_init(ctx: &mut TxContext) { init(ctx) }
}
