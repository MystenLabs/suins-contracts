
<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_update_image"></a>

# Module `0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94::update_image`



-  [Struct `UpdateImage`](#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_update_image_UpdateImage)
-  [Constants](#@Constants_0)
-  [Function `update_image_url`](#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_update_image_update_image_url)
-  [Function `image_data_from_bcs`](#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_update_image_image_data_from_bcs)


<pre><code><b>use</b> <a href="dependencies/move-stdlib/string.md#0x1_string">0x1::string</a>;
<b>use</b> <a href="dependencies/sui-framework/bcs.md#0x2_bcs">0x2::bcs</a>;
<b>use</b> <a href="dependencies/sui-framework/clock.md#0x2_clock">0x2::clock</a>;
<b>use</b> <a href="dependencies/sui-framework/ecdsa_k1.md#0x2_ecdsa_k1">0x2::ecdsa_k1</a>;
<b>use</b> <a href="config.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_config">0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94::config</a>;
<b>use</b> <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94::domain</a>;
<b>use</b> <a href="registry.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_registry">0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94::registry</a>;
<b>use</b> <a href="suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94::suins</a>;
<b>use</b> <a href="suins_registration.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_registration">0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94::suins_registration</a>;
</code></pre>



<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_update_image_UpdateImage"></a>

## Struct `UpdateImage`

Authorization token for the app.


<pre><code><b>struct</b> <a href="update_image.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_update_image_UpdateImage">UpdateImage</a> <b>has</b> drop
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


<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_update_image_EInvalidData"></a>

Message data cannot be parsed.


<pre><code><b>const</b> <a href="update_image.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_update_image_EInvalidData">EInvalidData</a>: u64 = 0;
</code></pre>



<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_update_image_EInvalidDomainData"></a>

The parsed name does not match the expected domain.


<pre><code><b>const</b> <a href="update_image.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_update_image_EInvalidDomainData">EInvalidDomainData</a>: u64 = 1;
</code></pre>



<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_update_image_ESignatureNotMatch"></a>

Invalid signature for the message.


<pre><code><b>const</b> <a href="update_image.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_update_image_ESignatureNotMatch">ESignatureNotMatch</a>: u64 = 2;
</code></pre>



<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_update_image_update_image_url"></a>

## Function `update_image_url`

Updates the image attached to a <code>SuinsRegistration</code>.


<pre><code>entry <b>fun</b> <a href="update_image.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_update_image_update_image_url">update_image_url</a>(<a href="suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>: &<a href="suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_SuiNS">suins::SuiNS</a>, nft: &<b>mut</b> <a href="suins_registration.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_registration_SuinsRegistration">suins_registration::SuinsRegistration</a>, raw_msg: <a href="dependencies/move-stdlib/vector.md#0x1_vector">vector</a>&lt;u8&gt;, signature: <a href="dependencies/move-stdlib/vector.md#0x1_vector">vector</a>&lt;u8&gt;, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &<a href="dependencies/sui-framework/clock.md#0x2_clock_Clock">clock::Clock</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code>entry <b>fun</b> <a href="update_image.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_update_image_update_image_url">update_image_url</a>(
   <a href="suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>: &SuiNS,
   nft: &<b>mut</b> SuinsRegistration,
   raw_msg: <a href="dependencies/move-stdlib/vector.md#0x1_vector">vector</a>&lt;u8&gt;,
   signature: <a href="dependencies/move-stdlib/vector.md#0x1_vector">vector</a>&lt;u8&gt;,
   <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &Clock,
) {
    <a href="suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>.assert_app_is_authorized&lt;<a href="update_image.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_update_image_UpdateImage">UpdateImage</a>&gt;();
    <b>let</b> <a href="registry.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_registry">registry</a> = <a href="suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>.<a href="registry.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_registry">registry</a>&lt;Registry&gt;();
    <a href="registry.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_registry">registry</a>.assert_nft_is_authorized(nft, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>);

    <b>let</b> <a href="config.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_config">config</a> = <a href="suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>.get_config&lt;Config&gt;();

    <b>assert</b>!(
        <a href="dependencies/sui-framework/ecdsa_k1.md#0x2_ecdsa_k1_secp256k1_verify">ecdsa_k1::secp256k1_verify</a>(&signature, <a href="config.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_config">config</a>.public_key(), &raw_msg, 1),
        <a href="update_image.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_update_image_ESignatureNotMatch">ESignatureNotMatch</a>
    );

    <b>let</b> (ipfs_hash, domain_name, expiration_timestamp_ms, _data) = <a href="update_image.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_update_image_image_data_from_bcs">image_data_from_bcs</a>(raw_msg);

    <b>assert</b>!(nft.expiration_timestamp_ms() == expiration_timestamp_ms, <a href="update_image.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_update_image_EInvalidData">EInvalidData</a>);
    <b>assert</b>!(nft.<a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a>().to_string() == domain_name, <a href="update_image.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_update_image_EInvalidDomainData">EInvalidDomainData</a>);

    nft.<a href="update_image.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_update_image_update_image_url">update_image_url</a>(ipfs_hash);

    // TODO emit an <a href="dependencies/sui-framework/event.md#0x2_event">event</a>
    // <a href="dependencies/sui-framework/event.md#0x2_event_emit">event::emit</a>(ImageUpdatedEvent {
    //     sender: <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context_sender">tx_context::sender</a>(ctx),
    //     domain_name: nft.name,
    //     new_image: nft.<a href="dependencies/sui-framework/url.md#0x2_url">url</a>,
    //     data: additional_data,
    // })
}
</code></pre>



</details>

<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_update_image_image_data_from_bcs"></a>

## Function `image_data_from_bcs`

Parses the message bytes into the image data.
```
struct MessageData {
ipfs_hash: String,
domain_name: String,
expiration_timestamp_ms: u64,
data: String
}
```


<pre><code><b>fun</b> <a href="update_image.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_update_image_image_data_from_bcs">image_data_from_bcs</a>(msg_bytes: <a href="dependencies/move-stdlib/vector.md#0x1_vector">vector</a>&lt;u8&gt;): (<a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>, <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>, u64, <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="update_image.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_update_image_image_data_from_bcs">image_data_from_bcs</a>(msg_bytes: <a href="dependencies/move-stdlib/vector.md#0x1_vector">vector</a>&lt;u8&gt;): (String, String, u64, String) {
    <b>let</b> <b>mut</b> <a href="dependencies/move-stdlib/bcs.md#0x1_bcs">bcs</a> = bcs::new(msg_bytes);

    <b>let</b> ipfs_hash = utf8(<a href="dependencies/move-stdlib/bcs.md#0x1_bcs">bcs</a>.peel_vec_u8());
    <b>let</b> domain_name = utf8(<a href="dependencies/move-stdlib/bcs.md#0x1_bcs">bcs</a>.peel_vec_u8());
    <b>let</b> expiration_timestamp_ms = <a href="dependencies/move-stdlib/bcs.md#0x1_bcs">bcs</a>.peel_u64();
    <b>let</b> data = utf8(<a href="dependencies/move-stdlib/bcs.md#0x1_bcs">bcs</a>.peel_vec_u8());

    <b>let</b> remainder = <a href="dependencies/move-stdlib/bcs.md#0x1_bcs">bcs</a>.into_remainder_bytes();
    remainder.destroy_empty();

    (
        ipfs_hash,
        domain_name,
        expiration_timestamp_ms,
        data,
    )
}
</code></pre>



</details>
