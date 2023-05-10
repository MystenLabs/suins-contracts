module suins::registry {
    use std::option::{Self, none, some, Option};
    use std::string::{Self, String};

    use sui::tx_context::TxContext;
    use sui::object;
    use sui::table::{Self, Table};
    use sui::clock::Clock;
    use sui::vec_map::VecMap;

    use suins::registration_nft::{Self as nft, RegistrationNFT};
    use suins::name_record::{Self, NameRecord};
    use suins::domain::{Self, Domain};
    use suins::constants;

    friend suins::suins;

    /// The `RegistrationNFT` has expired.
    const ENftExpired: u64 = 0;
    /// Trying to override a record that is not expired.
    const ERecordNotExpired: u64 = 1;
    /// The `RegistrationNFT` does not match the `NameRecord`.
    const EIdMismatch: u64 = 2;
    /// The `NameRecord` has expired.
    const ERecordExpired: u64 = 3;
    /// The reverse lookup record does not match the `NameRecord`.
    const ERecordMismatch: u64 = 4;
    /// Trying to add a reverse lookup record while the target is empty.
    const ETargetNotSet: u64 = 5;
    /// Trying to register a subdomain (only *.sui is currently allowed).
    const EInvalidDomain: u64 = 6;
    /// Trying to register a domain name in a different TLD (not .sui).
    const EInvalidTld: u64 = 7;
    /// Trying to register domain name that is shorter than 3 symbols.
    const EInvalidDomainLength: u64 = 8;

    /// The `Registry` object. Attached as a dynamic field to the `SuiNS` object,
    /// and the `suins` module controls the access to the `Registry`.
    ///
    /// Contains two tables necessary for the lookup.
    struct Registry has store {
        /// The `registry` table maps `Domain` to `NameRecord`.
        /// Added / replaced in the `add_record` function.
        registry: Table<Domain, NameRecord>,
        /// The `reverse_registry` table maps `address` to `domain_name`.
        /// Updated in the `set_reverse_lookup` function.
        reverse_registry: Table<address, String>,
    }

    // === Friend Functions ===

    public(friend) fun new(ctx: &mut TxContext): Registry {
        Registry {
            registry: table::new(ctx),
            reverse_registry: table::new(ctx),
        }
    }

    /// Attempts to add a new record to the registry and returns a
    /// `RegistrationNFT` upon success.
    public fun add_record(
        self: &mut Registry,
        domain: Domain,
        no_years: u8,
        clock: &Clock,
        ctx: &mut TxContext,
    ): RegistrationNFT {
        // First check to see if there is already an entry for this domain
        if (table::contains(&self.registry, domain)) {
            // Remove the record and assert that it has expired past the grace period
            let record = table::remove(&mut self.registry, domain);
            assert!(name_record::has_expired_past_grace_period(&record, clock), ERecordNotExpired);

            let old_target_address = name_record::target_address(&record);
            handle_invalidate_reverse_record(self, domain, old_target_address, none());
        };

        // If we've made it to this point then we know that we are able to
        // register an entry for this domain.
        let nft = nft::new(domain, no_years, clock, ctx);
        let name_record = name_record::new(object::id(&nft), nft::expiration_timestamp_ms(&nft));
        table::add(&mut self.registry, domain, name_record);
        nft
    }

    public fun set_target_address(
        self: &mut Registry,
        domain: Domain,
        new_target: Option<address>,
    ) {
        let record = table::borrow_mut(&mut self.registry, domain);
        let old_target = name_record::target_address(record);

        name_record::set_target_address(record, new_target);
        handle_invalidate_reverse_record(self, domain, old_target, new_target);
    }

    public fun unset_reverse_lookup(self: &mut Registry, address: address) {
        table::remove(&mut self.reverse_registry, address);
    }

    /// Reverse lookup can only be set for the record that has the target address.
    /// TODO: Should it be this way?
    public fun set_reverse_lookup(
        self: &mut Registry,
        address: address,
        domain: Domain,
    ) {
        let record = table::borrow(&self.registry, domain);
        let target = name_record::target_address(record);

        assert!(option::is_some(&target), ETargetNotSet);
        assert!(some(address) == target, ERecordMismatch);

        if (table::contains(&self.reverse_registry, address)) {
            *table::borrow_mut(&mut self.reverse_registry, address) = domain::to_string(&domain);
        } else {
            table::add(&mut self.reverse_registry, address, domain::to_string(&domain));
        };
    }

    /// Update the `expiration_timestamp_ms` of the given `RegistrationNFT` and
    /// `NameRecord`. Requires the `RegistrationNFT` to make sure that both
    /// timestamps are in sync.
    public fun set_expiration_timestamp_ms(
        self: &mut Registry,
        nft: &mut RegistrationNFT,
        domain: Domain,
        expiration_timestamp_ms: u64,
    ) {
        let record = table::borrow_mut(&mut self.registry, domain);

        assert!(object::id(nft) == name_record::nft_id(record), EIdMismatch);
        name_record::set_expiration_timestamp_ms(record, expiration_timestamp_ms);
        nft::set_expiration_timestamp_ms(nft, expiration_timestamp_ms);
    }

    /// Update the `data` of the given `NameRecord` using a `RegistrationNFT`.
    public fun set_data(
        self: &mut Registry,
        domain: Domain,
        data: VecMap<String, String>
    ) {
        let record = table::borrow_mut(&mut self.registry, domain);
        name_record::set_data(record, data);
    }

    // === Reads ===

    /// Check whether the given `domain` is registered in the `Registry`.
    public fun has_record(self: &Registry, domain: Domain): bool {
        table::contains(&self.registry, domain)
    }

    /// Returns the `NameRecord` associated with the given domain or None.
    public fun lookup(self: &Registry, domain: Domain): Option<NameRecord> {
        if (table::contains(&self.registry, domain)) {
            let record = table::borrow(&self.registry, domain);
            some(*record)
        } else {
            none()
        }
    }

    /// Returns the `domain_name` associated with the given address or None.
    public fun reverse_lookup(self: &Registry, address: address): Option<String> {
        if (table::contains(&self.reverse_registry, address)) {
            some(*table::borrow(&self.reverse_registry, address))
        } else {
            none()
        }
    }

    /// Asserts that the provided NFT:
    /// 1. Matches the ID in the corresponding `Record`
    /// 2. Has not expired (does not take into account the grace period)
    public fun assert_nft_is_authorized(self: &Registry, nft: &RegistrationNFT, clock: &Clock) {
        let domain = nft::domain(nft);
        let record = table::borrow(&self.registry, domain);

        // The NFT does not
        assert!(object::id(nft) == name_record::nft_id(record), EIdMismatch);
        assert!(!name_record::has_expired(record, clock), ERecordExpired);
        assert!(!nft::has_expired(nft, clock), ENftExpired);
    }

    /// Returns the `data` associated with the given `Domain`.
    public fun get_data(self: &Registry, domain: Domain): &VecMap<String, String> {
        let record = table::borrow(&self.registry, domain);
        name_record::data(record)
    }

    // === Private Functions ===

    fun handle_invalidate_reverse_record(
        self: &mut Registry,
        domain: Domain,
        old_target_address: Option<address>,
        new_target_address: Option<address>,
    ) {
        if (old_target_address == new_target_address) {
            return
        };

        if (option::is_none(&old_target_address)) {
            return
        };

        let old_target_address = option::destroy_some(old_target_address);
        let reverse_registry = &mut self.reverse_registry;

        if (table::contains(reverse_registry, old_target_address)) {
            let default_domain = table::borrow(reverse_registry, old_target_address);
            if (*default_domain == domain::to_string(&domain)) {
                table::remove(reverse_registry, old_target_address);
            }
        };
    }

    // === Helpers ===

    /// Asserts that a domain is registerable by a user:
    /// - TLD is "sui"
    /// - only has 1 label, "name", other than the TLD
    /// - "name" is >= 3 characters long
    public fun assert_valid_user_registerable_domain(domain: &Domain) {
        assert!(domain::number_of_levels(domain) == 2, EInvalidDomain);
        assert!(domain::tld(domain) == &constants::sui_tld(), EInvalidTld);
        assert!(string::length(domain::sld(domain)) >= 3, EInvalidDomainLength);
    }

    // === Test Functions ===

    #[test_only]
    /// Create a new `Registry` for testing Purposes.
    public fun new_for_testing(ctx: &mut TxContext): Registry {
        new(ctx)
    }

    #[test_only]
    public fun remove_record_for_testing(
        self: &mut Registry,
        domain: Domain,
    ): NameRecord {
        table::remove(&mut self.registry, domain)
    }

    #[test_only]
    public fun destroy_empty_for_testing(self: Registry) {
        let Registry {
            registry,
            reverse_registry,
        } = self;

        table::destroy_empty(registry);
        table::destroy_empty(reverse_registry);
    }
}
