// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// A `temporary` proxy used to proxy subdomain requests
/// because we can't use references in a PTB.
/// 
/// Module has no tests as it's a plain proxy for other function calls. 
/// All validation happens on those functions.
/// 
/// This package will stop being used when we've implemented references in PTBs.
module temp_subdomain_proxy::subdomain_proxy {
    use std::string::String;

    use sui::tx_context::TxContext;
    use sui::clock::Clock;

    use suins::suins::SuiNS;
    use suins::subdomain_registration::{Self, SubDomainRegistration};
    
    use subdomains::subdomains;
    use utils::direct_setup;

    public fun create_subdomain(
        suins: &mut SuiNS,
        subdomain: &SubDomainRegistration,
        clock: &Clock,
        subdomain_name: String,
        expiration_timestamp_ms: u64,
        allow_creation: bool,
        allow_time_extension: bool,
        ctx: &mut TxContext
    ): SubDomainRegistration {
        subdomains::create(
            suins,
            subdomain_registration::borrow(subdomain),
            clock,
            subdomain_name,
            expiration_timestamp_ms,
            allow_creation,
            allow_time_extension,
            ctx
        )
    }

    public fun create_leaf(
        suins: &mut SuiNS,
        subdomain: &SubDomainRegistration,
        clock: &Clock,
        subdomain_name: String,
        target: address,
        ctx: &mut TxContext
    ){
        subdomains::create_leaf(
            suins,
            subdomain_registration::borrow(subdomain),
            clock,
            subdomain_name,
            target,
            ctx
        );
    }
    
    public fun remove_leaf(
        suins: &mut SuiNS,
        subdomain: &SubDomainRegistration,
        clock: &Clock,
        subdomain_name: String,
    ) {
        subdomains::remove_leaf(
            suins,
            subdomain_registration::borrow(subdomain),
            clock,
            subdomain_name,
        );
    }

    public fun set_target_address(
        suins: &mut SuiNS,
        subdomain: &SubDomainRegistration,
        new_target: address,
        clock: &Clock,
    ) {
        direct_setup::set_target_address(
            suins,
            subdomain_registration::borrow(subdomain),
            new_target,
            clock,
        );
    }
    
}
