
<a name="0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins"></a>

# Module `0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b::suins`

The main module of the SuiNS application, defines the <code><a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_SuiNS">SuiNS</a></code> object and
the authorization mechanism for interacting with the main data storage.

Authorization mechanic:
The Admin can authorize applications to access protected features of the
SuiNS, they're named with a prefix <code>app_*</code>. Once authorized, application can
get mutable access to the <code>Registry</code> and add to the application <code>Balance</code>.

At any moment any of the applications can be deathorized by the Admin
making it impossible for the deauthorized module to access the registry.
---
Package Upgrades in mind:
- None of the public functions of the SuiNS feature any specific types -
instead we use generics to define the actual types in arbitrary modules.
- The <code>Registry</code> itself (the main feature of the application) is stored as
a dynamic field so that we can change the type and the module that serves
the registry without breaking the SuiNS compatibility.
- Any of the old modules can be deauthorized hence disabling its access to
the registry and the balance.


-  [Resource `AdminCap`](#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_AdminCap)
-  [Resource `SuiNS`](#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_SuiNS)
-  [Struct `SUINS`](#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_SUINS)
-  [Struct `ConfigKey`](#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_ConfigKey)
-  [Struct `RegistryKey`](#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_RegistryKey)
-  [Struct `AppKey`](#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_AppKey)
-  [Constants](#@Constants_0)
-  [Function `init`](#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_init)
-  [Function `withdraw`](#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_withdraw)
-  [Function `authorize_app`](#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_authorize_app)
-  [Function `deauthorize_app`](#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_deauthorize_app)
-  [Function `is_app_authorized`](#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_is_app_authorized)
-  [Function `assert_app_is_authorized`](#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_assert_app_is_authorized)
-  [Function `app_add_balance`](#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_app_add_balance)
-  [Function `app_registry_mut`](#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_app_registry_mut)
-  [Function `add_config`](#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_add_config)
-  [Function `get_config`](#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_get_config)
-  [Function `remove_config`](#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_remove_config)
-  [Function `registry`](#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registry)
-  [Function `add_registry`](#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_add_registry)


<pre><code><b>use</b> <a href="dependencies/sui-framework/balance.md#0x2_balance">0x2::balance</a>;
<b>use</b> <a href="dependencies/sui-framework/coin.md#0x2_coin">0x2::coin</a>;
<b>use</b> <a href="dependencies/sui-framework/dynamic_field.md#0x2_dynamic_field">0x2::dynamic_field</a>;
<b>use</b> <a href="dependencies/sui-framework/object.md#0x2_object">0x2::object</a>;
<b>use</b> <a href="dependencies/sui-framework/package.md#0x2_package">0x2::package</a>;
<b>use</b> <a href="dependencies/sui-framework/sui.md#0x2_sui">0x2::sui</a>;
<b>use</b> <a href="dependencies/sui-framework/transfer.md#0x2_transfer">0x2::transfer</a>;
<b>use</b> <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context">0x2::tx_context</a>;
</code></pre>



<a name="0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_AdminCap"></a>

## Resource `AdminCap`

An admin capability. The admin has full control over the application.
This object must be issued only once during module initialization.


<pre><code><b>struct</b> <a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_AdminCap">AdminCap</a> <b>has</b> store, key
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>id: <a href="dependencies/sui-framework/object.md#0x2_object_UID">object::UID</a></code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_SuiNS"></a>

## Resource `SuiNS`

The main application object. Stores the state of the application,
used for adding / removing and reading name records.

Dynamic fields:
- <code><a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry">registry</a>: <a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_RegistryKey">RegistryKey</a>&lt;R&gt; -&gt; R</code>
- <code><a href="config.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_config">config</a>: <a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_ConfigKey">ConfigKey</a>&lt;C&gt; -&gt; C</code>


<pre><code><b>struct</b> <a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_SuiNS">SuiNS</a> <b>has</b> key
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>id: <a href="dependencies/sui-framework/object.md#0x2_object_UID">object::UID</a></code>
</dt>
<dd>

</dd>
<dt>
<code><a href="dependencies/sui-framework/balance.md#0x2_balance">balance</a>: <a href="dependencies/sui-framework/balance.md#0x2_balance_Balance">balance::Balance</a>&lt;<a href="dependencies/sui-framework/sui.md#0x2_sui_SUI">sui::SUI</a>&gt;</code>
</dt>
<dd>
 The total balance of the SuiNS. Can be added to by authorized apps.
 Can be withdrawn only by the application Admin.
</dd>
</dl>


</details>

<a name="0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_SUINS"></a>

## Struct `SUINS`

The one-time-witness used to claim Publisher object.


<pre><code><b>struct</b> <a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_SUINS">SUINS</a> <b>has</b> drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>dummy_field: bool</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_ConfigKey"></a>

## Struct `ConfigKey`

Key under which a configuration is stored. It is type dependent, so
that different configurations can be stored at the same time. Eg
currently we store application <code>Config</code> (and <code>Promotion</code> configuration).


<pre><code><b>struct</b> <a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_ConfigKey">ConfigKey</a>&lt;Config&gt; <b>has</b> <b>copy</b>, drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>dummy_field: bool</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_RegistryKey"></a>

## Struct `RegistryKey`

Key under which the Registry object is stored.

In the V1, the object stored under this key is <code>Registry</code>, however, for
future migration purposes (if we ever need to change the Registry), we
keep the phantom parameter so two different Registries can co-exist.


<pre><code><b>struct</b> <a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_RegistryKey">RegistryKey</a>&lt;Config&gt; <b>has</b> <b>copy</b>, drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>dummy_field: bool</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_AppKey"></a>

## Struct `AppKey`

An authorization Key kept in the SuiNS - allows applications access
protected features of the SuiNS (such as app_add_balance, etc.)
The <code>App</code> type parameter is a witness which should be defined in the
original module (Controller, Registry, Registrar - whatever).


<pre><code><b>struct</b> <a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_AppKey">AppKey</a>&lt;App: drop&gt; <b>has</b> <b>copy</b>, drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>dummy_field: bool</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="@Constants_0"></a>

## Constants


<a name="0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_EAppNotAuthorized"></a>

An application is not authorized to access the feature.


<pre><code><b>const</b> <a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_EAppNotAuthorized">EAppNotAuthorized</a>: u64 = 1;
</code></pre>



<a name="0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_ENoProfits"></a>

Trying to withdraw from an empty balance.


<pre><code><b>const</b> <a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_ENoProfits">ENoProfits</a>: u64 = 0;
</code></pre>



<a name="0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_init"></a>

## Function `init`

Module initializer:
- create SuiNS object
- create admin capability
- claim Publisher object (for Display and TransferPolicy)


<pre><code><b>fun</b> <a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_init">init</a>(otw: <a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_SUINS">suins::SUINS</a>, ctx: &<b>mut</b> <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_init">init</a>(otw: <a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_SUINS">SUINS</a>, ctx: &<b>mut</b> TxContext) {
    sui::package::claim_and_keep(otw, ctx);

    // Create the <a href="admin.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_admin">admin</a> capability; only performed once.
    <a href="dependencies/sui-framework/transfer.md#0x2_transfer_transfer">transfer::transfer</a>(<a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_AdminCap">AdminCap</a> {
        id: <a href="dependencies/sui-framework/object.md#0x2_object_new">object::new</a>(ctx),
    }, <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context_sender">tx_context::sender</a>(ctx));

    <b>let</b> <a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a> = <a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_SuiNS">SuiNS</a> {
        id: <a href="dependencies/sui-framework/object.md#0x2_object_new">object::new</a>(ctx),
        <a href="dependencies/sui-framework/balance.md#0x2_balance">balance</a>: <a href="dependencies/sui-framework/balance.md#0x2_balance_zero">balance::zero</a>(),
    };

    <a href="dependencies/sui-framework/transfer.md#0x2_transfer_share_object">transfer::share_object</a>(<a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>);
}
</code></pre>



</details>

<a name="0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_withdraw"></a>

## Function `withdraw`

Withdraw from the SuiNS balance directly and access the Coins within the same
transaction. This is useful for the admin to withdraw funds from the SuiNS
and then send them somewhere specific or keep at the address.


<pre><code><b>public</b> <b>fun</b> <a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_withdraw">withdraw</a>(_: &<a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_AdminCap">suins::AdminCap</a>, self: &<b>mut</b> <a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_SuiNS">suins::SuiNS</a>, ctx: &<b>mut</b> <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context_TxContext">tx_context::TxContext</a>): <a href="dependencies/sui-framework/coin.md#0x2_coin_Coin">coin::Coin</a>&lt;<a href="dependencies/sui-framework/sui.md#0x2_sui_SUI">sui::SUI</a>&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_withdraw">withdraw</a>(_: &<a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_AdminCap">AdminCap</a>, self: &<b>mut</b> <a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_SuiNS">SuiNS</a>, ctx: &<b>mut</b> TxContext): Coin&lt;SUI&gt; {
    <b>let</b> amount = self.<a href="dependencies/sui-framework/balance.md#0x2_balance">balance</a>.value();
    <b>assert</b>!(amount &gt; 0, <a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_ENoProfits">ENoProfits</a>);
    <a href="dependencies/sui-framework/coin.md#0x2_coin_take">coin::take</a>(&<b>mut</b> self.<a href="dependencies/sui-framework/balance.md#0x2_balance">balance</a>, amount, ctx)
}
</code></pre>



</details>

<a name="0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_authorize_app"></a>

## Function `authorize_app`

Authorize an application to access protected features of the SuiNS.


<pre><code><b>public</b> <b>fun</b> <a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_authorize_app">authorize_app</a>&lt;App: drop&gt;(_: &<a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_AdminCap">suins::AdminCap</a>, self: &<b>mut</b> <a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_SuiNS">suins::SuiNS</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_authorize_app">authorize_app</a>&lt;App: drop&gt;(_: &<a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_AdminCap">AdminCap</a>, self: &<b>mut</b> <a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_SuiNS">SuiNS</a>) {
    df::add(&<b>mut</b> self.id, <a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_AppKey">AppKey</a>&lt;App&gt;{}, <b>true</b>);
}
</code></pre>



</details>

<a name="0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_deauthorize_app"></a>

## Function `deauthorize_app`

Deauthorize an application by removing its authorization key.


<pre><code><b>public</b> <b>fun</b> <a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_deauthorize_app">deauthorize_app</a>&lt;App: drop&gt;(_: &<a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_AdminCap">suins::AdminCap</a>, self: &<b>mut</b> <a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_SuiNS">suins::SuiNS</a>): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_deauthorize_app">deauthorize_app</a>&lt;App: drop&gt;(_: &<a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_AdminCap">AdminCap</a>, self: &<b>mut</b> <a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_SuiNS">SuiNS</a>): bool {
    df::remove(&<b>mut</b> self.id, <a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_AppKey">AppKey</a>&lt;App&gt;{})
}
</code></pre>



</details>

<a name="0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_is_app_authorized"></a>

## Function `is_app_authorized`

Check if an application is authorized to access protected features of
the SuiNS.


<pre><code><b>public</b> <b>fun</b> <a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_is_app_authorized">is_app_authorized</a>&lt;App: drop&gt;(self: &<a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_SuiNS">suins::SuiNS</a>): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_is_app_authorized">is_app_authorized</a>&lt;App: drop&gt;(self: &<a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_SuiNS">SuiNS</a>): bool {
    df::exists_(&self.id, <a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_AppKey">AppKey</a>&lt;App&gt;{})
}
</code></pre>



</details>

<a name="0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_assert_app_is_authorized"></a>

## Function `assert_app_is_authorized`

Assert that an application is authorized to access protected features of
the SuiNS. Aborts with <code><a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_EAppNotAuthorized">EAppNotAuthorized</a></code> if not.


<pre><code><b>public</b> <b>fun</b> <a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_assert_app_is_authorized">assert_app_is_authorized</a>&lt;App: drop&gt;(self: &<a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_SuiNS">suins::SuiNS</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_assert_app_is_authorized">assert_app_is_authorized</a>&lt;App: drop&gt;(self: &<a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_SuiNS">SuiNS</a>) {
    <b>assert</b>!(<a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_is_app_authorized">is_app_authorized</a>&lt;App&gt;(self), <a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_EAppNotAuthorized">EAppNotAuthorized</a>);
}
</code></pre>



</details>

<a name="0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_app_add_balance"></a>

## Function `app_add_balance`

Adds balance to the SuiNS.


<pre><code><b>public</b> <b>fun</b> <a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_app_add_balance">app_add_balance</a>&lt;App: drop&gt;(_: App, self: &<b>mut</b> <a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_SuiNS">suins::SuiNS</a>, <a href="dependencies/sui-framework/balance.md#0x2_balance">balance</a>: <a href="dependencies/sui-framework/balance.md#0x2_balance_Balance">balance::Balance</a>&lt;<a href="dependencies/sui-framework/sui.md#0x2_sui_SUI">sui::SUI</a>&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_app_add_balance">app_add_balance</a>&lt;App: drop&gt;(_: App, self: &<b>mut</b> <a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_SuiNS">SuiNS</a>, <a href="dependencies/sui-framework/balance.md#0x2_balance">balance</a>: Balance&lt;SUI&gt;) {
    <a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_assert_app_is_authorized">assert_app_is_authorized</a>&lt;App&gt;(self);
    self.<a href="dependencies/sui-framework/balance.md#0x2_balance">balance</a>.join(<a href="dependencies/sui-framework/balance.md#0x2_balance">balance</a>);
}
</code></pre>



</details>

<a name="0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_app_registry_mut"></a>

## Function `app_registry_mut`

Get a mutable access to the <code>Registry</code> object. Can only be performed by authorized
applications.


<pre><code><b>public</b> <b>fun</b> <a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_app_registry_mut">app_registry_mut</a>&lt;App: drop, R: store&gt;(_: App, self: &<b>mut</b> <a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_SuiNS">suins::SuiNS</a>): &<b>mut</b> R
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_app_registry_mut">app_registry_mut</a>&lt;App: drop, R: store&gt;(_: App, self: &<b>mut</b> <a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_SuiNS">SuiNS</a>): &<b>mut</b> R {
    <a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_assert_app_is_authorized">assert_app_is_authorized</a>&lt;App&gt;(self);
    df::borrow_mut(&<b>mut</b> self.id, <a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_RegistryKey">RegistryKey</a>&lt;R&gt; {})
}
</code></pre>



</details>

<a name="0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_add_config"></a>

## Function `add_config`

Attach dynamic configuration object to the application.


<pre><code><b>public</b> <b>fun</b> <a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_add_config">add_config</a>&lt;Config: drop, store&gt;(_: &<a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_AdminCap">suins::AdminCap</a>, self: &<b>mut</b> <a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_SuiNS">suins::SuiNS</a>, <a href="config.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_config">config</a>: Config)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_add_config">add_config</a>&lt;Config: store + drop&gt;(_: &<a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_AdminCap">AdminCap</a>, self: &<b>mut</b> <a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_SuiNS">SuiNS</a>, <a href="config.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_config">config</a>: Config) {
    df::add(&<b>mut</b> self.id, <a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_ConfigKey">ConfigKey</a>&lt;Config&gt; {}, <a href="config.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_config">config</a>);
}
</code></pre>



</details>

<a name="0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_get_config"></a>

## Function `get_config`

Borrow configuration object. Read-only mode for applications.


<pre><code><b>public</b> <b>fun</b> <a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_get_config">get_config</a>&lt;Config: drop, store&gt;(self: &<a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_SuiNS">suins::SuiNS</a>): &Config
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_get_config">get_config</a>&lt;Config: store + drop&gt;(self: &<a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_SuiNS">SuiNS</a>): &Config {
    df::borrow(&self.id, <a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_ConfigKey">ConfigKey</a>&lt;Config&gt; {})
}
</code></pre>



</details>

<a name="0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_remove_config"></a>

## Function `remove_config`

Get the configuration object for editing. The admin should put it back
after editing (no extra check performed). Can be used to swap
configuration since the <code>T</code> has <code>drop</code>. Eg nothing is stopping the admin
from removing the configuration object and adding a new one.

Fully taking the config also allows for edits within a transaction.


<pre><code><b>public</b> <b>fun</b> <a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_remove_config">remove_config</a>&lt;Config: drop, store&gt;(_: &<a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_AdminCap">suins::AdminCap</a>, self: &<b>mut</b> <a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_SuiNS">suins::SuiNS</a>): Config
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_remove_config">remove_config</a>&lt;Config: store + drop&gt;(_: &<a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_AdminCap">AdminCap</a>, self: &<b>mut</b> <a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_SuiNS">SuiNS</a>): Config {
    df::remove(&<b>mut</b> self.id, <a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_ConfigKey">ConfigKey</a>&lt;Config&gt; {})
}
</code></pre>



</details>

<a name="0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registry"></a>

## Function `registry`

Get a read-only access to the <code>Registry</code> object.


<pre><code><b>public</b> <b>fun</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry">registry</a>&lt;R: store&gt;(self: &<a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_SuiNS">suins::SuiNS</a>): &R
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry">registry</a>&lt;R: store&gt;(self: &<a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_SuiNS">SuiNS</a>): &R {
    df::borrow(&self.id, <a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_RegistryKey">RegistryKey</a>&lt;R&gt; {})
}
</code></pre>



</details>

<a name="0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_add_registry"></a>

## Function `add_registry`

Add a registry to the SuiNS. Can only be performed by the admin.


<pre><code><b>public</b> <b>fun</b> <a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_add_registry">add_registry</a>&lt;R: store&gt;(_: &<a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_AdminCap">suins::AdminCap</a>, self: &<b>mut</b> <a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_SuiNS">suins::SuiNS</a>, <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry">registry</a>: R)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_add_registry">add_registry</a>&lt;R: store&gt;(_: &<a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_AdminCap">AdminCap</a>, self: &<b>mut</b> <a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_SuiNS">SuiNS</a>, <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry">registry</a>: R) {
    df::add(&<b>mut</b> self.id, <a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_RegistryKey">RegistryKey</a>&lt;R&gt; {}, <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry">registry</a>);
}
</code></pre>



</details>
