
<a name="0x42cff5d07eca51e9dcef278c9c3a8b98a0f70f06977868614f6eab1a22d9bd89_direct_setup"></a>

# Module `0x42cff5d07eca51e9dcef278c9c3a8b98a0f70f06977868614f6eab1a22d9bd89::direct_setup`

A simple package to allows us set a target address &  default name in a single PTB in frontend.
Unblocks better UX in the registration flow.


-  [Struct `DirectSetup`](#0x42cff5d07eca51e9dcef278c9c3a8b98a0f70f06977868614f6eab1a22d9bd89_direct_setup_DirectSetup)
-  [Constants](#@Constants_0)
-  [Function `set_target_address`](#0x42cff5d07eca51e9dcef278c9c3a8b98a0f70f06977868614f6eab1a22d9bd89_direct_setup_set_target_address)
-  [Function `set_reverse_lookup`](#0x42cff5d07eca51e9dcef278c9c3a8b98a0f70f06977868614f6eab1a22d9bd89_direct_setup_set_reverse_lookup)
-  [Function `unset_reverse_lookup`](#0x42cff5d07eca51e9dcef278c9c3a8b98a0f70f06977868614f6eab1a22d9bd89_direct_setup_unset_reverse_lookup)
-  [Function `set_user_data`](#0x42cff5d07eca51e9dcef278c9c3a8b98a0f70f06977868614f6eab1a22d9bd89_direct_setup_set_user_data)
-  [Function `unset_user_data`](#0x42cff5d07eca51e9dcef278c9c3a8b98a0f70f06977868614f6eab1a22d9bd89_direct_setup_unset_user_data)
-  [Function `burn_expired`](#0x42cff5d07eca51e9dcef278c9c3a8b98a0f70f06977868614f6eab1a22d9bd89_direct_setup_burn_expired)
-  [Function `burn_expired_subname`](#0x42cff5d07eca51e9dcef278c9c3a8b98a0f70f06977868614f6eab1a22d9bd89_direct_setup_burn_expired_subname)
-  [Function `registry_mut`](#0x42cff5d07eca51e9dcef278c9c3a8b98a0f70f06977868614f6eab1a22d9bd89_direct_setup_registry_mut)


<pre><code><b>use</b> <a href="dependencies/move-stdlib/option.md#0x1_option">0x1::option</a>;
<b>use</b> <a href="dependencies/move-stdlib/string.md#0x1_string">0x1::string</a>;
<b>use</b> <a href="dependencies/sui-framework/clock.md#0x2_clock">0x2::clock</a>;
<b>use</b> <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context">0x2::tx_context</a>;
<b>use</b> <a href="dependencies/sui-framework/vec_map.md#0x2_vec_map">0x2::vec_map</a>;
<b>use</b> <a href="dependencies/suins/domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b::domain</a>;
<b>use</b> <a href="dependencies/suins/registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry">0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b::registry</a>;
<b>use</b> <a href="dependencies/suins/subdomain_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_subdomain_registration">0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b::subdomain_registration</a>;
<b>use</b> <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b::suins</a>;
<b>use</b> <a href="dependencies/suins/suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration">0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b::suins_registration</a>;
</code></pre>



<a name="0x42cff5d07eca51e9dcef278c9c3a8b98a0f70f06977868614f6eab1a22d9bd89_direct_setup_DirectSetup"></a>

## Struct `DirectSetup`

Authorization token for the controller.


<pre><code><b>struct</b> <a href="direct_setup.md#0x42cff5d07eca51e9dcef278c9c3a8b98a0f70f06977868614f6eab1a22d9bd89_direct_setup_DirectSetup">DirectSetup</a> <b>has</b> drop
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


<a name="0x42cff5d07eca51e9dcef278c9c3a8b98a0f70f06977868614f6eab1a22d9bd89_direct_setup_AVATAR"></a>



<pre><code><b>const</b> <a href="direct_setup.md#0x42cff5d07eca51e9dcef278c9c3a8b98a0f70f06977868614f6eab1a22d9bd89_direct_setup_AVATAR">AVATAR</a>: <a href="dependencies/move-stdlib/vector.md#0x1_vector">vector</a>&lt;u8&gt; = [97, 118, 97, 116, 97, 114];
</code></pre>



<a name="0x42cff5d07eca51e9dcef278c9c3a8b98a0f70f06977868614f6eab1a22d9bd89_direct_setup_CONTENT_HASH"></a>



<pre><code><b>const</b> <a href="direct_setup.md#0x42cff5d07eca51e9dcef278c9c3a8b98a0f70f06977868614f6eab1a22d9bd89_direct_setup_CONTENT_HASH">CONTENT_HASH</a>: <a href="dependencies/move-stdlib/vector.md#0x1_vector">vector</a>&lt;u8&gt; = [99, 111, 110, 116, 101, 110, 116, 95, 104, 97, 115, 104];
</code></pre>



<a name="0x42cff5d07eca51e9dcef278c9c3a8b98a0f70f06977868614f6eab1a22d9bd89_direct_setup_EUnsupportedKey"></a>

Tries to add not supported user data in the vecmap of the name record.


<pre><code><b>const</b> <a href="direct_setup.md#0x42cff5d07eca51e9dcef278c9c3a8b98a0f70f06977868614f6eab1a22d9bd89_direct_setup_EUnsupportedKey">EUnsupportedKey</a>: u64 = 1;
</code></pre>



<a name="0x42cff5d07eca51e9dcef278c9c3a8b98a0f70f06977868614f6eab1a22d9bd89_direct_setup_set_target_address"></a>

## Function `set_target_address`

Set the target address of a domain.


<pre><code><b>public</b> <b>fun</b> <a href="direct_setup.md#0x42cff5d07eca51e9dcef278c9c3a8b98a0f70f06977868614f6eab1a22d9bd89_direct_setup_set_target_address">set_target_address</a>(<a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>: &<b>mut</b> <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_SuiNS">suins::SuiNS</a>, nft: &<a href="dependencies/suins/suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_SuinsRegistration">suins_registration::SuinsRegistration</a>, new_target: <a href="dependencies/move-stdlib/option.md#0x1_option_Option">option::Option</a>&lt;<b>address</b>&gt;, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &<a href="dependencies/sui-framework/clock.md#0x2_clock_Clock">clock::Clock</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="direct_setup.md#0x42cff5d07eca51e9dcef278c9c3a8b98a0f70f06977868614f6eab1a22d9bd89_direct_setup_set_target_address">set_target_address</a>(
    <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>: &<b>mut</b> SuiNS,
    nft: &SuinsRegistration,
    new_target: Option&lt;<b>address</b>&gt;,
    <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &Clock,
) {
    <b>let</b> <a href="dependencies/suins/registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry">registry</a> = <a href="direct_setup.md#0x42cff5d07eca51e9dcef278c9c3a8b98a0f70f06977868614f6eab1a22d9bd89_direct_setup_registry_mut">registry_mut</a>(<a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>);
    <a href="dependencies/suins/registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry">registry</a>.assert_nft_is_authorized(nft, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>);

    <b>let</b> <a href="dependencies/suins/domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a> = nft.<a href="dependencies/suins/domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>();
    <a href="dependencies/suins/registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry">registry</a>.<a href="direct_setup.md#0x42cff5d07eca51e9dcef278c9c3a8b98a0f70f06977868614f6eab1a22d9bd89_direct_setup_set_target_address">set_target_address</a>(<a href="dependencies/suins/domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>, new_target);
}
</code></pre>



</details>

<a name="0x42cff5d07eca51e9dcef278c9c3a8b98a0f70f06977868614f6eab1a22d9bd89_direct_setup_set_reverse_lookup"></a>

## Function `set_reverse_lookup`

Set the reverse lookup address for the domain


<pre><code><b>public</b> <b>fun</b> <a href="direct_setup.md#0x42cff5d07eca51e9dcef278c9c3a8b98a0f70f06977868614f6eab1a22d9bd89_direct_setup_set_reverse_lookup">set_reverse_lookup</a>(<a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>: &<b>mut</b> <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_SuiNS">suins::SuiNS</a>, domain_name: <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>, ctx: &<a href="dependencies/sui-framework/tx_context.md#0x2_tx_context_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="direct_setup.md#0x42cff5d07eca51e9dcef278c9c3a8b98a0f70f06977868614f6eab1a22d9bd89_direct_setup_set_reverse_lookup">set_reverse_lookup</a>(<a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>: &<b>mut</b> SuiNS, domain_name: String, ctx: &TxContext) {
    <a href="direct_setup.md#0x42cff5d07eca51e9dcef278c9c3a8b98a0f70f06977868614f6eab1a22d9bd89_direct_setup_registry_mut">registry_mut</a>(<a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>).<a href="direct_setup.md#0x42cff5d07eca51e9dcef278c9c3a8b98a0f70f06977868614f6eab1a22d9bd89_direct_setup_set_reverse_lookup">set_reverse_lookup</a>(ctx.sender(), <a href="dependencies/suins/domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain_new">domain::new</a>(domain_name));
}
</code></pre>



</details>

<a name="0x42cff5d07eca51e9dcef278c9c3a8b98a0f70f06977868614f6eab1a22d9bd89_direct_setup_unset_reverse_lookup"></a>

## Function `unset_reverse_lookup`

User-facing function - unset the reverse lookup address for the domain.


<pre><code><b>public</b> <b>fun</b> <a href="direct_setup.md#0x42cff5d07eca51e9dcef278c9c3a8b98a0f70f06977868614f6eab1a22d9bd89_direct_setup_unset_reverse_lookup">unset_reverse_lookup</a>(<a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>: &<b>mut</b> <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_SuiNS">suins::SuiNS</a>, ctx: &<a href="dependencies/sui-framework/tx_context.md#0x2_tx_context_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="direct_setup.md#0x42cff5d07eca51e9dcef278c9c3a8b98a0f70f06977868614f6eab1a22d9bd89_direct_setup_unset_reverse_lookup">unset_reverse_lookup</a>(<a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>: &<b>mut</b> SuiNS, ctx: &TxContext) {
    <a href="direct_setup.md#0x42cff5d07eca51e9dcef278c9c3a8b98a0f70f06977868614f6eab1a22d9bd89_direct_setup_registry_mut">registry_mut</a>(<a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>).<a href="direct_setup.md#0x42cff5d07eca51e9dcef278c9c3a8b98a0f70f06977868614f6eab1a22d9bd89_direct_setup_unset_reverse_lookup">unset_reverse_lookup</a>(ctx.sender());
}
</code></pre>



</details>

<a name="0x42cff5d07eca51e9dcef278c9c3a8b98a0f70f06977868614f6eab1a22d9bd89_direct_setup_set_user_data"></a>

## Function `set_user_data`

User-facing function - add a new key-value pair to the name record's data.


<pre><code><b>public</b> <b>fun</b> <a href="direct_setup.md#0x42cff5d07eca51e9dcef278c9c3a8b98a0f70f06977868614f6eab1a22d9bd89_direct_setup_set_user_data">set_user_data</a>(<a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>: &<b>mut</b> <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_SuiNS">suins::SuiNS</a>, nft: &<a href="dependencies/suins/suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_SuinsRegistration">suins_registration::SuinsRegistration</a>, key: <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>, value: <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &<a href="dependencies/sui-framework/clock.md#0x2_clock_Clock">clock::Clock</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="direct_setup.md#0x42cff5d07eca51e9dcef278c9c3a8b98a0f70f06977868614f6eab1a22d9bd89_direct_setup_set_user_data">set_user_data</a>(
    <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>: &<b>mut</b> SuiNS, nft: &SuinsRegistration, key: String, value: String, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &Clock
) {
    <b>let</b> <a href="dependencies/suins/registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry">registry</a> = <a href="direct_setup.md#0x42cff5d07eca51e9dcef278c9c3a8b98a0f70f06977868614f6eab1a22d9bd89_direct_setup_registry_mut">registry_mut</a>(<a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>);
    <b>let</b> <b>mut</b> data = *<a href="dependencies/suins/registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry">registry</a>.get_data(nft.<a href="dependencies/suins/domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>());
    <b>let</b> <a href="dependencies/suins/domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a> = nft.<a href="dependencies/suins/domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>();

    <a href="dependencies/suins/registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry">registry</a>.assert_nft_is_authorized(nft, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>);
    <b>let</b> key_bytes = *key.bytes();
    <b>assert</b>!(key_bytes == <a href="direct_setup.md#0x42cff5d07eca51e9dcef278c9c3a8b98a0f70f06977868614f6eab1a22d9bd89_direct_setup_AVATAR">AVATAR</a> || key_bytes == <a href="direct_setup.md#0x42cff5d07eca51e9dcef278c9c3a8b98a0f70f06977868614f6eab1a22d9bd89_direct_setup_CONTENT_HASH">CONTENT_HASH</a>, <a href="direct_setup.md#0x42cff5d07eca51e9dcef278c9c3a8b98a0f70f06977868614f6eab1a22d9bd89_direct_setup_EUnsupportedKey">EUnsupportedKey</a>);

    <b>if</b> (data.contains(&key)) {
        data.remove(&key);
    };

    data.insert(key, value);
    <a href="dependencies/suins/registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry">registry</a>.set_data(<a href="dependencies/suins/domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>, data);
}
</code></pre>



</details>

<a name="0x42cff5d07eca51e9dcef278c9c3a8b98a0f70f06977868614f6eab1a22d9bd89_direct_setup_unset_user_data"></a>

## Function `unset_user_data`

User-facing function - remove a key from the name record's data.


<pre><code><b>public</b> <b>fun</b> <a href="direct_setup.md#0x42cff5d07eca51e9dcef278c9c3a8b98a0f70f06977868614f6eab1a22d9bd89_direct_setup_unset_user_data">unset_user_data</a>(<a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>: &<b>mut</b> <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_SuiNS">suins::SuiNS</a>, nft: &<a href="dependencies/suins/suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_SuinsRegistration">suins_registration::SuinsRegistration</a>, key: <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &<a href="dependencies/sui-framework/clock.md#0x2_clock_Clock">clock::Clock</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="direct_setup.md#0x42cff5d07eca51e9dcef278c9c3a8b98a0f70f06977868614f6eab1a22d9bd89_direct_setup_unset_user_data">unset_user_data</a>(
    <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>: &<b>mut</b> SuiNS, nft: &SuinsRegistration, key: String, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &Clock
) {
    <b>let</b> <a href="dependencies/suins/registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry">registry</a> = <a href="direct_setup.md#0x42cff5d07eca51e9dcef278c9c3a8b98a0f70f06977868614f6eab1a22d9bd89_direct_setup_registry_mut">registry_mut</a>(<a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>);
    <b>let</b> <b>mut</b> data = *<a href="dependencies/suins/registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry">registry</a>.get_data(nft.<a href="dependencies/suins/domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>());
    <b>let</b> <a href="dependencies/suins/domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a> = nft.<a href="dependencies/suins/domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>();

    <a href="dependencies/suins/registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry">registry</a>.assert_nft_is_authorized(nft, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>);

    <b>if</b> (data.contains(&key)) {
        data.remove(&key);
    };

    <a href="dependencies/suins/registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry">registry</a>.set_data(<a href="dependencies/suins/domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>, data);
}
</code></pre>



</details>

<a name="0x42cff5d07eca51e9dcef278c9c3a8b98a0f70f06977868614f6eab1a22d9bd89_direct_setup_burn_expired"></a>

## Function `burn_expired`



<pre><code><b>public</b> <b>fun</b> <a href="direct_setup.md#0x42cff5d07eca51e9dcef278c9c3a8b98a0f70f06977868614f6eab1a22d9bd89_direct_setup_burn_expired">burn_expired</a>(<a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>: &<b>mut</b> <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_SuiNS">suins::SuiNS</a>, nft: <a href="dependencies/suins/suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_SuinsRegistration">suins_registration::SuinsRegistration</a>, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &<a href="dependencies/sui-framework/clock.md#0x2_clock_Clock">clock::Clock</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="direct_setup.md#0x42cff5d07eca51e9dcef278c9c3a8b98a0f70f06977868614f6eab1a22d9bd89_direct_setup_burn_expired">burn_expired</a>(<a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>: &<b>mut</b> SuiNS, nft: SuinsRegistration, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &Clock) {
    <a href="direct_setup.md#0x42cff5d07eca51e9dcef278c9c3a8b98a0f70f06977868614f6eab1a22d9bd89_direct_setup_registry_mut">registry_mut</a>(<a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>).burn_registration_object(nft, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>);
}
</code></pre>



</details>

<a name="0x42cff5d07eca51e9dcef278c9c3a8b98a0f70f06977868614f6eab1a22d9bd89_direct_setup_burn_expired_subname"></a>

## Function `burn_expired_subname`



<pre><code><b>public</b> <b>fun</b> <a href="direct_setup.md#0x42cff5d07eca51e9dcef278c9c3a8b98a0f70f06977868614f6eab1a22d9bd89_direct_setup_burn_expired_subname">burn_expired_subname</a>(<a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>: &<b>mut</b> <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_SuiNS">suins::SuiNS</a>, nft: <a href="dependencies/suins/subdomain_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_subdomain_registration_SubDomainRegistration">subdomain_registration::SubDomainRegistration</a>, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &<a href="dependencies/sui-framework/clock.md#0x2_clock_Clock">clock::Clock</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="direct_setup.md#0x42cff5d07eca51e9dcef278c9c3a8b98a0f70f06977868614f6eab1a22d9bd89_direct_setup_burn_expired_subname">burn_expired_subname</a>(<a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>: &<b>mut</b> SuiNS, nft: SubDomainRegistration, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &Clock) {
    <a href="direct_setup.md#0x42cff5d07eca51e9dcef278c9c3a8b98a0f70f06977868614f6eab1a22d9bd89_direct_setup_registry_mut">registry_mut</a>(<a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>).burn_subdomain_object(nft, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>);
}
</code></pre>



</details>

<a name="0x42cff5d07eca51e9dcef278c9c3a8b98a0f70f06977868614f6eab1a22d9bd89_direct_setup_registry_mut"></a>

## Function `registry_mut`



<pre><code><b>fun</b> <a href="direct_setup.md#0x42cff5d07eca51e9dcef278c9c3a8b98a0f70f06977868614f6eab1a22d9bd89_direct_setup_registry_mut">registry_mut</a>(<a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>: &<b>mut</b> <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_SuiNS">suins::SuiNS</a>): &<b>mut</b> <a href="dependencies/suins/registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_Registry">registry::Registry</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="direct_setup.md#0x42cff5d07eca51e9dcef278c9c3a8b98a0f70f06977868614f6eab1a22d9bd89_direct_setup_registry_mut">registry_mut</a>(<a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>: &<b>mut</b> SuiNS): &<b>mut</b> Registry {
    <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_app_registry_mut">suins::app_registry_mut</a>&lt;<a href="direct_setup.md#0x42cff5d07eca51e9dcef278c9c3a8b98a0f70f06977868614f6eab1a22d9bd89_direct_setup_DirectSetup">DirectSetup</a>, Registry&gt;(<a href="direct_setup.md#0x42cff5d07eca51e9dcef278c9c3a8b98a0f70f06977868614f6eab1a22d9bd89_direct_setup_DirectSetup">DirectSetup</a> {}, <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>)
}
</code></pre>



</details>
