/// This module is intended to maintain records of domain names including the owner, resolver address and time to live (TTL).
/// The owners of this only own the name, not own the registration.
/// It primarily facilitates the lending and borrowing of domain names.
module suins::registry {
    use sui::event;
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{TxContext, sender};
    use std::string::{Self, String, utf8};
    use suins::entity::{SuiNS, NameRecord};
    use suins::entity::{
        Self,
        name_record_owner,
        name_record_owner_mut,
        name_record_ttl,
        name_record_ttl_mut,
        new_name_record,
        name_record_linked_addr,
        name_record_default_domain_name,
    };
    use sui::table;
    use sui::hex;
    use sui::address;

    friend suins::registrar;
    friend suins::reverse_registrar;
    friend suins::controller;

    const MAX_TTL: u64 = 0x100000;
    const NAME: vector<u8> = b"name";
    const ADDR: vector<u8> = b"addr";
    const AVATAR: vector<u8> = b"avatar";
    const CONTENTHASH: vector<u8> = b"contenthash";
    const ADDR_REVERSE_TLD: vector<u8> = b"addr.reverse";

    // errors in the range of 101..200 indicate SuiNS errors
    const EUnauthorized: u64 = 101;
    const EDomainNameNotExists: u64 = 102;
    const EKeyNotExists: u64 = 103;
    const EDefaultDomainNameNotMatch: u64 = 104;

    // https://examples.sui.io/patterns/capability.html
    struct AdminCap has key, store { id: UID }

    struct OwnerChangedEvent has copy, drop {
        domain_name: String,
        new_owner: address,
    }

    struct ResolverChangedEvent has copy, drop {
        domain_name: String,
        new_resolver: address,
    }

    struct TTLChangedEvent has copy, drop {
        domain_name: String,
        new_ttl: u64,
    }

    struct NewRecordEvent has copy, drop {
        node: String,
        owner: address,
        resolver: address,
        ttl: u64,
    }

    struct DataChangedEvent has copy, drop {
        domain_name: String,
        key: String,
        new_value: String,
    }

    struct DataRemovedEvent has copy, drop {
        domain_name: String,
        key: String,
    }

    struct LinkedAddrChangedEvent has copy, drop {
        domain_name: String,
        new_addr: address,
    }

    struct LinkedAddrRemovedEvent has copy, drop {
        domain_name: String,
    }

    struct DefaultDomainNameChangedEvent has copy, drop {
        domain_name: String,
        new_default_domain_name: String,
    }

    struct DefaultDomainNameRemovedEvent has copy, drop {
        domain_name: String,
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
    public entry fun set_owner(suins: &mut SuiNS, domain_name: vector<u8>, owner: address, ctx: &mut TxContext) {
        authorised(suins, domain_name, ctx);

        let domain_name = string::utf8(domain_name);
        set_owner_internal(suins, domain_name, owner);
        event::emit(OwnerChangedEvent { domain_name, new_owner: owner });
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
    public entry fun set_subdomain_name_owner(
        suins: &mut SuiNS,
        domain_name: vector<u8>,
        label: vector<u8>,
        owner: address,
        ctx: &mut TxContext,
    ) {
        authorised(suins, domain_name, ctx);

        let subdomain_name = make_subdomain_name(label, utf8(domain_name));
        set_owner_internal(suins, subdomain_name, owner);
        event::emit(OwnerChangedEvent { domain_name: subdomain_name, new_owner: owner });
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
    public entry fun set_ttl(suins: &mut SuiNS, domain_name: vector<u8>, ttl: u64, ctx: &mut TxContext) {
        authorised(suins, domain_name, ctx);

        let domain_name = string::utf8(domain_name);
        let record = get_name_record_mut(suins, domain_name);

        *entity::name_record_ttl_mut(record) = ttl;
        event::emit(TTLChangedEvent { domain_name, new_ttl: ttl });
    }

    /// #### Notice
    /// This funtions allows owner of `node` to set content hash url.
    ///
    /// #### Dev
    /// Create 'contenthash' key if not exist.
    /// `hash` isn't validated.
    ///
    /// #### Params
    /// `node`: node to be updated
    /// `hash`: content hash url
    ///
    /// Panics
    /// Panics if caller isn't the owner of `node`
    public entry fun set_data(
        suins: &mut SuiNS,
        domain_name: vector<u8>,
        key: vector<u8>,
        new_value: vector<u8>,
        ctx: &mut TxContext
    ) {
        authorised(suins, domain_name, ctx);

        let domain_name = utf8(domain_name);
        let key = utf8(key);
        let new_value = utf8(new_value);
        let name_record = get_name_record_mut(suins, domain_name);
        let name_record_data = entity::name_record_data_mut(name_record);

        if (table::contains(name_record_data, key)) *table::borrow_mut(name_record_data, key) = new_value
        else table::add(name_record_data, key, new_value);

        event::emit(DataChangedEvent { domain_name, key, new_value });
    }

    /// #### Notice
    /// This funtions allows owner of `node` to unset content hash url.
    ///
    /// #### Params
    /// `node`: node to be updated
    ///
    /// Panics
    /// Panics if caller isn't the owner of `node`
    /// or `node` doesn't exist.
    public entry fun unset_data(
        suins: &mut SuiNS,
        domain_name: vector<u8>,
        key: vector<u8>,
        ctx: &mut TxContext
    ) {
        authorised(suins, domain_name, ctx);

        let domain_name = utf8(domain_name);
        let key = utf8(key);
        let name_record = get_name_record_mut(suins, domain_name);
        let name_record_data = entity::name_record_data_mut(name_record);

        table::remove(name_record_data, key);
        event::emit(DataRemovedEvent { domain_name, key });
    }

    /// #### Notice
    /// This funtions allows owner of `domain_name` to set default addr.
    ///
    /// #### Params
    /// `node`: node to be updated
    /// `new_addr`: new address value
    ///
    /// Panics
    /// Panics if caller isn't the owner of `node`
    public entry fun set_linked_addr(
        suins: &mut SuiNS,
        domain_name: vector<u8>,
        new_addr: address,
        ctx: &mut TxContext,
    ) {
        authorised(suins, domain_name, ctx);

        let domain_name = utf8(domain_name);
        let name_record = get_name_record_mut(suins, domain_name);

        *entity::name_record_linked_addr_mut(name_record) = new_addr;
        event::emit(LinkedAddrChangedEvent { domain_name, new_addr });
    }

    public entry fun unset_linked_addr(
        suins: &mut SuiNS,
        domain_name: vector<u8>,
        ctx: &mut TxContext,
    ) {
        authorised(suins, domain_name, ctx);

        let domain_name = utf8(domain_name);
        let name_record = get_name_record_mut(suins, domain_name);

        *entity::name_record_linked_addr_mut(name_record) = @0x0;
        event::emit(LinkedAddrRemovedEvent { domain_name });
    }

    public entry fun set_default_domain_name(
        suins: &mut SuiNS,
        new_default_domain_name: vector<u8>,
        ctx: &mut TxContext,
    ) {
        let reverse_label = hex::encode(address::to_bytes(sender(ctx)));
        let reverse_domain_name = make_subdomain_name(reverse_label, utf8(ADDR_REVERSE_TLD));
        let name_record = get_name_record_mut(suins, reverse_domain_name);
        let new_default_domain_name = utf8(new_default_domain_name);

        *entity::name_record_default_domain_name_mut(name_record) = new_default_domain_name;
        event::emit(DefaultDomainNameChangedEvent { domain_name: reverse_domain_name, new_default_domain_name });
    }

    public entry fun unset_default_domain_name(
        suins: &mut SuiNS,
        ctx: &mut TxContext,
    ) {
        let reverse_label = hex::encode(address::to_bytes(sender(ctx)));
        let reverse_domain_name = make_subdomain_name(reverse_label, utf8(ADDR_REVERSE_TLD));
        let name_record = get_name_record_mut(suins, reverse_domain_name);

        *entity::name_record_default_domain_name_mut(name_record) = utf8(b"");
        event::emit(DefaultDomainNameRemovedEvent { domain_name: reverse_domain_name });
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
    public fun owner(suins: &SuiNS, domain_name: vector<u8>): address {
        let name_record = get_name_record(suins, utf8(domain_name));
        entity::name_record_owner(name_record)
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
    public fun ttl(suins: &SuiNS, domain_name: vector<u8>): u64 {
        let name_record = get_name_record(suins, utf8(domain_name));
        name_record_ttl(name_record)
    }

    public fun linked_addr(suins: &SuiNS, domain_name: vector<u8>): address {
        let name_record = get_name_record(suins, utf8(domain_name));
        name_record_linked_addr(name_record)
    }

    public fun default_domain_name(suins: &SuiNS, addr: address): String {
        let reverse_label = hex::encode(address::to_bytes(addr));
        let reverse_domain_name = make_subdomain_name(reverse_label, utf8(ADDR_REVERSE_TLD));
        let reverse_name_record = get_name_record(suins, reverse_domain_name);

        let default_domain_name = name_record_default_domain_name(reverse_name_record);
        let default_domain_name_record = get_name_record(suins, default_domain_name);
        assert!(name_record_linked_addr(default_domain_name_record) == addr, EDefaultDomainNameNotMatch);

        default_domain_name
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
    public fun get_name_record_all_fields(suins: &SuiNS, domain_name: vector<u8>): (address, address, u64, String) {
        let name_record = get_name_record(suins, utf8(domain_name));
        (name_record_owner(name_record), name_record_linked_addr(name_record), name_record_ttl(name_record), name_record_default_domain_name(name_record))
    }

    public fun get_name_record_data(suins: &SuiNS, domain_name: vector<u8>, key: vector<u8>): String {
        let name_record = get_name_record(suins, utf8(domain_name));
        let name_record_data = entity::name_record_data(name_record);
        let key = utf8(key);

        assert!(table::contains(name_record_data, key), EKeyNotExists);
        *table::borrow(name_record_data, key)
    }

    // === Friend and Private Functions ===

    public(friend) fun authorised(suins: &SuiNS, domain_name: vector<u8>, ctx: &TxContext) {
        let owner = owner(suins, domain_name);
        assert!(sender(ctx) == owner, EUnauthorized);
    }

    public(friend) fun set_owner_internal(suins: &mut SuiNS, domain_name: String, owner: address) {
        let name_record = get_name_record_mut(suins, domain_name);
        *name_record_owner_mut(name_record) = owner
    }

    public(friend) fun addr_reverse_tld(): String {
        string::utf8(ADDR_REVERSE_TLD)
    }

    // this function is intended to be called by the Registrar, no need to check for owner
    public(friend) fun set_record_internal(
        suins: &mut SuiNS,
        domain_name: String,
        owner: address,
        ttl: u64,
        ctx: &mut TxContext,
    ) {
        let registry = entity::registry_mut(suins);
        if (table::contains(registry, domain_name)) {
            let record = table::borrow_mut(registry, domain_name);
            *name_record_owner_mut(record) = owner;
            *name_record_ttl_mut(record) = ttl;
        } else new_record(suins, domain_name, owner, ttl, ctx);
    }

    public(friend) fun make_subdomain_name(label: vector<u8>, base_domain_name: String): String {
        let subdomain_name = string::utf8(label);
        string::append_utf8(&mut subdomain_name, b".");
        string::append(&mut subdomain_name, base_domain_name);
        subdomain_name
    }

    fun init(ctx: &mut TxContext) {
        transfer::transfer(AdminCap {
            id: object::new(ctx)
        }, sender(ctx));
    }

    fun new_record(
        suins: &mut SuiNS,
        domain_name: String,
        owner: address,
        ttl: u64,
        ctx: &mut TxContext,
    ) {
        let record = new_name_record(owner, ttl, ctx);
        let registry = entity::registry_mut(suins);
        table::add(registry, domain_name, record);
    }

    fun get_name_record(suins: &SuiNS, domain_name: String): &NameRecord {
        let registry = entity::registry(suins);
        assert!(table::contains(registry, domain_name), EDomainNameNotExists);
        table::borrow(registry, domain_name)
    }

    fun get_name_record_mut(suins: &mut SuiNS, domain_name: String): &mut NameRecord {
        let registry = entity::registry_mut(suins);
        assert!(table::contains(registry, domain_name), EDomainNameNotExists);
        table::borrow_mut(registry, domain_name)
    }

    #[test_only]
    friend suins::registry_tests;
    #[test_only]
    friend suins::registry_tests_2;

    #[test_only]
    public fun new_record_test(suins: &mut SuiNS, domain_name: String, owner: address, ctx: &mut TxContext) {
        new_record(suins, domain_name, owner, 0, ctx);
    }

    #[test_only]
    public fun record_exists(suins: &SuiNS, node: String): bool {
        let registry = entity::registry(suins);
        table::contains(registry, node)
    }

    #[test_only]
    public fun default_domain_name_test(suins: &SuiNS, addr: address): String {
        let reverse_label = hex::encode(address::to_bytes(addr));
        let reverse_domain_name = make_subdomain_name(reverse_label, utf8(ADDR_REVERSE_TLD));
        let reverse_name_record = get_name_record(suins, reverse_domain_name);

        name_record_default_domain_name(reverse_name_record)
    }

    #[test_only]
    /// Wrapper of module initializer for testing
    public fun test_init(ctx: &mut TxContext) {
        transfer::transfer(AdminCap {
            id: object::new(ctx)
        }, sender(ctx));
    }
}
