/// The `NameRecord` is a struct that represents a single record in the registry.
/// Can be replaced by any other data structure due to the way `NameRecord`s are
/// stored and managed. SuiNS has no direct and permanent dependency on this
/// module.
module suins::name_record {
    use std::option::{Self, Option};
    use std::string::String;

    use sui::clock::{timestamp_ms, Clock};
    use sui::vec_map::{Self, VecMap};
    use sui::object::ID;

    use suins::constants;

    /// A single record in the registry.
    struct NameRecord has copy, store, drop {
        /// The ID of the `RegistrationNFT` assigned to this record.
        ///
        /// The owner of the corrisponding `RegistrationNFT` has the rights to
        /// be able to change and adjust the `target_address` of this domain.
        ///
        /// It is possible that the ID changes if the record expires and is
        /// purchased by someone else.
        nft_id: ID,
        /// Timestamp in milliseconds when the record expires.
        expiration_timestamp_ms: u64,
        /// The target address that this domain points to
        target_address: Option<address>,
        /// Additional data which may be stored in a record
        data: VecMap<String, String>,
    }

    /// Create a new NameRecord.
    public fun new(
        nft_id: ID,
        expiration_timestamp_ms: u64,
    ): NameRecord {
        NameRecord {
            nft_id,
            expiration_timestamp_ms,
            target_address: option::none(),
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

    // === Getters ===

    /// Check if the record has expired (including the grace period).
    public fun has_expired(self: &NameRecord, clock: &Clock): bool {
        (self.expiration_timestamp_ms + constants::grace_period_ms()) < timestamp_ms(clock)
    }

    /// Read the `data` field from the `NameRecord`.
    public fun data(self: &NameRecord): &VecMap<String, String> { &self.data }

    /// Read the `target_address` field from the `NameRecord`.
    public fun target_address(self: &NameRecord): Option<address> { self.target_address }

    /// Read the `nft_id` field from the `NameRecord`.
    public fun nft_id(self: &NameRecord): ID { self.nft_id }

    /// Read the `expiration_timestamp_ms` field from the `NameRecord`.
    public fun expiration_timestamp_ms(self: &NameRecord): u64 { self.expiration_timestamp_ms }
}
