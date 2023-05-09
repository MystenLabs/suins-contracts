/// Defines the `Domain` type and helper functions.
///
/// Domains are structured similar to their web2 counterpart and the rules
/// determining what a valid domain is can be found here:
/// https://en.wikipedia.org/wiki/Domain_name#Domain_name_syntax
module suins::domain {
    use std::string::{Self, String, utf8};
    use std::vector;

    const EInvalidDomain: u64 = 0;

    /// The maximum length of a full domain
    const MAX_DOMAIN_LENGTH: u64 = 200;
    /// The minimum length of an individual label in a domain.
    const MIN_LABEL_LENGTH: u64 = 3;
    /// The maximum length of an individual label in a domain.
    const MAX_LABEL_LENGTH: u64 = 63;

    /// Representation of a valid SuiNS `Domain`.
    struct Domain has copy, drop, store {
        /// Vector of labels that make up a domain.
        ///
        /// Labels are stored in reverse order such that the TLD is always in position `0`.
        /// e.g. domain "pay.name.sui" will be stored in the vector as ["sui", "name", "pay"].
        labels: vector<String>,
    }

    // Construct a `Domain` by parsing and validating the provided string
    public fun new(domain: String): Domain {
        assert!(string::length(&domain) <= MAX_DOMAIN_LENGTH, EInvalidDomain);

        let labels = split_by_dot(domain);
        validate_labels(&labels);
        vector::reverse(&mut labels);
        Domain {
            labels
        }
    }

    /// Converts a domain into a fully-qualified string representation.
    public fun to_string(self: &Domain): String {
        let dot = utf8(b".");
        let len = vector::length(&self.labels);
        let i = 0;
        let out = string::utf8(vector::empty());

        while (i < len) {
            let part = vector::borrow(&self.labels, (len - i) - 1);
            string::append(&mut out, *part);

            i = i + 1;
            if (i != len) {
                string::append(&mut out, dot);
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
        vector::borrow(&self.labels, level)
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
        vector::length(&self.labels)
    }

    public fun is_subdomain(self: &Domain, other: &Domain): bool {
        let len_self = number_of_levels(self);
        let len_other = number_of_levels(other);
        let index = 0;

        if (len_self > len_other) {
            return false
        };

        while (index < len_self && index < len_other) {
            if (label(self, index) != label(other, index)) {
                return false
            };
            
            index = index + 1;
        };

        true
    }

    fun validate_labels(labels: &vector<String>) {
        assert!(!vector::is_empty(labels), EInvalidDomain);

        let len = vector::length(labels);
        let index = 0;

        while (index < len) {
            let label = vector::borrow(labels, index);
            validate_label(label);
            index = index + 1;
        }
    }

    fun validate_label(label: &String) {
        let len = string::length(label);
        let label_bytes = string::bytes(label);
        let index = 0;

        assert!(len >= MIN_LABEL_LENGTH && len <= MAX_LABEL_LENGTH, EInvalidDomain);

        while (index < len) {
            let character = *vector::borrow(label_bytes, index);
             assert!(
                 (0x61 <= character && character <= 0x7A)                       // a-z
                     || (0x30 <= character && character <= 0x39)                // 0-9
                     || (character == 0x2D && index != 0 && index != len - 1),  // '-' not at beginning or end
                 EInvalidDomain
             );
            index = index + 1;
        };
    }

    /// Splits a string `s` by the character `.` into a vector of subslices, excluding the `.`
    fun split_by_dot(s: String): vector<String> {
        let dot = utf8(b".");
        let parts: vector<String> = vector[];
        while (!string::is_empty(&s)) {
            let index_of_next_dot = string::index_of(&s, &dot);
            let part = string::sub_string(&s, 0, index_of_next_dot);
            vector::push_back(&mut parts, part);

            let len = string::length(&s);
            let start_of_next_part = if (index_of_next_dot == len) {
                len
            } else {
                index_of_next_dot + 1
            };

            s = string::sub_string(&s, start_of_next_part, len);
        };

        parts
    }

    // === Tests ===

    // TODO: add more tests
    #[test_only]
    use sui::test_utils::assert_eq;

    fun round_trip(name: String) {
        let domain = new(name);
        assert_eq(name, to_string(&domain));
    }

    #[test]
    fun domain_simple() {
        let s = utf8(b"abc.123");
        let expected = vector[utf8(b"abc"), utf8(b"123")];
        vector::reverse(&mut expected);
        let actual = new(s);
        assert_eq(actual.labels, expected);
        round_trip(s);
        assert_eq(to_string(&actual), s);
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
}
