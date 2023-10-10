// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

module subdomains::utils {
    use std::string::{Self, String, utf8};
    use std::vector;

    use suins::domain::{Self, Domain};

    /// the minimum size a subdomain label can have.
    const MIN_LABEL_SIZE: u64 = 3;
    /// the maximum depth a subdomain can have.
    const MAX_SUBDOMAIN_DEPTH: u8 = 8;

    /// tries to register a subdomain with a depth more than the one allowed.
    const EDepthOutOfLimit: u64 = 1;
    /// tires to register a subdomain with the wrong parent (level)
    const EInvalidParentDepth: u64 = 2;
    /// tries to register a subdomain with the wrong parent (based on name)
    const EInvalidParent: u64 = 3;
    /// tries to register a label of size less than 3.
    const EInvalidLabelSize: u64 = 4;
    /// tries to register a domain with an unsupported tld.
    const ENotSupportedTLD: u64 = 5;

    /// Derive the parent of a subdomain by the subdomain. 
    /// e.g. `subdomain.example.sui` -> `example.sui` 
    public fun parent_from_child(domain: &Domain): Domain {
        // skip last element, as this is the subdomain's digit.
        let i = domain::number_of_levels(domain) - 1;
        let domain_name: String = string::utf8(b"");
        let dot = utf8(b".");

        while(i > 0) {
            i = i - 1;
            string::append(&mut domain_name, *domain::label(domain, i));

            if(i > 0) string::append(&mut domain_name, dot);
        };

        domain::new(domain_name)
    }

    /// Check whether a `Domain` is a subdomain.
    public fun is_subdomain(domain: &Domain): bool {
        domain::number_of_levels(domain) > 2
    }

    /// Validates that the child name is a valid child for parent.
    public fun validate_subdomain(parent: &Domain, child: &Domain) {
        validate_subdomain_label(child);
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

    /// Validates that the TLD of the domain is supported for subdomains.
    /// In the beggining, only .sui names will be supported but we might 
    /// want to add support for others (or not allow).
    /// (E.g., with `.move` service, we might want to restrict how subdomains are created)
    public fun validate_tld(supported_tlds: &vector<String>, domain: &Domain) {
        let i=0;
        while(i < vector::length(supported_tlds)) {
            if(domain::tld(domain) == vector::borrow(supported_tlds, i)) {
                return
            };
            i = i + 1;
        };
        abort ENotSupportedTLD
    }

    /// Validate that the subdomain label (e.g. `sub` in `sub.example.sui`) is valid.
    fun validate_subdomain_label(domain: &Domain) {
        // our label is the last vector element, as labels are stored in reverse order.
        let label = domain::label(domain, domain::number_of_levels(domain) - 1);
        assert!(string::length(label) >= MIN_LABEL_SIZE, EInvalidLabelSize);
    }

}
