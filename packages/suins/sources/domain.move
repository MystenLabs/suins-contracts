// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// Defines the `Domain` type and helper functions.
///
/// Domains are structured similar to their web2 counterpart and the rules
/// determining what a valid domain is can be found here:
/// https://en.wikipedia.org/wiki/Domain_name#Domain_name_syntax
module suins::domain {
    use std::string::{Self, String, utf8};

    const EInvalidDomain: u64 = 0;

    /// The maximum length of a full domain
    const MAX_DOMAIN_LENGTH: u64 = 235;
    /// The minimum length of an individual label in a domain.
    const MIN_LABEL_LENGTH: u64 = 1;
    /// The maximum length of an individual label in a domain.
    const MAX_LABEL_LENGTH: u64 = 63;

    /// Representation of a valid SuiNS `Domain`.
    public struct Domain has copy, drop, store {
        /// Vector of labels that make up a domain.
        ///
        /// Labels are stored in reverse order such that the TLD is always in position `0`.
        /// e.g. domain "pay.name.sui" will be stored in the vector as ["sui", "name", "pay"].
        labels: vector<String>,
    }

    // Construct a `Domain` by parsing and validating the provided string
    public fun new(domain: String): Domain {
        assert!(domain.length() <= MAX_DOMAIN_LENGTH, EInvalidDomain);

        let mut labels = split_by_dot(domain);
        validate_labels(&labels);
        labels.reverse();
        Domain {
            labels
        }
    }

    /// Converts a domain into a fully-qualified string representation.
    public fun to_string(self: &Domain): String {
        let dot = utf8(b".");
        let len = self.labels.length();
        let mut i = 0;
        let mut out = string::utf8(vector::empty());

        while (i < len) {
            let part = &self.labels[(len - i) - 1];
            out.append(*part);

            i = i + 1;
            if (i != len) {
                out.append(dot);
            }
        };

        out
    }

    /// Returns the `label` in a domain specified by `level`.
    ///
    /// Given the domain "pay.name.sui" the individual labels have the following levels:
    /// - "pay" - `2`
    /// - "name" - `1`
    /// - "sui" - `0`
    ///
    /// This means that the TLD will always be at level `0`.
    public fun label(self: &Domain, level: u64): &String {
        &self.labels[level]
    }

    /// Returns the TLD (Top-Level Domain) of a `Domain`.
    ///
    /// "name.sui" -> "sui"
    public fun tld(self: &Domain): &String {
        label(self, 0)
    }

    /// Returns the SLD (Second-Level Domain) of a `Domain`.
    ///
    /// "name.sui" -> "sui"
    public fun sld(self: &Domain): &String {
        label(self, 1)
    }

    public fun number_of_levels(self: &Domain): u64 {
        self.labels.length()
    }

    public fun is_subdomain(domain: &Domain): bool {
        number_of_levels(domain) > 2
    }

    /// Derive the parent of a subdomain. 
    /// e.g. `subdomain.example.sui` -> `example.sui` 
    public fun parent(domain: &Domain): Domain {
        let mut labels = domain.labels;
        // we pop the last element and construct the parent from the remaining labels.
        labels.pop_back();

        Domain {
            labels
        }
    }
    
    /// Checks if `parent` domain is a valid parent for `child`.
    public fun is_parent_of(parent: &Domain, child: &Domain): bool {
        number_of_levels(parent) < number_of_levels(child) && 
        &parent(child).labels == &parent.labels
    }

    fun validate_labels(labels: &vector<String>) {
        assert!(!labels.is_empty(), EInvalidDomain);

        let len = labels.length();
        let mut index = 0;

        while (index < len) {
            let label = &labels[index];
            assert!(is_valid_label(label), EInvalidDomain);
            index = index + 1;
        }
    }

    fun is_valid_label(label: &String): bool {
        let len = label.length();
        let label_bytes = label.bytes();
        let mut index = 0;

        if (!(len >= MIN_LABEL_LENGTH && len <= MAX_LABEL_LENGTH)) {
            return false
        };

        while (index < len) {
            let character = label_bytes[index];
            let is_valid_character =
                (0x61 <= character && character <= 0x7A)                   // a-z
                || (0x30 <= character && character <= 0x39)                // 0-9
                || (character == 0x2D && index != 0 && index != len - 1);  // '-' not at beginning or end

            if (!is_valid_character) {
                return false
            };

            index = index + 1;
        };

        true
    }

    /// Splits a string `s` by the character `.` into a vector of subslices, excluding the `.`
    fun split_by_dot(mut s: String): vector<String> {
        let dot = utf8(b".");
        let mut parts: vector<String> = vector[];
        while (!s.is_empty()) {
            let index_of_next_dot = s.index_of(&dot);
            let part = s.sub_string(0, index_of_next_dot);
            parts.push_back(part);

            let len = s.length();
            let start_of_next_part = if (index_of_next_dot == len) {
                len
            } else {
                index_of_next_dot + 1
            };

            s = s.sub_string(start_of_next_part, len);
        };

        parts
    }

    // === Tests ===

    #[test_only]
    use sui::test_utils::assert_eq;

    #[test_only]
    fun test_valid_domain(name: vector<u8>, expected_labels: vector<vector<u8>>) {
        let name = utf8(name);
        let domain = new(name);
        let expected_labels = prep_expected_labels(expected_labels);
        assert_eq(domain.labels, expected_labels);
        assert_eq(name, to_string(&domain));

        // Validate `domain::label` function
        let len = vector::length(&expected_labels);
        let mut index = 0;

        while (index < len) {
            let label = &expected_labels[index];
            assert_eq(*label, *label(&domain, index));
            index = index + 1;
        }
    }

    #[test_only]
    fun prep_expected_labels(mut labels: vector<vector<u8>>): vector<String> {
        let mut out = vector[];
        while (!labels.is_empty()) {
            let label = labels.pop_back();
            out.push_back(utf8(label));
        };
        out
    }

    #[test]
    fun valid_domains() {
        test_valid_domain(b"abc.123", vector[b"abc", b"123"]);
        test_valid_domain(b"suins.sui", vector[b"suins", b"sui"]);
        test_valid_domain(b"1.2.3.4.5.6.7.8.9.0.sui", vector[b"1", b"2", b"3", b"4", b"5", b"6", b"7", b"8", b"9", b"0", b"sui"]);
        test_valid_domain(b"pay.mysten.sui", vector[b"pay", b"mysten", b"sui"]);
        test_valid_domain(b"abcdefghijklmnopqrstuvxyz0123456789.move", vector[b"abcdefghijklmnopqrstuvxyz0123456789", b"move"]);
        test_valid_domain(b"a----b.sui", vector[b"a----b", b"sui"]);
    }

    #[test_only]
    fun expect_valid_label(label: vector<u8>, is_valid: bool) {
        let label = utf8(label);
        assert_eq(is_valid_label(&label), is_valid);
    }

    #[test]
    fun test_valid_labels() {
        expect_valid_label(b"", false);
        expect_valid_label(b"-", false);
        expect_valid_label(b"-aaa", false);
        expect_valid_label(b"aaa-", false);
        expect_valid_label(b"a-a", true);
        expect_valid_label(b"abcdefghijklmnopqrstuvxyz-0123456789", true);
    }

    #[test_only]
    fun expect_is_subdomain(domain: vector<u8>, subdomain: vector<u8>, expected: bool) {
        let domain = new(utf8(domain));
        let subdomain = new(utf8(subdomain));
        assert_eq(is_parent_of(&domain, &subdomain), expected);
    }

    #[test]
    fun test_is_subdomain() {
        expect_is_subdomain(b"mysten.sui", b"pay.mysten.sui", true);
        expect_is_subdomain(b"pay.mysten.sui", b"mysten.sui", false);
        expect_is_subdomain(b"mysten.sui", b"pay.move.sui", false);
    }

    #[test]
    fun split_simple() {
        let s = utf8(b"a.b");
        let expected = vector[utf8(b"a"), utf8(b"b")];
        let actual = split_by_dot(s);
        assert_eq(actual, expected);
    }

    #[test]
    fun split_simple_2() {
        let s = utf8(b"pay.narwhal.sui");
        let expected = vector[utf8(b"pay"), utf8(b"narwhal"), utf8(b"sui")];
        let actual = split_by_dot(s);
        assert_eq(actual, expected);
    }

    #[test]
    fun split_string_with_no_dots() {
        let s = utf8(b"abc");
        let expected = vector[utf8(b"abc")];
        let actual = split_by_dot(s);
        assert_eq(actual, expected);
    }

    #[test]
    fun split_string_surrounded_by_dots() {
        let s = utf8(b".a.");
        let expected = vector[utf8(vector::empty()), utf8(b"a")];
        let actual = split_by_dot(s);
        assert_eq(actual, expected);
    }

    #[test]
    fun split_empty_string() {
        let s = utf8(vector::empty());
        let expected = vector[];
        let actual = split_by_dot(s);
        assert_eq(actual, expected);
    }

    #[test]
    fun split_one_dot() {
        let s = utf8(b".");
        let expected = vector[utf8(vector::empty())];
        let actual = split_by_dot(s);
        assert_eq(actual, expected);
    }

    #[test]
    fun split_two_dots() {
        let s = utf8(b"..");
        let expected = vector[utf8(vector::empty()), utf8(vector::empty())];
        let actual = split_by_dot(s);
        assert_eq(actual, expected);
    }

    #[test]
    fun split_three_dots() {
        let s = utf8(b"...");
        let expected = vector[utf8(vector::empty()), utf8(vector::empty()), utf8(vector::empty())];
        let actual = split_by_dot(s);
        assert_eq(actual, expected);
    }

    #[test]
    fun derive_parent(){
        let parent = new(utf8(b"parent.sui"));
        let child = new(utf8(b"child.parent.sui"));

        assert!(parent(&child) == parent, 0);
    }
}
