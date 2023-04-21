/// This module is intended to maintain records of domain names including the owner, linked address, default domain name and time to live (TTL).
/// The owners of this only own the name, not own the registration.
/// It primarily facilitates the lending and borrowing of domain names.
module suins::registry {
    use sui::event;
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{TxContext, sender};
    use std::string::String;
    use suins::entity::{SuiNS, NameRecord};
    use suins::entity::{
        Self,
        name_record_owner,
        name_record_owner_mut,
        name_record_ttl,
        name_record_ttl_mut,
        new_name_record,
        name_record_linked_addr,
        name_record_linked_addr_mut,
    };
    use sui::table;

    friend suins::registrar;
    friend suins::controller;

    const MAX_TTL: u64 = 0x100000;
    const NAME: vector<u8> = b"name";
    const ADDR: vector<u8> = b"addr";
    const AVATAR: vector<u8> = b"avatar";
    const CONTENTHASH: vector<u8> = b"contenthash";

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

    struct TTLChangedEvent has copy, drop {
        domain_name: String,
        new_ttl: u64,
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
        address: address,
        new_default_domain_name: String,
    }

    struct DefaultDomainNameRemovedEvent has copy, drop {
        address: address,
    }

    /// #### Notice
    /// This funtions allows owner of `domain name` to reassign ownership of this domain name.
    /// The `domain name` can have multiple levels.
    ///
    /// #### Dev
    /// `Record` indexed by `domain name` is updated.
    ///
    /// #### Params
    /// `domain name`: domain name to be updated
    /// `owner`: new owner address
    ///
    /// Panics
    /// Panics if caller isn't the owner of `domain name`
    /// or `domain name` doesn't exists.
    public entry fun set_owner(suins: &mut SuiNS, domain_name: String, owner: address, ctx: &mut TxContext) {
        is_authorised(suins, domain_name, ctx);

        set_owner_internal(suins, domain_name, owner);
        event::emit(OwnerChangedEvent { domain_name, new_owner: owner });
    }

    /// #### Notice
    /// This funtions allows owner of `domain name` to reassign ttl address of this domain name.
    /// The `domain name` can have multiple levels.
    ///
    /// #### Dev
    /// `Record` indexed by `domain name` is updated.
    ///
    /// #### Params
    /// `ttl`: new TTL address
    ///
    /// Panics
    /// Panics if caller isn't the owner of `domain name`
    /// or `domain name` doesn't exists.
    public entry fun set_ttl(suins: &mut SuiNS, domain_name: String, ttl: u64, ctx: &mut TxContext) {
        is_authorised(suins, domain_name, ctx);

        let domain_name = domain_name;
        let record = get_name_record_mut(suins, domain_name);

        *entity::name_record_ttl_mut(record) = ttl;
        event::emit(TTLChangedEvent { domain_name, new_ttl: ttl });
    }

    /// #### Notice
    /// This funtions allows owner of `domain name` to set custom data.
    ///
    /// #### Params
    /// `domain_name`: domain name to be updated
    /// `hash`: content hash url
    ///
    /// Panics
    /// Panics if caller isn't the owner of `domain name`
    public entry fun set_data(
        suins: &mut SuiNS,
        domain_name: String,
        key: String,
        new_value: String,
        ctx: &mut TxContext
    ) {
        is_authorised(suins, domain_name, ctx);

        let domain_name = domain_name;
        let name_record = get_name_record_mut(suins, domain_name);
        let name_record_data = entity::name_record_data_mut(name_record);

        if (table::contains(name_record_data, key)) *table::borrow_mut(name_record_data, key) = new_value
        else table::add(name_record_data, key, new_value);

        event::emit(DataChangedEvent { domain_name, key, new_value });
    }

    /// #### Notice
    /// This funtions allows owner of `domain_name` to unset custom data.
    ///
    /// #### Params
    /// `domain_name`: domain name to be updated
    ///
    /// Panics
    /// Panics if caller isn't the owner of `domain_name`
    /// or `domain_name` doesn't exist.
    public entry fun unset_data(
        suins: &mut SuiNS,
        domain_name: String,
        key: String,
        ctx: &mut TxContext
    ) {
        is_authorised(suins, domain_name, ctx);

        let name_record = get_name_record_mut(suins, domain_name);
        let name_record_data = entity::name_record_data_mut(name_record);

        table::remove(name_record_data, key);
        event::emit(DataRemovedEvent { domain_name, key });
    }

    /// #### Notice
    /// This funtions allows owner of `domain_name` to set linked addr.
    ///
    /// #### Params
    /// `domain_name`: domain_name to be updated
    /// `new_addr`: new address value
    ///
    /// Panics
    /// Panics if caller isn't the owner of `domain_name`
    public entry fun set_linked_addr(
        suins: &mut SuiNS,
        domain_name: String,
        new_addr: address,
        ctx: &mut TxContext,
    ) {
        is_authorised(suins, domain_name, ctx);

        let name_record = get_name_record_mut(suins, domain_name);
        let old_linked_addr = entity::name_record_linked_addr(name_record);
        *entity::name_record_linked_addr_mut(name_record) = new_addr;
        event::emit(LinkedAddrChangedEvent { domain_name, new_addr });

        if (old_linked_addr != new_addr) {
            let reverse_registry = entity::reverse_registry_mut(suins);
            if (table::contains(reverse_registry, old_linked_addr)) {
                table::remove(reverse_registry, old_linked_addr);
            };
        };
    }

    public entry fun unset_linked_addr(
        suins: &mut SuiNS,
        domain_name: String,
        ctx: &mut TxContext,
    ) {
        is_authorised(suins, domain_name, ctx);

        let name_record = get_name_record_mut(suins, domain_name);
        let old_linked_addr = entity::name_record_linked_addr(name_record);
        *entity::name_record_linked_addr_mut(name_record) = @0x0;
        event::emit(LinkedAddrRemovedEvent { domain_name });

        let reverse_registry = entity::reverse_registry_mut(suins);
        if (table::contains(reverse_registry, old_linked_addr)) {
            table::remove(reverse_registry, old_linked_addr);
        };
    }

    public entry fun set_default_domain_name(
        suins: &mut SuiNS,
        new_default_domain_name: String,
        ctx: &mut TxContext,
    ) {
        let sender_address = sender(ctx);
        let record = get_name_record(suins, new_default_domain_name);

        // When setting a defalt domain name for an address, the domain name
        // must already be pointing at the address
        assert!(
            sender_address == entity::name_record_linked_addr(record),
            EDefaultDomainNameNotMatch
        );

        let reverse_registry = entity::reverse_registry_mut(suins);

        if (table::contains(reverse_registry, sender_address)) {
            let default_domain_name = table::borrow_mut(reverse_registry, sender_address);
            *default_domain_name = new_default_domain_name;
        } else {
            table::add(reverse_registry, sender_address, new_default_domain_name);
        };

        event::emit(DefaultDomainNameChangedEvent { address: sender_address, new_default_domain_name });
    }

    public entry fun unset_default_domain_name(
        suins: &mut SuiNS,
        ctx: &mut TxContext,
    ) {
        let sender_address = sender(ctx);
        let reverse_registry = entity::reverse_registry_mut(suins);
        table::remove(reverse_registry, sender_address);

        event::emit(DefaultDomainNameRemovedEvent { address: sender_address });
    }

    // === Public Functions ===

    /// #### Notice
    /// Get owner address of a `domain_name`.
    /// The `domain_name` can have multiple levels.
    ///
    /// #### Params
    /// `domain_name`: domain name to find the owner
    ///
    /// Panics
    /// Panics if `domain_name` doesn't exists.
    public fun owner(suins: &SuiNS, domain_name: String): address {
        let name_record = get_name_record(suins, domain_name);
        entity::name_record_owner(name_record)
    }

    /// #### Notice
    /// Get ttl of a `domain_name`.
    ///
    /// #### Params
    /// `domain_name`: domain name to find the ttl
    ///
    /// Panics
    /// Panics if `domain_name` doesn't exists.
    public fun ttl(suins: &SuiNS, domain_name: String): u64 {
        let name_record = get_name_record(suins, domain_name);
        name_record_ttl(name_record)
    }

    public fun linked_addr(suins: &SuiNS, domain_name: String): address {
        let name_record = get_name_record(suins, domain_name);
        name_record_linked_addr(name_record)
    }

    public fun default_domain_name(suins: &SuiNS, addr: address): String {
        let reverse_registry = entity::reverse_registry(suins);

        let default_domain_name = *table::borrow(reverse_registry, addr);

        default_domain_name
    }

    /// #### Notice
    /// Get `(owner, linked_addr, ttl)` of a `domain_name`.
    /// The `domain_name` can have multiple levels.
    ///
    /// #### Params
    /// `domain_name`: domain_name to find the ttl
    ///
    /// Panics
    /// Panics if `domain_name` doesn't exists.
    public fun get_name_record_all_fields(suins: &SuiNS, domain_name: String): (address, address, u64) {
        let name_record = get_name_record(suins, domain_name);
        (name_record_owner(name_record), name_record_linked_addr(name_record), name_record_ttl(name_record))
    }

    public fun get_name_record_data(suins: &SuiNS, domain_name: String, key: String): String {
        let name_record = get_name_record(suins, domain_name);
        let name_record_data = entity::name_record_data(name_record);

        assert!(table::contains(name_record_data, key), EKeyNotExists);
        *table::borrow(name_record_data, key)
    }

    public fun is_authorised(suins: &SuiNS, domain_name: String, ctx: &TxContext) {
        let owner = owner(suins, domain_name);
        assert!(sender(ctx) == owner, EUnauthorized);
    }

    // === Friend and Private Functions ===

    public(friend) fun set_owner_internal(suins: &mut SuiNS, domain_name: String, owner: address) {
        let name_record = get_name_record_mut(suins, domain_name);
        *name_record_owner_mut(name_record) = owner
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
            *name_record_linked_addr_mut(record) = owner;
        } else new_record(suins, domain_name, owner, ttl, ctx);
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
        let record = new_name_record(owner, ttl, owner, ctx);
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
    public fun record_exists(suins: &SuiNS, domain_name: String): bool {
        let registry = entity::registry(suins);
        table::contains(registry, domain_name)
    }

    #[test_only]
    /// Wrapper of module initializer for testing
    public fun test_init(ctx: &mut TxContext) {
        transfer::transfer(AdminCap {
            id: object::new(ctx)
        }, sender(ctx));
    }
}
