module suins::suins {
    use std::option::some;
    use std::string::String;

    use sui::tx_context::{sender, Self, TxContext};
    use sui::object::{Self, UID};
    use sui::table::{Self, Table};
    use sui::transfer;
    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::dynamic_field as df;

    use suins::name_record;

    friend suins::registry;
    friend suins::auction;

    /// Trying to withdraw from an empty balance.
    const ENoProfits: u64 = 0;
    /// Trying to access a name record that belongs to another account.
    const ENotRecordOwner: u64 = 1;
    /// An application is not authorized to access the feature.
    const EAppNotAuthorized: u64 = 2;

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
        registrars: UID,
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
            registrars: object::new(ctx),
        };

        transfer::share_object(suins);
    }

    // === Admin actions ===

    /// Withdraw from the SuiNS balance directly and access the Coins within the same
    /// transaction. This is useful for the admin to withdraw funds from the SuiNS
    /// and then send them somewhere specific or keep at the address.
    public fun withdraw(_: &AdminCap, self: &mut SuiNS, ctx: &mut TxContext): Coin<SUI> {
        let amount = balance(self);
        assert!(amount > 0, ENoProfits);
        coin::take(&mut self.balance, amount, ctx)
    }

    // === App Auth ===

    /// An authorization Key kept in the SuiNS - allows applications access
    /// protected features of the SuiNS (such as add_to_balance, add_record
    /// etc.)
    /// The `App` type parameter is a witness which should be defined in the
    /// original module (Controller, Registry, Registrar - whatever).
    struct AppKey<phantom App: drop> has copy, store, drop {}

    /// Authorize an application to access protected features of the SuiNS.
    public fun authorize_app<App: drop>(_: &AdminCap, self: &mut SuiNS) {
        df::add(&mut self.id, AppKey<App>{}, true);
    }

    /// Deauthorize an application by removing its authorization key.
    public fun deathorize_app<App: drop>(_: &AdminCap, self: &mut SuiNS): bool {
        df::remove(&mut self.id, AppKey<App>{})
    }

    /// Check if an application is authorized to access protected features of
    /// the SuiNS.
    public fun is_app_authorized<App: drop>(self: &SuiNS): bool {
        df::exists_(&self.id, AppKey<App>{})
    }

    // === Protected features ===

    /// Mutable access to `SuiNS.UID` for authorized applications.
    public fun app_uid_mut<App: drop>(_: App, self: &mut SuiNS): &mut UID {
        assert!(is_app_authorized<App>(self), EAppNotAuthorized);
        &mut self.id
    }

    /// Borrow configuration object. Read-only mode for applications.
    public fun app_get_config_mut<App: drop, Config: store + drop>(_: App, self: &mut SuiNS): &mut Config {
        assert!(is_app_authorized<App>(self), EAppNotAuthorized);
        df::borrow_mut(&mut self.id, ConfigKey<Config> {})
    }

    /// Add a new record to the SuiNS.
    public fun app_add_record<App: drop>(
        _: App, self: &mut SuiNS, domain_name: String, owner: address
    ) {
        assert!(is_app_authorized<App>(self), EAppNotAuthorized);
        let name_record = name_record::new(some(owner));
        if (has_name_record(self, domain_name)) {
            *table::borrow_mut(&mut self.record_owner, domain_name) = owner;
            *df::borrow_mut(&mut self.registry, domain_name) = name_record;
        } else {
            table::add(&mut self.record_owner, domain_name, owner);
            df::add(&mut self.registry, domain_name, name_record)
        }
    }

    /// Get the registrars_mut field of the SuiNS.
    public fun app_registrars_mut<App: drop>(_: App, self: &mut SuiNS): &mut UID {
        assert!(is_app_authorized<App>(self), EAppNotAuthorized);
        &mut self.registrars
    }

    public fun app_set_owner<App: drop>(
        _: App, self: &mut SuiNS, domain_name: String, owner: address
    ) {
        assert!(is_app_authorized<App>(self), EAppNotAuthorized);
        *table::borrow_mut(&mut self.record_owner, domain_name) = owner;
    }

    /// Adds balance to the SuiNS.
    public fun app_add_balance<App: drop>(_: App, self: &mut SuiNS, balance: Balance<SUI>) {
        assert!(is_app_authorized<App>(self), EAppNotAuthorized);
        balance::join(&mut self.balance, balance);
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

    /// Get the configuration object for editing. The admin should put it back
    /// after editing (no extra check performed). Can be used to swap
    /// configuration since the `T` has `drop`. Eg nothing is stopping the admin
    /// from removing the configuration object and adding a new one.
    ///
    /// Fully taking the config also allows for edits within a transaction.
    public fun remove_config<Config: store + drop>(_: &AdminCap, self: &mut SuiNS): Config {
        df::remove(&mut self.id, ConfigKey<Config> {})
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

    /// Read the `name_record` for the specified `domain_name`.
    public fun name_record<Record: store + drop>(self: &SuiNS, domain_name: String): &Record {
        df::borrow(&self.registry, domain_name)
    }

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
    /// TODO: consider better name_record API.
    public fun has_name_record(self: &SuiNS, domain_name: String): bool {
        df::exists_(&self.registry, domain_name)
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

    // not sure about exposing just UID yet!
    public fun uid(self: &SuiNS): &UID { &self.id }

    public fun registry(self: &SuiNS): &UID { &self.registry }
    public fun registrars(self: &SuiNS): &UID { &self.registrars }
    public fun reverse_registry(self: &SuiNS): &Table<address, String> {
        &self.reverse_registry
    }

    public fun balance(self: &SuiNS): u64 {
        balance::value(&self.balance)
    }

    // === Friend and Private Functions ===

    public(friend) fun reverse_registry_mut(self: &mut SuiNS): &mut Table<address, String> {
        &mut self.reverse_registry
    }

    public(friend) fun send_from_balance(self: &mut SuiNS, amount: u64, receiver: address, ctx: &mut TxContext) {
        let coin = coin::take(&mut self.balance, amount, ctx);
        transfer::public_transfer(coin, receiver);
    }

    // === Testing ===

    #[test_only] use suins::config;
    #[test_only] use suins::promotion;
    #[test_only] struct Test has drop {}

    #[test_only]
    /// Wrapper of module initializer for testing
    public fun init_for_testing(ctx: &mut TxContext): SuiNS {
        let admin_cap = AdminCap { id: object::new(ctx) };
        let suins = SuiNS {
            id: object::new(ctx),
            balance: balance::zero(),
            registry: object::new(ctx),
            record_owner: table::new(ctx),
            reverse_registry: table::new(ctx),
            registrars: object::new(ctx)
        };

        authorize_app<Test>(&admin_cap, &mut suins);
        add_config(&admin_cap, &mut suins, promotion::new());
        add_config(&admin_cap, &mut suins, config::new(
            vector[],
            true,
            1200 * suins::constants::mist_per_sui(),
            200 * suins::constants::mist_per_sui(),
            50 * suins::constants::mist_per_sui(),
        ));
        transfer::transfer(admin_cap, tx_context::sender(ctx));
        suins
    }

    #[test_only]
    public fun share_for_testing(self: SuiNS) {
        transfer::share_object(self)
    }

    #[test_only]
    public fun authorize_app_for_testing<App: drop>(self: &mut SuiNS) {
        df::add(&mut self.id, AppKey<App> {}, true)
    }

    #[test_only]
    /// Add a record for testing purposes.
    public fun add_record_for_testing(self: &mut SuiNS, domain_name: String, owner: address) {
        app_add_record(Test {}, self, domain_name, owner)
    }
}
