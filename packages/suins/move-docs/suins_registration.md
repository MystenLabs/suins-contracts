
<a name="0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration"></a>

# Module `0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b::suins_registration`

Handles creation of the <code><a href="suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_SuinsRegistration">SuinsRegistration</a></code>s. Separates the logic of creating
a <code><a href="suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_SuinsRegistration">SuinsRegistration</a></code>. New <code><a href="suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_SuinsRegistration">SuinsRegistration</a></code>s can be created only by the
<code><a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry">registry</a></code> and this module is tightly coupled with it.

When reviewing the module, make sure that:

- mutable functions can't be called directly by the owner
- all getters are public and take an immutable reference


-  [Resource `SuinsRegistration`](#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_SuinsRegistration)
-  [Function `new`](#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_new)
-  [Function `set_expiration_timestamp_ms`](#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_set_expiration_timestamp_ms)
-  [Function `update_image_url`](#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_update_image_url)
-  [Function `burn`](#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_burn)
-  [Function `has_expired`](#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_has_expired)
-  [Function `has_expired_past_grace_period`](#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_has_expired_past_grace_period)
-  [Function `domain`](#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_domain)
-  [Function `domain_name`](#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_domain_name)
-  [Function `expiration_timestamp_ms`](#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_expiration_timestamp_ms)
-  [Function `image_url`](#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_image_url)
-  [Function `uid`](#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_uid)
-  [Function `uid_mut`](#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_uid_mut)


<pre><code><b>use</b> <a href="dependencies/move-stdlib/string.md#0x1_string">0x1::string</a>;
<b>use</b> <a href="dependencies/sui-framework/clock.md#0x2_clock">0x2::clock</a>;
<b>use</b> <a href="dependencies/sui-framework/object.md#0x2_object">0x2::object</a>;
<b>use</b> <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context">0x2::tx_context</a>;
<b>use</b> <a href="constants.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_constants">0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b::constants</a>;
<b>use</b> <a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b::domain</a>;
</code></pre>



<a name="0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_SuinsRegistration"></a>

## Resource `SuinsRegistration`

The main access point for the user.


<pre><code><b>struct</b> <a href="suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_SuinsRegistration">SuinsRegistration</a> <b>has</b> store, key
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>id: <a href="dependencies/sui-framework/object.md#0x2_object_UID">object::UID</a></code>
</dt>
<dd>

</dd>
<dt>
<code><a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>: <a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain_Domain">domain::Domain</a></code>
</dt>
<dd>
 The parsed domain.
</dd>
<dt>
<code>domain_name: <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a></code>
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
<code>image_url: <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a></code>
</dt>
<dd>
 Short IPFS hash of the image to be displayed for the NFT.
</dd>
</dl>


</details>

<a name="0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_new"></a>

## Function `new`

Creates a new <code><a href="suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_SuinsRegistration">SuinsRegistration</a></code>.
Can only be called by the <code><a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry">registry</a></code> module.


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_new">new</a>(<a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>: <a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain_Domain">domain::Domain</a>, no_years: u8, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &<a href="dependencies/sui-framework/clock.md#0x2_clock_Clock">clock::Clock</a>, ctx: &<b>mut</b> <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context_TxContext">tx_context::TxContext</a>): <a href="suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_SuinsRegistration">suins_registration::SuinsRegistration</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<a href="dependencies/sui-framework/package.md#0x2_package">package</a>) <b>fun</b> <a href="suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_new">new</a>(
    <a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>: Domain,
    no_years: u8,
    <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &Clock,
    ctx: &<b>mut</b> TxContext
): <a href="suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_SuinsRegistration">SuinsRegistration</a> {
    <a href="suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_SuinsRegistration">SuinsRegistration</a> {
        id: <a href="dependencies/sui-framework/object.md#0x2_object_new">object::new</a>(ctx),
        domain_name: <a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>.to_string(),
        <a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>,
        expiration_timestamp_ms: timestamp_ms(<a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>) + ((no_years <b>as</b> u64) * <a href="constants.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_constants_year_ms">constants::year_ms</a>()),
        image_url: <a href="constants.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_constants_default_image">constants::default_image</a>(),
    }
}
</code></pre>



</details>

<a name="0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_set_expiration_timestamp_ms"></a>

## Function `set_expiration_timestamp_ms`

Sets the <code>expiration_timestamp_ms</code> for this NFT.


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_set_expiration_timestamp_ms">set_expiration_timestamp_ms</a>(self: &<b>mut</b> <a href="suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_SuinsRegistration">suins_registration::SuinsRegistration</a>, expiration_timestamp_ms: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<a href="dependencies/sui-framework/package.md#0x2_package">package</a>) <b>fun</b> <a href="suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_set_expiration_timestamp_ms">set_expiration_timestamp_ms</a>(self: &<b>mut</b> <a href="suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_SuinsRegistration">SuinsRegistration</a>, expiration_timestamp_ms: u64) {
    self.expiration_timestamp_ms = expiration_timestamp_ms;
}
</code></pre>



</details>

<a name="0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_update_image_url"></a>

## Function `update_image_url`

Updates the <code>image_url</code> field for this NFT. Is only called in the <code><a href="update_image.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_update_image">update_image</a></code> for now.


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_update_image_url">update_image_url</a>(self: &<b>mut</b> <a href="suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_SuinsRegistration">suins_registration::SuinsRegistration</a>, image_url: <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<a href="dependencies/sui-framework/package.md#0x2_package">package</a>) <b>fun</b> <a href="suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_update_image_url">update_image_url</a>(self: &<b>mut</b> <a href="suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_SuinsRegistration">SuinsRegistration</a>, image_url: String) {
    self.image_url = image_url;
}
</code></pre>



</details>

<a name="0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_burn"></a>

## Function `burn`

Destroys the <code><a href="suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_SuinsRegistration">SuinsRegistration</a></code> by deleting it from the store, returning
storage rebates to the caller.
Can only be called by the <code><a href="registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry">registry</a></code> module.


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_burn">burn</a>(self: <a href="suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_SuinsRegistration">suins_registration::SuinsRegistration</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<a href="dependencies/sui-framework/package.md#0x2_package">package</a>) <b>fun</b> <a href="suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_burn">burn</a>(self: <a href="suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_SuinsRegistration">SuinsRegistration</a>) {
    <b>let</b> <a href="suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_SuinsRegistration">SuinsRegistration</a> {
        id,
        image_url: _,
        <a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>: _,
        domain_name: _,
        expiration_timestamp_ms: _
    } = self;

    id.delete();
}
</code></pre>



</details>

<a name="0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_has_expired"></a>

## Function `has_expired`

Check whether the <code><a href="suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_SuinsRegistration">SuinsRegistration</a></code> has expired by comparing the
expiration timeout with the current time.


<pre><code><b>public</b> <b>fun</b> <a href="suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_has_expired">has_expired</a>(self: &<a href="suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_SuinsRegistration">suins_registration::SuinsRegistration</a>, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &<a href="dependencies/sui-framework/clock.md#0x2_clock_Clock">clock::Clock</a>): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_has_expired">has_expired</a>(self: &<a href="suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_SuinsRegistration">SuinsRegistration</a>, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &Clock): bool {
    self.<a href="suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_expiration_timestamp_ms">expiration_timestamp_ms</a> &lt; timestamp_ms(<a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>)
}
</code></pre>



</details>

<a name="0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_has_expired_past_grace_period"></a>

## Function `has_expired_past_grace_period`

Check whether the <code><a href="suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_SuinsRegistration">SuinsRegistration</a></code> has expired by comparing the
expiration timeout with the current time. This function also takes into
account the grace period.


<pre><code><b>public</b> <b>fun</b> <a href="suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_has_expired_past_grace_period">has_expired_past_grace_period</a>(self: &<a href="suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_SuinsRegistration">suins_registration::SuinsRegistration</a>, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &<a href="dependencies/sui-framework/clock.md#0x2_clock_Clock">clock::Clock</a>): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_has_expired_past_grace_period">has_expired_past_grace_period</a>(self: &<a href="suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_SuinsRegistration">SuinsRegistration</a>, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &Clock): bool {
    (self.expiration_timestamp_ms + <a href="constants.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_constants_grace_period_ms">constants::grace_period_ms</a>()) &lt; timestamp_ms(<a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>)
}
</code></pre>



</details>

<a name="0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_domain"></a>

## Function `domain`

Get the <code><a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a></code> field of the <code><a href="suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_SuinsRegistration">SuinsRegistration</a></code>.


<pre><code><b>public</b> <b>fun</b> <a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>(self: &<a href="suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_SuinsRegistration">suins_registration::SuinsRegistration</a>): <a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain_Domain">domain::Domain</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>(self: &<a href="suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_SuinsRegistration">SuinsRegistration</a>): Domain { self.<a href="domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a> }
</code></pre>



</details>

<a name="0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_domain_name"></a>

## Function `domain_name`

Get the <code>domain_name</code> field of the <code><a href="suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_SuinsRegistration">SuinsRegistration</a></code>.


<pre><code><b>public</b> <b>fun</b> <a href="suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_domain_name">domain_name</a>(self: &<a href="suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_SuinsRegistration">suins_registration::SuinsRegistration</a>): <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_domain_name">domain_name</a>(self: &<a href="suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_SuinsRegistration">SuinsRegistration</a>): String { self.domain_name }
</code></pre>



</details>

<a name="0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_expiration_timestamp_ms"></a>

## Function `expiration_timestamp_ms`

Get the <code>expiration_timestamp_ms</code> field of the <code><a href="suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_SuinsRegistration">SuinsRegistration</a></code>.


<pre><code><b>public</b> <b>fun</b> <a href="suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_expiration_timestamp_ms">expiration_timestamp_ms</a>(self: &<a href="suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_SuinsRegistration">suins_registration::SuinsRegistration</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_expiration_timestamp_ms">expiration_timestamp_ms</a>(self: &<a href="suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_SuinsRegistration">SuinsRegistration</a>): u64 { self.expiration_timestamp_ms }
</code></pre>



</details>

<a name="0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_image_url"></a>

## Function `image_url`

Get the <code>image_url</code> field of the <code><a href="suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_SuinsRegistration">SuinsRegistration</a></code>.


<pre><code><b>public</b> <b>fun</b> <a href="suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_image_url">image_url</a>(self: &<a href="suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_SuinsRegistration">suins_registration::SuinsRegistration</a>): <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_image_url">image_url</a>(self: &<a href="suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_SuinsRegistration">SuinsRegistration</a>): String { self.image_url }
</code></pre>



</details>

<a name="0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_uid"></a>

## Function `uid`



<pre><code><b>public</b> <b>fun</b> <a href="suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_uid">uid</a>(self: &<a href="suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_SuinsRegistration">suins_registration::SuinsRegistration</a>): &<a href="dependencies/sui-framework/object.md#0x2_object_UID">object::UID</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_uid">uid</a>(self: &<a href="suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_SuinsRegistration">SuinsRegistration</a>): &UID { &self.id }
</code></pre>



</details>

<a name="0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_uid_mut"></a>

## Function `uid_mut`

Get the mutable <code>id</code> field of the <code><a href="suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_SuinsRegistration">SuinsRegistration</a></code>.


<pre><code><b>public</b> <b>fun</b> <a href="suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_uid_mut">uid_mut</a>(self: &<b>mut</b> <a href="suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_SuinsRegistration">suins_registration::SuinsRegistration</a>): &<b>mut</b> <a href="dependencies/sui-framework/object.md#0x2_object_UID">object::UID</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_uid_mut">uid_mut</a>(self: &<b>mut</b> <a href="suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_SuinsRegistration">SuinsRegistration</a>): &<b>mut</b> UID { &<b>mut</b> self.id }
</code></pre>



</details>
