// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// Handles creation of the `SuinsRegistration`s. Separates the logic of creating
/// a `SuinsRegistration`. New `SuinsRegistration`s can be created only by the
/// `registry` and this module is tightly coupled with it.
///
/// When reviewing the module, make sure that:
///
/// - mutable functions can't be called directly by the owner
/// - all getters are public and take an immutable reference
///
module suins::suins_registration {
    use std::string::{String};
    use sui::clock::{timestamp_ms, Clock};

    use suins::{constants, domain::Domain};

    /* friend suins::registry; */
    /* friend suins::update_image; */

    /// The main access point for the user.
    public struct SuinsRegistration has key, store {
        id: UID,
        /// The parsed domain.
        domain: Domain,
        /// The domain name that the NFT is for.
        domain_name: String,
        /// Timestamp in milliseconds when this NFT expires.
        expiration_timestamp_ms: u64,
        /// Short IPFS hash of the image to be displayed for the NFT.
        image_url: String,
    }

    // === Protected methods ===

    /// Creates a new `SuinsRegistration`.
    /// Can only be called by the `registry` module.
    public(package) fun new(
        domain: Domain,
        no_years: u8,
        clock: &Clock,
        ctx: &mut TxContext
    ): SuinsRegistration {
        SuinsRegistration {
            id: object::new(ctx),
            domain_name: domain.to_string(),
            domain,
            expiration_timestamp_ms: timestamp_ms(clock) + ((no_years as u64) * constants::year_ms()),
            image_url: constants::default_image(),
        }
    }

    /// Sets the `expiration_timestamp_ms` for this NFT.
    public(package) fun set_expiration_timestamp_ms(self: &mut SuinsRegistration, expiration_timestamp_ms: u64) {
        self.expiration_timestamp_ms = expiration_timestamp_ms;
    }

    /// Updates the `image_url` field for this NFT. Is only called in the `update_image` for now.
    public(package) fun update_image_url(self: &mut SuinsRegistration, image_url: String) {
        self.image_url = image_url;
    }

    /// Destroys the `SuinsRegistration` by deleting it from the store, returning
    /// storage rebates to the caller.
    /// Can only be called by the `registry` module.
    public(package) fun burn(self: SuinsRegistration) {
        let SuinsRegistration {
            id,
            image_url: _,
            domain: _,
            domain_name: _,
            expiration_timestamp_ms: _
        } = self;

        id.delete();
    }

    // === Public methods ===

    /// Check whether the `SuinsRegistration` has expired by comparing the
    /// expiration timeout with the current time.
    public fun has_expired(self: &SuinsRegistration, clock: &Clock): bool {
        self.expiration_timestamp_ms < timestamp_ms(clock)
    }

    /// Check whether the `SuinsRegistration` has expired by comparing the
    /// expiration timeout with the current time. This function also takes into
    /// account the grace period.
    public fun has_expired_past_grace_period(self: &SuinsRegistration, clock: &Clock): bool {
        (self.expiration_timestamp_ms + constants::grace_period_ms()) < timestamp_ms(clock)
    }

    // === Getters ===

    /// Get the `domain` field of the `SuinsRegistration`.
    public fun domain(self: &SuinsRegistration): Domain { self.domain }

    /// Get the `domain_name` field of the `SuinsRegistration`.
    public fun domain_name(self: &SuinsRegistration): String { self.domain_name }

    /// Get the `expiration_timestamp_ms` field of the `SuinsRegistration`.
    public fun expiration_timestamp_ms(self: &SuinsRegistration): u64 { self.expiration_timestamp_ms }

    /// Get the `image_url` field of the `SuinsRegistration`.
    public fun image_url(self: &SuinsRegistration): String { self.image_url }

    // get a read-only `uid` field of `SuinsRegistration`.
    public fun uid(self: &SuinsRegistration): &UID { &self.id }

    /// Get the mutable `id` field of the `SuinsRegistration`.
    public fun uid_mut(self: &mut SuinsRegistration): &mut UID { &mut self.id }

    // === Testing ===

    #[test_only]
    public fun new_for_testing(
        domain: Domain,
        no_years: u8,
        clock: &Clock,
        ctx: &mut TxContext
    ): SuinsRegistration {
        new(domain, no_years, clock, ctx)
    }

    #[test_only]
    public fun set_expiration_timestamp_ms_for_testing(
        self: &mut SuinsRegistration,
        expiration_timestamp_ms: u64
    ) {
        set_expiration_timestamp_ms(self, expiration_timestamp_ms);
    }

    #[test_only]
    public fun update_image_url_for_testing(
        self: &mut SuinsRegistration,
        image_url: String
    ) {
        update_image_url(self, image_url);
    }

    #[test_only]
    public fun burn_for_testing(nft: SuinsRegistration) {
        let SuinsRegistration {
            id,
            image_url: _,
            domain: _,
            domain_name: _,
            expiration_timestamp_ms: _
        } = nft;

        id.delete();
    }
}
