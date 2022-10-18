module suins::addr_resolver {

    use sui::vec_map::VecMap;
    use std::string::{Self, String};
    use sui::vec_map;
    use suins::base_registry;
    use suins::base_registry::Registry;
    use sui::tx_context::TxContext;
    use sui::event;
    use sui::object::{Self, UID};
    use sui::transfer;

    // errors in the range of 401..500 indicate Address Resolver errors
    const ENodeNotExists: u64 = 402;

    struct AddressChangedEvent has copy, drop {
        node: String,
        addr: address,
    }

    struct AddrResolver has key {
        id: UID,
        addresses: VecMap<String, address>,
    }

    fun init(ctx: &mut TxContext) {
        let resolver = AddrResolver {
            id: object::new(ctx),
            addresses: vec_map::empty(),
        };
        transfer::share_object(resolver);
    }

    public fun addr(resolver: &AddrResolver, node: vector<u8>): address {
        *vec_map::get(&resolver.addresses, &string::utf8(node))
    }

    public entry fun set_addr(
        resolver: &mut AddrResolver,
        registry: &Registry,
        node: vector<u8>,
        addr: address,
        ctx: &mut TxContext
    ) {
        base_registry::authorised(registry, node, ctx);

        let node = string::utf8(node);
        if (vec_map::contains(&resolver.addresses, &node)) {
            let resolved_address = vec_map::get_mut(&mut resolver.addresses, &node);
            *resolved_address = addr;
        } else {
            vec_map::insert(&mut resolver.addresses, node, addr);
        };

        event::emit(AddressChangedEvent { node, addr });
    }

    #[test_only]
    /// Wrapper of module initializer for testing
    public fun test_init(ctx: &mut TxContext) { init(ctx) }
}
