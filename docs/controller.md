
<a name="0x0_controller"></a>

# Module `0x0::controller`



-  [Struct `Controller`](#0x0_controller_Controller)
-  [Constants](#@Constants_0)
-  [Function `set_target_address`](#0x0_controller_set_target_address)
-  [Function `set_reverse_lookup`](#0x0_controller_set_reverse_lookup)
-  [Function `unset_reverse_lookup`](#0x0_controller_unset_reverse_lookup)
-  [Function `set_user_data`](#0x0_controller_set_user_data)
-  [Function `unset_user_data`](#0x0_controller_unset_user_data)


<pre><code><b>use</b> <a href="domain.md#0x0_domain">0x0::domain</a>;
<b>use</b> <a href="registration_nft.md#0x0_registration_nft">0x0::registration_nft</a>;
<b>use</b> <a href="registry.md#0x0_registry">0x0::registry</a>;
<b>use</b> <a href="suins.md#0x0_suins">0x0::suins</a>;
<b>use</b> <a href="">0x1::option</a>;
<b>use</b> <a href="">0x1::string</a>;
<b>use</b> <a href="">0x2::clock</a>;
<b>use</b> <a href="">0x2::tx_context</a>;
<b>use</b> <a href="">0x2::vec_map</a>;
</code></pre>



<a name="0x0_controller_Controller"></a>

## Struct `Controller`

Authorization token for the controller.


<pre><code><b>struct</b> <a href="controller.md#0x0_controller_Controller">Controller</a> <b>has</b> drop
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


<a name="0x0_controller_AVATAR"></a>



<pre><code><b>const</b> <a href="controller.md#0x0_controller_AVATAR">AVATAR</a>: <a href="">vector</a>&lt;u8&gt; = [97, 118, 97, 116, 97, 114];
</code></pre>



<a name="0x0_controller_CONTENT_HASH"></a>



<pre><code><b>const</b> <a href="controller.md#0x0_controller_CONTENT_HASH">CONTENT_HASH</a>: <a href="">vector</a>&lt;u8&gt; = [99, 111, 110, 116, 101, 110, 116, 95, 104, 97, 115, 104];
</code></pre>



<a name="0x0_controller_EUnsupportedKey"></a>



<pre><code><b>const</b> <a href="controller.md#0x0_controller_EUnsupportedKey">EUnsupportedKey</a>: u64 = 0;
</code></pre>



<a name="0x0_controller_set_target_address"></a>

## Function `set_target_address`

User-facing function (upgradable) - set the target address of a domain.


<pre><code>entry <b>fun</b> <a href="controller.md#0x0_controller_set_target_address">set_target_address</a>(<a href="suins.md#0x0_suins">suins</a>: &<b>mut</b> <a href="suins.md#0x0_suins_SuiNS">suins::SuiNS</a>, nft: &<a href="registration_nft.md#0x0_registration_nft_RegistrationNFT">registration_nft::RegistrationNFT</a>, new_target: <a href="_Option">option::Option</a>&lt;<b>address</b>&gt;, <a href="">clock</a>: &<a href="_Clock">clock::Clock</a>)
</code></pre>


<a name="0x0_controller_set_reverse_lookup"></a>

## Function `set_reverse_lookup`

User-facing function (upgradable) - set the reverse lookup address for the domain.


<pre><code>entry <b>fun</b> <a href="controller.md#0x0_controller_set_reverse_lookup">set_reverse_lookup</a>(<a href="suins.md#0x0_suins">suins</a>: &<b>mut</b> <a href="suins.md#0x0_suins_SuiNS">suins::SuiNS</a>, domain_name: <a href="_String">string::String</a>, ctx: &<a href="_TxContext">tx_context::TxContext</a>)
</code></pre>


<a name="0x0_controller_unset_reverse_lookup"></a>

## Function `unset_reverse_lookup`

User-facing function (upgradable) - unset the reverse lookup address for the domain.


<pre><code>entry <b>fun</b> <a href="controller.md#0x0_controller_unset_reverse_lookup">unset_reverse_lookup</a>(<a href="suins.md#0x0_suins">suins</a>: &<b>mut</b> <a href="suins.md#0x0_suins_SuiNS">suins::SuiNS</a>, ctx: &<a href="_TxContext">tx_context::TxContext</a>)
</code></pre>


<a name="0x0_controller_set_user_data"></a>

## Function `set_user_data`

User-facing function (upgradable) - add a new key-value pair to the name record's data.


<pre><code>entry <b>fun</b> <a href="controller.md#0x0_controller_set_user_data">set_user_data</a>(<a href="suins.md#0x0_suins">suins</a>: &<b>mut</b> <a href="suins.md#0x0_suins_SuiNS">suins::SuiNS</a>, nft: &<a href="registration_nft.md#0x0_registration_nft_RegistrationNFT">registration_nft::RegistrationNFT</a>, key: <a href="_String">string::String</a>, value: <a href="_String">string::String</a>, <a href="">clock</a>: &<a href="_Clock">clock::Clock</a>)
</code></pre>


<a name="0x0_controller_unset_user_data"></a>

## Function `unset_user_data`

User-facing function (upgradable) - remove a key from the name record's data.


<pre><code>entry <b>fun</b> <a href="controller.md#0x0_controller_unset_user_data">unset_user_data</a>(<a href="suins.md#0x0_suins">suins</a>: &<b>mut</b> <a href="suins.md#0x0_suins_SuiNS">suins::SuiNS</a>, nft: &<a href="registration_nft.md#0x0_registration_nft_RegistrationNFT">registration_nft::RegistrationNFT</a>, key: <a href="_String">string::String</a>, <a href="">clock</a>: &<a href="_Clock">clock::Clock</a>)
</code></pre>
