/// Copying controller logic here to see what we can do with it.
/// Stores the main user interaction logic (except for the Auction).
module suins::controller {
    use std::vector;
    use std::option::Option;
    use std::string::{Self, utf8, String};
    use sui::coin::{Self, Coin};
    use sui::tx_context::{sender, TxContext};
    // use sui::clock::{timestamp_ms, Clock};
    use sui::clock::Clock;
    use sui::sui::SUI;
    // use sui::object;
    use sui::bcs;
    use sui::ecdsa_k1;

    use suins::domain;
    use suins::constants;
    // use suins::name_record;
    use suins::registry::{Self, Registry};
    use suins::suins::{Self, SuiNS};
    use suins::config::{Self, Config};
    use suins::domain::Domain;
    use suins::registration_nft::{Self as nft, RegistrationNFT};

    /// Number of years passed is not within [1-5] interval.
    const EInvalidYearsArgument: u64 = 0;
    /// Trying to register a subdomain (only *.sui is currently allowed).
    const EInvalidDomain: u64 = 1;
    /// Trying to register a domain name in a different TLD (not .sui).
    const EInvalidTld: u64 = 2;
    /// Trying to register domain name that is shorter than 6 symbols.
    const EInvalidDomainLength: u64 = 3;
    /// The payment does not match the price for the domain.
    const EIncorrectAmount: u64 = 4;
    /// Trying to purchase a domain that is already registered and active.
    const ENotExpired: u64 = 5;
    /// The NFT does not match the currently active `nft_id` in the `NameRecord`.
    const EInvalidToken: u64 = 6;

    /// Trying to update an image in an expired `RegistrationNFT`.
    const EExpired: u64 = 0;
    /// Message data cannot be parsed.
    const EInvalidData: u64 = 1;
    /// The parsed name does not match the expected domain.
    const EInvalidDomainData: u64 = 2;
    const ESignatureNotMatch: u64 = 210;

    /// Authorization token for the app.
    struct App has drop {}

    // Allows direct purchases of domains
    //
    // Makes sure that:
    // - the domain is not already registered (or, if active, expired)
    // - the domain TLD is .sui
    // - the domain is not a subdomain
    // - number of years is within [1-5] interval
    public fun register(
        suins: &mut SuiNS,
        domain_name: String,
        no_years: u8,
        payment: Coin<SUI>,
        clock: &Clock,
        ctx: &mut TxContext
    ): RegistrationNFT {
        suins::assert_app_is_authorized<App>(suins);

        let config = suins::get_config<Config>(suins);
        assert!(config::is_user_registration_enabled(config), 0);

        let domain = domain::new(domain_name);
        assert_valid_user_registerable_domain(&domain);

        assert!(0 < no_years && no_years <= 5, EInvalidYearsArgument);

        let label = vector::borrow(domain::labels(&domain), 0);
        let price = config::calculate_price(config, (string::length(label) as u8), no_years);

        assert!(coin::value(&payment) == price, EIncorrectAmount);

        suins::app_add_balance(App {}, suins, coin::into_balance(payment));
        let registry = suins::registry_mut<Registry, App>(suins, App {});
        registry::add_record(registry, domain, no_years, clock, ctx)
    }

    // /// Renew a registered domain name by a number of years (not exceeding 5).
    // /// The domain name must be already registered and active; `RegistrationNFT`
    // /// serves as the proof of that.
    // ///
    // /// We make sure that (in order):
    // /// - the domain is already registered and active
    // /// - the RegistrationNFT matches the NameRecord.nft_id
    // /// - the domain TLD is .sui
    // /// - the domain is not a subdomain
    // /// - number of years is within [1-5] interval
    // /// - the new expiration does not exceed 5 years from now
    // /// - the payment matches the price for the domain
    // ///
    // /// TODO: update the record via SuiNS.
    // public fun renew(
    //     suins: &mut SuiNS,
    //     token: &mut RegistrationNFT,
    //     no_years: u8,
    //     payment: Coin<SUI>,
    //     clock: &Clock,
    // ) {
    //     let domain = nft::domain(token);

    //     let labels = domain::labels(&domain);
    //     let label_len = (string::length(vector::borrow(labels, 0)) as u8);
    //     let config = suins::get_config<Config>(suins);
    //     let price = config::calculate_price(config, label_len, no_years);
    //     let name_record = suins::name_record(suins, domain);
    //     // to be used to check if the new expiration is within 5 years from now
    //     let _max_expires = timestamp_ms(clock) + (5 * constants::year_ms());

    //     assert!(vector::length(labels) == 2, EInvalidDomain);
    //     assert!(domain::tld(&domain) == &constants::sui_tld(), EInvalidTld);
    //     assert!(0 < no_years && no_years <= 5, EInvalidYearsArgument);
    //     assert!(coin::value(&payment) == price, EIncorrectAmount);
    //     assert!(name_record::nft_id(name_record) == object::id(token), EInvalidToken);

    //     suins::app_add_balance(App {}, suins, coin::into_balance(payment));
    //     // update the record
    // }

    // === Update Records Functionality ===

    public fun set_target_address(
        suins: &mut SuiNS,
        nft: &RegistrationNFT,
        new_target: Option<address>,
        clock: &Clock,
    ) {
        suins::assert_app_is_authorized<App>(suins);

        let registry = suins::registry_mut<Registry, App>(suins, App {});
        registry::set_target_address(registry, nft, new_target, clock);
    }

    public fun set_reverse_lookup(
        suins: &mut SuiNS,
        domain: Option<Domain>,
        ctx: &TxContext,
    ) {
        suins::assert_app_is_authorized<App>(suins);

        let registry = suins::registry_mut<Registry, App>(suins, App {});
        let sender = sender(ctx);
        registry::set_reverse_lookup(registry, sender, domain);
    }

    // === Update Image Functionality ===

    /// Updates the image attached to a `RegistrationNFT`.
    public fun update_image_url(
       suins: &mut SuiNS,
       nft: &mut RegistrationNFT,
       raw_msg: vector<u8>,
       signature: vector<u8>,
       clock: &Clock,
       _ctx: &mut TxContext,
    ) {
        suins::assert_app_is_authorized<App>(suins);
        // let registry = suins::registry<Registry>(suins);
        let config = suins::get_config<Config>(suins);

        assert!(
            ecdsa_k1::secp256k1_verify(&signature, config::public_key(config), &raw_msg, 1),
            ESignatureNotMatch
        );

        let (ipfs_hash, domain_name, expiration_timestamp_ms, _data) = image_data_from_bcs(raw_msg);

        assert!(!nft::has_expired(nft, clock), EExpired);
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

    /// === Helpers ===

    /// Asserts that a domain is registerable by a user:
    /// - TLD is "sui"
    /// - only has 1 label, "name", other than the TLD
    /// - "name" is >= 3 characters long
    public fun assert_valid_user_registerable_domain(domain: &Domain) {
        assert!(domain::tld(domain) == &constants::sui_tld(), EInvalidTld);
        let labels = domain::labels(domain);
        assert!(vector::length(labels) == 2, EInvalidDomain);
        assert!(string::length(vector::borrow(labels, 0)) >= 3, EInvalidDomainLength);
    }
}
