
<a name="0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_constants"></a>

# Module `0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0::constants`

Module to wrap all constants used across the project. A sigleton and not
meant to be modified (only extended).

This module is free from any non-framework dependencies and serves as a
single place of storing constants and proving convenient APIs for reading.


-  [Constants](#@Constants_0)
-  [Function `sui_tld`](#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_constants_sui_tld)
-  [Function `default_image`](#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_constants_default_image)
-  [Function `mist_per_sui`](#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_constants_mist_per_sui)
-  [Function `min_domain_length`](#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_constants_min_domain_length)
-  [Function `max_domain_length`](#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_constants_max_domain_length)
-  [Function `max_bps`](#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_constants_max_bps)
-  [Function `year_ms`](#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_constants_year_ms)
-  [Function `grace_period_ms`](#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_constants_grace_period_ms)
-  [Function `subdomain_allow_creation_key`](#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_constants_subdomain_allow_creation_key)
-  [Function `subdomain_allow_extension_key`](#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_constants_subdomain_allow_extension_key)
-  [Function `leaf_expiration_timestamp`](#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_constants_leaf_expiration_timestamp)


<pre><code><b>use</b> <a href="dependencies/move-stdlib/string.md#0x1_string">0x1::string</a>;
</code></pre>



<a name="@Constants_0"></a>

## Constants


<a name="0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_constants_MIST_PER_SUI"></a>

The amount of MIST in 1 SUI.


<pre><code><b>const</b> <a href="constants.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_constants_MIST_PER_SUI">MIST_PER_SUI</a>: u64 = 1000000000;
</code></pre>



<a name="0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_constants_MAX_DOMAIN_LENGTH"></a>

The maximum length of a domain name.


<pre><code><b>const</b> <a href="constants.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_constants_MAX_DOMAIN_LENGTH">MAX_DOMAIN_LENGTH</a>: u8 = 63;
</code></pre>



<a name="0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_constants_ALLOW_CREATION"></a>

Subdomain constants

These constants are the core of the subdomain functionality.
Even if we decide to change the subdomain module, these can
be re-used. They're added as metadata on NameRecord.

Whether a parent name can create child names. (name -> subdomain)


<pre><code><b>const</b> <a href="constants.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_constants_ALLOW_CREATION">ALLOW_CREATION</a>: <a href="dependencies/move-stdlib/vector.md#0x1_vector">vector</a>&lt;u8&gt; = [83, 95, 65, 67];
</code></pre>



<a name="0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_constants_ALLOW_TIME_EXTENSION"></a>

Whether a child-name can auto-renew (if the parent hasn't changed).


<pre><code><b>const</b> <a href="constants.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_constants_ALLOW_TIME_EXTENSION">ALLOW_TIME_EXTENSION</a>: <a href="dependencies/move-stdlib/vector.md#0x1_vector">vector</a>&lt;u8&gt; = [83, 95, 65, 84, 69];
</code></pre>



<a name="0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_constants_DEFAULT_IMAGE"></a>

Default value for the image_url; IPFS hash.


<pre><code><b>const</b> <a href="constants.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_constants_DEFAULT_IMAGE">DEFAULT_IMAGE</a>: <a href="dependencies/move-stdlib/vector.md#0x1_vector">vector</a>&lt;u8&gt; = [81, 109, 97, 76, 70, 103, 52, 116, 81, 89, 97, 110, 115, 70, 112, 121, 82, 113, 109, 68, 102, 65, 66, 100, 107, 85, 86, 121, 54, 54, 100, 72, 116, 112, 110, 107, 72, 49, 53, 118, 49, 76, 80, 122, 99, 89];
</code></pre>



<a name="0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_constants_GRACE_PERIOD_MS"></a>

30 day Grace period in milliseconds.


<pre><code><b>const</b> <a href="constants.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_constants_GRACE_PERIOD_MS">GRACE_PERIOD_MS</a>: u64 = 2592000000;
</code></pre>



<a name="0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_constants_LEAF_EXPIRATION_TIMESTAMP"></a>

A leaf record doesn't expire. Expiration is retrieved by the parent's expiration.


<pre><code><b>const</b> <a href="constants.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_constants_LEAF_EXPIRATION_TIMESTAMP">LEAF_EXPIRATION_TIMESTAMP</a>: u64 = 0;
</code></pre>



<a name="0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_constants_MAX_BPS"></a>

Max value for basis points.


<pre><code><b>const</b> <a href="constants.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_constants_MAX_BPS">MAX_BPS</a>: u16 = 10000;
</code></pre>



<a name="0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_constants_MIN_DOMAIN_LENGTH"></a>

The minimum length of a domain name.


<pre><code><b>const</b> <a href="constants.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_constants_MIN_DOMAIN_LENGTH">MIN_DOMAIN_LENGTH</a>: u8 = 3;
</code></pre>



<a name="0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_constants_SUI_TLD"></a>

Top level domain for SUI.


<pre><code><b>const</b> <a href="constants.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_constants_SUI_TLD">SUI_TLD</a>: <a href="dependencies/move-stdlib/vector.md#0x1_vector">vector</a>&lt;u8&gt; = [115, 117, 105];
</code></pre>



<a name="0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_constants_YEAR_MS"></a>

The amount of milliseconds in a year.


<pre><code><b>const</b> <a href="constants.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_constants_YEAR_MS">YEAR_MS</a>: u64 = 31536000000;
</code></pre>



<a name="0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_constants_sui_tld"></a>

## Function `sui_tld`

Top level domain for SUI as a String.


<pre><code><b>public</b> <b>fun</b> <a href="constants.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_constants_sui_tld">sui_tld</a>(): <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="constants.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_constants_sui_tld">sui_tld</a>(): String { utf8(<a href="constants.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_constants_SUI_TLD">SUI_TLD</a>) }
</code></pre>



</details>

<a name="0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_constants_default_image"></a>

## Function `default_image`

Default value for the image_url.


<pre><code><b>public</b> <b>fun</b> <a href="constants.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_constants_default_image">default_image</a>(): <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="constants.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_constants_default_image">default_image</a>(): String { utf8(<a href="constants.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_constants_DEFAULT_IMAGE">DEFAULT_IMAGE</a>) }
</code></pre>



</details>

<a name="0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_constants_mist_per_sui"></a>

## Function `mist_per_sui`

The amount of MIST in 1 SUI.


<pre><code><b>public</b> <b>fun</b> <a href="constants.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_constants_mist_per_sui">mist_per_sui</a>(): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="constants.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_constants_mist_per_sui">mist_per_sui</a>(): u64 { <a href="constants.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_constants_MIST_PER_SUI">MIST_PER_SUI</a> }
</code></pre>



</details>

<a name="0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_constants_min_domain_length"></a>

## Function `min_domain_length`

The minimum length of a domain name.


<pre><code><b>public</b> <b>fun</b> <a href="constants.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_constants_min_domain_length">min_domain_length</a>(): u8
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="constants.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_constants_min_domain_length">min_domain_length</a>(): u8 { <a href="constants.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_constants_MIN_DOMAIN_LENGTH">MIN_DOMAIN_LENGTH</a> }
</code></pre>



</details>

<a name="0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_constants_max_domain_length"></a>

## Function `max_domain_length`

The maximum length of a domain name.


<pre><code><b>public</b> <b>fun</b> <a href="constants.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_constants_max_domain_length">max_domain_length</a>(): u8
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="constants.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_constants_max_domain_length">max_domain_length</a>(): u8 { <a href="constants.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_constants_MAX_DOMAIN_LENGTH">MAX_DOMAIN_LENGTH</a> }
</code></pre>



</details>

<a name="0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_constants_max_bps"></a>

## Function `max_bps`

Maximum value for basis points.


<pre><code><b>public</b> <b>fun</b> <a href="constants.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_constants_max_bps">max_bps</a>(): u16
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="constants.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_constants_max_bps">max_bps</a>(): u16 { <a href="constants.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_constants_MAX_BPS">MAX_BPS</a> }
</code></pre>



</details>

<a name="0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_constants_year_ms"></a>

## Function `year_ms`

The amount of milliseconds in a year.


<pre><code><b>public</b> <b>fun</b> <a href="constants.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_constants_year_ms">year_ms</a>(): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="constants.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_constants_year_ms">year_ms</a>(): u64 { <a href="constants.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_constants_YEAR_MS">YEAR_MS</a> }
</code></pre>



</details>

<a name="0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_constants_grace_period_ms"></a>

## Function `grace_period_ms`

Grace period in milliseconds after which the domain expires.


<pre><code><b>public</b> <b>fun</b> <a href="constants.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_constants_grace_period_ms">grace_period_ms</a>(): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="constants.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_constants_grace_period_ms">grace_period_ms</a>(): u64 { <a href="constants.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_constants_GRACE_PERIOD_MS">GRACE_PERIOD_MS</a> }
</code></pre>



</details>

<a name="0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_constants_subdomain_allow_creation_key"></a>

## Function `subdomain_allow_creation_key`

Subdomain constants
The NameRecord key that a subdomain can create child names.


<pre><code><b>public</b> <b>fun</b> <a href="constants.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_constants_subdomain_allow_creation_key">subdomain_allow_creation_key</a>(): <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="constants.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_constants_subdomain_allow_creation_key">subdomain_allow_creation_key</a>(): String{ utf8(<a href="constants.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_constants_ALLOW_CREATION">ALLOW_CREATION</a>) }
</code></pre>



</details>

<a name="0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_constants_subdomain_allow_extension_key"></a>

## Function `subdomain_allow_extension_key`

The NameRecord key that a subdomain can self-renew.


<pre><code><b>public</b> <b>fun</b> <a href="constants.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_constants_subdomain_allow_extension_key">subdomain_allow_extension_key</a>(): <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="constants.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_constants_subdomain_allow_extension_key">subdomain_allow_extension_key</a>(): String{ utf8(<a href="constants.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_constants_ALLOW_TIME_EXTENSION">ALLOW_TIME_EXTENSION</a>) }
</code></pre>



</details>

<a name="0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_constants_leaf_expiration_timestamp"></a>

## Function `leaf_expiration_timestamp`

A getter for a leaf name record's expiration timestamp.


<pre><code><b>public</b> <b>fun</b> <a href="constants.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_constants_leaf_expiration_timestamp">leaf_expiration_timestamp</a>(): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="constants.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_constants_leaf_expiration_timestamp">leaf_expiration_timestamp</a>(): u64 { <a href="constants.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_constants_LEAF_EXPIRATION_TIMESTAMP">LEAF_EXPIRATION_TIMESTAMP</a> }
</code></pre>



</details>
