/// Use for reverse domains in the form of "123abc.addr.reverse"
/// This kind of domains are needed to get default name,...
module suins::reverse_registrar {

    use sui::event;
    use sui::tx_context::{TxContext, sender};
    use suins::entity::{Self, SuiNS};
    use suins::registry;
    use suins::converter;
    use std::string;

    const ADDR_REVERSE_BASE_NODE: vector<u8> = b"addr.reverse";

    struct ReverseClaimedEvent has copy, drop {
        addr: address,
        resolver: address,
    }

    /// #### Notice
    /// Similar to `claim_with_resolver`. The only differrence is
    /// this function uses `default_name_resolver` property as resolver address.
    public entry fun claim(suins: &mut SuiNS, owner: address, ctx: &mut TxContext) {
        let resolver = entity::default_resolver(suins);
        claim_with_resolver(suins, owner, resolver, ctx)
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
        suins: &mut SuiNS,
        owner: address,
        resolver: address,
        ctx: &mut TxContext
    ) {
        let label = converter::address_to_string(sender(ctx));
        let node = registry::make_node(label, string::utf8(ADDR_REVERSE_BASE_NODE));
        registry::set_record_internal(suins, node, owner, resolver, 0);

        event::emit(ReverseClaimedEvent { addr: sender(ctx), resolver })
    }
}
