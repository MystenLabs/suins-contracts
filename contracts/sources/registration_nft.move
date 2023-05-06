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
    use suins::domain::{Self, Domain};

    friend suins::suins;
    friend suins::registry;

    /// Trying to update an image in an expired `RegistrationNFT`.
    const EExpired: u64 = 0;
    /// Message data cannot be parsed.
    const EInvalidData: u64 = 1;
    /// The parsed name does not match the expected domain.
    const EInvalidDomainData: u64 = 2;

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

    // === Public methods ===

    /// Update the image URl for the `RegistrationNFT`. Can only be performed by
    ///
    public fun update_image(
        self: &mut RegistrationNFT,
        _signature: vector<u8>,
        _hashed_msg: vector<u8>,
        raw_msg: vector<u8>,
        clock: &Clock,
        _ctx: &mut TxContext,
    ) {
        // cryptography bits
        // TODO: need to get access to `public_key` here - how?
        // HINT: search `assert_image_msg_match` to find the function

        let (ipfs_hash, domain_name, expiration_timestamp_ms, _data) = bcs_to_image_data(raw_msg);

        assert!(!has_expired(self, clock), EExpired);
        assert!(self.expiration_timestamp_ms == expiration_timestamp_ms, EInvalidData);
        assert!(domain::to_string(&self.domain) == domain_name, EInvalidDomainData);

        self.image_url = ipfs_hash;
    }

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

    // === Utilities ===

    /// Parses the message bytes into the image data.
    ///
    /// ```
    /// struct MessageData {
    ///   ipfs_hash: String,
    ///   domain_name: String,
    ///   expiration_timestamp_ms: u64,
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
