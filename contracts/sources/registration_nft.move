/// Module that handles creation of the `RegistrationNFT`s. Separates the logic
/// of creating a `RegistrationNFT` from the main SuiNS block. New `RegistrationNFT`s
/// can be created only by the suins.
///
///
module suins::registration_nft {
    use std::string::{String};
    use sui::object::{Self, UID};
    use sui::tx_context::TxContext;
    use sui::clock::{timestamp_ms, Clock};

    use suins::constants;
    use suins::domain::Domain;

    friend suins::controller;
    friend suins::registry;

    /// The main access point for the user.
    struct RegistrationNFT has key, store {
        id: UID,
        /// The domain name that the NFT is for.
        domain: Domain,
        /// Timestamp in milliseconds when this NFT expires.
        expiration_timestamp_ms: u64,
        /// Short IPFS hash of the image to be displayed for the NFT.
        image_url: String,
    }

    // === Protected methods ===

    /// Can only be called by the SuiNS, creates a new `RegistrationNFT`.
    public(friend) fun new(
        domain: Domain,
        no_years: u8,
        clock: &Clock,
        ctx: &mut TxContext
    ): RegistrationNFT {
        RegistrationNFT {
            id: object::new(ctx),
            domain,
            expiration_timestamp_ms: timestamp_ms(clock) + ((no_years as u64) * constants::year_ms()),
            image_url: constants::default_image(),
        }
    }

    /// Sets the expiration_timestamp_ms for this NFT
    public(friend) fun set_expiration_timestamp_ms(self: &mut RegistrationNFT, expiration_timestamp_ms: u64) {
        self.expiration_timestamp_ms = expiration_timestamp_ms;
    }

    public(friend) fun update_image_url(self: &mut RegistrationNFT, image_url: String) {
        self.image_url = image_url;
    }

    // === Public methods ===

    /// Check whether the `RegistrationNFT` has expired by comparing the
    /// expiration timeout with the current time.
    public fun has_expired(self: &RegistrationNFT, clock: &Clock): bool {
        self.expiration_timestamp_ms < timestamp_ms(clock)
    }

    /// Check whether the `RegistrationNFT` has expired by comparing the
    /// expiration timeout with the current time. This function also takes into
    /// account the grace period.
    public fun has_expired_with_grace(self: &RegistrationNFT, clock: &Clock): bool {
        (self.expiration_timestamp_ms + constants::grace_period_ms()) < timestamp_ms(clock)
    }

    // === Getters ===

    /// Get the `domain` field of the `RegistrationNFT`.
    public fun domain(self: &RegistrationNFT): Domain { self.domain }

    /// Get the `expiration_timestamp_ms` field of the `RegistrationNFT`.
    public fun expiration_timestamp_ms(self: &RegistrationNFT): u64 { self.expiration_timestamp_ms }
}
