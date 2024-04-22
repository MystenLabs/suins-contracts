
<a name="0x0_admin"></a>

# Module `0x0::admin`

Admin features of the SuiNS application. Meant to be called directly
by the suins admin.


-  [Struct `Admin`](#0x0_admin_Admin)
-  [Function `authorize`](#0x0_admin_authorize)
-  [Function `reserve_domain`](#0x0_admin_reserve_domain)
-  [Function `reserve_domains`](#0x0_admin_reserve_domains)


<pre><code><b>use</b> <a href="config.md#0x0_config">0x0::config</a>;
<b>use</b> <a href="domain.md#0x0_domain">0x0::domain</a>;
<b>use</b> <a href="registration_nft.md#0x0_registration_nft">0x0::registration_nft</a>;
<b>use</b> <a href="registry.md#0x0_registry">0x0::registry</a>;
<b>use</b> <a href="suins.md#0x0_suins">0x0::suins</a>;
<b>use</b> <a href="">0x1::string</a>;
<b>use</b> <a href="">0x1::vector</a>;
<b>use</b> <a href="">0x2::clock</a>;
<b>use</b> <a href="">0x2::transfer</a>;
<b>use</b> <a href="">0x2::tx_context</a>;
</code></pre>



<a name="0x0_admin_Admin"></a>

## Struct `Admin`

The authorization witness.


<pre><code><b>struct</b> <a href="admin.md#0x0_admin_Admin">Admin</a> <b>has</b> drop
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

<a name="0x0_admin_authorize"></a>

## Function `authorize`

Authorize the admin application in the SuiNS to get access
to protected functions. Must be called in order to use the rest
of the functions.


<pre><code><b>public</b> <b>fun</b> <a href="admin.md#0x0_admin_authorize">authorize</a>(cap: &<a href="suins.md#0x0_suins_AdminCap">suins::AdminCap</a>, <a href="suins.md#0x0_suins">suins</a>: &<b>mut</b> <a href="suins.md#0x0_suins_SuiNS">suins::SuiNS</a>)
</code></pre>


<a name="0x0_admin_reserve_domain"></a>

## Function `reserve_domain`

Reserve a <code><a href="domain.md#0x0_domain">domain</a></code> in the <code>SuiNS</code>.


<pre><code><b>public</b> <b>fun</b> <a href="admin.md#0x0_admin_reserve_domain">reserve_domain</a>(_: &<a href="suins.md#0x0_suins_AdminCap">suins::AdminCap</a>, <a href="suins.md#0x0_suins">suins</a>: &<b>mut</b> <a href="suins.md#0x0_suins_SuiNS">suins::SuiNS</a>, domain_name: <a href="_String">string::String</a>, no_years: u8, <a href="">clock</a>: &<a href="_Clock">clock::Clock</a>, ctx: &<b>mut</b> <a href="_TxContext">tx_context::TxContext</a>): <a href="registration_nft.md#0x0_registration_nft_RegistrationNFT">registration_nft::RegistrationNFT</a>
</code></pre>


<a name="0x0_admin_reserve_domains"></a>

## Function `reserve_domains`

Reserve a list of domains.


<pre><code>entry <b>fun</b> <a href="admin.md#0x0_admin_reserve_domains">reserve_domains</a>(_: &<a href="suins.md#0x0_suins_AdminCap">suins::AdminCap</a>, <a href="suins.md#0x0_suins">suins</a>: &<b>mut</b> <a href="suins.md#0x0_suins_SuiNS">suins::SuiNS</a>, domains: <a href="">vector</a>&lt;<a href="_String">string::String</a>&gt;, no_years: u8, <a href="">clock</a>: &<a href="_Clock">clock::Clock</a>, ctx: &<b>mut</b> <a href="_TxContext">tx_context::TxContext</a>)
</code></pre>
