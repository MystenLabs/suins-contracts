// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

module subdomains::utils {
    use std::string::{Self, String, utf8};
    use std::vector;

    use suins::domain::{Self, Domain};
    use suins::constants::{sui_tld};

    /// the minimum size a subdomain label can have.
    const MIN_LABEL_SIZE: u8 = 3;
    /// the maximum depth a subdomain can have.
    const MAX_SUBDOMAIN_DEPTH: u8 = 8;

    /// VecMap Keys for the NameRecord (that define whether a name can create or update)
    const ALLOW_CREATION: vector<u8> = b"ALLOW_CREATION";
    const ALLOW_TIME_EXTENSION: vector<u8> = b"ALLOW_TIME_EXTENSION";

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

    /// A Subdomain configuration object.
    /// Holds the allow-listed tlds, the max depth and the minimum label size.
    struct SubDomainConfig has copy, store, drop {
        allowed_tlds: vector<String>,
        max_depth: u8,
        min_label_size: u8
    }

    public fun default_config(): SubDomainConfig {
        SubDomainConfig {
            allowed_tlds: vector[sui_tld()],
            max_depth: MAX_SUBDOMAIN_DEPTH,
            min_label_size: MIN_LABEL_SIZE
        }
    }

    // Generates a custom config for Subdomains.
    public fun new_config(
        allowed_tlds: vector<String>,
        max_depth: u8,
        min_label_size: u8
    ): SubDomainConfig {
        SubDomainConfig {
            allowed_tlds,
            max_depth,
            min_label_size
        }
    }

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
    public fun validate_subdomain(parent: &Domain, child: &Domain, config: &SubDomainConfig) {
        validate_tld(child, config);
        validate_subdomain_label(child, config);
        assert!((domain::number_of_levels(child) as u8) <= config.max_depth, EDepthOutOfLimit);
    
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
    public fun validate_tld(domain: &Domain, config: &SubDomainConfig) {
        let i=0;
        while(i < vector::length(&config.allowed_tlds)) {
            if(domain::tld(domain) == vector::borrow(&config.allowed_tlds, i)) {
                return
            };
            i = i + 1;
        };
        abort ENotSupportedTLD
    }

    public fun allow_creation_key(): String{
        utf8(ALLOW_CREATION)
    }

    public fun allow_extension_key(): String{
        utf8(ALLOW_TIME_EXTENSION)
    }

    /// Validate that the subdomain label (e.g. `sub` in `sub.example.sui`) is valid.
    fun validate_subdomain_label(domain: &Domain, config: &SubDomainConfig) {
        // our label is the last vector element, as labels are stored in reverse order.
        let label = domain::label(domain, domain::number_of_levels(domain) - 1);
        assert!(string::length(label) >= (config.min_label_size as u64), EInvalidLabelSize);
    }

}
