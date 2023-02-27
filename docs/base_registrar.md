
<a name="0x0_base_registrar"></a>

# Module `0x0::base_registrar`

Base structure for all kind of registrars except reverse one.
Call <code>new_tld</code> to setup new registrar.
All functions that have any logic to charge payment in this module aren't supposed to be called directly,
users must call the corresponding functions in <code>Controller</code>.


-  [Resource `RegistrationNFT`](#0x0_base_registrar_RegistrationNFT)
-  [Struct `RegistrationDetail`](#0x0_base_registrar_RegistrationDetail)
-  [Resource `BaseRegistrar`](#0x0_base_registrar_BaseRegistrar)
-  [Resource `TLDList`](#0x0_base_registrar_TLDList)
-  [Struct `NameRenewedEvent`](#0x0_base_registrar_NameRenewedEvent)
-  [Struct `NameReclaimedEvent`](#0x0_base_registrar_NameReclaimedEvent)
-  [Struct `ImageUpdatedEvent`](#0x0_base_registrar_ImageUpdatedEvent)
-  [Constants](#@Constants_0)
-  [Function `new_tld`](#0x0_base_registrar_new_tld)
-  [Function `reclaim_name`](#0x0_base_registrar_reclaim_name)
-  [Function `update_image_url`](#0x0_base_registrar_update_image_url)
-  [Function `is_available`](#0x0_base_registrar_is_available)
-  [Function `is_expired`](#0x0_base_registrar_is_expired)
-  [Function `name_expires_at`](#0x0_base_registrar_name_expires_at)
-  [Function `base_node`](#0x0_base_registrar_base_node)
-  [Function `base_node_bytes`](#0x0_base_registrar_base_node_bytes)
-  [Function `assert_nft_not_expires`](#0x0_base_registrar_assert_nft_not_expires)
-  [Function `assert_image_msg_not_empty`](#0x0_base_registrar_assert_image_msg_not_empty)
-  [Function `assert_image_msg_match`](#0x0_base_registrar_assert_image_msg_match)
-  [Function `register`](#0x0_base_registrar_register)
-  [Function `register_with_image`](#0x0_base_registrar_register_with_image)
-  [Function `renew`](#0x0_base_registrar_renew)
-  [Function `get_label_part`](#0x0_base_registrar_get_label_part)
-  [Function `init`](#0x0_base_registrar_init)


<pre><code><b>use</b> <a href="base_registry.md#0x0_base_registry">0x0::base_registry</a>;
<b>use</b> <a href="configuration.md#0x0_configuration">0x0::configuration</a>;
<b>use</b> <a href="remove_later.md#0x0_remove_later">0x0::remove_later</a>;
<b>use</b> <a href="">0x1::ascii</a>;
<b>use</b> <a href="">0x1::hash</a>;
<b>use</b> <a href="">0x1::option</a>;
<b>use</b> <a href="">0x1::string</a>;
<b>use</b> <a href="">0x1::vector</a>;
<b>use</b> <a href="">0x2::dynamic_field</a>;
<b>use</b> <a href="">0x2::ecdsa_k1</a>;
<b>use</b> <a href="">0x2::event</a>;
<b>use</b> <a href="">0x2::object</a>;
<b>use</b> <a href="">0x2::transfer</a>;
<b>use</b> <a href="">0x2::tx_context</a>;
<b>use</b> <a href="">0x2::url</a>;
</code></pre>



<a name="0x0_base_registrar_RegistrationNFT"></a>

## Resource `RegistrationNFT`

NFT representing ownership of a domain


<pre><code><b>struct</b> <a href="base_registrar.md#0x0_base_registrar_RegistrationNFT">RegistrationNFT</a> <b>has</b> store, key
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
<code>name: <a href="_String">string::String</a></code>
</dt>
<dd>
 name and url fields have special meaning in sui explorer and extension
 if url is a ipfs image, this image is showed on sui explorer and extension
</dd>
<dt>
<code><a href="">url</a>: <a href="_Url">url::Url</a></code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0x0_base_registrar_RegistrationDetail"></a>

## Struct `RegistrationDetail`



<pre><code><b>struct</b> <a href="base_registrar.md#0x0_base_registrar_RegistrationDetail">RegistrationDetail</a> <b>has</b> drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>expiry: u64</code>
</dt>
<dd>

</dd>
<dt>
<code>owner: <b>address</b></code>
</dt>
<dd>

</dd>
<dt>
<code>nft_id: <a href="_ID">object::ID</a></code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0x0_base_registrar_BaseRegistrar"></a>

## Resource `BaseRegistrar`

Mapping domain name to registration record (instance of <code><a href="base_registrar.md#0x0_base_registrar_RegistrationDetail">RegistrationDetail</a></code>).
Each record is a dynamic field of this share object,.


<pre><code><b>struct</b> <a href="base_registrar.md#0x0_base_registrar_BaseRegistrar">BaseRegistrar</a> <b>has</b> key
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
<code>tld: <a href="_String">string::String</a></code>
</dt>
<dd>

</dd>
<dt>
<code>tld_bytes: <a href="">vector</a>&lt;u8&gt;</code>
</dt>
<dd>
 base_node represented in byte array
</dd>
</dl>


</details>

<a name="0x0_base_registrar_TLDList"></a>

## Resource `TLDList`

list of all TLD managed by this registrar


<pre><code><b>struct</b> <a href="base_registrar.md#0x0_base_registrar_TLDList">TLDList</a> <b>has</b> key
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
<code>tlds: <a href="">vector</a>&lt;<a href="_String">string::String</a>&gt;</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0x0_base_registrar_NameRenewedEvent"></a>

## Struct `NameRenewedEvent`



<pre><code><b>struct</b> <a href="base_registrar.md#0x0_base_registrar_NameRenewedEvent">NameRenewedEvent</a> <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>label: <a href="_String">string::String</a></code>
</dt>
<dd>

</dd>
<dt>
<code>expiry: u64</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0x0_base_registrar_NameReclaimedEvent"></a>

## Struct `NameReclaimedEvent`



<pre><code><b>struct</b> <a href="base_registrar.md#0x0_base_registrar_NameReclaimedEvent">NameReclaimedEvent</a> <b>has</b> <b>copy</b>, drop
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

<a name="0x0_base_registrar_ImageUpdatedEvent"></a>

## Struct `ImageUpdatedEvent`



<pre><code><b>struct</b> <a href="base_registrar.md#0x0_base_registrar_ImageUpdatedEvent">ImageUpdatedEvent</a> <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>sender: <b>address</b></code>
</dt>
<dd>

</dd>
<dt>
<code>node: <a href="_String">string::String</a></code>
</dt>
<dd>

</dd>
<dt>
<code>new_image: <a href="_Url">url::Url</a></code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="@Constants_0"></a>

## Constants


<a name="0x0_base_registrar_EInvalidLabel"></a>



<pre><code><b>const</b> <a href="base_registrar.md#0x0_base_registrar_EInvalidLabel">EInvalidLabel</a>: u64 = 203;
</code></pre>



<a name="0x0_base_registrar_EUnauthorized"></a>



<pre><code><b>const</b> <a href="base_registrar.md#0x0_base_registrar_EUnauthorized">EUnauthorized</a>: u64 = 101;
</code></pre>



<a name="0x0_base_registrar_MAX_TTL"></a>



<pre><code><b>const</b> <a href="base_registrar.md#0x0_base_registrar_MAX_TTL">MAX_TTL</a>: u64 = 1048576;
</code></pre>



<a name="0x0_base_registrar_EHashedMessageNotMatch"></a>



<pre><code><b>const</b> <a href="base_registrar.md#0x0_base_registrar_EHashedMessageNotMatch">EHashedMessageNotMatch</a>: u64 = 212;
</code></pre>



<a name="0x0_base_registrar_EInvalidBaseNode"></a>



<pre><code><b>const</b> <a href="base_registrar.md#0x0_base_registrar_EInvalidBaseNode">EInvalidBaseNode</a>: u64 = 209;
</code></pre>



<a name="0x0_base_registrar_EInvalidDuration"></a>



<pre><code><b>const</b> <a href="base_registrar.md#0x0_base_registrar_EInvalidDuration">EInvalidDuration</a>: u64 = 206;
</code></pre>



<a name="0x0_base_registrar_EInvalidImageMessage"></a>



<pre><code><b>const</b> <a href="base_registrar.md#0x0_base_registrar_EInvalidImageMessage">EInvalidImageMessage</a>: u64 = 211;
</code></pre>



<a name="0x0_base_registrar_ELabelExpired"></a>



<pre><code><b>const</b> <a href="base_registrar.md#0x0_base_registrar_ELabelExpired">ELabelExpired</a>: u64 = 205;
</code></pre>



<a name="0x0_base_registrar_ELabelNotExists"></a>



<pre><code><b>const</b> <a href="base_registrar.md#0x0_base_registrar_ELabelNotExists">ELabelNotExists</a>: u64 = 207;
</code></pre>



<a name="0x0_base_registrar_ELabelUnAvailable"></a>



<pre><code><b>const</b> <a href="base_registrar.md#0x0_base_registrar_ELabelUnAvailable">ELabelUnAvailable</a>: u64 = 204;
</code></pre>



<a name="0x0_base_registrar_ENFTExpired"></a>



<pre><code><b>const</b> <a href="base_registrar.md#0x0_base_registrar_ENFTExpired">ENFTExpired</a>: u64 = 213;
</code></pre>



<a name="0x0_base_registrar_ESignatureNotMatch"></a>



<pre><code><b>const</b> <a href="base_registrar.md#0x0_base_registrar_ESignatureNotMatch">ESignatureNotMatch</a>: u64 = 210;
</code></pre>



<a name="0x0_base_registrar_ETLDExists"></a>



<pre><code><b>const</b> <a href="base_registrar.md#0x0_base_registrar_ETLDExists">ETLDExists</a>: u64 = 208;
</code></pre>



<a name="0x0_base_registrar_GRACE_PERIOD"></a>



<pre><code><b>const</b> <a href="base_registrar.md#0x0_base_registrar_GRACE_PERIOD">GRACE_PERIOD</a>: u8 = 90;
</code></pre>



<a name="0x0_base_registrar_new_tld"></a>

## Function `new_tld`


<a name="@Notice_1"></a>

###### Notice

The admin uses this function to create a new <code><a href="base_registrar.md#0x0_base_registrar_BaseRegistrar">BaseRegistrar</a></code> share object
that manages domains having the same top level domain.



<a name="@Params_2"></a>

###### Params

<code>new_tld</code>: the TLD that this new share object manages.

Panic
Panic if this TLD already exists.


<pre><code><b>public</b> entry <b>fun</b> <a href="base_registrar.md#0x0_base_registrar_new_tld">new_tld</a>(_: &<a href="base_registry.md#0x0_base_registry_AdminCap">base_registry::AdminCap</a>, tld_list: &<b>mut</b> <a href="base_registrar.md#0x0_base_registrar_TLDList">base_registrar::TLDList</a>, new_tld: <a href="">vector</a>&lt;u8&gt;, ctx: &<b>mut</b> <a href="_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="base_registrar.md#0x0_base_registrar_new_tld">new_tld</a>(
    _: &AdminCap,
    tld_list: &<b>mut</b> <a href="base_registrar.md#0x0_base_registrar_TLDList">TLDList</a>,
    new_tld: <a href="">vector</a>&lt;u8&gt;,
    ctx: &<b>mut</b> TxContext,
) {
    <b>let</b> tld_str = <a href="_utf8">string::utf8</a>(new_tld);
    <b>let</b> len = <a href="_length">vector::length</a>(&tld_list.tlds);
    <b>let</b> index = 0;

    <b>while</b> (index &lt; len) {
        <b>let</b> existed_tld = <a href="_borrow">vector::borrow</a>(&tld_list.tlds, index);
        <b>assert</b>!(*existed_tld != tld_str, <a href="base_registrar.md#0x0_base_registrar_ETLDExists">ETLDExists</a>);
        index = index + 1;
    };

    <a href="_push_back">vector::push_back</a>(&<b>mut</b> tld_list.tlds, tld_str);
    <a href="_share_object">transfer::share_object</a>(<a href="base_registrar.md#0x0_base_registrar_BaseRegistrar">BaseRegistrar</a> {
        id: <a href="_new">object::new</a>(ctx),
        tld: tld_str,
        tld_bytes: new_tld,
    });
}
</code></pre>



</details>

<a name="0x0_base_registrar_reclaim_name"></a>

## Function `reclaim_name`


<a name="@Notice_3"></a>

###### Notice

The owner of the NFT uses this function to change the <code>owner</code> property of the
corresponding name record stored in the <code>Registry</code>.


<a name="@Params_4"></a>

###### Params

<code>owner</code>: new owner address of name record.

Panic
Panic if the NFT no longer exists
or the NFT expired.


<pre><code><b>public</b> entry <b>fun</b> <a href="base_registrar.md#0x0_base_registrar_reclaim_name">reclaim_name</a>(registrar: &<a href="base_registrar.md#0x0_base_registrar_BaseRegistrar">base_registrar::BaseRegistrar</a>, registry: &<b>mut</b> <a href="base_registry.md#0x0_base_registry_Registry">base_registry::Registry</a>, nft: &<a href="base_registrar.md#0x0_base_registrar_RegistrationNFT">base_registrar::RegistrationNFT</a>, owner: <b>address</b>, ctx: &<b>mut</b> <a href="_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="base_registrar.md#0x0_base_registrar_reclaim_name">reclaim_name</a>(
    registrar: &<a href="base_registrar.md#0x0_base_registrar_BaseRegistrar">BaseRegistrar</a>,
    registry: &<b>mut</b> Registry,
    nft: &<a href="base_registrar.md#0x0_base_registrar_RegistrationNFT">RegistrationNFT</a>,
    owner: <b>address</b>,
    ctx: &<b>mut</b> TxContext,
) {
    <a href="base_registrar.md#0x0_base_registrar_assert_nft_not_expires">assert_nft_not_expires</a>(registrar, nft, ctx);

    <b>let</b> label = <a href="base_registrar.md#0x0_base_registrar_get_label_part">get_label_part</a>(&nft.name, &registrar.tld);
    <b>let</b> registration = field::borrow&lt;String, <a href="base_registrar.md#0x0_base_registrar_RegistrationDetail">RegistrationDetail</a>&gt;(&registrar.id, label);
    <b>assert</b>!(registration.expiry &gt;= epoch(ctx), <a href="base_registrar.md#0x0_base_registrar_ELabelExpired">ELabelExpired</a>);

    <a href="base_registry.md#0x0_base_registry_set_owner_internal">base_registry::set_owner_internal</a>(registry, nft.name, owner);
    <a href="_emit">event::emit</a>(<a href="base_registrar.md#0x0_base_registrar_NameReclaimedEvent">NameReclaimedEvent</a> {
        node: nft.name,
        owner,
    })
}
</code></pre>



</details>

<a name="0x0_base_registrar_update_image_url"></a>

## Function `update_image_url`


<a name="@Notice_5"></a>

###### Notice

The owner of the NFT uses this function to update <code><a href="">url</a></code> field of his/her NFT.
The <code>signature</code>, <code>raw_msg</code> and <code>raw_msg</code> are generated by our Backend only.


<a name="@Params_6"></a>

###### Params

<code>nft</code>: the NFT to be updated,
<code>signature</code>: secp256k1 of <code>hashed_msg</code>
<code>hashed_msg</code>: sha256 of <code>raw_msg</code>
<code>raw_msg</code>: the data to verify and update image url, with format: <ipfs_url>,<owner>,<expiry>.

Panic
Panic if the NFT no longer invalid
or <code>signature</code>, <code>hashed_msg</code> or <code>raw_msg</code> is empty
or <code>hash_msg</code> doesn't match <code>raw_msg</code>
or <code>signature</code> doesn't match <code>hashed_msg</code> and <code>public_key</code> stored in Configuration
or the data in NFTs don't match <code>raw_msg</code>


<pre><code><b>public</b> entry <b>fun</b> <a href="base_registrar.md#0x0_base_registrar_update_image_url">update_image_url</a>(registrar: &<a href="base_registrar.md#0x0_base_registrar_BaseRegistrar">base_registrar::BaseRegistrar</a>, config: &<a href="configuration.md#0x0_configuration_Configuration">configuration::Configuration</a>, nft: &<b>mut</b> <a href="base_registrar.md#0x0_base_registrar_RegistrationNFT">base_registrar::RegistrationNFT</a>, signature: <a href="">vector</a>&lt;u8&gt;, hashed_msg: <a href="">vector</a>&lt;u8&gt;, raw_msg: <a href="">vector</a>&lt;u8&gt;, ctx: &<b>mut</b> <a href="_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="base_registrar.md#0x0_base_registrar_update_image_url">update_image_url</a>(
    registrar: &<a href="base_registrar.md#0x0_base_registrar_BaseRegistrar">BaseRegistrar</a>,
    config: &Configuration,
    nft: &<b>mut</b> <a href="base_registrar.md#0x0_base_registrar_RegistrationNFT">RegistrationNFT</a>,
    signature: <a href="">vector</a>&lt;u8&gt;,
    hashed_msg: <a href="">vector</a>&lt;u8&gt;,
    raw_msg: <a href="">vector</a>&lt;u8&gt;,
    ctx: &<b>mut</b> TxContext,
) {
    <a href="base_registrar.md#0x0_base_registrar_assert_nft_not_expires">assert_nft_not_expires</a>(registrar, nft, ctx);
    <a href="base_registrar.md#0x0_base_registrar_assert_image_msg_not_empty">assert_image_msg_not_empty</a>(&signature, &hashed_msg, &raw_msg);
    <a href="base_registrar.md#0x0_base_registrar_assert_image_msg_match">assert_image_msg_match</a>(config, signature, hashed_msg, raw_msg);

    <b>let</b> (ipfs, node_msg, expiry) = <a href="remove_later.md#0x0_remove_later_deserialize_image_msg">remove_later::deserialize_image_msg</a>(raw_msg);

    <b>assert</b>!(node_msg == nft.name, <a href="base_registrar.md#0x0_base_registrar_EInvalidImageMessage">EInvalidImageMessage</a>);

    <b>let</b> label = <a href="base_registrar.md#0x0_base_registrar_get_label_part">get_label_part</a>(&nft.name, &registrar.tld);

    <b>assert</b>!(expiry == <a href="base_registrar.md#0x0_base_registrar_name_expires_at">name_expires_at</a>(registrar, label), <a href="base_registrar.md#0x0_base_registrar_EInvalidImageMessage">EInvalidImageMessage</a>);

    nft.<a href="">url</a> = <a href="_new_unsafe_from_bytes">url::new_unsafe_from_bytes</a>(*<a href="_bytes">string::bytes</a>(&ipfs));
    <a href="_emit">event::emit</a>(<a href="base_registrar.md#0x0_base_registrar_ImageUpdatedEvent">ImageUpdatedEvent</a> {
        sender: sender(ctx),
        node: nft.name,
        new_image: nft.<a href="">url</a>,
    })
}
</code></pre>



</details>

<a name="0x0_base_registrar_is_available"></a>

## Function `is_available`


<a name="@Notice_7"></a>

###### Notice

Check if node derived from <code>label</code> and <code>registrar.tld</code> is available for registration.
<code>label</code> has an extra <code><a href="base_registrar.md#0x0_base_registrar_GRACE_PERIOD">GRACE_PERIOD</a></code> time after the expiration date,
during which it's consisered unavailable.
This <code><a href="base_registrar.md#0x0_base_registrar_GRACE_PERIOD">GRACE_PERIOD</a></code> is for the current owner to have time to renew.


<a name="@Params_8"></a>

###### Params

<code>label</code>: label to be checked


<a name="@Returns_9"></a>

###### Returns

true if this node is available for registration
false otherwise


<pre><code><b>public</b> <b>fun</b> <a href="base_registrar.md#0x0_base_registrar_is_available">is_available</a>(registrar: &<a href="base_registrar.md#0x0_base_registrar_BaseRegistrar">base_registrar::BaseRegistrar</a>, label: <a href="_String">string::String</a>, ctx: &<a href="_TxContext">tx_context::TxContext</a>): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="base_registrar.md#0x0_base_registrar_is_available">is_available</a>(registrar: &<a href="base_registrar.md#0x0_base_registrar_BaseRegistrar">BaseRegistrar</a>, label: String, ctx: &TxContext): bool {
    <b>let</b> expiry = <a href="base_registrar.md#0x0_base_registrar_name_expires_at">name_expires_at</a>(registrar, label);
    <b>if</b> (expiry != 0) {
        <b>return</b> expiry + (<a href="base_registrar.md#0x0_base_registrar_GRACE_PERIOD">GRACE_PERIOD</a> <b>as</b> u64) &lt; epoch(ctx)
    };
    <b>true</b>
}
</code></pre>



</details>

<a name="0x0_base_registrar_is_expired"></a>

## Function `is_expired`


<a name="@Notice_10"></a>

###### Notice

Check if node derived from <code>label</code> and <code>registrar.tld</code> is expired.


<a name="@Params_11"></a>

###### Params

<code>label</code>: label to be checked


<a name="@Returns:_12"></a>

###### Returns:

true if this node expired
false if it's not


<pre><code><b>public</b> <b>fun</b> <a href="base_registrar.md#0x0_base_registrar_is_expired">is_expired</a>(registrar: &<a href="base_registrar.md#0x0_base_registrar_BaseRegistrar">base_registrar::BaseRegistrar</a>, label: <a href="_String">string::String</a>, ctx: &<a href="_TxContext">tx_context::TxContext</a>): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="base_registrar.md#0x0_base_registrar_is_expired">is_expired</a>(registrar: &<a href="base_registrar.md#0x0_base_registrar_BaseRegistrar">BaseRegistrar</a>, label: String, ctx: &TxContext): bool {
    <b>let</b> expiry = <a href="base_registrar.md#0x0_base_registrar_name_expires_at">name_expires_at</a>(registrar, label);
    <b>if</b> (expiry != 0) {
        <b>return</b> expiry &lt; epoch(ctx)
    };
    <b>true</b>
}
</code></pre>



</details>

<a name="0x0_base_registrar_name_expires_at"></a>

## Function `name_expires_at`


<a name="@Notice_13"></a>

###### Notice

Returns the epoch after which the <code>label</code> is expired.


<a name="@Params_14"></a>

###### Params

<code>label</code>: label to be checked


<a name="@Returns_15"></a>

###### Returns

0: if <code>label</code> expired
otherwise: the expiration date


<pre><code><b>public</b> <b>fun</b> <a href="base_registrar.md#0x0_base_registrar_name_expires_at">name_expires_at</a>(registrar: &<a href="base_registrar.md#0x0_base_registrar_BaseRegistrar">base_registrar::BaseRegistrar</a>, label: <a href="_String">string::String</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="base_registrar.md#0x0_base_registrar_name_expires_at">name_expires_at</a>(registrar: &<a href="base_registrar.md#0x0_base_registrar_BaseRegistrar">BaseRegistrar</a>, label: String): u64 {
    <b>if</b> (field::exists_with_type&lt;String, <a href="base_registrar.md#0x0_base_registrar_RegistrationDetail">RegistrationDetail</a>&gt;(&registrar.id, label)) {
        <b>return</b> field::borrow&lt;String, <a href="base_registrar.md#0x0_base_registrar_RegistrationDetail">RegistrationDetail</a>&gt;(&registrar.id, label).expiry
    };
    0
}
</code></pre>



</details>

<a name="0x0_base_registrar_base_node"></a>

## Function `base_node`



<pre><code><b>public</b> <b>fun</b> <a href="base_registrar.md#0x0_base_registrar_base_node">base_node</a>(registrar: &<a href="base_registrar.md#0x0_base_registrar_BaseRegistrar">base_registrar::BaseRegistrar</a>): <a href="_String">string::String</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="base_registrar.md#0x0_base_registrar_base_node">base_node</a>(registrar: &<a href="base_registrar.md#0x0_base_registrar_BaseRegistrar">BaseRegistrar</a>): String {
    registrar.tld
}
</code></pre>



</details>

<a name="0x0_base_registrar_base_node_bytes"></a>

## Function `base_node_bytes`



<pre><code><b>public</b> <b>fun</b> <a href="base_registrar.md#0x0_base_registrar_base_node_bytes">base_node_bytes</a>(registrar: &<a href="base_registrar.md#0x0_base_registrar_BaseRegistrar">base_registrar::BaseRegistrar</a>): <a href="">vector</a>&lt;u8&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="base_registrar.md#0x0_base_registrar_base_node_bytes">base_node_bytes</a>(registrar: &<a href="base_registrar.md#0x0_base_registrar_BaseRegistrar">BaseRegistrar</a>): <a href="">vector</a>&lt;u8&gt; {
    registrar.tld_bytes
}
</code></pre>



</details>

<a name="0x0_base_registrar_assert_nft_not_expires"></a>

## Function `assert_nft_not_expires`


<a name="@Notice_16"></a>

###### Notice

Validate if <code>nft</code> is valid or not.


<a name="@Params_17"></a>

###### Params

<code>nft</code>: NFT to be checked

Panic
Panic if the NFT is longer stored in SC
or the the data of the NFT mismatches the data stored in SC
or the NFTs expired.


<pre><code><b>public</b> <b>fun</b> <a href="base_registrar.md#0x0_base_registrar_assert_nft_not_expires">assert_nft_not_expires</a>(registrar: &<a href="base_registrar.md#0x0_base_registrar_BaseRegistrar">base_registrar::BaseRegistrar</a>, nft: &<a href="base_registrar.md#0x0_base_registrar_RegistrationNFT">base_registrar::RegistrationNFT</a>, ctx: &<b>mut</b> <a href="_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="base_registrar.md#0x0_base_registrar_assert_nft_not_expires">assert_nft_not_expires</a>(registrar: &<a href="base_registrar.md#0x0_base_registrar_BaseRegistrar">BaseRegistrar</a>, nft: &<a href="base_registrar.md#0x0_base_registrar_RegistrationNFT">RegistrationNFT</a>, ctx: &<b>mut</b> TxContext) {
    <b>let</b> label = <a href="base_registrar.md#0x0_base_registrar_get_label_part">get_label_part</a>(&nft.name, &registrar.tld);
    <b>let</b> detail = field::borrow&lt;String, <a href="base_registrar.md#0x0_base_registrar_RegistrationDetail">RegistrationDetail</a>&gt;(&registrar.id, label);
    // TODO: delete NFT <b>if</b> it expired
    <b>assert</b>!(detail.owner == sender(ctx), <a href="base_registrar.md#0x0_base_registrar_ENFTExpired">ENFTExpired</a>);
    <b>assert</b>!(detail.nft_id == uid_to_inner(&nft.id), <a href="base_registrar.md#0x0_base_registrar_ENFTExpired">ENFTExpired</a>);
    <b>assert</b>!(!<a href="base_registrar.md#0x0_base_registrar_is_expired">is_expired</a>(registrar, label, ctx), <a href="base_registrar.md#0x0_base_registrar_ENFTExpired">ENFTExpired</a>);
}
</code></pre>



</details>

<a name="0x0_base_registrar_assert_image_msg_not_empty"></a>

## Function `assert_image_msg_not_empty`



<pre><code><b>public</b> <b>fun</b> <a href="base_registrar.md#0x0_base_registrar_assert_image_msg_not_empty">assert_image_msg_not_empty</a>(signature: &<a href="">vector</a>&lt;u8&gt;, hashed_msg: &<a href="">vector</a>&lt;u8&gt;, raw_msg: &<a href="">vector</a>&lt;u8&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="base_registrar.md#0x0_base_registrar_assert_image_msg_not_empty">assert_image_msg_not_empty</a>(signature: &<a href="">vector</a>&lt;u8&gt;, hashed_msg: &<a href="">vector</a>&lt;u8&gt;, raw_msg: &<a href="">vector</a>&lt;u8&gt;) {
    <b>assert</b>!(
        !<a href="_is_empty">vector::is_empty</a>(signature)
            && !<a href="_is_empty">vector::is_empty</a>(hashed_msg)
            && !<a href="_is_empty">vector::is_empty</a>(raw_msg),
        <a href="base_registrar.md#0x0_base_registrar_EInvalidImageMessage">EInvalidImageMessage</a>
    );
}
</code></pre>



</details>

<a name="0x0_base_registrar_assert_image_msg_match"></a>

## Function `assert_image_msg_match`



<pre><code><b>public</b> <b>fun</b> <a href="base_registrar.md#0x0_base_registrar_assert_image_msg_match">assert_image_msg_match</a>(config: &<a href="configuration.md#0x0_configuration_Configuration">configuration::Configuration</a>, signature: <a href="">vector</a>&lt;u8&gt;, hashed_msg: <a href="">vector</a>&lt;u8&gt;, raw_msg: <a href="">vector</a>&lt;u8&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="base_registrar.md#0x0_base_registrar_assert_image_msg_match">assert_image_msg_match</a>(
    config: &Configuration,
    signature: <a href="">vector</a>&lt;u8&gt;,
    hashed_msg: <a href="">vector</a>&lt;u8&gt;,
    raw_msg: <a href="">vector</a>&lt;u8&gt;
) {
    <b>assert</b>!(sha2_256(raw_msg) == hashed_msg, <a href="base_registrar.md#0x0_base_registrar_EHashedMessageNotMatch">EHashedMessageNotMatch</a>);
    <b>assert</b>!(
        <a href="_secp256k1_verify">ecdsa_k1::secp256k1_verify</a>(&signature, <a href="configuration.md#0x0_configuration_public_key">configuration::public_key</a>(config), &hashed_msg),
        <a href="base_registrar.md#0x0_base_registrar_ESignatureNotMatch">ESignatureNotMatch</a>
    );
}
</code></pre>



</details>

<a name="0x0_base_registrar_register"></a>

## Function `register`

label can have multiple levels, e.g. 'dn.suins' or 'suins'
this function doesn't charge fee


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="base_registrar.md#0x0_base_registrar_register">register</a>(registrar: &<b>mut</b> <a href="base_registrar.md#0x0_base_registrar_BaseRegistrar">base_registrar::BaseRegistrar</a>, registry: &<b>mut</b> <a href="base_registry.md#0x0_base_registry_Registry">base_registry::Registry</a>, config: &<a href="configuration.md#0x0_configuration_Configuration">configuration::Configuration</a>, label: <a href="">vector</a>&lt;u8&gt;, owner: <b>address</b>, duration: u64, <a href="resolver.md#0x0_resolver">resolver</a>: <b>address</b>, ctx: &<b>mut</b> <a href="_TxContext">tx_context::TxContext</a>): <a href="_ID">object::ID</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="base_registrar.md#0x0_base_registrar_register">register</a>(
    registrar: &<b>mut</b> <a href="base_registrar.md#0x0_base_registrar_BaseRegistrar">BaseRegistrar</a>,
    registry: &<b>mut</b> Registry,
    config: &Configuration,
    label: <a href="">vector</a>&lt;u8&gt;,
    owner: <b>address</b>,
    duration: u64,
    <a href="resolver.md#0x0_resolver">resolver</a>: <b>address</b>,
    ctx: &<b>mut</b> TxContext
): ID {
    <b>let</b> (nft_id, _url) = <a href="base_registrar.md#0x0_base_registrar_register_with_image">register_with_image</a>(
        registrar,
        registry,
        config,
        label,
        owner,
        duration,
        <a href="resolver.md#0x0_resolver">resolver</a>,
        <a href="">vector</a>[],
        <a href="">vector</a>[],
        <a href="">vector</a>[],
        ctx
    );
    nft_id
}
</code></pre>



</details>

<a name="0x0_base_registrar_register_with_image"></a>

## Function `register_with_image`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="base_registrar.md#0x0_base_registrar_register_with_image">register_with_image</a>(registrar: &<b>mut</b> <a href="base_registrar.md#0x0_base_registrar_BaseRegistrar">base_registrar::BaseRegistrar</a>, registry: &<b>mut</b> <a href="base_registry.md#0x0_base_registry_Registry">base_registry::Registry</a>, config: &<a href="configuration.md#0x0_configuration_Configuration">configuration::Configuration</a>, label: <a href="">vector</a>&lt;u8&gt;, owner: <b>address</b>, duration: u64, <a href="resolver.md#0x0_resolver">resolver</a>: <b>address</b>, signature: <a href="">vector</a>&lt;u8&gt;, hashed_msg: <a href="">vector</a>&lt;u8&gt;, raw_msg: <a href="">vector</a>&lt;u8&gt;, ctx: &<b>mut</b> <a href="_TxContext">tx_context::TxContext</a>): (<a href="_ID">object::ID</a>, <a href="_Url">url::Url</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="base_registrar.md#0x0_base_registrar_register_with_image">register_with_image</a>(
    registrar: &<b>mut</b> <a href="base_registrar.md#0x0_base_registrar_BaseRegistrar">BaseRegistrar</a>,
    registry: &<b>mut</b> Registry,
    config: &Configuration,
    label: <a href="">vector</a>&lt;u8&gt;,
    owner: <b>address</b>,
    duration: u64,
    <a href="resolver.md#0x0_resolver">resolver</a>: <b>address</b>,
    signature: <a href="">vector</a>&lt;u8&gt;,
    hashed_msg: <a href="">vector</a>&lt;u8&gt;,
    raw_msg: <a href="">vector</a>&lt;u8&gt;,
    ctx: &<b>mut</b> TxContext
): (ID, Url) {
    // the calling fuction is responsible for checking emptyness of msg
    <b>assert</b>!(duration &gt; 0, <a href="base_registrar.md#0x0_base_registrar_EInvalidDuration">EInvalidDuration</a>);
    // TODO: label is already validated in Controller, consider removing this
    <b>let</b> label = <a href="_try_utf8">string::try_utf8</a>(label);
    <b>assert</b>!(<a href="_is_some">option::is_some</a>(&label), <a href="base_registrar.md#0x0_base_registrar_EInvalidLabel">EInvalidLabel</a>);
    <b>let</b> label = <a href="_extract">option::extract</a>(&<b>mut</b> label);
    <b>assert</b>!(<a href="base_registrar.md#0x0_base_registrar_is_available">is_available</a>(registrar, label, ctx), <a href="base_registrar.md#0x0_base_registrar_ELabelUnAvailable">ELabelUnAvailable</a>);

    <b>let</b> expiry = epoch(ctx) + duration;
    <b>let</b> node = label;
    <a href="_append_utf8">string::append_utf8</a>(&<b>mut</b> node, b".");
    <a href="_append">string::append</a>(&<b>mut</b> node, registrar.tld);

    <b>let</b> <a href="">url</a>;
    <b>if</b> (<a href="_is_empty">vector::is_empty</a>(&hashed_msg) || <a href="_is_empty">vector::is_empty</a>(&raw_msg) || <a href="_is_empty">vector::is_empty</a>(&signature))
        <a href="">url</a> = <a href="_new_unsafe_from_bytes">url::new_unsafe_from_bytes</a>(<a href="">vector</a>[])
    <b>else</b> {
        <a href="base_registrar.md#0x0_base_registrar_assert_image_msg_match">assert_image_msg_match</a>(config, signature, hashed_msg, raw_msg);

        <b>let</b> (ipfs, node_msg, expiry_msg) = <a href="remove_later.md#0x0_remove_later_deserialize_image_msg">remove_later::deserialize_image_msg</a>(raw_msg);

        <b>assert</b>!(node_msg == node, <a href="base_registrar.md#0x0_base_registrar_EInvalidImageMessage">EInvalidImageMessage</a>);
        <b>assert</b>!(expiry_msg == expiry, <a href="base_registrar.md#0x0_base_registrar_EInvalidImageMessage">EInvalidImageMessage</a>);

        <a href="">url</a> = <a href="_new_unsafe">url::new_unsafe</a>(<a href="_to_ascii">string::to_ascii</a>(ipfs));
    };

    <b>let</b> nft = <a href="base_registrar.md#0x0_base_registrar_RegistrationNFT">RegistrationNFT</a> {
        id: <a href="_new">object::new</a>(ctx),
        name: node,
        <a href="">url</a>,
    };
    <b>let</b> nft_id = <a href="_uid_to_inner">object::uid_to_inner</a>(&nft.id);
    <b>let</b> detail = <a href="base_registrar.md#0x0_base_registrar_RegistrationDetail">RegistrationDetail</a> { expiry, owner, nft_id };

    <b>if</b> (field::exists_with_type&lt;String, <a href="base_registrar.md#0x0_base_registrar_RegistrationDetail">RegistrationDetail</a>&gt;(&registrar.id, label)) {
        // this `label` is available for registration again
        field::remove&lt;String, <a href="base_registrar.md#0x0_base_registrar_RegistrationDetail">RegistrationDetail</a>&gt;(&<b>mut</b> registrar.id, label);
    };

    field::add(&<b>mut</b> registrar.id, label, detail);
    <a href="_transfer">transfer::transfer</a>(nft, owner);
    <a href="base_registry.md#0x0_base_registry_set_record_internal">base_registry::set_record_internal</a>(registry, node, owner, <a href="resolver.md#0x0_resolver">resolver</a>, 0);

    (nft_id, <a href="">url</a>)
}
</code></pre>



</details>

<a name="0x0_base_registrar_renew"></a>

## Function `renew`

this function doesn't charge fee
intended to be called by <code>Controller</code>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="base_registrar.md#0x0_base_registrar_renew">renew</a>(registrar: &<b>mut</b> <a href="base_registrar.md#0x0_base_registrar_BaseRegistrar">base_registrar::BaseRegistrar</a>, label: <a href="">vector</a>&lt;u8&gt;, duration: u64, ctx: &<a href="_TxContext">tx_context::TxContext</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="base_registrar.md#0x0_base_registrar_renew">renew</a>(registrar: &<b>mut</b> <a href="base_registrar.md#0x0_base_registrar_BaseRegistrar">BaseRegistrar</a>, label: <a href="">vector</a>&lt;u8&gt;, duration: u64, ctx: &TxContext): u64 {
    <b>let</b> label = <a href="_utf8">string::utf8</a>(label);
    <b>let</b> expiry = <a href="base_registrar.md#0x0_base_registrar_name_expires_at">name_expires_at</a>(registrar, label);

    <b>assert</b>!(expiry &gt; 0, <a href="base_registrar.md#0x0_base_registrar_ELabelNotExists">ELabelNotExists</a>);
    <b>assert</b>!(expiry + (<a href="base_registrar.md#0x0_base_registrar_GRACE_PERIOD">GRACE_PERIOD</a> <b>as</b> u64) &gt;= epoch(ctx), <a href="base_registrar.md#0x0_base_registrar_ELabelExpired">ELabelExpired</a>);

    <b>let</b> detail: &<b>mut</b> <a href="base_registrar.md#0x0_base_registrar_RegistrationDetail">RegistrationDetail</a> = field::borrow_mut(&<b>mut</b> registrar.id, label);
    detail.expiry = detail.expiry + duration;

    <a href="_emit">event::emit</a>(<a href="base_registrar.md#0x0_base_registrar_NameRenewedEvent">NameRenewedEvent</a> { label, expiry: detail.expiry });
    detail.expiry
}
</code></pre>



</details>

<a name="0x0_base_registrar_get_label_part"></a>

## Function `get_label_part`



<pre><code><b>fun</b> <a href="base_registrar.md#0x0_base_registrar_get_label_part">get_label_part</a>(node: &<a href="_String">string::String</a>, tld: &<a href="_String">string::String</a>): <a href="_String">string::String</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="base_registrar.md#0x0_base_registrar_get_label_part">get_label_part</a>(node: &String, tld: &String): String {
    <b>let</b> index_of_dot = <a href="_index_of">string::index_of</a>(node, tld);
    <b>assert</b>!(index_of_dot == <a href="_length">string::length</a>(node) - <a href="_length">string::length</a>(tld), <a href="base_registrar.md#0x0_base_registrar_EInvalidBaseNode">EInvalidBaseNode</a>);

    <a href="_sub_string">string::sub_string</a>(node, 0, index_of_dot - 1)
}
</code></pre>



</details>

<a name="0x0_base_registrar_init"></a>

## Function `init`



<pre><code><b>fun</b> <a href="base_registrar.md#0x0_base_registrar_init">init</a>(ctx: &<b>mut</b> <a href="_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="base_registrar.md#0x0_base_registrar_init">init</a>(ctx: &<b>mut</b> TxContext) {
    <a href="_share_object">transfer::share_object</a>(<a href="base_registrar.md#0x0_base_registrar_TLDList">TLDList</a> {
        id: <a href="_new">object::new</a>(ctx),
        tlds: <a href="_empty">vector::empty</a>&lt;String&gt;(),
    });
}
</code></pre>



</details>
