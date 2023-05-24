
<a name="0x0_update_image"></a>

# Module `0x0::update_image`



-  [Struct `UpdateImage`](#0x0_update_image_UpdateImage)
-  [Constants](#@Constants_0)
-  [Function `update_image_url`](#0x0_update_image_update_image_url)
-  [Function `image_data_from_bcs`](#0x0_update_image_image_data_from_bcs)


<pre><code><b>use</b> <a href="config.md#0x0_config">0x0::config</a>;
<b>use</b> <a href="domain.md#0x0_domain">0x0::domain</a>;
<b>use</b> <a href="registration_nft.md#0x0_registration_nft">0x0::registration_nft</a>;
<b>use</b> <a href="registry.md#0x0_registry">0x0::registry</a>;
<b>use</b> <a href="suins.md#0x0_suins">0x0::suins</a>;
<b>use</b> <a href="">0x1::string</a>;
<b>use</b> <a href="">0x2::bcs</a>;
<b>use</b> <a href="">0x2::clock</a>;
<b>use</b> <a href="">0x2::ecdsa_k1</a>;
</code></pre>



<a name="0x0_update_image_UpdateImage"></a>

## Struct `UpdateImage`

Authorization token for the app.


<pre><code><b>struct</b> <a href="update_image.md#0x0_update_image_UpdateImage">UpdateImage</a> <b>has</b> drop
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


<a name="0x0_update_image_EInvalidData"></a>

Message data cannot be parsed.


<pre><code><b>const</b> <a href="update_image.md#0x0_update_image_EInvalidData">EInvalidData</a>: u64 = 0;
</code></pre>



<a name="0x0_update_image_EInvalidDomainData"></a>

The parsed name does not match the expected domain.


<pre><code><b>const</b> <a href="update_image.md#0x0_update_image_EInvalidDomainData">EInvalidDomainData</a>: u64 = 1;
</code></pre>



<a name="0x0_update_image_ESignatureNotMatch"></a>

Invalid signature for the message.


<pre><code><b>const</b> <a href="update_image.md#0x0_update_image_ESignatureNotMatch">ESignatureNotMatch</a>: u64 = 2;
</code></pre>



<a name="0x0_update_image_update_image_url"></a>

## Function `update_image_url`

Updates the image attached to a <code>RegistrationNFT</code>.


<pre><code>entry <b>fun</b> <a href="update_image.md#0x0_update_image_update_image_url">update_image_url</a>(<a href="suins.md#0x0_suins">suins</a>: &<b>mut</b> <a href="suins.md#0x0_suins_SuiNS">suins::SuiNS</a>, nft: &<b>mut</b> <a href="registration_nft.md#0x0_registration_nft_RegistrationNFT">registration_nft::RegistrationNFT</a>, raw_msg: <a href="">vector</a>&lt;u8&gt;, signature: <a href="">vector</a>&lt;u8&gt;, <a href="">clock</a>: &<a href="_Clock">clock::Clock</a>)
</code></pre>


<a name="0x0_update_image_image_data_from_bcs"></a>

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


<pre><code><b>fun</b> <a href="update_image.md#0x0_update_image_image_data_from_bcs">image_data_from_bcs</a>(msg_bytes: <a href="">vector</a>&lt;u8&gt;): (<a href="_String">string::String</a>, <a href="_String">string::String</a>, u64, <a href="_String">string::String</a>)
</code></pre>
