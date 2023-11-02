// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

module suins::registry {
    use std::option::{Self, none, some, Option};
    use std::string::String;

    use sui::tx_context::TxContext;
    use sui::object;
    use sui::table::{Self, Table};
    use sui::clock::Clock;
    use sui::vec_map::VecMap;

    use suins::suins_registration::{Self as nft, SuinsRegistration};
    use suins::name_record::{Self, NameRecord};
    use suins::domain::{Self, Domain};
    use suins::suins::AdminCap;

    /// The `SuinsRegistration` has expired.
    const ENftExpired: u64 = 0;
    /// Trying to override a record that is not expired.
    const ERecordNotExpired: u64 = 1;
    /// The `SuinsRegistration` does not match the `NameRecord`.
    const EIdMismatch: u64 = 2;
    /// The `NameRecord` has expired.
    const ERecordExpired: u64 = 3;
    /// The reverse lookup record does not match the `NameRecord`.
    const ERecordMismatch: u64 = 4;
    /// Trying to add a reverse lookup record while the target is empty.
    const ETargetNotSet: u64 = 5;
    /// Trying to remove or operate on a non-leaf record as if it were a leaf record.
    const ENotLeafRecord: u64 = 6;
    /// Trying to add a leaf record for a non-subdomain.
    const ENotASubDomain: u64 = 7;
    /// Trying to lookup a record that doesn't exist.
    const ERecordNotFound: u64 = 8;

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
        reverse_registry: Table<address, Domain>,
    }

    public fun new(_: &AdminCap, ctx: &mut TxContext): Registry {
        Registry {
            registry: table::new(ctx),
            reverse_registry: table::new(ctx),
        }
    }

    /// Attemps to add a new record to the registry without looking at the grace period. 
    /// Currently used for subdomains where there's no grace period to respect.
    /// Returns a `SuinsRegistration` upon success.
    public fun add_record_ignoring_grace_period(
        self: &mut Registry,
        domain: Domain,
        no_years: u8,
        clock: &Clock,
        ctx: &mut TxContext,
    ): SuinsRegistration {
        internal_add_record(self, domain, no_years, clock, false, ctx)
    }

    /// Attempts to add a new record to the registry and returns a
    /// `SuinsRegistration` upon success.
    /// Only use with second-level names. Enforces a `grace_period` by default. 
    /// Not suitable for subdomains (unless a grace period is needed).
    public fun add_record(
        self: &mut Registry,
        domain: Domain,
        no_years: u8,
        clock: &Clock,
        ctx: &mut TxContext,
    ): SuinsRegistration {
        internal_add_record(self, domain, no_years, clock, true, ctx)
    }

    /// Attempts to burn an NFT and get storage rebates.
    /// Only works if the NFT has expired.
    public fun burn_registration_object(
        self: &mut Registry,
        nft: SuinsRegistration,
        clock: &Clock
    ) {
        // First we make sure that the SuinsRegistration object has expired.
        assert!(nft::has_expired(&nft, clock), ERecordNotExpired);
        
        let domain = nft::domain(&nft);
        // Then, if the registry still has a record for this domain and the NFT ID matches, we remove it.
        if(table::contains(&self.registry, domain)) {

            let record = table::borrow(&mut self.registry, domain);

            if(name_record::nft_id(record) == object::id(&nft)) {
                let record = table::remove(&mut self.registry, domain);
                handle_invalidate_reverse_record(self, &domain, name_record::target_address(&record), none());
            }
        };
        // burn the NFT.
        nft::burn(nft);
    }

    /// 
    /// 
    /// Adds a `leaf` record to the registry.
    /// A `leaf` record is a record that is a subdomain and doesn't have
    /// an equivalent `SuinsRegistration` object.
    /// 
    /// Instead, the parent's `SuinsRegistration` object is used to
    /// manage the target_address, as well as altering expiration timestamps etc.
    /// 
    /// 1. Leaf records can't have children. They only work as a resolving mechanism.
    /// 2. Leaf records must always have a `target` address (can't point to `none`).
    /// 3. Leaf records do not expire. Their expiration date is actually what defines their type.
    /// 
    /// Leaf record's expiration is defined by the parent's expiration. Since the parent can only be a `node`,
    /// we need to check that the parent's NFT_ID is valid & the parent hasn't expired.
    /// 
    public fun add_leaf_record(
        self: &mut Registry,
        domain: Domain,
        clock: &Clock,
        target: address,
        _ctx: &mut TxContext
    ) {
        // Validate tha the domain is a subdomain. We can't have `leaf` SLD names in any scenario,
        // as they 
        assert!(domain::is_subdomain(&domain), ENotASubDomain);

        // get the parent of the domain
        let parent = domain::parent_from_child(&domain);
        let option_parent_name_record = lookup(self, parent);

        assert!(option::is_some(&option_parent_name_record), ERecordNotFound);

        // finds existing parent record
        let parent_name_record = option::extract(&mut option_parent_name_record);

        // Removes an existing record if it exists and is expired.
        remove_existing_record_if_exists_and_expired(self, domain, clock, false);
        
        // adds the `leaf` record to the registry.
        table::add(&mut self.registry, domain, name_record::new_leaf(name_record::nft_id(&parent_name_record), some(target)));
    }

    /// 
    /// Can be used to remove a leaf record.
    /// Leaf records do not have any symmetrical `SuinsRegistration` object,
    /// so we do not care about removing them from the registry.
    /// 
    /// Access to this function is controlled by authorized packages/modules.
    /// 
    public fun remove_leaf_record(
        self: &mut Registry,
        domain: Domain,
    ) {
        // We can only call remove on a leaf record.
        assert!(is_leaf_record(self, domain), ENotLeafRecord);

        // if it's a leaf record, there's no SuinsRegistraion object.
        // We can just go ahead and remove the name-record, and invalidate the reverse record (if any).
        let record = table::remove(&mut self.registry, domain);
        let old_target_address = name_record::target_address(&record);

        handle_invalidate_reverse_record(self, &domain, old_target_address, none());
    }

    /// Checks whether a subdomain record is `leaf`.
    /// `leaf` record: a record whose target address can only be set by the parent,
    /// hence the nft_id points to the parent's ID. Leaf records can't create subdomains
    /// and don't have their own `SuinsRegistration` object Cap. The `SuinsRegistration` of the parent
    /// is the one that manages them.
    /// 
    /// They are only used for resolving names for app usage, such as `username.mystenlabs.sui`.
    ///
    public fun is_leaf_record(
        self: &Registry,
        domain: Domain
    ): bool {
        if(!domain::is_subdomain(&domain)) {
            return false;
        };
        
        let option_name_record = lookup(self, domain);

        if(option::is_none(&option_name_record)) {
            return false;
        };

        name_record::is_leaf_record(&option::extract(&mut option_name_record))
    }

    public fun set_target_address(
        self: &mut Registry,
        domain: Domain,
        new_target: Option<address>,
    ) {
        let record = table::borrow_mut(&mut self.registry, domain);
        let old_target = name_record::target_address(record);

        name_record::set_target_address(record, new_target);
        handle_invalidate_reverse_record(self, &domain, old_target, new_target);
    }

    public fun unset_reverse_lookup(self: &mut Registry, address: address) {
        table::remove(&mut self.reverse_registry, address);
    }

    /// Reverse lookup can only be set for the record that has the target address.
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
            *table::borrow_mut(&mut self.reverse_registry, address) = domain;
        } else {
            table::add(&mut self.reverse_registry, address, domain);
        };
    }

    /// Update the `expiration_timestamp_ms` of the given `SuinsRegistration` and
    /// `NameRecord`. Requires the `SuinsRegistration` to make sure that both
    /// timestamps are in sync.
    public fun set_expiration_timestamp_ms(
        self: &mut Registry,
        nft: &mut SuinsRegistration,
        domain: Domain,
        expiration_timestamp_ms: u64,
    ) {
        let record = table::borrow_mut(&mut self.registry, domain);

        assert!(object::id(nft) == name_record::nft_id(record), EIdMismatch);
        name_record::set_expiration_timestamp_ms(record, expiration_timestamp_ms);
        nft::set_expiration_timestamp_ms(nft, expiration_timestamp_ms);
    }

    /// Update the `data` of the given `NameRecord` using a `SuinsRegistration`.
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
    public fun reverse_lookup(self: &Registry, address: address): Option<Domain> {
        if (table::contains(&self.reverse_registry, address)) {
            some(*table::borrow(&self.reverse_registry, address))
        } else {
            none()
        }
    }

    /// Asserts that the provided NFT:
    /// 1. Matches the ID in the corresponding `Record`
    /// 2. Has not expired (does not take into account the grace period)
    public fun assert_nft_is_authorized(self: &Registry, nft: &SuinsRegistration, clock: &Clock) {
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

    /// An internal helper to add a record, based on period.
    fun internal_add_record(
        self: &mut Registry,
        domain: Domain,
        no_years: u8,
        clock: &Clock,
        with_grace_period: bool,
        ctx: &mut TxContext,
    ): SuinsRegistration {
        remove_existing_record_if_exists_and_expired(self, domain, clock, with_grace_period);

        // If we've made it to this point then we know that we are able to
        // register an entry for this domain.
        let nft = nft::new(domain, no_years, clock, ctx);
        let name_record = name_record::new(object::id(&nft), nft::expiration_timestamp_ms(&nft));
        table::add(&mut self.registry, domain, name_record);
        nft
    }

    fun remove_existing_record_if_exists_and_expired(
        self: &mut Registry,
        domain: Domain,
        clock: &Clock,
        with_grace_period: bool,
    ) {
        // First check to see if there is already an entry for this domain
        if (table::contains(&self.registry, domain)) {
            // Remove the record and assert that it has expired past the grace period
            let record = table::remove(&mut self.registry, domain);

            if (with_grace_period) {
                assert!(name_record::has_expired_past_grace_period(&record, clock), ERecordNotExpired);
            } else {
                assert!(name_record::has_expired(&record, clock), ERecordNotExpired);
            };

            let old_target_address = name_record::target_address(&record);
            handle_invalidate_reverse_record(self, &domain, old_target_address, none());
        };
    }

    fun handle_invalidate_reverse_record(
        self: &mut Registry,
        domain: &Domain,
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
            if (default_domain == domain) {
                table::remove(reverse_registry, old_target_address);
            }
        };
    }

    // === Test Functions ===
    #[test_only] use suins::suins::{add_registry, SuiNS};

    #[test_only]
    public fun init_for_testing(cap: &AdminCap, suins: &mut SuiNS, ctx: &mut TxContext) {
        add_registry(cap, suins, new(cap, ctx));
    }

    #[test_only]
    /// Create a new `Registry` for testing Purposes.
    public fun new_for_testing(ctx: &mut TxContext): Registry {
        Registry {
            registry: table::new(ctx),
            reverse_registry: table::new(ctx),
        }
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

        table::drop(registry);
        table::drop(reverse_registry);
    }
}
