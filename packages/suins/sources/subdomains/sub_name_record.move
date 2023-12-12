// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

// A `SubNameRecord` entry, which is specific to subdomains and how we handle them in namespaces.
module suins::sub_name_record {
    
    use suins::name_record::NameRecord;
    
    /// A subname record, similar to a name record, but with extra metadata / fields.
    struct SubNameRecord has copy, store, drop {
        // The NameRecord's core data
        name_record: NameRecord,
        // whether the subname is a leaf (no expiration).
        is_leaf: bool,
        // Whether to allow extending the expiration date of the subname
        allow_extension: bool,
        // Whether to allow creation of nested names.
        allow_creation: bool,
    }

    /// A subname record is a `NameRecord` & some extra metadata.
    public fun new(
        name_record: NameRecord,
        is_leaf: bool,
        allow_extension: bool,
        allow_creation: bool,
    ): SubNameRecord {
        SubNameRecord {
            name_record: name_record,
            is_leaf: is_leaf,
            allow_extension: allow_extension,
            allow_creation: allow_creation,
        }
    }

    public fun is_leaf(self: &SubNameRecord): bool {
        self.is_leaf
    }

    public fun is_creation_allowed(self: &SubNameRecord): bool {
        self.allow_creation
    }

    public fun is_extension_allowed(self: &SubNameRecord): bool {
        self.allow_extension
    }

    public fun name_record(self: &SubNameRecord): NameRecord {
        self.name_record
    }
}
