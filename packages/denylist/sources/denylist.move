// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

module denylist::denylist {
    use std::string::String;
    use std::vector;

    use sui::tx_context::{TxContext};
    use sui::table::{Self, Table};
    
    use suins::suins::{Self, AdminCap, SuiNS};

    /// No names in the passed list
    const ENoWordsInList: u64 = 1;

    /// A wrapper that holds the reserved and blocked names.
    struct Denylist has store {
        // The list of reserved names. 
        // Our public SLD registrations will be checking against it.
        reserved: Table<String, bool>,
        // The list of blocked names.
        // Subdomains + registrations will be checking against.
        blocked: Table<String, bool>,
    }

    /// The authorization for the denylist registry.
    struct DenyListAuth has drop {}

    public fun setup(suins: &mut SuiNS, cap: &AdminCap, ctx: &mut TxContext) {
        suins::add_registry(cap, suins, Denylist {
            reserved: table::new(ctx),
            blocked: table::new(ctx)
        });
    }

    /// Check for a reserved name
    public fun is_reserved_name(suins: &SuiNS, name: String): bool {
        table::contains(&denylist(suins).reserved, name)
    }

    /// Checks for a blocked name.
    public fun is_blocked_name(suins: &SuiNS, name: String): bool {
        table::contains(&denylist(suins).blocked, name)
    }

    /// Add a list of reserved names to the list as admin.
    public fun add_reserved_names(suins: &mut SuiNS, _: &AdminCap, words: vector<String>) {
        internal_add_names_to_list(&mut denylist_mut(suins).reserved, words);
    }

    /// Add a list of offensive names to the list as admin.
    public fun add_blocked_names(suins: &mut SuiNS, _: &AdminCap, words: vector<String>) {
        internal_add_names_to_list(&mut denylist_mut(suins).blocked, words);
    }

    /// Remove a list of words from the reserved names list.
    public fun remove_reserved_names(suins: &mut SuiNS, _: &AdminCap, words: vector<String>) {
        internal_remove_names_from_list(&mut denylist_mut(suins).reserved, words);
    }

    /// Remove a list of words from the list as admin.
    public fun remove_blocked_names(suins: &mut SuiNS, _: &AdminCap, words: vector<String>) {
        internal_remove_names_from_list(&mut denylist_mut(suins).blocked, words);
    }

    /// Get immutable access to the registry.
    fun denylist(suins: &SuiNS): &Denylist {
        suins::registry(suins)
    }

    /// Internal helper to get access to the BlockedNames object
    fun denylist_mut(suins: &mut SuiNS): &mut Denylist {
        suins::app_registry_mut<DenyListAuth, Denylist>(DenyListAuth {}, suins)
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
    public fun new_for_testing(ctx: &mut TxContext): Denylist {
        Denylist {
            reserved: table::new(ctx),
            blocked: table::new(ctx)
        }
    }
}
