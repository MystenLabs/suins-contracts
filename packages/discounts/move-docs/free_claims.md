
<a name="0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims"></a>

# Module `0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d::free_claims`

A module that allows claiming names of a set length for free by presenting an object T.
Each <code>T</code> can have a separate configuration for a discount percentage.
If a <code>T</code> doesn't exist, registration will fail.

Can be called only when promotions are active for a specific type T.
Activation / deactivation happens through PTBs.


-  [Struct `FreeClaimsApp`](#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_FreeClaimsApp)
-  [Struct `FreeClaimsKey`](#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_FreeClaimsKey)
-  [Struct `FreeClaimsConfig`](#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_FreeClaimsConfig)
-  [Constants](#@Constants_0)
-  [Function `free_claim`](#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_free_claim)
-  [Function `free_claim_with_day_one`](#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_free_claim_with_day_one)
-  [Function `internal_claim_free_name`](#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_internal_claim_free_name)
-  [Function `authorize_type`](#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_authorize_type)
-  [Function `deauthorize_type`](#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_deauthorize_type)
-  [Function `force_deauthorize_type`](#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_force_deauthorize_type)
-  [Function `assert_config_exists`](#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_assert_config_exists)
-  [Function `assert_domain_length_eligible`](#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_assert_domain_length_eligible)
-  [Function `assert_valid_length_setup`](#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_assert_valid_length_setup)


<pre><code><b>use</b> <a href="dependencies/move-stdlib/ascii.md#0x1_ascii">0x1::ascii</a>;
<b>use</b> <a href="dependencies/move-stdlib/string.md#0x1_string">0x1::string</a>;
<b>use</b> <a href="dependencies/move-stdlib/type_name.md#0x1_type_name">0x1::type_name</a>;
<b>use</b> <a href="dependencies/sui-framework/clock.md#0x2_clock">0x2::clock</a>;
<b>use</b> <a href="dependencies/sui-framework/dynamic_field.md#0x2_dynamic_field">0x2::dynamic_field</a>;
<b>use</b> <a href="dependencies/sui-framework/linked_table.md#0x2_linked_table">0x2::linked_table</a>;
<b>use</b> <a href="dependencies/sui-framework/object.md#0x2_object">0x2::object</a>;
<b>use</b> <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context">0x2::tx_context</a>;
<b>use</b> <a href="dependencies/suins/domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b::domain</a>;
<b>use</b> <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b::suins</a>;
<b>use</b> <a href="dependencies/suins/suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration">0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b::suins_registration</a>;
<b>use</b> <a href="dependencies/day_one/day_one.md#0x50f27a05cbfb319617403dec4a4c420e4b0c6cc139a9af9305218bd4dddc2a4f_day_one">0x50f27a05cbfb319617403dec4a4c420e4b0c6cc139a9af9305218bd4dddc2a4f::day_one</a>;
<b>use</b> <a href="house.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_house">0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d::house</a>;
</code></pre>



<a name="0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_FreeClaimsApp"></a>

## Struct `FreeClaimsApp`

A key to authorize DiscountHouse to register names on SuiNS.


<pre><code><b>struct</b> <a href="free_claims.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_FreeClaimsApp">FreeClaimsApp</a> <b>has</b> drop
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

<a name="0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_FreeClaimsKey"></a>

## Struct `FreeClaimsKey`

A key that opens up free claims for type T.


<pre><code><b>struct</b> <a href="free_claims.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_FreeClaimsKey">FreeClaimsKey</a>&lt;T&gt; <b>has</b> <b>copy</b>, drop, store
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

<a name="0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_FreeClaimsConfig"></a>

## Struct `FreeClaimsConfig`

We hold the configuration for the promotion
We only allow 1 claim / per configuration / per promotion.
We keep the used ids as a LinkedTable so we can get our rebates when closing the promotion.


<pre><code><b>struct</b> <a href="free_claims.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_FreeClaimsConfig">FreeClaimsConfig</a> <b>has</b> store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>domain_length_range: <a href="dependencies/move-stdlib/vector.md#0x1_vector">vector</a>&lt;u8&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>used_objects: <a href="dependencies/sui-framework/linked_table.md#0x2_linked_table_LinkedTable">linked_table::LinkedTable</a>&lt;<a href="dependencies/sui-framework/object.md#0x2_object_ID">object::ID</a>, bool&gt;</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="@Constants_0"></a>

## Constants


<a name="0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_EConfigExists"></a>

A configuration already exists


<pre><code><b>const</b> <a href="free_claims.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_EConfigExists">EConfigExists</a>: u64 = 1;
</code></pre>



<a name="0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_EConfigNotExists"></a>

A configuration doesn't exist


<pre><code><b>const</b> <a href="free_claims.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_EConfigNotExists">EConfigNotExists</a>: u64 = 2;
</code></pre>



<a name="0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_ENotActiveDayOne"></a>

Tries to claim with a non active DayOne


<pre><code><b>const</b> <a href="free_claims.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_ENotActiveDayOne">ENotActiveDayOne</a>: u64 = 6;
</code></pre>



<a name="0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_ENotValidForDayOne"></a>

Tries to use DayOne on regular register flow.


<pre><code><b>const</b> <a href="free_claims.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_ENotValidForDayOne">ENotValidForDayOne</a>: u64 = 5;
</code></pre>



<a name="0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_EAlreadyClaimed"></a>

Object has already been used in this promotion.


<pre><code><b>const</b> <a href="free_claims.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_EAlreadyClaimed">EAlreadyClaimed</a>: u64 = 4;
</code></pre>



<a name="0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_EInvalidCharacterRange"></a>

Invalid length array


<pre><code><b>const</b> <a href="free_claims.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_EInvalidCharacterRange">EInvalidCharacterRange</a>: u64 = 3;
</code></pre>



<a name="0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_free_claim"></a>

## Function `free_claim`

A function to register a name with a discount using type <code>T</code>.


<pre><code><b>public</b> <b>fun</b> <a href="free_claims.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_free_claim">free_claim</a>&lt;T: key&gt;(self: &<b>mut</b> <a href="house.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_house_DiscountHouse">house::DiscountHouse</a>, <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>: &<b>mut</b> <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_SuiNS">suins::SuiNS</a>, <a href="dependencies/sui-framework/object.md#0x2_object">object</a>: &T, domain_name: <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &<a href="dependencies/sui-framework/clock.md#0x2_clock_Clock">clock::Clock</a>, ctx: &<b>mut</b> <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context_TxContext">tx_context::TxContext</a>): <a href="dependencies/suins/suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_SuinsRegistration">suins_registration::SuinsRegistration</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="free_claims.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_free_claim">free_claim</a>&lt;T: key&gt;(
    self: &<b>mut</b> DiscountHouse,
    <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>: &<b>mut</b> SuiNS,
    <a href="dependencies/sui-framework/object.md#0x2_object">object</a>: &T,
    domain_name: String,
    <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &Clock,
    ctx: &<b>mut</b> TxContext
): SuinsRegistration {
    // For normal flow, we do not allow DayOne <b>to</b> be used.
    // DayOne can only be used on `register_with_day_one` function.
    <b>assert</b>!(`type`::into_string(`type`::get&lt;T&gt;()) != `type`::into_string(`type`::get&lt;DayOne&gt;()), <a href="free_claims.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_ENotValidForDayOne">ENotValidForDayOne</a>);

    <a href="free_claims.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_internal_claim_free_name">internal_claim_free_name</a>&lt;T&gt;(self, <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>, domain_name, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>, <a href="dependencies/sui-framework/object.md#0x2_object">object</a>, ctx)
}
</code></pre>



</details>

<a name="0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_free_claim_with_day_one"></a>

## Function `free_claim_with_day_one`



<pre><code><b>public</b> <b>fun</b> <a href="free_claims.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_free_claim_with_day_one">free_claim_with_day_one</a>(self: &<b>mut</b> <a href="house.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_house_DiscountHouse">house::DiscountHouse</a>, <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>: &<b>mut</b> <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_SuiNS">suins::SuiNS</a>, <a href="dependencies/day_one/day_one.md#0x50f27a05cbfb319617403dec4a4c420e4b0c6cc139a9af9305218bd4dddc2a4f_day_one">day_one</a>: &<a href="dependencies/day_one/day_one.md#0x50f27a05cbfb319617403dec4a4c420e4b0c6cc139a9af9305218bd4dddc2a4f_day_one_DayOne">day_one::DayOne</a>, domain_name: <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &<a href="dependencies/sui-framework/clock.md#0x2_clock_Clock">clock::Clock</a>, ctx: &<b>mut</b> <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context_TxContext">tx_context::TxContext</a>): <a href="dependencies/suins/suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_SuinsRegistration">suins_registration::SuinsRegistration</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="free_claims.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_free_claim_with_day_one">free_claim_with_day_one</a>(
    self: &<b>mut</b> DiscountHouse,
    <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>: &<b>mut</b> SuiNS,
    <a href="dependencies/day_one/day_one.md#0x50f27a05cbfb319617403dec4a4c420e4b0c6cc139a9af9305218bd4dddc2a4f_day_one">day_one</a>: &DayOne,
    domain_name: String,
    <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &Clock,
    ctx: &<b>mut</b> TxContext
): SuinsRegistration {
    <b>assert</b>!(is_active(<a href="dependencies/day_one/day_one.md#0x50f27a05cbfb319617403dec4a4c420e4b0c6cc139a9af9305218bd4dddc2a4f_day_one">day_one</a>), <a href="free_claims.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_ENotActiveDayOne">ENotActiveDayOne</a>);
    <a href="free_claims.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_internal_claim_free_name">internal_claim_free_name</a>&lt;DayOne&gt;(self, <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>, domain_name, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>, <a href="dependencies/day_one/day_one.md#0x50f27a05cbfb319617403dec4a4c420e4b0c6cc139a9af9305218bd4dddc2a4f_day_one">day_one</a>, ctx)
}
</code></pre>



</details>

<a name="0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_internal_claim_free_name"></a>

## Function `internal_claim_free_name`

Internal helper that checks if there's a valid configuration for T,
validates that the domain name is of vlaid length, and then does the registration.


<pre><code><b>fun</b> <a href="free_claims.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_internal_claim_free_name">internal_claim_free_name</a>&lt;T: key&gt;(self: &<b>mut</b> <a href="house.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_house_DiscountHouse">house::DiscountHouse</a>, <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>: &<b>mut</b> <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_SuiNS">suins::SuiNS</a>, domain_name: <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &<a href="dependencies/sui-framework/clock.md#0x2_clock_Clock">clock::Clock</a>, <a href="dependencies/sui-framework/object.md#0x2_object">object</a>: &T, ctx: &<b>mut</b> <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context_TxContext">tx_context::TxContext</a>): <a href="dependencies/suins/suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_SuinsRegistration">suins_registration::SuinsRegistration</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="free_claims.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_internal_claim_free_name">internal_claim_free_name</a>&lt;T: key&gt;(
    self: &<b>mut</b> DiscountHouse,
    <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>: &<b>mut</b> SuiNS,
    domain_name: String,
    <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &Clock,
    <a href="dependencies/sui-framework/object.md#0x2_object">object</a>: &T,
    ctx: &<b>mut</b> TxContext
): SuinsRegistration {
    self.assert_version_is_valid();
    // validate that there's a configuration for type T.
    <a href="free_claims.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_assert_config_exists">assert_config_exists</a>&lt;T&gt;(self);

    // We only allow one free registration per <a href="dependencies/sui-framework/object.md#0x2_object">object</a>.
    // We shall check the id hasn't been used before first.
    <b>let</b> id = <a href="dependencies/sui-framework/object.md#0x2_object_id">object::id</a>&lt;T&gt;(<a href="dependencies/sui-framework/object.md#0x2_object">object</a>);

    // validate that the supplied <a href="dependencies/sui-framework/object.md#0x2_object">object</a> hasn't been used <b>to</b> claim a free name.
    <b>let</b> <a href="dependencies/suins/config.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_config">config</a> = df::borrow_mut&lt;<a href="free_claims.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_FreeClaimsKey">FreeClaimsKey</a>&lt;T&gt;, <a href="free_claims.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_FreeClaimsConfig">FreeClaimsConfig</a>&gt;(self.uid_mut(), <a href="free_claims.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_FreeClaimsKey">FreeClaimsKey</a>&lt;T&gt;{});
    <b>assert</b>!(!<a href="dependencies/suins/config.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_config">config</a>.used_objects.contains(id), <a href="free_claims.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_EAlreadyClaimed">EAlreadyClaimed</a>);

    // add the supplied <a href="dependencies/sui-framework/object.md#0x2_object">object</a>'s id <b>to</b> the used objects list.
    <a href="dependencies/suins/config.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_config">config</a>.used_objects.push_back(id, <b>true</b>);

    // Now validate the <a href="dependencies/suins/domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>, and that the rule applies here.
    <b>let</b> <a href="dependencies/suins/domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a> = <a href="dependencies/suins/domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain_new">domain::new</a>(domain_name);
    <a href="free_claims.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_assert_domain_length_eligible">assert_domain_length_eligible</a>(&<a href="dependencies/suins/domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>, <a href="dependencies/suins/config.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_config">config</a>);

    <a href="house.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_house_friend_add_registry_entry">house::friend_add_registry_entry</a>(<a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>, <a href="dependencies/suins/domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>, ctx)
}
</code></pre>



</details>

<a name="0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_authorize_type"></a>

## Function `authorize_type`

An admin action to authorize a type T for free claiming of names by presenting
an object of type <code>T</code>.


<pre><code><b>public</b> <b>fun</b> <a href="free_claims.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_authorize_type">authorize_type</a>&lt;T: key&gt;(_: &<a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_AdminCap">suins::AdminCap</a>, self: &<b>mut</b> <a href="house.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_house_DiscountHouse">house::DiscountHouse</a>, domain_length_range: <a href="dependencies/move-stdlib/vector.md#0x1_vector">vector</a>&lt;u8&gt;, ctx: &<b>mut</b> <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="free_claims.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_authorize_type">authorize_type</a>&lt;T: key&gt;(
    _: &AdminCap,
    self: &<b>mut</b> DiscountHouse,
    domain_length_range: <a href="dependencies/move-stdlib/vector.md#0x1_vector">vector</a>&lt;u8&gt;,
    ctx: &<b>mut</b> TxContext
) {
    self.assert_version_is_valid();
    <b>assert</b>!(!df::exists_(self.uid_mut(), <a href="free_claims.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_FreeClaimsKey">FreeClaimsKey</a>&lt;T&gt; {}), <a href="free_claims.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_EConfigExists">EConfigExists</a>);

    // validate the range is valid.
    <a href="free_claims.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_assert_valid_length_setup">assert_valid_length_setup</a>(&domain_length_range);

    df::add(self.uid_mut(), <a href="free_claims.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_FreeClaimsKey">FreeClaimsKey</a>&lt;T&gt;{}, <a href="free_claims.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_FreeClaimsConfig">FreeClaimsConfig</a> {
        domain_length_range,
        used_objects: <a href="dependencies/sui-framework/linked_table.md#0x2_linked_table_new">linked_table::new</a>(ctx)
    });
}
</code></pre>



</details>

<a name="0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_deauthorize_type"></a>

## Function `deauthorize_type`

An admin action to deauthorize type T from getting discounts.
Deauthorization also brings storage rebates by destroying the table of used objects.
If we re-authorize a type, objects can be re-used, but that's considered a separate promotion.


<pre><code><b>public</b> <b>fun</b> <a href="free_claims.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_deauthorize_type">deauthorize_type</a>&lt;T&gt;(_: &<a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_AdminCap">suins::AdminCap</a>, self: &<b>mut</b> <a href="house.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_house_DiscountHouse">house::DiscountHouse</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="free_claims.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_deauthorize_type">deauthorize_type</a>&lt;T&gt;(_: &AdminCap, self: &<b>mut</b> DiscountHouse) {
    self.assert_version_is_valid();
    <a href="free_claims.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_assert_config_exists">assert_config_exists</a>&lt;T&gt;(self);
    <b>let</b> <a href="free_claims.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_FreeClaimsConfig">FreeClaimsConfig</a> { <b>mut</b> used_objects, domain_length_range: _ } = df::remove&lt;<a href="free_claims.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_FreeClaimsKey">FreeClaimsKey</a>&lt;T&gt;, <a href="free_claims.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_FreeClaimsConfig">FreeClaimsConfig</a>&gt;(self.uid_mut(), <a href="free_claims.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_FreeClaimsKey">FreeClaimsKey</a>&lt;T&gt;{});

    // parse each entry and remove it. Gives us storage rebates.
    <b>while</b>(used_objects.length() &gt; 0) {
        used_objects.pop_front();
    };

    used_objects.destroy_empty();
}
</code></pre>



</details>

<a name="0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_force_deauthorize_type"></a>

## Function `force_deauthorize_type`

Worried by the 1000 DFs load limit, I introduce a <code>drop_type</code> function now
to make sure we can force-finish a promotion for type <code>T</code>.


<pre><code><b>public</b> <b>fun</b> <a href="free_claims.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_force_deauthorize_type">force_deauthorize_type</a>&lt;T&gt;(_: &<a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_AdminCap">suins::AdminCap</a>, self: &<b>mut</b> <a href="house.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_house_DiscountHouse">house::DiscountHouse</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="free_claims.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_force_deauthorize_type">force_deauthorize_type</a>&lt;T&gt;(_: &AdminCap, self: &<b>mut</b> DiscountHouse) {
    self.assert_version_is_valid();
    <a href="free_claims.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_assert_config_exists">assert_config_exists</a>&lt;T&gt;(self);
    <b>let</b> <a href="free_claims.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_FreeClaimsConfig">FreeClaimsConfig</a> { used_objects, domain_length_range: _ } = df::remove&lt;<a href="free_claims.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_FreeClaimsKey">FreeClaimsKey</a>&lt;T&gt;, <a href="free_claims.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_FreeClaimsConfig">FreeClaimsConfig</a>&gt;(self.uid_mut(), <a href="free_claims.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_FreeClaimsKey">FreeClaimsKey</a>&lt;T&gt;{});
    used_objects.drop();
}
</code></pre>



</details>

<a name="0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_assert_config_exists"></a>

## Function `assert_config_exists`



<pre><code><b>fun</b> <a href="free_claims.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_assert_config_exists">assert_config_exists</a>&lt;T&gt;(self: &<b>mut</b> <a href="house.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_house_DiscountHouse">house::DiscountHouse</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="free_claims.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_assert_config_exists">assert_config_exists</a>&lt;T&gt;(self: &<b>mut</b> DiscountHouse) {
    <b>assert</b>!(df::exists_with_type&lt;<a href="free_claims.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_FreeClaimsKey">FreeClaimsKey</a>&lt;T&gt;, <a href="free_claims.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_FreeClaimsConfig">FreeClaimsConfig</a>&gt;(self.uid_mut(), <a href="free_claims.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_FreeClaimsKey">FreeClaimsKey</a>&lt;T&gt; {}), <a href="free_claims.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_EConfigNotExists">EConfigNotExists</a>);
}
</code></pre>



</details>

<a name="0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_assert_domain_length_eligible"></a>

## Function `assert_domain_length_eligible`

Validate that the domain length is valid for the passed configuration.


<pre><code><b>fun</b> <a href="free_claims.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_assert_domain_length_eligible">assert_domain_length_eligible</a>(<a href="dependencies/suins/domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>: &<a href="dependencies/suins/domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain_Domain">domain::Domain</a>, <a href="dependencies/suins/config.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_config">config</a>: &<a href="free_claims.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_FreeClaimsConfig">free_claims::FreeClaimsConfig</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="free_claims.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_assert_domain_length_eligible">assert_domain_length_eligible</a>(<a href="dependencies/suins/domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>: &Domain, <a href="dependencies/suins/config.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_config">config</a>: &<a href="free_claims.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_FreeClaimsConfig">FreeClaimsConfig</a>) {
    <b>let</b> domain_length = (<a href="dependencies/suins/domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>.sld().length() <b>as</b> u8);
    <b>let</b> from = <a href="dependencies/suins/config.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_config">config</a>.domain_length_range[0];
    <b>let</b> <b>to</b> = <a href="dependencies/suins/config.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_config">config</a>.domain_length_range[1];

    <b>assert</b>!(domain_length &gt;= from && domain_length &lt;= <b>to</b>, <a href="free_claims.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_EInvalidCharacterRange">EInvalidCharacterRange</a>);
}
</code></pre>



</details>

<a name="0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_assert_valid_length_setup"></a>

## Function `assert_valid_length_setup`



<pre><code><b>fun</b> <a href="free_claims.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_assert_valid_length_setup">assert_valid_length_setup</a>(domain_length_range: &<a href="dependencies/move-stdlib/vector.md#0x1_vector">vector</a>&lt;u8&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="free_claims.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_assert_valid_length_setup">assert_valid_length_setup</a>(domain_length_range: &<a href="dependencies/move-stdlib/vector.md#0x1_vector">vector</a>&lt;u8&gt;) {
    <b>assert</b>!(domain_length_range.length() == 2, <a href="free_claims.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_EInvalidCharacterRange">EInvalidCharacterRange</a>);

    <b>let</b> from = domain_length_range[0];
    <b>let</b> <b>to</b> = domain_length_range[1];

    <b>assert</b>!(<b>to</b> &gt;= from, <a href="free_claims.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_free_claims_EInvalidCharacterRange">EInvalidCharacterRange</a>);
}
</code></pre>



</details>
