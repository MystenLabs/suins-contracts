// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// A simple BOGO that allows a `DayOne` holder to trade 
/// a domain registered before the expiration day we set
/// with another one of the same size.
/// 
module day_one::bogo {
    use std::string::{Self, String};

    use sui::clock::{Clock};
    use sui::tx_context::{TxContext};
    use sui::dynamic_field::{Self as df};

    use suins::config;
    use suins::domain::{Self, Domain};
    use suins::suins::{Self, SuiNS};
    use suins::suins_registration::{Self as nft, SuinsRegistration};
    use suins::registry::{Self, Registry};

    use day_one::day_one::{Self, DayOne};

    /// Authorization token for the BOGO app.
    /// Used to authorize the app to claim free names by using a DayOne object.
    struct BogoApp has drop {}

    /// Dynamic field key which shows that the `SuinsRegistration` object was
    /// minted from a Day1 promotion.
    struct UsedInDayOnePromo has copy, store, drop { }

    // This will define if a domain name was bought in an auction.
    // The only way to understand that, is to check that the expiration day is 
    // less than last_day of auctions + 1 year.
    const LAST_VALID_EXPIRATION_DATE: u64 = 1721499031 * 1000; // Saturday, 20 July 2024 18:10:31 UTC

    // Default registration duration is 1 year.
    const DEFAULT_DURATION: u8 = 1;

    // This domain has already been used to mint a free domain.
    const EDomainAlreadyUsed: u64 = 0;
    // Domain was not bought in an auction.
    const ENotPurchasedInAuction: u64 = 1;
    // Domain user tries to purchase has a size missmatch. Only applicable for 3 + 4 length domains.
    const ESizeMissMatch: u64 = 2;

    /// We have a requirement that this promotion will run for a specified amount of time (30 Days).
    /// I believe it's better to deauthorize the app when we do not want to have it any more,
    /// instead of hard-coding the limits here.
    public fun claim(
        day_one_nft: &mut DayOne,
        suins: &mut SuiNS,
        domain_nft: &mut SuinsRegistration,
        domain_name: String,
        clock: &Clock,
        ctx: &mut TxContext,
    ): SuinsRegistration {
        // verify we can register names using this app.
        suins::assert_app_is_authorized<BogoApp>(suins);

        // check that domain_nft hasn't been already used in this deal.
        assert!(!used_in_promo(domain_nft), EDomainAlreadyUsed);

        // Verify that the domain was bought in an auction.
        // We understand if a domain was bought in an auction if the expiry date is less than the last day of auction + 1 year. 
        assert!(nft::expiration_timestamp_ms(domain_nft) <= LAST_VALID_EXPIRATION_DATE, ENotPurchasedInAuction);

        // generate a domain out of the input string.
        let new_domain = domain::new(domain_name);
        let new_domain_size = domain_length(&new_domain);

        let domain_size = domain_length(&nft::domain(domain_nft));

        // make sure the domain is valid.
        config::assert_valid_user_registerable_domain(&new_domain);

        // if size < 5, we need to make sure we're getting a domain name of the same size.
        assert!(!((domain_size < 5 || new_domain_size < 5) && domain_size != new_domain_size), ESizeMissMatch);

        // activate the day_one_nft if it's not activated.
        // This will grant it access to future promotions.
        if(!day_one::is_active(day_one_nft)) day_one::activate(day_one_nft);

        let registry = suins::app_registry_mut<BogoApp, Registry>(BogoApp {}, suins);
        let nft = registry::add_record(registry, new_domain, DEFAULT_DURATION, clock, ctx);

        // mark both the new and the current domain presented as used, so that they can't 
        // be redeemed twice in this deal.
        mark_domain_as_used(domain_nft);
        mark_domain_as_used(&mut nft);

        nft
    }

    // Returns the size of a domain name. (e.g test.sui -> 4)
    fun domain_length(domain: &Domain): u64{
        string::length(domain::sld(domain))
    }

    // Check if the domain has been minted for free from this bogo promo.
    public fun used_in_promo(domain_nft: &SuinsRegistration): bool {
        df::exists_(nft::uid(domain_nft), UsedInDayOnePromo {})
    }

    public fun last_valid_expiration(): u64 {
        LAST_VALID_EXPIRATION_DATE
    }

     /// Attaches a DF that marks a domain as `used` in another day 1 object.
    fun mark_domain_as_used(domain_nft: &mut SuinsRegistration) {
        df::add(nft::uid_mut(domain_nft), UsedInDayOnePromo {}, true)
    }

}
