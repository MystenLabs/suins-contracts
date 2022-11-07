module suins::resolver {

    use sui::bag::{Self, Bag};
    use sui::event;
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::TxContext;
    use suins::base_registry::{Self, Registry};
    use suins::converter;
    use std::string::{Self, String, utf8};
    use sui::table;

    const ADDR_REVERSE_BASE_NODE: vector<u8> = b"addr.reverse";
    const NAME: vector<u8> = b"name";
    const ADDR: vector<u8> = b"addr";
    const AVATAR: vector<u8> = b"avatar";

    struct NameChangedEvent has copy, drop {
        addr: address,
        name: String,
    }

    struct NameRemovedEvent has copy, drop {
        addr: address,
    }

    struct AvatarChangedEvent has copy, drop {
        node: String,
        avatar: String,
    }

    struct AddrChangedEvent has copy, drop {
        node: String,
        addr: address,
    }

    // this share object is used by many type of resolver, e.g., text resolver, addr resolver,...
    struct BaseResolver has key {
        id: UID,
        resolvers: Bag,
    }

    fun init(ctx: &mut TxContext) {
        let resolvers = bag::new(ctx);
        bag::add(&mut resolvers, utf8(ADDR), table::new<String, address>(ctx));
        bag::add(&mut resolvers, utf8(NAME), table::new<address, String>(ctx));
        bag::add(&mut resolvers, utf8(AVATAR), table::new<String, String>(ctx));
        transfer::share_object(BaseResolver {
            id: object::new(ctx),
            resolvers,
        });
    }

    public fun name(name_resolver: &BaseResolver, addr: address): String {
        let names = bag::borrow(&name_resolver.resolvers, utf8(NAME));
        *table::borrow<address, String>(names, addr)
    }

    public fun avatar(base_resolver: &BaseResolver, node: vector<u8>): String {
        let avatars = bag::borrow(&base_resolver.resolvers, utf8(AVATAR));
        *table::borrow<String, String>(avatars, utf8(node))
    }

    public fun addr(base_resolver: &BaseResolver, node: vector<u8>): address {
        let addrs = bag::borrow(&base_resolver.resolvers, utf8(ADDR));
        *table::borrow<String, address>(addrs, utf8(node))
    }

    public entry fun set_name(
        base_resolver: &mut BaseResolver,
        registry: &Registry,
        addr: address,
        new_name: vector<u8>,
        ctx: &mut TxContext
    ) {
        let label = converter::address_to_string(addr);
        let node = base_registry::make_node(label, utf8(ADDR_REVERSE_BASE_NODE));
        base_registry::authorised(registry, *string::bytes(&node), ctx);

        let new_name = utf8(new_name);
        let names = bag::borrow_mut(&mut base_resolver.resolvers, utf8(NAME));
        if (table::contains(names, addr)) {
            let current_name = table::borrow_mut<address, String>(names, addr);
            *current_name = new_name;
        } else {
            table::add(names, addr, new_name);
        };

        event::emit(NameChangedEvent { addr, name: new_name });
    }

    public entry fun unset_name(
        base_resolver: &mut BaseResolver,
        registry: &Registry,
        addr: address,
        ctx: &mut TxContext
    ) {
        let label = converter::address_to_string(addr);
        let node = base_registry::make_node(label, utf8(ADDR_REVERSE_BASE_NODE));
        base_registry::authorised(registry, *string::bytes(&node), ctx);

        let names = bag::borrow_mut(&mut base_resolver.resolvers, utf8(NAME));
        table::remove<address, String>(names, addr);
        event::emit(NameRemovedEvent { addr });
    }

    // only allow set avatar for domain atm
    public entry fun set_avatar(
        base_resolver: &mut BaseResolver,
        registry: &Registry,
        node: vector<u8>,
        new_avatar: vector<u8>,
        ctx: &mut TxContext
    ) {
        base_registry::authorised(registry, node, ctx);

        let node = utf8(node);
        let new_avatar = utf8(new_avatar);
        let avatars = bag::borrow_mut(&mut base_resolver.resolvers, utf8(AVATAR));
        if (table::contains(avatars, node)) {
            let current_avatar = table::borrow_mut<String, String>(avatars, node);
            *current_avatar = new_avatar;
        } else {
            table::add(avatars, node, new_avatar);
        };

        event::emit(AvatarChangedEvent { node, avatar: new_avatar });
    }

    public entry fun set_addr(
        base_resolver: &mut BaseResolver,
        registry: &Registry,
        node: vector<u8>,
        new_addr: address,
        ctx: &mut TxContext
    ) {
        base_registry::authorised(registry, node, ctx);

        let node = utf8(node);
        let addresses = bag::borrow_mut(&mut base_resolver.resolvers, utf8(ADDR));
        if (table::contains(addresses, node)) {
            let current_addr = table::borrow_mut<String, address>(addresses, node);
            *current_addr = new_addr;
        } else {
            table::add(addresses, node, new_addr);
        };

        event::emit(AddrChangedEvent { node, addr: new_addr });
    }

    #[test_only]
    /// Wrapper of module initializer for testing
    public fun test_init(ctx: &mut TxContext) { init(ctx) }
}
