module suins::suins {

    use sui::tx_context::{Self, TxContext};
    use sui::object::{UID, ID};
    use sui::table::Table;
    use std::string::String;
    use sui::table;
    use sui::transfer;
    use sui::object;
    use sui::linked_table::LinkedTable;
    use sui::balance::Balance;
    use sui::sui::SUI;
    use sui::linked_table;
    use sui::balance;

    friend suins::registry;
    friend suins::registrar;
    friend suins::controller;
    friend suins::coin_util;
    friend suins::auction;

    const MAX_U64: u64 = 18446744073709551615;

    // https://examples.sui.io/patterns/capability.html
    struct AdminCap has key, store {
        id: UID,
    }

    struct SuiNS has key {
        id: UID,
        /// Maps domain names to name records (instance of `NameRecord`).
        registry: Table<String, NameRecord>,

        /// Map from addresses to a configured default domain
        reverse_registry: Table<address, String>,

        /// Maps tlds to registrar objects, each registrar object is responsible for domains of a particular tld.
        /// Registrar object is a mapping of domain names to registration records (instance of `RegistrationRecord`).
        /// A registrar object can be created by calling `new_tld` and has a record with key `tld` to represent its tld.
        registrars: Table<String, Table<String, RegistrationRecord>>,
        controller: Controller,
    }

    struct NameRecord has store {
        owner: address,
        linked_addr: address,
        ttl: u64,
        data: Table<String, String>,
    }

    /// each registration records has a corresponding name records
    struct RegistrationRecord has store, drop {
        expired_at: u64,
        nft_id: ID,
    }

    struct Controller has store {
        commitments: LinkedTable<vector<u8>, u64>,
        balance: Balance<SUI>,
        /// set by `configure_auction`
        /// the last epoch when bidder can call `finalize_auction`
        auction_house_finalized_at: u64,
    }

    public fun registry(suins: &SuiNS): &Table<String, NameRecord> {
        &suins.registry
    }

    public fun registrars(suins: &SuiNS): &Table<String, Table<String, RegistrationRecord>> {
        &suins.registrars
    }

    public fun registrar(suins: &SuiNS, tld: String): &Table<String, RegistrationRecord> {
        table::borrow(&suins.registrars, tld)
    }

    public fun name_record_owner(name_record: &NameRecord): address {
        name_record.owner
    }

    public fun name_record_ttl(name_record: &NameRecord): u64 {
        name_record.ttl
    }

    public fun name_record_linked_addr(name_record: &NameRecord): address {
        name_record.linked_addr
    }

    public fun registration_record_expired_at(record: &RegistrationRecord): u64 {
        record.expired_at
    }

    public fun registration_record_nft_id(record: &RegistrationRecord): ID {
        record.nft_id
    }

    public fun controller_commitments(suins: &SuiNS): &LinkedTable<vector<u8>, u64> {
        &suins.controller.commitments
    }

    public fun controller_auction_house_finalized_at(suins: &SuiNS): u64 {
        suins.controller.auction_house_finalized_at
    }

    public fun max_epoch_allowed(): u64 {
        MAX_U64 - 365
    }

    public fun max_u64(): u64 {
        MAX_U64
    }

    public fun controller_balance(suins: &SuiNS): &Balance<SUI> {
        &suins.controller.balance
    }

    public fun new_registration_record(expired_at: u64, nft_id: ID): RegistrationRecord {
        RegistrationRecord { expired_at, nft_id }
    }

    public fun new_name_record(owner: address, ttl: u64, linked_addr: address, ctx: &mut TxContext): NameRecord {
        NameRecord {
            owner,
            ttl,
            linked_addr,
            data: table::new(ctx),
        }
    }

    // === Friend and Private Functions ===

    public(friend) fun name_record_data(name_record: &NameRecord): &Table<String, String> {
        &name_record.data
    }

    public(friend) fun registry_mut(suins: &mut SuiNS): &mut Table<String, NameRecord> {
        &mut suins.registry
    }

    public(friend) fun reverse_registry(suins: &SuiNS): &Table<address, String> {
        &suins.reverse_registry
    }

    public(friend) fun reverse_registry_mut(suins: &mut SuiNS): &mut Table<address, String> {
        &mut suins.reverse_registry
    }

    public(friend) fun registrars_mut(suins: &mut SuiNS): &mut Table<String, Table<String, RegistrationRecord>> {
        &mut suins.registrars
    }

    public(friend) fun registrar_mut(suins: &mut SuiNS, tld: String): &mut Table<String, RegistrationRecord> {
        table::borrow_mut(&mut suins.registrars, tld)
    }

    public(friend) fun name_record_owner_mut(name_record: &mut NameRecord): &mut address {
        &mut name_record.owner
    }

    public(friend) fun name_record_ttl_mut(name_record: &mut NameRecord): &mut u64 {
        &mut name_record.ttl
    }

    public(friend) fun name_record_linked_addr_mut(name_record: &mut NameRecord): &mut address {
        &mut name_record.linked_addr
    }

    public(friend) fun name_record_data_mut(name_record: &mut NameRecord): &mut Table<String, String> {
        &mut name_record.data
    }

    public(friend) fun registration_record_expired_at_mut(record: &mut RegistrationRecord): &mut u64 {
        &mut record.expired_at
    }

    public(friend) fun controller_commitments_mut(suins: &mut SuiNS): &mut LinkedTable<vector<u8>, u64> {
        &mut suins.controller.commitments
    }

    /// Use carefully
    public(friend) fun controller_balance_mut(suins: &mut SuiNS): &mut Balance<SUI> {
        &mut suins.controller.balance
    }

    public(friend) fun controller_auction_house_finalized_at_mut(suins: &mut SuiNS): &mut u64 {
        &mut suins.controller.auction_house_finalized_at
    }

    fun init(ctx: &mut TxContext) {
        let admin_cap = AdminCap {
            id: object::new(ctx),
        };
        transfer::transfer(admin_cap, tx_context::sender(ctx));

        let registry = table::new(ctx);
        let reverse_registry = table::new(ctx);
        let registrars = table::new(ctx);
        let controller = Controller {
            commitments: linked_table::new(ctx),
            balance: balance::zero(),
            auction_house_finalized_at: max_epoch_allowed(),
        };

        let suins = SuiNS {
            id: object::new(ctx),
            registry,
            reverse_registry,
            registrars,
            controller,
        };

        transfer::share_object(suins);
    }

    // === Testing ===

    #[test_only]
    friend suins::registry_tests;
    #[test_only]
    friend suins::registry_tests_2;

    #[test_only]
    /// Wrapper of module initializer for testing
    public fun test_init(ctx: &mut TxContext) {
        let admin_cap = AdminCap {
            id: object::new(ctx),
        };
        transfer::transfer(admin_cap, tx_context::sender(ctx));

        let registry = table::new(ctx);
        let reverse_registry = table::new(ctx);
        let registrars = table::new(ctx);
        let controller = Controller {
            commitments: linked_table::new(ctx),
            balance: balance::zero(),
            auction_house_finalized_at: max_epoch_allowed(),
        };

        let suins = SuiNS {
            id: object::new(ctx),
            registry,
            reverse_registry,
            registrars,
            controller,
        };

        transfer::share_object(suins);
    }
}
