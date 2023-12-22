// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// A namespace is a registry tied to a SLD Domain. (e.g. test.sui)
/// 
/// TODOS:
/// 1. Add events to help indexing subdomains in our API.
/// 2. Double-check business validation rules (e.g. shall we allow only 3 digit labels?).
/// 3. Create an external module (probably in `utils` package) to allow creation of namespaces.
/// 4. Add offensive words list to prevent creation of offensive subdomains. We'll probably use a static list (immutable).
/// 5. Add a `set_reverse_lookup` option on registry to allow setting a subdomain as the default for an address.
module suins::namespace {
    use std::option::{Self, some, none, Option};
    use std::string::{Self, String};

    use sui::address;
    use sui::object::{Self, UID, ID};
    use sui::tx_context::{TxContext};

    use sui::table::{Self, Table};
    use sui::clock::{Self, Clock};
    use sui::dynamic_field::{Self as df};
    use sui::transfer;
    use sui::vec_map;

    use suins::domain::{Self, Domain};
    use suins::name_record;
    use suins::sub_name_record::{Self, SubNameRecord};
    use suins::suins_registration::{Self as nft, SuinsRegistration};
    use suins::registry::{Self, Registry};
    use suins::constants;
    use suins::subdomain_registration::{Self, SubDomainRegistration};

    /// Initial version.
    const VERSION: u8 = 0;
    
    /// Tries to create a namespace or domain for a domain that has expired. 
    const ENFTExpired: u64 = 1;
    /// Tries to create a namespace for a domain that already has a namespace.
    const ENameSpaceAlreadyCreated: u64 = 2;
    /// Tries to create a namespace for a domain that is not a SLD.
    const ENotASLDName: u64 = 3;
    /// Tries to create a subdomain in a non-matching namespace.
    const ENamespaceMissmatch: u64 = 4;
    /// Tries to override a record that hasn't expired yet.
    const ERecordNotExpired: u64 = 5;
    /// Tries to remove a record that is not a leaf record.
    const ENotLeafRecord: u64 = 6;
    /// Tries to create a subdomain with the wrong parent.
    const EInvalidParent: u64 = 7;
    /// Tries to create a subdomain with an invalid expiration date (after parents' expiration or not enough time)
    const EInvalidExpirationDate: u64 = 8;
    /// Tries to create a subdomain with an invalid depth (over the limit)
    const EInvalidSubdomainDepth: u64 = 9;
    /// Tries to create a subdomain without being allowed to do so.
    const ENameCreationDisabled: u64 = 10;
    /// Tries to create a namespace with a not-supported TLD.
    const ENotSupportedTLD: u64 = 11;
    /// Tries to use the namespace on an older version of the package.
    const EInvalidVersion: u64 = 12;
    /// Tries to borrow the namespace's UID mutably without being the owner of the parent NFT.
    const EUnauthorizedNFT: u64 = 13;
    /// Tries to extend the expiration of a subdomain without being allowed to do so.
    const ETimeExtensionDisabled: u64 = 14;
    
    /// A shared object that holds the registry of a subdomain's records.
    struct Namespace has key {
        id: UID,
        parent_nft_id: ID,
        parent: Domain,
        registry: Table<Domain, SubNameRecord>,
        // We keep the expiration timestamp of the parent to make sure we don't create subdomains that outlive their parent.
        // We can (permissionless-ly) bump it.
        expiration_timestamp_ms: u64,
        version: u8,
    }

    /// Attached to the names to:
    /// 1. Prevent multiple namespaces being created for the same domain.
    /// 2. Validate that the namespace is correct for a given NFT.
    struct NameSpaceData has copy, store, drop {}

    /// A parent DF key to identify the parent of an NFT.
    struct Parent has copy, store, drop {}

    /// Creates a namespace for the given domain.
    /// We need to use an external package to call this, which is authorized on the main `SuiNS` object.
    /// We can enforce any kind of business logic there (e.g. charge creation of namespaces, etc.)
    /// 
    /// We cannot control what goes on in the namespace after we go live, but we can force a namespace
    /// to use the latest version utilizing the `version` field.
    public fun create_namespace(registry: &mut Registry, nft: &mut SuinsRegistration, clock: &Clock, ctx: &mut TxContext) {
        // share the registry.
        transfer::share_object(internal_create_namespace(registry, nft, clock, ctx));
    }

    /// Adds a record to the namespace.
    public fun add_record(
        self: &mut Namespace,
        parent: &SuinsRegistration,
        expiration_timestamp_ms: u64,
        allow_creation: bool,
        allow_extension: bool,
        domain_name: String,
        clock: &Clock,
        ctx: &mut TxContext
    ): SubDomainRegistration {
        assert_is_valid_version(self);
        let domain = domain::new(domain_name);

        // Checks that parent is not expired, parent is valid for this namespace,
        // and that the parent is indeed the parent for the given domain_name.
        assert_parent_valid_for_domain(self, domain, parent, clock);

        // check depth of labels.
        assert_is_valid_subdomain_depth(&domain);

        // make sure the expiration stamp is less or equal to the parent's expiration.
        assert!(expiration_timestamp_ms <= nft::expiration_timestamp_ms(parent), EInvalidExpirationDate);
        // make sure expiration has the minimum duration.
        assert!(expiration_timestamp_ms >= clock::timestamp_ms(clock) + constants::minimum_subdomain_duration(), EInvalidExpirationDate);

        internal_remove_existing_record_if_exists_and_expired(self, domain, clock);

        // Create NFT and fix timestamp.
        let nft = nft::new(domain, 1, clock, ctx);
        nft::set_expiration_timestamp_ms(&mut nft, expiration_timestamp_ms);

        // Tag the NFT with the namespace's ID, to quick-check that the namespace is correct for the NFT in future actions.
        internal_tag_namespace(&mut nft, object::id(self));

        // Tag the NFT with the parent, to prevent allowing extension if the parent changes.
        internal_tag_parent(&mut nft, object::id(parent));


        let sub_name_record = sub_name_record::new(
            name_record::new_extended(
                object::id(&nft),
                expiration_timestamp_ms,
                none()
            ), 
            false,
            allow_extension, 
            allow_creation
        );

        // add the sub_name record to the registry
        table::add(&mut self.registry, domain, sub_name_record);

        subdomain_registration::new(nft, clock, ctx)
    }

    /// Adds a `leaf` record to the namespace.
    /// A `leaf` record is a record that is a subdomain and doesn't have an equivalent `SuinsRegistration` object.
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
        self: &mut Namespace,
        parent: &SuinsRegistration,
        domain_name: String,
        clock: &Clock,
        target: address,
        _ctx: &mut TxContext
    ) {
        assert_is_valid_version(self);
        let domain = domain::new(domain_name);
        // Checks that parent is not expired, parent is valid for this namespace,
        // and that the parent is indeed the parent for the given domain_name.
        assert_parent_valid_for_domain(self, domain, parent, clock);
        assert_is_valid_subdomain_depth(&domain);

        internal_remove_existing_record_if_exists_and_expired(self, domain, clock);

        let name_record = name_record::new_leaf(object::id(parent), some(target));
        
        // adds the `leaf` record to the registry.
        table::add(&mut self.registry, domain, sub_name_record::new(name_record, true, false, false));
    }

    /// Can be used to remove a leaf record.
    /// Leaf records do not have any symmetrical `SuinsRegistration` object,
    /// so we do not care about removing them from the registry.
    public fun remove_leaf_record(
        self: &mut Namespace,
        parent: &SuinsRegistration,
        domain_name: String,
        clock: &Clock,
    ) {
        assert_is_valid_version(self);
        let domain = domain::new(domain_name);

        // Checks that parent is not expired, parent is valid for this namespace, 
        // and that the parent is actually the parent for the given domain_name.
        assert_parent_valid_for_domain(self, domain, parent, clock);

        // if it's a leaf record, there's no `SuinsRegistration` object.
        // We can just go ahead and remove the name_record, and invalidate the reverse record (if any).
        let record = table::remove(&mut self.registry, domain);

        // We can only call remove on a leaf record.
        assert!(sub_name_record::is_leaf(&record), ENotLeafRecord);
    }

    /// Extend a name's expiration (if allowed).
    public fun extend_expiration(self: &mut Namespace, nft: &mut SuinsRegistration, expiration_timestamp_ms: u64) {
        assert_is_valid_version(self);

        // validate that the NFT is valid for this namespace.
        assert!(is_nft_valid_for_namespace(self, nft), ENamespaceMissmatch);

        // Validate that the NFT's timestamp can be extended.
        assert!(is_extension_allowed(self, nft), ETimeExtensionDisabled);

        // Validate we're setting an expiration greater than the current one.
        assert!(expiration_timestamp_ms > nft::expiration_timestamp_ms(nft), EInvalidExpirationDate);

        // Find parent of NFT.
        let parent = domain::parent(&nft::domain(nft));

        // verify that the ID in the registry has not changed.
        let sub_name_record = lookup(self, nft::domain(nft));
        assert!(name_record::nft_id(sub_name_record::name_record(option::borrow(&sub_name_record))) == object::id(nft), EUnauthorizedNFT);

        // Check parent's expiration date.
        let max_expiration = if (&parent == &self.parent) {
            self.expiration_timestamp_ms
        } else {
            let parent_record = lookup(self, parent);
            let parent_name_record = sub_name_record::name_record(option::borrow(&parent_record));

            // Make sure parent has not changed.
            assert!(&name_record::nft_id(parent_name_record) == nft_parent(nft), EInvalidParent);

            name_record::expiration_timestamp_ms(parent_name_record)
        };

        // Validate expiration date <= parent's
        assert!(expiration_timestamp_ms <= max_expiration, EInvalidExpirationDate);

        let subdomain_record = table::borrow_mut(&mut self.registry, nft::domain(nft));
        let name_record = sub_name_record::name_record_mut(subdomain_record);

        // Update both the registry entry + the NFT's value.
        name_record::set_expiration_timestamp_ms(name_record, expiration_timestamp_ms);
        nft::set_expiration_timestamp_ms(nft, expiration_timestamp_ms);
    }
    
    /// Returns the `SubNameRecord` associated with the given domain or None.
    public fun lookup(self: &Namespace, domain: Domain): Option<SubNameRecord> {
        assert_is_valid_version(self);
        if (table::contains(&self.registry, domain)) {
            let record = table::borrow(&self.registry, domain);
            some(*record)
        } else {
            none()
        }
    }

    /// == Simple getters == 
    public fun parent_nft_id(self: &Namespace): ID {
        self.parent_nft_id
    }

    public fun parent(self: &Namespace): Domain {
        self.parent
    }

    /// Get the namespace for the given domain.
    /// Check of existence is done in the caller.
    public fun namespace(registration: &SuinsRegistration): &ID {
        df::borrow<NameSpaceData, ID>(nft::uid(registration), NameSpaceData {})
    }

    /// Set the target address for a subdomain.
    public fun set_target_address(self: &mut Namespace, nft: &SuinsRegistration, clock: &Clock, target: address) {
        assert_is_valid_version(self);

        // Validate that the NFT is still valid.
        assert!(!nft::has_expired(nft, clock), ENFTExpired);

        let domain = nft::domain(nft);
        let sub_name_record = table::borrow_mut(&mut self.registry, domain);

        let name_record = sub_name_record::name_record_mut(sub_name_record);

        // For subdomains, we don't invalidate reverse entries.
        // If we did care, we'd need to also do it when we create a name (to make sure there isn't a non expired one there)
        // so we would have to go through the main registry (and create congestion there).
        name_record::set_target_address(name_record, some(target));
    }

    /// Extend the namespace's expiration date.
    /// Recommended to be coupled when renewing a name as part of the PTB.
    /// 
    /// We could potentially make this completely permission-less by passing the `Registry` object
    /// and looking up the parent, but that might create unnecessary congestion as people might build PTBs that automatically
    /// extend the namespace expiration date (to avoid having to check off-chain before adding that PTB step).
    /// 
    /// Another approach is we can add a permission-less `entry` function to make sure that anyone can explicitly call it,
    /// but only allow that one transaction in the PTB. (we can introduce it on a package upgrade)
    public fun update_expiration(self: &mut Namespace, nft: &SuinsRegistration) {
        assert!(object::id(nft) == self.parent_nft_id, EUnauthorizedNFT);

        if (nft::expiration_timestamp_ms(nft) > self.expiration_timestamp_ms) {
            self.expiration_timestamp_ms = nft::expiration_timestamp_ms(nft);
        };
    }

    /// A public function to bump the version of a namespace
    /// based on the package's version.
    /// 
    /// Can be called by anyone to bump the version, and we can always decide to
    /// bump it for namespaces in any future package upgrade utilizing our indexing.
    public fun bump_version(self: &mut Namespace) {
        if (self.version < VERSION) {
            self.version = VERSION
        }
    }

    /// Immutable UID access.
    public fun uid(self: &Namespace): &UID {
        &self.id
    }

    /// Get the UID of the namespace as the parent name holder
    /// Allows us to install 3rd party logic to the namespace.
    public fun uid_mut(self: &mut Namespace, nft: &SuinsRegistration): &mut UID {
        assert!(object::id(nft) == self.parent_nft_id, EUnauthorizedNFT);
        &mut self.id
    }


    public fun expiration_timestamp_ms(self: &Namespace): u64 {
        self.expiration_timestamp_ms
    }

    /// Allows burning an epxired SubDomainRegistration
    public fun destroy_registration(registry: &mut Registry, sub_nft: SubDomainRegistration, clock: &Clock) {
        let nft = subdomain_registration::destroy(sub_nft);
        registry::burn_registration_object(registry, nft, clock);
    }

    /// === Private helpers === 
    /// 
    /// A guard for future versioning of our namespaces
    fun assert_is_valid_version(self: &Namespace) {
        assert!(self.version == VERSION, EInvalidVersion);
    }

    fun internal_remove_existing_record_if_exists_and_expired(
        namespace: &mut Namespace,
        domain: Domain,
        clock: &Clock
    ) {
        // if the domain is not part of the registry, we can override.
        if (!table::contains(&namespace.registry, domain)){
            return
        };

        // Remove the record and assert that it has expired.
        let record = table::remove(&mut namespace.registry, domain);
        let name_record = sub_name_record::name_record(&record);

        // Special case for leaf records, we can override them iff their parent has changed or has expired.
        if (sub_name_record::is_leaf(&record)) {

            // If the parent is a SLD, it means that the parent cannot expire (otherwise the namespace would have expired).
            // In order to replace a leaf record, we have to remove + re-add.
            if (domain::number_of_levels(&domain) == 3) {
                abort ERecordNotExpired
            };

            // find the parent of the leaf record.
            let option_parent_name_record = lookup(namespace, domain::parent(&domain));

            // I don't think that's a realistic scenario (We cannot have a child record without a parent record),
            // but adding it for sanity.
            if (!option::is_some(&option_parent_name_record)) {
                return
            };

            // if there's a parent (if not, we can just remove it), we need to check if the parent is valid.
            // -> If the parent is valid, we need to check if the parent is expired.
            // -> If the parent is not valid (nft_id has changed), or if the parent doesn't exist anymore (owner burned it), we can override the leaf record.
            let parent_name_record = sub_name_record::name_record(option::borrow(&option_parent_name_record));

            // If the parent is the same and hasn't expired, we can't override the leaf record like this.
            // We need to first remove + then call create (to protect accidental overrides).
            if (name_record::nft_id(parent_name_record) == name_record::nft_id(name_record)) {
                assert!(name_record::has_expired(parent_name_record, clock), ERecordNotExpired);
            };
        } else {
            assert!(name_record::has_expired(name_record, clock), ERecordNotExpired);
        };
    }

    /// Validate that the parent is valid when creating the namespace. 
    /// If we want to unblock the creation of a namespace for other TLDs (e.g. .move)
    /// we need to do a package upgrade and redo the logic here.
    fun is_accepted_tld(domain: &Domain): bool {
        domain::tld(domain) == &constants::sui_tld()
    }

    /// Check the depth of the domain we're trying to create
    fun assert_is_valid_subdomain_depth(domain: &Domain){
        assert!(domain::number_of_levels(domain) <= constants::max_domain_levels(), EInvalidSubdomainDepth);
    }

    /// Check that:
    /// 1. Parent is valid for the given namespace
    /// 2. Parent is not expired. We cannot use expired parents.
    /// 3. Passed domain is indeed a child of the parent.
    /// 4. Creation is allowed for the parent.
    fun assert_parent_valid_for_domain(
        namespace: &Namespace,
        domain: Domain,
        parent: &SuinsRegistration,
        clock: &Clock
    ) {
        // validate that the NFT is valid for this namespace.
        assert!(is_nft_valid_for_namespace(namespace, parent), ENamespaceMissmatch);

        // Validate that the NFT is still valid.
        assert!(!nft::has_expired(parent, clock), ENFTExpired);

        // Validate that the parent is the actual parent for the given domain_name.
        assert!(domain::is_parent_of(&nft::domain(parent), &domain), EInvalidParent);

        // Validate that creation is allowed for the parent.
        assert!(is_creation_allowed(namespace, parent), ENameCreationDisabled);
    }

    /// Check if creation is allowed for parent.
    fun is_creation_allowed(
        namespace: &Namespace,
        parent: &SuinsRegistration,
    ): bool {
        let parent_domain = nft::domain(parent);

        if (!domain::is_subdomain(&parent_domain)){
            return true
        };

        let record = lookup(namespace, parent_domain);

        if (option::is_none(&record)){
            return false
        };

        sub_name_record::is_creation_allowed(option::borrow(&record))
    }

    /// Check if time extension is allowed for this subdomain.
    fun is_extension_allowed(
        namespace: &Namespace,
        subdomain: &SuinsRegistration,
    ): bool {
        let domain = nft::domain(subdomain);

        if (!domain::is_subdomain(&domain)){
            return false
        };

        let record = lookup(namespace, domain);

        if (option::is_none(&record)){
            return false
        };

        sub_name_record::is_extension_allowed(option::borrow(&record))
    }

    /// Validate that an NFT is valid for this namespace (> means it was created here).
    fun is_nft_valid_for_namespace(namespace: &Namespace, nft: &SuinsRegistration): bool {
        if (!internal_namespace_exists(nft)){
            return false
        };

        &object::id(namespace) == namespace(nft)
    }

    /// Validate that a namespace has been attached to the NFT.
    fun internal_namespace_exists(nft: &SuinsRegistration): bool {
        df::exists_with_type<NameSpaceData, ID>(nft::uid(nft), NameSpaceData {})
    }

    /// Internal helper to tag an object with the namespace.
    /// Tagging the namespace makes it easy to check if the namespace is correct for a passed NFT.
    fun internal_tag_namespace(nft: &mut SuinsRegistration, id: ID) {
        df::add(nft::uid_mut(nft), NameSpaceData {}, id);
    }

    /// Returns the NFT's parent.
    fun nft_parent(nft: &SuinsRegistration): &ID {
        df::borrow<Parent, ID>(nft::uid(nft), Parent {})
    }

    /// Tag the parent NFT.
    fun internal_tag_parent(nft: &mut SuinsRegistration, id: ID) {
        df::add(nft::uid_mut(nft), Parent {} , id);
    }

    /// Internal helper to create namespace. Split so we can easily test it too.
    fun internal_create_namespace(registry: &mut Registry, nft: &mut SuinsRegistration, clock: &Clock, ctx: &mut TxContext): Namespace {
        // Validate that there's no namespace for that particular ID
        assert!(!internal_namespace_exists(nft), ENameSpaceAlreadyCreated);

        // the parent domain (creating the namespace)
        let parent_domain = nft::domain(nft);

        // Validate that the parent is a valid TLD for our namespaces setup.
        // Explanation: We might not use the namespaces for `.move` service
        assert!(is_accepted_tld(&parent_domain), ENotSupportedTLD);

        // Validate that the NFT is still valid.
        assert!(!nft::has_expired(nft, clock), ENFTExpired);

        // Validate that it's a SLD (only those have their own namespaces)
        assert!(!domain::is_subdomain(&parent_domain), ENotASLDName);

        let name_space_id = object::new(ctx);

        // Add the namespace metadata to the NFT (to prevent multiple namespaces from being created).
        internal_tag_namespace(nft, *object::uid_as_inner(&name_space_id));

        // Create the Namespace for the object
        let namespace = Namespace {
            id: name_space_id,
            parent_nft_id: object::id(nft),
            parent: parent_domain,
            registry: table::new(ctx),
            expiration_timestamp_ms: nft::expiration_timestamp_ms(nft),
            version: VERSION,
        };

        // Update metadata of main registry to include the namespace ID.
        // That allows the RPC to easily find which namespace to query for a given SLD domain.
        let metadata = *registry::get_data(registry, parent_domain);
        vec_map::insert(&mut metadata, constants::namespace_key(), address::to_string(object::id_address(&namespace)));
        vec_map::insert(&mut metadata, constants::namespace_table_id(), address::to_string(object::id_address(&namespace.registry)));
        registry::set_data(registry, parent_domain, metadata);

        namespace
    }


    #[test_only]
    public fun create_namespace_for_testing(registry: &mut Registry, nft: &mut SuinsRegistration, clock: &Clock, ctx: &mut TxContext): Namespace {
        internal_create_namespace(registry, nft, clock, ctx)
    }

    #[test_only]
    public fun burn_namespace_for_testing(namespace: Namespace) {
        let Namespace {
            id,
            parent_nft_id: _,
            parent: _,
            registry,
            expiration_timestamp_ms: _,
            version: _,
        } = namespace;

        table::drop(registry);
        object::delete(id);
    }
}