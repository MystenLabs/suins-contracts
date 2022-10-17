module suins::reverse_registrar {

    use std::bcs;
    use sui::event;
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use std::vector;
    use suins::base_registry::{Self, Registry, AdminCap};
    use std::string;

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

        let label = address_to_string(addr);
        let subnode = base_registry::make_subnode(label, string::utf8(ADDR_REVERSE_BASE_NODE));
        base_registry::set_subnode_record_internal(registry, subnode, owner, resolver, 0);

        event::emit(ReverseClaimedEvent { addr, resolver })
    }

    fun authorised(registry: &Registry, addr: address, ctx: &TxContext) {
        let sender = tx_context::sender(ctx);
        if (sender != addr && !base_registry::is_approval_for_all(registry, sender, addr)) abort EUnauthorized;
    }

    fun address_to_string(addr: address): vector<u8> {
        let bytes = bcs::to_bytes(&addr);
        let len = vector::length(&bytes);
        let index = 0;
        let result: vector<u8> = vector[];

        while(index < len) {
            let byte = *vector::borrow(&bytes, index);

            let first: u8 = (byte >> 4) & 0xF;
            // a in HEX == 10 in DECIMAL
            // 'a' in CHAR  == 97 in DECIMAL
            // 8 in HEX == 8 in DECIMAL
            // '8' in CHAR  == 56 in DECIMAL
            if (first > 9) first = first + 87
            else first = first + 48;

            let second: u8 = byte & 0xF;
            if (second > 9) second = second + 87
            else second = second + 48;

            vector::push_back(&mut result, first);
            vector::push_back(&mut result, second);

            index = index + 1;
        };

        result
    }

    #[test_only]
    public fun address_to_string_helper(addr: address): string::String {
        string::utf8(address_to_string(addr))
    }

    #[test_only]
    public fun get_default_resolver(registrar: &ReverseRegistrar): address {
        registrar.default_resolver
    }

    #[test_only]
    /// Wrapper of module initializer for testing
    public fun test_init(ctx: &mut TxContext) { init(ctx) }
}
