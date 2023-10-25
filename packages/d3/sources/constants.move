// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

module d3::constants {

    use std::string::{String, utf8};

    /// The Metadata Key that shows the d3 eligibility.
    const D3_COMPATIBILITY_METADATA: vector<u8> = b"D3_COMPATIBLE";
    /// The ICANN lock metadata for a D3 compliant name that got locked by ICANN.
    const ICANN_LOCK: vector<u8> = b"ICANN_LOCK";

    public fun d3_compatibility_metadata_key(): String {
        utf8(D3_COMPATIBILITY_METADATA)
    }

    public fun icann_lock_metadata_key(): String {
        utf8(ICANN_LOCK)
    }
}
