/// Module that handles creation of the `RegistrationNFT`s. Separates the logic
/// of creating a `RegistrationNFT` from the main SuiNS block. New `RegistrationNFT`s
/// can be created only by the suins.
///
///
module suins::registration_nft {
    use std::string::String;
    use sui::object::{Self, UID};
    use sui::tx_context::TxContext;

    use suins::constants;

    // The one in only friend.
    friend suins::suins;

    /// The main access point for the user.
    struct RegistrationNFT has key, store {
        id: UID,
        /// Short IPFS hash of the image to be displayed for the NFT.
        image_url: String,
        /// The domain name that the NFT is for.
        domain_name: String,
        /// The expiration timestampt of the NFT.
        expires_at: u64
    }

    /// Can only be called by the SuiNS, creates a new `RegistrationNFT`.
    public(friend) fun new(
        domain_name: String,
        image_url: String,
        ctx: &mut TxContext
    ): RegistrationNFT {
        RegistrationNFT {
            domain_name,
            id: object::new(ctx),
            image_url: constants::default_image(),
            expires_at: 0
        }
    }

    // === Getters ===

    /// Get the `domain_name` field of the `RegistrationNFT`.
    public fun domain(self: &RegistrationNFT): String { self.domain_name }
    /// Get the `expires_at` field of the `RegistrationNFT`.
    public fun expires_at(self: &RegistrationNFT): u64 { self.expires_at }
}
