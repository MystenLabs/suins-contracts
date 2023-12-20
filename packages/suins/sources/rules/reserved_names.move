// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// A list that can be used to prevent registrations with our reserved names list.
/// 
/// Can be used in any SuiNS registration package (optionally, as we might have an admin registration that skips these checks).
/// Can also be used in subdomain registration (namespaces) (checks only the offensive table)
module suins::reserved_names {
    use std::vector;
    use std::string::{String};

    use sui::object::{Self, UID};
    use sui::tx_context::TxContext;
    use sui::table::{Self, Table};
    use sui::transfer;

    use suins::suins::AdminCap;

    /// == Error Codes ==
    /// No names in the passed list
    const ENoWordsInList: u64 = 1;
    /// The name is in the reserved list so it can't be used.
    const EReservedName: u64 = 2;
    /// The name is in the offensive list so it can't be used.
    const EOffensiveName: u64 = 3;
    /// Tries to check against an expired or invalid list.
    const EInvalidVersion: u64 = 4;

    /// A struct that holds the BlockedNames list.
    struct ReservedNames has key, store {
        id: UID,
        // the list of reserved names. Our public registrations will be checking against it.
        reserved: Table<String, bool>,
        // the list of offensive names. Subdomains + registrations will be checking against.
        offensive: Table<String, bool>,
        // Allows us to use `frozen` objects & check versioning on our packages.
        version: u32
    }

    /// The flow is:
    /// 1. We create a list as an admin
    /// 2. We populate it with reserved / offensive names
    /// 3. We `freeze` it so it is no longer mutable.
    /// 4. We do a version check on each package we use this for, if we wanna ever mutate our lists.
    /// 
    /// For a future mutation we should repeat the steps, increment the version and `freeze` it again:
    ///  1. For our registration/renewal/discounts packages, we'd need to de-authorize them, publish them again and check against the newest version.
    ///  2.  For subdomains: We need to do the same, and also permissionless-ly bump the version of namespaces.
    public fun new(
        _: &AdminCap,
        version: u32,
        ctx: &mut TxContext
    ): ReservedNames {
        ReservedNames {
            id: object::new(ctx),
            reserved: table::new(ctx),
            offensive: table::new(ctx),
            version
        }
    }

    #[lint_allow(freeze_wrapped)]
    /// Freezes the list so it cannot be mutated anymoreand can be used without adding shared object congestion in packages.
    /// <Use with caution>: Always bump the version and follow the steps explained in the `new` function.
    public fun freeze_list(
        list: ReservedNames
    ) {
        transfer::freeze_object(list);
    }

    /// == Public functionality == 
    ///
    /// An easy assertion that the word is not in the resered names list.
    public fun assert_is_not_reserved_name(self: &ReservedNames, name: String, expected_version: u32) {
        assert_is_valid_version(self, expected_version);
        assert!(!is_reserved_name(self, name), EReservedName);
    }

    /// Boolean check for reserved names to use in custom cases.
    public fun is_reserved_name(self: &ReservedNames, name: String): bool {
        table::contains(&self.reserved, name)
    }

    /// An easy assertion that the word is not in the offensive names list.
    /// We also validate against a version here.
    public fun assert_is_not_offensive_name(self: &ReservedNames, name: String, expected_version: u32) {
        assert_is_valid_version(self, expected_version);
        assert!(!is_offensive_name(self, name), EOffensiveName);
    }

    public fun is_offensive_name(self: &ReservedNames, name: String): bool {
        table::contains(&self.offensive, name)
    }

    /// == Admin functionality == 
    /// 
    /// Add a list of reserved names to the list as admin.
    public fun add_reserved_names(self: &mut ReservedNames, words: vector<String>) {
        internal_add_names_to_list(&mut self.reserved, words);
    }

    /// Add a list of offensive names to the list as admin.
    public fun add_offensive_names(self: &mut ReservedNames, words: vector<String>) {
        internal_add_names_to_list(&mut self.offensive, words);
    }

    /// Remove a list of words from the reserved names list.
    public fun remove_reserved_names(self: &mut ReservedNames, words: vector<String>) {
        internal_remove_names_from_list(&mut self.reserved, words);
    }

    /// Remove a list of words from the list as admin.
    public fun remove_offensive_names(self: &mut ReservedNames, words: vector<String>) {
        internal_remove_names_from_list(&mut self.offensive, words);
    }

    /// Validate that the frozen object has the expected version.
    /// Expected version is defined by the package that uses this list + calls for validation.
    public fun assert_is_valid_version(self: &ReservedNames, expected_version: u32) {
        assert!(self.version == expected_version, EInvalidVersion);
    }

    /// Internal helper to batch add words to a table.
    fun internal_add_names_to_list(table: &mut Table<String, bool>, words: vector<String>) {
        assert!(vector::length(&words) > 0, ENoWordsInList);

        let i = vector::length(&words);

        while (i > 0) {
            i = i - 1;
            let word = *vector::borrow(&words, i);
            table::add(table, word, true);
        };
    }

    /// Internal helper to remove words from a table.
    fun internal_remove_names_from_list(table: &mut Table<String, bool>, words: vector<String>) {
        assert!(vector::length(&words) > 0, ENoWordsInList);

        let i = vector::length(&words);

        while (i > 0) {
            i = i - 1;
            let word = *vector::borrow(&words, i);
            table::remove(table, word);
        };
    }

    #[test_only]
    public fun list_for_testing(version: u32, ctx: &mut TxContext): ReservedNames {
        ReservedNames {
            id: object::new(ctx),
            reserved: table::new(ctx),
            offensive: table::new(ctx),
            version
        }
    }

    #[test_only]
    public fun burn_list_for_testing(list: ReservedNames){
        let ReservedNames { reserved, offensive, id, version: _ } = list;
        table::drop(reserved);
        table::drop(offensive);
        object::delete(id);
    }
}
