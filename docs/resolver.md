
<a name="0x0_resolver"></a>

# Module `0x0::resolver`

Default implementation for a resolver module.
Its purpose is to store external data, such as content hash, default name, etc.
Third-party resolvers have to follow the public function specified in this module.


-  [Struct `NameChangedEvent`](#0x0_resolver_NameChangedEvent)
-  [Struct `NameRemovedEvent`](#0x0_resolver_NameRemovedEvent)
-  [Struct `TextRecordChangedEvent`](#0x0_resolver_TextRecordChangedEvent)
-  [Struct `ContenthashChangedEvent`](#0x0_resolver_ContenthashChangedEvent)
-  [Struct `ContenthashRemovedEvent`](#0x0_resolver_ContenthashRemovedEvent)
-  [Struct `AvatarChangedEvent`](#0x0_resolver_AvatarChangedEvent)
-  [Struct `AvatarRemovedEvent`](#0x0_resolver_AvatarRemovedEvent)
-  [Struct `AddrChangedEvent`](#0x0_resolver_AddrChangedEvent)
-  [Resource `BaseResolver`](#0x0_resolver_BaseResolver)
-  [Constants](#@Constants_0)
-  [Function `set_contenthash`](#0x0_resolver_set_contenthash)
-  [Function `unset_contenthash`](#0x0_resolver_unset_contenthash)
-  [Function `set_avatar`](#0x0_resolver_set_avatar)
-  [Function `unset_avatar`](#0x0_resolver_unset_avatar)
-  [Function `set_name`](#0x0_resolver_set_name)
-  [Function `unset_name`](#0x0_resolver_unset_name)
-  [Function `set_text`](#0x0_resolver_set_text)
-  [Function `set_addr`](#0x0_resolver_set_addr)
-  [Function `contenthash`](#0x0_resolver_contenthash)
-  [Function `avatar`](#0x0_resolver_avatar)
-  [Function `name`](#0x0_resolver_name)
-  [Function `text`](#0x0_resolver_text)
-  [Function `addr`](#0x0_resolver_addr)
-  [Function `all_data`](#0x0_resolver_all_data)
-  [Function `init`](#0x0_resolver_init)


<pre><code><b>use</b> <a href="base_registry.md#0x0_base_registry">0x0::base_registry</a>;
<b>use</b> <a href="converter.md#0x0_converter">0x0::converter</a>;
<b>use</b> <a href="">0x1::string</a>;
<b>use</b> <a href="">0x2::dynamic_field</a>;
<b>use</b> <a href="">0x2::event</a>;
<b>use</b> <a href="">0x2::object</a>;
<b>use</b> <a href="">0x2::transfer</a>;
<b>use</b> <a href="">0x2::tx_context</a>;
<b>use</b> <a href="">0x2::vec_map</a>;
</code></pre>



<a name="0x0_resolver_NameChangedEvent"></a>

## Struct `NameChangedEvent`



<pre><code><b>struct</b> <a href="resolver.md#0x0_resolver_NameChangedEvent">NameChangedEvent</a> <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>addr: <b>address</b></code>
</dt>
<dd>

</dd>
<dt>
<code>name: <a href="_String">string::String</a></code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0x0_resolver_NameRemovedEvent"></a>

## Struct `NameRemovedEvent`



<pre><code><b>struct</b> <a href="resolver.md#0x0_resolver_NameRemovedEvent">NameRemovedEvent</a> <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>addr: <b>address</b></code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0x0_resolver_TextRecordChangedEvent"></a>

## Struct `TextRecordChangedEvent`



<pre><code><b>struct</b> <a href="resolver.md#0x0_resolver_TextRecordChangedEvent">TextRecordChangedEvent</a> <b>has</b> <b>copy</b>, drop
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
<code>key: <a href="_String">string::String</a></code>
</dt>
<dd>

</dd>
<dt>
<code>value: <a href="_String">string::String</a></code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0x0_resolver_ContenthashChangedEvent"></a>

## Struct `ContenthashChangedEvent`



<pre><code><b>struct</b> <a href="resolver.md#0x0_resolver_ContenthashChangedEvent">ContenthashChangedEvent</a> <b>has</b> <b>copy</b>, drop
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
<code>contenthash: <a href="_String">string::String</a></code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0x0_resolver_ContenthashRemovedEvent"></a>

## Struct `ContenthashRemovedEvent`



<pre><code><b>struct</b> <a href="resolver.md#0x0_resolver_ContenthashRemovedEvent">ContenthashRemovedEvent</a> <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>node: <a href="_String">string::String</a></code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0x0_resolver_AvatarChangedEvent"></a>

## Struct `AvatarChangedEvent`



<pre><code><b>struct</b> <a href="resolver.md#0x0_resolver_AvatarChangedEvent">AvatarChangedEvent</a> <b>has</b> <b>copy</b>, drop
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
<code>avatar: <a href="_String">string::String</a></code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0x0_resolver_AvatarRemovedEvent"></a>

## Struct `AvatarRemovedEvent`



<pre><code><b>struct</b> <a href="resolver.md#0x0_resolver_AvatarRemovedEvent">AvatarRemovedEvent</a> <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>node: <a href="_String">string::String</a></code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0x0_resolver_AddrChangedEvent"></a>

## Struct `AddrChangedEvent`



<pre><code><b>struct</b> <a href="resolver.md#0x0_resolver_AddrChangedEvent">AddrChangedEvent</a> <b>has</b> <b>copy</b>, drop
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
<code>addr: <a href="_String">string::String</a></code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0x0_resolver_BaseResolver"></a>

## Resource `BaseResolver`

Mapping domain name to its VecMap resources.
Each record is a dynamic field of this share object,.
Records's format:
'suins.sui': {
'contenthash': 'QmNZiPk974vDsPmQii3YbrMKfi12KTSNM7XMiYyiea4VYZ',
'addr': 'abc123',
'avatar': 'QmfWrgbTZqwzqsvdeNc3NKacggMuTaN83sQ8V7Bs2nXKRD',
'key': 'abc',
},
'ab123.addr.reverse': {
'name': 'suins.sui',
}


<pre><code><b>struct</b> <a href="resolver.md#0x0_resolver_BaseResolver">BaseResolver</a> <b>has</b> key
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


<a name="0x0_resolver_ADDR"></a>



<pre><code><b>const</b> <a href="resolver.md#0x0_resolver_ADDR">ADDR</a>: <a href="">vector</a>&lt;u8&gt; = [97, 100, 100, 114];
</code></pre>



<a name="0x0_resolver_ADDR_REVERSE_BASE_NODE"></a>



<pre><code><b>const</b> <a href="resolver.md#0x0_resolver_ADDR_REVERSE_BASE_NODE">ADDR_REVERSE_BASE_NODE</a>: <a href="">vector</a>&lt;u8&gt; = [97, 100, 100, 114, 46, 114, 101, 118, 101, 114, 115, 101];
</code></pre>



<a name="0x0_resolver_AVATAR"></a>



<pre><code><b>const</b> <a href="resolver.md#0x0_resolver_AVATAR">AVATAR</a>: <a href="">vector</a>&lt;u8&gt; = [97, 118, 97, 116, 97, 114];
</code></pre>



<a name="0x0_resolver_CONTENTHASH"></a>



<pre><code><b>const</b> <a href="resolver.md#0x0_resolver_CONTENTHASH">CONTENTHASH</a>: <a href="">vector</a>&lt;u8&gt; = [99, 111, 110, 116, 101, 110, 116, 104, 97, 115, 104];
</code></pre>



<a name="0x0_resolver_EInvalidKey"></a>



<pre><code><b>const</b> <a href="resolver.md#0x0_resolver_EInvalidKey">EInvalidKey</a>: u64 = 701;
</code></pre>



<a name="0x0_resolver_NAME"></a>



<pre><code><b>const</b> <a href="resolver.md#0x0_resolver_NAME">NAME</a>: <a href="">vector</a>&lt;u8&gt; = [110, 97, 109, 101];
</code></pre>



<a name="0x0_resolver_set_contenthash"></a>

## Function `set_contenthash`


<a name="@Notice_1"></a>

###### Notice

This funtions allows owner of <code>node</code> to set content hash url.


<a name="@Dev_2"></a>

###### Dev

Create 'contenthash' key if not exist.
<code><a href="">hash</a></code> isn't validated.


<a name="@Params_3"></a>

###### Params

<code>node</code>: node to be updated
<code><a href="">hash</a></code>: content hash url

Panics
Panics if caller isn't the owner of <code>node</code>


<pre><code><b>public</b> entry <b>fun</b> <a href="resolver.md#0x0_resolver_set_contenthash">set_contenthash</a>(base_resolver: &<b>mut</b> <a href="resolver.md#0x0_resolver_BaseResolver">resolver::BaseResolver</a>, registry: &<a href="base_registry.md#0x0_base_registry_Registry">base_registry::Registry</a>, node: <a href="">vector</a>&lt;u8&gt;, <a href="">hash</a>: <a href="">vector</a>&lt;u8&gt;, ctx: &<b>mut</b> <a href="_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="resolver.md#0x0_resolver_set_contenthash">set_contenthash</a>(
    base_resolver: &<b>mut</b> <a href="resolver.md#0x0_resolver_BaseResolver">BaseResolver</a>,
    registry: &Registry,
    node: <a href="">vector</a>&lt;u8&gt;,
    <a href="">hash</a>: <a href="">vector</a>&lt;u8&gt;,
    ctx: &<b>mut</b> TxContext
) {
    <a href="base_registry.md#0x0_base_registry_authorised">base_registry::authorised</a>(registry, node, ctx);
    <b>let</b> node = utf8(node);
    <b>let</b> new_hash = utf8(<a href="">hash</a>);
    <b>let</b> key = utf8(<a href="resolver.md#0x0_resolver_CONTENTHASH">CONTENTHASH</a>);

    <b>if</b> (field::exists_with_type&lt;String, VecMap&lt;String, String&gt;&gt;(&base_resolver.id, node)) {
        <b>let</b> record = field::borrow_mut&lt;String, VecMap&lt;String, String&gt;&gt;(&<b>mut</b> base_resolver.id, node);
        <b>if</b> (<a href="_contains">vec_map::contains</a>(record, &key)) {
            // `node` and `contenthash` exist
            <b>let</b> current_contenthash = <a href="_get_mut">vec_map::get_mut</a>(record, &key);
            *current_contenthash = new_hash;
        } <b>else</b> {
            // `node` <b>exists</b> but `contenthash` doesn't
            <a href="_insert">vec_map::insert</a>(record, key, new_hash);
        }
    } <b>else</b> {
        // `node` not exist
        <b>let</b> new_record = <a href="_empty">vec_map::empty</a>&lt;String, String&gt;();
        <a href="_insert">vec_map::insert</a>(&<b>mut</b> new_record, key, new_hash);
        field::add(&<b>mut</b> base_resolver.id, node, new_record);
    };

    <a href="_emit">event::emit</a>(<a href="resolver.md#0x0_resolver_ContenthashChangedEvent">ContenthashChangedEvent</a> { node, contenthash: new_hash });
}
</code></pre>



</details>

<a name="0x0_resolver_unset_contenthash"></a>

## Function `unset_contenthash`


<a name="@Notice_4"></a>

###### Notice

This funtions allows owner of <code>node</code> to unset content hash url.


<a name="@Params_5"></a>

###### Params

<code>node</code>: node to be updated

Panics
Panics if caller isn't the owner of <code>node</code>
or <code>node</code> doesn't exist.


<pre><code><b>public</b> entry <b>fun</b> <a href="resolver.md#0x0_resolver_unset_contenthash">unset_contenthash</a>(base_resolver: &<b>mut</b> <a href="resolver.md#0x0_resolver_BaseResolver">resolver::BaseResolver</a>, registry: &<a href="base_registry.md#0x0_base_registry_Registry">base_registry::Registry</a>, node: <a href="">vector</a>&lt;u8&gt;, ctx: &<b>mut</b> <a href="_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="resolver.md#0x0_resolver_unset_contenthash">unset_contenthash</a>(
    base_resolver: &<b>mut</b> <a href="resolver.md#0x0_resolver_BaseResolver">BaseResolver</a>,
    registry: &Registry,
    node: <a href="">vector</a>&lt;u8&gt;,
    ctx: &<b>mut</b> TxContext
) {
    <a href="base_registry.md#0x0_base_registry_authorised">base_registry::authorised</a>(registry, node, ctx);

    <b>let</b> node = utf8(node);
    <b>let</b> record = field::borrow_mut&lt;String, VecMap&lt;String, String&gt;&gt;(&<b>mut</b> base_resolver.id, node);
    <a href="_remove">vec_map::remove</a>(record, &utf8(<a href="resolver.md#0x0_resolver_CONTENTHASH">CONTENTHASH</a>));
    <a href="_emit">event::emit</a>(<a href="resolver.md#0x0_resolver_ContenthashRemovedEvent">ContenthashRemovedEvent</a> { node });
}
</code></pre>



</details>

<a name="0x0_resolver_set_avatar"></a>

## Function `set_avatar`


<a name="@Notice_6"></a>

###### Notice

This funtions allows owner of <code>node</code> to set avatar url.


<a name="@Dev_7"></a>

###### Dev

Create 'avatar' key if not exist.


<a name="@Params_8"></a>

###### Params

<code>node</code>: node to be updated
<code>avatar</code>: avatar url

Panics
Panics if caller isn't the owner of <code>node</code>


<pre><code><b>public</b> entry <b>fun</b> <a href="resolver.md#0x0_resolver_set_avatar">set_avatar</a>(base_resolver: &<b>mut</b> <a href="resolver.md#0x0_resolver_BaseResolver">resolver::BaseResolver</a>, registry: &<a href="base_registry.md#0x0_base_registry_Registry">base_registry::Registry</a>, node: <a href="">vector</a>&lt;u8&gt;, <a href="">hash</a>: <a href="">vector</a>&lt;u8&gt;, ctx: &<b>mut</b> <a href="_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="resolver.md#0x0_resolver_set_avatar">set_avatar</a>(
    base_resolver: &<b>mut</b> <a href="resolver.md#0x0_resolver_BaseResolver">BaseResolver</a>,
    registry: &Registry,
    node: <a href="">vector</a>&lt;u8&gt;,
    <a href="">hash</a>: <a href="">vector</a>&lt;u8&gt;,
    ctx: &<b>mut</b> TxContext
) {
    // TODO: group avatar, contenthash,... into 1 function
    <a href="base_registry.md#0x0_base_registry_authorised">base_registry::authorised</a>(registry, node, ctx);
    <b>let</b> node = utf8(node);
    <b>let</b> new_hash = utf8(<a href="">hash</a>);
    <b>let</b> key = utf8(<a href="resolver.md#0x0_resolver_AVATAR">AVATAR</a>);

    <b>if</b> (field::exists_with_type&lt;String, VecMap&lt;String, String&gt;&gt;(&base_resolver.id, node)) {
        <b>let</b> record = field::borrow_mut&lt;String, VecMap&lt;String, String&gt;&gt;(&<b>mut</b> base_resolver.id, node);
        <b>if</b> (<a href="_contains">vec_map::contains</a>(record, &key)) {
            // `node` and `contenthash` exist
            <b>let</b> current_contenthash = <a href="_get_mut">vec_map::get_mut</a>(record, &key);
            *current_contenthash = new_hash;
        } <b>else</b> {
            // `node` <b>exists</b> but `avatar` doesn't
            <a href="_insert">vec_map::insert</a>(record, key, new_hash);
        }
    } <b>else</b> {
        // `node` not exist
        <b>let</b> new_record = <a href="_empty">vec_map::empty</a>&lt;String, String&gt;();
        <a href="_insert">vec_map::insert</a>(&<b>mut</b> new_record, key, new_hash);
        field::add(&<b>mut</b> base_resolver.id, node, new_record);
    };

    <a href="_emit">event::emit</a>(<a href="resolver.md#0x0_resolver_ContenthashChangedEvent">ContenthashChangedEvent</a> { node, contenthash: new_hash });
}
</code></pre>



</details>

<a name="0x0_resolver_unset_avatar"></a>

## Function `unset_avatar`


<a name="@Notice_9"></a>

###### Notice

This funtions allows owner of <code>node</code> to unset avatar url.


<a name="@Params_10"></a>

###### Params

<code>node</code>: node to be updated

Panics
Panics if caller isn't the owner of <code>node</code>
or <code>node</code> doesn't exist.


<pre><code><b>public</b> entry <b>fun</b> <a href="resolver.md#0x0_resolver_unset_avatar">unset_avatar</a>(base_resolver: &<b>mut</b> <a href="resolver.md#0x0_resolver_BaseResolver">resolver::BaseResolver</a>, registry: &<a href="base_registry.md#0x0_base_registry_Registry">base_registry::Registry</a>, node: <a href="">vector</a>&lt;u8&gt;, ctx: &<b>mut</b> <a href="_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="resolver.md#0x0_resolver_unset_avatar">unset_avatar</a>(
    base_resolver: &<b>mut</b> <a href="resolver.md#0x0_resolver_BaseResolver">BaseResolver</a>,
    registry: &Registry,
    node: <a href="">vector</a>&lt;u8&gt;,
    ctx: &<b>mut</b> TxContext
) {
    <a href="base_registry.md#0x0_base_registry_authorised">base_registry::authorised</a>(registry, node, ctx);

    <b>let</b> node = utf8(node);
    <b>let</b> record = field::borrow_mut&lt;String, VecMap&lt;String, String&gt;&gt;(&<b>mut</b> base_resolver.id, node);
    <a href="_remove">vec_map::remove</a>(record, &utf8(<a href="resolver.md#0x0_resolver_AVATAR">AVATAR</a>));
    <a href="_emit">event::emit</a>(<a href="resolver.md#0x0_resolver_AvatarRemovedEvent">AvatarRemovedEvent</a> { node });
}
</code></pre>



</details>

<a name="0x0_resolver_set_name"></a>

## Function `set_name`


<a name="@Notice_11"></a>

###### Notice

This funtions allows owner of <code>sender_addr.addr.reverse</code> to set default domain name which is mapped to the sender address.
The node is identified by the sender address with format: <code>sender_addr</code>.addr.reverse.


<a name="@Dev_12"></a>

###### Dev

Create 'name' key if not exist.
<code>new_name</code> isn't validated.


<a name="@Params_13"></a>

###### Params

<code>node</code>: node to be updated
<code>new_name</code>: new domain name to be set

Panics
Panics if caller isn't the owner of <code>sender_addr</code>.addr.reverse.


<pre><code><b>public</b> entry <b>fun</b> <a href="resolver.md#0x0_resolver_set_name">set_name</a>(base_resolver: &<b>mut</b> <a href="resolver.md#0x0_resolver_BaseResolver">resolver::BaseResolver</a>, registry: &<a href="base_registry.md#0x0_base_registry_Registry">base_registry::Registry</a>, addr: <b>address</b>, new_name: <a href="">vector</a>&lt;u8&gt;, ctx: &<b>mut</b> <a href="_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="resolver.md#0x0_resolver_set_name">set_name</a>(
    base_resolver: &<b>mut</b> <a href="resolver.md#0x0_resolver_BaseResolver">BaseResolver</a>,
    registry: &Registry,
    addr: <b>address</b>,
    new_name: <a href="">vector</a>&lt;u8&gt;,
    ctx: &<b>mut</b> TxContext
) {
    <b>let</b> label = <a href="converter.md#0x0_converter_address_to_string">converter::address_to_string</a>(addr);
    <b>let</b> node = <a href="base_registry.md#0x0_base_registry_make_node">base_registry::make_node</a>(label, utf8(<a href="resolver.md#0x0_resolver_ADDR_REVERSE_BASE_NODE">ADDR_REVERSE_BASE_NODE</a>));
    // TODO: do we have <b>to</b> authorised this?
    <a href="base_registry.md#0x0_base_registry_authorised">base_registry::authorised</a>(registry, *<a href="_bytes">string::bytes</a>(&node), ctx);

    <b>let</b> new_name = utf8(new_name);
    <b>let</b> key = utf8(<a href="resolver.md#0x0_resolver_NAME">NAME</a>);

    <b>if</b> (field::exists_with_type&lt;String, VecMap&lt;String, String&gt;&gt;(&base_resolver.id, node)) {
        <b>let</b> record = field::borrow_mut&lt;String, VecMap&lt;String, String&gt;&gt;(&<b>mut</b> base_resolver.id, node);
        <b>if</b> (<a href="_contains">vec_map::contains</a>(record, &key)) {
            // `node` and `name` exist
            <b>let</b> current_name = <a href="_get_mut">vec_map::get_mut</a>(record, &key);
            *current_name = new_name;
        } <b>else</b> {
            // `node` <b>exists</b> but `name` doesn't
            <a href="_insert">vec_map::insert</a>(record, key, new_name);
        }
    } <b>else</b> {
        // `node` not exist
        <b>let</b> new_record = <a href="_empty">vec_map::empty</a>&lt;String, String&gt;();
        <a href="_insert">vec_map::insert</a>(&<b>mut</b> new_record, key, new_name);
        field::add(&<b>mut</b> base_resolver.id, node, new_record);
    };

    <a href="_emit">event::emit</a>(<a href="resolver.md#0x0_resolver_NameChangedEvent">NameChangedEvent</a> { addr, name: new_name });
}
</code></pre>



</details>

<a name="0x0_resolver_unset_name"></a>

## Function `unset_name`


<a name="@Notice_14"></a>

###### Notice

This funtions allows owner of <code>addr</code>.addr.reverse to unset default name.


<a name="@Params_15"></a>

###### Params

<code>addr</code>: node to be unset with format <code>addr</code>.addr.reverse.

Panics
Panics if caller isn't the owner of <code>node</code>
or <code>addr</code>.addr.reverse doesn't exist.


<pre><code><b>public</b> entry <b>fun</b> <a href="resolver.md#0x0_resolver_unset_name">unset_name</a>(base_resolver: &<b>mut</b> <a href="resolver.md#0x0_resolver_BaseResolver">resolver::BaseResolver</a>, registry: &<a href="base_registry.md#0x0_base_registry_Registry">base_registry::Registry</a>, addr: <b>address</b>, ctx: &<b>mut</b> <a href="_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="resolver.md#0x0_resolver_unset_name">unset_name</a>(
    base_resolver: &<b>mut</b> <a href="resolver.md#0x0_resolver_BaseResolver">BaseResolver</a>,
    registry: &Registry,
    addr: <b>address</b>,
    ctx: &<b>mut</b> TxContext
) {
    <b>let</b> label = <a href="converter.md#0x0_converter_address_to_string">converter::address_to_string</a>(addr);
    <b>let</b> node = <a href="base_registry.md#0x0_base_registry_make_node">base_registry::make_node</a>(label, utf8(<a href="resolver.md#0x0_resolver_ADDR_REVERSE_BASE_NODE">ADDR_REVERSE_BASE_NODE</a>));
    <a href="base_registry.md#0x0_base_registry_authorised">base_registry::authorised</a>(registry, *<a href="_bytes">string::bytes</a>(&node), ctx);
    <b>let</b> record = field::borrow_mut(&<b>mut</b> base_resolver.id, node);
    <a href="_remove">vec_map::remove</a>&lt;String, String&gt;(record, &utf8(<a href="resolver.md#0x0_resolver_NAME">NAME</a>));

    <a href="_emit">event::emit</a>(<a href="resolver.md#0x0_resolver_NameRemovedEvent">NameRemovedEvent</a> { addr });
}
</code></pre>



</details>

<a name="0x0_resolver_set_text"></a>

## Function `set_text`


<a name="@Notice_16"></a>

###### Notice

This funtions allows owner of <code>node</code> to set text record.
Text record is an object.


<a name="@Params_17"></a>

###### Params

<code>node</code>: node to be updated
<code>key</code>: key of text record object
<code>new_value</code>: new value for the key

Panics
Panics if caller isn't the owner of <code>node</code>


<pre><code><b>public</b> entry <b>fun</b> <a href="resolver.md#0x0_resolver_set_text">set_text</a>(base_resolver: &<b>mut</b> <a href="resolver.md#0x0_resolver_BaseResolver">resolver::BaseResolver</a>, registry: &<a href="base_registry.md#0x0_base_registry_Registry">base_registry::Registry</a>, node: <a href="">vector</a>&lt;u8&gt;, key: <a href="">vector</a>&lt;u8&gt;, new_value: <a href="">vector</a>&lt;u8&gt;, ctx: &<b>mut</b> <a href="_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="resolver.md#0x0_resolver_set_text">set_text</a>(
    base_resolver: &<b>mut</b> <a href="resolver.md#0x0_resolver_BaseResolver">BaseResolver</a>,
    registry: &Registry,
    node: <a href="">vector</a>&lt;u8&gt;,
    key: <a href="">vector</a>&lt;u8&gt;,
    new_value: <a href="">vector</a>&lt;u8&gt;,
    ctx: &<b>mut</b> TxContext
) {
    <b>assert</b>!(key != <a href="resolver.md#0x0_resolver_CONTENTHASH">CONTENTHASH</a> && key != <a href="resolver.md#0x0_resolver_ADDR">ADDR</a> && key != <a href="resolver.md#0x0_resolver_AVATAR">AVATAR</a> && key != <a href="resolver.md#0x0_resolver_NAME">NAME</a>, <a href="resolver.md#0x0_resolver_EInvalidKey">EInvalidKey</a>);
    // TODO: we don't have unset_text function
    <a href="base_registry.md#0x0_base_registry_authorised">base_registry::authorised</a>(registry, node, ctx);
    <b>let</b> node = utf8(node);
    <b>let</b> new_value = utf8(new_value);
    <b>let</b> key = utf8(key);

    <b>if</b> (field::exists_with_type&lt;String, VecMap&lt;String, String&gt;&gt;(&base_resolver.id, node)) {
        <b>let</b> record = field::borrow_mut&lt;String, VecMap&lt;String, String&gt;&gt;(&<b>mut</b> base_resolver.id, node);
        <b>if</b> (<a href="_contains">vec_map::contains</a>(record, &key)) {
            // `node` and `key` exist
            <b>let</b> current_value = <a href="_get_mut">vec_map::get_mut</a>(record, &key);
            *current_value = new_value;
        } <b>else</b> {
            // `node` <b>exists</b> but `key` doesn't
            <a href="_insert">vec_map::insert</a>(record, key, new_value);
        }
    } <b>else</b> {
        // `node` not exist
        <b>let</b> new_record = <a href="_empty">vec_map::empty</a>&lt;String, String&gt;();
        <a href="_insert">vec_map::insert</a>(&<b>mut</b> new_record, key, new_value);
        field::add(&<b>mut</b> base_resolver.id, node, new_record);
    };

    <a href="_emit">event::emit</a>(<a href="resolver.md#0x0_resolver_TextRecordChangedEvent">TextRecordChangedEvent</a> { node, key, value: new_value });
}
</code></pre>



</details>

<a name="0x0_resolver_set_addr"></a>

## Function `set_addr`


<a name="@Notice_18"></a>

###### Notice

This funtions allows owner of <code>node</code> to set default addr.


<a name="@Params_19"></a>

###### Params

<code>node</code>: node to be updated
<code>new_addr</code>: new address value

Panics
Panics if caller isn't the owner of <code>node</code>


<pre><code><b>public</b> entry <b>fun</b> <a href="resolver.md#0x0_resolver_set_addr">set_addr</a>(base_resolver: &<b>mut</b> <a href="resolver.md#0x0_resolver_BaseResolver">resolver::BaseResolver</a>, registry: &<a href="base_registry.md#0x0_base_registry_Registry">base_registry::Registry</a>, node: <a href="">vector</a>&lt;u8&gt;, new_addr: <b>address</b>, ctx: &<b>mut</b> <a href="_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="resolver.md#0x0_resolver_set_addr">set_addr</a>(
    base_resolver: &<b>mut</b> <a href="resolver.md#0x0_resolver_BaseResolver">BaseResolver</a>,
    registry: &Registry,
    node: <a href="">vector</a>&lt;u8&gt;,
    new_addr: <b>address</b>,
    ctx: &<b>mut</b> TxContext
) {
    // TODO: we don't have unset_addr function
    <a href="base_registry.md#0x0_base_registry_authorised">base_registry::authorised</a>(registry, node, ctx);
    <b>let</b> node = utf8(node);
    <b>let</b> key = utf8(<a href="resolver.md#0x0_resolver_ADDR">ADDR</a>);
    <b>let</b> new_addr = utf8(<a href="converter.md#0x0_converter_address_to_string">converter::address_to_string</a>(new_addr));

    <b>if</b> (field::exists_with_type&lt;String, VecMap&lt;String, String&gt;&gt;(&base_resolver.id, node)) {
        <b>let</b> record = field::borrow_mut&lt;String, VecMap&lt;String, String&gt;&gt;(&<b>mut</b> base_resolver.id, node);
        <b>if</b> (<a href="_contains">vec_map::contains</a>(record, &key)) {
            <b>let</b> current_addr = <a href="_get_mut">vec_map::get_mut</a>(record, &key);
            *current_addr = new_addr;
        } <b>else</b> {
            // `node` <b>exists</b> but `key` doesn't
            <a href="_insert">vec_map::insert</a>(record, key, new_addr);
        }
    } <b>else</b> {
        <b>let</b> new_record = <a href="_empty">vec_map::empty</a>&lt;String, String&gt;();
        <a href="_insert">vec_map::insert</a>(&<b>mut</b> new_record, key, new_addr);
        field::add(&<b>mut</b> base_resolver.id, node, new_record);
    };

    <a href="_emit">event::emit</a>(<a href="resolver.md#0x0_resolver_AddrChangedEvent">AddrChangedEvent</a> { node, addr: new_addr });
}
</code></pre>



</details>

<a name="0x0_resolver_contenthash"></a>

## Function `contenthash`


<a name="@Notice_20"></a>

###### Notice

Get content hash of a <code>node</code>.


<a name="@Dev_21"></a>

###### Dev

Returns empty string if <code>node</code> or <code>contenthash</code> key doesn't exist.


<a name="@Params_22"></a>

###### Params

<code>node</code>: node to find the content hash


<pre><code><b>public</b> <b>fun</b> <a href="resolver.md#0x0_resolver_contenthash">contenthash</a>(base_resolver: &<a href="resolver.md#0x0_resolver_BaseResolver">resolver::BaseResolver</a>, node: <a href="">vector</a>&lt;u8&gt;): <a href="_String">string::String</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="resolver.md#0x0_resolver_contenthash">contenthash</a>(base_resolver: &<a href="resolver.md#0x0_resolver_BaseResolver">BaseResolver</a>, node: <a href="">vector</a>&lt;u8&gt;): String {
    <b>let</b> key = utf8(<a href="resolver.md#0x0_resolver_CONTENTHASH">CONTENTHASH</a>);
    <b>let</b> node = utf8(node);

    <b>if</b> (field::exists_with_type&lt;String, VecMap&lt;String, String&gt;&gt;(&base_resolver.id, node)) {
        <b>let</b> record = field::borrow&lt;String, VecMap&lt;String, String&gt;&gt;(&base_resolver.id, node);
        <b>if</b> (<a href="_contains">vec_map::contains</a>(record, &key)) {
            <b>return</b> *<a href="_get">vec_map::get</a>(record, &key)
        };
    };
    utf8(b"")
}
</code></pre>



</details>

<a name="0x0_resolver_avatar"></a>

## Function `avatar`


<a name="@Notice_23"></a>

###### Notice

Get avatar of a <code>node</code>.


<a name="@Dev_24"></a>

###### Dev

Returns empty string if <code>node</code> or <code>avatar</code> key doesn't exist.


<a name="@Params_25"></a>

###### Params

<code>node</code>: node to find the content hash


<pre><code><b>public</b> <b>fun</b> <a href="resolver.md#0x0_resolver_avatar">avatar</a>(base_resolver: &<a href="resolver.md#0x0_resolver_BaseResolver">resolver::BaseResolver</a>, node: <a href="">vector</a>&lt;u8&gt;): <a href="_String">string::String</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="resolver.md#0x0_resolver_avatar">avatar</a>(base_resolver: &<a href="resolver.md#0x0_resolver_BaseResolver">BaseResolver</a>, node: <a href="">vector</a>&lt;u8&gt;): String {
    <b>let</b> key = utf8(<a href="resolver.md#0x0_resolver_AVATAR">AVATAR</a>);
    <b>let</b> node = utf8(node);

    <b>if</b> (field::exists_with_type&lt;String, VecMap&lt;String, String&gt;&gt;(&base_resolver.id, node)) {
        <b>let</b> record = field::borrow&lt;String, VecMap&lt;String, String&gt;&gt;(&base_resolver.id, node);
        <b>if</b> (<a href="_contains">vec_map::contains</a>(record, &key)) {
            <b>return</b> *<a href="_get">vec_map::get</a>(record, &key)
        };
    };
    utf8(b"")
}
</code></pre>



</details>

<a name="0x0_resolver_name"></a>

## Function `name`


<a name="@Notice_26"></a>

###### Notice

Get default name of a <code>node</code>.


<a name="@Dev_27"></a>

###### Dev

Returns empty string if <code>node</code> or <code>name</code> key doesn't exist.


<a name="@Params_28"></a>

###### Params

<code>node</code>: node to find the default name


<pre><code><b>public</b> <b>fun</b> <a href="resolver.md#0x0_resolver_name">name</a>(base_resolver: &<a href="resolver.md#0x0_resolver_BaseResolver">resolver::BaseResolver</a>, addr: <b>address</b>): <a href="_String">string::String</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="resolver.md#0x0_resolver_name">name</a>(base_resolver: &<a href="resolver.md#0x0_resolver_BaseResolver">BaseResolver</a>, addr: <b>address</b>): String {
    <b>let</b> label = <a href="converter.md#0x0_converter_address_to_string">converter::address_to_string</a>(addr);
    <b>let</b> node = <a href="base_registry.md#0x0_base_registry_make_node">base_registry::make_node</a>(label, utf8(<a href="resolver.md#0x0_resolver_ADDR_REVERSE_BASE_NODE">ADDR_REVERSE_BASE_NODE</a>));
    <b>let</b> key = utf8(<a href="resolver.md#0x0_resolver_NAME">NAME</a>);

    <b>if</b> (field::exists_with_type&lt;String, VecMap&lt;String, String&gt;&gt;(&base_resolver.id, node)) {
        <b>let</b> record = field::borrow&lt;String, VecMap&lt;String, String&gt;&gt;(&base_resolver.id, node);
        <b>if</b> (<a href="_contains">vec_map::contains</a>(record, &key)) {
            <b>return</b> *<a href="_get">vec_map::get</a>(record, &key)
        };
    };
    utf8(b"")
}
</code></pre>



</details>

<a name="0x0_resolver_text"></a>

## Function `text`


<a name="@Notice_29"></a>

###### Notice

Get value of a key in text record object.


<a name="@Dev_30"></a>

###### Dev

Returns empty string if not exists.


<a name="@Params_31"></a>

###### Params

<code>node</code>: node to find the text record key.


<pre><code><b>public</b> <b>fun</b> <a href="resolver.md#0x0_resolver_text">text</a>(base_resolver: &<a href="resolver.md#0x0_resolver_BaseResolver">resolver::BaseResolver</a>, node: <a href="">vector</a>&lt;u8&gt;, key: <a href="">vector</a>&lt;u8&gt;): <a href="_String">string::String</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="resolver.md#0x0_resolver_text">text</a>(base_resolver: &<a href="resolver.md#0x0_resolver_BaseResolver">BaseResolver</a>, node: <a href="">vector</a>&lt;u8&gt;, key: <a href="">vector</a>&lt;u8&gt;): String {
    <b>let</b> key = utf8(key);
    <b>let</b> node = utf8(node);

    <b>if</b> (field::exists_with_type&lt;String, VecMap&lt;String, String&gt;&gt;(&base_resolver.id, node)) {
        <b>let</b> record = field::borrow&lt;String, VecMap&lt;String, String&gt;&gt;(&base_resolver.id, node);
        <b>if</b> (<a href="_contains">vec_map::contains</a>(record, &key)) {
            <b>return</b> *<a href="_get">vec_map::get</a>(record, &key)
        };
    };
    utf8(b"")
}
</code></pre>



</details>

<a name="0x0_resolver_addr"></a>

## Function `addr`


<a name="@Notice_32"></a>

###### Notice

Get <code>addr</code> of a <code>node</code>.


<a name="@Dev_33"></a>

###### Dev

Returns @0x0 address if not exists.


<a name="@Params_34"></a>

###### Params

<code>node</code>: node to find the default addr.


<pre><code><b>public</b> <b>fun</b> <a href="resolver.md#0x0_resolver_addr">addr</a>(base_resolver: &<a href="resolver.md#0x0_resolver_BaseResolver">resolver::BaseResolver</a>, node: <a href="">vector</a>&lt;u8&gt;): <a href="_String">string::String</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="resolver.md#0x0_resolver_addr">addr</a>(base_resolver: &<a href="resolver.md#0x0_resolver_BaseResolver">BaseResolver</a>, node: <a href="">vector</a>&lt;u8&gt;): String {
    <b>let</b> node = utf8(node);
    <b>let</b> key = utf8(<a href="resolver.md#0x0_resolver_ADDR">ADDR</a>);

    <b>if</b> (field::exists_with_type&lt;String, VecMap&lt;String, String&gt;&gt;(&base_resolver.id, node)) {
        <b>let</b> record = field::borrow&lt;String, VecMap&lt;String, String&gt;&gt;(&base_resolver.id, node);
        <b>if</b> (<a href="_contains">vec_map::contains</a>(record, &key)) {
            <b>return</b> *<a href="_get">vec_map::get</a>(record, &key)
        };
    };
    utf8(b"")
}
</code></pre>



</details>

<a name="0x0_resolver_all_data"></a>

## Function `all_data`


<a name="@Notice_35"></a>

###### Notice

Get <code>(contenthash, addr, avatar, name)</code> of a <code>node</code>.


<a name="@Dev_36"></a>

###### Dev

Returns empty string and @0x0 address if not exists.


<a name="@Params_37"></a>

###### Params

<code>node</code>: node to find the data.


<pre><code><b>public</b> <b>fun</b> <a href="resolver.md#0x0_resolver_all_data">all_data</a>(base_resolver: &<a href="resolver.md#0x0_resolver_BaseResolver">resolver::BaseResolver</a>, node: <a href="">vector</a>&lt;u8&gt;): (<a href="_String">string::String</a>, <a href="_String">string::String</a>, <a href="_String">string::String</a>, <a href="_String">string::String</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="resolver.md#0x0_resolver_all_data">all_data</a>(
    base_resolver: &<a href="resolver.md#0x0_resolver_BaseResolver">BaseResolver</a>,
    node: <a href="">vector</a>&lt;u8&gt;,
): (String, String, String, String) {
    <b>let</b> empty_str = utf8(b"");
    <b>let</b> node = utf8(node);

    <b>if</b> (field::exists_with_type&lt;String, VecMap&lt;String, String&gt;&gt;(&base_resolver.id, node)) {
        <b>let</b> record = field::borrow&lt;String, VecMap&lt;String, String&gt;&gt;(&base_resolver.id, node);

        <b>let</b> contenthash = empty_str;
        <b>if</b> (<a href="_contains">vec_map::contains</a>(record, &utf8(<a href="resolver.md#0x0_resolver_CONTENTHASH">CONTENTHASH</a>))) {
            contenthash = *<a href="_get">vec_map::get</a>(record, &utf8(<a href="resolver.md#0x0_resolver_CONTENTHASH">CONTENTHASH</a>));
        };

        <b>let</b> addr = empty_str;
        <b>if</b> (<a href="_contains">vec_map::contains</a>(record, &utf8(<a href="resolver.md#0x0_resolver_ADDR">ADDR</a>))) {
            addr = *<a href="_get">vec_map::get</a>(record, &utf8(<a href="resolver.md#0x0_resolver_ADDR">ADDR</a>));
        };

        <b>let</b> avatar = empty_str;
        <b>if</b> (<a href="_contains">vec_map::contains</a>(record, &utf8(<a href="resolver.md#0x0_resolver_AVATAR">AVATAR</a>))) {
            avatar = *<a href="_get">vec_map::get</a>(record, &utf8(<a href="resolver.md#0x0_resolver_AVATAR">AVATAR</a>));
        };

        <b>let</b> name = empty_str;
        <b>if</b> (<a href="_contains">vec_map::contains</a>(record, &utf8(<a href="resolver.md#0x0_resolver_NAME">NAME</a>))) {
            name = *<a href="_get">vec_map::get</a>(record, &utf8(<a href="resolver.md#0x0_resolver_NAME">NAME</a>));
        };
        <b>return</b> (contenthash, addr, avatar, name)
    };
    (empty_str, empty_str, empty_str, empty_str)
}
</code></pre>



</details>

<a name="0x0_resolver_init"></a>

## Function `init`



<pre><code><b>fun</b> <a href="resolver.md#0x0_resolver_init">init</a>(ctx: &<b>mut</b> <a href="_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="resolver.md#0x0_resolver_init">init</a>(ctx: &<b>mut</b> TxContext) {
    <a href="_share_object">transfer::share_object</a>(<a href="resolver.md#0x0_resolver_BaseResolver">BaseResolver</a> {
        id: <a href="_new">object::new</a>(ctx),
    });
}
</code></pre>



</details>
