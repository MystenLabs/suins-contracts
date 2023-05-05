/// Unifies previously defined modules: validator and converter.
/// Holds the neutral logic for validation and conversion of strings.
///
/// This module is free from any non-framework dependencies.
module suins::string_utils {
    use std::ascii;
    use std::vector;
    use std::string::{Self, String};

    /// Label did not pass validation.
    const EInvalidLabel: u64 = 0;
    /// Emitted when the input string is not a valid number.
    const EInvalidNumber: u64 = 1;

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
                (0x61 <= character && character <= 0x7A)            // a-z
                    || (0x30 <= character && character <= 0x39)     // 0-9
                    || (character == 0x2D && index != 0 && index != len - 1),
                EInvalidLabel
            );
            index = index + 1;
            continue
        }
    }

    /// Check whether a given string is a valid ASCII string.
    public fun is_valid_ascii(str: String): bool {
        let ascii = string::to_ascii(str);
        ascii::all_characters_printable(&ascii)
    }
}
