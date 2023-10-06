// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

module subdomains::unit_tests {
    use std::string::{utf8};
    use suins::domain::{Self, new as new_domain};
    use subdomains::utils::{validate_subdomain, parent_from_child};

    // === Validity of subdomain | parent lengths (based on string) ===
    #[test]
    fun test_parent_relationships() {
        validate_subdomain(&new_domain(utf8(b"example.sui")), &new_domain(utf8(b"sub.example.sui")));
        validate_subdomain(&new_domain(utf8(b"sub.example.sui")), &new_domain(utf8(b"sub.sub.example.sui")));
        validate_subdomain(&new_domain(utf8(b"sub.sub.example.sui")), &new_domain(utf8(b"sub.sub.sub.example.sui")));
        validate_subdomain(&new_domain(utf8(b"sub.sub.sub.sub.sub.example.sui")), &new_domain(utf8(b"sub.sub.sub.sub.sub.sub.example.sui")));
    }

    #[test, expected_failure(abort_code=subdomains::utils::EDepthOutOfLimit)]
    fun test_too_large_subdomain_failure() {
        validate_subdomain(&new_domain(utf8(b"example.sui")), &new_domain(utf8(b"sub.sub.sub.sub.sub.sub.sub.example.sui")));
    }

    #[test, expected_failure(abort_code=subdomains::utils::EInvalidParentDepth)]
    fun test_invalid_parent_length_failure() {
        validate_subdomain(&new_domain(utf8(b"example.sui")), &new_domain(utf8(b"sub.sub.example.sui")));
    }

    #[test, expected_failure(abort_code=subdomains::utils::EInvalidParentDepth)]
    fun test_invalid_parent_smaller_length_failure() {
        validate_subdomain(&new_domain(utf8(b"sub.sub.example.sui")), &new_domain(utf8(b"sub.example.sui")));
    }

    #[test, expected_failure(abort_code=subdomains::utils::EInvalidParent)]
    fun test_invalid_parent_failure() {
        validate_subdomain(&new_domain(utf8(b"test.example.sui")), &new_domain(utf8(b"sub.sub.example.sui")));
    }

    #[test, expected_failure(abort_code=subdomains::utils::EInvalidParent)]
    fun test_invalid_parent_tld_failure() {
        validate_subdomain(&new_domain(utf8(b"sub.example.move")), &new_domain(utf8(b"sub.sub.example.sui")));
    }
    #[test, expected_failure(abort_code=subdomains::utils::EInvalidParent)]
    fun test_invalid_parent_sld_failure() {
        validate_subdomain(&new_domain(utf8(b"sub.exampl.sui")), &new_domain(utf8(b"sub.sub.example.sui")));
    }
    
    #[test, expected_failure(abort_code=subdomains::utils::EInvalidLabelSize)]
    fun test_invalid_child_label_size_failure() {
        validate_subdomain(&new_domain(utf8(b"sub.exampl.sui")), &new_domain(utf8(b"ob.example.sui")));
    }

    #[test]
    fun derive_parent_from_child(){
        let parent = parent_from_child(&new_domain(utf8(b"sub.example.sui")));
        assert!(domain::to_string(&parent) == utf8(b"example.sui"), 0);

        let parent = parent_from_child(&new_domain(utf8(b"sub.sub.sub.sub.sub.sub.example.sui")));
        assert!(domain::to_string(&parent) == utf8(b"sub.sub.sub.sub.sub.example.sui"), 0);

    }
}
