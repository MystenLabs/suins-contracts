module suins::reverse_registrar {

    use sui::event;
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use suins::base_registry::{Self, Registry, AdminCap};
    use std::string;
    use suins::converter;

    const ADDR_REVERSE_BASE_NODE: vector<u8> = b"addr.reverse";

    struct ReverseClaimedEvent has copy, drop {
        addr: address,
        resolver: address,
    }

    struct DefaultResolverChangedEvent has copy, drop {
        resolver: address,
    }

    struct ReverseRegistrar has key {
        id: UID,
        default_name_resolver: address,
    }

    fun init(ctx: &mut TxContext) {
        transfer::share_object(ReverseRegistrar {
            id: object::new(ctx),
            // cannot get the ID of name_resolver in `init`, admin need to update this by calling `set_default_resolver`
            default_name_resolver: @0x0,
        });
    }

    public entry fun set_default_resolver(_: &AdminCap, registrar: &mut ReverseRegistrar, resolver: address) {
        registrar.default_name_resolver = resolver;
        event::emit(DefaultResolverChangedEvent { resolver })
    }

    public entry fun claim(registrar: &mut ReverseRegistrar, registry: &mut Registry, owner: address, ctx: &mut TxContext) {
        claim_with_resolver(registry, owner, *&registrar.default_name_resolver, ctx)
    }

    public entry fun claim_with_resolver(
        registry: &mut Registry,
        owner: address,
        resolver: address,
        ctx: &mut TxContext
    ) {
        let addr = tx_context::sender(ctx);
        let label = converter::address_to_string(addr);
        let node = base_registry::make_node(label, string::utf8(ADDR_REVERSE_BASE_NODE));
        base_registry::set_record_internal(registry, node, owner, resolver, 0);

        event::emit(ReverseClaimedEvent { addr, resolver })
    }

    #[test_only]
    public fun get_default_resolver(registrar: &ReverseRegistrar): address {
        registrar.default_name_resolver
    }

    #[test_only]
    /// Wrapper of module initializer for testing
    public fun test_init(ctx: &mut TxContext) {
        transfer::share_object(ReverseRegistrar {
            id: object::new(ctx),
            default_name_resolver: @0x0,
        });
    }
}
