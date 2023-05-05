/// Module that handles creation of the `RegistrationNFT`s. Separates the logic
/// of creating a `RegistrationNFT` from the main SuiNS block. New `RegistrationNFT`s
/// can be created only by the suins.
///
///
module suins::registration_nft {
    use std::string::{utf8, String};
    use sui::object::{Self, UID};
    use sui::tx_context::TxContext;
    use sui::clock::{timestamp_ms, Clock};
    use sui::bcs;

    use suins::constants;
    use suins::domain::Domain;

    // The one in only friend.
    friend suins::suins;

    /// Trying to update an image in an expired `RegistrationNFT`.
    const EExpired: u64 = 0;
    /// Message data cannot be parsed.
    const EInvalidData: u64 = 1;
    /// The parsed name does not match the expected domain.
    const EInvalidDomainData: u64 = 2;

    /// The main access point for the user.
    struct RegistrationNFT has key, store {
        id: UID,
        /// Short IPFS hash of the image to be displayed for the NFT.
        image_url: String,
        /// The domain name that the NFT is for.
        domain: Domain,
        /// The expiration timestamp of the NFT.
        expires_at: u64
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

    // === Public methods ===

    /// Update the image URl for the `RegistrationNFT`. Can only be performed by
    ///
    public fun update_image(
        self: &mut RegistrationNFT,
        signature: vector<u8>,
        hashed_msg: vector<u8>,
        raw_msg: vector<u8>,
        clock: &Clock,
        ctx: &mut TxContext,
    ) {
        // cryptography bits
        // TODO: need to get access to `public_key` here - how?
        // HINT: search `assert_image_msg_match` to find the function

        let (ipfs_hash, domain_name, expires_at, data) = bcs_to_image_data(raw_msg);

        assert!(!has_expired(self, clock), EExpired);
        assert!(self.expires_at == expires_at, EInvalidData);
        assert!(domain::to_string(&self.domain) == domain_name, EInvalidDomainData);

        self.image_url = ipfs_hash;
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

    // === Utilities ===

    /// Parses the message bytes into the image data.
    ///
    /// ```
    /// struct MessageData {
    ///   ipfs_hash: String,
    ///   domain_name: String,
    ///   expires_at: u64,
    ///   data: String
    /// }
    /// ```
    ///
    fun bcs_to_image_data(msg_bytes: vector<u8>): (String, String, u64, String) {
        let bcs = bcs::new(msg_bytes);

        (
            utf8(bcs::peel_vec_u8(&mut bcs)),
            utf8(bcs::peel_vec_u8(&mut bcs)),
            bcs::peel_u64(&mut bcs),
            utf8(bcs::peel_vec_u8(&mut bcs))
        )
    }
}
