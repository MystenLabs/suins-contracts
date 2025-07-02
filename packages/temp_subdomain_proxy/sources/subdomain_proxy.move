// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// A `temporary` proxy used to proxy subdomain requests
/// because we can't use references in a PTB.
///
/// Module has no tests as it's a plain proxy for other function calls.
/// All validation happens on those functions.
///
/// This package will stop being used when we've implemented references in PTBs.
module suins_temp_subdomain_proxy::subdomain_proxy;

use std::string::String;
use sui::clock::Clock;
use suins::{controller, subdomain_registration::SubDomainRegistration, suins::SuiNS};
use suins_subdomains::subdomains;

public fun new(
    suins: &mut SuiNS,
    subdomain: &SubDomainRegistration,
    clock: &Clock,
    subdomain_name: String,
    expiration_timestamp_ms: u64,
    allow_creation: bool,
    allow_time_extension: bool,
    ctx: &mut TxContext,
): SubDomainRegistration {
    subdomains::new(
        suins,
        subdomain.nft(),
        clock,
        subdomain_name,
        expiration_timestamp_ms,
        allow_creation,
        allow_time_extension,
        ctx,
    )
}

public fun new_leaf(
    suins: &mut SuiNS,
    subdomain: &SubDomainRegistration,
    clock: &Clock,
    subdomain_name: String,
    target: address,
    ctx: &mut TxContext,
) {
    subdomains::new_leaf(
        suins,
        subdomain.nft(),
        clock,
        subdomain_name,
        target,
        ctx,
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
        subdomain.nft(),
        clock,
        subdomain_name,
    );
}

public fun edit_setup(
    suins: &mut SuiNS,
    parent: &SubDomainRegistration,
    clock: &Clock,
    subdomain_name: String,
    allow_creation: bool,
    allow_time_extension: bool,
) {
    subdomains::edit_setup(
        suins,
        parent.nft(),
        clock,
        subdomain_name,
        allow_creation,
        allow_time_extension,
    );
}

public fun set_target_address(
    suins: &mut SuiNS,
    subdomain: &SubDomainRegistration,
    new_target: Option<address>,
    clock: &Clock,
) {
    controller::set_target_address(
        suins,
        subdomain.nft(),
        new_target,
        clock,
    );
}

public fun set_user_data(
    suins: &mut SuiNS,
    subdomain: &SubDomainRegistration,
    key: String,
    value: String,
    clock: &Clock,
) {
    controller::set_user_data(
        suins,
        subdomain.nft(),
        key,
        value,
        clock,
    );
}

public fun set_user_data_leaf_subname(
    suins: &mut SuiNS,
    subdomain: &SubDomainRegistration,
    key: String,
    value: String,
    subdomain_name: String,
    clock: &Clock,
) {
    controller::set_user_data_leaf_subname(
        suins,
        subdomain.nft(),
        key,
        value,
        subdomain_name,
        clock,
    );
}

public fun unset_user_data(
    suins: &mut SuiNS,
    subdomain: &SubDomainRegistration,
    key: String,
    clock: &Clock,
) {
    controller::unset_user_data(
        suins,
        subdomain.nft(),
        key,
        clock,
    );
}

public fun unset_user_data_leaf_subname(
    suins: &mut SuiNS,
    subdomain: &SubDomainRegistration,
    key: String,
    subdomain_name: String,
    clock: &Clock,
) {
    controller::unset_user_data_leaf_subname(
        suins,
        subdomain.nft(),
        key,
        subdomain_name,
        clock,
    );
}
