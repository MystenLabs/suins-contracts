module suins::validator {

    use std::vector;
    use std::string::{Self, String};

    const EInvalidLabel: u64 = 704;

    public fun validate_label(
        label: String,
        min_characters: u64,
        max_characters: u64
    ) {
        let label_bytes = string::bytes(&label);
        let len = vector::length(label_bytes);
        assert!(min_characters <= len && len <= max_characters, EInvalidLabel);
        let index = 0;

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
}
