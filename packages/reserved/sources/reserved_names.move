// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// A list that can be used to prevent registrations with our reserved names list.
/// 
/// Can be used in any SuiNS registration package (optionally, as we might have an admin registration that skips these checks).
/// Can also be used in subdomain registration (checks on the offensive table)
module reserved::reserved_names {
    use std::vector;
    use std::string::{String};

    use sui::object::{Self, UID};
    use sui::tx_context::{TxContext, sender};
    use sui::table::{Self, Table};
    use sui::transfer;

    /// == Error Codes ==
    /// No names in the passed list
    const ENoWordsInList: u64 = 1;
    /// The name is in the reserved list so it can't be used.
    const EReservedName: u64 = 2;
    /// The name is in the offensive list so it can't be used.
    const EOffensiveName: u64 = 3;

    /// A struct that holds the ReservedList list.
    /// 
    /// We hold two different tables:
    /// 1. Reserved: Names (SLD) that our partner's hold and we don't want to share.
    /// 2. Offensive: Names that are offensive and we don't want people to use. This one will be checked on subdomains too.
    struct ReservedList has key {
        id: UID,
        reserved: Table<String, bool>,
        offensive: Table<String, bool>
    }

    /// The Cap to add/remove words from the list.
    /// We are generating a new Cap to decouple from SuiNS (skip dependency on main app's AdminCap) and to be able to use
    /// in a 1 out of 6 multisig address, to make additions / removals faster.
    struct ReservedListCap has key, store {
        id: UID
    }

    /// Share the empty list & transfer cap to the admin.
    fun init(ctx: &mut TxContext) {
        transfer::share_object(ReservedList {
            id: object::new(ctx),
            reserved: table::new(ctx),
            offensive: table::new(ctx)
        });

        transfer::transfer(ReservedListCap {
            id: object::new(ctx)
        }, sender(ctx));
    }


    /// == Public functionality == 
    ///
    /// An easy assertion that the word is not in the resered names list.
    public fun assert_is_not_reserved_name(self: &ReservedList, word: String) {
        assert!(!is_reserved_name(self, word), EReservedName);
    }

    /// Boolean check for reserved names to use in custom cases.
    public fun is_reserved_name(self: &ReservedList, word: String): bool {
        table::contains(&self.reserved, word)
    }

    /// An easy assertion that the word is not in the offensive names list.
    public fun assert_is_not_offensive_name(self: &ReservedList, word: String) {
        assert!(!is_offensive_name(self, word), EOffensiveName);
    }

    public fun is_offensive_name(self: &ReservedList, word: String): bool {
        table::contains(&self.offensive, word)
    }

    /// == Admin functionality == 
    /// 
    /// Add a list of reserved names to the list as admin.
    public fun add_reserved_names(self: &mut ReservedList, _: &ReservedListCap, words: vector<String>) {
        internal_add_names_to_list(&mut self.reserved, words);
    }

    /// Add a list of offensive names to the list as admin.
    public fun add_offensive_names(self: &mut ReservedList, _: &ReservedListCap, words: vector<String>) {
        internal_add_names_to_list(&mut self.offensive, words);
    }

    /// Remove a list of words from the reserved names list.
    public fun remove_reserved_names(self: &mut ReservedList, _: &ReservedListCap, words: vector<String>) {
        internal_remove_names_from_list(&mut self.reserved, words);
    }

    /// Remove a list of words from the list as admin.
    public fun remove_offensive_names(self: &mut ReservedList, _: &ReservedListCap, words: vector<String>) {
        internal_remove_names_from_list(&mut self.offensive, words);
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
    public fun list_for_testing(ctx: &mut TxContext): ReservedList {
        ReservedList {
            id: object::new(ctx),
            reserved: table::new(ctx),
            offensive: table::new(ctx)
        }
    }

    #[test_only]
    public fun cap_for_testing(ctx: &mut TxContext): ReservedListCap {
        ReservedListCap {
            id: object::new(ctx)
        }
    }

    #[test_only]
    public fun burn_list_for_testing(list: ReservedList){
        let ReservedList { reserved, offensive, id } = list;
        table::drop(reserved);
        table::drop(offensive);
        object::delete(id);
    }

    #[test_only]
    public fun burn_cap_for_testing(cap: ReservedListCap){
        let ReservedListCap { id } = cap;
        object::delete(id);
    }
}
