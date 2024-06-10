
<a name="0x2acc85a8f3bb96abb72ec06df0a9ac9b8026d6081560bf1f614531ec9fd93575_renew"></a>

# Module `0x2acc85a8f3bb96abb72ec06df0a9ac9b8026d6081560bf1f614531ec9fd93575::renew`

A renewal module for the SuiNS app.
This module allows users to renew their domains.

The renewal is capped at 5 years.


-  [Struct `Renew`](#0x2acc85a8f3bb96abb72ec06df0a9ac9b8026d6081560bf1f614531ec9fd93575_renew_Renew)
-  [Struct `NameRenewed`](#0x2acc85a8f3bb96abb72ec06df0a9ac9b8026d6081560bf1f614531ec9fd93575_renew_NameRenewed)
-  [Struct `RenewalConfig`](#0x2acc85a8f3bb96abb72ec06df0a9ac9b8026d6081560bf1f614531ec9fd93575_renew_RenewalConfig)
-  [Constants](#@Constants_0)
-  [Function `setup`](#0x2acc85a8f3bb96abb72ec06df0a9ac9b8026d6081560bf1f614531ec9fd93575_renew_setup)
-  [Function `renew`](#0x2acc85a8f3bb96abb72ec06df0a9ac9b8026d6081560bf1f614531ec9fd93575_renew_renew)
-  [Function `target_expiration`](#0x2acc85a8f3bb96abb72ec06df0a9ac9b8026d6081560bf1f614531ec9fd93575_renew_target_expiration)
-  [Function `validate_payment`](#0x2acc85a8f3bb96abb72ec06df0a9ac9b8026d6081560bf1f614531ec9fd93575_renew_validate_payment)


<pre><code><b>use</b> <a href="dependencies/move-stdlib/option.md#0x1_option">0x1::option</a>;
<b>use</b> <a href="dependencies/move-stdlib/string.md#0x1_string">0x1::string</a>;
<b>use</b> <a href="dependencies/sui-framework/balance.md#0x2_balance">0x2::balance</a>;
<b>use</b> <a href="dependencies/sui-framework/clock.md#0x2_clock">0x2::clock</a>;
<b>use</b> <a href="dependencies/sui-framework/coin.md#0x2_coin">0x2::coin</a>;
<b>use</b> <a href="dependencies/sui-framework/event.md#0x2_event">0x2::event</a>;
<b>use</b> <a href="dependencies/sui-framework/object.md#0x2_object">0x2::object</a>;
<b>use</b> <a href="dependencies/sui-framework/sui.md#0x2_sui">0x2::sui</a>;
<b>use</b> <a href="dependencies/suins/config.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_config">0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94::config</a>;
<b>use</b> <a href="dependencies/suins/constants.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_constants">0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94::constants</a>;
<b>use</b> <a href="dependencies/suins/domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94::domain</a>;
<b>use</b> <a href="dependencies/suins/name_record.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record">0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94::name_record</a>;
<b>use</b> <a href="dependencies/suins/registry.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_registry">0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94::registry</a>;
<b>use</b> <a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94::suins</a>;
<b>use</b> <a href="dependencies/suins/suins_registration.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_registration">0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94::suins_registration</a>;
</code></pre>



<a name="0x2acc85a8f3bb96abb72ec06df0a9ac9b8026d6081560bf1f614531ec9fd93575_renew_Renew"></a>

## Struct `Renew`

Authorization token for the app.


<pre><code><b>struct</b> <a href="renew.md#0x2acc85a8f3bb96abb72ec06df0a9ac9b8026d6081560bf1f614531ec9fd93575_renew_Renew">Renew</a> <b>has</b> drop
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

<a name="0x2acc85a8f3bb96abb72ec06df0a9ac9b8026d6081560bf1f614531ec9fd93575_renew_NameRenewed"></a>

## Struct `NameRenewed`

An event to help track financial transactions


<pre><code><b>struct</b> <a href="renew.md#0x2acc85a8f3bb96abb72ec06df0a9ac9b8026d6081560bf1f614531ec9fd93575_renew_NameRenewed">NameRenewed</a> <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code><a href="dependencies/suins/domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a>: <a href="dependencies/suins/domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_Domain">domain::Domain</a></code>
</dt>
<dd>

</dd>
<dt>
<code>amount: u64</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0x2acc85a8f3bb96abb72ec06df0a9ac9b8026d6081560bf1f614531ec9fd93575_renew_RenewalConfig"></a>

## Struct `RenewalConfig`

The renewal's package configuration.


<pre><code><b>struct</b> <a href="renew.md#0x2acc85a8f3bb96abb72ec06df0a9ac9b8026d6081560bf1f614531ec9fd93575_renew_RenewalConfig">RenewalConfig</a> <b>has</b> drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code><a href="dependencies/suins/config.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_config">config</a>: <a href="dependencies/suins/config.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_config_Config">config::Config</a></code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="@Constants_0"></a>

## Constants


<a name="0x2acc85a8f3bb96abb72ec06df0a9ac9b8026d6081560bf1f614531ec9fd93575_renew_ERecordExpired"></a>



<pre><code><b>const</b> <a href="renew.md#0x2acc85a8f3bb96abb72ec06df0a9ac9b8026d6081560bf1f614531ec9fd93575_renew_ERecordExpired">ERecordExpired</a>: u64 = 5;
</code></pre>



<a name="0x2acc85a8f3bb96abb72ec06df0a9ac9b8026d6081560bf1f614531ec9fd93575_renew_ERecordNotFound"></a>



<pre><code><b>const</b> <a href="renew.md#0x2acc85a8f3bb96abb72ec06df0a9ac9b8026d6081560bf1f614531ec9fd93575_renew_ERecordNotFound">ERecordNotFound</a>: u64 = 3;
</code></pre>



<a name="0x2acc85a8f3bb96abb72ec06df0a9ac9b8026d6081560bf1f614531ec9fd93575_renew_EIncorrectAmount"></a>

The payment does not match the price for the domain.


<pre><code><b>const</b> <a href="renew.md#0x2acc85a8f3bb96abb72ec06df0a9ac9b8026d6081560bf1f614531ec9fd93575_renew_EIncorrectAmount">EIncorrectAmount</a>: u64 = 1;
</code></pre>



<a name="0x2acc85a8f3bb96abb72ec06df0a9ac9b8026d6081560bf1f614531ec9fd93575_renew_EInvalidYearsArgument"></a>

Number of years passed is not within [1-5] interval.


<pre><code><b>const</b> <a href="renew.md#0x2acc85a8f3bb96abb72ec06df0a9ac9b8026d6081560bf1f614531ec9fd93575_renew_EInvalidYearsArgument">EInvalidYearsArgument</a>: u64 = 0;
</code></pre>



<a name="0x2acc85a8f3bb96abb72ec06df0a9ac9b8026d6081560bf1f614531ec9fd93575_renew_EMoreThanSixYears"></a>

Tries to renew a name more than 6 years in the future.
Our renewal is capped at 5 years.


<pre><code><b>const</b> <a href="renew.md#0x2acc85a8f3bb96abb72ec06df0a9ac9b8026d6081560bf1f614531ec9fd93575_renew_EMoreThanSixYears">EMoreThanSixYears</a>: u64 = 2;
</code></pre>



<a name="0x2acc85a8f3bb96abb72ec06df0a9ac9b8026d6081560bf1f614531ec9fd93575_renew_ERecordNftIDMismatch"></a>



<pre><code><b>const</b> <a href="renew.md#0x2acc85a8f3bb96abb72ec06df0a9ac9b8026d6081560bf1f614531ec9fd93575_renew_ERecordNftIDMismatch">ERecordNftIDMismatch</a>: u64 = 4;
</code></pre>



<a name="0x2acc85a8f3bb96abb72ec06df0a9ac9b8026d6081560bf1f614531ec9fd93575_renew_setup"></a>

## Function `setup`

Allows admin to initalize the custom pricing config for the renewal module.
We're wrapping initial <code>Config</code> because we want to add custom pricing for renewals,
and we can only have 1 config of each type in the suins app.
We still set this up by using the default config functionality from suins package.
The <code>public_key</code> passed in the <code>Config</code> can be a random u8 array with length 33.


<pre><code><b>public</b> <b>fun</b> <a href="renew.md#0x2acc85a8f3bb96abb72ec06df0a9ac9b8026d6081560bf1f614531ec9fd93575_renew_setup">setup</a>(<a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>: &<b>mut</b> <a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_SuiNS">suins::SuiNS</a>, cap: &<a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_AdminCap">suins::AdminCap</a>, <a href="dependencies/suins/config.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_config">config</a>: <a href="dependencies/suins/config.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_config_Config">config::Config</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="renew.md#0x2acc85a8f3bb96abb72ec06df0a9ac9b8026d6081560bf1f614531ec9fd93575_renew_setup">setup</a>(<a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>: &<b>mut</b> SuiNS, cap: &AdminCap, <a href="dependencies/suins/config.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_config">config</a>: Config) {
    <a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_add_config">suins::add_config</a>&lt;<a href="renew.md#0x2acc85a8f3bb96abb72ec06df0a9ac9b8026d6081560bf1f614531ec9fd93575_renew_RenewalConfig">RenewalConfig</a>&gt;(cap, <a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>, <a href="renew.md#0x2acc85a8f3bb96abb72ec06df0a9ac9b8026d6081560bf1f614531ec9fd93575_renew_RenewalConfig">RenewalConfig</a> { <a href="dependencies/suins/config.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_config">config</a> });
}
</code></pre>



</details>

<a name="0x2acc85a8f3bb96abb72ec06df0a9ac9b8026d6081560bf1f614531ec9fd93575_renew_renew"></a>

## Function `renew`



<pre><code><b>public</b> <b>fun</b> <a href="renew.md#0x2acc85a8f3bb96abb72ec06df0a9ac9b8026d6081560bf1f614531ec9fd93575_renew">renew</a>(<a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>: &<b>mut</b> <a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_SuiNS">suins::SuiNS</a>, nft: &<b>mut</b> <a href="dependencies/suins/suins_registration.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_registration_SuinsRegistration">suins_registration::SuinsRegistration</a>, no_years: u8, payment: <a href="dependencies/sui-framework/coin.md#0x2_coin_Coin">coin::Coin</a>&lt;<a href="dependencies/sui-framework/sui.md#0x2_sui_SUI">sui::SUI</a>&gt;, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &<a href="dependencies/sui-framework/clock.md#0x2_clock_Clock">clock::Clock</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="renew.md#0x2acc85a8f3bb96abb72ec06df0a9ac9b8026d6081560bf1f614531ec9fd93575_renew">renew</a>(
    <a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>: &<b>mut</b> SuiNS,
    nft: &<b>mut</b> SuinsRegistration,
    no_years: u8,
    payment: Coin&lt;SUI&gt;,
    <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &Clock
) {
    // authorization occurs inside the call.
    <b>let</b> <a href="dependencies/suins/domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a> =  nft.<a href="dependencies/suins/domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a>();
    // check <b>if</b> the name is valid, for <b>public</b> registration
    // Also checks <b>if</b> the <a href="dependencies/suins/domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a> is not a subdomain, validates label lengths, TLD.
    <a href="dependencies/suins/config.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_config_assert_valid_user_registerable_domain">config::assert_valid_user_registerable_domain</a>(&<a href="dependencies/suins/domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a>);

    // check that the payment is correct for the specified name.
    <a href="renew.md#0x2acc85a8f3bb96abb72ec06df0a9ac9b8026d6081560bf1f614531ec9fd93575_renew_validate_payment">validate_payment</a>(<a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>, &payment, &<a href="dependencies/suins/domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a>, no_years);

    // Get <a href="dependencies/suins/registry.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_registry">registry</a> (also checks that app is authorized) + start validating.
    <b>let</b> <a href="dependencies/suins/registry.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_registry">registry</a> = <a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_app_registry_mut">suins::app_registry_mut</a>&lt;<a href="renew.md#0x2acc85a8f3bb96abb72ec06df0a9ac9b8026d6081560bf1f614531ec9fd93575_renew_Renew">Renew</a>, Registry&gt;(<a href="renew.md#0x2acc85a8f3bb96abb72ec06df0a9ac9b8026d6081560bf1f614531ec9fd93575_renew_Renew">Renew</a> {}, <a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>);

    // Calculate target expiration. Aborts <b>if</b> expiration or selected years are invalid.
    <b>let</b> target_expiration = <a href="renew.md#0x2acc85a8f3bb96abb72ec06df0a9ac9b8026d6081560bf1f614531ec9fd93575_renew_target_expiration">target_expiration</a>(<a href="dependencies/suins/registry.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_registry">registry</a>, nft, <a href="dependencies/suins/domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a>, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>, no_years);

    // set the expiration of the NFT + the <a href="dependencies/suins/registry.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_registry">registry</a>'s name record.
    <a href="dependencies/suins/registry.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_registry">registry</a>.set_expiration_timestamp_ms(nft, <a href="dependencies/suins/domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a>, target_expiration);

    sui::event::emit(<a href="renew.md#0x2acc85a8f3bb96abb72ec06df0a9ac9b8026d6081560bf1f614531ec9fd93575_renew_NameRenewed">NameRenewed</a> { <a href="dependencies/suins/domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a>, amount: <a href="dependencies/sui-framework/coin.md#0x2_coin_value">coin::value</a>(&payment) });
    <a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_app_add_balance">suins::app_add_balance</a>(<a href="renew.md#0x2acc85a8f3bb96abb72ec06df0a9ac9b8026d6081560bf1f614531ec9fd93575_renew_Renew">Renew</a> {}, <a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>, <a href="dependencies/sui-framework/coin.md#0x2_coin_into_balance">coin::into_balance</a>(payment));
}
</code></pre>



</details>

<a name="0x2acc85a8f3bb96abb72ec06df0a9ac9b8026d6081560bf1f614531ec9fd93575_renew_target_expiration"></a>

## Function `target_expiration`

Calculate the target expiration for a domain,
or abort if the domain or the expiration setup is invalid.


<pre><code><b>fun</b> <a href="renew.md#0x2acc85a8f3bb96abb72ec06df0a9ac9b8026d6081560bf1f614531ec9fd93575_renew_target_expiration">target_expiration</a>(<a href="dependencies/suins/registry.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_registry">registry</a>: &<a href="dependencies/suins/registry.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_registry_Registry">registry::Registry</a>, nft: &<a href="dependencies/suins/suins_registration.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_registration_SuinsRegistration">suins_registration::SuinsRegistration</a>, <a href="dependencies/suins/domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a>: <a href="dependencies/suins/domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_Domain">domain::Domain</a>, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &<a href="dependencies/sui-framework/clock.md#0x2_clock_Clock">clock::Clock</a>, no_years: u8): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="renew.md#0x2acc85a8f3bb96abb72ec06df0a9ac9b8026d6081560bf1f614531ec9fd93575_renew_target_expiration">target_expiration</a>(
    <a href="dependencies/suins/registry.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_registry">registry</a>: &Registry,
    nft: &SuinsRegistration,
    <a href="dependencies/suins/domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a>: Domain,
    <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &Clock,
    no_years: u8,
): u64 {
    <b>let</b> name_record_option = <a href="dependencies/suins/registry.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_registry">registry</a>.lookup(<a href="dependencies/suins/domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a>);
    // validate that the <a href="dependencies/suins/name_record.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record">name_record</a> still exists in the <a href="dependencies/suins/registry.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_registry">registry</a>.
    <b>assert</b>!(<a href="dependencies/move-stdlib/option.md#0x1_option_is_some">option::is_some</a>(&name_record_option), <a href="renew.md#0x2acc85a8f3bb96abb72ec06df0a9ac9b8026d6081560bf1f614531ec9fd93575_renew_ERecordNotFound">ERecordNotFound</a>);

    <b>let</b> <a href="dependencies/suins/name_record.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record">name_record</a> = <a href="dependencies/move-stdlib/option.md#0x1_option_destroy_some">option::destroy_some</a>(name_record_option);

    // Validate that the name <b>has</b> not expired. If it <b>has</b>, we can only re-purchase (and that might involve different pricing).
    <b>assert</b>!(!<a href="dependencies/suins/name_record.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record">name_record</a>.has_expired_past_grace_period(<a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>), <a href="renew.md#0x2acc85a8f3bb96abb72ec06df0a9ac9b8026d6081560bf1f614531ec9fd93575_renew_ERecordExpired">ERecordExpired</a>);

    // validate that the supplied NFT ID matches the NFT ID of the <a href="dependencies/suins/registry.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_registry">registry</a>.
    <b>assert</b>!(<a href="dependencies/suins/name_record.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record">name_record</a>.nft_id() == <a href="dependencies/sui-framework/object.md#0x2_object_id">object::id</a>(nft), <a href="renew.md#0x2acc85a8f3bb96abb72ec06df0a9ac9b8026d6081560bf1f614531ec9fd93575_renew_ERecordNftIDMismatch">ERecordNftIDMismatch</a>);

    // Validate that the no_years supplied makes sense. (1-5).
    <b>assert</b>!(0 &lt; no_years && no_years &lt;= 5, <a href="renew.md#0x2acc85a8f3bb96abb72ec06df0a9ac9b8026d6081560bf1f614531ec9fd93575_renew_EInvalidYearsArgument">EInvalidYearsArgument</a>);

    // calcualate target expiration!
    <b>let</b> target_expiration = <a href="dependencies/suins/name_record.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record">name_record</a>.expiration_timestamp_ms() + (no_years <b>as</b> u64) * <a href="dependencies/suins/constants.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_constants_year_ms">constants::year_ms</a>();

    // validate that the target expiration is not more than 6 years in the future.
    <b>assert</b>!(<a href="renew.md#0x2acc85a8f3bb96abb72ec06df0a9ac9b8026d6081560bf1f614531ec9fd93575_renew_target_expiration">target_expiration</a> &lt; <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>.timestamp_ms() + (<a href="dependencies/suins/constants.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_constants_year_ms">constants::year_ms</a>() * 6), <a href="renew.md#0x2acc85a8f3bb96abb72ec06df0a9ac9b8026d6081560bf1f614531ec9fd93575_renew_EMoreThanSixYears">EMoreThanSixYears</a>);

    target_expiration
}
</code></pre>



</details>

<a name="0x2acc85a8f3bb96abb72ec06df0a9ac9b8026d6081560bf1f614531ec9fd93575_renew_validate_payment"></a>

## Function `validate_payment`

Validates that the payment Coin is correct for the domain + number of years


<pre><code><b>fun</b> <a href="renew.md#0x2acc85a8f3bb96abb72ec06df0a9ac9b8026d6081560bf1f614531ec9fd93575_renew_validate_payment">validate_payment</a>(<a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>: &<a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_SuiNS">suins::SuiNS</a>, payment: &<a href="dependencies/sui-framework/coin.md#0x2_coin_Coin">coin::Coin</a>&lt;<a href="dependencies/sui-framework/sui.md#0x2_sui_SUI">sui::SUI</a>&gt;, <a href="dependencies/suins/domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a>: &<a href="dependencies/suins/domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_Domain">domain::Domain</a>, no_years: u8)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="renew.md#0x2acc85a8f3bb96abb72ec06df0a9ac9b8026d6081560bf1f614531ec9fd93575_renew_validate_payment">validate_payment</a>(<a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>: &SuiNS, payment: &Coin&lt;SUI&gt;, <a href="dependencies/suins/domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a>: &Domain, no_years: u8){
    <b>let</b> <a href="dependencies/suins/config.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_config">config</a> = <a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>.get_config&lt;<a href="renew.md#0x2acc85a8f3bb96abb72ec06df0a9ac9b8026d6081560bf1f614531ec9fd93575_renew_RenewalConfig">RenewalConfig</a>&gt;();
    <b>let</b> label = <a href="dependencies/suins/domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a>.sld();
    <b>let</b> price = <a href="dependencies/suins/config.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_config">config</a>.<a href="dependencies/suins/config.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_config">config</a>.calculate_price((label.length() <b>as</b> u8), no_years);
    <b>assert</b>!(payment.value() == price, <a href="renew.md#0x2acc85a8f3bb96abb72ec06df0a9ac9b8026d6081560bf1f614531ec9fd93575_renew_EIncorrectAmount">EIncorrectAmount</a>);
}
</code></pre>



</details>
