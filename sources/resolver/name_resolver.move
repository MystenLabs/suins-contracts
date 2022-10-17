module suins::name_resolver {

    use sui::event;
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::vec_map::{Self, VecMap};
    use sui::vec_set::{Self, VecSet};
    use std::string::{Self, String};
    use suins::base_registry::{Self, Registry};
    use suins::converter;

    const ADDR_REVERSE_BASE_NODE: vector<u8> = b"addr.reverse";

    // errors in the range of 401..500 indicate Address Resolver errors
    const EUnauthorized: u64 = 101;

    struct NameChangedEvent has copy, drop {
        addr: address,
        name: String,
    }

    struct NameResolver has key {
        id: UID,
        names: VecMap<address, String>,
        authorisations: VecMap<address, VecSet<address>>,
    }

    fun init(ctx: &mut TxContext) {
        let resolver = NameResolver {
            id: object::new(ctx),
            names: vec_map::empty(),
            authorisations: vec_map::empty(),
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
        authorised(resolver, registry, addr, ctx);

        let name = string::utf8(name);
        if (vec_map::contains(&resolver.names, &addr)) {
            let resolved_address = vec_map::get_mut(&mut resolver.names, &addr);
            *resolved_address = name;
        } else {
            vec_map::insert(&mut resolver.names, addr, name);
        };

        event::emit(NameChangedEvent { addr, name });
    }

    public entry fun set_authorisation(
        resolver: &mut NameResolver,
        registry: &Registry,
        addr: address,
        target: address,
        is_authorised: bool,
        ctx: &mut TxContext,
    ) {
        let label = converter::address_to_string(addr);
        let node = base_registry::make_subnode(label, string::utf8(ADDR_REVERSE_BASE_NODE));

        let owner = base_registry::owner(registry, *string::bytes(&node));
        let sender = tx_context::sender(ctx);
        if (owner != sender) abort EUnauthorized;

        if (!vec_map::contains(&resolver.authorisations, &addr)) {
            vec_map::insert(&mut resolver.authorisations, addr, vec_set::empty());
        };

        let authorisations = vec_map::get_mut(&mut resolver.authorisations, &addr);
        if (is_authorised) vec_set::insert(authorisations, target)
        else vec_set::remove(authorisations, &target);
    }

    fun authorised(resolver: &NameResolver, registry: &Registry, addr: address, ctx: &mut TxContext) {
        let label = converter::address_to_string(addr);
        let node = base_registry::make_subnode(label, string::utf8(ADDR_REVERSE_BASE_NODE));

        let owner = base_registry::owner(registry, *string::bytes(&node));
        let sender = tx_context::sender(ctx);
        if (owner == sender) return;

        if (vec_map::contains(&resolver.authorisations, &addr)) {
            let authorisations = vec_map::get(&resolver.authorisations, &addr);
            if (vec_set::contains(authorisations, &sender)) return;
        };
        abort EUnauthorized
    }

    #[test_only]
    public fun is_authorised(resolver: &mut NameResolver, addr: address, target: address): bool {
        vec_set::contains(vec_map::get(&resolver.authorisations, &addr), &target)
    }
    #[test_only]
    /// Wrapper of module initializer for testing
    public fun test_init(ctx: &mut TxContext) { init(ctx) }
}
