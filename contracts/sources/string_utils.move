/// Unifies previously defined modules: validator and converter.
/// Holds the neutral logic for validation and conversion of strings.
module suins::string_utils {
    use std::ascii;
    use std::vector;
    use std::string::{Self, String};

    /// TODO: Are we sure about error codes here?
    const EInvalidLabel: u64 = 704;
    /// Emitted when the input string is not a valid number.
    const EInvalidNumber: u64 = 601;

    /// Validate a given label, make sure that the length of the input string
    /// fits into the given range and that the characters are valid.
    ///
    /// Allowed characters are: a-z, 0-9 and hyphen (-).
    /// The ASCII code ranges are: 0x61-0x7A, 0x30-0x39, 0x2D
    public fun validate_label(
        label: String,
        min_characters: u8,
        max_characters: u8
    ) {
        let label_bytes = string::bytes(&label);
        let len = vector::length(label_bytes);
        let index = 0;

        assert!(len < 255, EInvalidLabel);
        assert!(min_characters <= (len as u8) && (len as u8) <= max_characters, EInvalidLabel);

        while (index < len) {
            let character = *vector::borrow(label_bytes, index);
            assert!(
                (0x61 <= character && character <= 0x7A)                           // a-z
                    || (0x30 <= character && character <= 0x39)                    // 0-9
                    || (character == 0x2D && index != 0 && index != len - 1),
                EInvalidLabel
            );
            index = index + 1;
            continue
        }
    }

    /// Read a number from a given string (eg b"123").
    /// Aborts if a character is met (not in the range `0-9` - `0x30-0x39`).
    public fun string_to_number(str: String): u64 {
        let bytes = string::bytes(&str);
        // count from 1 because Move doesn't have negative number atm
        let index = vector::length(bytes);
        let result: u64 = 0;
        let base = 1;

        while (index > 0) {
            let byte = *vector::borrow(bytes, index - 1);
            assert!(byte >= 0x30 && byte <= 0x39, EInvalidNumber); // 0-9
            result = result + ((byte as u64) - 0x30) * base;
            // avoid overflow if input is MAX_U64
            if (index != 1) base = base * 10;
            index = index - 1;
        };

        result
    }

    /// Check whether a given string is a valid ASCII string.
    public fun is_valid_ascii(str: String): bool {
        let ascii = string::to_ascii(str);
        ascii::all_characters_printable(&ascii)
    }
}
