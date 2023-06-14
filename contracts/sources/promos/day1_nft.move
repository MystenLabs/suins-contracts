module suins::day1_nft {
    use std::string::{Self, String};
    use std::option::{Self, Option};

    use sui::clock::{Self, Clock};
    use sui::object::{Self, UID, ID};
    use sui::tx_context::{TxContext};
    use sui::dynamic_field::{Self as df};
    use sui::event;

    use suins::config;
    use suins::domain::{Self, Domain};
    use suins::suins::{Self, SuiNS, AdminCap};
    use suins::suins_registration::{Self as nft, SuinsRegistration};
    use suins::registry::{Self, Registry};

    /// Constants
    /// The period that you can attach domains to a Day1 Object is 1 day.
    const ATTACH_DOMAINS_PERIOD_MS: u64 = 1 * 24 * 60 * 60 * 1000;
    /// One year is the default duration for a domain.
    const DEFAULT_DURATION: u8 = 1;

    /// Error messages
    // This Day1NFT has already been activated
    const EAlreadyActivated: u64 = 0;
    // This domain has already been used to mint a free domain.
    const EDomainAlreadyUsed: u64 = 1;
    // Attaching period has expired for `SuinsDay1` object.
    const EAttachingExpired: u64 = 2;
    // Tries to use an expired domain.
    const EDomainExpired: u64 = 3;
    // Tries to claim a domain with a non activated SuinsDay1 object.
    const ENotActivated: u64 = 4;
    // Day1Object doesn't have free claims
    const ENotEnoughFreeClaims: u64 = 5;
    // Domain is from free promo and cant be re-used
    const EPromoDomainUsed: u64 = 6;

    /// App Authorization 
    /// Authorization token for the app.
    /// Used to authorize the app to claim free names
    /// by using a SuinsDay1 object.
    struct Day1AuthToken has drop {}

    /// Dynamic field Key: Shows that the `SuinsRegistration` object has
    /// been stamped for Day1NFT
    struct UsedInDay1 has copy, store, drop { }

    /// Dynamic field key which shows that the `SuinsRegistration` object was
    /// minted from a Day1 promotion.
    struct MintedFromDay1 has copy, store, drop { }

    // the Day1NFT contains the free available mints of names
    // as well as the activation status.
    struct SuinsDay1 has key, store {
        id: UID,
        free_three_char_names: u64,
        free_four_char_names: u64,
        free_five_char_names: u64,
        is_activated: bool,
        activation_expiry: Option<u64>
    }

    // Mint a Day1NFT by passing the AdminCap.
    public fun mint(_: &AdminCap, ctx: &mut TxContext): SuinsDay1 {
        SuinsDay1 {
            id: object::new(ctx),
            free_three_char_names: 0,
            free_four_char_names: 0,
            free_five_char_names: 0,
            is_activated: false,
            activation_expiry: option::none()
        }
    }

    // Usage of Day1NFt to claim a free domain.
    // Aborts if the day1 object is not activated,
    // the domain
    public fun claim(
        self: &mut SuinsDay1,
        suins: &mut SuiNS, 
        domain_name: String,
        clock: &Clock,
        ctx: &mut TxContext,
    ): SuinsRegistration {
        // verify the `SuinsDay1` object is activated.
        assert!(self.is_activated, ENotActivated);

        suins::assert_app_is_authorized<Day1AuthToken>(suins);
        let domain = domain::new(domain_name);
        // make sure the domain is a .sui domain and not a subdomain
        config::assert_valid_user_registerable_domain(&domain);

        // get domain's size
        let size = domain_length(&domain);

        // based on the size of the domain, we check if there are enough
        // available claims on the `Day1Object`.
        if(size == 3){
            assert!(self.free_three_char_names > 0, ENotEnoughFreeClaims);
            self.free_three_char_names = self.free_three_char_names - 1;
        } else if(size == 4){
            assert!(self.free_four_char_names > 0, ENotEnoughFreeClaims);
            self.free_four_char_names = self.free_four_char_names - 1;
        }else{
            assert!(self.free_five_char_names > 0, ENotEnoughFreeClaims);
            self.free_five_char_names = self.free_five_char_names - 1;
        };

        // Register the domain to the registry.
        // There's a possibility to abort if the domain is taken.
        let registry = suins::app_registry_mut<Day1AuthToken, Registry>(Day1AuthToken {}, suins);
        let nft = registry::add_record(registry, domain, DEFAULT_DURATION, clock, ctx);

        event::emit(FreeDomainClaimedEvent {
            day1_id: object::uid_to_inner(&self.id),
            domain
        });

        // mark the domain as used.
        mark_domain_as_promo(&mut nft);
        
        nft
    }

    /// Attaches a domain to `SuinsDay1NFT`
    /// When the first attachment happens the clock is set to `ATTACH_DOMAINS_PERIOD_MS` (+ current time)
    /// Aborts:
    /// 1. domain_nft is invalid or has been used for another attachment
    /// 2. day1_nft attaching has expired
    public fun attach_domain(
       self: &mut SuinsDay1,
       domain_nft: &mut SuinsRegistration,
       clock: &Clock
    ) {
        // assert that the nft that was passed hasn't expired.
        assert!(!nft::has_expired(domain_nft, clock), EDomainExpired);

        // assert that the day1_nft is not activated.
        assert!(!self.is_activated, EAlreadyActivated);

        // verify the `domain_nft` hasn't been attached to another day1 object.
        assert!(!is_domain_attached(domain_nft), EDomainAlreadyUsed);

        // verify that `domain_nft` hasn't been minted for free from another promo.
        assert!(!is_free_domain_from_promo(domain_nft), EPromoDomainUsed);

        let current_time = clock::timestamp_ms(clock);
        // (first domain attachment only)
        // if the day1_nft doesn't have an `activation_expiry` value set, we set
        // it to be `ATTACH_DOMAINS_PERIOD_MS` from current time.
        if (option::is_none(&self.activation_expiry)){
            self.activation_expiry = option::some(current_time + ATTACH_DOMAINS_PERIOD_MS);
        };

        // extract expiry timestamp from from option.
        let activation_expiry_ms = option::get_with_default(&self.activation_expiry, current_time);

        // Make sure the limit epoch hasn't passed.
        assert!(current_time <= activation_expiry_ms, EAttachingExpired);

        let size = domain_length(&nft::domain(domain_nft));

        // increase available free domains based on the supplied domain.
        if (size == 3){
            self.free_three_char_names = self.free_three_char_names + 1;
        }else if (size == 4){
            self.free_four_char_names = self.free_four_char_names + 1;
        }else {
            self.free_five_char_names = self.free_five_char_names + 1;
        };

        // mark the domain as used.
        mark_domain_as_used(domain_nft);

        event::emit(DomainAttachedEvent {
            day1_id: object::uid_to_inner(&self.id),
            domain: nft::domain(domain_nft)
        })
    }

    // Activates the day1 object to be used in claiming.
    public entry fun activate(self: &mut SuinsDay1){
        // Verify that the day1 nft is not activated.
        assert!(!self.is_activated, EAlreadyActivated);

        // activate it to claim free domains.
        self.is_activated = true;

        event::emit(PromoActivated {
            day1_id: object::uid_to_inner(&self.id),
            free_five_char_names: self.free_five_char_names,
            free_four_char_names: self.free_four_char_names,
            free_three_char_names: self.free_three_char_names
        })
    }



    /// Check if a domain has been attached for a day1 nft free claim.
    public fun is_domain_attached(domain_nft: &SuinsRegistration): bool {
        let uid = nft::uid(domain_nft);
        let key = UsedInDay1 {};

        df::exists_(uid, key)
    }

    // Check if the domain has been minted for free from this promo.
    public fun is_free_domain_from_promo(domain_nft: &SuinsRegistration): bool {
        let uid = nft::uid(domain_nft);
        let key = MintedFromDay1 {};

        df::exists_(uid, key)
    }

    // === Private helpers ===

    /// Attaches a DF that marks a domain as `used` in another day 1 object.
    fun mark_domain_as_used(domain_nft: &mut SuinsRegistration) {
        let uid_mut = nft::uid_mut(domain_nft);
        let key = UsedInDay1 {};

        df::add(uid_mut, key, true)
    }

    /// Attaches a DF that marks a domain as `used` in another day 1 object.
    fun mark_domain_as_promo(domain_nft: &mut SuinsRegistration) {
        let uid_mut = nft::uid_mut(domain_nft);
        let key = MintedFromDay1 {};

        df::add(uid_mut, key, true)
    }

    // Returns the size of a domain name.
    fun domain_length(domain: &Domain): u64{
        // actual name from the name array.
        let label = domain::sld(domain);
        // size of the name.
        string::length(label)
    }


  // === Public getters ===

    public fun free_five_char_names(self: &SuinsDay1): u64 {
        self.free_five_char_names
    }

    public fun free_four_char_names(self: &SuinsDay1): u64 {
        self.free_four_char_names
    }

    public fun free_three_char_names(self: &SuinsDay1): u64 {
        self.free_three_char_names
    }

    public fun is_activated(self: &SuinsDay1): bool {
        self.is_activated
    }

    public fun activation_expiry(self: &SuinsDay1): Option<u64> {
        self.activation_expiry
    }

    // === Events ===

    struct DomainAttachedEvent has copy, drop {
        day1_id: ID,
        domain: Domain
    }

    struct FreeDomainClaimedEvent has copy, drop {
        day1_id: ID,
        domain: Domain
    }

    struct PromoActivated has copy, drop {
        day1_id: ID,
        free_three_char_names: u64,
        free_four_char_names: u64,
        free_five_char_names: u64
    }

    #[test_only]
    public fun mint_for_testing(ctx: &mut TxContext): SuinsDay1 {
        SuinsDay1 {
            id: object::new(ctx),
            free_three_char_names: 0,
            free_four_char_names: 0,
            free_five_char_names: 0,
            is_activated: false,
            activation_expiry: option::none()
        }
    }

    #[test_only]
    public fun burn_for_testing(nft: SuinsDay1) {

        let SuinsDay1 {
            id,
            free_three_char_names: _,
            free_four_char_names: _,
            free_five_char_names: _,
            is_activated: _,
            activation_expiry: _,
        } = nft;

        object::delete(id);
    }

}
