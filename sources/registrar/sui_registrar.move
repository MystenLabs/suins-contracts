module suins::sui_registrar {
    use sui::event;
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::TxContext;
    use sui::vec_map::{Self};
    use sui::vec_set;
    use suins::base_registry::{Registry, RegistrationNFT};
    use sui::tx_context;
    use std::string;
    use std::option;
    use suins::base_registry;
    use std::string::String;

    const BASE_NODE: vector<u8> = b"sui";
    // in terms of epoch
    const GRACE_PERIOD: u8 = 3;

    // errors in the range of 201..300 indicate Registrar errors
    const EUnauthorized: u64 = 201;
    const EOnlyController: u64 = 202;
    const ESubnodeInvalid: u64 = 203;
    const ESubnodeUnAvailable: u64 = 204;
    const ESubNodeExpired: u64 = 205;

    struct NameRegisteredEvent has copy, drop {
        subnode: String,
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
    public(friend) fun register(
        registrar: &mut SuiRegistrar,
        registry: &mut Registry,
        nft: &RegistrationNFT,
        id: vector<u8>,
        owner: address,
        duration: u64,
        ctx: &mut TxContext
    ) {
        register_(registrar, registry, nft, id, owner, duration, true, ctx);
    }

    // nft: .sui NFT
    public(friend) fun register_only(
        registrar: &mut SuiRegistrar,
        registry: &mut Registry,
        nft: &RegistrationNFT,
        id: vector<u8>,
        owner: address,
        duration: u64,
        ctx: &mut TxContext
    ) {
        register_(registrar, registry, nft, id, owner, duration, false, ctx);
    }

    fun register_(
        registrar: &mut SuiRegistrar,
        registry: &mut Registry,
        nft: &RegistrationNFT,
        id: vector<u8>,
        owner: address,
        duration: u64,
        update_registry: bool,
        ctx: &mut TxContext
    ) {
        // TODO: add later when implement controller
        // assert!(only_controller(registrar, ctx), EOnlyController) ;

        let subnode = string::try_utf8(id);
        assert!(option::is_some(&subnode), ESubnodeInvalid);
        let subnode = option::extract(&mut subnode);
        assert!(available(registrar, subnode, ctx), ESubnodeUnAvailable);
        // Prevent future overflow
        // https://github.com/ensdomains/ens-contracts/blob/master/contracts/ethregistrar/BaseRegistrarImplementation.sol#L150
        // assert!(tx_context::epoch(ctx) + GRACE_PERIOD + duration > tx_context::epoch(ctx) + GRACE_PERIOD, 0);

        let detail = RegistrationDetail {
            expiry: tx_context::epoch(ctx) + duration,
            owner,
        };
        vec_map::insert(&mut registrar.expiries, subnode, detail);
        if (update_registry) base_registry::set_subnode_owner(registry, nft, id, owner, ctx);

        event::emit(NameRegisteredEvent {
            subnode,
            owner,
            expiry: tx_context::epoch(ctx) + duration,
        })
    }

    fun only_controller(registrar: &SuiRegistrar, ctx: &TxContext): bool {
        vec_set::contains(&registrar.controllers, &tx_context::sender(ctx))
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
