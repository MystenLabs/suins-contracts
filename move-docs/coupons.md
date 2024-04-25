
<a name="0x0_coupons"></a>

# Module `0x0::coupons`

A module to support coupons for SuiNS.
This module allows secondary modules (e.g. Discord) to add or remove coupons too.
This allows for separation of logic & ease of de-authorization in case we don't want some functionality anymore.

Coupons are unique string codes, that can be used (based on the business rules) to claim discounts in the app.
Each coupon is validated towards a list of rules. View <code><a href="rules.md#0x0_rules">rules</a></code> module for explanation.
The app is authorized on <code>SuiNS</code> to be able to claim names and add earnings to the registry.


-  [Struct `CouponsApp`](#0x0_coupons_CouponsApp)
-  [Struct `AppKey`](#0x0_coupons_AppKey)
-  [Struct `Data`](#0x0_coupons_Data)
-  [Resource `CouponHouse`](#0x0_coupons_CouponHouse)
-  [Struct `Coupon`](#0x0_coupons_Coupon)
-  [Constants](#@Constants_0)
-  [Function `init`](#0x0_coupons_init)
-  [Function `register_with_coupon`](#0x0_coupons_register_with_coupon)
-  [Function `calculate_sale_price`](#0x0_coupons_calculate_sale_price)
-  [Function `app_data_mut`](#0x0_coupons_app_data_mut)
-  [Function `is_app_authorized`](#0x0_coupons_is_app_authorized)
-  [Function `assert_app_is_authorized`](#0x0_coupons_assert_app_is_authorized)
-  [Function `authorize_app`](#0x0_coupons_authorize_app)
-  [Function `deauthorize_app`](#0x0_coupons_deauthorize_app)
-  [Function `set_version`](#0x0_coupons_set_version)
-  [Function `assert_version_is_valid`](#0x0_coupons_assert_version_is_valid)
-  [Function `admin_add_coupon`](#0x0_coupons_admin_add_coupon)
-  [Function `admin_remove_coupon`](#0x0_coupons_admin_remove_coupon)
-  [Function `app_add_coupon`](#0x0_coupons_app_add_coupon)
-  [Function `app_remove_coupon`](#0x0_coupons_app_remove_coupon)
-  [Function `internal_calculate_sale_price`](#0x0_coupons_internal_calculate_sale_price)
-  [Function `internal_save_coupon`](#0x0_coupons_internal_save_coupon)
-  [Function `internal_create_coupon`](#0x0_coupons_internal_create_coupon)
-  [Function `internal_remove_coupon`](#0x0_coupons_internal_remove_coupon)


<pre><code><b>use</b> <a href="constants.md#0x0_constants">0x0::constants</a>;
<b>use</b> <a href="rules.md#0x0_rules">0x0::rules</a>;
<b>use</b> <a href="dependencies/move-stdlib/string.md#0x1_string">0x1::string</a>;
<b>use</b> <a href="dependencies/sui-framework/balance.md#0x2_balance">0x2::balance</a>;
<b>use</b> <a href="dependencies/sui-framework/clock.md#0x2_clock">0x2::clock</a>;
<b>use</b> <a href="dependencies/sui-framework/coin.md#0x2_coin">0x2::coin</a>;
<b>use</b> <a href="dependencies/sui-framework/dynamic_field.md#0x2_dynamic_field">0x2::dynamic_field</a>;
<b>use</b> <a href="dependencies/sui-framework/object.md#0x2_object">0x2::object</a>;
<b>use</b> <a href="dependencies/sui-framework/sui.md#0x2_sui">0x2::sui</a>;
<b>use</b> <a href="dependencies/sui-framework/table.md#0x2_table">0x2::table</a>;
<b>use</b> <a href="dependencies/sui-framework/transfer.md#0x2_transfer">0x2::transfer</a>;
<b>use</b> <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context">0x2::tx_context</a>;
<b>use</b> <a href="dependencies/suins/config.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_config">0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0::config</a>;
<b>use</b> <a href="dependencies/suins/domain.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_domain">0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0::domain</a>;
<b>use</b> <a href="dependencies/suins/registry.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_registry">0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0::registry</a>;
<b>use</b> <a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0::suins</a>;
<b>use</b> <a href="dependencies/suins/suins_registration.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins_registration">0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0::suins_registration</a>;
</code></pre>



<a name="0x0_coupons_CouponsApp"></a>

## Struct `CouponsApp`



<pre><code><b>struct</b> <a href="coupons.md#0x0_coupons_CouponsApp">CouponsApp</a> <b>has</b> drop
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

<a name="0x0_coupons_AppKey"></a>

## Struct `AppKey`

Authorization Key for secondary apps (e.g. Discord) connected to this module.


<pre><code><b>struct</b> <a href="coupons.md#0x0_coupons_AppKey">AppKey</a>&lt;App: drop&gt; <b>has</b> <b>copy</b>, drop, store
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

<a name="0x0_coupons_Data"></a>

## Struct `Data`

Create a <code><a href="coupons.md#0x0_coupons_Data">Data</a></code> struct that only authorized apps can get mutable access to.
We don't save the coupon's table directly on the shared object, because we want authorized apps to only perform
certain actions with the table (and not give full <code><b>mut</b></code> access to it).


<pre><code><b>struct</b> <a href="coupons.md#0x0_coupons_Data">Data</a> <b>has</b> store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code><a href="coupons.md#0x0_coupons">coupons</a>: <a href="dependencies/sui-framework/table.md#0x2_table_Table">table::Table</a>&lt;<a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>, <a href="coupons.md#0x0_coupons_Coupon">coupons::Coupon</a>&gt;</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0x0_coupons_CouponHouse"></a>

## Resource `CouponHouse`

The CouponHouse Shared Object which holds a table of coupon codes available for claim.


<pre><code><b>struct</b> <a href="coupons.md#0x0_coupons_CouponHouse">CouponHouse</a> <b>has</b> store, key
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
<code>data: <a href="coupons.md#0x0_coupons_Data">coupons::Data</a></code>
</dt>
<dd>

</dd>
<dt>
<code>version: u8</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0x0_coupons_Coupon"></a>

## Struct `Coupon`

A Coupon has a type, a value and a ruleset.
- <code>Rules</code> are defined on the module <code><a href="rules.md#0x0_rules">rules</a></code>, and covers a variety of everything we needed for the service.
- <code>type</code> is a u8 constant, defined on <code><a href="dependencies/suins/constants.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_constants">constants</a></code> which makes a coupon fixed price or discount percentage
- <code>value</code> is a u64 constant, which can be in the range of (0,100] for discount percentage, or any value > 0 for fixed price.


<pre><code><b>struct</b> <a href="coupons.md#0x0_coupons_Coupon">Coupon</a> <b>has</b> <b>copy</b>, drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>type: u8</code>
</dt>
<dd>

</dd>
<dt>
<code>amount: u64</code>
</dt>
<dd>

</dd>
<dt>
<code><a href="rules.md#0x0_rules">rules</a>: <a href="rules.md#0x0_rules_CouponRules">rules::CouponRules</a></code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="@Constants_0"></a>

## Constants


<a name="0x0_coupons_EAppNotAuthorized"></a>

An app that's not authorized tries to access private data.


<pre><code><b>const</b> <a href="coupons.md#0x0_coupons_EAppNotAuthorized">EAppNotAuthorized</a>: u64 = 1;
</code></pre>



<a name="0x0_coupons_ECouponAlreadyExists"></a>

Coupon already exists


<pre><code><b>const</b> <a href="coupons.md#0x0_coupons_ECouponAlreadyExists">ECouponAlreadyExists</a>: u64 = 0;
</code></pre>



<a name="0x0_coupons_ECouponNotExists"></a>

Coupon doesn't exist.


<pre><code><b>const</b> <a href="coupons.md#0x0_coupons_ECouponNotExists">ECouponNotExists</a>: u64 = 5;
</code></pre>



<a name="0x0_coupons_EIncorrectAmount"></a>

The payment does not match the price for the domain.


<pre><code><b>const</b> <a href="coupons.md#0x0_coupons_EIncorrectAmount">EIncorrectAmount</a>: u64 = 4;
</code></pre>



<a name="0x0_coupons_EInvalidVersion"></a>

Tries to use app on an invalid version.


<pre><code><b>const</b> <a href="coupons.md#0x0_coupons_EInvalidVersion">EInvalidVersion</a>: u64 = 2;
</code></pre>



<a name="0x0_coupons_EInvalidYearsArgument"></a>

These errors are claim errors.
Number of years passed is not within [1-5] interval.


<pre><code><b>const</b> <a href="coupons.md#0x0_coupons_EInvalidYearsArgument">EInvalidYearsArgument</a>: u64 = 3;
</code></pre>



<a name="0x0_coupons_VERSION"></a>

Our versioning of the coupons package.


<pre><code><b>const</b> <a href="coupons.md#0x0_coupons_VERSION">VERSION</a>: u8 = 1;
</code></pre>



<a name="0x0_coupons_init"></a>

## Function `init`



<pre><code><b>fun</b> <a href="coupons.md#0x0_coupons_init">init</a>(ctx: &<b>mut</b> <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="coupons.md#0x0_coupons_init">init</a>(ctx: &<b>mut</b> TxContext){
    <a href="dependencies/sui-framework/transfer.md#0x2_transfer_share_object">transfer::share_object</a>(<a href="coupons.md#0x0_coupons_CouponHouse">CouponHouse</a> {
        id: <a href="dependencies/sui-framework/object.md#0x2_object_new">object::new</a>(ctx),
        data: <a href="coupons.md#0x0_coupons_Data">Data</a> { <a href="coupons.md#0x0_coupons">coupons</a>: <a href="dependencies/sui-framework/table.md#0x2_table_new">table::new</a>(ctx) },
        version: <a href="coupons.md#0x0_coupons_VERSION">VERSION</a>
    });
}
</code></pre>



</details>

<a name="0x0_coupons_register_with_coupon"></a>

## Function `register_with_coupon`

Register a name using a coupon code.


<pre><code><b>public</b> <b>fun</b> <a href="coupons.md#0x0_coupons_register_with_coupon">register_with_coupon</a>(self: &<b>mut</b> <a href="coupons.md#0x0_coupons_CouponHouse">coupons::CouponHouse</a>, <a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>: &<b>mut</b> <a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins_SuiNS">suins::SuiNS</a>, coupon_code: <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>, domain_name: <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>, no_years: u8, payment: <a href="dependencies/sui-framework/coin.md#0x2_coin_Coin">coin::Coin</a>&lt;<a href="dependencies/sui-framework/sui.md#0x2_sui_SUI">sui::SUI</a>&gt;, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &<a href="dependencies/sui-framework/clock.md#0x2_clock_Clock">clock::Clock</a>, ctx: &<b>mut</b> <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context_TxContext">tx_context::TxContext</a>): <a href="dependencies/suins/suins_registration.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins_registration_SuinsRegistration">suins_registration::SuinsRegistration</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="coupons.md#0x0_coupons_register_with_coupon">register_with_coupon</a>(
    self: &<b>mut</b> <a href="coupons.md#0x0_coupons_CouponHouse">CouponHouse</a>,
    <a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>: &<b>mut</b> SuiNS,
    coupon_code: String,
    domain_name: String,
    no_years: u8,
    payment: Coin&lt;SUI&gt;,
    <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &Clock,
    ctx: &<b>mut</b> TxContext
): SuinsRegistration {
    self.<a href="coupons.md#0x0_coupons_assert_version_is_valid">assert_version_is_valid</a>();
    // Validate that specified coupon is valid.
    <b>assert</b>!(self.data.<a href="coupons.md#0x0_coupons">coupons</a>.contains(coupon_code), <a href="coupons.md#0x0_coupons_ECouponNotExists">ECouponNotExists</a>);

    // Verify coupon house is authorized <b>to</b> buy names.
    <a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>.<a href="coupons.md#0x0_coupons_assert_app_is_authorized">assert_app_is_authorized</a>&lt;<a href="coupons.md#0x0_coupons_CouponsApp">CouponsApp</a>&gt;();

    // Validate registration years are in [0,5] <a href="range.md#0x0_range">range</a>.
    <b>assert</b>!(no_years &gt; 0 && no_years &lt;= 5, <a href="coupons.md#0x0_coupons_EInvalidYearsArgument">EInvalidYearsArgument</a>);

    <b>let</b> <a href="dependencies/suins/config.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_config">config</a> = <a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>.get_config();
    <b>let</b> <a href="dependencies/suins/domain.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_domain">domain</a> = <a href="dependencies/suins/domain.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_domain_new">domain::new</a>(domain_name);
    <b>let</b> label = <a href="dependencies/suins/domain.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_domain">domain</a>.sld();

    <b>let</b> domain_length = (label.length() <b>as</b> u8);

    // Borrow coupon from the <a href="dependencies/sui-framework/table.md#0x2_table">table</a>.
    <b>let</b> coupon = &<b>mut</b> self.data.<a href="coupons.md#0x0_coupons">coupons</a>[coupon_code];

    // We need <b>to</b> do a total of 5 checks, based on `CouponRules`
    // Our checks work <b>with</b> `AND`, all of the conditions must pass for a coupon <b>to</b> be used.
    // 1. Validate <a href="dependencies/suins/domain.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_domain">domain</a> size.
    coupon.<a href="rules.md#0x0_rules">rules</a>.assert_coupon_valid_for_domain_size(domain_length);
    // 2. Decrease available claims. Will ABORT <b>if</b> the coupon doesn't have enough available claims.
    coupon.<a href="rules.md#0x0_rules">rules</a>.decrease_available_claims();
    // 3. Validate the coupon is valid for the specified user.
    coupon.<a href="rules.md#0x0_rules">rules</a>.assert_coupon_valid_for_address(ctx.sender());
    // 4. Validate the coupon hasn't expired (Based on <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>)
    coupon.<a href="rules.md#0x0_rules">rules</a>.assert_coupon_is_not_expired(<a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>);
    // 5. Validate years are valid for the coupon.
    coupon.<a href="rules.md#0x0_rules">rules</a>.assert_coupon_valid_for_domain_years(no_years);

    // Validate name can be registered (is main <a href="dependencies/suins/domain.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_domain">domain</a> (no subdomain) and length is valid)
    <a href="dependencies/suins/config.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_config_assert_valid_user_registerable_domain">config::assert_valid_user_registerable_domain</a>(&<a href="dependencies/suins/domain.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_domain">domain</a>);

    <b>let</b> original_price = <a href="dependencies/suins/config.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_config_calculate_price">config::calculate_price</a>(<a href="dependencies/suins/config.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_config">config</a>, domain_length, no_years);
    <b>let</b> sale_price = <a href="coupons.md#0x0_coupons_internal_calculate_sale_price">internal_calculate_sale_price</a>(original_price, coupon);

    <b>assert</b>!(payment.value() == sale_price, <a href="coupons.md#0x0_coupons_EIncorrectAmount">EIncorrectAmount</a>);
    <a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins_app_add_balance">suins::app_add_balance</a>(<a href="coupons.md#0x0_coupons_CouponsApp">CouponsApp</a> {}, <a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>, payment.into_balance());

    // Clean up our <a href="dependencies/suins/registry.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_registry">registry</a> by removing the coupon <b>if</b> no more available claims!
    <b>if</b>(!coupon.<a href="rules.md#0x0_rules">rules</a>.has_available_claims()){
        // remove the coupon, since it's no longer usable.
        self.data.<a href="coupons.md#0x0_coupons_internal_remove_coupon">internal_remove_coupon</a>(coupon_code);
    };

    <b>let</b> <a href="dependencies/suins/registry.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_registry">registry</a> = <a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins_app_registry_mut">suins::app_registry_mut</a>&lt;<a href="coupons.md#0x0_coupons_CouponsApp">CouponsApp</a>, Registry&gt;(<a href="coupons.md#0x0_coupons_CouponsApp">CouponsApp</a> {}, <a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>);
    <a href="dependencies/suins/registry.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_registry">registry</a>.add_record(<a href="dependencies/suins/domain.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_domain">domain</a>, no_years, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>, ctx)
}
</code></pre>



</details>

<a name="0x0_coupons_calculate_sale_price"></a>

## Function `calculate_sale_price`



<pre><code><b>public</b> <b>fun</b> <a href="coupons.md#0x0_coupons_calculate_sale_price">calculate_sale_price</a>(self: &<b>mut</b> <a href="coupons.md#0x0_coupons_CouponHouse">coupons::CouponHouse</a>, price: u64, coupon_code: <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="coupons.md#0x0_coupons_calculate_sale_price">calculate_sale_price</a>(self: &<b>mut</b> <a href="coupons.md#0x0_coupons_CouponHouse">CouponHouse</a>, price: u64, coupon_code: String): u64 {
    // Validate that specified coupon is valid.
    <b>assert</b>!(self.data.<a href="coupons.md#0x0_coupons">coupons</a>.contains(coupon_code), <a href="coupons.md#0x0_coupons_ECouponNotExists">ECouponNotExists</a>);
    // Borrow coupon from the <a href="dependencies/sui-framework/table.md#0x2_table">table</a>.
    <b>let</b> coupon = &<b>mut</b> self.data.<a href="coupons.md#0x0_coupons">coupons</a>[coupon_code];
    <a href="coupons.md#0x0_coupons_internal_calculate_sale_price">internal_calculate_sale_price</a>(price, coupon)
}
</code></pre>



</details>

<a name="0x0_coupons_app_data_mut"></a>

## Function `app_data_mut`



<pre><code><b>public</b> <b>fun</b> <a href="coupons.md#0x0_coupons_app_data_mut">app_data_mut</a>&lt;App: drop&gt;(_: App, self: &<b>mut</b> <a href="coupons.md#0x0_coupons_CouponHouse">coupons::CouponHouse</a>): &<b>mut</b> <a href="coupons.md#0x0_coupons_Data">coupons::Data</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="coupons.md#0x0_coupons_app_data_mut">app_data_mut</a>&lt;App: drop&gt;(_: App, self: &<b>mut</b> <a href="coupons.md#0x0_coupons_CouponHouse">CouponHouse</a>): &<b>mut</b> <a href="coupons.md#0x0_coupons_Data">Data</a> {
    <a href="coupons.md#0x0_coupons_assert_version_is_valid">assert_version_is_valid</a>(self);
    // verify app is authorized <b>to</b> get a mutable reference.
    <a href="coupons.md#0x0_coupons_assert_app_is_authorized">assert_app_is_authorized</a>&lt;App&gt;(self);
    &<b>mut</b> self.data
}
</code></pre>



</details>

<a name="0x0_coupons_is_app_authorized"></a>

## Function `is_app_authorized`

Check if an application is authorized to access protected features of the Coupon House.


<pre><code><b>public</b> <b>fun</b> <a href="coupons.md#0x0_coupons_is_app_authorized">is_app_authorized</a>&lt;App: drop&gt;(self: &<a href="coupons.md#0x0_coupons_CouponHouse">coupons::CouponHouse</a>): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="coupons.md#0x0_coupons_is_app_authorized">is_app_authorized</a>&lt;App: drop&gt;(self: &<a href="coupons.md#0x0_coupons_CouponHouse">CouponHouse</a>): bool {
    df::exists_(&self.id, <a href="coupons.md#0x0_coupons_AppKey">AppKey</a>&lt;App&gt;{})
}
</code></pre>



</details>

<a name="0x0_coupons_assert_app_is_authorized"></a>

## Function `assert_app_is_authorized`

Assert that an application is authorized to access protected features of Coupon House.
Aborts with <code><a href="coupons.md#0x0_coupons_EAppNotAuthorized">EAppNotAuthorized</a></code> if not.


<pre><code><b>public</b> <b>fun</b> <a href="coupons.md#0x0_coupons_assert_app_is_authorized">assert_app_is_authorized</a>&lt;App: drop&gt;(self: &<a href="coupons.md#0x0_coupons_CouponHouse">coupons::CouponHouse</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="coupons.md#0x0_coupons_assert_app_is_authorized">assert_app_is_authorized</a>&lt;App: drop&gt;(self: &<a href="coupons.md#0x0_coupons_CouponHouse">CouponHouse</a>) {
    <b>assert</b>!(<a href="coupons.md#0x0_coupons_is_app_authorized">is_app_authorized</a>&lt;App&gt;(self), <a href="coupons.md#0x0_coupons_EAppNotAuthorized">EAppNotAuthorized</a>);
}
</code></pre>



</details>

<a name="0x0_coupons_authorize_app"></a>

## Function `authorize_app`

Authorize an app. This allows to a secondary module to add/remove coupons.


<pre><code><b>public</b> <b>fun</b> <a href="coupons.md#0x0_coupons_authorize_app">authorize_app</a>&lt;App: drop&gt;(_: &<a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins_AdminCap">suins::AdminCap</a>, self: &<b>mut</b> <a href="coupons.md#0x0_coupons_CouponHouse">coupons::CouponHouse</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="coupons.md#0x0_coupons_authorize_app">authorize_app</a>&lt;App: drop&gt;(_: &AdminCap, self: &<b>mut</b> <a href="coupons.md#0x0_coupons_CouponHouse">CouponHouse</a>) {
    df::add(&<b>mut</b> self.id, <a href="coupons.md#0x0_coupons_AppKey">AppKey</a>&lt;App&gt;{}, <b>true</b>);
}
</code></pre>



</details>

<a name="0x0_coupons_deauthorize_app"></a>

## Function `deauthorize_app`

De-authorize an app. The app can no longer add or remove


<pre><code><b>public</b> <b>fun</b> <a href="coupons.md#0x0_coupons_deauthorize_app">deauthorize_app</a>&lt;App: drop&gt;(_: &<a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins_AdminCap">suins::AdminCap</a>, self: &<b>mut</b> <a href="coupons.md#0x0_coupons_CouponHouse">coupons::CouponHouse</a>): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="coupons.md#0x0_coupons_deauthorize_app">deauthorize_app</a>&lt;App: drop&gt;(_: &AdminCap, self: &<b>mut</b> <a href="coupons.md#0x0_coupons_CouponHouse">CouponHouse</a>): bool {
    df::remove(&<b>mut</b> self.id, <a href="coupons.md#0x0_coupons_AppKey">AppKey</a>&lt;App&gt;{})
}
</code></pre>



</details>

<a name="0x0_coupons_set_version"></a>

## Function `set_version`

An admin helper to set the version of the shared object.
Registrations are only possible if the latest version is being used.


<pre><code><b>public</b> <b>fun</b> <a href="coupons.md#0x0_coupons_set_version">set_version</a>(_: &<a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins_AdminCap">suins::AdminCap</a>, self: &<b>mut</b> <a href="coupons.md#0x0_coupons_CouponHouse">coupons::CouponHouse</a>, version: u8)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="coupons.md#0x0_coupons_set_version">set_version</a>(_: &AdminCap, self: &<b>mut</b> <a href="coupons.md#0x0_coupons_CouponHouse">CouponHouse</a>, version: u8) {
    self.version = version;
}
</code></pre>



</details>

<a name="0x0_coupons_assert_version_is_valid"></a>

## Function `assert_version_is_valid`

Validate that the version of the app is the latest.


<pre><code><b>public</b> <b>fun</b> <a href="coupons.md#0x0_coupons_assert_version_is_valid">assert_version_is_valid</a>(self: &<a href="coupons.md#0x0_coupons_CouponHouse">coupons::CouponHouse</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="coupons.md#0x0_coupons_assert_version_is_valid">assert_version_is_valid</a>(self: &<a href="coupons.md#0x0_coupons_CouponHouse">CouponHouse</a>) {
    <b>assert</b>!(self.version == <a href="coupons.md#0x0_coupons_VERSION">VERSION</a>, <a href="coupons.md#0x0_coupons_EInvalidVersion">EInvalidVersion</a>);
}
</code></pre>



</details>

<a name="0x0_coupons_admin_add_coupon"></a>

## Function `admin_add_coupon`

To create a coupon, you have to call the PTB in the specific order
1. (Optional) Call rules::new_domain_length_rule(type, length) // generate a length specific rule (e.g. only domains of size 5)
2. Call rules::coupon_rules(...) to create the coupon's ruleset.


<pre><code><b>public</b> <b>fun</b> <a href="coupons.md#0x0_coupons_admin_add_coupon">admin_add_coupon</a>(_: &<a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins_AdminCap">suins::AdminCap</a>, self: &<b>mut</b> <a href="coupons.md#0x0_coupons_CouponHouse">coupons::CouponHouse</a>, code: <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>, type: u8, amount: u64, <a href="rules.md#0x0_rules">rules</a>: <a href="rules.md#0x0_rules_CouponRules">rules::CouponRules</a>, ctx: &<b>mut</b> <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="coupons.md#0x0_coupons_admin_add_coupon">admin_add_coupon</a>(
    _: &AdminCap,
    self: &<b>mut</b> <a href="coupons.md#0x0_coupons_CouponHouse">CouponHouse</a>,
    code: String,
    `type`: u8,
    amount: u64,
    <a href="rules.md#0x0_rules">rules</a>: CouponRules,
    ctx: &<b>mut</b> TxContext
) {
    <a href="coupons.md#0x0_coupons_assert_version_is_valid">assert_version_is_valid</a>(self);
    <a href="coupons.md#0x0_coupons_internal_save_coupon">internal_save_coupon</a>(&<b>mut</b> self.data, code, <a href="coupons.md#0x0_coupons_internal_create_coupon">internal_create_coupon</a>(`type`, amount, <a href="rules.md#0x0_rules">rules</a>, ctx));
}
</code></pre>



</details>

<a name="0x0_coupons_admin_remove_coupon"></a>

## Function `admin_remove_coupon`



<pre><code><b>public</b> <b>fun</b> <a href="coupons.md#0x0_coupons_admin_remove_coupon">admin_remove_coupon</a>(_: &<a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins_AdminCap">suins::AdminCap</a>, self: &<b>mut</b> <a href="coupons.md#0x0_coupons_CouponHouse">coupons::CouponHouse</a>, code: <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="coupons.md#0x0_coupons_admin_remove_coupon">admin_remove_coupon</a>(_: &AdminCap, self: &<b>mut</b> <a href="coupons.md#0x0_coupons_CouponHouse">CouponHouse</a>, code: String){
    <a href="coupons.md#0x0_coupons_internal_remove_coupon">internal_remove_coupon</a>(&<b>mut</b> self.data, code)
}
</code></pre>



</details>

<a name="0x0_coupons_app_add_coupon"></a>

## Function `app_add_coupon`



<pre><code><b>public</b> <b>fun</b> <a href="coupons.md#0x0_coupons_app_add_coupon">app_add_coupon</a>(self: &<b>mut</b> <a href="coupons.md#0x0_coupons_Data">coupons::Data</a>, code: <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>, type: u8, amount: u64, <a href="rules.md#0x0_rules">rules</a>: <a href="rules.md#0x0_rules_CouponRules">rules::CouponRules</a>, ctx: &<b>mut</b> <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="coupons.md#0x0_coupons_app_add_coupon">app_add_coupon</a>(
    self: &<b>mut</b> <a href="coupons.md#0x0_coupons_Data">Data</a>,
    code: String,
    `type`: u8,
    amount: u64,
    <a href="rules.md#0x0_rules">rules</a>: CouponRules,
    ctx: &<b>mut</b> TxContext
){
    <a href="coupons.md#0x0_coupons_internal_save_coupon">internal_save_coupon</a>(self, code, <a href="coupons.md#0x0_coupons_internal_create_coupon">internal_create_coupon</a>(`type`, amount, <a href="rules.md#0x0_rules">rules</a>, ctx));
}
</code></pre>



</details>

<a name="0x0_coupons_app_remove_coupon"></a>

## Function `app_remove_coupon`



<pre><code><b>public</b> <b>fun</b> <a href="coupons.md#0x0_coupons_app_remove_coupon">app_remove_coupon</a>(self: &<b>mut</b> <a href="coupons.md#0x0_coupons_Data">coupons::Data</a>, code: <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="coupons.md#0x0_coupons_app_remove_coupon">app_remove_coupon</a>(self: &<b>mut</b> <a href="coupons.md#0x0_coupons_Data">Data</a>, code: String) {
    <a href="coupons.md#0x0_coupons_internal_remove_coupon">internal_remove_coupon</a>(self, code);
}
</code></pre>



</details>

<a name="0x0_coupons_internal_calculate_sale_price"></a>

## Function `internal_calculate_sale_price`

A helper to calculate the final price after the discount.


<pre><code><b>fun</b> <a href="coupons.md#0x0_coupons_internal_calculate_sale_price">internal_calculate_sale_price</a>(price: u64, coupon: &<a href="coupons.md#0x0_coupons_Coupon">coupons::Coupon</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="coupons.md#0x0_coupons_internal_calculate_sale_price">internal_calculate_sale_price</a>(price: u64, coupon: &<a href="coupons.md#0x0_coupons_Coupon">Coupon</a>): u64{
    // If it's fixed price, we just deduce the amount.
    <b>if</b>(coupon.`type` == constants::fixed_price_discount_type()){
        <b>if</b>(coupon.amount &gt; price) <b>return</b> 0; // protect underflow case.
        <b>return</b> price - coupon.amount
    };

    // If it's discount price, we calculate the discount
    <b>let</b> discount =  (((price <b>as</b> u128) * (coupon.amount <b>as</b> u128) / 100) <b>as</b> u64);
    // then remove it from the sale price.
    price - discount
}
</code></pre>



</details>

<a name="0x0_coupons_internal_save_coupon"></a>

## Function `internal_save_coupon`

Private internal functions
An internal function to save the coupon in the shared object's config.


<pre><code><b>fun</b> <a href="coupons.md#0x0_coupons_internal_save_coupon">internal_save_coupon</a>(self: &<b>mut</b> <a href="coupons.md#0x0_coupons_Data">coupons::Data</a>, code: <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>, coupon: <a href="coupons.md#0x0_coupons_Coupon">coupons::Coupon</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="coupons.md#0x0_coupons_internal_save_coupon">internal_save_coupon</a>(
    self: &<b>mut</b> <a href="coupons.md#0x0_coupons_Data">Data</a>,
    code: String,
    coupon: <a href="coupons.md#0x0_coupons_Coupon">Coupon</a>
) {
    <b>assert</b>!(!self.<a href="coupons.md#0x0_coupons">coupons</a>.contains(code), <a href="coupons.md#0x0_coupons_ECouponAlreadyExists">ECouponAlreadyExists</a>);
    self.<a href="coupons.md#0x0_coupons">coupons</a>.add(code, coupon);
}
</code></pre>



</details>

<a name="0x0_coupons_internal_create_coupon"></a>

## Function `internal_create_coupon`

An internal function to create a coupon object.


<pre><code><b>fun</b> <a href="coupons.md#0x0_coupons_internal_create_coupon">internal_create_coupon</a>(type: u8, amount: u64, <a href="rules.md#0x0_rules">rules</a>: <a href="rules.md#0x0_rules_CouponRules">rules::CouponRules</a>, _ctx: &<b>mut</b> <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context_TxContext">tx_context::TxContext</a>): <a href="coupons.md#0x0_coupons_Coupon">coupons::Coupon</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="coupons.md#0x0_coupons_internal_create_coupon">internal_create_coupon</a>(
    `type`: u8,
    amount: u64,
    <a href="rules.md#0x0_rules">rules</a>: CouponRules,
    _ctx: &<b>mut</b> TxContext
): <a href="coupons.md#0x0_coupons_Coupon">Coupon</a> {
    <a href="rules.md#0x0_rules_assert_is_valid_amount">rules::assert_is_valid_amount</a>(`type`, amount);
    <a href="rules.md#0x0_rules_assert_is_valid_discount_type">rules::assert_is_valid_discount_type</a>(`type`);
    <a href="coupons.md#0x0_coupons_Coupon">Coupon</a> {
        `type`, amount, <a href="rules.md#0x0_rules">rules</a>
    }
}
</code></pre>



</details>

<a name="0x0_coupons_internal_remove_coupon"></a>

## Function `internal_remove_coupon`



<pre><code><b>fun</b> <a href="coupons.md#0x0_coupons_internal_remove_coupon">internal_remove_coupon</a>(self: &<b>mut</b> <a href="coupons.md#0x0_coupons_Data">coupons::Data</a>, code: <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="coupons.md#0x0_coupons_internal_remove_coupon">internal_remove_coupon</a>(self: &<b>mut</b> <a href="coupons.md#0x0_coupons_Data">Data</a>, code: String) {
    self.<a href="coupons.md#0x0_coupons">coupons</a>.remove(code);
}
</code></pre>



</details>
