
<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_admin"></a>

# Module `0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94::admin`

Admin features of the SuiNS application. Meant to be called directly
by the suins admin.


-  [Struct `Admin`](#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_admin_Admin)
-  [Function `authorize`](#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_admin_authorize)
-  [Function `reserve_domain`](#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_admin_reserve_domain)
-  [Function `reserve_domains`](#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_admin_reserve_domains)


<pre><code><b>use</b> <a href="dependencies/move-stdlib/string.md#0x1_string">0x1::string</a>;
<b>use</b> <a href="dependencies/move-stdlib/vector.md#0x1_vector">0x1::vector</a>;
<b>use</b> <a href="dependencies/sui-framework/clock.md#0x2_clock">0x2::clock</a>;
<b>use</b> <a href="dependencies/sui-framework/transfer.md#0x2_transfer">0x2::transfer</a>;
<b>use</b> <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context">0x2::tx_context</a>;
<b>use</b> <a href="config.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_config">0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94::config</a>;
<b>use</b> <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94::domain</a>;
<b>use</b> <a href="registry.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_registry">0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94::registry</a>;
<b>use</b> <a href="suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94::suins</a>;
<b>use</b> <a href="suins_registration.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_registration">0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94::suins_registration</a>;
</code></pre>



<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_admin_Admin"></a>

## Struct `Admin`

The authorization witness.


<pre><code><b>struct</b> <a href="admin.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_admin_Admin">Admin</a> <b>has</b> drop
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

<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_admin_authorize"></a>

## Function `authorize`

Authorize the admin application in the SuiNS to get access
to protected functions. Must be called in order to use the rest
of the functions.


<pre><code><b>public</b> <b>fun</b> <a href="admin.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_admin_authorize">authorize</a>(cap: &<a href="suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_AdminCap">suins::AdminCap</a>, <a href="suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>: &<b>mut</b> <a href="suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_SuiNS">suins::SuiNS</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="admin.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_admin_authorize">authorize</a>(cap: &AdminCap, <a href="suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>: &<b>mut</b> SuiNS) {
    <a href="suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_authorize_app">suins::authorize_app</a>&lt;<a href="admin.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_admin_Admin">Admin</a>&gt;(cap, <a href="suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>)
}
</code></pre>



</details>

<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_admin_reserve_domain"></a>

## Function `reserve_domain`

Reserve a <code><a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a></code> in the <code>SuiNS</code>.


<pre><code><b>public</b> <b>fun</b> <a href="admin.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_admin_reserve_domain">reserve_domain</a>(_: &<a href="suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_AdminCap">suins::AdminCap</a>, <a href="suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>: &<b>mut</b> <a href="suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_SuiNS">suins::SuiNS</a>, domain_name: <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>, no_years: u8, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &<a href="dependencies/sui-framework/clock.md#0x2_clock_Clock">clock::Clock</a>, ctx: &<b>mut</b> <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context_TxContext">tx_context::TxContext</a>): <a href="suins_registration.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_registration_SuinsRegistration">suins_registration::SuinsRegistration</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="admin.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_admin_reserve_domain">reserve_domain</a>(
    _: &AdminCap,
    <a href="suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>: &<b>mut</b> SuiNS,
    domain_name: String,
    no_years: u8,
    <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &Clock,
    ctx: &<b>mut</b> TxContext
): SuinsRegistration {
    <b>let</b> <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a> = <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_new">domain::new</a>(domain_name);
    <a href="config.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_config_assert_valid_user_registerable_domain">config::assert_valid_user_registerable_domain</a>(&<a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a>);
    <b>let</b> <a href="registry.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_registry">registry</a> = <a href="suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_app_registry_mut">suins::app_registry_mut</a>&lt;<a href="admin.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_admin_Admin">Admin</a>, Registry&gt;(<a href="admin.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_admin_Admin">Admin</a> {}, <a href="suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>);
    <a href="registry.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_registry">registry</a>.add_record(<a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a>, no_years, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>, ctx)
}
</code></pre>



</details>

<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_admin_reserve_domains"></a>

## Function `reserve_domains`

Reserve a list of domains.


<pre><code>entry <b>fun</b> <a href="admin.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_admin_reserve_domains">reserve_domains</a>(_: &<a href="suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_AdminCap">suins::AdminCap</a>, <a href="suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>: &<b>mut</b> <a href="suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_SuiNS">suins::SuiNS</a>, domains: <a href="dependencies/move-stdlib/vector.md#0x1_vector">vector</a>&lt;<a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>&gt;, no_years: u8, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &<a href="dependencies/sui-framework/clock.md#0x2_clock_Clock">clock::Clock</a>, ctx: &<b>mut</b> <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code>entry <b>fun</b> <a href="admin.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_admin_reserve_domains">reserve_domains</a>(
    _: &AdminCap,
    <a href="suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>: &<b>mut</b> SuiNS,
    <b>mut</b> domains: <a href="dependencies/move-stdlib/vector.md#0x1_vector">vector</a>&lt;String&gt;,
    no_years: u8,
    <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &Clock,
    ctx: &<b>mut</b> TxContext
) {
    <b>let</b> sender = sender(ctx);
    <b>let</b> <a href="registry.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_registry">registry</a> = <a href="suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_app_registry_mut">suins::app_registry_mut</a>&lt;<a href="admin.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_admin_Admin">Admin</a>, Registry&gt;(<a href="admin.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_admin_Admin">Admin</a> {}, <a href="suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>);
    <b>while</b> (!domains.is_empty()) {
        <b>let</b> <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a> = <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_new">domain::new</a>(domains.pop_back());
        <a href="config.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_config_assert_valid_user_registerable_domain">config::assert_valid_user_registerable_domain</a>(&<a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a>);
        <b>let</b> nft = <a href="registry.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_registry">registry</a>.add_record(<a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a>, no_years, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>, ctx);
        sui::transfer::public_transfer(nft, sender);
    };
}
</code></pre>



</details>
