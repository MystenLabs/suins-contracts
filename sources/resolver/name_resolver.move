module suins::name_resolver {

    use sui::event;
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::TxContext;
    use sui::vec_map::{Self, VecMap};
    use std::string::{Self, String};
    use suins::base_registry::{Self, Registry};
    use suins::converter;

    const ADDR_REVERSE_BASE_NODE: vector<u8> = b"addr.reverse";

    struct NameChangedEvent has copy, drop {
        addr: address,
        name: String,
    }

    struct NameRemovedEvent has copy, drop {
        addr: address,
    }

    struct NameResolver has key {
        id: UID,
        names: VecMap<address, String>,
    }

    fun init(ctx: &mut TxContext) {
        let resolver = NameResolver {
            id: object::new(ctx),
            names: vec_map::empty(),
        };
        transfer::share_object(resolver);
    }

    public fun name(resolver: &NameResolver, addr: address): String {
        *vec_map::get(&resolver.names, &addr)
    }

    public entry fun set_name(
        resolver: &mut NameResolver,
        registry: &Registry,
        addr: address,
        name: vector<u8>,
        ctx: &mut TxContext
    ) {
        let label = converter::address_to_string(addr);
        let node = base_registry::make_node(label, string::utf8(ADDR_REVERSE_BASE_NODE));
        base_registry::authorised(registry, *string::bytes(&node), ctx);

        let name = string::utf8(name);
        if (vec_map::contains(&resolver.names, &addr)) {
            let resolved_address = vec_map::get_mut(&mut resolver.names, &addr);
            *resolved_address = name;
        } else {
            vec_map::insert(&mut resolver.names, addr, name);
        };

        event::emit(NameChangedEvent { addr, name });
    }

    public entry fun unset(
        resolver: &mut NameResolver,
        registry: &Registry,
        addr: address,
        ctx: &mut TxContext
    ) {
        let label = converter::address_to_string(addr);
        let node = base_registry::make_node(label, string::utf8(ADDR_REVERSE_BASE_NODE));
        base_registry::authorised(registry, *string::bytes(&node), ctx);

        vec_map::remove(&mut resolver.names, &addr);
        event::emit(NameRemovedEvent { addr });
    }

    #[test_only]
    /// Wrapper of module initializer for testing
    public fun test_init(ctx: &mut TxContext) { init(ctx) }
}
