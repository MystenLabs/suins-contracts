
<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record"></a>

# Module `0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94::name_record`

The <code><a href="name_record.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_NameRecord">NameRecord</a></code> is a struct that represents a single record in the registry.
Can be replaced by any other data structure due to the way <code><a href="name_record.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_NameRecord">NameRecord</a></code>s are
stored and managed. SuiNS has no direct and permanent dependency on this
module.


-  [Struct `NameRecord`](#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_NameRecord)
-  [Function `new`](#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_new)
-  [Function `new_leaf`](#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_new_leaf)
-  [Function `set_data`](#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_set_data)
-  [Function `set_target_address`](#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_set_target_address)
-  [Function `set_expiration_timestamp_ms`](#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_set_expiration_timestamp_ms)
-  [Function `has_expired`](#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_has_expired)
-  [Function `has_expired_past_grace_period`](#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_has_expired_past_grace_period)
-  [Function `is_leaf_record`](#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_is_leaf_record)
-  [Function `data`](#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_data)
-  [Function `target_address`](#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_target_address)
-  [Function `nft_id`](#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_nft_id)
-  [Function `expiration_timestamp_ms`](#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_expiration_timestamp_ms)


<pre><code><b>use</b> <a href="dependencies/move-stdlib/option.md#0x1_option">0x1::option</a>;
<b>use</b> <a href="dependencies/move-stdlib/string.md#0x1_string">0x1::string</a>;
<b>use</b> <a href="dependencies/sui-framework/clock.md#0x2_clock">0x2::clock</a>;
<b>use</b> <a href="dependencies/sui-framework/object.md#0x2_object">0x2::object</a>;
<b>use</b> <a href="dependencies/sui-framework/vec_map.md#0x2_vec_map">0x2::vec_map</a>;
<b>use</b> <a href="constants.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_constants">0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94::constants</a>;
</code></pre>



<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_NameRecord"></a>

## Struct `NameRecord`

A single record in the registry.


<pre><code><b>struct</b> <a href="name_record.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_NameRecord">NameRecord</a> <b>has</b> <b>copy</b>, drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>nft_id: <a href="dependencies/sui-framework/object.md#0x2_object_ID">object::ID</a></code>
</dt>
<dd>
 The ID of the <code>SuinsRegistration</code> assigned to this record.

 The owner of the corrisponding <code>SuinsRegistration</code> has the rights to
 be able to change and adjust the <code>target_address</code> of this domain.

 It is possible that the ID changes if the record expires and is
 purchased by someone else.
</dd>
<dt>
<code>expiration_timestamp_ms: u64</code>
</dt>
<dd>
 Timestamp in milliseconds when the record expires.
</dd>
<dt>
<code>target_address: <a href="dependencies/move-stdlib/option.md#0x1_option_Option">option::Option</a>&lt;<b>address</b>&gt;</code>
</dt>
<dd>
 The target address that this domain points to
</dd>
<dt>
<code>data: <a href="dependencies/sui-framework/vec_map.md#0x2_vec_map_VecMap">vec_map::VecMap</a>&lt;<a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>, <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>&gt;</code>
</dt>
<dd>
 Additional data which may be stored in a record
</dd>
</dl>


</details>

<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_new"></a>

## Function `new`

Create a new NameRecord.


<pre><code><b>public</b> <b>fun</b> <a href="name_record.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_new">new</a>(nft_id: <a href="dependencies/sui-framework/object.md#0x2_object_ID">object::ID</a>, expiration_timestamp_ms: u64): <a href="name_record.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_NameRecord">name_record::NameRecord</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="name_record.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_new">new</a>(
    nft_id: ID,
    expiration_timestamp_ms: u64,
): <a href="name_record.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_NameRecord">NameRecord</a> {
    <a href="name_record.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_NameRecord">NameRecord</a> {
        nft_id,
        expiration_timestamp_ms,
        target_address: <a href="dependencies/move-stdlib/option.md#0x1_option_none">option::none</a>(),
        data: <a href="dependencies/sui-framework/vec_map.md#0x2_vec_map_empty">vec_map::empty</a>(),
    }
}
</code></pre>



</details>

<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_new_leaf"></a>

## Function `new_leaf`

Create a <code>leaf</code> NameRecord.


<pre><code><b>public</b> <b>fun</b> <a href="name_record.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_new_leaf">new_leaf</a>(parent_id: <a href="dependencies/sui-framework/object.md#0x2_object_ID">object::ID</a>, target_address: <a href="dependencies/move-stdlib/option.md#0x1_option_Option">option::Option</a>&lt;<b>address</b>&gt;): <a href="name_record.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_NameRecord">name_record::NameRecord</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="name_record.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_new_leaf">new_leaf</a>(
    parent_id: ID,
    target_address: Option&lt;<b>address</b>&gt;
): <a href="name_record.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_NameRecord">NameRecord</a> {
    <a href="name_record.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_NameRecord">NameRecord</a> {
        nft_id: parent_id,
        expiration_timestamp_ms: <a href="constants.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_constants_leaf_expiration_timestamp">constants::leaf_expiration_timestamp</a>(),
        target_address,
        data: <a href="dependencies/sui-framework/vec_map.md#0x2_vec_map_empty">vec_map::empty</a>()
    }
}
</code></pre>



</details>

<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_set_data"></a>

## Function `set_data`

Set data as a vec_map directly overriding the data set in the
registration self. This simplifies the editing flow and gives
the user and clients a fine-grained control over custom data.

Here's a meta example of how a PTB would look like:
```
let record = moveCall('data', [domain_name]);
moveCall('vec_map::insert', [record.data, key, value]);
moveCall('vec_map::remove', [record.data, other_key]);
moveCall('set_data', [domain_name, record.data]);
```


<pre><code><b>public</b> <b>fun</b> <a href="name_record.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_set_data">set_data</a>(self: &<b>mut</b> <a href="name_record.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_NameRecord">name_record::NameRecord</a>, data: <a href="dependencies/sui-framework/vec_map.md#0x2_vec_map_VecMap">vec_map::VecMap</a>&lt;<a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>, <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="name_record.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_set_data">set_data</a>(self: &<b>mut</b> <a href="name_record.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_NameRecord">NameRecord</a>, data: VecMap&lt;String, String&gt;) {
    self.data = data;
}
</code></pre>



</details>

<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_set_target_address"></a>

## Function `set_target_address`

Set the <code>target_address</code> field of the <code><a href="name_record.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_NameRecord">NameRecord</a></code>.


<pre><code><b>public</b> <b>fun</b> <a href="name_record.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_set_target_address">set_target_address</a>(self: &<b>mut</b> <a href="name_record.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_NameRecord">name_record::NameRecord</a>, new_address: <a href="dependencies/move-stdlib/option.md#0x1_option_Option">option::Option</a>&lt;<b>address</b>&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="name_record.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_set_target_address">set_target_address</a>(self: &<b>mut</b> <a href="name_record.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_NameRecord">NameRecord</a>, new_address: Option&lt;<b>address</b>&gt;) {
    self.target_address = new_address;
}
</code></pre>



</details>

<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_set_expiration_timestamp_ms"></a>

## Function `set_expiration_timestamp_ms`



<pre><code><b>public</b> <b>fun</b> <a href="name_record.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_set_expiration_timestamp_ms">set_expiration_timestamp_ms</a>(self: &<b>mut</b> <a href="name_record.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_NameRecord">name_record::NameRecord</a>, expiration_timestamp_ms: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="name_record.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_set_expiration_timestamp_ms">set_expiration_timestamp_ms</a>(
    self: &<b>mut</b> <a href="name_record.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_NameRecord">NameRecord</a>,
    expiration_timestamp_ms: u64,
) {
    self.expiration_timestamp_ms = expiration_timestamp_ms;
}
</code></pre>



</details>

<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_has_expired"></a>

## Function `has_expired`

Check if the record has expired.


<pre><code><b>public</b> <b>fun</b> <a href="name_record.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_has_expired">has_expired</a>(self: &<a href="name_record.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_NameRecord">name_record::NameRecord</a>, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &<a href="dependencies/sui-framework/clock.md#0x2_clock_Clock">clock::Clock</a>): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="name_record.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_has_expired">has_expired</a>(self: &<a href="name_record.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_NameRecord">NameRecord</a>, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &Clock): bool {
    self.<a href="name_record.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_expiration_timestamp_ms">expiration_timestamp_ms</a> &lt; timestamp_ms(<a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>)
}
</code></pre>



</details>

<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_has_expired_past_grace_period"></a>

## Function `has_expired_past_grace_period`

Check if the record has expired, taking into account the grace period.


<pre><code><b>public</b> <b>fun</b> <a href="name_record.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_has_expired_past_grace_period">has_expired_past_grace_period</a>(self: &<a href="name_record.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_NameRecord">name_record::NameRecord</a>, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &<a href="dependencies/sui-framework/clock.md#0x2_clock_Clock">clock::Clock</a>): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="name_record.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_has_expired_past_grace_period">has_expired_past_grace_period</a>(self: &<a href="name_record.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_NameRecord">NameRecord</a>, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &Clock): bool {
    (self.expiration_timestamp_ms + <a href="constants.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_constants_grace_period_ms">constants::grace_period_ms</a>()) &lt; timestamp_ms(<a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>)
}
</code></pre>



</details>

<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_is_leaf_record"></a>

## Function `is_leaf_record`

Checks whether a name_record is a <code>leaf</code> record.


<pre><code><b>public</b> <b>fun</b> <a href="name_record.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_is_leaf_record">is_leaf_record</a>(self: &<a href="name_record.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_NameRecord">name_record::NameRecord</a>): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="name_record.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_is_leaf_record">is_leaf_record</a>(self: &<a href="name_record.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_NameRecord">NameRecord</a>): bool {
    self.expiration_timestamp_ms == <a href="constants.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_constants_leaf_expiration_timestamp">constants::leaf_expiration_timestamp</a>()
}
</code></pre>



</details>

<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_data"></a>

## Function `data`

Read the <code>data</code> field from the <code><a href="name_record.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_NameRecord">NameRecord</a></code>.


<pre><code><b>public</b> <b>fun</b> <a href="name_record.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_data">data</a>(self: &<a href="name_record.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_NameRecord">name_record::NameRecord</a>): &<a href="dependencies/sui-framework/vec_map.md#0x2_vec_map_VecMap">vec_map::VecMap</a>&lt;<a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>, <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="name_record.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_data">data</a>(self: &<a href="name_record.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_NameRecord">NameRecord</a>): &VecMap&lt;String, String&gt; { &self.data }
</code></pre>



</details>

<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_target_address"></a>

## Function `target_address`

Read the <code>target_address</code> field from the <code><a href="name_record.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_NameRecord">NameRecord</a></code>.


<pre><code><b>public</b> <b>fun</b> <a href="name_record.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_target_address">target_address</a>(self: &<a href="name_record.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_NameRecord">name_record::NameRecord</a>): <a href="dependencies/move-stdlib/option.md#0x1_option_Option">option::Option</a>&lt;<b>address</b>&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="name_record.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_target_address">target_address</a>(self: &<a href="name_record.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_NameRecord">NameRecord</a>): Option&lt;<b>address</b>&gt; { self.target_address }
</code></pre>



</details>

<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_nft_id"></a>

## Function `nft_id`

Read the <code>nft_id</code> field from the <code><a href="name_record.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_NameRecord">NameRecord</a></code>.


<pre><code><b>public</b> <b>fun</b> <a href="name_record.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_nft_id">nft_id</a>(self: &<a href="name_record.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_NameRecord">name_record::NameRecord</a>): <a href="dependencies/sui-framework/object.md#0x2_object_ID">object::ID</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="name_record.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_nft_id">nft_id</a>(self: &<a href="name_record.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_NameRecord">NameRecord</a>): ID { self.nft_id }
</code></pre>



</details>

<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_expiration_timestamp_ms"></a>

## Function `expiration_timestamp_ms`

Read the <code>expiration_timestamp_ms</code> field from the <code><a href="name_record.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_NameRecord">NameRecord</a></code>.


<pre><code><b>public</b> <b>fun</b> <a href="name_record.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_expiration_timestamp_ms">expiration_timestamp_ms</a>(self: &<a href="name_record.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_NameRecord">name_record::NameRecord</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="name_record.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_expiration_timestamp_ms">expiration_timestamp_ms</a>(self: &<a href="name_record.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_name_record_NameRecord">NameRecord</a>): u64 { self.expiration_timestamp_ms }
</code></pre>



</details>
