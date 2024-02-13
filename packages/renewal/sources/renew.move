// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// A renewal module for the SuiNS app.
/// This module allows users to renew their domains.
/// 
/// The renewal is capped at 5 years.
module renewal::renew {
    use std::string::{Self};
    use std::option;

    use sui::coin::{Self, Coin};

    use sui::clock::{Self, Clock};
    use sui::sui::SUI;
    use sui::object;

    use suins::constants;
    use suins::domain::{Self, Domain};
    use suins::registry::{Self, Registry};
    use suins::suins::{Self, SuiNS};
    use suins::config::{Self, Config};
    use suins::suins_registration::{Self as nft, SuinsRegistration};
    use suins::name_record;

    /// Number of years passed is not within [1-5] interval.
    const EInvalidYearsArgument: u64 = 0;
    /// The payment does not match the price for the domain.
    const EIncorrectAmount: u64 = 1;
    /// Tries to renew a name more than 6 years in the future.
    /// Our renewal is capped at 5 years.
    const EMoreThanSixYears: u64 = 2;
    // Tries to renew a name that does not exist in the registry (expired + burned?!).
    const ERecordNotFound: u64 = 3;
    // Tries to renew a name with an NFT that doesn't match the NFT ID of the registry.
    const ERecordNftIDMismatch: u64 = 4;
    // Tries to renew a name that has expired.
    const ERecordExpired: u64 = 5;

    /// Authorization token for the app.
    struct Renew has drop {}

    // Allows renewals of names.
    //
    // Makes sure that:
    // - the domain is registered & valid
    // - the domain TLD is .sui
    // - the domain is not a subdomain
    // - number of years is within [1-5] interval
    public fun renew(
        suins: &mut SuiNS,
        nft: &mut SuinsRegistration,
        no_years: u8,
        payment: Coin<SUI>,
        clock: &Clock
    ) {
        // authorization occurs inside the call.
        let domain =  nft::domain(nft);
        // check if the name is valid, for public registration
        // Also checks if the domain is not a subdomain, validates label lengths, TLD.
        config::assert_valid_user_registerable_domain(&domain);

        // check that the payment is correct for the specified name.
        validate_payment(suins, &payment, &domain, no_years);

        // Get registry (also checks that app is authorized) + start validating.
        let registry = suins::app_registry_mut<Renew, Registry>(Renew {}, suins);

        // Calculate target expiration. Aborts if expiration or selected years are invalid.
        let target_expiration = target_expiration_or_abort(registry, nft, domain, clock, no_years);

        // set the expiration of the NFT + the registry's name record. 
        registry::set_expiration_timestamp_ms(registry, nft, domain, target_expiration);
        suins::app_add_balance(Renew {}, suins, coin::into_balance(payment));
    }

    fun target_expiration_or_abort(
        registry: &Registry,
        nft: &SuinsRegistration,
        domain: Domain,
        clock: &Clock,
        no_years: u8,
    ): u64 {
        let name_record_option = registry::lookup(registry, domain);
        // validate that the name_record still exists in the registry.
        assert!(option::is_some(&name_record_option), ERecordNotFound);

        let name_record = option::destroy_some(name_record_option);

        // validate that the name has not expired.
        assert!(!name_record::has_expired_past_grace_period(&name_record, clock), ERecordExpired);

        // validate that the supplied NFT ID matches the NFT ID of the registry.
        assert!(name_record::nft_id(&name_record) == object::id(nft), ERecordNftIDMismatch);

        // Validate that the no_years supplied makes sense. (1-5).
        assert!(0 < no_years && no_years <= 5, EInvalidYearsArgument);

        // calcualate target expiration!
        let target_expiration = name_record::expiration_timestamp_ms(&name_record) + (no_years as u64) * constants::year_ms();

        // validate that the target expiration is not more than 6 years in the future.
        assert!(target_expiration < clock::timestamp_ms(clock) + (constants::year_ms() * 6), EMoreThanSixYears);

        target_expiration
    }

    fun validate_payment(suins: &SuiNS,payment: &Coin<SUI>, domain: &Domain, no_years: u8){
        let config = suins::get_config<Config>(suins);
        let label = domain::sld(domain);
        let price = config::calculate_price(config, (string::length(label) as u8), no_years);
        assert!(coin::value(payment) == price, EIncorrectAmount);
    }
}
