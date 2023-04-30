/// Temporarily moving `NameRecord` logic here until we figure out the
/// best way to handle it.
///
/// This module is free from any non-framework dependencies.
///
/// Thoughts:
/// - we may change the table inside the SuiNS to a direct dynamic field
/// this way we don't overpopulate the SuiNS with too many type restrictions
/// and can change the format of the NameRecord later on (eg discard the use
/// of this module completely)
/// - having NameRecord flexible can save us a lot of headaches in the future
module suins::name_record {
    use std::option::Option;
    use std::string::String;
    use sui::vec_map::{Self, VecMap};

    /// A single record in the registry.
    struct NameRecord has copy, store, drop {
        /// The target address that this domain points to
        target_address: Option<address>,
        /// Additional data which may be stored in a record
        data: VecMap<String, String>,
    }

    /// Create a new NameRecord.
    public fun new(target_address: Option<address>): NameRecord {
        NameRecord {
            target_address: target_address,
            data: vec_map::empty(),
        }
    }

    // === Setters ===

    /// Set data as a vec_map directly overriding the data set in the
    /// registration self. This simplifies the editing flow and gives
    /// the user and clients a fine-grained control over custom data.
    ///
    /// Here's a meta example of how a PTB would look like:
    /// ```
    /// let record = moveCall('data', [domain_name]);
    /// moveCall('vec_map::insert', [record.data, key, value]);
    /// moveCall('vec_map::remove', [record.data, other_key]);
    /// moveCall('set_data', [domain_name, record.data]);
    /// ```
    public fun set_data(self: &mut NameRecord, data: VecMap<String, String>) {
        self.data = data;
    }

    /// Set the `target_address` field of the `NameRecord`.
    public fun set_target_address(self: &mut NameRecord, new_address: Option<address>) {
        self.target_address = new_address;
    }

    // === Mutable ===

    /// Read the `data` field from the `NameRecord`.
    public fun data_mut(self: &mut NameRecord): &mut VecMap<String, String> {
        &mut self.data
    }

    // === Getters ===

    /// Read the `data` field from the `NameRecord`.
    public fun data(self: &NameRecord): &VecMap<String, String> {
        &self.data
    }

    /// Read the `target_address` field from the `NameRecord`.
    public fun target_address(self: &NameRecord): Option<address> {
        self.target_address
    }

    // TODO: do this when changing the 'target address' for the reverse registry.
    // if (old_target_address != new_addr) {
    //     let reverse_registry = suins::reverse_registry_mut(suins);
    //     if (table::contains(reverse_registry, old_target_address)) {
    //         table::remove(reverse_registry, old_target_address);
    //     };
    // };

    // TODO: do this when unsetting the 'target address' for the reverse registry.
    // let reverse_registry = suins::reverse_registry_mut(suins);
    // if (table::contains(reverse_registry, old_target_address)) {
    //     table::remove(reverse_registry, old_target_address);
    // };
}
