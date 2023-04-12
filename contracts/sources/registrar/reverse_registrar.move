/// Use for reverse domains in the form of "123abc.addr.reverse"
/// This kind of domains are needed to get default name,...
module suins::reverse_registrar {

    use sui::event;
    use sui::tx_context::{TxContext, sender};
    use suins::entity::SuiNS;
    use suins::registry;
    use sui::address;
    use sui::hex;

    struct ReverseClaimedEvent has copy, drop {
        addr: address,
    }

    /// #### Notice
    /// Similar to `claim_with_resolver`. The only differrence is
    /// this function uses `default_name_resolver` property as resolver address.
    public entry fun claim(suins: &mut SuiNS, owner: address, ctx: &mut TxContext) {
        let label = hex::encode(address::to_bytes(sender(ctx)));
        let node = registry::make_subdomain_name(label, registry::addr_reverse_tld());
        registry::set_record_internal(suins, node, owner, 0, ctx);

        event::emit(ReverseClaimedEvent { addr: sender(ctx) })
    }
}
