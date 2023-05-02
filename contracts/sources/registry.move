/// This module is intended to maintain records of domain names including the owner, linked address and default domain name.
/// The owners of this only own the name, not own the registration.
/// It primarily facilitates the lending and borrowing of domain names.
module suins::registry {
    use std::option::{Self, none, some, Option};
    use std::string::String;

    use sui::table;
    use sui::vec_map;
    use sui::event;
    use sui::tx_context::{TxContext, sender};

    use suins::suins::{Self, SuiNS};
    use suins::name_record::{Self, NameRecord};

    // errors in the range of 101..200 indicate SuiNS errors
    const EUnauthorized: u64 = 101;
    const EDomainNameNotExists: u64 = 102;
    const EKeyNotExists: u64 = 103;
    const EDefaultDomainNameNotMatch: u64 = 104;

    /// #### Notice
    /// This funtions allows owner of `domain name` to set custom data.
    ///
    /// #### Params
    /// `domain_name`: domain name to be updated
    /// `hash`: content hash url
    ///
    /// Panics
    /// Panics if caller isn't the owner of `domain name`
    public fun set_data(
        suins: &mut SuiNS,
        domain_name: String,
        key: String,
        new_value: String,
        ctx: &mut TxContext
    ) {
        let record = suins::name_record_mut(suins, domain_name, ctx);
        let record_data = name_record::data_mut(record);

        if (vec_map::contains(record_data, &key)) {
            *vec_map::get_mut(record_data, &key) = new_value
        } else {
            vec_map::insert(record_data, key, new_value);
        };

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
    public fun unset_data(
        suins: &mut SuiNS,
        domain_name: String,
        key: String,
        ctx: &mut TxContext
    ) {
        let record = suins::name_record_mut(suins, domain_name, ctx);
        let record_data = name_record::data_mut(record);

        vec_map::remove(record_data, &key);
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
    public fun set_target_address(
        suins: &mut SuiNS,
        domain_name: String,
        new_addr: address,
        ctx: &mut TxContext,
    ) {
        let record = suins::name_record_mut(suins, domain_name, ctx);
        let old_target_address = name_record::target_address(record);

        name_record::set_target_address(record, some(new_addr));
        event::emit(TargetAddressChangedEvent { domain_name, new_addr });

        if (option::is_some(&old_target_address)) {
            let old_target_address = option::destroy_some(old_target_address);
            if (old_target_address != new_addr) {
                let reverse_registry = suins::reverse_registry_mut(suins);
                if (table::contains(reverse_registry, old_target_address)) {
                    table::remove(reverse_registry, old_target_address);
                };
            };
        }
    }

    public fun unset_target_address(
        suins: &mut SuiNS,
        domain_name: String,
        ctx: &mut TxContext,
    ) {
        let record = suins::name_record_mut(suins, domain_name, ctx);
        let old_target_address = name_record::target_address(record);

        name_record::set_target_address(record, none());
        event::emit(TargetAddressRemovedEvent { domain_name });

        if (option::is_some(&old_target_address)) {
            let reverse_registry = suins::reverse_registry_mut(suins);
            let old_target_address = option::destroy_some(old_target_address);
            if (table::contains(reverse_registry, old_target_address)) {
                table::remove(reverse_registry, old_target_address);
            };
        }
    }

    public fun set_default_domain_name(
        suins: &mut SuiNS,
        new_default_domain_name: String,
        ctx: &mut TxContext,
    ) {
        let sender_address = sender(ctx);
        let record = suins::name_record<NameRecord>(suins, new_default_domain_name);

        // When setting a defalt domain name for an address, the domain name
        // must already be pointing at the address
        assert!(
            some(sender_address) == name_record::target_address(record),
            EDefaultDomainNameNotMatch
        );

        let reverse_registry = suins::reverse_registry_mut(suins);

        if (table::contains(reverse_registry, sender_address)) {
            let default_domain_name = table::borrow_mut(reverse_registry, sender_address);
            *default_domain_name = new_default_domain_name;
        } else {
            table::add(reverse_registry, sender_address, new_default_domain_name);
        };

        event::emit(DefaultDomainNameChangedEvent { address: sender_address, new_default_domain_name });
    }

    public fun unset_default_domain_name(
        suins: &mut SuiNS,
        ctx: &mut TxContext,
    ) {
        let sender_address = sender(ctx);
        let reverse_registry = suins::reverse_registry_mut(suins);
        table::remove(reverse_registry, sender_address);

        event::emit(DefaultDomainNameRemovedEvent { address: sender_address });
    }

    // === Public Functions ===

    public fun target_address(suins: &SuiNS, domain_name: String): Option<address> {
        let record = suins::name_record<NameRecord>(suins, domain_name);
        name_record::target_address(record)
    }

    public fun default_domain_name(suins: &SuiNS, addr: address): String {
        let reverse_registry = suins::reverse_registry(suins);
        *table::borrow(reverse_registry, addr)
    }

    /// #### Notice
    /// Get `(owner, target_address)` of a `domain_name`.
    /// The `domain_name` can have multiple levels.
    ///
    /// #### Params
    /// `domain_name`: domain_name to find the record
    ///
    /// Panics
    /// Panics if `domain_name` doesn't exists.
    public fun get_name_record_all_fields(suins: &SuiNS, domain_name: String): (address, Option<address>) {
        let record = suins::name_record<NameRecord>(suins, domain_name);
        let owner = suins::record_owner(suins, domain_name);
        ( owner, name_record::target_address(record) )
    }

    public fun get_name_record_data(suins: &SuiNS, domain_name: String, key: String): String {
        let record = suins::name_record<NameRecord>(suins, domain_name);
        let record_data = name_record::data(record);

        assert!(vec_map::contains(record_data, &key), EKeyNotExists);
        *vec_map::get(record_data, &key)
    }

    // === Events: TODO ===

    struct OwnerChangedEvent has copy, drop {
        domain_name: String,
        new_owner: address,
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

    struct TargetAddressChangedEvent has copy, drop {
        domain_name: String,
        new_addr: address,
    }

    struct TargetAddressRemovedEvent has copy, drop {
        domain_name: String,
    }

    struct DefaultDomainNameChangedEvent has copy, drop {
        address: address,
        new_default_domain_name: String,
    }

    struct DefaultDomainNameRemovedEvent has copy, drop {
        address: address,
    }
}
