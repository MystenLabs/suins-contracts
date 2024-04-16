// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// A renewal module for the SuiNS app.
/// This module allows users to renew their domains.
/// 
/// The renewal is capped at 5 years.
module renewal::renew {
    use sui::{coin::{Self, Coin}, clock::Clock, sui::SUI};

    use suins::{
        constants, 
        domain::Domain, 
        registry::Registry, 
        suins::{Self, SuiNS, AdminCap}, 
        config::{Self, Config}, 
        suins_registration::SuinsRegistration
    };

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
    public struct Renew has drop {}

    /// An event to help track financial transactions
    public struct NameRenewed has copy, drop {
        domain: Domain,
        amount: u64
    }
    
    /// The renewal's package configuration.
    public struct RenewalConfig has store, drop {
        config: Config
    }

    /// Allows admin to initalize the custom pricing config for the renewal module.
    /// We're wrapping initial `Config` because we want to add custom pricing for renewals,
    /// and we can only have 1 config of each type in the suins app.
    /// We still set this up by using the default config functionality from suins package.
    /// The `public_key` passed in the `Config` can be a random u8 array with length 33.
    public fun setup(cap: &AdminCap, suins: &mut SuiNS, config: Config) {
        suins::add_config<RenewalConfig>(cap, suins, RenewalConfig { config });
    }

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
        let domain =  nft.domain();
        // check if the name is valid, for public registration
        // Also checks if the domain is not a subdomain, validates label lengths, TLD.
        config::assert_valid_user_registerable_domain(&domain);

        // check that the payment is correct for the specified name.
        validate_payment(suins, &payment, &domain, no_years);

        // Get registry (also checks that app is authorized) + start validating.
        let registry = suins::app_registry_mut<Renew, Registry>(Renew {}, suins);

        // Calculate target expiration. Aborts if expiration or selected years are invalid.
        let target_expiration = target_expiration(registry, nft, domain, clock, no_years);

        // set the expiration of the NFT + the registry's name record. 
        registry.set_expiration_timestamp_ms(nft, domain, target_expiration);

        sui::event::emit(NameRenewed { domain, amount: coin::value(&payment) });
        suins::app_add_balance(Renew {}, suins, coin::into_balance(payment));
    }

    /// Calculate the target expiration for a domain, 
    /// or abort if the domain or the expiration setup is invalid.
    fun target_expiration(
        registry: &Registry,
        nft: &SuinsRegistration,
        domain: Domain,
        clock: &Clock,
        no_years: u8,
    ): u64 {
        let name_record_option = registry.lookup(domain);
        // validate that the name_record still exists in the registry.
        assert!(option::is_some(&name_record_option), ERecordNotFound);

        let name_record = option::destroy_some(name_record_option);

        // Validate that the name has not expired. If it has, we can only re-purchase (and that might involve different pricing).
        assert!(!name_record.has_expired_past_grace_period(clock), ERecordExpired);

        // validate that the supplied NFT ID matches the NFT ID of the registry.
        assert!(name_record.nft_id() == object::id(nft), ERecordNftIDMismatch);

        // Validate that the no_years supplied makes sense. (1-5).
        assert!(0 < no_years && no_years <= 5, EInvalidYearsArgument);

        // calcualate target expiration!
        let target_expiration = name_record.expiration_timestamp_ms() + (no_years as u64) * constants::year_ms();

        // validate that the target expiration is not more than 6 years in the future.
        assert!(target_expiration < clock.timestamp_ms() + (constants::year_ms() * 6), EMoreThanSixYears);

        target_expiration
    }

    /// Validates that the payment Coin is correct for the domain + number of years
    fun validate_payment(suins: &SuiNS, payment: &Coin<SUI>, domain: &Domain, no_years: u8){
        let config = suins.get_config<RenewalConfig>();
        let label = domain.sld();
        let price = config.config.calculate_price((label.length() as u8), no_years);
        assert!(payment.value() == price, EIncorrectAmount);
    }
}
