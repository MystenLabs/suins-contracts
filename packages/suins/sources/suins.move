// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// The main module of the SuiNS application, defines the `SuiNS` object and
/// the authorization mechanism for interacting with the main data storage.
///
/// Authorization mechanic:
/// The Admin can authorize applications to access protected features of the
/// SuiNS, they're named with a prefix `app_*`. Once authorized, application can
/// get mutable access to the `Registry` and add to the application `Balance`.
///
/// At any moment any of the applications can be deathorized by the Admin
/// making it impossible for the deauthorized module to access the registry.
/// ---
/// Package Upgrades in mind:
/// - None of the public functions of the SuiNS feature any specific types -
/// instead we use generics to define the actual types in arbitrary modules.
/// - The `Registry` itself (the main feature of the application) is stored as
/// a dynamic field so that we can change the type and the module that serves
/// the registry without breaking the SuiNS compatibility.
/// - Any of the old modules can be deauthorized hence disabling its access to
/// the registry and the balance.
module suins::suins {
    use sui::{balance::{Self, Balance}, coin::{Self, Coin}, dynamic_field as df, sui::SUI};

    /// Trying to withdraw from an empty balance.
    const ENoProfits: u64 = 0;
    /// An application is not authorized to access the feature.
    const EAppNotAuthorized: u64 = 1;

    /// An admin capability. The admin has full control over the application.
    /// This object must be issued only once during module initialization.
    public struct AdminCap has key, store { id: UID }

    /// The main application object. Stores the state of the application,
    /// used for adding / removing and reading name records.
    ///
    /// Dynamic fields:
    /// - `registry: RegistryKey<R> -> R`
    /// - `config: ConfigKey<C> -> C`
    public struct SuiNS has key {
        id: UID,
        /// The total balance of the SuiNS. Can be added to by authorized apps.
        /// Can be withdrawn only by the application Admin.
        balance: Balance<SUI>,
    }

    /// The one-time-witness used to claim Publisher object.
    public struct SUINS has drop {}

    // === Keys ===

    /// Key under which a configuration is stored. It is type dependent, so
    /// that different configurations can be stored at the same time. Eg
    /// currently we store application `Config` (and `Promotion` configuration).
    public struct ConfigKey<phantom Config> has copy, store, drop {}

    /// Key under which the Registry object is stored.
    ///
    /// In the V1, the object stored under this key is `Registry`, however, for
    /// future migration purposes (if we ever need to change the Registry), we
    /// keep the phantom parameter so two different Registries can co-exist.
    public struct RegistryKey<phantom Config> has copy, store, drop {}

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
        let amount = self.balance.value();
        assert!(amount > 0, ENoProfits);
        coin::take(&mut self.balance, amount, ctx)
    }

    // === App Auth ===

    /// An authorization Key kept in the SuiNS - allows applications access
    /// protected features of the SuiNS (such as app_add_balance, etc.)
    /// The `App` type parameter is a witness which should be defined in the
    /// original module (Controller, Registry, Registrar - whatever).
    public struct AppKey<phantom App: drop> has copy, store, drop {}

    /// Authorize an application to access protected features of the SuiNS.
    public fun authorize_app<App: drop>(_: &AdminCap, self: &mut SuiNS) {
        df::add(&mut self.id, AppKey<App>{}, true);
    }

    /// Deauthorize an application by removing its authorization key.
    public fun deauthorize_app<App: drop>(_: &AdminCap, self: &mut SuiNS): bool {
        df::remove(&mut self.id, AppKey<App>{})
    }

    /// Check if an application is authorized to access protected features of
    /// the SuiNS.
    public fun is_app_authorized<App: drop>(self: &SuiNS): bool {
        df::exists_(&self.id, AppKey<App>{})
    }

    /// Assert that an application is authorized to access protected features of
    /// the SuiNS. Aborts with `EAppNotAuthorized` if not.
    public fun assert_app_is_authorized<App: drop>(self: &SuiNS) {
        assert!(is_app_authorized<App>(self), EAppNotAuthorized);
    }

    // === Protected features ===

    /// Adds balance to the SuiNS.
    public fun app_add_balance<App: drop>(_: App, self: &mut SuiNS, balance: Balance<SUI>) {
        assert_app_is_authorized<App>(self);
        self.balance.join(balance);
    }

    /// Get a mutable access to the `Registry` object. Can only be performed by authorized
    /// applications.
    public fun app_registry_mut<App: drop, R: store>(_: App, self: &mut SuiNS): &mut R {
        assert_app_is_authorized<App>(self);
        df::borrow_mut(&mut self.id, RegistryKey<R> {})
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

    /// Get a read-only access to the `Registry` object.
    public fun registry<R: store>(self: &SuiNS): &R {
        df::borrow(&self.id, RegistryKey<R> {})
    }

    /// Add a registry to the SuiNS. Can only be performed by the admin.
    public fun add_registry<R: store>(_: &AdminCap, self: &mut SuiNS, registry: R) {
        df::add(&mut self.id, RegistryKey<R> {}, registry);
    }

    // === Testing ===

    #[test_only] use suins::config;
    #[test_only] public struct Test has drop {}

    #[test_only]
    public fun new_for_testing(ctx: &mut TxContext): (SuiNS, AdminCap) {
        (
            SuiNS { id: object::new(ctx), balance: balance::zero() },
            AdminCap { id: object::new(ctx) }
        )
    }

    #[test_only]
    /// Wrapper of module initializer for testing
    public fun init_for_testing(ctx: &mut TxContext): SuiNS {
        let admin_cap = AdminCap { id: object::new(ctx) };
        let mut suins = SuiNS {
            id: object::new(ctx),
            balance: balance::zero(),
        };

        authorize_app<Test>(&admin_cap, &mut suins);
        add_config(&admin_cap, &mut suins, config::new(
            b"000000000000000000000000000000000",
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
    /// Create an admin cap - only for testing.
    public fun create_admin_cap_for_testing(ctx: &mut TxContext): AdminCap {
        AdminCap { id: object::new(ctx) }
    }

    #[test_only]
    /// Burn the admin cap - only for testing.
    public fun burn_admin_cap_for_testing(admin_cap: AdminCap) {
        let AdminCap { id } = admin_cap;
        id.delete();
    }

    #[test_only]
    public fun authorize_app_for_testing<App: drop>(self: &mut SuiNS) {
        df::add(&mut self.id, AppKey<App> {}, true)
    }

    #[test_only]
    public fun total_balance(self: &SuiNS): u64 {
        self.balance.value()
    }
}
