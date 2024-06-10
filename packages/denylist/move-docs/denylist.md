
<a name="0xee65611da55aeec899a10df218a881d05236383eb61e4c20b21b4aa2d7580315_denylist"></a>

# Module `0xee65611da55aeec899a10df218a881d05236383eb61e4c20b21b4aa2d7580315::denylist`



-  [Struct `Denylist`](#0xee65611da55aeec899a10df218a881d05236383eb61e4c20b21b4aa2d7580315_denylist_Denylist)
-  [Struct `DenyListAuth`](#0xee65611da55aeec899a10df218a881d05236383eb61e4c20b21b4aa2d7580315_denylist_DenyListAuth)
-  [Constants](#@Constants_0)
-  [Function `setup`](#0xee65611da55aeec899a10df218a881d05236383eb61e4c20b21b4aa2d7580315_denylist_setup)
-  [Function `is_reserved_name`](#0xee65611da55aeec899a10df218a881d05236383eb61e4c20b21b4aa2d7580315_denylist_is_reserved_name)
-  [Function `is_blocked_name`](#0xee65611da55aeec899a10df218a881d05236383eb61e4c20b21b4aa2d7580315_denylist_is_blocked_name)
-  [Function `add_reserved_names`](#0xee65611da55aeec899a10df218a881d05236383eb61e4c20b21b4aa2d7580315_denylist_add_reserved_names)
-  [Function `add_blocked_names`](#0xee65611da55aeec899a10df218a881d05236383eb61e4c20b21b4aa2d7580315_denylist_add_blocked_names)
-  [Function `remove_reserved_names`](#0xee65611da55aeec899a10df218a881d05236383eb61e4c20b21b4aa2d7580315_denylist_remove_reserved_names)
-  [Function `remove_blocked_names`](#0xee65611da55aeec899a10df218a881d05236383eb61e4c20b21b4aa2d7580315_denylist_remove_blocked_names)
-  [Function `denylist`](#0xee65611da55aeec899a10df218a881d05236383eb61e4c20b21b4aa2d7580315_denylist_denylist)
-  [Function `denylist_mut`](#0xee65611da55aeec899a10df218a881d05236383eb61e4c20b21b4aa2d7580315_denylist_denylist_mut)
-  [Function `internal_add_names_to_list`](#0xee65611da55aeec899a10df218a881d05236383eb61e4c20b21b4aa2d7580315_denylist_internal_add_names_to_list)
-  [Function `internal_remove_names_from_list`](#0xee65611da55aeec899a10df218a881d05236383eb61e4c20b21b4aa2d7580315_denylist_internal_remove_names_from_list)


<pre><code><b>use</b> <a href="dependencies/move-stdlib/string.md#0x1_string">0x1::string</a>;
<b>use</b> <a href="dependencies/sui-framework/table.md#0x2_table">0x2::table</a>;
<b>use</b> <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context">0x2::tx_context</a>;
<b>use</b> <a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94::suins</a>;
</code></pre>



<a name="0xee65611da55aeec899a10df218a881d05236383eb61e4c20b21b4aa2d7580315_denylist_Denylist"></a>

## Struct `Denylist`

A wrapper that holds the reserved and blocked names.


<pre><code><b>struct</b> <a href="denylist.md#0xee65611da55aeec899a10df218a881d05236383eb61e4c20b21b4aa2d7580315_denylist_Denylist">Denylist</a> <b>has</b> store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>reserved: <a href="dependencies/sui-framework/table.md#0x2_table_Table">table::Table</a>&lt;<a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>, bool&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>blocked: <a href="dependencies/sui-framework/table.md#0x2_table_Table">table::Table</a>&lt;<a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>, bool&gt;</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0xee65611da55aeec899a10df218a881d05236383eb61e4c20b21b4aa2d7580315_denylist_DenyListAuth"></a>

## Struct `DenyListAuth`

The authorization for the denylist registry.


<pre><code><b>struct</b> <a href="denylist.md#0xee65611da55aeec899a10df218a881d05236383eb61e4c20b21b4aa2d7580315_denylist_DenyListAuth">DenyListAuth</a> <b>has</b> drop
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


<a name="0xee65611da55aeec899a10df218a881d05236383eb61e4c20b21b4aa2d7580315_denylist_ENoWordsInList"></a>

No names in the passed list


<pre><code><b>const</b> <a href="denylist.md#0xee65611da55aeec899a10df218a881d05236383eb61e4c20b21b4aa2d7580315_denylist_ENoWordsInList">ENoWordsInList</a>: u64 = 1;
</code></pre>



<a name="0xee65611da55aeec899a10df218a881d05236383eb61e4c20b21b4aa2d7580315_denylist_setup"></a>

## Function `setup`



<pre><code><b>public</b> <b>fun</b> <a href="denylist.md#0xee65611da55aeec899a10df218a881d05236383eb61e4c20b21b4aa2d7580315_denylist_setup">setup</a>(<a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>: &<b>mut</b> <a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_SuiNS">suins::SuiNS</a>, cap: &<a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_AdminCap">suins::AdminCap</a>, ctx: &<b>mut</b> <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="denylist.md#0xee65611da55aeec899a10df218a881d05236383eb61e4c20b21b4aa2d7580315_denylist_setup">setup</a>(<a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>: &<b>mut</b> SuiNS, cap: &AdminCap, ctx: &<b>mut</b> TxContext) {
    <a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_add_registry">suins::add_registry</a>(cap, <a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>, <a href="denylist.md#0xee65611da55aeec899a10df218a881d05236383eb61e4c20b21b4aa2d7580315_denylist_Denylist">Denylist</a> {
        reserved: <a href="dependencies/sui-framework/table.md#0x2_table_new">table::new</a>(ctx),
        blocked: <a href="dependencies/sui-framework/table.md#0x2_table_new">table::new</a>(ctx)
    });
}
</code></pre>



</details>

<a name="0xee65611da55aeec899a10df218a881d05236383eb61e4c20b21b4aa2d7580315_denylist_is_reserved_name"></a>

## Function `is_reserved_name`

Check for a reserved name


<pre><code><b>public</b> <b>fun</b> <a href="denylist.md#0xee65611da55aeec899a10df218a881d05236383eb61e4c20b21b4aa2d7580315_denylist_is_reserved_name">is_reserved_name</a>(<a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>: &<a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_SuiNS">suins::SuiNS</a>, name: <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="denylist.md#0xee65611da55aeec899a10df218a881d05236383eb61e4c20b21b4aa2d7580315_denylist_is_reserved_name">is_reserved_name</a>(<a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>: &SuiNS, name: String): bool {
    <a href="denylist.md#0xee65611da55aeec899a10df218a881d05236383eb61e4c20b21b4aa2d7580315_denylist">denylist</a>(<a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>).reserved.contains(name)
}
</code></pre>



</details>

<a name="0xee65611da55aeec899a10df218a881d05236383eb61e4c20b21b4aa2d7580315_denylist_is_blocked_name"></a>

## Function `is_blocked_name`

Checks for a blocked name.


<pre><code><b>public</b> <b>fun</b> <a href="denylist.md#0xee65611da55aeec899a10df218a881d05236383eb61e4c20b21b4aa2d7580315_denylist_is_blocked_name">is_blocked_name</a>(<a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>: &<a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_SuiNS">suins::SuiNS</a>, name: <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="denylist.md#0xee65611da55aeec899a10df218a881d05236383eb61e4c20b21b4aa2d7580315_denylist_is_blocked_name">is_blocked_name</a>(<a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>: &SuiNS, name: String): bool {
    <a href="denylist.md#0xee65611da55aeec899a10df218a881d05236383eb61e4c20b21b4aa2d7580315_denylist">denylist</a>(<a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>).blocked.contains(name)
}
</code></pre>



</details>

<a name="0xee65611da55aeec899a10df218a881d05236383eb61e4c20b21b4aa2d7580315_denylist_add_reserved_names"></a>

## Function `add_reserved_names`

Add a list of reserved names to the list as admin.


<pre><code><b>public</b> <b>fun</b> <a href="denylist.md#0xee65611da55aeec899a10df218a881d05236383eb61e4c20b21b4aa2d7580315_denylist_add_reserved_names">add_reserved_names</a>(<a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>: &<b>mut</b> <a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_SuiNS">suins::SuiNS</a>, _: &<a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_AdminCap">suins::AdminCap</a>, words: <a href="dependencies/move-stdlib/vector.md#0x1_vector">vector</a>&lt;<a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="denylist.md#0xee65611da55aeec899a10df218a881d05236383eb61e4c20b21b4aa2d7580315_denylist_add_reserved_names">add_reserved_names</a>(<a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>: &<b>mut</b> SuiNS, _: &AdminCap, words: <a href="dependencies/move-stdlib/vector.md#0x1_vector">vector</a>&lt;String&gt;) {
    <a href="denylist.md#0xee65611da55aeec899a10df218a881d05236383eb61e4c20b21b4aa2d7580315_denylist_internal_add_names_to_list">internal_add_names_to_list</a>(&<b>mut</b> <a href="denylist.md#0xee65611da55aeec899a10df218a881d05236383eb61e4c20b21b4aa2d7580315_denylist_denylist_mut">denylist_mut</a>(<a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>).reserved, words);
}
</code></pre>



</details>

<a name="0xee65611da55aeec899a10df218a881d05236383eb61e4c20b21b4aa2d7580315_denylist_add_blocked_names"></a>

## Function `add_blocked_names`

Add a list of offensive names to the list as admin.


<pre><code><b>public</b> <b>fun</b> <a href="denylist.md#0xee65611da55aeec899a10df218a881d05236383eb61e4c20b21b4aa2d7580315_denylist_add_blocked_names">add_blocked_names</a>(<a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>: &<b>mut</b> <a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_SuiNS">suins::SuiNS</a>, _: &<a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_AdminCap">suins::AdminCap</a>, words: <a href="dependencies/move-stdlib/vector.md#0x1_vector">vector</a>&lt;<a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="denylist.md#0xee65611da55aeec899a10df218a881d05236383eb61e4c20b21b4aa2d7580315_denylist_add_blocked_names">add_blocked_names</a>(<a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>: &<b>mut</b> SuiNS, _: &AdminCap, words: <a href="dependencies/move-stdlib/vector.md#0x1_vector">vector</a>&lt;String&gt;) {
    <a href="denylist.md#0xee65611da55aeec899a10df218a881d05236383eb61e4c20b21b4aa2d7580315_denylist_internal_add_names_to_list">internal_add_names_to_list</a>(&<b>mut</b> <a href="denylist.md#0xee65611da55aeec899a10df218a881d05236383eb61e4c20b21b4aa2d7580315_denylist_denylist_mut">denylist_mut</a>(<a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>).blocked, words);
}
</code></pre>



</details>

<a name="0xee65611da55aeec899a10df218a881d05236383eb61e4c20b21b4aa2d7580315_denylist_remove_reserved_names"></a>

## Function `remove_reserved_names`

Remove a list of words from the reserved names list.


<pre><code><b>public</b> <b>fun</b> <a href="denylist.md#0xee65611da55aeec899a10df218a881d05236383eb61e4c20b21b4aa2d7580315_denylist_remove_reserved_names">remove_reserved_names</a>(<a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>: &<b>mut</b> <a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_SuiNS">suins::SuiNS</a>, _: &<a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_AdminCap">suins::AdminCap</a>, words: <a href="dependencies/move-stdlib/vector.md#0x1_vector">vector</a>&lt;<a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="denylist.md#0xee65611da55aeec899a10df218a881d05236383eb61e4c20b21b4aa2d7580315_denylist_remove_reserved_names">remove_reserved_names</a>(<a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>: &<b>mut</b> SuiNS, _: &AdminCap, words: <a href="dependencies/move-stdlib/vector.md#0x1_vector">vector</a>&lt;String&gt;) {
    <a href="denylist.md#0xee65611da55aeec899a10df218a881d05236383eb61e4c20b21b4aa2d7580315_denylist_internal_remove_names_from_list">internal_remove_names_from_list</a>(&<b>mut</b> <a href="denylist.md#0xee65611da55aeec899a10df218a881d05236383eb61e4c20b21b4aa2d7580315_denylist_denylist_mut">denylist_mut</a>(<a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>).reserved, words);
}
</code></pre>



</details>

<a name="0xee65611da55aeec899a10df218a881d05236383eb61e4c20b21b4aa2d7580315_denylist_remove_blocked_names"></a>

## Function `remove_blocked_names`

Remove a list of words from the list as admin.


<pre><code><b>public</b> <b>fun</b> <a href="denylist.md#0xee65611da55aeec899a10df218a881d05236383eb61e4c20b21b4aa2d7580315_denylist_remove_blocked_names">remove_blocked_names</a>(<a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>: &<b>mut</b> <a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_SuiNS">suins::SuiNS</a>, _: &<a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_AdminCap">suins::AdminCap</a>, words: <a href="dependencies/move-stdlib/vector.md#0x1_vector">vector</a>&lt;<a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="denylist.md#0xee65611da55aeec899a10df218a881d05236383eb61e4c20b21b4aa2d7580315_denylist_remove_blocked_names">remove_blocked_names</a>(<a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>: &<b>mut</b> SuiNS, _: &AdminCap, words: <a href="dependencies/move-stdlib/vector.md#0x1_vector">vector</a>&lt;String&gt;) {
    <a href="denylist.md#0xee65611da55aeec899a10df218a881d05236383eb61e4c20b21b4aa2d7580315_denylist_internal_remove_names_from_list">internal_remove_names_from_list</a>(&<b>mut</b> <a href="denylist.md#0xee65611da55aeec899a10df218a881d05236383eb61e4c20b21b4aa2d7580315_denylist_denylist_mut">denylist_mut</a>(<a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>).blocked, words);
}
</code></pre>



</details>

<a name="0xee65611da55aeec899a10df218a881d05236383eb61e4c20b21b4aa2d7580315_denylist_denylist"></a>

## Function `denylist`

Get immutable access to the registry.


<pre><code><b>fun</b> <a href="denylist.md#0xee65611da55aeec899a10df218a881d05236383eb61e4c20b21b4aa2d7580315_denylist">denylist</a>(<a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>: &<a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_SuiNS">suins::SuiNS</a>): &<a href="denylist.md#0xee65611da55aeec899a10df218a881d05236383eb61e4c20b21b4aa2d7580315_denylist_Denylist">denylist::Denylist</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="denylist.md#0xee65611da55aeec899a10df218a881d05236383eb61e4c20b21b4aa2d7580315_denylist">denylist</a>(<a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>: &SuiNS): &<a href="denylist.md#0xee65611da55aeec899a10df218a881d05236383eb61e4c20b21b4aa2d7580315_denylist_Denylist">Denylist</a> {
    <a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>.registry()
}
</code></pre>



</details>

<a name="0xee65611da55aeec899a10df218a881d05236383eb61e4c20b21b4aa2d7580315_denylist_denylist_mut"></a>

## Function `denylist_mut`

Internal helper to get access to the BlockedNames object


<pre><code><b>fun</b> <a href="denylist.md#0xee65611da55aeec899a10df218a881d05236383eb61e4c20b21b4aa2d7580315_denylist_denylist_mut">denylist_mut</a>(<a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>: &<b>mut</b> <a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_SuiNS">suins::SuiNS</a>): &<b>mut</b> <a href="denylist.md#0xee65611da55aeec899a10df218a881d05236383eb61e4c20b21b4aa2d7580315_denylist_Denylist">denylist::Denylist</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="denylist.md#0xee65611da55aeec899a10df218a881d05236383eb61e4c20b21b4aa2d7580315_denylist_denylist_mut">denylist_mut</a>(<a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>: &<b>mut</b> SuiNS): &<b>mut</b> <a href="denylist.md#0xee65611da55aeec899a10df218a881d05236383eb61e4c20b21b4aa2d7580315_denylist_Denylist">Denylist</a> {
    <a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_app_registry_mut">suins::app_registry_mut</a>&lt;<a href="denylist.md#0xee65611da55aeec899a10df218a881d05236383eb61e4c20b21b4aa2d7580315_denylist_DenyListAuth">DenyListAuth</a>, <a href="denylist.md#0xee65611da55aeec899a10df218a881d05236383eb61e4c20b21b4aa2d7580315_denylist_Denylist">Denylist</a>&gt;(<a href="denylist.md#0xee65611da55aeec899a10df218a881d05236383eb61e4c20b21b4aa2d7580315_denylist_DenyListAuth">DenyListAuth</a> {}, <a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>)
}
</code></pre>



</details>

<a name="0xee65611da55aeec899a10df218a881d05236383eb61e4c20b21b4aa2d7580315_denylist_internal_add_names_to_list"></a>

## Function `internal_add_names_to_list`

Internal helper to batch add words to a table.


<pre><code><b>fun</b> <a href="denylist.md#0xee65611da55aeec899a10df218a881d05236383eb61e4c20b21b4aa2d7580315_denylist_internal_add_names_to_list">internal_add_names_to_list</a>(<a href="dependencies/sui-framework/table.md#0x2_table">table</a>: &<b>mut</b> <a href="dependencies/sui-framework/table.md#0x2_table_Table">table::Table</a>&lt;<a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>, bool&gt;, words: <a href="dependencies/move-stdlib/vector.md#0x1_vector">vector</a>&lt;<a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="denylist.md#0xee65611da55aeec899a10df218a881d05236383eb61e4c20b21b4aa2d7580315_denylist_internal_add_names_to_list">internal_add_names_to_list</a>(<a href="dependencies/sui-framework/table.md#0x2_table">table</a>: &<b>mut</b> Table&lt;String, bool&gt;, words: <a href="dependencies/move-stdlib/vector.md#0x1_vector">vector</a>&lt;String&gt;) {
    <b>assert</b>!(words.length() &gt; 0, <a href="denylist.md#0xee65611da55aeec899a10df218a881d05236383eb61e4c20b21b4aa2d7580315_denylist_ENoWordsInList">ENoWordsInList</a>);

    <b>let</b> <b>mut</b> i = words.length();

    <b>while</b> (i &gt; 0) {
        i = i - 1;
        <b>let</b> word = words[i];
        <a href="dependencies/sui-framework/table.md#0x2_table">table</a>.add(word, <b>true</b>);
    };
}
</code></pre>



</details>

<a name="0xee65611da55aeec899a10df218a881d05236383eb61e4c20b21b4aa2d7580315_denylist_internal_remove_names_from_list"></a>

## Function `internal_remove_names_from_list`

Internal helper to remove words from a table.


<pre><code><b>fun</b> <a href="denylist.md#0xee65611da55aeec899a10df218a881d05236383eb61e4c20b21b4aa2d7580315_denylist_internal_remove_names_from_list">internal_remove_names_from_list</a>(<a href="dependencies/sui-framework/table.md#0x2_table">table</a>: &<b>mut</b> <a href="dependencies/sui-framework/table.md#0x2_table_Table">table::Table</a>&lt;<a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>, bool&gt;, words: <a href="dependencies/move-stdlib/vector.md#0x1_vector">vector</a>&lt;<a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="denylist.md#0xee65611da55aeec899a10df218a881d05236383eb61e4c20b21b4aa2d7580315_denylist_internal_remove_names_from_list">internal_remove_names_from_list</a>(<a href="dependencies/sui-framework/table.md#0x2_table">table</a>: &<b>mut</b> Table&lt;String, bool&gt;, words: <a href="dependencies/move-stdlib/vector.md#0x1_vector">vector</a>&lt;String&gt;) {
    <b>assert</b>!(words.length() &gt; 0, <a href="denylist.md#0xee65611da55aeec899a10df218a881d05236383eb61e4c20b21b4aa2d7580315_denylist_ENoWordsInList">ENoWordsInList</a>);

    <b>let</b> <b>mut</b> i = words.length();

    <b>while</b> (i &gt; 0) {
        i = i - 1;
        <b>let</b> word = words[i];
        <a href="dependencies/sui-framework/table.md#0x2_table">table</a>.remove(word);
    };
}
</code></pre>



</details>
