
<a name="0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry"></a>

# Module `0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b::registry`



-  [Struct `Registry`](#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_Registry)
-  [Constants](#@Constants_0)
-  [Function `new`](#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_new)
-  [Function `add_record_ignoring_grace_period`](#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_add_record_ignoring_grace_period)
-  [Function `add_record`](#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_add_record)
-  [Function `burn_registration_object`](#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_burn_registration_object)
-  [Function `wrap_subdomain`](#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_wrap_subdomain)
-  [Function `burn_subdomain_object`](#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_burn_subdomain_object)
-  [Function `add_leaf_record`](#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_add_leaf_record)
-  [Function `remove_leaf_record`](#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_remove_leaf_record)
-  [Function `set_target_address`](#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_set_target_address)
-  [Function `unset_reverse_lookup`](#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_unset_reverse_lookup)
-  [Function `set_reverse_lookup`](#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_set_reverse_lookup)
-  [Function `set_expiration_timestamp_ms`](#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_set_expiration_timestamp_ms)
-  [Function `set_data`](#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_set_data)
-  [Function `has_record`](#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_has_record)
-  [Function `lookup`](#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_lookup)
-  [Function `reverse_lookup`](#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_reverse_lookup)
-  [Function `assert_nft_is_authorized`](#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_assert_nft_is_authorized)
-  [Function `get_data`](#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_get_data)
-  [Function `is_leaf_record`](#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_is_leaf_record)
-  [Function `internal_add_record`](#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_internal_add_record)
-  [Function `remove_existing_record_if_exists_and_expired`](#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_remove_existing_record_if_exists_and_expired)
-  [Function `handle_invalidate_reverse_record`](#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_handle_invalidate_reverse_record)


<pre><code><b>use</b> <a href="dependencies/move-stdlib/option.md#0x1_option">0x1::option</a>;
<b>use</b> <a href="dependencies/move-stdlib/string.md#0x1_string">0x1::string</a>;
<b>use</b> <a href="dependencies/sui-framework/clock.md#0x2_clock">0x2::clock</a>;
<b>use</b> <a href="dependencies/sui-framework/object.md#0x2_object">0x2::object</a>;
<b>use</b> <a href="dependencies/sui-framework/table.md#0x2_table">0x2::table</a>;
<b>use</b> <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context">0x2::tx_context</a>;
<b>use</b> <a href="dependencies/sui-framework/vec_map.md#0x2_vec_map">0x2::vec_map</a>;
<b>use</b> <a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b::domain</a>;
<b>use</b> <a href="name_record.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_name_record">0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b::name_record</a>;
<b>use</b> <a href="subdomain_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_subdomain_registration">0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b::subdomain_registration</a>;
<b>use</b> <a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b::suins</a>;
<b>use</b> <a href="suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration">0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b::suins_registration</a>;
</code></pre>



<a name="0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_Registry"></a>

## Struct `Registry`

The <code><a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_Registry">Registry</a></code> object. Attached as a dynamic field to the <code>SuiNS</code> object,
and the <code><a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a></code> module controls the access to the <code><a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_Registry">Registry</a></code>.

Contains two tables necessary for the lookup.


<pre><code><b>struct</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_Registry">Registry</a> <b>has</b> store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code><a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry">registry</a>: <a href="dependencies/sui-framework/table.md#0x2_table_Table">table::Table</a>&lt;<a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain_Domain">domain::Domain</a>, <a href="name_record.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_name_record_NameRecord">name_record::NameRecord</a>&gt;</code>
</dt>
<dd>
 The <code><a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry">registry</a></code> table maps <code>Domain</code> to <code>NameRecord</code>.
 Added / replaced in the <code>add_record</code> function.
</dd>
<dt>
<code>reverse_registry: <a href="dependencies/sui-framework/table.md#0x2_table_Table">table::Table</a>&lt;<b>address</b>, <a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain_Domain">domain::Domain</a>&gt;</code>
</dt>
<dd>
 The <code>reverse_registry</code> table maps <code><b>address</b></code> to <code>domain_name</code>.
 Updated in the <code>set_reverse_lookup</code> function.
</dd>
</dl>


</details>

<a name="@Constants_0"></a>

## Constants


<a name="0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_EIdMismatch"></a>

The <code>SuinsRegistration</code> does not match the <code>NameRecord</code>.


<pre><code><b>const</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_EIdMismatch">EIdMismatch</a>: u64 = 2;
</code></pre>



<a name="0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_EInvalidDepth"></a>

Trying to add a leaf record for a TLD or SLD.


<pre><code><b>const</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_EInvalidDepth">EInvalidDepth</a>: u64 = 7;
</code></pre>



<a name="0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_ENftExpired"></a>

The <code>SuinsRegistration</code> has expired.


<pre><code><b>const</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_ENftExpired">ENftExpired</a>: u64 = 0;
</code></pre>



<a name="0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_ENotLeafRecord"></a>

Trying to remove or operate on a non-leaf record as if it were a leaf record.


<pre><code><b>const</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_ENotLeafRecord">ENotLeafRecord</a>: u64 = 6;
</code></pre>



<a name="0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_ERecordExpired"></a>

The <code>NameRecord</code> has expired.


<pre><code><b>const</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_ERecordExpired">ERecordExpired</a>: u64 = 3;
</code></pre>



<a name="0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_ERecordMismatch"></a>

The reverse lookup record does not match the <code>NameRecord</code>.


<pre><code><b>const</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_ERecordMismatch">ERecordMismatch</a>: u64 = 4;
</code></pre>



<a name="0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_ERecordNotExpired"></a>

Trying to override a record that is not expired.


<pre><code><b>const</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_ERecordNotExpired">ERecordNotExpired</a>: u64 = 1;
</code></pre>



<a name="0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_ERecordNotFound"></a>

Trying to lookup a record that doesn't exist.


<pre><code><b>const</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_ERecordNotFound">ERecordNotFound</a>: u64 = 8;
</code></pre>



<a name="0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_ETargetNotSet"></a>

Trying to add a reverse lookup record while the target is empty.


<pre><code><b>const</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_ETargetNotSet">ETargetNotSet</a>: u64 = 5;
</code></pre>



<a name="0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_new"></a>

## Function `new`



<pre><code><b>public</b> <b>fun</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_new">new</a>(_: &<a href="suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_AdminCap">suins::AdminCap</a>, ctx: &<b>mut</b> <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context_TxContext">tx_context::TxContext</a>): <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_Registry">registry::Registry</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_new">new</a>(_: &AdminCap, ctx: &<b>mut</b> TxContext): <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_Registry">Registry</a> {
    <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_Registry">Registry</a> {
        <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry">registry</a>: <a href="dependencies/sui-framework/table.md#0x2_table_new">table::new</a>(ctx),
        reverse_registry: <a href="dependencies/sui-framework/table.md#0x2_table_new">table::new</a>(ctx),
    }
}
</code></pre>



</details>

<a name="0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_add_record_ignoring_grace_period"></a>

## Function `add_record_ignoring_grace_period`

Attemps to add a new record to the registry without looking at the grace period.
Currently used for subdomains where there's no grace period to respect.
Returns a <code>SuinsRegistration</code> upon success.


<pre><code><b>public</b> <b>fun</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_add_record_ignoring_grace_period">add_record_ignoring_grace_period</a>(self: &<b>mut</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_Registry">registry::Registry</a>, <a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>: <a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain_Domain">domain::Domain</a>, no_years: u8, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &<a href="dependencies/sui-framework/clock.md#0x2_clock_Clock">clock::Clock</a>, ctx: &<b>mut</b> <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context_TxContext">tx_context::TxContext</a>): <a href="suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_SuinsRegistration">suins_registration::SuinsRegistration</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_add_record_ignoring_grace_period">add_record_ignoring_grace_period</a>(
    self: &<b>mut</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_Registry">Registry</a>,
    <a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>: Domain,
    no_years: u8,
    <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &Clock,
    ctx: &<b>mut</b> TxContext,
): SuinsRegistration {
    self.<a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_internal_add_record">internal_add_record</a>(<a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>, no_years, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>, <b>false</b>, ctx)
}
</code></pre>



</details>

<a name="0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_add_record"></a>

## Function `add_record`

Attempts to add a new record to the registry and returns a
<code>SuinsRegistration</code> upon success.
Only use with second-level names. Enforces a <code>grace_period</code> by default.
Not suitable for subdomains (unless a grace period is needed).


<pre><code><b>public</b> <b>fun</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_add_record">add_record</a>(self: &<b>mut</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_Registry">registry::Registry</a>, <a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>: <a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain_Domain">domain::Domain</a>, no_years: u8, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &<a href="dependencies/sui-framework/clock.md#0x2_clock_Clock">clock::Clock</a>, ctx: &<b>mut</b> <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context_TxContext">tx_context::TxContext</a>): <a href="suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_SuinsRegistration">suins_registration::SuinsRegistration</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_add_record">add_record</a>(
    self: &<b>mut</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_Registry">Registry</a>,
    <a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>: Domain,
    no_years: u8,
    <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &Clock,
    ctx: &<b>mut</b> TxContext,
): SuinsRegistration {
    self.<a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_internal_add_record">internal_add_record</a>(<a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>, no_years, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>, <b>true</b>, ctx)
}
</code></pre>



</details>

<a name="0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_burn_registration_object"></a>

## Function `burn_registration_object`

Attempts to burn an NFT and get storage rebates.
Only works if the NFT has expired.


<pre><code><b>public</b> <b>fun</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_burn_registration_object">burn_registration_object</a>(self: &<b>mut</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_Registry">registry::Registry</a>, nft: <a href="suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_SuinsRegistration">suins_registration::SuinsRegistration</a>, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &<a href="dependencies/sui-framework/clock.md#0x2_clock_Clock">clock::Clock</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_burn_registration_object">burn_registration_object</a>(
    self: &<b>mut</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_Registry">Registry</a>,
    nft: SuinsRegistration,
    <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &Clock
) {
    // First we make sure that the SuinsRegistration <a href="dependencies/sui-framework/object.md#0x2_object">object</a> <b>has</b> expired.
    <b>assert</b>!(nft.has_expired(<a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>), <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_ERecordNotExpired">ERecordNotExpired</a>);

    <b>let</b> <a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a> = nft.<a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>();

    // Then, <b>if</b> the <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry">registry</a> still <b>has</b> a record for this <a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a> and the NFT ID matches, we remove it.
    <b>if</b> (self.<a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry">registry</a>.contains(<a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>)) {
        <b>let</b> record = &self.<a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry">registry</a>[<a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>];

        // We wanna remove the record only <b>if</b> the NFT ID matches.
        <b>if</b> (record.nft_id() == <a href="dependencies/sui-framework/object.md#0x2_object_id">object::id</a>(&nft)) {
            <b>let</b> record = self.<a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry">registry</a>.remove(<a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>);
            self.<a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_handle_invalidate_reverse_record">handle_invalidate_reverse_record</a>(&<a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>, record.target_address(), none());
        }
    };
    // burn the NFT.
    nft.burn();
}
</code></pre>



</details>

<a name="0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_wrap_subdomain"></a>

## Function `wrap_subdomain`

Allow creation of subdomain wrappers only to authorized modules.


<pre><code><b>public</b> <b>fun</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_wrap_subdomain">wrap_subdomain</a>(_: &<b>mut</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_Registry">registry::Registry</a>, nft: <a href="suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_SuinsRegistration">suins_registration::SuinsRegistration</a>, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &<a href="dependencies/sui-framework/clock.md#0x2_clock_Clock">clock::Clock</a>, ctx: &<b>mut</b> <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context_TxContext">tx_context::TxContext</a>): <a href="subdomain_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_subdomain_registration_SubDomainRegistration">subdomain_registration::SubDomainRegistration</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_wrap_subdomain">wrap_subdomain</a>(
    _: &<b>mut</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_Registry">Registry</a>,
    nft: SuinsRegistration,
    <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &Clock,
    ctx: &<b>mut</b> TxContext
): SubDomainRegistration {
    <a href="subdomain_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_subdomain_registration_new">subdomain_registration::new</a>(nft, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>, ctx)
}
</code></pre>



</details>

<a name="0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_burn_subdomain_object"></a>

## Function `burn_subdomain_object`

Attempts to burn a subdomain registration object,
and also invalidates any records in the registry / reverse registry.


<pre><code><b>public</b> <b>fun</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_burn_subdomain_object">burn_subdomain_object</a>(self: &<b>mut</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_Registry">registry::Registry</a>, nft: <a href="subdomain_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_subdomain_registration_SubDomainRegistration">subdomain_registration::SubDomainRegistration</a>, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &<a href="dependencies/sui-framework/clock.md#0x2_clock_Clock">clock::Clock</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_burn_subdomain_object">burn_subdomain_object</a>(
    self: &<b>mut</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_Registry">Registry</a>,
    nft: SubDomainRegistration,
    <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &Clock
) {
    <b>let</b> nft = nft.burn(<a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>);
    self.<a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_burn_registration_object">burn_registration_object</a>(nft, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>);
}
</code></pre>



</details>

<a name="0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_add_leaf_record"></a>

## Function `add_leaf_record`

Adds a <code>leaf</code> record to the registry.
A <code>leaf</code> record is a record that is a subdomain and doesn't have
an equivalent <code>SuinsRegistration</code> object.

Instead, the parent's <code>SuinsRegistration</code> object is used to manage target_address & remove it / determine expiration.

1. Leaf records can't have children. They only work as a resolving mechanism.
2. Leaf records must always have a <code>target</code> address (can't point to <code>none</code>).
3. Leaf records do not expire. Their expiration date is actually what defines their type.

Leaf record's expiration is defined by the parent's expiration. Since the parent can only be a <code>node</code>,
we need to check that the parent's NFT_ID is valid & hasn't expired.


<pre><code><b>public</b> <b>fun</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_add_leaf_record">add_leaf_record</a>(self: &<b>mut</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_Registry">registry::Registry</a>, <a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>: <a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain_Domain">domain::Domain</a>, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &<a href="dependencies/sui-framework/clock.md#0x2_clock_Clock">clock::Clock</a>, target: <b>address</b>, _ctx: &<b>mut</b> <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_add_leaf_record">add_leaf_record</a>(
    self: &<b>mut</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_Registry">Registry</a>,
    <a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>: Domain,
    <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &Clock,
    target: <b>address</b>,
    _ctx: &<b>mut</b> TxContext
) {
    <b>assert</b>!(<a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>.is_subdomain(), <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_EInvalidDepth">EInvalidDepth</a>);

    // get the parent of the <a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>
    <b>let</b> parent = <a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>.parent();
    <b>let</b> option_parent_name_record = self.<a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_lookup">lookup</a>(parent);

    <b>assert</b>!(option_parent_name_record.is_some(), <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_ERecordNotFound">ERecordNotFound</a>);

    // finds existing parent record
    <b>let</b> parent_name_record = option_parent_name_record.borrow();

    // Make sure that the parent isn't expired (because leaf record is invalid in that case).
    // Ignores grace period is it's only there so you don't accidently forget <b>to</b> renew your name.
    <b>assert</b>!(!parent_name_record.has_expired(<a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>), <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_ERecordExpired">ERecordExpired</a>);

    // Removes an existing record <b>if</b> it exists and is expired.
    self.<a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_remove_existing_record_if_exists_and_expired">remove_existing_record_if_exists_and_expired</a>(<a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>, <b>false</b>);

    // adds the `leaf` record <b>to</b> the <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry">registry</a>.
    self.<a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry">registry</a>.add(<a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>, <a href="name_record.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_name_record_new_leaf">name_record::new_leaf</a>(parent_name_record.nft_id(), some(target)));
}
</code></pre>



</details>

<a name="0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_remove_leaf_record"></a>

## Function `remove_leaf_record`

Can be used to remove a leaf record.
Leaf records do not have any symmetrical <code>SuinsRegistration</code> object.
Authorization of who calls this is delegated to the authorized module that calls this.


<pre><code><b>public</b> <b>fun</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_remove_leaf_record">remove_leaf_record</a>(self: &<b>mut</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_Registry">registry::Registry</a>, <a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>: <a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain_Domain">domain::Domain</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_remove_leaf_record">remove_leaf_record</a>(
    self: &<b>mut</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_Registry">Registry</a>,
    <a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>: Domain,
) {
    // We can only call remove on a leaf record.
    <b>assert</b>!(self.<a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_is_leaf_record">is_leaf_record</a>(<a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>), <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_ENotLeafRecord">ENotLeafRecord</a>);

    // <b>if</b> it's a leaf record, there's no `SuinsRegistration` <a href="dependencies/sui-framework/object.md#0x2_object">object</a>.
    // We can just go ahead and remove the <a href="name_record.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_name_record">name_record</a>, and invalidate the reverse record (<b>if</b> any).
    <b>let</b> record = self.<a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry">registry</a>.remove(<a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>);
    <b>let</b> old_target_address = record.target_address();

    self.<a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_handle_invalidate_reverse_record">handle_invalidate_reverse_record</a>(&<a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>, old_target_address, none());
}
</code></pre>



</details>

<a name="0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_set_target_address"></a>

## Function `set_target_address`



<pre><code><b>public</b> <b>fun</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_set_target_address">set_target_address</a>(self: &<b>mut</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_Registry">registry::Registry</a>, <a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>: <a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain_Domain">domain::Domain</a>, new_target: <a href="dependencies/move-stdlib/option.md#0x1_option_Option">option::Option</a>&lt;<b>address</b>&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_set_target_address">set_target_address</a>(
    self: &<b>mut</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_Registry">Registry</a>,
    <a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>: Domain,
    new_target: Option&lt;<b>address</b>&gt;,
) {
    <b>let</b> record = &<b>mut</b> self.<a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry">registry</a>[<a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>];
    <b>let</b> old_target = record.target_address();

    record.<a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_set_target_address">set_target_address</a>(new_target);
    self.<a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_handle_invalidate_reverse_record">handle_invalidate_reverse_record</a>(&<a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>, old_target, new_target);
}
</code></pre>



</details>

<a name="0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_unset_reverse_lookup"></a>

## Function `unset_reverse_lookup`



<pre><code><b>public</b> <b>fun</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_unset_reverse_lookup">unset_reverse_lookup</a>(self: &<b>mut</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_Registry">registry::Registry</a>, <b>address</b>: <b>address</b>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_unset_reverse_lookup">unset_reverse_lookup</a>(self: &<b>mut</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_Registry">Registry</a>, <b>address</b>: <b>address</b>) {
    self.reverse_registry.remove(<b>address</b>);
}
</code></pre>



</details>

<a name="0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_set_reverse_lookup"></a>

## Function `set_reverse_lookup`

Reverse lookup can only be set for the record that has the target address.


<pre><code><b>public</b> <b>fun</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_set_reverse_lookup">set_reverse_lookup</a>(self: &<b>mut</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_Registry">registry::Registry</a>, <b>address</b>: <b>address</b>, <a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>: <a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain_Domain">domain::Domain</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_set_reverse_lookup">set_reverse_lookup</a>(
    self: &<b>mut</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_Registry">Registry</a>,
    <b>address</b>: <b>address</b>,
    <a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>: Domain,
) {
    <b>let</b> record = &self.<a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry">registry</a>[<a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>];
    <b>let</b> target = record.target_address();

    <b>assert</b>!(target.is_some(), <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_ETargetNotSet">ETargetNotSet</a>);
    <b>assert</b>!(some(<b>address</b>) == target, <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_ERecordMismatch">ERecordMismatch</a>);

    <b>if</b> (self.reverse_registry.contains(<b>address</b>)) {
        *self.reverse_registry.borrow_mut(<b>address</b>) = <a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>;
    } <b>else</b> {
        self.reverse_registry.add(<b>address</b>, <a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>);
    };
}
</code></pre>



</details>

<a name="0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_set_expiration_timestamp_ms"></a>

## Function `set_expiration_timestamp_ms`

Update the <code>expiration_timestamp_ms</code> of the given <code>SuinsRegistration</code> and
<code>NameRecord</code>. Requires the <code>SuinsRegistration</code> to make sure that both
timestamps are in sync.


<pre><code><b>public</b> <b>fun</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_set_expiration_timestamp_ms">set_expiration_timestamp_ms</a>(self: &<b>mut</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_Registry">registry::Registry</a>, nft: &<b>mut</b> <a href="suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_SuinsRegistration">suins_registration::SuinsRegistration</a>, <a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>: <a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain_Domain">domain::Domain</a>, expiration_timestamp_ms: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_set_expiration_timestamp_ms">set_expiration_timestamp_ms</a>(
    self: &<b>mut</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_Registry">Registry</a>,
    nft: &<b>mut</b> SuinsRegistration,
    <a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>: Domain,
    expiration_timestamp_ms: u64,
) {
    <b>let</b> record = &<b>mut</b> self.<a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry">registry</a>[<a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>];

    <b>assert</b>!(<a href="dependencies/sui-framework/object.md#0x2_object_id">object::id</a>(nft) == record.nft_id(), <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_EIdMismatch">EIdMismatch</a>);
    record.<a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_set_expiration_timestamp_ms">set_expiration_timestamp_ms</a>(expiration_timestamp_ms);
    nft.<a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_set_expiration_timestamp_ms">set_expiration_timestamp_ms</a>(expiration_timestamp_ms);
}
</code></pre>



</details>

<a name="0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_set_data"></a>

## Function `set_data`

Update the <code>data</code> of the given <code>NameRecord</code> using a <code>SuinsRegistration</code>.
Use with caution and validate(!!) that any system fields are not removed (accidently),
when building authorized packages that can write the metadata field.


<pre><code><b>public</b> <b>fun</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_set_data">set_data</a>(self: &<b>mut</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_Registry">registry::Registry</a>, <a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>: <a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain_Domain">domain::Domain</a>, data: <a href="dependencies/sui-framework/vec_map.md#0x2_vec_map_VecMap">vec_map::VecMap</a>&lt;<a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>, <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_set_data">set_data</a>(
    self: &<b>mut</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_Registry">Registry</a>,
    <a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>: Domain,
    data: VecMap&lt;String, String&gt;
) {
    <b>let</b> record = &<b>mut</b> self.<a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry">registry</a>[<a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>];
    record.<a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_set_data">set_data</a>(data);
}
</code></pre>



</details>

<a name="0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_has_record"></a>

## Function `has_record`

Check whether the given <code><a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a></code> is registered in the <code><a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_Registry">Registry</a></code>.


<pre><code><b>public</b> <b>fun</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_has_record">has_record</a>(self: &<a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_Registry">registry::Registry</a>, <a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>: <a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain_Domain">domain::Domain</a>): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_has_record">has_record</a>(self: &<a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_Registry">Registry</a>, <a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>: Domain): bool {
    self.<a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry">registry</a>.contains(<a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>)
}
</code></pre>



</details>

<a name="0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_lookup"></a>

## Function `lookup`

Returns the <code>NameRecord</code> associated with the given domain or None.


<pre><code><b>public</b> <b>fun</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_lookup">lookup</a>(self: &<a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_Registry">registry::Registry</a>, <a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>: <a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain_Domain">domain::Domain</a>): <a href="dependencies/move-stdlib/option.md#0x1_option_Option">option::Option</a>&lt;<a href="name_record.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_name_record_NameRecord">name_record::NameRecord</a>&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_lookup">lookup</a>(self: &<a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_Registry">Registry</a>, <a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>: Domain): Option&lt;NameRecord&gt; {
    <b>if</b> (self.<a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry">registry</a>.contains(<a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>)) {
        <b>let</b> record = &self.<a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry">registry</a>[<a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>];
        some(*record)
    } <b>else</b> {
        none()
    }
}
</code></pre>



</details>

<a name="0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_reverse_lookup"></a>

## Function `reverse_lookup`

Returns the <code>domain_name</code> associated with the given address or None.


<pre><code><b>public</b> <b>fun</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_reverse_lookup">reverse_lookup</a>(self: &<a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_Registry">registry::Registry</a>, <b>address</b>: <b>address</b>): <a href="dependencies/move-stdlib/option.md#0x1_option_Option">option::Option</a>&lt;<a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain_Domain">domain::Domain</a>&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_reverse_lookup">reverse_lookup</a>(self: &<a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_Registry">Registry</a>, <b>address</b>: <b>address</b>): Option&lt;Domain&gt; {
    <b>if</b> (self.reverse_registry.contains(<b>address</b>)) {
        some(self.reverse_registry[<b>address</b>])
    } <b>else</b> {
        none()
    }
}
</code></pre>



</details>

<a name="0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_assert_nft_is_authorized"></a>

## Function `assert_nft_is_authorized`

Asserts that the provided NFT:
1. Matches the ID in the corresponding <code>Record</code>
2. Has not expired (does not take into account the grace period)


<pre><code><b>public</b> <b>fun</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_assert_nft_is_authorized">assert_nft_is_authorized</a>(self: &<a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_Registry">registry::Registry</a>, nft: &<a href="suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_SuinsRegistration">suins_registration::SuinsRegistration</a>, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &<a href="dependencies/sui-framework/clock.md#0x2_clock_Clock">clock::Clock</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_assert_nft_is_authorized">assert_nft_is_authorized</a>(self: &<a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_Registry">Registry</a>, nft: &SuinsRegistration, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &Clock) {
    <b>let</b> <a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a> = nft.<a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>();
    <b>let</b> record = &self.<a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry">registry</a>[<a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>];

    // The NFT does not
    <b>assert</b>!(<a href="dependencies/sui-framework/object.md#0x2_object_id">object::id</a>(nft) == record.nft_id(), <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_EIdMismatch">EIdMismatch</a>);
    <b>assert</b>!(!record.has_expired(<a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>), <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_ERecordExpired">ERecordExpired</a>);
    <b>assert</b>!(!nft.has_expired(<a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>), <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_ENftExpired">ENftExpired</a>);
}
</code></pre>



</details>

<a name="0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_get_data"></a>

## Function `get_data`

Returns the <code>data</code> associated with the given <code>Domain</code>.


<pre><code><b>public</b> <b>fun</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_get_data">get_data</a>(self: &<a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_Registry">registry::Registry</a>, <a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>: <a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain_Domain">domain::Domain</a>): &<a href="dependencies/sui-framework/vec_map.md#0x2_vec_map_VecMap">vec_map::VecMap</a>&lt;<a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>, <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_get_data">get_data</a>(self: &<a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_Registry">Registry</a>, <a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>: Domain): &VecMap&lt;String, String&gt; {
    <b>let</b> record = &self.<a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry">registry</a>[<a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>];
    record.data()
}
</code></pre>



</details>

<a name="0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_is_leaf_record"></a>

## Function `is_leaf_record`

Checks whether a subdomain record is <code>leaf</code>.
<code>leaf</code> record: a record whose target address can only be set by the parent,
hence the nft_id points to the parent's ID. Leaf records can't create subdomains
and don't have their own <code>SuinsRegistration</code> object Cap. The <code>SuinsRegistration</code> of the parent
is the one that manages them.



<pre><code><b>fun</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_is_leaf_record">is_leaf_record</a>(self: &<a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_Registry">registry::Registry</a>, <a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>: <a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain_Domain">domain::Domain</a>): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_is_leaf_record">is_leaf_record</a>(
    self: &<a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_Registry">Registry</a>,
    <a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>: Domain
): bool {
    <b>if</b> (!<a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>.is_subdomain()) {
        <b>return</b> <b>false</b>
    };

    <b>let</b> option_name_record = self.<a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_lookup">lookup</a>(<a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>);

    <b>if</b> (option_name_record.is_none()) {
        <b>return</b> <b>false</b>
    };

    option_name_record.borrow().<a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_is_leaf_record">is_leaf_record</a>()
}
</code></pre>



</details>

<a name="0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_internal_add_record"></a>

## Function `internal_add_record`

An internal helper to add a record


<pre><code><b>fun</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_internal_add_record">internal_add_record</a>(self: &<b>mut</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_Registry">registry::Registry</a>, <a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>: <a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain_Domain">domain::Domain</a>, no_years: u8, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &<a href="dependencies/sui-framework/clock.md#0x2_clock_Clock">clock::Clock</a>, with_grace_period: bool, ctx: &<b>mut</b> <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context_TxContext">tx_context::TxContext</a>): <a href="suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_SuinsRegistration">suins_registration::SuinsRegistration</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_internal_add_record">internal_add_record</a>(
    self: &<b>mut</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_Registry">Registry</a>,
    <a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>: Domain,
    no_years: u8,
    <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &Clock,
    with_grace_period: bool,
    ctx: &<b>mut</b> TxContext,
): SuinsRegistration {
    self.<a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_remove_existing_record_if_exists_and_expired">remove_existing_record_if_exists_and_expired</a>(<a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>, with_grace_period);

    // If we've made it <b>to</b> this point then we know that we are able <b>to</b>
    // register an entry for this <a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>.
    <b>let</b> nft = nft::new(<a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>, no_years, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>, ctx);
    <b>let</b> <a href="name_record.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_name_record">name_record</a> = <a href="name_record.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_name_record_new">name_record::new</a>(<a href="dependencies/sui-framework/object.md#0x2_object_id">object::id</a>(&nft), nft.expiration_timestamp_ms());
    self.<a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry">registry</a>.add(<a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>, <a href="name_record.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_name_record">name_record</a>);
    nft
}
</code></pre>



</details>

<a name="0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_remove_existing_record_if_exists_and_expired"></a>

## Function `remove_existing_record_if_exists_and_expired`



<pre><code><b>fun</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_remove_existing_record_if_exists_and_expired">remove_existing_record_if_exists_and_expired</a>(self: &<b>mut</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_Registry">registry::Registry</a>, <a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>: <a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain_Domain">domain::Domain</a>, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &<a href="dependencies/sui-framework/clock.md#0x2_clock_Clock">clock::Clock</a>, with_grace_period: bool)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_remove_existing_record_if_exists_and_expired">remove_existing_record_if_exists_and_expired</a>(
    self: &<b>mut</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_Registry">Registry</a>,
    <a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>: Domain,
    <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &Clock,
    with_grace_period: bool,
) {
    // <b>if</b> the <a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a> is not part of the <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry">registry</a>, we can override.
    <b>if</b> (!self.<a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry">registry</a>.contains(<a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>)) <b>return</b>;

    // Remove the record and <b>assert</b> that it <b>has</b> expired (past the grace period <b>if</b> applicable)
    <b>let</b> record = self.<a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry">registry</a>.remove(<a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>);

    // Special case for leaf records, we can override them iff their parent <b>has</b> changed or <b>has</b> expired.
    <b>if</b> (record.<a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_is_leaf_record">is_leaf_record</a>()) {
        // find the parent of the leaf record.
        <b>let</b> option_parent_name_record = self.<a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_lookup">lookup</a>(<a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>.parent());

        // <b>if</b> there's a parent (<b>if</b> not, we can just remove it), we need <b>to</b> check <b>if</b> the parent is valid.
        // -&gt; If the parent is valid, we need <b>to</b> check <b>if</b> the parent is expired.
        // -&gt; If the parent is not valid (nft_id <b>has</b> changed), or <b>if</b> the parent doesn't exist anymore (owner burned it), we can override the leaf record.
        <b>if</b> (option_parent_name_record.is_some()) {
            <b>let</b> parent_name_record = option_parent_name_record.borrow();

            // If the parent is the same and hasn't expired, we can't override the leaf record like this.
            // We need <b>to</b> first remove + then call create (<b>to</b> protect accidental overrides).
            <b>if</b> (parent_name_record.nft_id() == record.nft_id()) {
                <b>assert</b>!(parent_name_record.has_expired(<a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>), <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_ERecordNotExpired">ERecordNotExpired</a>);
            };
        }
    }<b>else</b> <b>if</b> (with_grace_period) {
        <b>assert</b>!(record.has_expired_past_grace_period(<a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>), <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_ERecordNotExpired">ERecordNotExpired</a>);
    } <b>else</b> {
        <b>assert</b>!(record.has_expired(<a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>), <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_ERecordNotExpired">ERecordNotExpired</a>);
    };

    <b>let</b> old_target_address = record.target_address();
    self.<a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_handle_invalidate_reverse_record">handle_invalidate_reverse_record</a>(&<a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>, old_target_address, none());
}
</code></pre>



</details>

<a name="0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_handle_invalidate_reverse_record"></a>

## Function `handle_invalidate_reverse_record`



<pre><code><b>fun</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_handle_invalidate_reverse_record">handle_invalidate_reverse_record</a>(self: &<b>mut</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_Registry">registry::Registry</a>, <a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>: &<a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain_Domain">domain::Domain</a>, old_target_address: <a href="dependencies/move-stdlib/option.md#0x1_option_Option">option::Option</a>&lt;<b>address</b>&gt;, new_target_address: <a href="dependencies/move-stdlib/option.md#0x1_option_Option">option::Option</a>&lt;<b>address</b>&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_handle_invalidate_reverse_record">handle_invalidate_reverse_record</a>(
    self: &<b>mut</b> <a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry_Registry">Registry</a>,
    <a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>: &Domain,
    old_target_address: Option&lt;<b>address</b>&gt;,
    new_target_address: Option&lt;<b>address</b>&gt;,
) {
    <b>if</b> (old_target_address == new_target_address) {
        <b>return</b>
    };

    <b>if</b> (old_target_address.is_none()) {
        <b>return</b>
    };

    <b>let</b> old_target_address = old_target_address.destroy_some();
    <b>let</b> reverse_registry = &<b>mut</b> self.reverse_registry;

    <b>if</b> (reverse_registry.contains(old_target_address)) {
        <b>let</b> default_domain = &reverse_registry[old_target_address];
        <b>if</b> (default_domain == <a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>) {
            reverse_registry.remove(old_target_address);
        }
    };
}
</code></pre>



</details>
