// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

module subdomains::utils {

    use suins::domain::{Self, Domain};

    const MAX_SUBDOMAIN_DEPTH: u8 = 8;

    // tries to register a subdomain with a depth more than the one allowed.
    const EDepthOutOfLimit: u64 = 1;
    // tires to register a subdomain with the wrong parent (level)
    const EInvalidParentDepth: u64 = 2;
    // tries to register a subdomain with the wrong parent (based on name)
    const EInvalidParent: u64 = 3;


    /// Check whether a `Domain` is a subdomain.
    public fun is_subdomain(domain: &Domain): bool {
        domain::number_of_levels(domain) > 2
    }

    // validates that the child name is a valid child for parent.
    public fun validate_subdomain(parent: &Domain, child: &Domain) {
        assert!((domain::number_of_levels(child) as u8) <= MAX_SUBDOMAIN_DEPTH, EDepthOutOfLimit);
    
        // validate that the child has 1 more label vs the parent.
        assert!((domain::number_of_levels(parent) + 1) == domain::number_of_levels(child), EInvalidParentDepth);

        // we start at the parent's length, and we work our way down to tld.
        let i = domain::number_of_levels(parent);

        while(i > 0) {
            // we start at domain::length() so we skip the subdomain's label.
            i = i - 1;
            assert!(domain::label(parent, i) == domain::label(child, i), EInvalidParent);
        }
    }

}
