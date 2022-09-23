module suins::sui_registrar {
    use sui::event;
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::TxContext;
    use sui::vec_map::{Self};
    use sui::vec_set;
    use suins::base_registry::{AdminCap, Registry};
    use sui::tx_context;
    use std::string;
    use std::option;
    use suins::base_registry;

    const BASE_NODE: vector<u8> = b"sui";
    // in terms of epoch
    const GRACE_PERIOD: u8 = 90;

    // errors in the range of 1..100 indicate Registrar errors
    const EUnauthorized: u64 = 1;
    const EOnlyController: u64 = 2;
    const EInvalidSubnode: u64 = 3;
    const ESubnodeUnAvailable: u64 = 4;

    struct ControllerAddedEvent has copy, drop {
        controller: address
    }

    struct ControllerRemovedEvent has copy, drop {
        controller: address
    }

    struct NameRegisteredEvent has copy, drop {
        subnode: string::String,
        owner: address,
        expiration_time: u64,
    }

    struct RegistryDetail has store, drop {
        expiration_time : u64,
    }

    struct RegistryDetailNFT has key {
        id: UID,
        subnode: string::String,
        expiration_time : u64,
    }

    struct SuiRegistrar has key {
        id: UID,
        subnodes: vec_map::VecMap<string::String, RegistryDetail>,
        controllers: vec_set::VecSet<address>,
    }

    fun init(ctx: &mut TxContext) {
        transfer::share_object(SuiRegistrar {
            id: object::new(ctx),
            subnodes: vec_map::empty(),
            controllers: vec_set::empty(),
        });
    }

    fun available(registrar: &SuiRegistrar, subnode: string::String, ctx: &TxContext): bool {
        if (vec_map::contains(&registrar.subnodes, &subnode)) {
            let expired_at = vec_map::get(&registrar.subnodes, &subnode).expiration_time;
            return expired_at + (GRACE_PERIOD as u64) < tx_context::epoch(ctx)
        };
        true
    }

    public entry fun add_controller(_: &AdminCap, registrar: &mut SuiRegistrar, controller: address) {
        vec_set::insert(&mut registrar.controllers, controller);
        event::emit(ControllerAddedEvent { controller });
    }

    public entry fun remove_controller(_: &AdminCap, registrar: &mut SuiRegistrar, controller: address) {
        vec_set::remove(&mut registrar.controllers, &controller);
        event::emit(ControllerRemovedEvent { controller });
    }

    public entry fun register(registry: &mut Registry, registrar: &mut SuiRegistrar, subnode: vector<u8>, owner: address, duration: u64, ctx: &mut TxContext) {
        assert!(vec_set::contains(&registrar.controllers, &tx_context::sender(ctx)), EOnlyController);

        let subnode = string::try_utf8(subnode);
        assert!(option::is_some(&subnode), EInvalidSubnode);

        let subnode = option::extract(&mut subnode);
        assert!(available(registrar, subnode, ctx), ESubnodeUnAvailable);
        // Prevent future overflow
        // https://github.com/ensdomains/ens-contracts/blob/master/contracts/ethregistrar/BaseRegistrarImplementation.sol#L150
        // assert!(tx_context::epoch(ctx) + GRACE_PERIOD + duration > tx_context::epoch(ctx) + GRACE_PERIOD, 0);

        let expiration_time = tx_context::epoch(ctx) + duration;
        let detail = RegistryDetail {
            expiration_time
        };
        vec_map::insert(&mut registrar.subnodes, subnode, detail);

        transfer::transfer(RegistryDetailNFT {
            id: object::new(ctx),
            subnode,
            expiration_time
        }, owner);
        base_registry::setSubnodeOwner(registry, owner, string::utf8(BASE_NODE), subnode, ctx);

        event::emit(NameRegisteredEvent {
            subnode,
            owner,
            expiration_time
        })
    }

    #[test_only]
    /// Wrapper of module initializer for testing
    public fun test_init(ctx: &mut TxContext) {
        init(ctx)
    }
}
