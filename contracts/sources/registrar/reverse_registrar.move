/// Use for reverse domains in the form of "123abc.addr.reverse"
/// This kind of domains are needed to get default name,...
module suins::reverse_registrar {

    use sui::event;
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{TxContext, sender};
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
        // doesn't need to store registration records because address itself can prove the ownership
        id: UID,
        default_name_resolver: address,
    }

    /// #### Notice
    /// Similar to `claim_with_resolver`. The only differrence is
    /// this function uses `default_name_resolver` property as resolver address.
    public entry fun claim(registrar: &mut ReverseRegistrar, registry: &mut Registry, owner: address, ctx: &mut TxContext) {
        claim_with_resolver(registry, owner, *&registrar.default_name_resolver, ctx)
    }

    /// #### Notice
    /// This function is used to created reverse domains, i.e. domains with format: `123abc.addr.reverse`.
    ///
    /// #### Dev
    /// Unlike `BaseRegistrar`, this function only creates name record.
    ///
    /// #### Params
    /// `owner`: new owner address of new name record.
    /// `resolver`: resolver address of new name record.
    public entry fun claim_with_resolver(
        registry: &mut Registry,
        owner: address,
        resolver: address,
        ctx: &mut TxContext
    ) {
        let label = converter::address_to_string(sender(ctx));
        let node = base_registry::make_node(label, string::utf8(ADDR_REVERSE_BASE_NODE));
        base_registry::set_record_internal(registry, node, owner, resolver, 0);

        event::emit(ReverseClaimedEvent { addr: sender(ctx), resolver })
    }

    /// #### Notice
    /// The admin uses this function to update `default_name_resolver`.
    public entry fun set_default_resolver(_: &AdminCap, registrar: &mut ReverseRegistrar, resolver: address) {
        registrar.default_name_resolver = resolver;
        event::emit(DefaultResolverChangedEvent { resolver })
    }

    // === Friend and Private Functions ===

    fun init(ctx: &mut TxContext) {
        transfer::share_object(ReverseRegistrar {
            id: object::new(ctx),
            // cannot get the ID of name_resolver in `init`, the admin has to update this by calling
            // `set_default_resolver`
            default_name_resolver: @0x0,
        });
    }

    // === Testing ===

    #[test_only]
    public fun get_default_resolver(registrar: &ReverseRegistrar): address {
        registrar.default_name_resolver
    }

    #[test_only]
    public fun test_init(ctx: &mut TxContext) {
        transfer::share_object(ReverseRegistrar {
            id: object::new(ctx),
            default_name_resolver: @0x0,
        });
    }
}
