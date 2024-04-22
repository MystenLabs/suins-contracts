// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

module suins::registry {
    use std::{option::{none, some}, string::String};

    use sui::{table::{Self, Table}, clock::Clock, vec_map::VecMap};

    use suins::{
        suins_registration::{Self as nft, SuinsRegistration}, 
        name_record::{Self, NameRecord}, 
        domain::Domain, 
        suins::AdminCap, 
        subdomain_registration::{Self, SubDomainRegistration}
    };

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
    /// Trying to add a leaf record for a TLD or SLD.
    const EInvalidDepth: u64 = 7;
    /// Trying to lookup a record that doesn't exist.
    const ERecordNotFound: u64 = 8;

    /// The `Registry` object. Attached as a dynamic field to the `SuiNS` object,
    /// and the `suins` module controls the access to the `Registry`.
    ///
    /// Contains two tables necessary for the lookup.
    public struct Registry has store {
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
        self.internal_add_record(domain, no_years, clock, false, ctx)
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
        self.internal_add_record(domain, no_years, clock, true, ctx)
    }

    /// Attempts to burn an NFT and get storage rebates.
    /// Only works if the NFT has expired.
    public fun burn_registration_object(
        self: &mut Registry,
        nft: SuinsRegistration,
        clock: &Clock
    ) {
        // First we make sure that the SuinsRegistration object has expired.
        assert!(nft.has_expired(clock), ERecordNotExpired);
        
        let domain = nft.domain();

        // Then, if the registry still has a record for this domain and the NFT ID matches, we remove it.
        if (self.registry.contains(domain)) {
            let record = &self.registry[domain];
            
            // We wanna remove the record only if the NFT ID matches.
            if (record.nft_id() == object::id(&nft)) {
                let record = self.registry.remove(domain);
                self.handle_invalidate_reverse_record(&domain, record.target_address(), none());
            }
        };
        // burn the NFT.
        nft.burn();
    }

    /// Allow creation of subdomain wrappers only to authorized modules.
    public fun wrap_subdomain(
        _: &mut Registry,
        nft: SuinsRegistration,
        clock: &Clock,
        ctx: &mut TxContext
    ): SubDomainRegistration {
        subdomain_registration::new(nft, clock, ctx)
    }

    /// Attempts to burn a subdomain registration object, 
    /// and also invalidates any records in the registry / reverse registry.
    public fun burn_subdomain_object(
        self: &mut Registry,
        nft: SubDomainRegistration,
        clock: &Clock
    ) {
        let nft = nft.burn(clock);
        self.burn_registration_object(nft, clock);
    }

    /// Adds a `leaf` record to the registry.
    /// A `leaf` record is a record that is a subdomain and doesn't have
    /// an equivalent `SuinsRegistration` object.
    /// 
    /// Instead, the parent's `SuinsRegistration` object is used to manage target_address & remove it / determine expiration.
    /// 
    /// 1. Leaf records can't have children. They only work as a resolving mechanism.
    /// 2. Leaf records must always have a `target` address (can't point to `none`).
    /// 3. Leaf records do not expire. Their expiration date is actually what defines their type.
    /// 
    /// Leaf record's expiration is defined by the parent's expiration. Since the parent can only be a `node`,
    /// we need to check that the parent's NFT_ID is valid & hasn't expired.
    public fun add_leaf_record(
        self: &mut Registry,
        domain: Domain,
        clock: &Clock,
        target: address,
        _ctx: &mut TxContext
    ) {
        assert!(domain.is_subdomain(), EInvalidDepth);

        // get the parent of the domain
        let parent = domain.parent();
        let option_parent_name_record = self.lookup(parent);

        assert!(option_parent_name_record.is_some(), ERecordNotFound);

        // finds existing parent record
        let parent_name_record = option_parent_name_record.borrow();

        // Make sure that the parent isn't expired (because leaf record is invalid in that case).
        // Ignores grace period is it's only there so you don't accidently forget to renew your name.
        assert!(!parent_name_record.has_expired(clock), ERecordExpired);

        // Removes an existing record if it exists and is expired.
        self.remove_existing_record_if_exists_and_expired(domain, clock, false);
        
        // adds the `leaf` record to the registry.
        self.registry.add(domain, name_record::new_leaf(parent_name_record.nft_id(), some(target)));
    }

    /// Can be used to remove a leaf record.
    /// Leaf records do not have any symmetrical `SuinsRegistration` object.
    /// Authorization of who calls this is delegated to the authorized module that calls this.
    public fun remove_leaf_record(
        self: &mut Registry,
        domain: Domain,
    ) {
        // We can only call remove on a leaf record.
        assert!(self.is_leaf_record(domain), ENotLeafRecord);

        // if it's a leaf record, there's no `SuinsRegistration` object.
        // We can just go ahead and remove the name_record, and invalidate the reverse record (if any).
        let record = self.registry.remove(domain);
        let old_target_address = record.target_address();

        self.handle_invalidate_reverse_record(&domain, old_target_address, none());
    }

    public fun set_target_address(
        self: &mut Registry,
        domain: Domain,
        new_target: Option<address>,
    ) {
        let record = &mut self.registry[domain];
        let old_target = record.target_address();

        record.set_target_address(new_target);
        self.handle_invalidate_reverse_record(&domain, old_target, new_target);
    }

    public fun unset_reverse_lookup(self: &mut Registry, address: address) {
        self.reverse_registry.remove(address);
    }

    /// Reverse lookup can only be set for the record that has the target address.
    public fun set_reverse_lookup(
        self: &mut Registry,
        address: address,
        domain: Domain,
    ) {
        let record = &self.registry[domain];
        let target = record.target_address();

        assert!(target.is_some(), ETargetNotSet);
        assert!(some(address) == target, ERecordMismatch);

        if (self.reverse_registry.contains(address)) {
            *self.reverse_registry.borrow_mut(address) = domain;
        } else {
            self.reverse_registry.add(address, domain);
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
        let record = &mut self.registry[domain];

        assert!(object::id(nft) == record.nft_id(), EIdMismatch);
        record.set_expiration_timestamp_ms(expiration_timestamp_ms);
        nft.set_expiration_timestamp_ms(expiration_timestamp_ms);
    }

    /// Update the `data` of the given `NameRecord` using a `SuinsRegistration`.
    /// Use with caution and validate(!!) that any system fields are not removed (accidently),
    /// when building authorized packages that can write the metadata field.
    public fun set_data(
        self: &mut Registry,
        domain: Domain,
        data: VecMap<String, String>
    ) {
        let record = &mut self.registry[domain];
        record.set_data(data);
    }

    // === Reads ===

    /// Check whether the given `domain` is registered in the `Registry`.
    public fun has_record(self: &Registry, domain: Domain): bool {
        self.registry.contains(domain)
    }

    /// Returns the `NameRecord` associated with the given domain or None.
    public fun lookup(self: &Registry, domain: Domain): Option<NameRecord> {
        if (self.registry.contains(domain)) {
            let record = &self.registry[domain];
            some(*record)
        } else {
            none()
        }
    }

    /// Returns the `domain_name` associated with the given address or None.
    public fun reverse_lookup(self: &Registry, address: address): Option<Domain> {
        if (self.reverse_registry.contains(address)) {
            some(self.reverse_registry[address])
        } else {
            none()
        }
    }

    /// Asserts that the provided NFT:
    /// 1. Matches the ID in the corresponding `Record`
    /// 2. Has not expired (does not take into account the grace period)
    public fun assert_nft_is_authorized(self: &Registry, nft: &SuinsRegistration, clock: &Clock) {
        let domain = nft.domain();
        let record = &self.registry[domain];

        // The NFT does not
        assert!(object::id(nft) == record.nft_id(), EIdMismatch);
        assert!(!record.has_expired(clock), ERecordExpired);
        assert!(!nft.has_expired(clock), ENftExpired);
    }

    /// Returns the `data` associated with the given `Domain`.
    public fun get_data(self: &Registry, domain: Domain): &VecMap<String, String> {
        let record = &self.registry[domain];
        record.data()
    }

    // === Private Functions ===

    /// Checks whether a subdomain record is `leaf`.
    /// `leaf` record: a record whose target address can only be set by the parent,
    /// hence the nft_id points to the parent's ID. Leaf records can't create subdomains
    /// and don't have their own `SuinsRegistration` object Cap. The `SuinsRegistration` of the parent
    /// is the one that manages them.
    /// 
    fun is_leaf_record(
        self: &Registry,
        domain: Domain
    ): bool {
        if (!domain.is_subdomain()) {
            return false
        };
        
        let option_name_record = self.lookup(domain);

        if (option_name_record.is_none()) {
            return false
        };

        option_name_record.borrow().is_leaf_record()
    }

    /// An internal helper to add a record
    fun internal_add_record(
        self: &mut Registry,
        domain: Domain,
        no_years: u8,
        clock: &Clock,
        with_grace_period: bool,
        ctx: &mut TxContext,
    ): SuinsRegistration {
        self.remove_existing_record_if_exists_and_expired(domain, clock, with_grace_period);

        // If we've made it to this point then we know that we are able to
        // register an entry for this domain.
        let nft = nft::new(domain, no_years, clock, ctx);
        let name_record = name_record::new(object::id(&nft), nft.expiration_timestamp_ms());
        self.registry.add(domain, name_record);
        nft
    }

    fun remove_existing_record_if_exists_and_expired(
        self: &mut Registry,
        domain: Domain,
        clock: &Clock,
        with_grace_period: bool,
    ) {
        // if the domain is not part of the registry, we can override.
        if (!self.registry.contains(domain)) return;

        // Remove the record and assert that it has expired (past the grace period if applicable)
        let record = self.registry.remove(domain);

        // Special case for leaf records, we can override them iff their parent has changed or has expired.
        if (record.is_leaf_record()) {
            // find the parent of the leaf record.
            let option_parent_name_record = self.lookup(domain.parent());

            // if there's a parent (if not, we can just remove it), we need to check if the parent is valid.
            // -> If the parent is valid, we need to check if the parent is expired.
            // -> If the parent is not valid (nft_id has changed), or if the parent doesn't exist anymore (owner burned it), we can override the leaf record.
            if (option_parent_name_record.is_some()) {
                let parent_name_record = option_parent_name_record.borrow();

                // If the parent is the same and hasn't expired, we can't override the leaf record like this.
                // We need to first remove + then call create (to protect accidental overrides).
                if (parent_name_record.nft_id() == record.nft_id()) {
                    assert!(parent_name_record.has_expired(clock), ERecordNotExpired);
                };
            }
        }else if (with_grace_period) {
            assert!(record.has_expired_past_grace_period(clock), ERecordNotExpired);
        } else {
            assert!(record.has_expired(clock), ERecordNotExpired);
        };

        let old_target_address = record.target_address();
        self.handle_invalidate_reverse_record(&domain, old_target_address, none());
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

        if (old_target_address.is_none()) {
            return
        };

        let old_target_address = old_target_address.destroy_some();
        let reverse_registry = &mut self.reverse_registry;

        if (reverse_registry.contains(old_target_address)) {
            let default_domain = &reverse_registry[old_target_address];
            if (default_domain == domain) {
                reverse_registry.remove(old_target_address);
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
        self.registry.remove(domain)
    }

    #[test_only]
    public fun destroy_empty_for_testing(self: Registry) {
        let Registry {
            registry,
            reverse_registry,
        } = self;

        registry.destroy_empty();
        reverse_registry.destroy_empty();
    }

    #[test_only]
    public fun destroy_for_testing(self: Registry) {
        let Registry {
            registry,
            reverse_registry,
        } = self;

        registry.drop();
        reverse_registry.drop();
    }
}
