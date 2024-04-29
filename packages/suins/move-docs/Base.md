# Base Architecture

The base architecture of the SuiNS application features the central object - SuiNS, which manages main two tables with records: map between a domain name and a matching NameRecord; and a reverse registry to lookup a default domain for an address.

> For the sake of discoverability we keep reverse registry centralized to allow for reverse domain lookup and having a single `domain` for an `address`.

## Flow

The only way to acquire a SuiNS record is participating in the Auction. The auction module is a simple bidding - the highest bidder wins.

> We also preserve a way to reserve domains by the admin. Functionality for it is stored in the `admin.move`.

## Modularity

To preserve extendability and a chance to upgrade, we followed the following principles.

### Configuration

All configuration objects are attached as dynamic fields. Functions that access them don't have a strict function signature and are, instead, generic. Each of the applications can import and use the correct type in getters. This way whenever we decide to upgrade the Config, we can as well upgrade all calls to the config - they happen in function bodies.
```rust
// Bad
public fun get_config(SuiNS): Config {}

// Good
public fun get_config<Config: store + drop>(SuiNS): Config {}
```

Not only we provide flexibility by avoiding type mentions in function signatures but also allow for different configurations attached via the same interface.

### App Authorization

SuiNS has a set of protected and heavily guarded methods, such as the `app_add_record` which creates a new record and a matching `RegistrationNFT`. These methods are the core functionality of the SuiNS - adding new records is what the application does - hence, we need to protected them.

Given that we chose a way of a centralized storage over sharding the state into separate objects, dynamic ways of authorization (each application holds an "AppCapability") are impossible. An Auction module is not a separate object, it has no state and cannot hold an authorization object. However, the need of limiting the functionality is still there, and while we cannot provide dynamic authorization, we can use *static* - the Witness pattern. We still can register authorized witnesses in the main SuiNS object so that every application module (eg Auction) can define its own witness type.

```rust
module suins::auction {
    /// The witness type
    struct App has drop {}
}

module suins::suins {
    /// Dynamically enable a Witness of a certain application, such as
    /// `suins::auction::App` so that they get access to protected calls.
    public fun authorize_app<App: drop>(AdminCap, SuiNS) {}

    /// Only authorized applications can call this functions by passing
    /// the App Witness
    public fun protected_call<App: drop>(_: App, /* ... */) {}
}
```

## Domain renewal

By default each `RegistrationNFT` acquired by winning the Auction is valid for 1 year. After one year and a grace period (30 days) NFTs become invalid. To renew the domain, one needs to call the `renew` function and pay the price for the renewal.

> Application config stores base prices for the Auction as well as the price for the renewal of the domain.
