module suins::addr_resolver {

    use sui::vec_map::VecMap;
    use std::string::{Self, String};
    use sui::vec_map;
    use suins::base_registry;
    use suins::base_registry::Registry;
    use sui::tx_context::TxContext;
    use sui::tx_context;
    use sui::vec_set::VecSet;
    use sui::vec_set;
    use sui::event;
    use sui::object::UID;
    use sui::object;
    use sui::transfer;

    // errors in the range of 401..500 indicate Address Resolver errors
    const EUnauthorized: u64 = 401;
    const ENodeNotExists: u64 = 402;

    struct AddressChangedEvent has copy, drop {
        node: String,
        addr: address,
    }

    struct AddrResolver has key {
        id: UID,
        addresses: VecMap<String, address>,
        authorisations: VecMap<String, VecSet<address>>,
    }

    fun init(ctx: &mut TxContext) {
        let resolver = AddrResolver {
            id: object::new(ctx),
            addresses: vec_map::empty(),
            authorisations: vec_map::empty(),
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
        authorised(resolver, registry, node, ctx);

        let node = string::utf8(node);
        if (vec_map::contains(&resolver.addresses, &node)) {
            let resolved_address = vec_map::get_mut(&mut resolver.addresses, &node);
            *resolved_address = addr;
        } else {
            vec_map::insert(&mut resolver.addresses, node, addr);
        };

        event::emit(AddressChangedEvent { node, addr });
    }

    public entry fun set_authorisation(
        resolver: &mut AddrResolver,
        registry: &Registry,
        node: vector<u8>,
        target: address,
        is_authorised: bool,
        ctx: &mut TxContext,
    ) {
        let owner = base_registry::owner(registry, node);
        let sender = tx_context::sender(ctx);
        if (owner != sender) abort EUnauthorized;

        let node = string::utf8(node);
        if (!vec_map::contains(&resolver.authorisations, &node)) {
            vec_map::insert(&mut resolver.authorisations, node, vec_set::empty());
        };

        let authorisations = vec_map::get_mut(&mut resolver.authorisations, &node);
        if (is_authorised) vec_set::insert(authorisations, target)
        else vec_set::remove(authorisations, &target);
    }

    fun authorised(resolver: &AddrResolver, registry: &Registry, node: vector<u8>, ctx: &mut TxContext) {
        let owner = base_registry::owner(registry, node);
        let sender = tx_context::sender(ctx);

        if (owner == sender) return;

        let node = string::utf8(node);
        if (vec_map::contains(&resolver.authorisations, &node)) {
            let authorisations = vec_map::get(&resolver.authorisations, &node);
            if (vec_set::contains(authorisations, &sender)) return;
        };
        abort EUnauthorized
    }

    #[test_only]
    public fun is_authorised(resolver: &mut AddrResolver, node: String, target: address): bool {
        vec_set::contains(vec_map::get(&resolver.authorisations, &node), &target)
    }
    #[test_only]
    /// Wrapper of module initializer for testing
    public fun test_init(ctx: &mut TxContext) { init(ctx) }
}
