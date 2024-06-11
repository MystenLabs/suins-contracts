
<a name="0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house"></a>

# Module `0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8::coupon_house`

A module to support coupons for SuiNS.
This module allows secondary modules (e.g. Discord) to add or remove coupons too.
This allows for separation of logic & ease of de-authorization in case we don't want some functionality anymore.

Coupons are unique string codes, that can be used (based on the business rules) to claim discounts in the app.
Each coupon is validated towards a list of rules. View <code><a href="rules.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_rules">rules</a></code> module for explanation.
The app is authorized on <code>SuiNS</code> to be able to claim names and add earnings to the registry.


-  [Struct `CouponsApp`](#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_CouponsApp)
-  [Struct `AppKey`](#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_AppKey)
-  [Struct `CouponHouse`](#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_CouponHouse)
-  [Constants](#@Constants_0)
-  [Function `setup`](#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_setup)
-  [Function `register_with_coupon`](#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_register_with_coupon)
-  [Function `calculate_sale_price`](#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_calculate_sale_price)
-  [Function `app_data_mut`](#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_app_data_mut)
-  [Function `authorize_app`](#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_authorize_app)
-  [Function `deauthorize_app`](#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_deauthorize_app)
-  [Function `set_version`](#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_set_version)
-  [Function `assert_version_is_valid`](#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_assert_version_is_valid)
-  [Function `admin_add_coupon`](#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_admin_add_coupon)
-  [Function `admin_remove_coupon`](#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_admin_remove_coupon)
-  [Function `app_add_coupon`](#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_app_add_coupon)
-  [Function `app_remove_coupon`](#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_app_remove_coupon)
-  [Function `is_app_authorized`](#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_is_app_authorized)
-  [Function `assert_app_is_authorized`](#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_assert_app_is_authorized)
-  [Function `coupon_house`](#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_coupon_house)
-  [Function `coupon_house_mut`](#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_coupon_house_mut)


<pre><code><b>use</b> <a href="dependencies/move-stdlib/string.md#0x1_string">0x1::string</a>;
<b>use</b> <a href="dependencies/sui-framework/bag.md#0x2_bag">0x2::bag</a>;
<b>use</b> <a href="dependencies/sui-framework/balance.md#0x2_balance">0x2::balance</a>;
<b>use</b> <a href="dependencies/sui-framework/clock.md#0x2_clock">0x2::clock</a>;
<b>use</b> <a href="dependencies/sui-framework/coin.md#0x2_coin">0x2::coin</a>;
<b>use</b> <a href="dependencies/sui-framework/dynamic_field.md#0x2_dynamic_field">0x2::dynamic_field</a>;
<b>use</b> <a href="dependencies/sui-framework/object.md#0x2_object">0x2::object</a>;
<b>use</b> <a href="dependencies/sui-framework/sui.md#0x2_sui">0x2::sui</a>;
<b>use</b> <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context">0x2::tx_context</a>;
<b>use</b> <a href="dependencies/suins/config.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_config">0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b::config</a>;
<b>use</b> <a href="dependencies/suins/domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b::domain</a>;
<b>use</b> <a href="dependencies/suins/registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry">0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b::registry</a>;
<b>use</b> <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b::suins</a>;
<b>use</b> <a href="dependencies/suins/suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration">0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b::suins_registration</a>;
<b>use</b> <a href="coupon.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon">0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8::coupon</a>;
<b>use</b> <a href="data.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_data">0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8::data</a>;
<b>use</b> <a href="rules.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_rules">0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8::rules</a>;
</code></pre>



<a name="0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_CouponsApp"></a>

## Struct `CouponsApp`



<pre><code><b>struct</b> <a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_CouponsApp">CouponsApp</a> <b>has</b> drop
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

<a name="0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_AppKey"></a>

## Struct `AppKey`

Authorization Key for secondary apps (e.g. Discord) connected to this module.


<pre><code><b>struct</b> <a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_AppKey">AppKey</a>&lt;A: drop&gt; <b>has</b> <b>copy</b>, drop, store
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

<a name="0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_CouponHouse"></a>

## Struct `CouponHouse`

The CouponHouse Shared Object which holds a table of coupon codes available for claim.


<pre><code><b>struct</b> <a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_CouponHouse">CouponHouse</a> <b>has</b> store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code><a href="data.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_data">data</a>: <a href="data.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_data_Data">data::Data</a></code>
</dt>
<dd>

</dd>
<dt>
<code>version: u8</code>
</dt>
<dd>

</dd>
<dt>
<code>storage: <a href="dependencies/sui-framework/object.md#0x2_object_UID">object::UID</a></code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="@Constants_0"></a>

## Constants


<a name="0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_EAppNotAuthorized"></a>

An app that's not authorized tries to access private data.


<pre><code><b>const</b> <a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_EAppNotAuthorized">EAppNotAuthorized</a>: u64 = 1;
</code></pre>



<a name="0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_ECouponNotExists"></a>

Coupon doesn't exist.


<pre><code><b>const</b> <a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_ECouponNotExists">ECouponNotExists</a>: u64 = 5;
</code></pre>



<a name="0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_EIncorrectAmount"></a>

The payment does not match the price for the domain.


<pre><code><b>const</b> <a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_EIncorrectAmount">EIncorrectAmount</a>: u64 = 4;
</code></pre>



<a name="0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_EInvalidVersion"></a>

Tries to use app on an invalid version.


<pre><code><b>const</b> <a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_EInvalidVersion">EInvalidVersion</a>: u64 = 2;
</code></pre>



<a name="0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_EInvalidYearsArgument"></a>

These errors are claim errors.
Number of years passed is not within [1-5] interval.


<pre><code><b>const</b> <a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_EInvalidYearsArgument">EInvalidYearsArgument</a>: u64 = 3;
</code></pre>



<a name="0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_VERSION"></a>

Our versioning of the coupons package.


<pre><code><b>const</b> <a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_VERSION">VERSION</a>: u8 = 1;
</code></pre>



<a name="0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_setup"></a>

## Function `setup`

Called once to setup the CouponHouse on SuiNS.


<pre><code><b>public</b> <b>fun</b> <a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_setup">setup</a>(<a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>: &<b>mut</b> <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_SuiNS">suins::SuiNS</a>, cap: &<a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_AdminCap">suins::AdminCap</a>, ctx: &<b>mut</b> <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_setup">setup</a>(<a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>: &<b>mut</b> SuiNS, cap: &AdminCap, ctx: &<b>mut</b> TxContext) {
    cap.add_registry(<a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>, <a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_CouponHouse">CouponHouse</a> {
        storage: <a href="dependencies/sui-framework/object.md#0x2_object_new">object::new</a>(ctx),
        <a href="data.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_data">data</a>: <a href="data.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_data_new">data::new</a>(ctx),
        version: <a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_VERSION">VERSION</a>
    });
}
</code></pre>



</details>

<a name="0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_register_with_coupon"></a>

## Function `register_with_coupon`

Register a name using a coupon code.


<pre><code><b>public</b> <b>fun</b> <a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_register_with_coupon">register_with_coupon</a>(<a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>: &<b>mut</b> <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_SuiNS">suins::SuiNS</a>, coupon_code: <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>, domain_name: <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>, no_years: u8, payment: <a href="dependencies/sui-framework/coin.md#0x2_coin_Coin">coin::Coin</a>&lt;<a href="dependencies/sui-framework/sui.md#0x2_sui_SUI">sui::SUI</a>&gt;, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &<a href="dependencies/sui-framework/clock.md#0x2_clock_Clock">clock::Clock</a>, ctx: &<b>mut</b> <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context_TxContext">tx_context::TxContext</a>): <a href="dependencies/suins/suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_SuinsRegistration">suins_registration::SuinsRegistration</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_register_with_coupon">register_with_coupon</a>(
    <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>: &<b>mut</b> SuiNS,
    coupon_code: String,
    domain_name: String,
    no_years: u8,
    payment: Coin&lt;SUI&gt;,
    <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &Clock,
    ctx: &<b>mut</b> TxContext
): SuinsRegistration {
    // Validate registration years are in [0,5] <a href="range.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_range">range</a>.
    <b>assert</b>!(no_years &gt; 0 && no_years &lt;= 5, <a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_EInvalidYearsArgument">EInvalidYearsArgument</a>);

    <b>let</b> <a href="dependencies/suins/config.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_config">config</a> = <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>.get_config&lt;Config&gt;();
    <b>let</b> <a href="dependencies/suins/domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a> = <a href="dependencies/suins/domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain_new">domain::new</a>(domain_name);
    <b>let</b> label = <a href="dependencies/suins/domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>.sld();
    <b>let</b> domain_length = (label.length() <b>as</b> u8);
    <b>let</b> original_price = <a href="dependencies/suins/config.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_config">config</a>.calculate_price(domain_length, no_years);
    // Validate name can be registered (is main <a href="dependencies/suins/domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a> (no subdomain) and length is valid)
    <a href="dependencies/suins/config.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_config_assert_valid_user_registerable_domain">config::assert_valid_user_registerable_domain</a>(&<a href="dependencies/suins/domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>);

    // Verify <a href="coupon.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon">coupon</a> house is authorized <b>to</b> get the <a href="dependencies/suins/registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry">registry</a> / register names.
    <b>let</b> <a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house">coupon_house</a> = <a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_coupon_house_mut">coupon_house_mut</a>(<a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>);

    // Validate that specified <a href="coupon.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon">coupon</a> is valid.
    <b>assert</b>!(<a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house">coupon_house</a>.<a href="data.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_data">data</a>.coupons().contains(coupon_code), <a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_ECouponNotExists">ECouponNotExists</a>);

    // Borrow <a href="coupon.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon">coupon</a> from the <a href="dependencies/sui-framework/table.md#0x2_table">table</a>.
    <b>let</b> <a href="coupon.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon">coupon</a>: &<b>mut</b> Coupon = &<b>mut</b> <a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house">coupon_house</a>.<a href="data.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_data">data</a>.coupons_mut()[coupon_code];

    // We need <b>to</b> do a total of 5 checks, based on `CouponRules`
    // Our checks work <b>with</b> `AND`, all of the conditions must pass for a <a href="coupon.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon">coupon</a> <b>to</b> be used.
    // 1. Validate <a href="dependencies/suins/domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a> size.
    <a href="coupon.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon">coupon</a>.<a href="rules.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_rules">rules</a>().assert_coupon_valid_for_domain_size(domain_length);
    // 2. Decrease available claims. Will ABORT <b>if</b> the <a href="coupon.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon">coupon</a> doesn't have enough available claims.
    <a href="coupon.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon">coupon</a>.rules_mut().decrease_available_claims();
    // 3. Validate the <a href="coupon.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon">coupon</a> is valid for the specified user.
    <a href="coupon.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon">coupon</a>.<a href="rules.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_rules">rules</a>().assert_coupon_valid_for_address(ctx.sender());
    // 4. Validate the <a href="coupon.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon">coupon</a> hasn't expired (Based on <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>)
    <a href="coupon.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon">coupon</a>.<a href="rules.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_rules">rules</a>().assert_coupon_is_not_expired(<a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>);
    // 5. Validate years are valid for the <a href="coupon.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon">coupon</a>.
    <a href="coupon.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon">coupon</a>.<a href="rules.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_rules">rules</a>().assert_coupon_valid_for_domain_years(no_years);

    <b>let</b> sale_price = <a href="coupon.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon">coupon</a>.<a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_calculate_sale_price">calculate_sale_price</a>(original_price);
    <b>assert</b>!(payment.value() == sale_price, <a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_EIncorrectAmount">EIncorrectAmount</a>);

    // Clean up our <a href="dependencies/suins/registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry">registry</a> by removing the <a href="coupon.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon">coupon</a> <b>if</b> no more available claims!
    <b>if</b>(!<a href="coupon.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon">coupon</a>.<a href="rules.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_rules">rules</a>().has_available_claims()){
        // remove the <a href="coupon.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon">coupon</a>, since it's no longer usable.
        <a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house">coupon_house</a>.<a href="data.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_data">data</a>.remove_coupon(coupon_code);
    };

    <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_app_add_balance">suins::app_add_balance</a>(<a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_CouponsApp">CouponsApp</a> {}, <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>, payment.into_balance());
    <b>let</b> <a href="dependencies/suins/registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry">registry</a> = <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_app_registry_mut">suins::app_registry_mut</a>&lt;<a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_CouponsApp">CouponsApp</a>, Registry&gt;(<a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_CouponsApp">CouponsApp</a> {}, <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>);
    <a href="dependencies/suins/registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry">registry</a>.add_record(<a href="dependencies/suins/domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>, no_years, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>, ctx)
}
</code></pre>



</details>

<a name="0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_calculate_sale_price"></a>

## Function `calculate_sale_price`



<pre><code><b>public</b> <b>fun</b> <a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_calculate_sale_price">calculate_sale_price</a>(<a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>: &<a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_SuiNS">suins::SuiNS</a>, price: u64, coupon_code: <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_calculate_sale_price">calculate_sale_price</a>(<a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>: &SuiNS, price: u64, coupon_code: String): u64 {
    <b>let</b> <a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house">coupon_house</a> = <a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house">coupon_house</a>(<a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>);
    // Validate that specified <a href="coupon.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon">coupon</a> is valid.
    <b>assert</b>!(<a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house">coupon_house</a>.<a href="data.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_data">data</a>.coupons().contains(coupon_code), <a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_ECouponNotExists">ECouponNotExists</a>);

    // Borrow <a href="coupon.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon">coupon</a> from the <a href="dependencies/sui-framework/table.md#0x2_table">table</a>.
    <b>let</b> <a href="coupon.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon">coupon</a>: &Coupon = &<a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house">coupon_house</a>.<a href="data.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_data">data</a>.coupons()[coupon_code];

    <a href="coupon.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon">coupon</a>.<a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_calculate_sale_price">calculate_sale_price</a>(price)
}
</code></pre>



</details>

<a name="0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_app_data_mut"></a>

## Function `app_data_mut`



<pre><code><b>public</b> <b>fun</b> <a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_app_data_mut">app_data_mut</a>&lt;A: drop&gt;(<a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>: &<b>mut</b> <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_SuiNS">suins::SuiNS</a>, _: A): &<b>mut</b> <a href="data.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_data_Data">data::Data</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_app_data_mut">app_data_mut</a>&lt;A: drop&gt;(<a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>: &<b>mut</b> SuiNS, _: A): &<b>mut</b> Data {
    <b>let</b> coupon_house_mut = <a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_coupon_house_mut">coupon_house_mut</a>(<a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>);
    coupon_house_mut.<a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_assert_version_is_valid">assert_version_is_valid</a>();
    // verify app is authorized <b>to</b> get a mutable reference.
    coupon_house_mut.<a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_assert_app_is_authorized">assert_app_is_authorized</a>&lt;A&gt;();
    &<b>mut</b> coupon_house_mut.<a href="data.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_data">data</a>
}
</code></pre>



</details>

<a name="0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_authorize_app"></a>

## Function `authorize_app`

Authorize an app on the coupon house. This allows to a secondary module to add/remove coupons.


<pre><code><b>public</b> <b>fun</b> <a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_authorize_app">authorize_app</a>&lt;A: drop&gt;(_: &<a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_AdminCap">suins::AdminCap</a>, <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>: &<b>mut</b> <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_SuiNS">suins::SuiNS</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_authorize_app">authorize_app</a>&lt;A: drop&gt;(_: &AdminCap, <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>: &<b>mut</b> SuiNS) {
    df::add(&<b>mut</b> <a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_coupon_house_mut">coupon_house_mut</a>(<a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>).storage, <a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_AppKey">AppKey</a>&lt;A&gt;{}, <b>true</b>);
}
</code></pre>



</details>

<a name="0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_deauthorize_app"></a>

## Function `deauthorize_app`

De-authorize an app. The app can no longer add or remove


<pre><code><b>public</b> <b>fun</b> <a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_deauthorize_app">deauthorize_app</a>&lt;A: drop&gt;(_: &<a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_AdminCap">suins::AdminCap</a>, <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>: &<b>mut</b> <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_SuiNS">suins::SuiNS</a>): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_deauthorize_app">deauthorize_app</a>&lt;A: drop&gt;(_: &AdminCap, <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>: &<b>mut</b> SuiNS): bool {
    df::remove(&<b>mut</b> <a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_coupon_house_mut">coupon_house_mut</a>(<a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>).storage, <a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_AppKey">AppKey</a>&lt;A&gt;{})
}
</code></pre>



</details>

<a name="0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_set_version"></a>

## Function `set_version`

An admin helper to set the version of the shared object.
Registrations are only possible if the latest version is being used.


<pre><code><b>public</b> <b>fun</b> <a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_set_version">set_version</a>(_: &<a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_AdminCap">suins::AdminCap</a>, <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>: &<b>mut</b> <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_SuiNS">suins::SuiNS</a>, version: u8)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_set_version">set_version</a>(_: &AdminCap, <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>: &<b>mut</b> SuiNS, version: u8) {
    <a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_coupon_house_mut">coupon_house_mut</a>(<a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>).version = version;
}
</code></pre>



</details>

<a name="0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_assert_version_is_valid"></a>

## Function `assert_version_is_valid`

Validate that the version of the app is the latest.


<pre><code><b>public</b> <b>fun</b> <a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_assert_version_is_valid">assert_version_is_valid</a>(self: &<a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_CouponHouse">coupon_house::CouponHouse</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_assert_version_is_valid">assert_version_is_valid</a>(self: &<a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_CouponHouse">CouponHouse</a>) {
    <b>assert</b>!(self.version == <a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_VERSION">VERSION</a>, <a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_EInvalidVersion">EInvalidVersion</a>);
}
</code></pre>



</details>

<a name="0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_admin_add_coupon"></a>

## Function `admin_add_coupon`

To create a coupon, you have to call the PTB in the specific order
1. (Optional) Call rules::new_domain_length_rule(type, length) // generate a length specific rule (e.g. only domains of size 5)
2. Call rules::coupon_rules(...) to create the coupon's ruleset.


<pre><code><b>public</b> <b>fun</b> <a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_admin_add_coupon">admin_add_coupon</a>(_: &<a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_AdminCap">suins::AdminCap</a>, <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>: &<b>mut</b> <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_SuiNS">suins::SuiNS</a>, code: <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>, kind: u8, amount: u64, <a href="rules.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_rules">rules</a>: <a href="rules.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_rules_CouponRules">rules::CouponRules</a>, ctx: &<b>mut</b> <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_admin_add_coupon">admin_add_coupon</a>(
    _: &AdminCap,
    <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>: &<b>mut</b> SuiNS,
    code: String,
    kind: u8,
    amount: u64,
    <a href="rules.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_rules">rules</a>: CouponRules,
    ctx: &<b>mut</b> TxContext
) {
    <b>let</b> <a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house">coupon_house</a> = <a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_coupon_house_mut">coupon_house_mut</a>(<a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>);
    <a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house">coupon_house</a>.<a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_assert_version_is_valid">assert_version_is_valid</a>();
    <a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house">coupon_house</a>.<a href="data.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_data">data</a>.save_coupon(code, <a href="coupon.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_new">coupon::new</a>(kind, amount, <a href="rules.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_rules">rules</a>, ctx));
}
</code></pre>



</details>

<a name="0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_admin_remove_coupon"></a>

## Function `admin_remove_coupon`



<pre><code><b>public</b> <b>fun</b> <a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_admin_remove_coupon">admin_remove_coupon</a>(_: &<a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_AdminCap">suins::AdminCap</a>, <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>: &<b>mut</b> <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_SuiNS">suins::SuiNS</a>, code: <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_admin_remove_coupon">admin_remove_coupon</a>(_: &AdminCap, <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>: &<b>mut</b> SuiNS, code: String){
    <b>let</b> <a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house">coupon_house</a> = <a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_coupon_house_mut">coupon_house_mut</a>(<a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>);
    <a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house">coupon_house</a>.<a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_assert_version_is_valid">assert_version_is_valid</a>();
    <a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house">coupon_house</a>.<a href="data.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_data">data</a>.remove_coupon(code);
}
</code></pre>



</details>

<a name="0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_app_add_coupon"></a>

## Function `app_add_coupon`



<pre><code><b>public</b> <b>fun</b> <a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_app_add_coupon">app_add_coupon</a>(<a href="data.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_data">data</a>: &<b>mut</b> <a href="data.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_data_Data">data::Data</a>, code: <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>, kind: u8, amount: u64, <a href="rules.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_rules">rules</a>: <a href="rules.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_rules_CouponRules">rules::CouponRules</a>, ctx: &<b>mut</b> <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_app_add_coupon">app_add_coupon</a>(
    <a href="data.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_data">data</a>: &<b>mut</b> Data,
    code: String,
    kind: u8,
    amount: u64,
    <a href="rules.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_rules">rules</a>: CouponRules,
    ctx: &<b>mut</b> TxContext
){
    <a href="data.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_data">data</a>.save_coupon(code, <a href="coupon.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_new">coupon::new</a>(kind, amount, <a href="rules.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_rules">rules</a>, ctx));
}
</code></pre>



</details>

<a name="0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_app_remove_coupon"></a>

## Function `app_remove_coupon`



<pre><code><b>public</b> <b>fun</b> <a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_app_remove_coupon">app_remove_coupon</a>(<a href="data.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_data">data</a>: &<b>mut</b> <a href="data.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_data_Data">data::Data</a>, code: <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_app_remove_coupon">app_remove_coupon</a>(<a href="data.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_data">data</a>: &<b>mut</b> Data, code: String) {
    <a href="data.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_data">data</a>.remove_coupon(code);
}
</code></pre>



</details>

<a name="0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_is_app_authorized"></a>

## Function `is_app_authorized`

Check if an application is authorized to access protected features of the Coupon House.


<pre><code><b>public</b> <b>fun</b> <a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_is_app_authorized">is_app_authorized</a>&lt;A: drop&gt;(<a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house">coupon_house</a>: &<a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_CouponHouse">coupon_house::CouponHouse</a>): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_is_app_authorized">is_app_authorized</a>&lt;A: drop&gt;(<a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house">coupon_house</a>: &<a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_CouponHouse">CouponHouse</a>): bool {
    df::exists_(&<a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house">coupon_house</a>.storage, <a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_AppKey">AppKey</a>&lt;A&gt;{})
}
</code></pre>



</details>

<a name="0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_assert_app_is_authorized"></a>

## Function `assert_app_is_authorized`

Assert that an application is authorized to access protected features of Coupon House.
Aborts with <code><a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_EAppNotAuthorized">EAppNotAuthorized</a></code> if not.


<pre><code><b>public</b> <b>fun</b> <a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_assert_app_is_authorized">assert_app_is_authorized</a>&lt;A: drop&gt;(<a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house">coupon_house</a>: &<a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_CouponHouse">coupon_house::CouponHouse</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_assert_app_is_authorized">assert_app_is_authorized</a>&lt;A: drop&gt;(<a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house">coupon_house</a>: &<a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_CouponHouse">CouponHouse</a>) {
    <b>assert</b>!(<a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house">coupon_house</a>.<a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_is_app_authorized">is_app_authorized</a>&lt;A&gt;(), <a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_EAppNotAuthorized">EAppNotAuthorized</a>);
}
</code></pre>



</details>

<a name="0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_coupon_house"></a>

## Function `coupon_house`

local helper to get the <code><a href="coupon.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon">coupon</a> house</code> object from the SuiNS object.


<pre><code><b>fun</b> <a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house">coupon_house</a>(<a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>: &<a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_SuiNS">suins::SuiNS</a>): &<a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_CouponHouse">coupon_house::CouponHouse</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house">coupon_house</a>(<a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>: &SuiNS): &<a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_CouponHouse">CouponHouse</a> {
    // Verify <a href="coupon.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon">coupon</a> house is authorized <b>to</b> get the <a href="dependencies/suins/registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry">registry</a> / register names.
    <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>.<a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_assert_app_is_authorized">assert_app_is_authorized</a>&lt;<a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_CouponsApp">CouponsApp</a>&gt;();
    <b>let</b> coupons = <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>.<a href="dependencies/suins/registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry">registry</a>&lt;<a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_CouponHouse">CouponHouse</a>&gt;();
    coupons.<a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_assert_version_is_valid">assert_version_is_valid</a>();
    coupons
}
</code></pre>



</details>

<a name="0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_coupon_house_mut"></a>

## Function `coupon_house_mut`

Gets a mutable reference to the coupon's house


<pre><code><b>fun</b> <a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_coupon_house_mut">coupon_house_mut</a>(<a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>: &<b>mut</b> <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_SuiNS">suins::SuiNS</a>): &<b>mut</b> <a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_CouponHouse">coupon_house::CouponHouse</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_coupon_house_mut">coupon_house_mut</a>(<a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>: &<b>mut</b> SuiNS): &<b>mut</b> <a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_CouponHouse">CouponHouse</a> {
   // Verify <a href="coupon.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon">coupon</a> house is authorized <b>to</b> get the <a href="dependencies/suins/registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry">registry</a> / register names.
    <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>.<a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_assert_app_is_authorized">assert_app_is_authorized</a>&lt;<a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_CouponsApp">CouponsApp</a>&gt;();
    <b>let</b> coupons = <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_app_registry_mut">suins::app_registry_mut</a>&lt;<a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_CouponsApp">CouponsApp</a>, <a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_CouponHouse">CouponHouse</a>&gt;(<a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_CouponsApp">CouponsApp</a> {}, <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>);
    coupons.<a href="coupon_house.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_house_assert_version_is_valid">assert_version_is_valid</a>();
    coupons
}
</code></pre>



</details>
