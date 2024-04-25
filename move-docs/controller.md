
<a name="0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_controller"></a>

# Module `0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0::controller`



-  [Struct `Controller`](#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_controller_Controller)
-  [Constants](#@Constants_0)
-  [Function `set_target_address`](#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_controller_set_target_address)
-  [Function `set_reverse_lookup`](#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_controller_set_reverse_lookup)
-  [Function `unset_reverse_lookup`](#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_controller_unset_reverse_lookup)
-  [Function `set_user_data`](#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_controller_set_user_data)
-  [Function `unset_user_data`](#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_controller_unset_user_data)


<pre><code><b>use</b> <a href="dependencies/move-stdlib/option.md#0x1_option">0x1::option</a>;
<b>use</b> <a href="dependencies/move-stdlib/string.md#0x1_string">0x1::string</a>;
<b>use</b> <a href="dependencies/sui-framework/clock.md#0x2_clock">0x2::clock</a>;
<b>use</b> <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context">0x2::tx_context</a>;
<b>use</b> <a href="dependencies/sui-framework/vec_map.md#0x2_vec_map">0x2::vec_map</a>;
<b>use</b> <a href="domain.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_domain">0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0::domain</a>;
<b>use</b> <a href="registry.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_registry">0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0::registry</a>;
<b>use</b> <a href="suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0::suins</a>;
<b>use</b> <a href="suins_registration.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins_registration">0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0::suins_registration</a>;
</code></pre>



<a name="0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_controller_Controller"></a>

## Struct `Controller`

Authorization token for the controller.


<pre><code><b>struct</b> <a href="controller.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_controller_Controller">Controller</a> <b>has</b> drop
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


<a name="0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_controller_AVATAR"></a>



<pre><code><b>const</b> <a href="controller.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_controller_AVATAR">AVATAR</a>: <a href="dependencies/move-stdlib/vector.md#0x1_vector">vector</a>&lt;u8&gt; = [97, 118, 97, 116, 97, 114];
</code></pre>



<a name="0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_controller_CONTENT_HASH"></a>



<pre><code><b>const</b> <a href="controller.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_controller_CONTENT_HASH">CONTENT_HASH</a>: <a href="dependencies/move-stdlib/vector.md#0x1_vector">vector</a>&lt;u8&gt; = [99, 111, 110, 116, 101, 110, 116, 95, 104, 97, 115, 104];
</code></pre>



<a name="0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_controller_EUnsupportedKey"></a>



<pre><code><b>const</b> <a href="controller.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_controller_EUnsupportedKey">EUnsupportedKey</a>: u64 = 0;
</code></pre>



<a name="0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_controller_set_target_address"></a>

## Function `set_target_address`

User-facing function (upgradable) - set the target address of a domain.


<pre><code>entry <b>fun</b> <a href="controller.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_controller_set_target_address">set_target_address</a>(<a href="suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>: &<b>mut</b> <a href="suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins_SuiNS">suins::SuiNS</a>, nft: &<a href="suins_registration.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins_registration_SuinsRegistration">suins_registration::SuinsRegistration</a>, new_target: <a href="dependencies/move-stdlib/option.md#0x1_option_Option">option::Option</a>&lt;<b>address</b>&gt;, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &<a href="dependencies/sui-framework/clock.md#0x2_clock_Clock">clock::Clock</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code>entry <b>fun</b> <a href="controller.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_controller_set_target_address">set_target_address</a>(
    <a href="suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>: &<b>mut</b> SuiNS,
    nft: &SuinsRegistration,
    new_target: Option&lt;<b>address</b>&gt;,
    <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &Clock,
) {
    <b>let</b> <a href="registry.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_registry">registry</a> = <a href="suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins_app_registry_mut">suins::app_registry_mut</a>&lt;<a href="controller.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_controller_Controller">Controller</a>, Registry&gt;(<a href="controller.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_controller_Controller">Controller</a> {}, <a href="suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>);
    <a href="registry.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_registry">registry</a>.assert_nft_is_authorized(nft, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>);

    <b>let</b> <a href="domain.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_domain">domain</a> = nft.<a href="domain.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_domain">domain</a>();
    <a href="registry.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_registry">registry</a>.<a href="controller.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_controller_set_target_address">set_target_address</a>(<a href="domain.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_domain">domain</a>, new_target);
}
</code></pre>



</details>

<a name="0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_controller_set_reverse_lookup"></a>

## Function `set_reverse_lookup`

User-facing function (upgradable) - set the reverse lookup address for the domain.


<pre><code>entry <b>fun</b> <a href="controller.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_controller_set_reverse_lookup">set_reverse_lookup</a>(<a href="suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>: &<b>mut</b> <a href="suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins_SuiNS">suins::SuiNS</a>, domain_name: <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>, ctx: &<a href="dependencies/sui-framework/tx_context.md#0x2_tx_context_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code>entry <b>fun</b> <a href="controller.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_controller_set_reverse_lookup">set_reverse_lookup</a>(<a href="suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>: &<b>mut</b> SuiNS, domain_name: String, ctx: &TxContext) {
    <b>let</b> <a href="domain.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_domain">domain</a> = <a href="domain.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_domain_new">domain::new</a>(domain_name);
    <b>let</b> <a href="registry.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_registry">registry</a> = <a href="suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins_app_registry_mut">suins::app_registry_mut</a>&lt;<a href="controller.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_controller_Controller">Controller</a>, Registry&gt;(<a href="controller.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_controller_Controller">Controller</a> {}, <a href="suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>);
    <a href="registry.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_registry">registry</a>.<a href="controller.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_controller_set_reverse_lookup">set_reverse_lookup</a>(sender(ctx), <a href="domain.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_domain">domain</a>);
}
</code></pre>



</details>

<a name="0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_controller_unset_reverse_lookup"></a>

## Function `unset_reverse_lookup`

User-facing function (upgradable) - unset the reverse lookup address for the domain.


<pre><code>entry <b>fun</b> <a href="controller.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_controller_unset_reverse_lookup">unset_reverse_lookup</a>(<a href="suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>: &<b>mut</b> <a href="suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins_SuiNS">suins::SuiNS</a>, ctx: &<a href="dependencies/sui-framework/tx_context.md#0x2_tx_context_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code>entry <b>fun</b> <a href="controller.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_controller_unset_reverse_lookup">unset_reverse_lookup</a>(<a href="suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>: &<b>mut</b> SuiNS, ctx: &TxContext) {
    <b>let</b> <a href="registry.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_registry">registry</a> = <a href="suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins_app_registry_mut">suins::app_registry_mut</a>&lt;<a href="controller.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_controller_Controller">Controller</a>, Registry&gt;(<a href="controller.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_controller_Controller">Controller</a> {}, <a href="suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>);
    <a href="registry.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_registry">registry</a>.<a href="controller.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_controller_unset_reverse_lookup">unset_reverse_lookup</a>(sender(ctx));
}
</code></pre>



</details>

<a name="0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_controller_set_user_data"></a>

## Function `set_user_data`

User-facing function (upgradable) - add a new key-value pair to the name record's data.


<pre><code>entry <b>fun</b> <a href="controller.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_controller_set_user_data">set_user_data</a>(<a href="suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>: &<b>mut</b> <a href="suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins_SuiNS">suins::SuiNS</a>, nft: &<a href="suins_registration.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins_registration_SuinsRegistration">suins_registration::SuinsRegistration</a>, key: <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>, value: <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &<a href="dependencies/sui-framework/clock.md#0x2_clock_Clock">clock::Clock</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code>entry <b>fun</b> <a href="controller.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_controller_set_user_data">set_user_data</a>(
    <a href="suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>: &<b>mut</b> SuiNS, nft: &SuinsRegistration, key: String, value: String, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &Clock
) {

    <b>let</b> <a href="registry.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_registry">registry</a> = <a href="suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins_app_registry_mut">suins::app_registry_mut</a>&lt;<a href="controller.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_controller_Controller">Controller</a>, Registry&gt;(<a href="controller.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_controller_Controller">Controller</a> {}, <a href="suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>);
    <b>let</b> <b>mut</b> data = *<a href="registry.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_registry">registry</a>.get_data(nft.<a href="domain.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_domain">domain</a>());
    <b>let</b> <a href="domain.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_domain">domain</a> = nft.<a href="domain.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_domain">domain</a>();

    <a href="registry.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_registry">registry</a>.assert_nft_is_authorized(nft, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>);
    <b>let</b> key_bytes = *key.bytes();
    <b>assert</b>!(key_bytes == <a href="controller.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_controller_AVATAR">AVATAR</a> || key_bytes == <a href="controller.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_controller_CONTENT_HASH">CONTENT_HASH</a>, <a href="controller.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_controller_EUnsupportedKey">EUnsupportedKey</a>);

    <b>if</b> (data.contains(&key)) {
        data.remove(&key);
    };

    data.insert(key, value);
    <a href="registry.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_registry">registry</a>.set_data(<a href="domain.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_domain">domain</a>, data);
}
</code></pre>



</details>

<a name="0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_controller_unset_user_data"></a>

## Function `unset_user_data`

User-facing function (upgradable) - remove a key from the name record's data.


<pre><code>entry <b>fun</b> <a href="controller.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_controller_unset_user_data">unset_user_data</a>(<a href="suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>: &<b>mut</b> <a href="suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins_SuiNS">suins::SuiNS</a>, nft: &<a href="suins_registration.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins_registration_SuinsRegistration">suins_registration::SuinsRegistration</a>, key: <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &<a href="dependencies/sui-framework/clock.md#0x2_clock_Clock">clock::Clock</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code>entry <b>fun</b> <a href="controller.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_controller_unset_user_data">unset_user_data</a>(
    <a href="suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>: &<b>mut</b> SuiNS, nft: &SuinsRegistration, key: String, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &Clock
) {
    <b>let</b> <a href="registry.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_registry">registry</a> = <a href="suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins_app_registry_mut">suins::app_registry_mut</a>&lt;<a href="controller.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_controller_Controller">Controller</a>, Registry&gt;(<a href="controller.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_controller_Controller">Controller</a> {}, <a href="suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>);
    <b>let</b> <b>mut</b> data = *<a href="registry.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_registry">registry</a>.get_data(nft.<a href="domain.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_domain">domain</a>());
    <b>let</b> <a href="domain.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_domain">domain</a> = nft.<a href="domain.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_domain">domain</a>();

    <a href="registry.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_registry">registry</a>.assert_nft_is_authorized(nft, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>);

    <b>if</b> (data.contains(&key)) {
        data.remove(&key);
    };

    <a href="registry.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_registry">registry</a>.set_data(<a href="domain.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_domain">domain</a>, data);
}
</code></pre>



</details>
