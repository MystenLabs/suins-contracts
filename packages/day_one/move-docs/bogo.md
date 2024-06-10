
<a name="0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_bogo"></a>

# Module `0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d::bogo`

A simple BOGO that allows a <code>DayOne</code> holder to trade
a domain registered before the expiration day we set
with another one of the same size.


-  [Struct `BogoApp`](#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_bogo_BogoApp)
-  [Struct `UsedInDayOnePromo`](#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_bogo_UsedInDayOnePromo)
-  [Constants](#@Constants_0)
-  [Function `claim`](#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_bogo_claim)
-  [Function `domain_length`](#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_bogo_domain_length)
-  [Function `used_in_promo`](#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_bogo_used_in_promo)
-  [Function `last_valid_expiration`](#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_bogo_last_valid_expiration)
-  [Function `mark_domain_as_used`](#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_bogo_mark_domain_as_used)


<pre><code><b>use</b> <a href="dependencies/move-stdlib/string.md#0x1_string">0x1::string</a>;
<b>use</b> <a href="dependencies/sui-framework/clock.md#0x2_clock">0x2::clock</a>;
<b>use</b> <a href="dependencies/sui-framework/dynamic_field.md#0x2_dynamic_field">0x2::dynamic_field</a>;
<b>use</b> <a href="dependencies/sui-framework/object.md#0x2_object">0x2::object</a>;
<b>use</b> <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context">0x2::tx_context</a>;
<b>use</b> <a href="dependencies/suins/config.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_config">0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94::config</a>;
<b>use</b> <a href="dependencies/suins/domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94::domain</a>;
<b>use</b> <a href="dependencies/suins/registry.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_registry">0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94::registry</a>;
<b>use</b> <a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94::suins</a>;
<b>use</b> <a href="dependencies/suins/suins_registration.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_registration">0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94::suins_registration</a>;
<b>use</b> <a href="day_one.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_day_one">0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d::day_one</a>;
</code></pre>



<a name="0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_bogo_BogoApp"></a>

## Struct `BogoApp`

Authorization token for the BOGO app.
Used to authorize the app to claim free names by using a DayOne object.


<pre><code><b>struct</b> <a href="bogo.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_bogo_BogoApp">BogoApp</a> <b>has</b> drop
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

<a name="0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_bogo_UsedInDayOnePromo"></a>

## Struct `UsedInDayOnePromo`

Dynamic field key which shows that the <code>SuinsRegistration</code> object was
minted from a Day1 promotion.


<pre><code><b>struct</b> <a href="bogo.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_bogo_UsedInDayOnePromo">UsedInDayOnePromo</a> <b>has</b> <b>copy</b>, drop, store
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


<a name="0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_bogo_DEFAULT_DURATION"></a>

Default registration duration is 1 year.


<pre><code><b>const</b> <a href="bogo.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_bogo_DEFAULT_DURATION">DEFAULT_DURATION</a>: u8 = 1;
</code></pre>



<a name="0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_bogo_EDomainAlreadyUsed"></a>

This domain has already been used to mint a free domain.


<pre><code><b>const</b> <a href="bogo.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_bogo_EDomainAlreadyUsed">EDomainAlreadyUsed</a>: u64 = 0;
</code></pre>



<a name="0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_bogo_ENotPurchasedInAuction"></a>

Domain was not bought in an auction.


<pre><code><b>const</b> <a href="bogo.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_bogo_ENotPurchasedInAuction">ENotPurchasedInAuction</a>: u64 = 1;
</code></pre>



<a name="0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_bogo_ESizeMissMatch"></a>

Domain user tries to purchase has a size missmatch. Only applicable for 3 + 4 length domains.


<pre><code><b>const</b> <a href="bogo.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_bogo_ESizeMissMatch">ESizeMissMatch</a>: u64 = 2;
</code></pre>



<a name="0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_bogo_LAST_VALID_EXPIRATION_DATE"></a>

This will define if a domain name was bought in an auction.
The only way to understand that, is to check that the expiration day is
less than last_day of auctions + 1 year.


<pre><code><b>const</b> <a href="bogo.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_bogo_LAST_VALID_EXPIRATION_DATE">LAST_VALID_EXPIRATION_DATE</a>: u64 = 1721499031000;
</code></pre>



<a name="0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_bogo_claim"></a>

## Function `claim`

We have a requirement that this promotion will run for a specified amount of time (30 Days).
I believe it's better to deauthorize the app when we do not want to have it any more,
instead of hard-coding the limits here.


<pre><code><b>public</b> <b>fun</b> <a href="bogo.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_bogo_claim">claim</a>(day_one_nft: &<b>mut</b> <a href="day_one.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_day_one_DayOne">day_one::DayOne</a>, <a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>: &<b>mut</b> <a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_SuiNS">suins::SuiNS</a>, domain_nft: &<b>mut</b> <a href="dependencies/suins/suins_registration.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_registration_SuinsRegistration">suins_registration::SuinsRegistration</a>, domain_name: <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &<a href="dependencies/sui-framework/clock.md#0x2_clock_Clock">clock::Clock</a>, ctx: &<b>mut</b> <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context_TxContext">tx_context::TxContext</a>): <a href="dependencies/suins/suins_registration.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_registration_SuinsRegistration">suins_registration::SuinsRegistration</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="bogo.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_bogo_claim">claim</a>(
    day_one_nft: &<b>mut</b> DayOne,
    <a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>: &<b>mut</b> SuiNS,
    domain_nft: &<b>mut</b> SuinsRegistration,
    domain_name: String,
    <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &Clock,
    ctx: &<b>mut</b> TxContext,
): SuinsRegistration {
    // verify we can register names using this app.
    <a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>.assert_app_is_authorized&lt;<a href="bogo.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_bogo_BogoApp">BogoApp</a>&gt;();

    // check that domain_nft hasn't been already used in this deal.
    <b>assert</b>!(!<a href="bogo.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_bogo_used_in_promo">used_in_promo</a>(domain_nft), <a href="bogo.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_bogo_EDomainAlreadyUsed">EDomainAlreadyUsed</a>);

    // Verify that the <a href="dependencies/suins/domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a> was bought in an auction.
    // We understand <b>if</b> a <a href="dependencies/suins/domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a> was bought in an auction <b>if</b> the expiry date is less than the last day of auction + 1 year.
    <b>assert</b>!(domain_nft.expiration_timestamp_ms() &lt;= <a href="bogo.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_bogo_LAST_VALID_EXPIRATION_DATE">LAST_VALID_EXPIRATION_DATE</a>, <a href="bogo.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_bogo_ENotPurchasedInAuction">ENotPurchasedInAuction</a>);

    // generate a <a href="dependencies/suins/domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a> out of the input <a href="dependencies/move-stdlib/string.md#0x1_string">string</a>.
    <b>let</b> new_domain = <a href="dependencies/suins/domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_new">domain::new</a>(domain_name);
    <b>let</b> new_domain_size = <a href="bogo.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_bogo_domain_length">domain_length</a>(&new_domain);

    <b>let</b> domain_size = <a href="bogo.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_bogo_domain_length">domain_length</a>(&domain_nft.<a href="dependencies/suins/domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a>());

    // make sure the <a href="dependencies/suins/domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a> is valid.
    <a href="dependencies/suins/config.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_config_assert_valid_user_registerable_domain">config::assert_valid_user_registerable_domain</a>(&new_domain);

    // <b>if</b> size &lt; 5, we need <b>to</b> make sure we're getting a <a href="dependencies/suins/domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a> name of the same size.
    <b>assert</b>!(!((domain_size &lt; 5 || new_domain_size &lt; 5) && domain_size != new_domain_size), <a href="bogo.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_bogo_ESizeMissMatch">ESizeMissMatch</a>);

    // activate the day_one_nft <b>if</b> it's not activated.
    // This will grant it access <b>to</b> future promotions.
    <b>if</b>(!<a href="day_one.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_day_one_is_active">day_one::is_active</a>(day_one_nft)) <a href="day_one.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_day_one_activate">day_one::activate</a>(day_one_nft);

    <b>let</b> <a href="dependencies/suins/registry.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_registry">registry</a> = <a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_app_registry_mut">suins::app_registry_mut</a>&lt;<a href="bogo.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_bogo_BogoApp">BogoApp</a>, Registry&gt;(<a href="bogo.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_bogo_BogoApp">BogoApp</a> {}, <a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>);
    <b>let</b> <b>mut</b> nft = <a href="dependencies/suins/registry.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_registry">registry</a>.add_record(new_domain, <a href="bogo.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_bogo_DEFAULT_DURATION">DEFAULT_DURATION</a>, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>, ctx);

    // mark both the new and the current <a href="dependencies/suins/domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a> presented <b>as</b> used, so that they can't
    // be redeemed twice in this deal.
    <a href="bogo.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_bogo_mark_domain_as_used">mark_domain_as_used</a>(domain_nft);
    <a href="bogo.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_bogo_mark_domain_as_used">mark_domain_as_used</a>(&<b>mut</b> nft);

    nft
}
</code></pre>



</details>

<a name="0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_bogo_domain_length"></a>

## Function `domain_length`

Returns the size of a domain name. (e.g test.sui -> 4)


<pre><code><b>fun</b> <a href="bogo.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_bogo_domain_length">domain_length</a>(<a href="dependencies/suins/domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a>: &<a href="dependencies/suins/domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_Domain">domain::Domain</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="bogo.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_bogo_domain_length">domain_length</a>(<a href="dependencies/suins/domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a>: &Domain): u64{
    <a href="dependencies/move-stdlib/string.md#0x1_string_length">string::length</a>(<a href="dependencies/suins/domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a>.sld())
}
</code></pre>



</details>

<a name="0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_bogo_used_in_promo"></a>

## Function `used_in_promo`

Check if the domain has been minted for free from this bogo promo.


<pre><code><b>public</b> <b>fun</b> <a href="bogo.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_bogo_used_in_promo">used_in_promo</a>(domain_nft: &<a href="dependencies/suins/suins_registration.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_registration_SuinsRegistration">suins_registration::SuinsRegistration</a>): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="bogo.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_bogo_used_in_promo">used_in_promo</a>(domain_nft: &SuinsRegistration): bool {
    df::exists_(domain_nft.uid(), <a href="bogo.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_bogo_UsedInDayOnePromo">UsedInDayOnePromo</a> {})
}
</code></pre>



</details>

<a name="0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_bogo_last_valid_expiration"></a>

## Function `last_valid_expiration`



<pre><code><b>public</b> <b>fun</b> <a href="bogo.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_bogo_last_valid_expiration">last_valid_expiration</a>(): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="bogo.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_bogo_last_valid_expiration">last_valid_expiration</a>(): u64 {
    <a href="bogo.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_bogo_LAST_VALID_EXPIRATION_DATE">LAST_VALID_EXPIRATION_DATE</a>
}
</code></pre>



</details>

<a name="0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_bogo_mark_domain_as_used"></a>

## Function `mark_domain_as_used`

Attaches a DF that marks a domain as <code>used</code> in another day 1 object.


<pre><code><b>fun</b> <a href="bogo.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_bogo_mark_domain_as_used">mark_domain_as_used</a>(domain_nft: &<b>mut</b> <a href="dependencies/suins/suins_registration.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_registration_SuinsRegistration">suins_registration::SuinsRegistration</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="bogo.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_bogo_mark_domain_as_used">mark_domain_as_used</a>(domain_nft: &<b>mut</b> SuinsRegistration) {
    df::add(domain_nft.uid_mut(), <a href="bogo.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_bogo_UsedInDayOnePromo">UsedInDayOnePromo</a> {}, <b>true</b>)
}
</code></pre>



</details>
