/// This module is intended to maintain records of domain names including the owner, resolver address and time to live (TTL).
/// The owners of this only own the name, not own the registration.
/// It primarily facilitates the lending and borrowing of domain names.
module suins::base_registry {
    use sui::event;
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{TxContext, sender};
    use std::string::{Self, String};
    use suins::entity::SuiNS;
    use suins::entity::{
        Self,
        name_record_owner,
        name_record_owner_mut,
        name_record_resolver,
        name_record_resolver_mut,
        name_record_ttl,
        name_record_ttl_mut,
        new_name_record
    };
    use sui::table;

    friend suins::base_registrar;
    friend suins::reverse_registrar;
    friend suins::controller;
    friend suins::resolver;

    const MAX_TTL: u64 = 0x100000;

    // errors in the range of 101..200 indicate SuiNS errors
    const EUnauthorized: u64 = 101;

    // https://examples.sui.io/patterns/capability.html
    struct AdminCap has key, store { id: UID }

    struct NewOwnerEvent has copy, drop {
        node: String,
        owner: address,
    }

    struct NewResolverEvent has copy, drop {
        node: String,
        resolver: address,
    }

    struct NewTTLEvent has copy, drop {
        node: String,
        ttl: u64,
    }

    struct NewRecordEvent has copy, drop {
        node: String,
        owner: address,
        resolver: address,
        ttl: u64,
    }

    /// #### Notice
    /// This funtions allows owner of `node` to reassign ownership of this node.
    /// The `node` can have multiple levels.
    ///
    /// #### Dev
    /// `Record` indexed by `node` is updated.
    ///
    /// #### Params
    /// `node`: node to be updated
    /// `owner`: new owner address
    ///
    /// Panics
    /// Panics if caller isn't the owner of `node`
    /// or `node` doesn't exists.
    public entry fun set_owner(suins: &mut SuiNS, node: vector<u8>, owner: address, ctx: &mut TxContext) {
        authorised(suins, node, ctx);

        let node = string::utf8(node);
        set_owner_internal(suins, node, owner);
        event::emit(NewOwnerEvent { node, owner });
    }

    /// #### Notice
    /// This funtions allow owner of `node` to reassign ownership of subnode.
    /// The `node` can have multiple levels.
    /// The subnode which is created by `label`.`node` must exist.
    ///
    /// #### Dev
    /// `Record` indexed by `label`.`node` is updated.
    ///
    /// #### Params
    /// `node`: node to get subnode
    /// `label`: label of subnode
    /// `owner`: new owner address
    ///
    /// Panics
    /// Panics if caller isn't the owner of `node`
    /// or `subnode` doesn't exists.
    public entry fun set_subnode_owner(
        suins: &mut SuiNS,
        node: vector<u8>,
        label: vector<u8>,
        owner: address,
        ctx: &mut TxContext,
    ) {
        // TODO: `node` can have multiple levels, should disable it because we don't support subdomain atm
        // FIXME: only allow nodes of 2 levels to reassign
        authorised(suins, node, ctx);

        let subnode = make_node(label, string::utf8(node));
        // requires both node and subnode to exist
        set_owner_internal(suins, subnode, owner);
        event::emit(NewOwnerEvent { node: subnode, owner });
    }

    /// #### Notice
    /// This funtions allows owner of `node` to reassign resolver address of this node.
    /// The `node` can have multiple levels.
    ///
    /// #### Dev
    /// `Record` indexed by `node` is updated.
    ///
    /// #### Params
    /// `node`: node to get subnode
    /// `resolver`: new resolver address
    ///
    /// Panics
    /// Panics if caller isn't the owner of `node`
    /// or `node` doesn't exists.
    public entry fun set_resolver(suins: &mut SuiNS, node: vector<u8>, resolver: address, ctx: &mut TxContext) {
        authorised(suins, node, ctx);
        
        let registry = entity::registry_mut(suins);
        let node = string::utf8(node);
        let record = table::borrow_mut(registry, node);
        *entity::name_record_resolver_mut(record) = resolver;
        event::emit(NewResolverEvent { node, resolver });
    }

    /// #### Notice
    /// This funtions allows owner of `node` to reassign ttl address of this node.
    /// The `node` can have multiple levels.
    ///
    /// #### Dev
    /// `Record` indexed by `node` is updated.
    ///
    /// #### Params
    /// `node`: node to get subnode
    /// `ttl`: new TTL address
    ///
    /// Panics
    /// Panics if caller isn't the owner of `node`
    /// or `node` doesn't exists.
    public entry fun set_TTL(suins: &mut SuiNS, node: vector<u8>, ttl: u64, ctx: &mut TxContext) {
        // TODO: does this function have any use?
        authorised(suins, node, ctx);

        let registry = entity::registry_mut(suins);
        let node = string::utf8(node);
        let record = table::borrow_mut(registry, node);
        *entity::name_record_ttl_mut(record) = ttl;
        event::emit(NewTTLEvent { node, ttl });
    }

    // === Public Functions ===

    /// #### Notice
    /// Get owner address of a `node`.
    /// The `node` can have multiple levels.
    ///
    /// #### Params
    /// `node`: node to find the owner
    ///
    /// Panics
    /// Panics if `node` doesn't exists.
    public fun owner(suins: &SuiNS, node: vector<u8>): address {
        let registry = entity::registry(suins);
        let name_record = table::borrow(registry, string::utf8(node));
        *name_record_owner(name_record)
    }

    /// #### Notice
    /// Get resolver address of a `node`.
    /// The `node` can have multiple levels.
    ///
    /// #### Params
    /// `node`: node to find the resolver address
    ///
    /// Panics
    /// Panics if `node` doesn't exists.
    public fun resolver(suins: &SuiNS, node: vector<u8>): address {
        let registry = entity::registry(suins);
        let name_record = table::borrow(registry, string::utf8(node));
        *name_record_resolver(name_record)
    }

    /// #### Notice
    /// Get ttl of a `node`.
    /// The `node` can have multiple levels.
    ///
    /// #### Params
    /// `node`: node to find the ttl
    ///
    /// Panics
    /// Panics if `node` doesn't exists.
    public fun ttl(suins: &SuiNS, node: vector<u8>): u64 {
        let registry = entity::registry(suins);
        let name_record = table::borrow(registry, string::utf8(node));
        *name_record_ttl(name_record)
    }

    /// #### Notice
    /// Get `(owner, resolver, ttl)` of a `node`.
    /// The `node` can have multiple levels.
    ///
    /// #### Params
    /// `node`: node to find the ttl
    ///
    /// Panics
    /// Panics if `node` doesn't exists.
    public fun get_record_by_key(suins: &SuiNS, key: String): (address, address, u64) {
        let registry = entity::registry(suins);
        let name_record = table::borrow(registry, key);

        (*name_record_owner(name_record), *name_record_resolver(name_record), *name_record_ttl(name_record))
    }

    // === Friend and Private Functions ===

    public(friend) fun authorised(suins: &SuiNS, node: vector<u8>, ctx: &TxContext) {
        let owner = owner(suins, node);
        assert!(sender(ctx) == owner, EUnauthorized);
    }

    public(friend) fun set_owner_internal(suins: &mut SuiNS, node: String, owner: address) {
        let registry = entity::registry_mut(suins);
        let name_record = table::borrow_mut(registry, node);
        *name_record_owner_mut(name_record) = owner
    }

    // this function is intended to be called by the Registrar, no need to check for owner
    public(friend) fun set_record_internal(
        suins: &mut SuiNS,
        node: String,
        owner: address,
        resolver: address,
        ttl: u64,
    ) {
        let registry = entity::registry_mut(suins);
        if (table::contains(registry, node)) {
            let record = table::borrow_mut(registry, node);
            *name_record_owner_mut(record) = owner;
            *name_record_resolver_mut(record) = resolver;
            *name_record_ttl_mut(record) = ttl;
        } else new_record(suins, node, owner, resolver, ttl);
    }

    public(friend) fun make_node(label: vector<u8>, base_node: String): String {
        let node = string::utf8(label);
        string::append_utf8(&mut node, b".");
        string::append(&mut node, base_node);
        node
    }

    fun init(ctx: &mut TxContext) {
        transfer::transfer(AdminCap {
            id: object::new(ctx)
        }, sender(ctx));
    }

    fun new_record(
        suins: &mut SuiNS,
        node: String,
        owner: address,
        resolver: address,
        ttl: u64,
    ) {
        let record = new_name_record(owner, resolver, ttl);
        let registry = entity::registry_mut(suins);
        table::add(registry, node, record);
    }

    #[test_only]
    friend suins::base_registry_tests;
    #[test_only]
    friend suins::resolver_tests;

    #[test_only]
    public fun new_record_test(suins: &mut SuiNS, node: String, owner: address) {
        new_record(suins, node, owner, @0x0, 0);
    }

    #[test_only]
    public fun record_exists(suins: &SuiNS, node: String): bool {
        let registry = entity::registry(suins);
        table::contains(registry, node)
    }

    #[test_only]
    /// Wrapper of module initializer for testing
    public fun test_init(ctx: &mut TxContext) {
        transfer::transfer(AdminCap {
            id: object::new(ctx)
        }, sender(ctx));
    }
}
