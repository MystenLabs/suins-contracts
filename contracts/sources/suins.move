module suins::suins {
    use std::option::some;
    use std::string::String;

    use sui::tx_context::{sender, Self, TxContext};
    use sui::object::{UID, ID};
    use sui::table::Table;
    use sui::table;
    use sui::transfer;
    use sui::object;
    use sui::linked_table::LinkedTable;
    use sui::balance::Balance;
    use sui::sui::SUI;
    use sui::linked_table;
    use sui::balance;
    use sui::coin::{Self, Coin};
    use sui::dynamic_field as df;

    use suins::constants;
    use suins::name_record;

    friend suins::registry;
    friend suins::registrar;
    friend suins::controller;
    friend suins::auction;

    /// Trying to withdraw from an empty balance.
    const ENoProfits: u64 = 0;
    /// Trying to access a name record that belongs to another account.
    const ENotRecordOwner: u64 = 1;

    /// An admin capability. The admin has full control over the application.
    /// This object must be issued only once during module initialization.
    struct AdminCap has key, store { id: UID }

    /// The main application object. Stores the state of the application,
    /// used for adding / removing and reading name records.
    struct SuiNS has key {
        id: UID,
        /// The total balance of the SuiNS.
        balance: Balance<SUI>,
        /// Maps domain names to name records (instance of `NameRecord`).
        /// `String => (T = NameRecord)`
        registry: UID,
        /// Map from addresses to a configured default domain
        reverse_registry: Table<address, String>,
        /// Track record ownership to perform authorization.
        /// TODO: try nuke ownership from the NameRecord.
        record_owner: Table<String, address>,
        /// Maps tlds to registrar objects, each registrar object is responsible for domains of a particular tld.
        /// Registrar object is a mapping of domain names to registration records (instance of `RegistrationRecord`).
        /// A registrar object can be created by calling `new_tld` and has a record with key `tld` to represent its tld.
        registrars: Table<String, Table<String, RegistrationRecord>>,
        /// The controller object is responsible for managing the auction house.
        controller: Controller,
    }

    /// each registration records has a corresponding name records
    struct RegistrationRecord has store, drop {
        expired_at: u64,
        nft_id: ID,
    }

    struct Controller has store {
        commitments: LinkedTable<vector<u8>, u64>,
        /// set by `configure_auction`
        /// the last epoch when bidder can call `finalize_auction`
        auction_house_finalized_at: u64,
    }

    /// The one-time-witness used to claim Publisher object.
    struct SUINS has drop {}

    // === Keys ===

    /// Key under which a configuration is stored. It is type dependent, so
    /// that different configurations can be stored at the same time. Eg
    /// currently we store application `Config` and `Promotion` configuration.
    struct ConfigKey<phantom Config> has copy, store, drop {}

    /// Module initializer:
    /// - create SuiNS object
    /// - create admin capability
    /// - claim Publisher object (for Display and TransferPolicy)
    fun init(otw: SUINS, ctx: &mut TxContext) {
        sui::package::claim_and_keep(otw, ctx);

        // Create the admin capability; only performed once.
        transfer::transfer(AdminCap {
            id: object::new(ctx),
        }, tx_context::sender(ctx));

        let suins = SuiNS {
            id: object::new(ctx),
            balance: balance::zero(),
            registry: object::new(ctx),
            reverse_registry: table::new(ctx),
            record_owner: table::new(ctx),
            registrars: table::new(ctx),
            controller: Controller {
                commitments: linked_table::new(ctx),
                auction_house_finalized_at: constants::max_epoch_allowed(),
            }
        };

        transfer::share_object(suins);
    }

    // === Config management ===

    /// Attach dynamic configuration object to the application.
    public fun add_config<Config: store + drop>(_: &AdminCap, self: &mut SuiNS, config: Config) {
        df::add(&mut self.id, ConfigKey<Config> {}, config);
    }

    /// Borrow configuration object. Read-only mode for applications.
    public fun get_config<Config: store + drop>(self: &SuiNS): &Config {
        df::borrow(&self.id, ConfigKey<Config> {})
    }

    /// Borrow configuration object. Read-only mode for applications.
    // Keep as friend
    public(friend) fun get_config_mut<Config: store + drop>(self: &mut SuiNS): &mut Config {
        df::borrow_mut(&mut self.id, ConfigKey<Config> {})
    }

    /// Get the configuration object for editing. The admin should put it back
    /// after editing (no extra check performed). Can be used to swap
    /// configuration since the `T` has `drop`. Eg nothing is stopping the admin
    /// from removing the configuration object and adding a new one.
    ///
    /// Fully taking the config also allows for edits within a transaction.
    public fun remove_config<Config: store + drop>(_: &AdminCap, self: &mut SuiNS): Config {
        df::remove(&mut self.id, ConfigKey<Config> {})
    }

    // === Admin actions ===

    /// Withdraw from the SuiNS balance directly and access the Coins within the same
    /// transaction. This is useful for the admin to withdraw funds from the SuiNS
    /// and then send them somewhere specific or keep at the address.
    ///
    /// TODO: check logic around coin management in the application.
    public fun withdraw(_: &AdminCap, self: &mut SuiNS, ctx: &mut TxContext): Coin<SUI> {
        let amount = balance(self);
        assert!(amount > 0, ENoProfits);
        coin::take(&mut self.balance, amount, ctx)
    }

    // === Registrar ===

    public fun new_registration_record(expired_at: u64, nft_id: ID): RegistrationRecord {
        RegistrationRecord { expired_at, nft_id }
    }

    // === Records creation ===

    // TODO: revisit this section once Registry is cleaned up.
    // Thoughts:
    // - generalizing NameRecord and utilizing type parameters is great
    // but in the current implementation it conflicts with the ability
    // to give owner the full power over the record. We can't call "owner check"
    // on a type that we don't know.
    // - idea - how about separate `domain_name => owner` mapping for each
    // name record. This would free the format while preserving the ownership
    // part free of the actual NameRecord type / format. The implication would
    // be an extra dynamic field to track but it might not be too big of a deal
    // given the flexibility it gives us.

    /// Mutable access to the name record.
    /// TODO: add reverse registry methods to the name record when it is changed.
    /// TODO: see `name_record` module for details.
    public fun name_record_mut<Record: store + drop>(
        self: &mut SuiNS, domain_name: String, ctx: &mut TxContext
    ): &mut Record {
        assert!(record_owner(self, domain_name) == sender(ctx), ENotRecordOwner);
        df::borrow_mut(&mut self.registry, domain_name)
    }

    /// REFACTOR: remove friend once `Registry` is dealt with.
    public(friend) fun name_record_mut_internal<Record: store + drop>(
        self: &mut SuiNS, domain_name: String
    ): &mut Record {
        df::borrow_mut(&mut self.registry, domain_name)
    }

    /// REFACTOR: remove friend once `Registry` is dealt with.
    /// TODO: consider better name_record API.
    public fun has_name_record(self: &SuiNS, domain_name: String): bool {
        df::exists_(&self.registry, domain_name)
    }

    /// Creates and adds a new `name_record` to the `SuiNS`.
    /// REFACTOR: remove friend once `Registry` is dealt with.
    public(friend) fun add_record(
        suins: &mut SuiNS,
        domain_name: String,
        owner: address
    ) {
        let name_record = name_record::new(some(owner));
        if (has_name_record(suins, domain_name)) {
            *table::borrow_mut(&mut suins.record_owner, domain_name) = owner;
            *df::borrow_mut(&mut suins.registry, domain_name) = name_record;
        } else {
            table::add(&mut suins.record_owner, domain_name, owner);
            df::add(&mut suins.registry, domain_name, name_record)
        }
    }

    /// Transfer ownership of the name record to the `new_address`.
    public fun transfer_ownership(
        self: &mut SuiNS,
        domain_name: String,
        new_owner: address,
        ctx: &mut TxContext
    ) {
        let old_owner = record_owner(self, domain_name);
        assert!(old_owner == sender(ctx), ENotRecordOwner);
        *table::borrow_mut(&mut self.record_owner, domain_name) = new_owner;
    }

    // === Fields access ===

    public fun record_owner(self: &SuiNS, domain_name: String): address {
        *table::borrow(&self.record_owner, domain_name)
    }

    /// Read the `name_record` for the specified `domain_name`.
    public fun name_record<Record: store + drop>(self: &SuiNS, domain_name: String): &Record {
        df::borrow(&self.registry, domain_name)
    }

    public fun registry(self: &SuiNS): &UID {
        &self.registry
    }

    public fun registrars(
        self: &SuiNS
    ): &Table<String, Table<String, RegistrationRecord>> {
        &self.registrars
    }

    public fun registrar(
        self: &SuiNS, tld: String
    ): &Table<String, RegistrationRecord> {
        table::borrow(&self.registrars, tld)
    }

    public fun registration_record_expired_at(record: &RegistrationRecord): u64 {
        record.expired_at
    }

    public fun registration_record_nft_id(record: &RegistrationRecord): ID {
        record.nft_id
    }

    public fun controller_commitments(
        self: &SuiNS
    ): &LinkedTable<vector<u8>, u64> {
        &self.controller.commitments
    }

    public fun controller_auction_house_finalized_at(self: &SuiNS): u64 {
        self.controller.auction_house_finalized_at
    }

    public fun balance(self: &SuiNS): u64 {
        balance::value(&self.balance)
    }

    // === Friend and Private Functions ===

    public(friend) fun set_owner_internal(self: &mut SuiNS, domain_name: String, owner: address) {
        *table::borrow_mut(&mut self.record_owner, domain_name) = owner;
    }

    public(friend) fun reverse_registry(self: &SuiNS): &Table<address, String> {
        &self.reverse_registry
    }

    public(friend) fun reverse_registry_mut(self: &mut SuiNS): &mut Table<address, String> {
        &mut self.reverse_registry
    }

    public(friend) fun registrars_mut(self: &mut SuiNS): &mut Table<String, Table<String, RegistrationRecord>> {
        &mut self.registrars
    }

    public(friend) fun registrar_mut(self: &mut SuiNS, tld: String): &mut Table<String, RegistrationRecord> {
        table::borrow_mut(&mut self.registrars, tld)
    }

    public(friend) fun registration_record_expired_at_mut(record: &mut RegistrationRecord): &mut u64 {
        &mut record.expired_at
    }

    public(friend) fun controller_commitments_mut(self: &mut SuiNS): &mut LinkedTable<vector<u8>, u64> {
        &mut self.controller.commitments
    }

    public(friend) fun controller_auction_house_finalized_at_mut(self: &mut SuiNS): &mut u64 {
        &mut self.controller.auction_house_finalized_at
    }

    /// Only used by auction
    public(friend) fun join_balance(self: &mut SuiNS, balance: Balance<SUI>) {
        balance::join(&mut self.balance, balance);
    }

    public(friend) fun add_to_balance(self: &mut SuiNS, coin: Coin<SUI>) {
        coin::put(&mut self.balance, coin);
    }

    public(friend) fun send_from_balance(self: &mut SuiNS, amount: u64, receiver: address, ctx: &mut TxContext) {
        let coin = coin::take(&mut self.balance, amount, ctx);
        transfer::public_transfer(coin, receiver);
    }

    // === Testing ===

    #[test_only] use suins::config;
    #[test_only] use suins::promotion;
    #[test_only] friend suins::registry_tests;
    #[test_only] friend suins::registry_tests_2;

    #[test_only]
    /// Wrapper of module initializer for testing
    public fun test_init(ctx: &mut TxContext) {
        let registry = object::new(ctx);
        let record_owner = table::new(ctx);
        let reverse_registry = table::new(ctx);
        let registrars = table::new(ctx);
        let controller = Controller {
            commitments: linked_table::new(ctx),
            auction_house_finalized_at: constants::max_epoch_allowed(),
        };

        let admin_cap = AdminCap { id: object::new(ctx) };
        let suins = SuiNS {
            id: object::new(ctx),
            balance: balance::zero(),
            registry,
            record_owner,
            reverse_registry,
            registrars,
            controller,
        };

        add_config(&admin_cap, &mut suins, promotion::new());
        add_config(&admin_cap, &mut suins, config::new(
            vector[],
            true,
            1200 * suins::constants::mist_per_sui(),
            200 * suins::constants::mist_per_sui(),
            50 * suins::constants::mist_per_sui(),
        ));


        transfer::transfer(admin_cap, tx_context::sender(ctx));
        transfer::share_object(suins);
    }

    #[test_only]
    /// Add a record for testing purposes.
    public fun add_record_for_testing(self: &mut SuiNS, domain_name: String, owner: address) {
        add_record(self, domain_name, owner)
    }
}
