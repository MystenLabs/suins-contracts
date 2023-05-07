module suins::suins {
    use sui::tx_context::{Self, TxContext};
    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin};
    use sui::dynamic_field as df;
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::sui::SUI;

    /// Trying to withdraw from an empty balance.
    const ENoProfits: u64 = 0;
    /// Trying to access a name record that belongs to another account.
    const ENotRecordOwner: u64 = 1;
    /// An application is not authorized to access the feature.
    const EAppNotAuthorized: u64 = 2;
    /// Beep boop.
    const EDefaultDomainNameNotMatch: u64 = 3;
    /// The `RegistrationNFT` has expired.
    const ENftExpired: u64 = 4;
    /// Trying to use a `RegistrationNFT` that expired and was replaced.
    const ENftIdNotMatch: u64 = 5;

    /// An admin capability. The admin has full control over the application.
    /// This object must be issued only once during module initialization.
    struct AdminCap has key, store { id: UID }

    /// The main application object. Stores the state of the application,
    /// used for adding / removing and reading name records.
    struct SuiNS has key {
        id: UID,
        /// The total balance of the SuiNS.
        balance: Balance<SUI>,

        // === Dynamic Fields ===

        // registry: RegistryKey<R> -> R
        // config: ConfigKey<C> -> C
    }

    /// The one-time-witness used to claim Publisher object.
    struct SUINS has drop {}

    // === Keys ===

    /// Key under which a configuration is stored. It is type dependent, so
    /// that different configurations can be stored at the same time. Eg
    /// currently we store application `Config` and `Promotion` configuration.
    struct ConfigKey<phantom Config> has copy, store, drop {}

    struct RegistryKey<phantom Config> has copy, store, drop {}

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
        };

        transfer::share_object(suins);
    }

    // === Admin actions ===

    /// Withdraw from the SuiNS balance directly and access the Coins within the same
    /// transaction. This is useful for the admin to withdraw funds from the SuiNS
    /// and then send them somewhere specific or keep at the address.
    public fun withdraw(_: &AdminCap, self: &mut SuiNS, ctx: &mut TxContext): Coin<SUI> {
        let amount = balance::value(&self.balance);
        assert!(amount > 0, ENoProfits);
        coin::take(&mut self.balance, amount, ctx)
    }

    // === App Auth ===

    /// An authorization Key kept in the SuiNS - allows applications access
    /// protected features of the SuiNS (such as app_add_balance, etc.)
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

    public fun assert_app_is_authorized<App: drop>(self: &SuiNS) {
        assert!(is_app_authorized<App>(self), EAppNotAuthorized);
    }

    // === Protected features ===

    /// Mutable access to `SuiNS.UID` for authorized applications.
    public fun app_uid_mut<App: drop>(_: App, self: &mut SuiNS): &mut UID {
        assert!(is_app_authorized<App>(self), EAppNotAuthorized);
        &mut self.id
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

    // === Registry ===

    public fun registry<R: store>(self: &SuiNS): &R {
        df::borrow(&self.id, RegistryKey<R> {})
    }

    public fun registry_mut<R: store, App: drop>(self: &mut SuiNS, _: App): &mut R {
        assert_app_is_authorized<App>(self);
        df::borrow_mut(&mut self.id, RegistryKey<R> {})
    }

    fun add_registry<R: store>(_: &AdminCap, self: &mut SuiNS, registry: R) {
        df::add(&mut self.id, RegistryKey<R> {}, registry);
    }

    fun remove_registry<R: store>(_: &AdminCap, self: &mut SuiNS): R {
        df::remove(&mut self.id, RegistryKey<R> {})
    }

    // === Friend and Private Functions ===

    // === Testing ===

    #[test_only] use std::string::String;
    #[test_only] use sui::clock::Clock;
    #[test_only] use suins::registry::{Self, Registry};
    #[test_only] use suins::config;
    #[test_only] use suins::registration_nft::RegistrationNFT;
    #[test_only] use suins::domain;
    #[test_only] struct Test has drop {}

    #[test_only]
    /// Wrapper of module initializer for testing
    public fun init_for_testing(ctx: &mut TxContext): SuiNS {
        let admin_cap = AdminCap { id: object::new(ctx) };
        let suins = SuiNS {
            id: object::new(ctx),
            balance: balance::zero(),
        };

        authorize_app<Test>(&admin_cap, &mut suins);
        add_config(&admin_cap, &mut suins, config::new(
            vector[],
            1200 * suins::constants::mist_per_sui(),
            200 * suins::constants::mist_per_sui(),
            50 * suins::constants::mist_per_sui(),
        ));
        add_registry(&admin_cap, &mut suins, registry::new(ctx));
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
    public fun add_record_for_testing(
        self: &mut SuiNS, domain_name: String, clock: &Clock, ctx: &mut TxContext
    ): RegistrationNFT {
        let registry = registry_mut<Registry, Test>(self, Test {});
        registry::add_record(registry, domain::new(domain_name), 1, clock, ctx)
    }
}
