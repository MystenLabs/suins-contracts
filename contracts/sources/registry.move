module suins::registry {
    use std::option::{Self, none, some, Option};
    use std::string::String;

    use sui::tx_context::TxContext;
    use sui::object;
    use sui::table::{Self, Table};
    use sui::clock::Clock;

    use suins::registration_nft::{Self as nft, RegistrationNFT};
    use suins::name_record::{Self, NameRecord};
    use suins::domain::{Self, Domain};

    friend suins::suins;

    /// The `RegistrationNFT` has expired.
    const ENftExpired: u64 = 4;
    /// The `NameRecord` has expired.
    const ERecordExpired: u64 = 3;
    const EIdMismatch: u64 = 2;

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
            assert!(name_record::has_expired_past_grace_period(&record, clock), 0);

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

    public fun set_reverse_lookup(
        self: &mut Registry,
        address: address,
        domain: Option<Domain>,
    ) {
        if (option::is_none(&domain)) {
            table::remove(&mut self.reverse_registry, address);
            return
        };

        let domain = option::destroy_some(domain);
        let record = table::borrow(&self.registry, domain);

        assert!(some(address) == name_record::target_address(record), 0);

        if (table::contains(&self.reverse_registry, address)) {
            *table::borrow_mut(&mut self.reverse_registry, address) = domain::to_string(&domain);
        } else {
            table::add(&mut self.reverse_registry, address, domain::to_string(&domain));
        };
    }

    public fun set_expiration_timestamp_ms(
        self: &mut Registry,
        domain: Domain,
        expiration_timestamp_ms: u64,
    ) {
        let record = table::borrow_mut(&mut self.registry, domain);
        name_record::set_expiration_timestamp_ms(record, expiration_timestamp_ms);
    }

    // === Reads ===

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

        assert!(object::id(nft) == name_record::nft_id(record), EIdMismatch);
        assert!(!name_record::has_expired(record, clock), ERecordExpired);
        assert!(!nft::has_expired(nft, clock), ENftExpired);
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

    // === Test Functions ===

    #[test_only]
    public fun destroy_empty(self: Registry) {
        let Registry {
            registry,
            reverse_registry,
        } = self;

        table::destroy_empty(registry);
        table::destroy_empty(reverse_registry);
    }
}
