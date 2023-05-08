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

    /// The `RegistrationNFT` has expired.
    const ENftExpired: u64 = 4;

    struct Registry has store {
        registry: Table<Domain, NameRecord>,
        reverse_registry: Table<address, String>,
    }

    // === Public Functions ===

    public fun lookup(self: &Registry, domain: Domain): Option<NameRecord> {
        if (table::contains(&self.registry, domain)) {
            let record = table::borrow(&self.registry, domain);
            some(*record)
        } else {
            none()
        }
    }

    public fun reverse_lookup(self: &Registry, address: address): Option<String> {
        if (table::contains(&self.reverse_registry, address)) {
            some(*table::borrow(&self.reverse_registry, address))
        } else {
            none()
        }
    }

    // === Friend Functions ===

    public fun new(ctx: &mut TxContext): Registry {
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
            // Remove the record and assert that it has expired
            let record = table::remove(&mut self.registry, domain);
            assert!(name_record::has_expired(&record, clock), 0);

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

    //TODO: think about doing the nft checks outside in the Controller
    public fun set_target_address(
        self: &mut Registry,
        nft: &RegistrationNFT,
        new_target: Option<address>,
        clock: &Clock,
    ) {
        assert!(!nft::has_expired(nft, clock), ENftExpired);

        let domain = nft::domain(nft);

        let record = table::borrow_mut(&mut self.registry, domain);
        assert!(!name_record::has_expired(record, clock), 0);
        assert!(object::id(nft) == name_record::nft_id(record), 0);

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
