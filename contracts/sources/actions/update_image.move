module suins::update_image {
    use std::vector;
    use std::string::{utf8, String};
    use sui::clock::Clock;
    use sui::bcs;
    use sui::ecdsa_k1;

    use suins::domain;
    use suins::registry::{Self, Registry};
    use suins::suins::{Self, SuiNS};
    use suins::config::{Self, Config};
    use suins::suins_registration::{Self as nft, SuinsRegistration};

    /// Message data cannot be parsed.
    const EInvalidData: u64 = 0;
    /// The parsed name does not match the expected domain.
    const EInvalidDomainData: u64 = 1;
    /// Invalid signature for the message.
    const ESignatureNotMatch: u64 = 2;

    /// Authorization token for the app.
    struct UpdateImage has drop {}

    /// Updates the image attached to a `SuinsRegistration`.
    entry fun update_image_url(
       suins: &mut SuiNS,
       nft: &mut SuinsRegistration,
       raw_msg: vector<u8>,
       signature: vector<u8>,
       clock: &Clock,
    ) {
        suins::assert_app_is_authorized<UpdateImage>(suins);
        let registry = suins::registry<Registry>(suins);
        registry::assert_nft_is_authorized(registry, nft, clock);

        let config = suins::get_config<Config>(suins);

        assert!(
            ecdsa_k1::secp256k1_verify(&signature, config::public_key(config), &raw_msg, 1),
            ESignatureNotMatch
        );

        let (ipfs_hash, domain_name, expiration_timestamp_ms, _data) = image_data_from_bcs(raw_msg);

        assert!(nft::expiration_timestamp_ms(nft) == expiration_timestamp_ms, EInvalidData);
        assert!(domain::to_string(&nft::domain(nft)) == domain_name, EInvalidDomainData);

        nft::update_image_url(nft, ipfs_hash);

        // TODO emit an event
        // event::emit(ImageUpdatedEvent {
        //     sender: tx_context::sender(ctx),
        //     domain_name: nft.name,
        //     new_image: nft.url,
        //     data: additional_data,
        // })
    }

    /// Parses the message bytes into the image data.
    /// ```
    /// struct MessageData {
    ///   ipfs_hash: String,
    ///   domain_name: String,
    ///   expiration_timestamp_ms: u64,
    ///   data: String
    /// }
    /// ```
    fun image_data_from_bcs(msg_bytes: vector<u8>): (String, String, u64, String) {
        let bcs = bcs::new(msg_bytes);

        let ipfs_hash = utf8(bcs::peel_vec_u8(&mut bcs));
        let domain_name = utf8(bcs::peel_vec_u8(&mut bcs));
        let expiration_timestamp_ms = bcs::peel_u64(&mut bcs);
        let data = utf8(bcs::peel_vec_u8(&mut bcs));

        let remainder = bcs::into_remainder_bytes(bcs);
        vector::destroy_empty(remainder);

        (
            ipfs_hash,
            domain_name,
            expiration_timestamp_ms,
            data,
        )
    }
}
