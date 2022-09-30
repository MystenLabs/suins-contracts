module suins::sui_registrar {
    use sui::event;
    use sui::object::{Self, ID, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::vec_map::{Self};
    use sui::vec_set;
    use suins::base_registry::{Self, Registry};
    use std::string::{Self, String};
    use std::option::{Self, Option};

    const BASE_NODE: vector<u8> = b"sui";
    // in terms of epoch
    const GRACE_PERIOD: u8 = 90;

    // errors in the range of 201..300 indicate Registrar errors
    const EUnauthorized: u64 = 201;
    const EOnlyController: u64 = 202;
    const ESubnodeInvalid: u64 = 203;
    const ESubnodeUnAvailable: u64 = 204;
    const ESubNodeExpired: u64 = 205;

    struct NameRegisteredEvent has copy, drop {
        id: Option<ID>,
        resolver: Option<address>,
        ttl: Option<u64>,
        // full_node = sub_node + '.' + base_node, e.g, eastagile.sui
        base_node: String,
        sub_node: String,
        owner: address,
        expiry: u64,
    }

    struct RegistrationDetail has store {
        expiry: u64,
        owner: address,
    }

    struct SuiRegistrar has key {
        id: UID,
        // key is subnode
        expiries: vec_map::VecMap<String, RegistrationDetail>,
        controllers: vec_set::VecSet<address>,
    }

    fun init(ctx: &mut TxContext) {
        transfer::share_object(SuiRegistrar {
            id: object::new(ctx),
            expiries: vec_map::empty(),
            controllers: vec_set::empty(),
        });
    }

    public fun available(registrar: &SuiRegistrar, id: String, ctx: &TxContext): bool {
        if (record_exists(registrar, id)) {
            let expiry = vec_map::get(&registrar.expiries, &id).expiry;
            return expiry + (GRACE_PERIOD as u64) < tx_context::epoch(ctx)
        };
        true
    }

    public fun name_expires(registrar: &SuiRegistrar, id: String): u64 {
        if (record_exists(registrar, id)) {
            return vec_map::get(&registrar.expiries, &id).expiry
        };
        0
    }

    // nft: .sui NFT
    // with the nft_name, owner of NFT is able to register third level domain,
    // e.g. `nft_name: eastagile.sui, id: dn => dn.eastagile.sui`
    // without the nft_name, only able to register second level domain, e.g. `dn.sui`
    // nft_name must be gotten from RegistrationNFT
    public(friend) fun register(
        registrar: &mut SuiRegistrar,
        registry: &mut Registry,
        nft_name: Option<String>,
        id: vector<u8>,
        owner: address,
        duration: u64,
        ctx: &mut TxContext
    ) {
        register_(registrar, registry, nft_name, id, owner, duration, true, ctx);
    }

    // nft: .sui NFT
    public(friend) fun register_only(
        registrar: &mut SuiRegistrar,
        registry: &mut Registry,
        nft_name: Option<String>,
        id: vector<u8>,
        owner: address,
        duration: u64,
        ctx: &mut TxContext
    ) {
        register_(registrar, registry, nft_name, id, owner, duration, false, ctx);
    }

    fun register_(
        registrar: &mut SuiRegistrar,
        registry: &mut Registry,
        nft_name: Option<String>,
        id: vector<u8>,
        owner: address,
        duration: u64,
        update_registry: bool,
        ctx: &mut TxContext
    ) {
        let sub_node = string::try_utf8(id);
        assert!(option::is_some(&sub_node), ESubnodeInvalid);
        let sub_node = option::extract(&mut sub_node);
        assert!(available(registrar, sub_node, ctx), ESubnodeUnAvailable);
        // Prevent future overflow
        // https://github.com/ensdomains/ens-contracts/blob/master/contracts/ethregistrar/BaseRegistrarImplementation.sol#L150
        // assert!(tx_context::epoch(ctx) + GRACE_PERIOD + duration > tx_context::epoch(ctx) + GRACE_PERIOD, 0);

        let detail = RegistrationDetail {
            expiry: tx_context::epoch(ctx) + duration,
            owner,
        };
        vec_map::insert(&mut registrar.expiries, sub_node, detail);

        let base_node: String;
        if (option::is_some(&nft_name)) base_node =  option::extract(&mut nft_name)
        else base_node = string::utf8(BASE_NODE);

        if (update_registry) {
            let new_record_event = base_registry::set_subnode_owner(registry, base_node, id, owner, ctx);
            if (option::is_some(&new_record_event)) {
                // if set_subnode_owner create a new record, the caller need to emit an event by themselves
                let event = option::extract(&mut new_record_event);
                let (object_id, resolver, ttl) = base_registry::get_record_event_fields(&event);
                event::emit(NameRegisteredEvent {
                    id: option::some(object_id),
                    resolver: option::some(resolver),
                    ttl: option::some(ttl),
                    base_node,
                    sub_node,
                    owner,
                    expiry: tx_context::epoch(ctx) + duration,
                });
                return
            }
        };

        event::emit(NameRegisteredEvent {
            id: option::none<ID>(),
            base_node,
            sub_node,
            owner,
            resolver: option::none<address>(),
            ttl: option::none<u64>(),
            expiry: tx_context::epoch(ctx) + duration,
        })
    }

    public fun record_exists(registrar: &SuiRegistrar, id: String): bool {
        vec_map::contains(&registrar.expiries, &id)
    }

    #[test_only]
    friend suins::sui_registrar_tests;
    #[test_only]
    /// Wrapper of module initializer for testing
    public fun test_init(ctx: &mut TxContext) {
        init(ctx)
    }
}
