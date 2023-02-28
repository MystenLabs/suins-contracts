
<a name="0x0_reverse_registrar"></a>

# Module `0x0::reverse_registrar`

Use for reverse domains in the form of "123abc.addr.reverse"
This kind of domains are needed to get default name,...


-  [Struct `ReverseClaimedEvent`](#0x0_reverse_registrar_ReverseClaimedEvent)
-  [Struct `DefaultResolverChangedEvent`](#0x0_reverse_registrar_DefaultResolverChangedEvent)
-  [Resource `ReverseRegistrar`](#0x0_reverse_registrar_ReverseRegistrar)
-  [Constants](#@Constants_0)
-  [Function `claim`](#0x0_reverse_registrar_claim)
-  [Function `claim_with_resolver`](#0x0_reverse_registrar_claim_with_resolver)
-  [Function `set_default_resolver`](#0x0_reverse_registrar_set_default_resolver)
-  [Function `init`](#0x0_reverse_registrar_init)


<pre><code><b>use</b> <a href="base_registry.md#0x0_base_registry">0x0::base_registry</a>;
<b>use</b> <a href="converter.md#0x0_converter">0x0::converter</a>;
<b>use</b> <a href="">0x1::string</a>;
<b>use</b> <a href="">0x2::event</a>;
<b>use</b> <a href="">0x2::object</a>;
<b>use</b> <a href="">0x2::transfer</a>;
<b>use</b> <a href="">0x2::tx_context</a>;
</code></pre>



<a name="0x0_reverse_registrar_ReverseClaimedEvent"></a>

## Struct `ReverseClaimedEvent`



<pre><code><b>struct</b> <a href="reverse_registrar.md#0x0_reverse_registrar_ReverseClaimedEvent">ReverseClaimedEvent</a> <b>has</b> <b>copy</b>, drop
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
<code><a href="resolver.md#0x0_resolver">resolver</a>: <b>address</b></code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0x0_reverse_registrar_DefaultResolverChangedEvent"></a>

## Struct `DefaultResolverChangedEvent`



<pre><code><b>struct</b> <a href="reverse_registrar.md#0x0_reverse_registrar_DefaultResolverChangedEvent">DefaultResolverChangedEvent</a> <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code><a href="resolver.md#0x0_resolver">resolver</a>: <b>address</b></code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0x0_reverse_registrar_ReverseRegistrar"></a>

## Resource `ReverseRegistrar`



<pre><code><b>struct</b> <a href="reverse_registrar.md#0x0_reverse_registrar_ReverseRegistrar">ReverseRegistrar</a> <b>has</b> key
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>id: <a href="_UID">object::UID</a></code>
</dt>
<dd>

</dd>
<dt>
<code>default_name_resolver: <b>address</b></code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="@Constants_0"></a>

## Constants


<a name="0x0_reverse_registrar_ADDR_REVERSE_BASE_NODE"></a>



<pre><code><b>const</b> <a href="reverse_registrar.md#0x0_reverse_registrar_ADDR_REVERSE_BASE_NODE">ADDR_REVERSE_BASE_NODE</a>: <a href="">vector</a>&lt;u8&gt; = [97, 100, 100, 114, 46, 114, 101, 118, 101, 114, 115, 101];
</code></pre>



<a name="0x0_reverse_registrar_claim"></a>

## Function `claim`


<a name="@Notice_1"></a>

###### Notice

Similar to <code>claim_with_resolver</code>. The only differrence is
this function uses <code>default_name_resolver</code> property as resolver address.


<pre><code><b>public</b> entry <b>fun</b> <a href="reverse_registrar.md#0x0_reverse_registrar_claim">claim</a>(registrar: &<b>mut</b> <a href="reverse_registrar.md#0x0_reverse_registrar_ReverseRegistrar">reverse_registrar::ReverseRegistrar</a>, registry: &<b>mut</b> <a href="base_registry.md#0x0_base_registry_Registry">base_registry::Registry</a>, owner: <b>address</b>, ctx: &<b>mut</b> <a href="_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="reverse_registrar.md#0x0_reverse_registrar_claim">claim</a>(registrar: &<b>mut</b> <a href="reverse_registrar.md#0x0_reverse_registrar_ReverseRegistrar">ReverseRegistrar</a>, registry: &<b>mut</b> Registry, owner: <b>address</b>, ctx: &<b>mut</b> TxContext) {
    <a href="reverse_registrar.md#0x0_reverse_registrar_claim_with_resolver">claim_with_resolver</a>(registry, owner, *&registrar.default_name_resolver, ctx)
}
</code></pre>



</details>

<a name="0x0_reverse_registrar_claim_with_resolver"></a>

## Function `claim_with_resolver`


<a name="@Notice_2"></a>

###### Notice

This function is used to created reverse domains, i.e. domains with format: <code>123abc.addr.reverse</code>.


<a name="@Dev_3"></a>

###### Dev

Unlike <code>BaseRegistrar</code>, this function only creates name record.


<a name="@Params_4"></a>

###### Params

<code>owner</code>: new owner address of new name record.
<code><a href="resolver.md#0x0_resolver">resolver</a></code>: resolver address of new name record.


<pre><code><b>public</b> entry <b>fun</b> <a href="reverse_registrar.md#0x0_reverse_registrar_claim_with_resolver">claim_with_resolver</a>(registry: &<b>mut</b> <a href="base_registry.md#0x0_base_registry_Registry">base_registry::Registry</a>, owner: <b>address</b>, <a href="resolver.md#0x0_resolver">resolver</a>: <b>address</b>, ctx: &<b>mut</b> <a href="_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="reverse_registrar.md#0x0_reverse_registrar_claim_with_resolver">claim_with_resolver</a>(
    registry: &<b>mut</b> Registry,
    owner: <b>address</b>,
    <a href="resolver.md#0x0_resolver">resolver</a>: <b>address</b>,
    ctx: &<b>mut</b> TxContext
) {
    <b>let</b> label = <a href="converter.md#0x0_converter_address_to_string">converter::address_to_string</a>(sender(ctx));
    <b>let</b> node = <a href="base_registry.md#0x0_base_registry_make_node">base_registry::make_node</a>(label, <a href="_utf8">string::utf8</a>(<a href="reverse_registrar.md#0x0_reverse_registrar_ADDR_REVERSE_BASE_NODE">ADDR_REVERSE_BASE_NODE</a>));
    <a href="base_registry.md#0x0_base_registry_set_record_internal">base_registry::set_record_internal</a>(registry, node, owner, <a href="resolver.md#0x0_resolver">resolver</a>, 0);

    <a href="_emit">event::emit</a>(<a href="reverse_registrar.md#0x0_reverse_registrar_ReverseClaimedEvent">ReverseClaimedEvent</a> { addr: sender(ctx), <a href="resolver.md#0x0_resolver">resolver</a> })
}
</code></pre>



</details>

<a name="0x0_reverse_registrar_set_default_resolver"></a>

## Function `set_default_resolver`


<a name="@Notice_5"></a>

###### Notice

The admin uses this function to update <code>default_name_resolver</code>.


<pre><code><b>public</b> entry <b>fun</b> <a href="reverse_registrar.md#0x0_reverse_registrar_set_default_resolver">set_default_resolver</a>(_: &<a href="base_registry.md#0x0_base_registry_AdminCap">base_registry::AdminCap</a>, registrar: &<b>mut</b> <a href="reverse_registrar.md#0x0_reverse_registrar_ReverseRegistrar">reverse_registrar::ReverseRegistrar</a>, <a href="resolver.md#0x0_resolver">resolver</a>: <b>address</b>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="reverse_registrar.md#0x0_reverse_registrar_set_default_resolver">set_default_resolver</a>(_: &AdminCap, registrar: &<b>mut</b> <a href="reverse_registrar.md#0x0_reverse_registrar_ReverseRegistrar">ReverseRegistrar</a>, <a href="resolver.md#0x0_resolver">resolver</a>: <b>address</b>) {
    registrar.default_name_resolver = <a href="resolver.md#0x0_resolver">resolver</a>;
    <a href="_emit">event::emit</a>(<a href="reverse_registrar.md#0x0_reverse_registrar_DefaultResolverChangedEvent">DefaultResolverChangedEvent</a> { <a href="resolver.md#0x0_resolver">resolver</a> })
}
</code></pre>



</details>

<a name="0x0_reverse_registrar_init"></a>

## Function `init`



<pre><code><b>fun</b> <a href="reverse_registrar.md#0x0_reverse_registrar_init">init</a>(ctx: &<b>mut</b> <a href="_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="reverse_registrar.md#0x0_reverse_registrar_init">init</a>(ctx: &<b>mut</b> TxContext) {
    <a href="_share_object">transfer::share_object</a>(<a href="reverse_registrar.md#0x0_reverse_registrar_ReverseRegistrar">ReverseRegistrar</a> {
        id: <a href="_new">object::new</a>(ctx),
        // cannot get the ID of name_resolver in `init`, the admin <b>has</b> <b>to</b> <b>update</b> this by calling
        // `set_default_resolver`
        default_name_resolver: @0x0,
    });
}
</code></pre>



</details>
