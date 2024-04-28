
<a name="0x0_discounts"></a>

# Module `0x0::discounts`

A module that allows purchasing names in a different price by presenting a reference of type T.
Each <code>T</code> can have a separate configuration for a discount percentage.
If a <code>T</code> doesn't exist, registration will fail.

Can be called only when promotions are active for a specific type T.
Activation / deactivation happens through PTBs.


-  [Struct `DiscountKey`](#0x0_discounts_DiscountKey)
-  [Struct `DiscountConfig`](#0x0_discounts_DiscountConfig)
-  [Constants](#@Constants_0)
-  [Function `register`](#0x0_discounts_register)
-  [Function `register_with_day_one`](#0x0_discounts_register_with_day_one)
-  [Function `calculate_price`](#0x0_discounts_calculate_price)
-  [Function `authorize_type`](#0x0_discounts_authorize_type)
-  [Function `deauthorize_type`](#0x0_discounts_deauthorize_type)
-  [Function `internal_register_name`](#0x0_discounts_internal_register_name)
-  [Function `assert_config_exists`](#0x0_discounts_assert_config_exists)


<pre><code><b>use</b> <a href="house.md#0x0_house">0x0::house</a>;
<b>use</b> <a href="dependencies/move-stdlib/ascii.md#0x1_ascii">0x1::ascii</a>;
<b>use</b> <a href="dependencies/move-stdlib/option.md#0x1_option">0x1::option</a>;
<b>use</b> <a href="dependencies/move-stdlib/string.md#0x1_string">0x1::string</a>;
<b>use</b> <a href="dependencies/move-stdlib/type_name.md#0x1_type_name">0x1::type_name</a>;
<b>use</b> <a href="dependencies/sui-framework/balance.md#0x2_balance">0x2::balance</a>;
<b>use</b> <a href="dependencies/sui-framework/clock.md#0x2_clock">0x2::clock</a>;
<b>use</b> <a href="dependencies/sui-framework/coin.md#0x2_coin">0x2::coin</a>;
<b>use</b> <a href="dependencies/sui-framework/dynamic_field.md#0x2_dynamic_field">0x2::dynamic_field</a>;
<b>use</b> <a href="dependencies/sui-framework/object.md#0x2_object">0x2::object</a>;
<b>use</b> <a href="dependencies/sui-framework/sui.md#0x2_sui">0x2::sui</a>;
<b>use</b> <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context">0x2::tx_context</a>;
<b>use</b> <a href="dependencies/day_one/day_one.md#0xbf1431324a4a6eadd70e0ac6c5a16f36492f255ed4d011978b2cf34ad738efe6_day_one">0xbf1431324a4a6eadd70e0ac6c5a16f36492f255ed4d011978b2cf34ad738efe6::day_one</a>;
<b>use</b> <a href="dependencies/suins/domain.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_domain">0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0::domain</a>;
<b>use</b> <a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0::suins</a>;
<b>use</b> <a href="dependencies/suins/suins_registration.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins_registration">0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0::suins_registration</a>;
</code></pre>



<a name="0x0_discounts_DiscountKey"></a>

## Struct `DiscountKey`

A key that opens up discounts for type T.


<pre><code><b>struct</b> <a href="discounts.md#0x0_discounts_DiscountKey">DiscountKey</a>&lt;T&gt; <b>has</b> <b>copy</b>, drop, store
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

<a name="0x0_discounts_DiscountConfig"></a>

## Struct `DiscountConfig`

The Discount config for type T.
We save the sale price for each letter configuration (3 chars, 4 chars, 5+ chars)


<pre><code><b>struct</b> <a href="discounts.md#0x0_discounts_DiscountConfig">DiscountConfig</a> <b>has</b> <b>copy</b>, drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>three_char_price: u64</code>
</dt>
<dd>

</dd>
<dt>
<code>four_char_price: u64</code>
</dt>
<dd>

</dd>
<dt>
<code>five_plus_char_price: u64</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="@Constants_0"></a>

## Constants


<a name="0x0_discounts_EConfigExists"></a>

A configuration already exists


<pre><code><b>const</b> <a href="discounts.md#0x0_discounts_EConfigExists">EConfigExists</a>: u64 = 1;
</code></pre>



<a name="0x0_discounts_EConfigNotExists"></a>

A configuration doesn't exist


<pre><code><b>const</b> <a href="discounts.md#0x0_discounts_EConfigNotExists">EConfigNotExists</a>: u64 = 2;
</code></pre>



<a name="0x0_discounts_EIncorrectAmount"></a>

Invalid payment value


<pre><code><b>const</b> <a href="discounts.md#0x0_discounts_EIncorrectAmount">EIncorrectAmount</a>: u64 = 3;
</code></pre>



<a name="0x0_discounts_ENotActiveDayOne"></a>

Tries to claim with a non active DayOne


<pre><code><b>const</b> <a href="discounts.md#0x0_discounts_ENotActiveDayOne">ENotActiveDayOne</a>: u64 = 5;
</code></pre>



<a name="0x0_discounts_ENotValidForDayOne"></a>

Tries to use DayOne on regular register flow.


<pre><code><b>const</b> <a href="discounts.md#0x0_discounts_ENotValidForDayOne">ENotValidForDayOne</a>: u64 = 4;
</code></pre>



<a name="0x0_discounts_register"></a>

## Function `register`

A function to register a name with a discount using type <code>T</code>.


<pre><code><b>public</b> <b>fun</b> <a href="discounts.md#0x0_discounts_register">register</a>&lt;T&gt;(self: &<b>mut</b> <a href="house.md#0x0_house_DiscountHouse">house::DiscountHouse</a>, <a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>: &<b>mut</b> <a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins_SuiNS">suins::SuiNS</a>, _: &T, domain_name: <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>, payment: <a href="dependencies/sui-framework/coin.md#0x2_coin_Coin">coin::Coin</a>&lt;<a href="dependencies/sui-framework/sui.md#0x2_sui_SUI">sui::SUI</a>&gt;, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &<a href="dependencies/sui-framework/clock.md#0x2_clock_Clock">clock::Clock</a>, _reseller: <a href="dependencies/move-stdlib/option.md#0x1_option_Option">option::Option</a>&lt;<a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>&gt;, ctx: &<b>mut</b> <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context_TxContext">tx_context::TxContext</a>): <a href="dependencies/suins/suins_registration.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins_registration_SuinsRegistration">suins_registration::SuinsRegistration</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="discounts.md#0x0_discounts_register">register</a>&lt;T&gt;(
    self: &<b>mut</b> DiscountHouse,
    <a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>: &<b>mut</b> SuiNS,
    _: &T,
    domain_name: String,
    payment: Coin&lt;SUI&gt;,
    <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &Clock,
    _reseller: Option&lt;String&gt;,
    ctx: &<b>mut</b> TxContext
): SuinsRegistration {
    // For normal flow, we do not allow DayOne <b>to</b> be used.
    // DayOne can only be used on `register_with_day_one` function.
    <b>assert</b>!(`type`::into_string(`type`::get&lt;T&gt;()) != `type`::into_string(`type`::get&lt;DayOne&gt;()), <a href="discounts.md#0x0_discounts_ENotValidForDayOne">ENotValidForDayOne</a>);
    <a href="discounts.md#0x0_discounts_internal_register_name">internal_register_name</a>&lt;T&gt;(self, <a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>, domain_name, payment, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>, ctx)
}
</code></pre>



</details>

<a name="0x0_discounts_register_with_day_one"></a>

## Function `register_with_day_one`

A special function for DayOne registration.
We separate it from the normal registration flow because we only want it to be usable
for activated DayOnes.


<pre><code><b>public</b> <b>fun</b> <a href="discounts.md#0x0_discounts_register_with_day_one">register_with_day_one</a>(self: &<b>mut</b> <a href="house.md#0x0_house_DiscountHouse">house::DiscountHouse</a>, <a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>: &<b>mut</b> <a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins_SuiNS">suins::SuiNS</a>, <a href="dependencies/day_one/day_one.md#0xbf1431324a4a6eadd70e0ac6c5a16f36492f255ed4d011978b2cf34ad738efe6_day_one">day_one</a>: &<a href="dependencies/day_one/day_one.md#0xbf1431324a4a6eadd70e0ac6c5a16f36492f255ed4d011978b2cf34ad738efe6_day_one_DayOne">day_one::DayOne</a>, domain_name: <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>, payment: <a href="dependencies/sui-framework/coin.md#0x2_coin_Coin">coin::Coin</a>&lt;<a href="dependencies/sui-framework/sui.md#0x2_sui_SUI">sui::SUI</a>&gt;, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &<a href="dependencies/sui-framework/clock.md#0x2_clock_Clock">clock::Clock</a>, _reseller: <a href="dependencies/move-stdlib/option.md#0x1_option_Option">option::Option</a>&lt;<a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>&gt;, ctx: &<b>mut</b> <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context_TxContext">tx_context::TxContext</a>): <a href="dependencies/suins/suins_registration.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins_registration_SuinsRegistration">suins_registration::SuinsRegistration</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="discounts.md#0x0_discounts_register_with_day_one">register_with_day_one</a>(
    self: &<b>mut</b> DiscountHouse,
    <a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>: &<b>mut</b> SuiNS,
    <a href="dependencies/day_one/day_one.md#0xbf1431324a4a6eadd70e0ac6c5a16f36492f255ed4d011978b2cf34ad738efe6_day_one">day_one</a>: &DayOne,
    domain_name: String,
    payment: Coin&lt;SUI&gt;,
    <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &Clock,
    _reseller: Option&lt;String&gt;,
    ctx: &<b>mut</b> TxContext
): SuinsRegistration {
    <b>assert</b>!(is_active(<a href="dependencies/day_one/day_one.md#0xbf1431324a4a6eadd70e0ac6c5a16f36492f255ed4d011978b2cf34ad738efe6_day_one">day_one</a>), <a href="discounts.md#0x0_discounts_ENotActiveDayOne">ENotActiveDayOne</a>);
    <a href="discounts.md#0x0_discounts_internal_register_name">internal_register_name</a>&lt;DayOne&gt;(self, <a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>, domain_name, payment, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>, ctx)
}
</code></pre>



</details>

<a name="0x0_discounts_calculate_price"></a>

## Function `calculate_price`

Calculate the price of a label.


<pre><code><b>public</b> <b>fun</b> <a href="discounts.md#0x0_discounts_calculate_price">calculate_price</a>(self: &<a href="discounts.md#0x0_discounts_DiscountConfig">discounts::DiscountConfig</a>, length: u8): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="discounts.md#0x0_discounts_calculate_price">calculate_price</a>(self: &<a href="discounts.md#0x0_discounts_DiscountConfig">DiscountConfig</a>, length: u8): u64 {

    <b>let</b> price = <b>if</b> (length == 3) {
        self.three_char_price
    } <b>else</b> <b>if</b> (length == 4) {
        self.four_char_price
    } <b>else</b> {
        self.five_plus_char_price
    };

    price
}
</code></pre>



</details>

<a name="0x0_discounts_authorize_type"></a>

## Function `authorize_type`

An admin action to authorize a type T for special pricing.


<pre><code><b>public</b> <b>fun</b> <a href="discounts.md#0x0_discounts_authorize_type">authorize_type</a>&lt;T&gt;(_: &<a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins_AdminCap">suins::AdminCap</a>, self: &<b>mut</b> <a href="house.md#0x0_house_DiscountHouse">house::DiscountHouse</a>, three_char_price: u64, four_char_price: u64, five_plus_char_price: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="discounts.md#0x0_discounts_authorize_type">authorize_type</a>&lt;T&gt;(
    _: &AdminCap,
    self: &<b>mut</b> DiscountHouse,
    three_char_price: u64,
    four_char_price: u64,
    five_plus_char_price: u64
) {
    self.assert_version_is_valid();
    <b>assert</b>!(!df::exists_(<a href="house.md#0x0_house_uid_mut">house::uid_mut</a>(self), <a href="discounts.md#0x0_discounts_DiscountKey">DiscountKey</a>&lt;T&gt; {}), <a href="discounts.md#0x0_discounts_EConfigExists">EConfigExists</a>);

    df::add(<a href="house.md#0x0_house_uid_mut">house::uid_mut</a>(self), <a href="discounts.md#0x0_discounts_DiscountKey">DiscountKey</a>&lt;T&gt;{}, <a href="discounts.md#0x0_discounts_DiscountConfig">DiscountConfig</a> {
        three_char_price,
        four_char_price,
        five_plus_char_price
    });
}
</code></pre>



</details>

<a name="0x0_discounts_deauthorize_type"></a>

## Function `deauthorize_type`

An admin action to deauthorize type T from getting discounts.


<pre><code><b>public</b> <b>fun</b> <a href="discounts.md#0x0_discounts_deauthorize_type">deauthorize_type</a>&lt;T&gt;(_: &<a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins_AdminCap">suins::AdminCap</a>, self: &<b>mut</b> <a href="house.md#0x0_house_DiscountHouse">house::DiscountHouse</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="discounts.md#0x0_discounts_deauthorize_type">deauthorize_type</a>&lt;T&gt;(_: &AdminCap, self: &<b>mut</b> DiscountHouse) {
    self.assert_version_is_valid();
    <a href="discounts.md#0x0_discounts_assert_config_exists">assert_config_exists</a>&lt;T&gt;(self);
    df::remove&lt;<a href="discounts.md#0x0_discounts_DiscountKey">DiscountKey</a>&lt;T&gt;, <a href="discounts.md#0x0_discounts_DiscountConfig">DiscountConfig</a>&gt;(self.uid_mut(), <a href="discounts.md#0x0_discounts_DiscountKey">DiscountKey</a>&lt;T&gt;{});
}
</code></pre>



</details>

<a name="0x0_discounts_internal_register_name"></a>

## Function `internal_register_name`

Internal helper to handle the registration process


<pre><code><b>fun</b> <a href="discounts.md#0x0_discounts_internal_register_name">internal_register_name</a>&lt;T&gt;(self: &<b>mut</b> <a href="house.md#0x0_house_DiscountHouse">house::DiscountHouse</a>, <a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>: &<b>mut</b> <a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins_SuiNS">suins::SuiNS</a>, domain_name: <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>, payment: <a href="dependencies/sui-framework/coin.md#0x2_coin_Coin">coin::Coin</a>&lt;<a href="dependencies/sui-framework/sui.md#0x2_sui_SUI">sui::SUI</a>&gt;, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &<a href="dependencies/sui-framework/clock.md#0x2_clock_Clock">clock::Clock</a>, ctx: &<b>mut</b> <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context_TxContext">tx_context::TxContext</a>): <a href="dependencies/suins/suins_registration.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins_registration_SuinsRegistration">suins_registration::SuinsRegistration</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="discounts.md#0x0_discounts_internal_register_name">internal_register_name</a>&lt;T&gt;(
    self: &<b>mut</b> DiscountHouse,
    <a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>: &<b>mut</b> SuiNS,
    domain_name: String,
    payment: Coin&lt;SUI&gt;,
    <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &Clock,
    ctx: &<b>mut</b> TxContext
): SuinsRegistration {
    self.assert_version_is_valid();
    // validate that there's a configuration for type T.
    <a href="discounts.md#0x0_discounts_assert_config_exists">assert_config_exists</a>&lt;T&gt;(self);

    <b>let</b> <a href="dependencies/suins/domain.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_domain">domain</a> = <a href="dependencies/suins/domain.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_domain_new">domain::new</a>(domain_name);
    <b>let</b> price = <a href="discounts.md#0x0_discounts_calculate_price">calculate_price</a>(df::borrow(self.uid_mut(), <a href="discounts.md#0x0_discounts_DiscountKey">DiscountKey</a>&lt;T&gt;{}), (<a href="dependencies/suins/domain.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_domain">domain</a>.sld().length() <b>as</b> u8));

    <b>assert</b>!(payment.value() == price, <a href="discounts.md#0x0_discounts_EIncorrectAmount">EIncorrectAmount</a>);
    <a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins_app_add_balance">suins::app_add_balance</a>(<a href="house.md#0x0_house_suins_app_auth">house::suins_app_auth</a>(), <a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>, payment.into_balance());

    <a href="house.md#0x0_house_friend_add_registry_entry">house::friend_add_registry_entry</a>(<a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>, <a href="dependencies/suins/domain.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_domain">domain</a>, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>, ctx)
}
</code></pre>



</details>

<a name="0x0_discounts_assert_config_exists"></a>

## Function `assert_config_exists`



<pre><code><b>fun</b> <a href="discounts.md#0x0_discounts_assert_config_exists">assert_config_exists</a>&lt;T&gt;(self: &<b>mut</b> <a href="house.md#0x0_house_DiscountHouse">house::DiscountHouse</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="discounts.md#0x0_discounts_assert_config_exists">assert_config_exists</a>&lt;T&gt;(self: &<b>mut</b> DiscountHouse) {
    <b>assert</b>!(df::exists_with_type&lt;<a href="discounts.md#0x0_discounts_DiscountKey">DiscountKey</a>&lt;T&gt;, <a href="discounts.md#0x0_discounts_DiscountConfig">DiscountConfig</a>&gt;(<a href="house.md#0x0_house_uid_mut">house::uid_mut</a>(self), <a href="discounts.md#0x0_discounts_DiscountKey">DiscountKey</a>&lt;T&gt; {}), <a href="discounts.md#0x0_discounts_EConfigNotExists">EConfigNotExists</a>);
}
</code></pre>



</details>
