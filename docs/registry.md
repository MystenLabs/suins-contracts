
<a name="0x0_registry"></a>

# Module `0x0::registry`



-  [Struct `Registry`](#0x0_registry_Registry)
-  [Constants](#@Constants_0)
-  [Function `new`](#0x0_registry_new)
-  [Function `add_record`](#0x0_registry_add_record)
-  [Function `set_target_address`](#0x0_registry_set_target_address)
-  [Function `unset_reverse_lookup`](#0x0_registry_unset_reverse_lookup)
-  [Function `set_reverse_lookup`](#0x0_registry_set_reverse_lookup)
-  [Function `set_expiration_timestamp_ms`](#0x0_registry_set_expiration_timestamp_ms)
-  [Function `set_data`](#0x0_registry_set_data)
-  [Function `has_record`](#0x0_registry_has_record)
-  [Function `lookup`](#0x0_registry_lookup)
-  [Function `reverse_lookup`](#0x0_registry_reverse_lookup)
-  [Function `assert_nft_is_authorized`](#0x0_registry_assert_nft_is_authorized)
-  [Function `get_data`](#0x0_registry_get_data)
-  [Function `handle_invalidate_reverse_record`](#0x0_registry_handle_invalidate_reverse_record)


<pre><code><b>use</b> <a href="domain.md#0x0_domain">0x0::domain</a>;
<b>use</b> <a href="name_record.md#0x0_name_record">0x0::name_record</a>;
<b>use</b> <a href="registration_nft.md#0x0_registration_nft">0x0::registration_nft</a>;
<b>use</b> <a href="suins.md#0x0_suins">0x0::suins</a>;
<b>use</b> <a href="">0x1::option</a>;
<b>use</b> <a href="">0x1::string</a>;
<b>use</b> <a href="">0x2::clock</a>;
<b>use</b> <a href="">0x2::object</a>;
<b>use</b> <a href="">0x2::table</a>;
<b>use</b> <a href="">0x2::tx_context</a>;
<b>use</b> <a href="">0x2::vec_map</a>;
</code></pre>



<a name="0x0_registry_Registry"></a>

## Struct `Registry`

The <code><a href="registry.md#0x0_registry_Registry">Registry</a></code> object. Attached as a dynamic field to the <code>SuiNS</code> object,
and the <code><a href="suins.md#0x0_suins">suins</a></code> module controls the access to the <code><a href="registry.md#0x0_registry_Registry">Registry</a></code>.

Contains two tables necessary for the lookup.


<pre><code><b>struct</b> <a href="registry.md#0x0_registry_Registry">Registry</a> <b>has</b> store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code><a href="registry.md#0x0_registry">registry</a>: <a href="_Table">table::Table</a>&lt;<a href="domain.md#0x0_domain_Domain">domain::Domain</a>, <a href="name_record.md#0x0_name_record_NameRecord">name_record::NameRecord</a>&gt;</code>
</dt>
<dd>
 The <code><a href="registry.md#0x0_registry">registry</a></code> table maps <code>Domain</code> to <code>NameRecord</code>.
 Added / replaced in the <code>add_record</code> function.
</dd>
<dt>
<code>reverse_registry: <a href="_Table">table::Table</a>&lt;<b>address</b>, <a href="domain.md#0x0_domain_Domain">domain::Domain</a>&gt;</code>
</dt>
<dd>
 The <code>reverse_registry</code> table maps <code><b>address</b></code> to <code>domain_name</code>.
 Updated in the <code>set_reverse_lookup</code> function.
</dd>
</dl>


</details>

<a name="@Constants_0"></a>

## Constants


<a name="0x0_registry_EIdMismatch"></a>

The <code>RegistrationNFT</code> does not match the <code>NameRecord</code>.


<pre><code><b>const</b> <a href="registry.md#0x0_registry_EIdMismatch">EIdMismatch</a>: u64 = 2;
</code></pre>



<a name="0x0_registry_ENftExpired"></a>

The <code>RegistrationNFT</code> has expired.


<pre><code><b>const</b> <a href="registry.md#0x0_registry_ENftExpired">ENftExpired</a>: u64 = 0;
</code></pre>



<a name="0x0_registry_ERecordExpired"></a>

The <code>NameRecord</code> has expired.


<pre><code><b>const</b> <a href="registry.md#0x0_registry_ERecordExpired">ERecordExpired</a>: u64 = 3;
</code></pre>



<a name="0x0_registry_ERecordMismatch"></a>

The reverse lookup record does not match the <code>NameRecord</code>.


<pre><code><b>const</b> <a href="registry.md#0x0_registry_ERecordMismatch">ERecordMismatch</a>: u64 = 4;
</code></pre>



<a name="0x0_registry_ERecordNotExpired"></a>

Trying to override a record that is not expired.


<pre><code><b>const</b> <a href="registry.md#0x0_registry_ERecordNotExpired">ERecordNotExpired</a>: u64 = 1;
</code></pre>



<a name="0x0_registry_ETargetNotSet"></a>

Trying to add a reverse lookup record while the target is empty.


<pre><code><b>const</b> <a href="registry.md#0x0_registry_ETargetNotSet">ETargetNotSet</a>: u64 = 5;
</code></pre>



<a name="0x0_registry_new"></a>

## Function `new`



<pre><code><b>public</b> <b>fun</b> <a href="registry.md#0x0_registry_new">new</a>(_: &<a href="suins.md#0x0_suins_AdminCap">suins::AdminCap</a>, ctx: &<b>mut</b> <a href="_TxContext">tx_context::TxContext</a>): <a href="registry.md#0x0_registry_Registry">registry::Registry</a>
</code></pre>


<a name="0x0_registry_add_record"></a>

## Function `add_record`

Attempts to add a new record to the registry and returns a
<code>RegistrationNFT</code> upon success.


<pre><code><b>public</b> <b>fun</b> <a href="registry.md#0x0_registry_add_record">add_record</a>(self: &<b>mut</b> <a href="registry.md#0x0_registry_Registry">registry::Registry</a>, <a href="domain.md#0x0_domain">domain</a>: <a href="domain.md#0x0_domain_Domain">domain::Domain</a>, no_years: u8, <a href="">clock</a>: &<a href="_Clock">clock::Clock</a>, ctx: &<b>mut</b> <a href="_TxContext">tx_context::TxContext</a>): <a href="registration_nft.md#0x0_registration_nft_RegistrationNFT">registration_nft::RegistrationNFT</a>
</code></pre>


<a name="0x0_registry_set_target_address"></a>

## Function `set_target_address`



<pre><code><b>public</b> <b>fun</b> <a href="registry.md#0x0_registry_set_target_address">set_target_address</a>(self: &<b>mut</b> <a href="registry.md#0x0_registry_Registry">registry::Registry</a>, <a href="domain.md#0x0_domain">domain</a>: <a href="domain.md#0x0_domain_Domain">domain::Domain</a>, new_target: <a href="_Option">option::Option</a>&lt;<b>address</b>&gt;)
</code></pre>


<a name="0x0_registry_unset_reverse_lookup"></a>

## Function `unset_reverse_lookup`



<pre><code><b>public</b> <b>fun</b> <a href="registry.md#0x0_registry_unset_reverse_lookup">unset_reverse_lookup</a>(self: &<b>mut</b> <a href="registry.md#0x0_registry_Registry">registry::Registry</a>, <b>address</b>: <b>address</b>)
</code></pre>


<a name="0x0_registry_set_reverse_lookup"></a>

## Function `set_reverse_lookup`

Reverse lookup can only be set for the record that has the target address.


<pre><code><b>public</b> <b>fun</b> <a href="registry.md#0x0_registry_set_reverse_lookup">set_reverse_lookup</a>(self: &<b>mut</b> <a href="registry.md#0x0_registry_Registry">registry::Registry</a>, <b>address</b>: <b>address</b>, <a href="domain.md#0x0_domain">domain</a>: <a href="domain.md#0x0_domain_Domain">domain::Domain</a>)
</code></pre>


<a name="0x0_registry_set_expiration_timestamp_ms"></a>

## Function `set_expiration_timestamp_ms`

Update the <code>expiration_timestamp_ms</code> of the given <code>RegistrationNFT</code> and
<code>NameRecord</code>. Requires the <code>RegistrationNFT</code> to make sure that both
timestamps are in sync.


<pre><code><b>public</b> <b>fun</b> <a href="registry.md#0x0_registry_set_expiration_timestamp_ms">set_expiration_timestamp_ms</a>(self: &<b>mut</b> <a href="registry.md#0x0_registry_Registry">registry::Registry</a>, nft: &<b>mut</b> <a href="registration_nft.md#0x0_registration_nft_RegistrationNFT">registration_nft::RegistrationNFT</a>, <a href="domain.md#0x0_domain">domain</a>: <a href="domain.md#0x0_domain_Domain">domain::Domain</a>, expiration_timestamp_ms: u64)
</code></pre>


<a name="0x0_registry_set_data"></a>

## Function `set_data`

Update the <code>data</code> of the given <code>NameRecord</code> using a <code>RegistrationNFT</code>.


<pre><code><b>public</b> <b>fun</b> <a href="registry.md#0x0_registry_set_data">set_data</a>(self: &<b>mut</b> <a href="registry.md#0x0_registry_Registry">registry::Registry</a>, <a href="domain.md#0x0_domain">domain</a>: <a href="domain.md#0x0_domain_Domain">domain::Domain</a>, data: <a href="_VecMap">vec_map::VecMap</a>&lt;<a href="_String">string::String</a>, <a href="_String">string::String</a>&gt;)
</code></pre>


<a name="0x0_registry_has_record"></a>

## Function `has_record`

Check whether the given <code><a href="domain.md#0x0_domain">domain</a></code> is registered in the <code><a href="registry.md#0x0_registry_Registry">Registry</a></code>.


<pre><code><b>public</b> <b>fun</b> <a href="registry.md#0x0_registry_has_record">has_record</a>(self: &<a href="registry.md#0x0_registry_Registry">registry::Registry</a>, <a href="domain.md#0x0_domain">domain</a>: <a href="domain.md#0x0_domain_Domain">domain::Domain</a>): bool
</code></pre>


<a name="0x0_registry_lookup"></a>

## Function `lookup`

Returns the <code>NameRecord</code> associated with the given domain or None.


<pre><code><b>public</b> <b>fun</b> <a href="registry.md#0x0_registry_lookup">lookup</a>(self: &<a href="registry.md#0x0_registry_Registry">registry::Registry</a>, <a href="domain.md#0x0_domain">domain</a>: <a href="domain.md#0x0_domain_Domain">domain::Domain</a>): <a href="_Option">option::Option</a>&lt;<a href="name_record.md#0x0_name_record_NameRecord">name_record::NameRecord</a>&gt;
</code></pre>


<a name="0x0_registry_reverse_lookup"></a>

## Function `reverse_lookup`

Returns the <code>domain_name</code> associated with the given address or None.


<pre><code><b>public</b> <b>fun</b> <a href="registry.md#0x0_registry_reverse_lookup">reverse_lookup</a>(self: &<a href="registry.md#0x0_registry_Registry">registry::Registry</a>, <b>address</b>: <b>address</b>): <a href="_Option">option::Option</a>&lt;<a href="domain.md#0x0_domain_Domain">domain::Domain</a>&gt;
</code></pre>


<a name="0x0_registry_assert_nft_is_authorized"></a>

## Function `assert_nft_is_authorized`

Asserts that the provided NFT:
1. Matches the ID in the corresponding <code>Record</code>
2. Has not expired (does not take into account the grace period)


<pre><code><b>public</b> <b>fun</b> <a href="registry.md#0x0_registry_assert_nft_is_authorized">assert_nft_is_authorized</a>(self: &<a href="registry.md#0x0_registry_Registry">registry::Registry</a>, nft: &<a href="registration_nft.md#0x0_registration_nft_RegistrationNFT">registration_nft::RegistrationNFT</a>, <a href="">clock</a>: &<a href="_Clock">clock::Clock</a>)
</code></pre>


<a name="0x0_registry_get_data"></a>

## Function `get_data`

Returns the <code>data</code> associated with the given <code>Domain</code>.


<pre><code><b>public</b> <b>fun</b> <a href="registry.md#0x0_registry_get_data">get_data</a>(self: &<a href="registry.md#0x0_registry_Registry">registry::Registry</a>, <a href="domain.md#0x0_domain">domain</a>: <a href="domain.md#0x0_domain_Domain">domain::Domain</a>): &<a href="_VecMap">vec_map::VecMap</a>&lt;<a href="_String">string::String</a>, <a href="_String">string::String</a>&gt;
</code></pre>


<a name="0x0_registry_handle_invalidate_reverse_record"></a>

## Function `handle_invalidate_reverse_record`



<pre><code><b>fun</b> <a href="registry.md#0x0_registry_handle_invalidate_reverse_record">handle_invalidate_reverse_record</a>(self: &<b>mut</b> <a href="registry.md#0x0_registry_Registry">registry::Registry</a>, <a href="domain.md#0x0_domain">domain</a>: &<a href="domain.md#0x0_domain_Domain">domain::Domain</a>, old_target_address: <a href="_Option">option::Option</a>&lt;<b>address</b>&gt;, new_target_address: <a href="_Option">option::Option</a>&lt;<b>address</b>&gt;)
</code></pre>
