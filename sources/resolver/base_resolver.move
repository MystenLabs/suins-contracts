module suins::base_resolver {

    use sui::event;
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::TxContext;
    use sui::vec_map::{Self, VecMap};
    use std::string::{Self, String};
    use suins::base_registry::{Self, Registry};
    use suins::converter;

    const ADDR_REVERSE_BASE_NODE: vector<u8> = b"addr.reverse";
    const NAME_RESOLVER: vector<u8> = b"name";
    const ADDR_RESOLVER: vector<u8> = b"addr";

    struct NameChangedEvent has copy, drop {
        addr: address,
        name: String,
    }

    struct AddressChangedEvent has copy, drop {
        node: String,
        addr: address,
    }

    struct NameRemovedEvent has copy, drop {
        addr: address,
    }

    struct BaseResolver has key {
        id: UID,
        resolvers: VecMap<String, VecMap<String, String>>,
    }

    fun init(ctx: &mut TxContext) {
        let resolvers = vec_map::empty();
        vec_map::insert(&mut resolvers, string::utf8(NAME_RESOLVER), vec_map::empty());
        vec_map::insert(&mut resolvers, string::utf8(ADDR_RESOLVER), vec_map::empty());
        let resolver = BaseResolver {
            id: object::new(ctx),
            resolvers,
        };
        transfer::share_object(resolver);
    }

    public fun addr(resolver: &BaseResolver, node: vector<u8>): String {
        let addr_resolver = vec_map::get(&resolver.resolvers, &string::utf8(ADDR_RESOLVER));
        *vec_map::get(addr_resolver, &string::utf8(node))
    }

    public fun name(resolver: &BaseResolver, addr: address): String {
        let name_resolver = vec_map::get(&resolver.resolvers, &string::utf8(NAME_RESOLVER));
        *vec_map::get(name_resolver, &string::utf8(converter::address_to_string(addr)))
    }

    public entry fun set_addr(
        base_resolver: &mut BaseResolver,
        registry: &Registry,
        node: vector<u8>,
        addr: address,
        ctx: &mut TxContext
    ) {
        base_registry::authorised(registry, node, ctx);

        let node = string::utf8(node);
        let addr_resolver = vec_map::get_mut(&mut base_resolver.resolvers, &string::utf8(ADDR_RESOLVER));
        if (vec_map::contains(addr_resolver, &node)) {
            let resolved_address = vec_map::get_mut(addr_resolver, &node);
            *resolved_address = string::utf8(converter::address_to_string(addr));
        } else {
            vec_map::insert(addr_resolver, node, string::utf8(converter::address_to_string(addr)));
        };

        event::emit(AddressChangedEvent { node, addr });
    }

    public entry fun set_name(
        resolver: &mut BaseResolver,
        registry: &Registry,
        addr: address,
        name: vector<u8>,
        ctx: &mut TxContext
    ) {
        let label = converter::address_to_string(addr);
        let node = base_registry::make_node(label, string::utf8(ADDR_REVERSE_BASE_NODE));
        base_registry::authorised(registry, *string::bytes(&node), ctx);

        let name = string::utf8(name);
        let addr_str = string::utf8(converter::address_to_string(addr));
        let name_resolver =
            vec_map::get_mut(&mut resolver.resolvers, &string::utf8(NAME_RESOLVER));
        if (vec_map::contains(name_resolver, &addr_str)) {
            let resolved_name = vec_map::get_mut(name_resolver, &addr_str);
            *resolved_name = name;
        } else {
            vec_map::insert(name_resolver, addr_str, name);
        };

        event::emit(NameChangedEvent { addr, name });
    }

    public entry fun unset_name(
        resolver: &mut BaseResolver,
        registry: &Registry,
        addr: address,
        ctx: &mut TxContext
    ) {
        let label = converter::address_to_string(addr);
        let node = base_registry::make_node(label, string::utf8(ADDR_REVERSE_BASE_NODE));
        base_registry::authorised(registry, *string::bytes(&node), ctx);

        let name_resolver =
            vec_map::get_mut(&mut resolver.resolvers, &string::utf8(NAME_RESOLVER));
        vec_map::remove(name_resolver, &string::utf8(converter::address_to_string(addr)));
        event::emit(NameRemovedEvent { addr });
    }

    #[test_only]
    /// Wrapper of module initializer for testing
    public fun test_init(ctx: &mut TxContext) { init(ctx) }
}
