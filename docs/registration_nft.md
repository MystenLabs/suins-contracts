
<a name="0x0_registration_nft"></a>

# Module `0x0::registration_nft`

Handles creation of the <code><a href="registration_nft.md#0x0_registration_nft_RegistrationNFT">RegistrationNFT</a></code>s. Separates the logic of creating
a <code><a href="registration_nft.md#0x0_registration_nft_RegistrationNFT">RegistrationNFT</a></code>. New <code><a href="registration_nft.md#0x0_registration_nft_RegistrationNFT">RegistrationNFT</a></code>s can be created only by the
<code><a href="registry.md#0x0_registry">registry</a></code> and this module is tightly coupled with it.

When reviewing the module, make sure that:

- mutable functions can't be called directly by the owner
- all getters are public and take an immutable reference


-  [Resource `RegistrationNFT`](#0x0_registration_nft_RegistrationNFT)
-  [Function `new`](#0x0_registration_nft_new)
-  [Function `set_expiration_timestamp_ms`](#0x0_registration_nft_set_expiration_timestamp_ms)
-  [Function `update_image_url`](#0x0_registration_nft_update_image_url)
-  [Function `has_expired`](#0x0_registration_nft_has_expired)
-  [Function `has_expired_past_grace_period`](#0x0_registration_nft_has_expired_past_grace_period)
-  [Function `domain`](#0x0_registration_nft_domain)
-  [Function `domain_name`](#0x0_registration_nft_domain_name)
-  [Function `expiration_timestamp_ms`](#0x0_registration_nft_expiration_timestamp_ms)
-  [Function `image_url`](#0x0_registration_nft_image_url)


<pre><code><b>use</b> <a href="constants.md#0x0_constants">0x0::constants</a>;
<b>use</b> <a href="domain.md#0x0_domain">0x0::domain</a>;
<b>use</b> <a href="">0x1::string</a>;
<b>use</b> <a href="">0x2::clock</a>;
<b>use</b> <a href="">0x2::object</a>;
<b>use</b> <a href="">0x2::tx_context</a>;
</code></pre>



<a name="0x0_registration_nft_RegistrationNFT"></a>

## Resource `RegistrationNFT`

The main access point for the user.


<pre><code><b>struct</b> <a href="registration_nft.md#0x0_registration_nft_RegistrationNFT">RegistrationNFT</a> <b>has</b> store, key
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
<code><a href="domain.md#0x0_domain">domain</a>: <a href="domain.md#0x0_domain_Domain">domain::Domain</a></code>
</dt>
<dd>
 The parsed domain.
</dd>
<dt>
<code>domain_name: <a href="_String">string::String</a></code>
</dt>
<dd>
 The domain name that the NFT is for.
</dd>
<dt>
<code>expiration_timestamp_ms: u64</code>
</dt>
<dd>
 Timestamp in milliseconds when this NFT expires.
</dd>
<dt>
<code>image_url: <a href="_String">string::String</a></code>
</dt>
<dd>
 Short IPFS hash of the image to be displayed for the NFT.
</dd>
</dl>


</details>

<a name="0x0_registration_nft_new"></a>

## Function `new`

Creates a new <code><a href="registration_nft.md#0x0_registration_nft_RegistrationNFT">RegistrationNFT</a></code>.
Can only be called by the <code><a href="registry.md#0x0_registry">registry</a></code> module.


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="registration_nft.md#0x0_registration_nft_new">new</a>(<a href="domain.md#0x0_domain">domain</a>: <a href="domain.md#0x0_domain_Domain">domain::Domain</a>, no_years: u8, <a href="">clock</a>: &<a href="_Clock">clock::Clock</a>, ctx: &<b>mut</b> <a href="_TxContext">tx_context::TxContext</a>): <a href="registration_nft.md#0x0_registration_nft_RegistrationNFT">registration_nft::RegistrationNFT</a>
</code></pre>


<a name="0x0_registration_nft_set_expiration_timestamp_ms"></a>

## Function `set_expiration_timestamp_ms`

Sets the <code>expiration_timestamp_ms</code> for this NFT.


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="registration_nft.md#0x0_registration_nft_set_expiration_timestamp_ms">set_expiration_timestamp_ms</a>(self: &<b>mut</b> <a href="registration_nft.md#0x0_registration_nft_RegistrationNFT">registration_nft::RegistrationNFT</a>, expiration_timestamp_ms: u64)
</code></pre>


<a name="0x0_registration_nft_update_image_url"></a>

## Function `update_image_url`

Updates the <code>image_url</code> field for this NFT. Is only called in the <code><a href="update_image.md#0x0_update_image">update_image</a></code> for now.


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="registration_nft.md#0x0_registration_nft_update_image_url">update_image_url</a>(self: &<b>mut</b> <a href="registration_nft.md#0x0_registration_nft_RegistrationNFT">registration_nft::RegistrationNFT</a>, image_url: <a href="_String">string::String</a>)
</code></pre>


<a name="0x0_registration_nft_has_expired"></a>

## Function `has_expired`

Check whether the <code><a href="registration_nft.md#0x0_registration_nft_RegistrationNFT">RegistrationNFT</a></code> has expired by comparing the
expiration timeout with the current time.


<pre><code><b>public</b> <b>fun</b> <a href="registration_nft.md#0x0_registration_nft_has_expired">has_expired</a>(self: &<a href="registration_nft.md#0x0_registration_nft_RegistrationNFT">registration_nft::RegistrationNFT</a>, <a href="">clock</a>: &<a href="_Clock">clock::Clock</a>): bool
</code></pre>


<a name="0x0_registration_nft_has_expired_past_grace_period"></a>

## Function `has_expired_past_grace_period`

Check whether the <code><a href="registration_nft.md#0x0_registration_nft_RegistrationNFT">RegistrationNFT</a></code> has expired by comparing the
expiration timeout with the current time. This function also takes into
account the grace period.


<pre><code><b>public</b> <b>fun</b> <a href="registration_nft.md#0x0_registration_nft_has_expired_past_grace_period">has_expired_past_grace_period</a>(self: &<a href="registration_nft.md#0x0_registration_nft_RegistrationNFT">registration_nft::RegistrationNFT</a>, <a href="">clock</a>: &<a href="_Clock">clock::Clock</a>): bool
</code></pre>


<a name="0x0_registration_nft_domain"></a>

## Function `domain`

Get the <code><a href="domain.md#0x0_domain">domain</a></code> field of the <code><a href="registration_nft.md#0x0_registration_nft_RegistrationNFT">RegistrationNFT</a></code>.


<pre><code><b>public</b> <b>fun</b> <a href="domain.md#0x0_domain">domain</a>(self: &<a href="registration_nft.md#0x0_registration_nft_RegistrationNFT">registration_nft::RegistrationNFT</a>): <a href="domain.md#0x0_domain_Domain">domain::Domain</a>
</code></pre>


<a name="0x0_registration_nft_domain_name"></a>

## Function `domain_name`

Get the <code>domain_name</code> field of the <code><a href="registration_nft.md#0x0_registration_nft_RegistrationNFT">RegistrationNFT</a></code>.


<pre><code><b>public</b> <b>fun</b> <a href="registration_nft.md#0x0_registration_nft_domain_name">domain_name</a>(self: &<a href="registration_nft.md#0x0_registration_nft_RegistrationNFT">registration_nft::RegistrationNFT</a>): <a href="_String">string::String</a>
</code></pre>


<a name="0x0_registration_nft_expiration_timestamp_ms"></a>

## Function `expiration_timestamp_ms`

Get the <code>expiration_timestamp_ms</code> field of the <code><a href="registration_nft.md#0x0_registration_nft_RegistrationNFT">RegistrationNFT</a></code>.


<pre><code><b>public</b> <b>fun</b> <a href="registration_nft.md#0x0_registration_nft_expiration_timestamp_ms">expiration_timestamp_ms</a>(self: &<a href="registration_nft.md#0x0_registration_nft_RegistrationNFT">registration_nft::RegistrationNFT</a>): u64
</code></pre>


<a name="0x0_registration_nft_image_url"></a>

## Function `image_url`

Get the <code>image_url</code> field of the <code><a href="registration_nft.md#0x0_registration_nft_RegistrationNFT">RegistrationNFT</a></code>.


<pre><code><b>public</b> <b>fun</b> <a href="registration_nft.md#0x0_registration_nft_image_url">image_url</a>(self: &<a href="registration_nft.md#0x0_registration_nft_RegistrationNFT">registration_nft::RegistrationNFT</a>): <a href="_String">string::String</a>
</code></pre>
