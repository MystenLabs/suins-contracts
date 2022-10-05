module suins::sui_registrar {
    use sui::event;
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::vec_map::{Self, VecMap};
    use sui::vec_set::{Self, VecSet};
    use suins::base_registry::{Self, Registry, AdminCap};
    use std::string::{Self, String};
    use std::option::{Self, Option};

    const BASE_NODE: vector<u8> = b"sui";
    // in terms of epoch
    const GRACE_PERIOD: u8 = 90;

    // errors in the range of 201..300 indicate Registrar errors
    const EUnauthorized: u64 = 201;
    const EInvalidLabel: u64 = 203;
    const ELabelUnAvailable: u64 = 204;
    const ELabelExpired: u64 = 205;
    const EInvalidDuration: u64 = 206;
    const ELabelNotExists: u64 = 207;

    struct NameRegisteredEvent has copy, drop {
        // id: Option<ID>,
        resolver: Option<address>,
        ttl: Option<u64>,
        // subnode = label + '.' + node, e.g, eastagile.sui
        node: String,
        label: String,
        owner: address,
        expiry: u64,
    }

    struct NameRenewedEvent has copy, drop {
        label: String,
        expiry: u64,
    }

    struct RegistrationDetail has store {
        expiry: u64,
        owner: address,
        approval: Option<address>,
    }

    struct SuiRegistrar has key {
        id: UID,
        // key is label, e.g. 'eastagile', 'dn.eastagile'
        expiries: VecMap<String, RegistrationDetail>,
        operators: VecMap<address, VecSet<address>>,
    }

    fun init(ctx: &mut TxContext) {
        transfer::share_object(SuiRegistrar {
            id: object::new(ctx),
            expiries: vec_map::empty(),
            operators: vec_map::empty(),
        });
    }

    public fun available(registrar: &SuiRegistrar, label: String, ctx: &TxContext): bool {
        let expiry = name_expires(registrar, label);
        if (expiry != 0 ) {
            return expiry + (GRACE_PERIOD as u64) < tx_context::epoch(ctx)
        };
        true
    }

    public fun name_expires(registrar: &SuiRegistrar, label: String): u64 {
        if (record_exists(registrar, label)) {
            // TODO: can return whole RegistrationDetail to not look up again
            return vec_map::get(&registrar.expiries, &label).expiry
        };
        0
    }

    // nft: .sui NFT
    // label can be multiple levels, e.g. 'dn.eastagile' or 'eastagile'
    public(friend) fun register(
        registrar: &mut SuiRegistrar,
        registry: &mut Registry,
        label: vector<u8>,
        owner: address,
        duration: u64,
        ctx: &mut TxContext
    ) {
        register_internal(registrar, registry, label, owner, duration, true, ctx);
    }

    // nft: .sui NFT
    public(friend) fun register_only(
        registrar: &mut SuiRegistrar,
        registry: &mut Registry,
        label: vector<u8>,
        owner: address,
        duration: u64,
        ctx: &mut TxContext
    ) {
        register_internal(registrar, registry, label, owner, duration, false, ctx);
    }

    public(friend) fun renew(registrar: &mut SuiRegistrar, label: vector<u8>, duration: u64, ctx: &TxContext): u64 {
        let label = string::utf8(label);
        let expiry = name_expires(registrar, label);
        assert!(expiry > 0, ELabelNotExists);
        assert!(expiry + (GRACE_PERIOD as u64) >= tx_context::epoch(ctx), ELabelExpired);

        let detail = vec_map::get_mut(&mut registrar.expiries, &label);
        detail.expiry = detail.expiry + duration;

        event::emit(NameRenewedEvent { label, expiry: detail.expiry });
        detail.expiry
    }

    public entry fun set_resolver(_: &AdminCap, registry: &mut Registry, resolver: address, ctx: &mut TxContext) {
        base_registry::set_resolver(registry, BASE_NODE, resolver, ctx);
    }

    public entry fun reclaim(
        registrar: &SuiRegistrar,
        registry: &mut Registry,
        label: vector<u8>,
        owner: address,
        ctx: &mut TxContext
    ) {
        assert!(
            is_approved_or_owner(registrar, string::utf8(label), ctx),
            EUnauthorized
        );
        base_registry::set_subnode_owner(registry, string::utf8(BASE_NODE), label, owner);
    }

    fun register_internal(
        registrar: &mut SuiRegistrar,
        registry: &mut Registry,
        label: vector<u8>,
        owner: address,
        duration: u64,
        update_registry: bool,
        ctx: &mut TxContext
    ) {
        let label_string = string::try_utf8(label);
        assert!(option::is_some(&label_string), EInvalidLabel);
        let label_string = option::extract(&mut label_string);
        assert!(available(registrar, label_string, ctx), ELabelUnAvailable);
        assert!(duration > 0, EInvalidDuration);
        // Prevent future overflow
        // https://github.com/ensdomains/ens-contracts/blob/master/contracts/ethregistrar/BaseRegistrarImplementation.sol#L150
        // assert!(tx_context::epoch(ctx) + GRACE_PERIOD + duration > tx_context::epoch(ctx) + GRACE_PERIOD, 0);

        let detail = RegistrationDetail {
            expiry: tx_context::epoch(ctx) + duration,
            owner,
            approval: option::none(),
        };
        vec_map::insert(&mut registrar.expiries, label_string, detail);

        if (update_registry) {
            let new_record_event =
                base_registry::set_subnode_owner(registry, string::utf8(BASE_NODE), label, owner);
            if (option::is_some(&new_record_event)) {
                // if set_subnode_owner create a new record, the caller need to emit an event by themselves
                let event = option::extract(&mut new_record_event);
                let (resolver, ttl) = base_registry::get_record_event_fields(&event);
                event::emit(NameRegisteredEvent {
                    resolver: option::some(resolver),
                    ttl: option::some(ttl),
                    node: string::utf8(BASE_NODE),
                    label: label_string,
                    owner,
                    expiry: tx_context::epoch(ctx) + duration,
                });
                return
            }
        };

        event::emit(NameRegisteredEvent {
            // id: option::none<ID>(),
            node: string::utf8(BASE_NODE),
            label: label_string,
            owner,
            resolver: option::none<address>(),
            ttl: option::none<u64>(),
            expiry: tx_context::epoch(ctx) + duration,
        })
    }

    public fun record_exists(registrar: &SuiRegistrar, label: String): bool {
        vec_map::contains(&registrar.expiries, &label)
    }

    public fun owner_of(registrar: &SuiRegistrar, label: String, ctx: &TxContext): address {
        assert!(name_expires(registrar, label) > tx_context::epoch(ctx), ELabelExpired);
        vec_map::get(&registrar.expiries, &label).owner
    }

    fun get_approved(registrar: &SuiRegistrar, label: String): address {
        let approval = vec_map::get(&registrar.expiries, &label).approval;
        if (option::is_some(&approval)) option::extract(&mut approval)
        else @0x0
    }

    fun is_approved_for_all(registrar: &SuiRegistrar, owner: address, operator: address): bool {
        if (vec_map::contains(&registrar.operators, &owner)) {
            let operators = vec_map::get(&registrar.operators, &owner);
            return vec_set::contains(operators, &operator)
        };
        false
    }

    fun is_approved_or_owner(registrar: &SuiRegistrar, label: String, ctx: &TxContext): bool {
        let owner = owner_of(registrar, label, ctx);
        let spender = tx_context::sender(ctx);
        spender == owner ||
            spender == get_approved(registrar, label) ||
            is_approved_for_all(registrar, owner, spender)
    }

    #[test_only]
    friend suins::sui_registrar_tests;
    #[test_only]
    /// Wrapper of module initializer for testing
    public fun test_init(ctx: &mut TxContext) {
        init(ctx)
    }
}
