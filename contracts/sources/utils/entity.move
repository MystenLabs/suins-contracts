module suins::entity {

    use sui::tx_context::TxContext;
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

    friend suins::base_registry;
    friend suins::base_registrar;
    friend suins::reverse_registrar;
    friend suins::controller;
    friend suins::coin_util;

    struct SuiNS has key {
        id: UID,
        /// Maps domain names to name records (instance of `NameRecord`).
        registry: Table<String, NameRecord>,
        /// Maps tlds to registrar objects, each registrar object is responsible for domains of a particular tld.
        /// Registrar object is a mapping of domain names to registration records (instance of `RegistrationRecord`).
        /// A registrar object can be created by calling `new_tld` and has a record with key `tld` to represent its tld.
        registrars: Table<String, Table<String, RegistrationRecord>>,
        /// Be used in `reverse_registrar.move`
        default_resolver: address,
        controller: Controller,
    }

    struct NameRecord has store, copy, drop {
        owner: address,
        resolver: address,
        ttl: u64,
    }

    /// each registration records has a corresponding name records
    struct RegistrationRecord has store, drop {
        expiry: u64,
        owner: address,
        nft_id: ID,
    }

    struct Controller has store {
        commitments: LinkedTable<vector<u8>, u64>,
        balance: Balance<SUI>,

    }

    public(friend) fun registry(suins: &SuiNS): &Table<String, NameRecord> {
        &suins.registry
    }

    public(friend) fun registry_mut(suins: &mut SuiNS): &mut Table<String, NameRecord> {
        &mut suins.registry
    }

    public(friend) fun registrars(suins: &SuiNS): &Table<String, Table<String, RegistrationRecord>> {
        &suins.registrars
    }

    public(friend) fun registrars_mut(suins: &mut SuiNS): &mut Table<String, Table<String, RegistrationRecord>> {
        &mut suins.registrars
    }

    public(friend) fun registrar(suins: &SuiNS, tld: String): &Table<String, RegistrationRecord> {
        table::borrow(&suins.registrars, tld)
    }

    public(friend) fun registrar_mut(suins: &mut SuiNS, tld: String): &mut Table<String, RegistrationRecord> {
        table::borrow_mut(&mut suins.registrars, tld)
    }

    public(friend) fun default_resolver(suins: &SuiNS): address {
        suins.default_resolver
    }

    public(friend) fun default_resolver_mut(suins: &mut SuiNS): &mut address {
        &mut suins.default_resolver
    }

    public(friend) fun name_record_owner(name_record: &NameRecord): &address {
        &name_record.owner
    }

    public(friend) fun name_record_owner_mut(name_record: &mut NameRecord): &mut address {
        &mut name_record.owner
    }


    public(friend) fun name_record_resolver(name_record: &NameRecord): &address {
        &name_record.resolver
    }

    public(friend) fun name_record_resolver_mut(name_record: &mut NameRecord): &mut address {
        &mut name_record.resolver
    }

    public(friend) fun name_record_ttl(name_record: &NameRecord): &u64 {
        &name_record.ttl
    }

    public(friend) fun name_record_ttl_mut(name_record: &mut NameRecord): &mut u64 {
        &mut name_record.ttl
    }

    public(friend) fun new_name_record(owner: address, resolver: address, ttl: u64): NameRecord {
        NameRecord { owner, resolver, ttl }
    }

    public(friend) fun registration_record_expiry(record: &RegistrationRecord): u64 {
        record.expiry
    }

    public(friend) fun registration_record_expiry_mut(record: &mut RegistrationRecord): &mut u64 {
        &mut record.expiry
    }

    public(friend) fun registration_record_owner(record: &RegistrationRecord): address {
        record.owner
    }

    public(friend) fun registration_record_nft_id(record: &RegistrationRecord): ID {
        record.nft_id
    }

    public(friend) fun new_registrtion_record(expiry: u64, owner: address, nft_id: ID): RegistrationRecord {
        RegistrationRecord { expiry, owner, nft_id }
    }

    public(friend) fun controller_commitments(suins: &SuiNS): &LinkedTable<vector<u8>, u64> {
        &suins.controller.commitments
    }

    public(friend) fun controller_commitments_mut(suins: &mut SuiNS): &mut LinkedTable<vector<u8>, u64> {
        &mut suins.controller.commitments
    }

    public(friend) fun controller_balance(suins: &SuiNS): &Balance<SUI> {
        &suins.controller.balance
    }

    /// Use carefully
    public(friend) fun controller_balance_mut(suins: &mut SuiNS): &mut Balance<SUI> {
        &mut suins.controller.balance
    }

    fun init(ctx: &mut TxContext) {
        let registry = table::new(ctx);
        let registrars = table::new(ctx);
        let controller = Controller {
            commitments: linked_table::new(ctx),
            balance: balance::zero(),
        };

        transfer::share_object(SuiNS {
            id: object::new(ctx),
            registry,
            registrars,
            default_resolver: @0x0,
            controller,
        })
    }

    // === Testing ===

    #[test_only]
    friend suins::base_registry_tests;
    #[test_only]
    friend suins::reverse_registrar_tests;

    #[test_only]
    public fun test_init(ctx: &mut TxContext) {
        let registry = table::new(ctx);
        let registrars = table::new(ctx);
        let controller = Controller {
            commitments: linked_table::new(ctx),
            balance: balance::zero(),
        };

        transfer::share_object(SuiNS {
            id: object::new(ctx),
            registry,
            registrars,
            default_resolver: @0x0,
            controller,
        })
    }
}