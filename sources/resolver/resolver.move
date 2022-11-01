module suins::resolver {

    use sui::event;
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::TxContext;
    use sui::vec_map::{Self, VecMap};
    use std::string::{Self, String, utf8};
    use suins::base_registry::{Self, Registry};
    use suins::converter;

    const ADDR_REVERSE_BASE_NODE: vector<u8> = b"addr.reverse";
    const NAME: vector<u8> = b"name";
    const ADDR: vector<u8> = b"addr";
    const AVATAR_RESOLVER: vector<u8> = b"avatar";

    struct NameChangedEvent has copy, drop {
        addr: address,
        name: String,
    }

    struct NameRemovedEvent has copy, drop {
        addr: address,
    }

    struct TextChangedEvent has copy, drop {
        node: String,
        key: String,
        value: String,
    }

    // this share object is used by many type of resolver, e.g., text resolver, addr resolver,...
    struct BaseResolver has key {
        id: UID,
        // map from key => node => value
        // key can be: avatar, addr...
        resolvers: VecMap<String, VecMap<String, String>>,
    }

    // name resolver use a separate struct because name resolver is used specially for default name
    // this struct still follows the same pattern as `BaseResolver`, so client will have a consistent view of the data
    struct NameResolver has key {
        id: UID,
        names: VecMap<String, VecMap<address, String>>,
    }

    fun init(ctx: &mut TxContext) {
        let names = vec_map::empty();
        vec_map::insert(&mut names, utf8(NAME), vec_map::empty());
        transfer::share_object(NameResolver {
            id: object::new(ctx),
            names,
        });

        let resolvers = vec_map::empty();
        vec_map::insert(&mut resolvers, utf8(ADDR), vec_map::empty());
        vec_map::insert(&mut resolvers, utf8(AVATAR_RESOLVER), vec_map::empty());
        transfer::share_object(BaseResolver {
            id: object::new(ctx),
            resolvers,
        });
    }

    public fun name(name_resolver: &NameResolver, addr: address): String {
        let names = vec_map::get(&name_resolver.names, &utf8(NAME));
        *vec_map::get(names, &addr)
    }

    public fun text(base_resolver: &BaseResolver, node: vector<u8>, key: vector<u8>): String {
        let resolver = vec_map::get(&base_resolver.resolvers, &utf8(key));
        *vec_map::get(resolver, &utf8(node))
    }

    // public entry fun set_text(
    //     base_resolver: &mut BaseResolver,
    //     // registry: &Registry,
    //     node: vector<u8>,
    //     key: vector<u8>,
    //     value: vector<u8>,
    //     // addr: address,
    //     // ctx: &mut TxContext
    // ) {
    //     // base_registry::authorised(registry, node, ctx);
    //     //
    //     let node = utf8(node);
    //     let key = utf8(key);
    //     let value = utf8(value);
    //     let resolver = vec_map::get_mut(&mut base_resolver.resolvers, &key);
    //     if (vec_map::contains(resolver, &node)) {
    //         let resolved_value = vec_map::get_mut(resolver, &node);
    //         *resolved_value = value;
    //     } else {
    //         vec_map::insert(resolver, node, value);
    //     };
    //
    //     event::emit(TextChangedEvent { node, key, value });
    // }

    public entry fun set_text(
        base_resolver: &mut BaseResolver,
        registry: &Registry,
        node: vector<u8>,
        key: vector<u8>,
        value: vector<u8>,
        ctx: &mut TxContext
    ) {
        base_registry::authorised(registry, node, ctx);

        let node = utf8(node);
        let key = utf8(key);
        let value = utf8(value);
        let resolver = vec_map::get_mut(&mut base_resolver.resolvers, &key);
        if (vec_map::contains(resolver, &node)) {
            let resolved_value = vec_map::get_mut(resolver, &node);
            *resolved_value = value;
        } else {
            vec_map::insert(resolver, node, value);
        };

        event::emit(TextChangedEvent { node, key, value });
    }

    public entry fun set_name(
        name_resolver: &mut NameResolver,
        registry: &Registry,
        addr: address,
        name: vector<u8>,
        ctx: &mut TxContext
    ) {
        let label = converter::address_to_string(addr);
        let node = base_registry::make_node(label, utf8(ADDR_REVERSE_BASE_NODE));
        base_registry::authorised(registry, *string::bytes(&node), ctx);

        let name = utf8(name);
        let names =
            vec_map::get_mut(&mut name_resolver.names, &utf8(NAME));
        if (vec_map::contains(names, &addr)) {
            let resolved_name = vec_map::get_mut(names, &addr);
            *resolved_name = name;
        } else {
            vec_map::insert(names, addr, name);
        };

        event::emit(NameChangedEvent { addr, name });
    }

    public entry fun unset_name(
        name_resolver: &mut NameResolver,
        registry: &Registry,
        addr: address,
        ctx: &mut TxContext
    ) {
        let label = converter::address_to_string(addr);
        let node = base_registry::make_node(label, utf8(ADDR_REVERSE_BASE_NODE));
        base_registry::authorised(registry, *string::bytes(&node), ctx);

        let names =
            vec_map::get_mut(&mut name_resolver.names, &utf8(NAME));
        vec_map::remove(names, &addr);
        event::emit(NameRemovedEvent { addr });
    }

    #[test_only]
    /// Wrapper of module initializer for testing
    public fun test_init(ctx: &mut TxContext) { init(ctx) }
}
