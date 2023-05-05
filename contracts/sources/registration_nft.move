/// Module that handles creation of the `RegistrationNFT`s. Separates the logic
/// of creating a `RegistrationNFT` from the main SuiNS block. New `RegistrationNFT`s
/// can be created only by the suins.
///
///
module suins::registration_nft {
    use std::string::String;
    use sui::object::{Self, UID};
    use sui::tx_context::TxContext;
    use sui::clock::{timestamp_ms, Clock};

    use suins::constants;
    use suins::domain::Domain;

    // The one in only friend.
    friend suins::suins;

    /// The main access point for the user.
    struct RegistrationNFT has key, store {
        id: UID,
        /// Short IPFS hash of the image to be displayed for the NFT.
        image_url: String,
        /// The domain name that the NFT is for.
        domain: Domain,
        /// The expiration timestampt of the NFT.
        expires_at: u64
    }

    /// Can only be called by the SuiNS, creates a new `RegistrationNFT`. By
    /// default we set expiration timeout to 1 year (but this needs to be verified).
    /// TODO: verify the expiration timeout.
    public(friend) fun new(
        domain: Domain,
        no_years: u8,
        clock: &Clock,
        ctx: &mut TxContext
    ): RegistrationNFT {
        RegistrationNFT {
            domain,
            id: object::new(ctx),
            image_url: constants::default_image(),
            expires_at: timestamp_ms(clock) + ((no_years as u64) * constants::year_ms())
        }
    }

    /// Calculate the price of the `RegistrationNFT` based on the domain name length.
    public(friend) fun set_expires_at(self: &mut RegistrationNFT, expires_at: u64) {
        self.expires_at = expires_at;
    }

    /// Check whether the `RegistrationNFT` has expired by comparing the
    /// expiration timeout with the current time.
    public fun has_expired(self: &RegistrationNFT, clock: &Clock): bool {
        self.expires_at < timestamp_ms(clock)
    }

    /// Check whether the `RegistrationNFT` has expired by comparing the
    /// expiration timeout with the current time. This function also takes into
    /// account the grace period.
    public fun has_expired_with_grace(self: &RegistrationNFT, clock: &Clock): bool {
        (self.expires_at + constants::grace_period_ms()) < timestamp_ms(clock)
    }

    // === Getters ===

    /// Get the `domain` field of the `RegistrationNFT`.
    public fun domain(self: &RegistrationNFT): Domain { self.domain }

    /// Get the `expires_at` field of the `RegistrationNFT`.
    public fun expires_at(self: &RegistrationNFT): u64 { self.expires_at }
}
