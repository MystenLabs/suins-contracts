module suins::reverse_registrar {

    use sui::event;
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use suins::base_registry::{Self, Registry, AdminCap};
    use std::string;
    use suins::converter;

    const ADDR_REVERSE_BASE_NODE: vector<u8> = b"addr.reverse";

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
    }

    fun init(ctx: &mut TxContext) {
        transfer::share_object(ReverseRegistrar {
            id: object::new(ctx),
            default_resolver: tx_context::sender(ctx),
        });
    }

    public entry fun set_default_resolver(_: &AdminCap, registrar: &mut ReverseRegistrar, resolver: address) {
        assert!(resolver != @0x0, EInvalidResolver);
        registrar.default_resolver = resolver;
        event::emit(DefaultResolverChangedEvent { resolver })
    }

    public entry fun claim(registrar: &mut ReverseRegistrar, registry: &mut Registry, owner: address, ctx: &mut TxContext) {
        claim_for_addr(registry, tx_context::sender(ctx), owner, *&registrar.default_resolver, ctx)
    }

    public entry fun claim_with_resolver(
        registry: &mut Registry,
        owner: address,
        resolver: address,
        ctx: &mut TxContext
    ) {
        claim_for_addr(registry, tx_context::sender(ctx), owner, resolver, ctx)
    }

    public entry fun claim_for_addr(
        registry: &mut Registry,
        addr: address,
        owner: address,
        resolver: address,
        ctx: &mut TxContext
    ) {
        assert!(resolver != @0x0, EInvalidResolver);
        authorised(registry, addr, ctx);

        let label = converter::address_to_string(addr);
        let subnode = base_registry::make_subnode(label, string::utf8(ADDR_REVERSE_BASE_NODE));
        base_registry::set_subnode_record_internal(registry, subnode, owner, resolver, 0);

        event::emit(ReverseClaimedEvent { addr, resolver })
    }

    fun authorised(registry: &Registry, addr: address, ctx: &TxContext) {
        let sender = tx_context::sender(ctx);
        if (sender != addr && !base_registry::is_approval_for_all(registry, sender, addr)) abort EUnauthorized;
    }

    #[test_only]
    public fun get_default_resolver(registrar: &ReverseRegistrar): address {
        registrar.default_resolver
    }

    #[test_only]
    /// Wrapper of module initializer for testing
    public fun test_init(ctx: &mut TxContext) { init(ctx) }
}
