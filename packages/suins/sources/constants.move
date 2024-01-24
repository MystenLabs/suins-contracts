// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// Module to wrap all constants used across the project. A sigleton and not
/// meant to be modified (only extended).
///
/// This module is free from any non-framework dependencies and serves as a
/// single place of storing constants and proving convenient APIs for reading.
module suins::constants {
    use std::string::{utf8, String};

    /// Max value for basis points.
    const MAX_BPS: u16 = 10000;
    /// The amount of MIST in 1 SUI.
    const MIST_PER_SUI: u64 = 1_000_000_000;
    /// The minimum length of a domain name.
    const MIN_DOMAIN_LENGTH: u8 = 3;
    /// The maximum length of a domain name.
    const MAX_DOMAIN_LENGTH: u8 = 63;
    /// Top level domain for SUI.
    const SUI_TLD: vector<u8> = b"sui";
    /// The amount of milliseconds in a year.
    const YEAR_MS: u64 = 365 * 24 * 60 * 60 * 1000;
    /// Default value for the image_url; IPFS hash.
    const DEFAULT_IMAGE: vector<u8> = b"QmaLFg4tQYansFpyRqmDfABdkUVy66dHtpnkH15v1LPzcY";
    /// 30 day Grace period in milliseconds.
    const GRACE_PERIOD_MS: u64 = 30 * 24 * 60 * 60 * 1000;

    /// A leaf record doesn't expire. Expiration is retrieved by the parent's expiration.
    const LEAF_EXPIRATION_TIMESTAMP: u64 = 0;

    /// Subdomain constants
    /// 
    /// These constants are the core of the subdomain functionality.
    /// Even if we decide to change the subdomain module, these can
    /// be re-used. They're added as metadata on NameRecord.
    /// 
    /// Whether a parent name can create child names. (name -> subdomain)
    const ALLOW_CREATION: vector<u8> = b"S_AC";
    /// Whether a child-name can auto-renew (if the parent hasn't changed).
    const ALLOW_TIME_EXTENSION: vector<u8> = b"S_ATE";

    // === Public functions ===

    /// Top level domain for SUI as a String.
    public fun sui_tld(): String { utf8(SUI_TLD) }
    /// Default value for the image_url.
    public fun default_image(): String { utf8(DEFAULT_IMAGE) }
    /// The amount of MIST in 1 SUI.
    public fun mist_per_sui(): u64 { MIST_PER_SUI }
    /// The minimum length of a domain name.
    public fun min_domain_length(): u8 { MIN_DOMAIN_LENGTH }
    /// The maximum length of a domain name.
    public fun max_domain_length(): u8 { MAX_DOMAIN_LENGTH }
    /// Maximum value for basis points.
    public fun max_bps(): u16 { MAX_BPS }
    /// The amount of milliseconds in a year.
    public fun year_ms(): u64 { YEAR_MS }
    /// Grace period in milliseconds after which the domain expires.
    public fun grace_period_ms(): u64 { GRACE_PERIOD_MS }

    /// Subdomain constants 
    /// The NameRecord key that a subdomain can create child names.
    public fun subdomain_allow_creation_key(): String{ utf8(ALLOW_CREATION) }
    /// The NameRecord key that a subdomain can self-renew.
    public fun subdomain_allow_extension_key(): String{ utf8(ALLOW_TIME_EXTENSION) }
    /// A getter for a leaf name record's expiration timestamp.
    public fun leaf_expiration_timestamp(): u64 { LEAF_EXPIRATION_TIMESTAMP }
}
