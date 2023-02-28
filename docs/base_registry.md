
<a name="0x0_base_registry"></a>

# Module `0x0::base_registry`

This module is intended to maintain records of domain names including the owner, resolver address and time to live (TTL).
The owners of this only own the name, not own the registration.
It primarily facilitates the lending and borrowing of domain names.


-  [Resource `AdminCap`](#0x0_base_registry_AdminCap)
-  [Struct `NewOwnerEvent`](#0x0_base_registry_NewOwnerEvent)
-  [Struct `NewResolverEvent`](#0x0_base_registry_NewResolverEvent)
-  [Struct `NewTTLEvent`](#0x0_base_registry_NewTTLEvent)
-  [Struct `NewRecordEvent`](#0x0_base_registry_NewRecordEvent)
-  [Struct `Record`](#0x0_base_registry_Record)
-  [Resource `Registry`](#0x0_base_registry_Registry)
-  [Constants](#@Constants_0)
-  [Function `set_owner`](#0x0_base_registry_set_owner)
-  [Function `set_subnode_owner`](#0x0_base_registry_set_subnode_owner)
-  [Function `set_resolver`](#0x0_base_registry_set_resolver)
-  [Function `set_TTL`](#0x0_base_registry_set_TTL)
-  [Function `owner`](#0x0_base_registry_owner)
-  [Function `resolver`](#0x0_base_registry_resolver)
-  [Function `ttl`](#0x0_base_registry_ttl)
-  [Function `get_record_by_key`](#0x0_base_registry_get_record_by_key)
-  [Function `authorised`](#0x0_base_registry_authorised)
-  [Function `set_owner_internal`](#0x0_base_registry_set_owner_internal)
-  [Function `set_record_internal`](#0x0_base_registry_set_record_internal)
-  [Function `make_node`](#0x0_base_registry_make_node)
-  [Function `init`](#0x0_base_registry_init)
-  [Function `new_record`](#0x0_base_registry_new_record)


<pre><code><b>use</b> <a href="">0x1::string</a>;
<b>use</b> <a href="">0x2::dynamic_field</a>;
<b>use</b> <a href="">0x2::event</a>;
<b>use</b> <a href="">0x2::object</a>;
<b>use</b> <a href="">0x2::transfer</a>;
<b>use</b> <a href="">0x2::tx_context</a>;
</code></pre>



<a name="0x0_base_registry_AdminCap"></a>

## Resource `AdminCap`



<pre><code><b>struct</b> <a href="base_registry.md#0x0_base_registry_AdminCap">AdminCap</a> <b>has</b> store, key
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>id: <a href="_UID">object::UID</a></code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0x0_base_registry_NewOwnerEvent"></a>

## Struct `NewOwnerEvent`



<pre><code><b>struct</b> <a href="base_registry.md#0x0_base_registry_NewOwnerEvent">NewOwnerEvent</a> <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>node: <a href="_String">string::String</a></code>
</dt>
<dd>

</dd>
<dt>
<code>owner: <b>address</b></code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0x0_base_registry_NewResolverEvent"></a>

## Struct `NewResolverEvent`



<pre><code><b>struct</b> <a href="base_registry.md#0x0_base_registry_NewResolverEvent">NewResolverEvent</a> <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>node: <a href="_String">string::String</a></code>
</dt>
<dd>

</dd>
<dt>
<code><a href="resolver.md#0x0_resolver">resolver</a>: <b>address</b></code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0x0_base_registry_NewTTLEvent"></a>

## Struct `NewTTLEvent`



<pre><code><b>struct</b> <a href="base_registry.md#0x0_base_registry_NewTTLEvent">NewTTLEvent</a> <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>node: <a href="_String">string::String</a></code>
</dt>
<dd>

</dd>
<dt>
<code>ttl: u64</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0x0_base_registry_NewRecordEvent"></a>

## Struct `NewRecordEvent`



<pre><code><b>struct</b> <a href="base_registry.md#0x0_base_registry_NewRecordEvent">NewRecordEvent</a> <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>node: <a href="_String">string::String</a></code>
</dt>
<dd>

</dd>
<dt>
<code>owner: <b>address</b></code>
</dt>
<dd>

</dd>
<dt>
<code><a href="resolver.md#0x0_resolver">resolver</a>: <b>address</b></code>
</dt>
<dd>

</dd>
<dt>
<code>ttl: u64</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0x0_base_registry_Record"></a>

## Struct `Record`

name records that correspond to registration records in <code>Registrar</code>


<pre><code><b>struct</b> <a href="base_registry.md#0x0_base_registry_Record">Record</a> <b>has</b> <b>copy</b>, drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>owner: <b>address</b></code>
</dt>
<dd>

</dd>
<dt>
<code><a href="resolver.md#0x0_resolver">resolver</a>: <b>address</b></code>
</dt>
<dd>

</dd>
<dt>
<code>ttl: u64</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0x0_base_registry_Registry"></a>

## Resource `Registry`

Mapping domain name to name record (instance of <code><a href="base_registry.md#0x0_base_registry_Record">Record</a></code>).
Each name record is a dynamic field of this share object,.


<pre><code><b>struct</b> <a href="base_registry.md#0x0_base_registry_Registry">Registry</a> <b>has</b> key
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>id: <a href="_UID">object::UID</a></code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="@Constants_0"></a>

## Constants


<a name="0x0_base_registry_EUnauthorized"></a>



<pre><code><b>const</b> <a href="base_registry.md#0x0_base_registry_EUnauthorized">EUnauthorized</a>: u64 = 101;
</code></pre>



<a name="0x0_base_registry_MAX_TTL"></a>



<pre><code><b>const</b> <a href="base_registry.md#0x0_base_registry_MAX_TTL">MAX_TTL</a>: u64 = 1048576;
</code></pre>



<a name="0x0_base_registry_set_owner"></a>

## Function `set_owner`


<a name="@Notice_1"></a>

###### Notice

This funtions allows owner of <code>node</code> to reassign ownership of this node.
The <code>node</code> can have multiple levels.


<a name="@Dev_2"></a>

###### Dev

<code><a href="base_registry.md#0x0_base_registry_Record">Record</a></code> indexed by <code>node</code> is updated.


<a name="@Params_3"></a>

###### Params

<code>node</code>: node to be updated
<code>owner</code>: new owner address


<a name="@Panics_4"></a>

###### Panics

Panics if caller isn't the owner of <code>node</code>
or <code>node</code> doesn't exists.


<pre><code><b>public</b> entry <b>fun</b> <a href="base_registry.md#0x0_base_registry_set_owner">set_owner</a>(registry: &<b>mut</b> <a href="base_registry.md#0x0_base_registry_Registry">base_registry::Registry</a>, node: <a href="">vector</a>&lt;u8&gt;, owner: <b>address</b>, ctx: &<b>mut</b> <a href="_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="base_registry.md#0x0_base_registry_set_owner">set_owner</a>(registry: &<b>mut</b> <a href="base_registry.md#0x0_base_registry_Registry">Registry</a>, node: <a href="">vector</a>&lt;u8&gt;, owner: <b>address</b>, ctx: &<b>mut</b> TxContext) {
    <a href="base_registry.md#0x0_base_registry_authorised">authorised</a>(registry, node, ctx);

    <b>let</b> node = <a href="_utf8">string::utf8</a>(node);
    <a href="base_registry.md#0x0_base_registry_set_owner_internal">set_owner_internal</a>(registry, node, owner);
    <a href="_emit">event::emit</a>(<a href="base_registry.md#0x0_base_registry_NewOwnerEvent">NewOwnerEvent</a> { node, owner });
}
</code></pre>



</details>

<a name="0x0_base_registry_set_subnode_owner"></a>

## Function `set_subnode_owner`


<a name="@Notice_5"></a>

###### Notice

This funtions allow owner of <code>node</code> to reassign ownership of subnode.
The <code>node</code> can have multiple levels.
The subnode which is created by <code>label</code>.<code>node</code> must exist.


<a name="@Dev_6"></a>

###### Dev

<code><a href="base_registry.md#0x0_base_registry_Record">Record</a></code> indexed by <code>label</code>.<code>node</code> is updated.


<a name="@Params_7"></a>

###### Params

<code>node</code>: node to get subnode
<code>label</code>: label of subnode
<code>owner</code>: new owner address


<a name="@Panics_8"></a>

###### Panics

Panics if caller isn't the owner of <code>node</code>
or <code>subnode</code> doesn't exists.


<pre><code><b>public</b> entry <b>fun</b> <a href="base_registry.md#0x0_base_registry_set_subnode_owner">set_subnode_owner</a>(registry: &<b>mut</b> <a href="base_registry.md#0x0_base_registry_Registry">base_registry::Registry</a>, node: <a href="">vector</a>&lt;u8&gt;, label: <a href="">vector</a>&lt;u8&gt;, owner: <b>address</b>, ctx: &<b>mut</b> <a href="_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="base_registry.md#0x0_base_registry_set_subnode_owner">set_subnode_owner</a>(
    registry: &<b>mut</b> <a href="base_registry.md#0x0_base_registry_Registry">Registry</a>,
    node: <a href="">vector</a>&lt;u8&gt;,
    label: <a href="">vector</a>&lt;u8&gt;,
    owner: <b>address</b>,
    ctx: &<b>mut</b> TxContext,
) {
    // TODO: `node` can have multiple levels, should disable it because we don't support subdomain atm
    // FIXME: only allow nodes of 2 levels <b>to</b> reassign
    <a href="base_registry.md#0x0_base_registry_authorised">authorised</a>(registry, node, ctx);

    <b>let</b> subnode = <a href="base_registry.md#0x0_base_registry_make_node">make_node</a>(label, <a href="_utf8">string::utf8</a>(node));
    // <b>requires</b> both node and subnode <b>to</b> exist
    <a href="base_registry.md#0x0_base_registry_set_owner_internal">set_owner_internal</a>(registry, subnode, owner);
    <a href="_emit">event::emit</a>(<a href="base_registry.md#0x0_base_registry_NewOwnerEvent">NewOwnerEvent</a> { node: subnode, owner });
}
</code></pre>



</details>

<a name="0x0_base_registry_set_resolver"></a>

## Function `set_resolver`


<a name="@Notice_9"></a>

###### Notice

This funtions allows owner of <code>node</code> to reassign resolver address of this node.
The <code>node</code> can have multiple levels.


<a name="@Dev_10"></a>

###### Dev

<code><a href="base_registry.md#0x0_base_registry_Record">Record</a></code> indexed by <code>node</code> is updated.


<a name="@Params_11"></a>

###### Params

<code>node</code>: node to get subnode
<code><a href="resolver.md#0x0_resolver">resolver</a></code>: new resolver address


<a name="@Panics_12"></a>

###### Panics

Panics if caller isn't the owner of <code>node</code>
or <code>node</code> doesn't exists.


<pre><code><b>public</b> entry <b>fun</b> <a href="base_registry.md#0x0_base_registry_set_resolver">set_resolver</a>(registry: &<b>mut</b> <a href="base_registry.md#0x0_base_registry_Registry">base_registry::Registry</a>, node: <a href="">vector</a>&lt;u8&gt;, <a href="resolver.md#0x0_resolver">resolver</a>: <b>address</b>, ctx: &<b>mut</b> <a href="_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="base_registry.md#0x0_base_registry_set_resolver">set_resolver</a>(registry: &<b>mut</b> <a href="base_registry.md#0x0_base_registry_Registry">Registry</a>, node: <a href="">vector</a>&lt;u8&gt;, <a href="resolver.md#0x0_resolver">resolver</a>: <b>address</b>, ctx: &<b>mut</b> TxContext) {
    <a href="base_registry.md#0x0_base_registry_authorised">authorised</a>(registry, node, ctx);

    <b>let</b> node = <a href="_utf8">string::utf8</a>(node);
    <b>let</b> record = field::borrow_mut&lt;String, <a href="base_registry.md#0x0_base_registry_Record">Record</a>&gt;(&<b>mut</b> registry.id, node);
    record.<a href="resolver.md#0x0_resolver">resolver</a> = <a href="resolver.md#0x0_resolver">resolver</a>;
    <a href="_emit">event::emit</a>(<a href="base_registry.md#0x0_base_registry_NewResolverEvent">NewResolverEvent</a> { node, <a href="resolver.md#0x0_resolver">resolver</a> });
}
</code></pre>



</details>

<a name="0x0_base_registry_set_TTL"></a>

## Function `set_TTL`


<a name="@Notice_13"></a>

###### Notice

This funtions allows owner of <code>node</code> to reassign ttl address of this node.
The <code>node</code> can have multiple levels.


<a name="@Dev_14"></a>

###### Dev

<code><a href="base_registry.md#0x0_base_registry_Record">Record</a></code> indexed by <code>node</code> is updated.


<a name="@Params_15"></a>

###### Params

<code>node</code>: node to get subnode
<code>ttl</code>: new TTL address


<a name="@Panics_16"></a>

###### Panics

Panics if caller isn't the owner of <code>node</code>
or <code>node</code> doesn't exists.


<pre><code><b>public</b> entry <b>fun</b> <a href="base_registry.md#0x0_base_registry_set_TTL">set_TTL</a>(registry: &<b>mut</b> <a href="base_registry.md#0x0_base_registry_Registry">base_registry::Registry</a>, node: <a href="">vector</a>&lt;u8&gt;, ttl: u64, ctx: &<b>mut</b> <a href="_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="base_registry.md#0x0_base_registry_set_TTL">set_TTL</a>(registry: &<b>mut</b> <a href="base_registry.md#0x0_base_registry_Registry">Registry</a>, node: <a href="">vector</a>&lt;u8&gt;, ttl: u64, ctx: &<b>mut</b> TxContext) {
    // TODO: does this function have any <b>use</b>?
    <a href="base_registry.md#0x0_base_registry_authorised">authorised</a>(registry, node, ctx);

    <b>let</b> node = <a href="_utf8">string::utf8</a>(node);
    <b>let</b> record = field::borrow_mut&lt;String, <a href="base_registry.md#0x0_base_registry_Record">Record</a>&gt;(&<b>mut</b> registry.id, node);
    record.ttl = ttl;
    <a href="_emit">event::emit</a>(<a href="base_registry.md#0x0_base_registry_NewTTLEvent">NewTTLEvent</a> { node, ttl });
}
</code></pre>



</details>

<a name="0x0_base_registry_owner"></a>

## Function `owner`


<a name="@Notice_17"></a>

###### Notice

Get owner address of a <code>node</code>.
The <code>node</code> can have multiple levels.


<a name="@Params_18"></a>

###### Params

<code>node</code>: node to find the owner


<a name="@Panics_19"></a>

###### Panics

Panics if <code>node</code> doesn't exists.


<pre><code><b>public</b> <b>fun</b> <a href="base_registry.md#0x0_base_registry_owner">owner</a>(registry: &<a href="base_registry.md#0x0_base_registry_Registry">base_registry::Registry</a>, node: <a href="">vector</a>&lt;u8&gt;): <b>address</b>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="base_registry.md#0x0_base_registry_owner">owner</a>(registry: &<a href="base_registry.md#0x0_base_registry_Registry">Registry</a>, node: <a href="">vector</a>&lt;u8&gt;): <b>address</b> {
    field::borrow&lt;String, <a href="base_registry.md#0x0_base_registry_Record">Record</a>&gt;(&registry.id, <a href="_utf8">string::utf8</a>(node)).owner
}
</code></pre>



</details>

<a name="0x0_base_registry_resolver"></a>

## Function `resolver`


<a name="@Notice_20"></a>

###### Notice

Get resolver address of a <code>node</code>.
The <code>node</code> can have multiple levels.


<a name="@Params_21"></a>

###### Params

<code>node</code>: node to find the resolver address


<a name="@Panics_22"></a>

###### Panics

Panics if <code>node</code> doesn't exists.


<pre><code><b>public</b> <b>fun</b> <a href="resolver.md#0x0_resolver">resolver</a>(registry: &<a href="base_registry.md#0x0_base_registry_Registry">base_registry::Registry</a>, node: <a href="">vector</a>&lt;u8&gt;): <b>address</b>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="resolver.md#0x0_resolver">resolver</a>(registry: &<a href="base_registry.md#0x0_base_registry_Registry">Registry</a>, node: <a href="">vector</a>&lt;u8&gt;): <b>address</b> {
    field::borrow&lt;String, <a href="base_registry.md#0x0_base_registry_Record">Record</a>&gt;(&registry.id, <a href="_utf8">string::utf8</a>(node)).<a href="resolver.md#0x0_resolver">resolver</a>
}
</code></pre>



</details>

<a name="0x0_base_registry_ttl"></a>

## Function `ttl`


<a name="@Notice_23"></a>

###### Notice

Get ttl of a <code>node</code>.
The <code>node</code> can have multiple levels.


<a name="@Params_24"></a>

###### Params

<code>node</code>: node to find the ttl


<a name="@Panics_25"></a>

###### Panics

Panics if <code>node</code> doesn't exists.


<pre><code><b>public</b> <b>fun</b> <a href="base_registry.md#0x0_base_registry_ttl">ttl</a>(registry: &<a href="base_registry.md#0x0_base_registry_Registry">base_registry::Registry</a>, node: <a href="">vector</a>&lt;u8&gt;): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="base_registry.md#0x0_base_registry_ttl">ttl</a>(registry: &<a href="base_registry.md#0x0_base_registry_Registry">Registry</a>, node: <a href="">vector</a>&lt;u8&gt;): u64 {
    field::borrow&lt;String, <a href="base_registry.md#0x0_base_registry_Record">Record</a>&gt;(&registry.id, <a href="_utf8">string::utf8</a>(node)).ttl
}
</code></pre>



</details>

<a name="0x0_base_registry_get_record_by_key"></a>

## Function `get_record_by_key`


<a name="@Notice_26"></a>

###### Notice

Get <code>(owner, <a href="resolver.md#0x0_resolver">resolver</a>, ttl)</code> of a <code>node</code>.
The <code>node</code> can have multiple levels.


<a name="@Params_27"></a>

###### Params

<code>node</code>: node to find the ttl


<a name="@Panics_28"></a>

###### Panics

Panics if <code>node</code> doesn't exists.


<pre><code><b>public</b> <b>fun</b> <a href="base_registry.md#0x0_base_registry_get_record_by_key">get_record_by_key</a>(registry: &<a href="base_registry.md#0x0_base_registry_Registry">base_registry::Registry</a>, key: <a href="_String">string::String</a>): (<b>address</b>, <b>address</b>, u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="base_registry.md#0x0_base_registry_get_record_by_key">get_record_by_key</a>(registry: &<a href="base_registry.md#0x0_base_registry_Registry">Registry</a>, key: String): (<b>address</b>, <b>address</b>, u64) {
    <b>let</b> record = field::borrow&lt;String, <a href="base_registry.md#0x0_base_registry_Record">Record</a>&gt;(&registry.id, key);

    (record.owner, record.<a href="resolver.md#0x0_resolver">resolver</a>, record.ttl)
}
</code></pre>



</details>

<a name="0x0_base_registry_authorised"></a>

## Function `authorised`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="base_registry.md#0x0_base_registry_authorised">authorised</a>(registry: &<a href="base_registry.md#0x0_base_registry_Registry">base_registry::Registry</a>, node: <a href="">vector</a>&lt;u8&gt;, ctx: &<a href="_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="base_registry.md#0x0_base_registry_authorised">authorised</a>(registry: &<a href="base_registry.md#0x0_base_registry_Registry">Registry</a>, node: <a href="">vector</a>&lt;u8&gt;, ctx: &TxContext) {
    <b>let</b> owner = <a href="base_registry.md#0x0_base_registry_owner">owner</a>(registry, node);
    <b>assert</b>!(sender(ctx) == owner, <a href="base_registry.md#0x0_base_registry_EUnauthorized">EUnauthorized</a>);
}
</code></pre>



</details>

<a name="0x0_base_registry_set_owner_internal"></a>

## Function `set_owner_internal`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="base_registry.md#0x0_base_registry_set_owner_internal">set_owner_internal</a>(registry: &<b>mut</b> <a href="base_registry.md#0x0_base_registry_Registry">base_registry::Registry</a>, node: <a href="_String">string::String</a>, owner: <b>address</b>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="base_registry.md#0x0_base_registry_set_owner_internal">set_owner_internal</a>(registry: &<b>mut</b> <a href="base_registry.md#0x0_base_registry_Registry">Registry</a>, node: String, owner: <b>address</b>) {
    <b>let</b> record = field::borrow_mut&lt;String, <a href="base_registry.md#0x0_base_registry_Record">Record</a>&gt;(&<b>mut</b> registry.id, node);
    record.owner = owner;
}
</code></pre>



</details>

<a name="0x0_base_registry_set_record_internal"></a>

## Function `set_record_internal`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="base_registry.md#0x0_base_registry_set_record_internal">set_record_internal</a>(registry: &<b>mut</b> <a href="base_registry.md#0x0_base_registry_Registry">base_registry::Registry</a>, node: <a href="_String">string::String</a>, owner: <b>address</b>, <a href="resolver.md#0x0_resolver">resolver</a>: <b>address</b>, ttl: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="base_registry.md#0x0_base_registry_set_record_internal">set_record_internal</a>(
    registry: &<b>mut</b> <a href="base_registry.md#0x0_base_registry_Registry">Registry</a>,
    node: String,
    owner: <b>address</b>,
    <a href="resolver.md#0x0_resolver">resolver</a>: <b>address</b>,
    ttl: u64,
) {
    <b>if</b> (field::exists_with_type&lt;String, <a href="base_registry.md#0x0_base_registry_Record">Record</a>&gt;(&registry.id, node)) {
        <b>let</b> record = field::borrow_mut&lt;String, <a href="base_registry.md#0x0_base_registry_Record">Record</a>&gt;(&<b>mut</b> registry.id, node);
        record.owner = owner;
        record.<a href="resolver.md#0x0_resolver">resolver</a> = <a href="resolver.md#0x0_resolver">resolver</a>;
        record.ttl = ttl;
    } <b>else</b> <a href="base_registry.md#0x0_base_registry_new_record">new_record</a>(registry, node, owner, <a href="resolver.md#0x0_resolver">resolver</a>, ttl);
}
</code></pre>



</details>

<a name="0x0_base_registry_make_node"></a>

## Function `make_node`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="base_registry.md#0x0_base_registry_make_node">make_node</a>(label: <a href="">vector</a>&lt;u8&gt;, base_node: <a href="_String">string::String</a>): <a href="_String">string::String</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="base_registry.md#0x0_base_registry_make_node">make_node</a>(label: <a href="">vector</a>&lt;u8&gt;, base_node: String): String {
    <b>let</b> node = <a href="_utf8">string::utf8</a>(label);
    <a href="_append_utf8">string::append_utf8</a>(&<b>mut</b> node, b".");
    <a href="_append">string::append</a>(&<b>mut</b> node, base_node);
    node
}
</code></pre>



</details>

<a name="0x0_base_registry_init"></a>

## Function `init`



<pre><code><b>fun</b> <a href="base_registry.md#0x0_base_registry_init">init</a>(ctx: &<b>mut</b> <a href="_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="base_registry.md#0x0_base_registry_init">init</a>(ctx: &<b>mut</b> TxContext) {
    <a href="_share_object">transfer::share_object</a>(<a href="base_registry.md#0x0_base_registry_Registry">Registry</a> {
        id: <a href="_new">object::new</a>(ctx),
    });
    <a href="_transfer">transfer::transfer</a>(<a href="base_registry.md#0x0_base_registry_AdminCap">AdminCap</a> {
        id: <a href="_new">object::new</a>(ctx)
    }, sender(ctx));
}
</code></pre>



</details>

<a name="0x0_base_registry_new_record"></a>

## Function `new_record`



<pre><code><b>fun</b> <a href="base_registry.md#0x0_base_registry_new_record">new_record</a>(registry: &<b>mut</b> <a href="base_registry.md#0x0_base_registry_Registry">base_registry::Registry</a>, node: <a href="_String">string::String</a>, owner: <b>address</b>, <a href="resolver.md#0x0_resolver">resolver</a>: <b>address</b>, ttl: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="base_registry.md#0x0_base_registry_new_record">new_record</a>(
    registry: &<b>mut</b> <a href="base_registry.md#0x0_base_registry_Registry">Registry</a>,
    node: String,
    owner: <b>address</b>,
    <a href="resolver.md#0x0_resolver">resolver</a>: <b>address</b>,
    ttl: u64,
) {
    <b>let</b> record = <a href="base_registry.md#0x0_base_registry_Record">Record</a> {
        owner,
        <a href="resolver.md#0x0_resolver">resolver</a>,
        ttl,
    };
    field::add(&<b>mut</b> registry.id, node, record);
}
</code></pre>



</details>
