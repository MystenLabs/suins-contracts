
<a name="0x0_subdomains"></a>

# Module `0x0::subdomains`

A registration module for subdomains.

This module is responsible for creating subdomains and managing their settings.

It allows the following functionality:

1. Registering a new subdomain as a holder of Parent NFT.
2. Setup the subdomain with capabilities (creating nested names, extending to parent's renewal time).
3. Registering <code>leaf</code> names (whose parent acts as the Capability holder)
4. Removing <code>leaf</code> names
5. Extending a subdomain expiration's time
6. Burning expired subdomain NFTs.

Comments:

1. By attaching the creation/extension attributes as metadata to the subdomain's NameRecord, we can easily
turn off this package completely, and retain the state on a different package's deployment. This is useful
both for effort-less upgradeability and gas savings.
2. For any <code>registry_mut</code> call, we know that if this module is not authorized, we'll get an abort
from the core suins package.

OPEN TODOS:



-  [Struct `SubDomains`](#0x0_subdomains_SubDomains)
-  [Struct `ParentKey`](#0x0_subdomains_ParentKey)
-  [Struct `App`](#0x0_subdomains_App)
-  [Constants](#@Constants_0)
-  [Function `setup`](#0x0_subdomains_setup)
-  [Function `new_leaf`](#0x0_subdomains_new_leaf)
-  [Function `remove_leaf`](#0x0_subdomains_remove_leaf)
-  [Function `new`](#0x0_subdomains_new)
-  [Function `extend_expiration`](#0x0_subdomains_extend_expiration)
-  [Function `edit_setup`](#0x0_subdomains_edit_setup)
-  [Function `burn`](#0x0_subdomains_burn)
-  [Function `parent`](#0x0_subdomains_parent)
-  [Function `internal_set_flag`](#0x0_subdomains_internal_set_flag)
-  [Function `is_creation_allowed`](#0x0_subdomains_is_creation_allowed)
-  [Function `is_extension_allowed`](#0x0_subdomains_is_extension_allowed)
-  [Function `record_metadata`](#0x0_subdomains_record_metadata)
-  [Function `internal_validate_nft_can_manage_subdomain`](#0x0_subdomains_internal_validate_nft_can_manage_subdomain)
-  [Function `internal_assert_parent_can_create_subdomains`](#0x0_subdomains_internal_assert_parent_can_create_subdomains)
-  [Function `internal_create_subdomain`](#0x0_subdomains_internal_create_subdomain)
-  [Function `registry`](#0x0_subdomains_registry)
-  [Function `registry_mut`](#0x0_subdomains_registry_mut)
-  [Function `app_config`](#0x0_subdomains_app_config)


<pre><code><b>use</b> <a href="config.md#0x0_config">0x0::config</a>;
<b>use</b> <a href="dependencies/denylist/denylist.md#0x0_denylist">0x0::denylist</a>;
<b>use</b> <a href="dependencies/move-stdlib/option.md#0x1_option">0x1::option</a>;
<b>use</b> <a href="dependencies/move-stdlib/string.md#0x1_string">0x1::string</a>;
<b>use</b> <a href="dependencies/sui-framework/clock.md#0x2_clock">0x2::clock</a>;
<b>use</b> <a href="dependencies/sui-framework/dynamic_field.md#0x2_dynamic_field">0x2::dynamic_field</a>;
<b>use</b> <a href="dependencies/sui-framework/object.md#0x2_object">0x2::object</a>;
<b>use</b> <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context">0x2::tx_context</a>;
<b>use</b> <a href="dependencies/sui-framework/vec_map.md#0x2_vec_map">0x2::vec_map</a>;
<b>use</b> <a href="dependencies/suins/constants.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_constants">0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0::constants</a>;
<b>use</b> <a href="dependencies/suins/domain.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_domain">0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0::domain</a>;
<b>use</b> <a href="dependencies/suins/name_record.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_name_record">0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0::name_record</a>;
<b>use</b> <a href="dependencies/suins/registry.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_registry">0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0::registry</a>;
<b>use</b> <a href="dependencies/suins/subdomain_registration.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_subdomain_registration">0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0::subdomain_registration</a>;
<b>use</b> <a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0::suins</a>;
<b>use</b> <a href="dependencies/suins/suins_registration.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins_registration">0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0::suins_registration</a>;
</code></pre>



<a name="0x0_subdomains_SubDomains"></a>

## Struct `SubDomains`

The authentication scheme for SuiNS.


<pre><code><b>struct</b> <a href="subdomains.md#0x0_subdomains_SubDomains">SubDomains</a> <b>has</b> drop
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

<a name="0x0_subdomains_ParentKey"></a>

## Struct `ParentKey`

The key to store the parent's ID in the subdomain object.


<pre><code><b>struct</b> <a href="subdomains.md#0x0_subdomains_ParentKey">ParentKey</a> <b>has</b> <b>copy</b>, drop, store
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

<a name="0x0_subdomains_App"></a>

## Struct `App`

The subdomain's config (specifies allowed TLDs, depth, sizes).


<pre><code><b>struct</b> <a href="subdomains.md#0x0_subdomains_App">App</a> <b>has</b> store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code><a href="config.md#0x0_config">config</a>: <a href="config.md#0x0_config_SubDomainConfig">config::SubDomainConfig</a></code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="@Constants_0"></a>

## Constants


<a name="0x0_subdomains_ACTIVE_METADATA_VALUE"></a>

Enabled metadata value.


<pre><code><b>const</b> <a href="subdomains.md#0x0_subdomains_ACTIVE_METADATA_VALUE">ACTIVE_METADATA_VALUE</a>: <a href="dependencies/move-stdlib/vector.md#0x1_vector">vector</a>&lt;u8&gt; = [49];
</code></pre>



<a name="0x0_subdomains_ECreationDisabledForSubDomain"></a>

Tries to create a subdomain with a parent that is not allowed to do so.


<pre><code><b>const</b> <a href="subdomains.md#0x0_subdomains_ECreationDisabledForSubDomain">ECreationDisabledForSubDomain</a>: u64 = 2;
</code></pre>



<a name="0x0_subdomains_EExtensionDisabledForSubDomain"></a>

Tries to extend the expiration of a subdomain which doesn't have the permission to do so.


<pre><code><b>const</b> <a href="subdomains.md#0x0_subdomains_EExtensionDisabledForSubDomain">EExtensionDisabledForSubDomain</a>: u64 = 3;
</code></pre>



<a name="0x0_subdomains_EInvalidExpirationDate"></a>

Tries to create a subdomain that expires later than the parent or below the minimum.


<pre><code><b>const</b> <a href="subdomains.md#0x0_subdomains_EInvalidExpirationDate">EInvalidExpirationDate</a>: u64 = 1;
</code></pre>



<a name="0x0_subdomains_ENotAllowedName"></a>

Checks whether a name is allowed or not (against blocked names list)


<pre><code><b>const</b> <a href="subdomains.md#0x0_subdomains_ENotAllowedName">ENotAllowedName</a>: u64 = 6;
</code></pre>



<a name="0x0_subdomains_EParentChanged"></a>

Parent for a given subdomain has changed, hence time extension cannot be done.


<pre><code><b>const</b> <a href="subdomains.md#0x0_subdomains_EParentChanged">EParentChanged</a>: u64 = 5;
</code></pre>



<a name="0x0_subdomains_ESubdomainReplaced"></a>

The subdomain has been replaced by a newer NFT, so it can't be renewed.


<pre><code><b>const</b> <a href="subdomains.md#0x0_subdomains_ESubdomainReplaced">ESubdomainReplaced</a>: u64 = 4;
</code></pre>



<a name="0x0_subdomains_setup"></a>

## Function `setup`



<pre><code><b>public</b> <b>fun</b> <a href="subdomains.md#0x0_subdomains_setup">setup</a>(<a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>: &<b>mut</b> <a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins_SuiNS">suins::SuiNS</a>, cap: &<a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins_AdminCap">suins::AdminCap</a>, _ctx: &<b>mut</b> <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="subdomains.md#0x0_subdomains_setup">setup</a>(<a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>: &<b>mut</b> SuiNS, cap: &AdminCap, _ctx: &<b>mut</b> TxContext){
    <a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins_add_registry">suins::add_registry</a>(cap, <a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>, <a href="subdomains.md#0x0_subdomains_App">App</a> {
        <a href="config.md#0x0_config">config</a>: <a href="config.md#0x0_config_default">config::default</a>()
    })
}
</code></pre>



</details>

<a name="0x0_subdomains_new_leaf"></a>

## Function `new_leaf`

Creates a <code>leaf</code> subdomain
A <code>leaf</code> subdomain, is a subdomain that is managed by the parent's NFT.


<pre><code><b>public</b> <b>fun</b> <a href="subdomains.md#0x0_subdomains_new_leaf">new_leaf</a>(<a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>: &<b>mut</b> <a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins_SuiNS">suins::SuiNS</a>, parent: &<a href="dependencies/suins/suins_registration.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins_registration_SuinsRegistration">suins_registration::SuinsRegistration</a>, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &<a href="dependencies/sui-framework/clock.md#0x2_clock_Clock">clock::Clock</a>, subdomain_name: <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>, target: <b>address</b>, ctx: &<b>mut</b> <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="subdomains.md#0x0_subdomains_new_leaf">new_leaf</a>(
    <a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>: &<b>mut</b> SuiNS,
    parent: &SuinsRegistration,
    <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &Clock,
    subdomain_name: String,
    target: <b>address</b>,
    ctx: &<b>mut</b> TxContext
) {
    <b>assert</b>!(!<a href="dependencies/denylist/denylist.md#0x0_denylist_is_blocked_name">denylist::is_blocked_name</a>(<a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>, subdomain_name), <a href="subdomains.md#0x0_subdomains_ENotAllowedName">ENotAllowedName</a>);

    <b>let</b> subdomain = <a href="dependencies/suins/domain.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_domain_new">domain::new</a>(subdomain_name);
    // all validation logic for subdomain creation / management.
    <a href="subdomains.md#0x0_subdomains_internal_validate_nft_can_manage_subdomain">internal_validate_nft_can_manage_subdomain</a>(<a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>, parent, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>, subdomain, <b>true</b>);

    // Aborts <b>with</b> `suins::registry::ERecordExists` <b>if</b> the subdomain already exists.
    <a href="subdomains.md#0x0_subdomains_registry_mut">registry_mut</a>(<a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>).add_leaf_record(subdomain, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>, target, ctx)
}
</code></pre>



</details>

<a name="0x0_subdomains_remove_leaf"></a>

## Function `remove_leaf`

Removes a <code>leaf</code> subdomain from the registry.
Management of the <code>leaf</code> subdomain can only be achieved through the parent's valid NFT.


<pre><code><b>public</b> <b>fun</b> <a href="subdomains.md#0x0_subdomains_remove_leaf">remove_leaf</a>(<a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>: &<b>mut</b> <a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins_SuiNS">suins::SuiNS</a>, parent: &<a href="dependencies/suins/suins_registration.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins_registration_SuinsRegistration">suins_registration::SuinsRegistration</a>, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &<a href="dependencies/sui-framework/clock.md#0x2_clock_Clock">clock::Clock</a>, subdomain_name: <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="subdomains.md#0x0_subdomains_remove_leaf">remove_leaf</a>(
    <a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>: &<b>mut</b> SuiNS,
    parent: &SuinsRegistration,
    <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &Clock,
    subdomain_name: String,
) {
    <b>let</b> subdomain = <a href="dependencies/suins/domain.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_domain_new">domain::new</a>(subdomain_name);

    // All validation logic for subdomain creation / management.
    // We pass `<b>false</b>` <b>as</b> last argument because even <b>if</b> we don't have create capabilities (anymore),
    // we can still remove a leaf name (we just can't add a new one).
    <a href="subdomains.md#0x0_subdomains_internal_validate_nft_can_manage_subdomain">internal_validate_nft_can_manage_subdomain</a>(<a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>, parent, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>, subdomain, <b>false</b>);

    <a href="subdomains.md#0x0_subdomains_registry_mut">registry_mut</a>(<a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>).remove_leaf_record(subdomain)
}
</code></pre>



</details>

<a name="0x0_subdomains_new"></a>

## Function `new`

Creates a new <code>node</code> subdomain

The following script does the following lookups:
1. Checks if app is authorized.
2. Validates that the parent NFT is valid and non expired.
3. Validates that the parent can create subdomains (based on the on-chain setup). [all 2nd level names with valid tld can create names]
4. Validates the subdomain validity.
2.1 Checks that the TLD is in the list of supported tlds.
2.2 Checks that the length of the new label has the min lenth.
2.3 Validates that this subdomain can indeed be registered by that parent.
2.4 Validates that the subdomain's expiration timestamp is less or equal to the parents.
2.5 Checks if this subdomain already exists. [If it does, it aborts if it's not expired, overrides otherwise]

It then saves the configuration for that child (manage-able by the parent), and returns the SuinsRegistration object.


<pre><code><b>public</b> <b>fun</b> <a href="subdomains.md#0x0_subdomains_new">new</a>(<a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>: &<b>mut</b> <a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins_SuiNS">suins::SuiNS</a>, parent: &<a href="dependencies/suins/suins_registration.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins_registration_SuinsRegistration">suins_registration::SuinsRegistration</a>, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &<a href="dependencies/sui-framework/clock.md#0x2_clock_Clock">clock::Clock</a>, subdomain_name: <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>, expiration_timestamp_ms: u64, allow_creation: bool, allow_time_extension: bool, ctx: &<b>mut</b> <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context_TxContext">tx_context::TxContext</a>): <a href="dependencies/suins/subdomain_registration.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_subdomain_registration_SubDomainRegistration">subdomain_registration::SubDomainRegistration</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="subdomains.md#0x0_subdomains_new">new</a>(
    <a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>: &<b>mut</b> SuiNS,
    parent: &SuinsRegistration,
    <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &Clock,
    subdomain_name: String,
    expiration_timestamp_ms: u64,
    allow_creation: bool,
    allow_time_extension: bool,
    ctx: &<b>mut</b> TxContext
): SubDomainRegistration {
    <b>assert</b>!(!<a href="dependencies/denylist/denylist.md#0x0_denylist_is_blocked_name">denylist::is_blocked_name</a>(<a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>, subdomain_name), <a href="subdomains.md#0x0_subdomains_ENotAllowedName">ENotAllowedName</a>);

    <b>let</b> subdomain = <a href="dependencies/suins/domain.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_domain_new">domain::new</a>(subdomain_name);
    // all validation logic for subdomain creation / management.
    <a href="subdomains.md#0x0_subdomains_internal_validate_nft_can_manage_subdomain">internal_validate_nft_can_manage_subdomain</a>(<a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>, parent, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>, subdomain, <b>true</b>);

    // Validate that the duration is at least the minimum duration.
    <b>assert</b>!(expiration_timestamp_ms &gt;= <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>.timestamp_ms() + <a href="subdomains.md#0x0_subdomains_app_config">app_config</a>(<a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>).<a href="config.md#0x0_config">config</a>.minimum_duration(), <a href="subdomains.md#0x0_subdomains_EInvalidExpirationDate">EInvalidExpirationDate</a>);
    // validate that the requested expiration timestamp is not greater than the parent's one.
    <b>assert</b>!(expiration_timestamp_ms &lt;= parent.expiration_timestamp_ms(), <a href="subdomains.md#0x0_subdomains_EInvalidExpirationDate">EInvalidExpirationDate</a>);

    // We register the subdomain (e.g. `subdomain.example.<a href="dependencies/sui-framework/sui.md#0x2_sui">sui</a>`) and <b>return</b> the SuinsRegistration <a href="dependencies/sui-framework/object.md#0x2_object">object</a>.
    // Aborts <b>with</b> `suins::registry::ERecordExists` <b>if</b> the subdomain already exists.
    <b>let</b> nft = <a href="subdomains.md#0x0_subdomains_internal_create_subdomain">internal_create_subdomain</a>(<a href="subdomains.md#0x0_subdomains_registry_mut">registry_mut</a>(<a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>), subdomain, expiration_timestamp_ms, <a href="dependencies/sui-framework/object.md#0x2_object_id">object::id</a>(parent), <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>, ctx);

    // We create the `setup` for the particular SubDomainRegistration.
    // We save a setting like: `subdomain.example.<a href="dependencies/sui-framework/sui.md#0x2_sui">sui</a>` -&gt; { allow_creation: <b>true</b>/<b>false</b>, allow_time_extension: <b>true</b>/<b>false</b> }
    <b>if</b> (allow_creation) {
        <a href="subdomains.md#0x0_subdomains_internal_set_flag">internal_set_flag</a>(<a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>, subdomain, subdomain_allow_creation_key(), allow_creation);
    };

    <b>if</b> (allow_time_extension){
        <a href="subdomains.md#0x0_subdomains_internal_set_flag">internal_set_flag</a>(<a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>, subdomain, subdomain_allow_extension_key(), allow_time_extension);
    };

    nft
}
</code></pre>



</details>

<a name="0x0_subdomains_extend_expiration"></a>

## Function `extend_expiration`

Extends the expiration of a <code>node</code> subdomain.


<pre><code><b>public</b> <b>fun</b> <a href="subdomains.md#0x0_subdomains_extend_expiration">extend_expiration</a>(<a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>: &<b>mut</b> <a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins_SuiNS">suins::SuiNS</a>, sub_nft: &<b>mut</b> <a href="dependencies/suins/subdomain_registration.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_subdomain_registration_SubDomainRegistration">subdomain_registration::SubDomainRegistration</a>, expiration_timestamp_ms: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="subdomains.md#0x0_subdomains_extend_expiration">extend_expiration</a>(
    <a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>: &<b>mut</b> SuiNS,
    sub_nft: &<b>mut</b> SubDomainRegistration,
    expiration_timestamp_ms: u64,
) {
    <b>let</b> <a href="dependencies/suins/registry.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_registry">registry</a> = <a href="dependencies/suins/registry.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_registry">registry</a>(<a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>);

    <b>let</b> nft = sub_nft.nft_mut();
    <b>let</b> subdomain = nft.<a href="dependencies/suins/domain.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_domain">domain</a>();
    <b>let</b> parent_domain = subdomain.<a href="subdomains.md#0x0_subdomains_parent">parent</a>();

    // Check <b>if</b> time extension is allowed for this subdomain.
    <b>assert</b>!(<a href="subdomains.md#0x0_subdomains_is_extension_allowed">is_extension_allowed</a>(&<a href="subdomains.md#0x0_subdomains_record_metadata">record_metadata</a>(<a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>, subdomain)), <a href="subdomains.md#0x0_subdomains_EExtensionDisabledForSubDomain">EExtensionDisabledForSubDomain</a>);

    <b>let</b> existing_name_record = <a href="dependencies/suins/registry.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_registry">registry</a>.lookup(subdomain);
    <b>let</b> parent_name_record = <a href="dependencies/suins/registry.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_registry">registry</a>.lookup(parent_domain);

    // we need <b>to</b> make sure this name record exists (both child + parent), otherwise we don't have a valid <a href="dependencies/sui-framework/object.md#0x2_object">object</a>.
    <b>assert</b>!(<a href="dependencies/move-stdlib/option.md#0x1_option_is_some">option::is_some</a>(&existing_name_record) && <a href="dependencies/move-stdlib/option.md#0x1_option_is_some">option::is_some</a>(&parent_name_record), <a href="subdomains.md#0x0_subdomains_ESubdomainReplaced">ESubdomainReplaced</a>);

    // Validate that the parent of the name is the same <b>as</b> the actual parent
    // (<b>to</b> prevent cases <b>where</b> owner of the parent changed. When that happens, <a href="subdomains.md#0x0_subdomains">subdomains</a> lose all abilities <b>to</b> renew / create <a href="subdomains.md#0x0_subdomains">subdomains</a>)
    <b>assert</b>!(<a href="subdomains.md#0x0_subdomains_parent">parent</a>(nft) == <a href="dependencies/move-stdlib/option.md#0x1_option_borrow">option::borrow</a>(&parent_name_record).nft_id(), <a href="subdomains.md#0x0_subdomains_EParentChanged">EParentChanged</a>);

    // validate that expiration date is &gt; than the current.
    <b>assert</b>!(expiration_timestamp_ms &gt; nft.expiration_timestamp_ms(), <a href="subdomains.md#0x0_subdomains_EInvalidExpirationDate">EInvalidExpirationDate</a>);
    // validate that the requested expiration timestamp is not greater than the parent's one.
    <b>assert</b>!(expiration_timestamp_ms &lt;= <a href="dependencies/move-stdlib/option.md#0x1_option_borrow">option::borrow</a>(&parent_name_record).expiration_timestamp_ms(), <a href="subdomains.md#0x0_subdomains_EInvalidExpirationDate">EInvalidExpirationDate</a>);

    <a href="subdomains.md#0x0_subdomains_registry_mut">registry_mut</a>(<a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>).set_expiration_timestamp_ms(nft, subdomain, expiration_timestamp_ms);
}
</code></pre>



</details>

<a name="0x0_subdomains_edit_setup"></a>

## Function `edit_setup`

Called by the parent domain to edit a subdomain's settings.
- Allows the parent domain to toggle time extension.
- Allows the parent to toggle subdomain (grand-children) creation
--> For creations: A parent can't retract already created children, nor can limit the depth if creation capability is on.


<pre><code><b>public</b> <b>fun</b> <a href="subdomains.md#0x0_subdomains_edit_setup">edit_setup</a>(<a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>: &<b>mut</b> <a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins_SuiNS">suins::SuiNS</a>, parent: &<a href="dependencies/suins/suins_registration.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins_registration_SuinsRegistration">suins_registration::SuinsRegistration</a>, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &<a href="dependencies/sui-framework/clock.md#0x2_clock_Clock">clock::Clock</a>, subdomain_name: <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>, allow_creation: bool, allow_time_extension: bool)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="subdomains.md#0x0_subdomains_edit_setup">edit_setup</a>(
    <a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>: &<b>mut</b> SuiNS,
    parent: &SuinsRegistration,
    <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &Clock,
    subdomain_name: String,
    allow_creation: bool,
    allow_time_extension: bool
) {
    // validate that parent is a valid, non expired <a href="dependencies/sui-framework/object.md#0x2_object">object</a>.
    <a href="dependencies/suins/registry.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_registry">registry</a>(<a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>).assert_nft_is_authorized(parent, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>);

    <b>let</b> parent_domain = parent.<a href="dependencies/suins/domain.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_domain">domain</a>();
    <b>let</b> subdomain = <a href="dependencies/suins/domain.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_domain_new">domain::new</a>(subdomain_name);

    // validate that the subdomain is valid for the supplied parent
    // (<b>as</b> well <b>as</b> it is valid in label length, total length, depth, etc).
    <a href="config.md#0x0_config_assert_is_valid_subdomain">config::assert_is_valid_subdomain</a>(&parent_domain, &subdomain, &<a href="subdomains.md#0x0_subdomains_app_config">app_config</a>(<a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>).<a href="config.md#0x0_config">config</a>);

    // We create the `setup` for the particular SubDomainRegistration.
    // We save a setting like: `subdomain.example.<a href="dependencies/sui-framework/sui.md#0x2_sui">sui</a>` -&gt; { allow_creation: <b>true</b>/<b>false</b>, allow_time_extension: <b>true</b>/<b>false</b> }
    <a href="subdomains.md#0x0_subdomains_internal_set_flag">internal_set_flag</a>(<a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>, subdomain, subdomain_allow_creation_key(), allow_creation);
    <a href="subdomains.md#0x0_subdomains_internal_set_flag">internal_set_flag</a>(<a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>, subdomain, subdomain_allow_extension_key(), allow_time_extension);
}
</code></pre>



</details>

<a name="0x0_subdomains_burn"></a>

## Function `burn`

Burns a <code>SubDomainRegistration</code> object if it is expired.


<pre><code><b>public</b> <b>fun</b> <a href="subdomains.md#0x0_subdomains_burn">burn</a>(<a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>: &<b>mut</b> <a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins_SuiNS">suins::SuiNS</a>, nft: <a href="dependencies/suins/subdomain_registration.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_subdomain_registration_SubDomainRegistration">subdomain_registration::SubDomainRegistration</a>, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &<a href="dependencies/sui-framework/clock.md#0x2_clock_Clock">clock::Clock</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="subdomains.md#0x0_subdomains_burn">burn</a>(
    <a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>: &<b>mut</b> SuiNS,
    nft: SubDomainRegistration,
    <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &Clock,
) {
    <a href="subdomains.md#0x0_subdomains_registry_mut">registry_mut</a>(<a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>).burn_subdomain_object(nft, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>);
}
</code></pre>



</details>

<a name="0x0_subdomains_parent"></a>

## Function `parent`

Parent ID of a subdomain


<pre><code><b>public</b> <b>fun</b> <a href="subdomains.md#0x0_subdomains_parent">parent</a>(subdomain: &<a href="dependencies/suins/suins_registration.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins_registration_SuinsRegistration">suins_registration::SuinsRegistration</a>): <a href="dependencies/sui-framework/object.md#0x2_object_ID">object::ID</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="subdomains.md#0x0_subdomains_parent">parent</a>(subdomain: &SuinsRegistration): ID {
    *df::borrow(subdomain.uid(), <a href="subdomains.md#0x0_subdomains_ParentKey">ParentKey</a> {})
}
</code></pre>



</details>

<a name="0x0_subdomains_internal_set_flag"></a>

## Function `internal_set_flag`



<pre><code><b>fun</b> <a href="subdomains.md#0x0_subdomains_internal_set_flag">internal_set_flag</a>(self: &<b>mut</b> <a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins_SuiNS">suins::SuiNS</a>, subdomain: <a href="dependencies/suins/domain.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_domain_Domain">domain::Domain</a>, key: <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>, enable: bool)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="subdomains.md#0x0_subdomains_internal_set_flag">internal_set_flag</a>(
    self: &<b>mut</b> SuiNS,
    subdomain: Domain,
    key: String,
    enable: bool
) {
    <b>let</b> <b>mut</b> <a href="config.md#0x0_config">config</a> = <a href="subdomains.md#0x0_subdomains_record_metadata">record_metadata</a>(self, subdomain);
    <b>let</b> is_enabled = <a href="config.md#0x0_config">config</a>.contains(&key);

    <b>if</b> (enable && !is_enabled) {
        <a href="config.md#0x0_config">config</a>.insert(key,  utf8(<a href="subdomains.md#0x0_subdomains_ACTIVE_METADATA_VALUE">ACTIVE_METADATA_VALUE</a>));
    };

    <b>if</b>(!enable && is_enabled) {
        <a href="config.md#0x0_config">config</a>.remove(&key);
    };

    <a href="subdomains.md#0x0_subdomains_registry_mut">registry_mut</a>(self).set_data(subdomain, <a href="config.md#0x0_config">config</a>);
}
</code></pre>



</details>

<a name="0x0_subdomains_is_creation_allowed"></a>

## Function `is_creation_allowed`

Check if subdomain creation is allowed.


<pre><code><b>fun</b> <a href="subdomains.md#0x0_subdomains_is_creation_allowed">is_creation_allowed</a>(metadata: &<a href="dependencies/sui-framework/vec_map.md#0x2_vec_map_VecMap">vec_map::VecMap</a>&lt;<a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>, <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>&gt;): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="subdomains.md#0x0_subdomains_is_creation_allowed">is_creation_allowed</a>(metadata: &VecMap&lt;String, String&gt;): bool {
    metadata.contains(&subdomain_allow_creation_key())
}
</code></pre>



</details>

<a name="0x0_subdomains_is_extension_allowed"></a>

## Function `is_extension_allowed`

Check if time extension is allowed.


<pre><code><b>fun</b> <a href="subdomains.md#0x0_subdomains_is_extension_allowed">is_extension_allowed</a>(metadata: &<a href="dependencies/sui-framework/vec_map.md#0x2_vec_map_VecMap">vec_map::VecMap</a>&lt;<a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>, <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>&gt;): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="subdomains.md#0x0_subdomains_is_extension_allowed">is_extension_allowed</a>(metadata: &VecMap&lt;String, String&gt;): bool {
    metadata.contains(&subdomain_allow_extension_key())
}
</code></pre>



</details>

<a name="0x0_subdomains_record_metadata"></a>

## Function `record_metadata`

Get the name record's metadata for a subdomain.


<pre><code><b>fun</b> <a href="subdomains.md#0x0_subdomains_record_metadata">record_metadata</a>(self: &<a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins_SuiNS">suins::SuiNS</a>, subdomain: <a href="dependencies/suins/domain.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_domain_Domain">domain::Domain</a>): <a href="dependencies/sui-framework/vec_map.md#0x2_vec_map_VecMap">vec_map::VecMap</a>&lt;<a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>, <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="subdomains.md#0x0_subdomains_record_metadata">record_metadata</a>(
    self: &SuiNS,
    subdomain: Domain
): VecMap&lt;String, String&gt; {
    *<a href="dependencies/suins/registry.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_registry">registry</a>(self).get_data(subdomain)
}
</code></pre>



</details>

<a name="0x0_subdomains_internal_validate_nft_can_manage_subdomain"></a>

## Function `internal_validate_nft_can_manage_subdomain`

Does all the regular checks for validating that a parent <code>SuinsRegistration</code> object
can operate on a given subdomain.

1. Checks that NFT is authorized.
2. Checks that the parent can create subdomains (applies to subdomain <code>node</code> names).
3. Validates that the subdomain is valid (accepted TLD, depth, length, is child of given parent, etc).


<pre><code><b>fun</b> <a href="subdomains.md#0x0_subdomains_internal_validate_nft_can_manage_subdomain">internal_validate_nft_can_manage_subdomain</a>(<a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>: &<a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins_SuiNS">suins::SuiNS</a>, parent: &<a href="dependencies/suins/suins_registration.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins_registration_SuinsRegistration">suins_registration::SuinsRegistration</a>, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &<a href="dependencies/sui-framework/clock.md#0x2_clock_Clock">clock::Clock</a>, subdomain: <a href="dependencies/suins/domain.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_domain_Domain">domain::Domain</a>, check_creation_auth: bool)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="subdomains.md#0x0_subdomains_internal_validate_nft_can_manage_subdomain">internal_validate_nft_can_manage_subdomain</a>(
    <a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>: &SuiNS,
    parent: &SuinsRegistration,
    <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &Clock,
    subdomain: Domain,
    // Set <b>to</b> `<b>true</b>` for `validate_creation` <b>if</b> you want <b>to</b> validate that the parent can create <a href="subdomains.md#0x0_subdomains">subdomains</a>.
    // Set <b>to</b> <b>false</b> when editing the setup of a subdomain or removing leaf names.
    check_creation_auth: bool
) {
    // validate that parent is a valid, non expired <a href="dependencies/sui-framework/object.md#0x2_object">object</a>.
    <a href="dependencies/suins/registry.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_registry">registry</a>(<a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>).assert_nft_is_authorized(parent, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>);

    <b>if</b> (check_creation_auth) {
        // validate that the parent can create <a href="subdomains.md#0x0_subdomains">subdomains</a>.
        <a href="subdomains.md#0x0_subdomains_internal_assert_parent_can_create_subdomains">internal_assert_parent_can_create_subdomains</a>(<a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>, parent.<a href="dependencies/suins/domain.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_domain">domain</a>());
    };

    // validate that the subdomain is valid for the supplied parent.
    <a href="config.md#0x0_config_assert_is_valid_subdomain">config::assert_is_valid_subdomain</a>(&parent.<a href="dependencies/suins/domain.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_domain">domain</a>(), &subdomain, &<a href="subdomains.md#0x0_subdomains_app_config">app_config</a>(<a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>).<a href="config.md#0x0_config">config</a>);
}
</code></pre>



</details>

<a name="0x0_subdomains_internal_assert_parent_can_create_subdomains"></a>

## Function `internal_assert_parent_can_create_subdomains`

Validate whether a <code>SuinsRegistration</code> object is eligible for creating a subdomain.
1. If the NFT is authorized (not expired, active)
2. If the parent is a subdomain, check whether it is allowed to create subdomains.


<pre><code><b>fun</b> <a href="subdomains.md#0x0_subdomains_internal_assert_parent_can_create_subdomains">internal_assert_parent_can_create_subdomains</a>(self: &<a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins_SuiNS">suins::SuiNS</a>, parent: <a href="dependencies/suins/domain.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_domain_Domain">domain::Domain</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="subdomains.md#0x0_subdomains_internal_assert_parent_can_create_subdomains">internal_assert_parent_can_create_subdomains</a>(
    self: &SuiNS,
    parent: Domain,
) {
    // <b>if</b> the parent is not a subdomain, we can always create <a href="subdomains.md#0x0_subdomains">subdomains</a>.
    <b>if</b> (!is_subdomain(&parent)) {
        <b>return</b>
    };

    // <b>if</b> `parent` is a subdomain. We check the subdomain <a href="config.md#0x0_config">config</a> <b>to</b> see <b>if</b> we are allowed <b>to</b> mint <a href="subdomains.md#0x0_subdomains">subdomains</a>.
    // For regular names (e.g. example.<a href="dependencies/sui-framework/sui.md#0x2_sui">sui</a>), we can always mint <a href="subdomains.md#0x0_subdomains">subdomains</a>.
    // <b>if</b> there's no <a href="config.md#0x0_config">config</a> for this parent, and the parent is a subdomain, we can't create deeper names.
     <b>assert</b>!(<a href="subdomains.md#0x0_subdomains_is_creation_allowed">is_creation_allowed</a>(&<a href="subdomains.md#0x0_subdomains_record_metadata">record_metadata</a>(self, parent)), <a href="subdomains.md#0x0_subdomains_ECreationDisabledForSubDomain">ECreationDisabledForSubDomain</a>);
}
</code></pre>



</details>

<a name="0x0_subdomains_internal_create_subdomain"></a>

## Function `internal_create_subdomain`

An internal function to add a subdomain to the registry with the correct expiration timestamp.
It doesn't check whether the expiration is valid. This needs to be checked on the calling function.


<pre><code><b>fun</b> <a href="subdomains.md#0x0_subdomains_internal_create_subdomain">internal_create_subdomain</a>(<a href="dependencies/suins/registry.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_registry">registry</a>: &<b>mut</b> <a href="dependencies/suins/registry.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_registry_Registry">registry::Registry</a>, subdomain: <a href="dependencies/suins/domain.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_domain_Domain">domain::Domain</a>, expiration_timestamp_ms: u64, parent_nft_id: <a href="dependencies/sui-framework/object.md#0x2_object_ID">object::ID</a>, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &<a href="dependencies/sui-framework/clock.md#0x2_clock_Clock">clock::Clock</a>, ctx: &<b>mut</b> <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context_TxContext">tx_context::TxContext</a>): <a href="dependencies/suins/subdomain_registration.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_subdomain_registration_SubDomainRegistration">subdomain_registration::SubDomainRegistration</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="subdomains.md#0x0_subdomains_internal_create_subdomain">internal_create_subdomain</a>(
    <a href="dependencies/suins/registry.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_registry">registry</a>: &<b>mut</b> Registry,
    subdomain: Domain,
    expiration_timestamp_ms: u64,
    parent_nft_id: ID,
    <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &Clock,
    ctx: &<b>mut</b> TxContext,
): SubDomainRegistration {
    <b>let</b> <b>mut</b> nft = <a href="dependencies/suins/registry.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_registry">registry</a>.add_record_ignoring_grace_period(subdomain, 1, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>, ctx);
    // set the timestamp <b>to</b> the correct one. `add_record` only works <b>with</b> years but we can correct it easily here.
    <a href="dependencies/suins/registry.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_registry">registry</a>.set_expiration_timestamp_ms(&<b>mut</b> nft, subdomain, expiration_timestamp_ms);

    // attach the `ParentID` <b>to</b> the SuinsRegistration, so we validate that the parent who created this subdomain
    // is the same <b>as</b> the one currently holding the parent <a href="dependencies/suins/domain.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_domain">domain</a>.
    df::add(nft.uid_mut(), <a href="subdomains.md#0x0_subdomains_ParentKey">ParentKey</a> {}, parent_nft_id);

    <a href="dependencies/suins/registry.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_registry">registry</a>.wrap_subdomain(nft, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>, ctx)
}
</code></pre>



</details>

<a name="0x0_subdomains_registry"></a>

## Function `registry`



<pre><code><b>fun</b> <a href="dependencies/suins/registry.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_registry">registry</a>(<a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>: &<a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins_SuiNS">suins::SuiNS</a>): &<a href="dependencies/suins/registry.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_registry_Registry">registry::Registry</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="dependencies/suins/registry.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_registry">registry</a>(<a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>: &SuiNS): &Registry {
    <a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>.<a href="dependencies/suins/registry.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_registry">registry</a>&lt;Registry&gt;()
}
</code></pre>



</details>

<a name="0x0_subdomains_registry_mut"></a>

## Function `registry_mut`



<pre><code><b>fun</b> <a href="subdomains.md#0x0_subdomains_registry_mut">registry_mut</a>(<a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>: &<b>mut</b> <a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins_SuiNS">suins::SuiNS</a>): &<b>mut</b> <a href="dependencies/suins/registry.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_registry_Registry">registry::Registry</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="subdomains.md#0x0_subdomains_registry_mut">registry_mut</a>(<a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>: &<b>mut</b> SuiNS): &<b>mut</b> Registry {
    <a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins_app_registry_mut">suins::app_registry_mut</a>&lt;<a href="subdomains.md#0x0_subdomains_SubDomains">SubDomains</a>, Registry&gt;(<a href="subdomains.md#0x0_subdomains_SubDomains">SubDomains</a> {}, <a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>)
}
</code></pre>



</details>

<a name="0x0_subdomains_app_config"></a>

## Function `app_config`



<pre><code><b>fun</b> <a href="subdomains.md#0x0_subdomains_app_config">app_config</a>(<a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>: &<a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins_SuiNS">suins::SuiNS</a>): &<a href="subdomains.md#0x0_subdomains_App">subdomains::App</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="subdomains.md#0x0_subdomains_app_config">app_config</a>(<a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>: &SuiNS): &<a href="subdomains.md#0x0_subdomains_App">App</a> {
    <a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>.<a href="dependencies/suins/registry.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_registry">registry</a>&lt;<a href="subdomains.md#0x0_subdomains_App">App</a>&gt;()
}
</code></pre>



</details>
