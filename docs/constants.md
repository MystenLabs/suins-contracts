
<a name="0x0_constants"></a>

# Module `0x0::constants`

Module to wrap all constants used across the project. A sigleton and not
meant to be modified (only extended).

This module is free from any non-framework dependencies and serves as a
single place of storing constants and proving convenient APIs for reading.


-  [Constants](#@Constants_0)
-  [Function `sui_tld`](#0x0_constants_sui_tld)
-  [Function `default_image`](#0x0_constants_default_image)
-  [Function `mist_per_sui`](#0x0_constants_mist_per_sui)
-  [Function `min_domain_length`](#0x0_constants_min_domain_length)
-  [Function `max_domain_length`](#0x0_constants_max_domain_length)
-  [Function `max_bps`](#0x0_constants_max_bps)
-  [Function `year_ms`](#0x0_constants_year_ms)
-  [Function `grace_period_ms`](#0x0_constants_grace_period_ms)


<pre><code><b>use</b> <a href="">0x1::string</a>;
</code></pre>



<a name="@Constants_0"></a>

## Constants


<a name="0x0_constants_MIST_PER_SUI"></a>

The amount of MIST in 1 SUI.


<pre><code><b>const</b> <a href="constants.md#0x0_constants_MIST_PER_SUI">MIST_PER_SUI</a>: u64 = 1000000000;
</code></pre>



<a name="0x0_constants_MAX_DOMAIN_LENGTH"></a>

The maximum length of a domain name.


<pre><code><b>const</b> <a href="constants.md#0x0_constants_MAX_DOMAIN_LENGTH">MAX_DOMAIN_LENGTH</a>: u8 = 63;
</code></pre>



<a name="0x0_constants_DEFAULT_IMAGE"></a>

Default value for the image_url; IPFS hash.


<pre><code><b>const</b> <a href="constants.md#0x0_constants_DEFAULT_IMAGE">DEFAULT_IMAGE</a>: <a href="">vector</a>&lt;u8&gt; = [81, 109, 97, 76, 70, 103, 52, 116, 81, 89, 97, 110, 115, 70, 112, 121, 82, 113, 109, 68, 102, 65, 66, 100, 107, 85, 86, 121, 54, 54, 100, 72, 116, 112, 110, 107, 72, 49, 53, 118, 49, 76, 80, 122, 99, 89];
</code></pre>



<a name="0x0_constants_GRACE_PERIOD_MS"></a>

30 day Grace period in milliseconds.


<pre><code><b>const</b> <a href="constants.md#0x0_constants_GRACE_PERIOD_MS">GRACE_PERIOD_MS</a>: u64 = 2592000000;
</code></pre>



<a name="0x0_constants_MAX_BPS"></a>

Max value for basis points.


<pre><code><b>const</b> <a href="constants.md#0x0_constants_MAX_BPS">MAX_BPS</a>: u16 = 10000;
</code></pre>



<a name="0x0_constants_MIN_DOMAIN_LENGTH"></a>

The minimum length of a domain name.


<pre><code><b>const</b> <a href="constants.md#0x0_constants_MIN_DOMAIN_LENGTH">MIN_DOMAIN_LENGTH</a>: u8 = 3;
</code></pre>



<a name="0x0_constants_SUI_TLD"></a>

Top level domain for SUI.


<pre><code><b>const</b> <a href="constants.md#0x0_constants_SUI_TLD">SUI_TLD</a>: <a href="">vector</a>&lt;u8&gt; = [115, 117, 105];
</code></pre>



<a name="0x0_constants_YEAR_MS"></a>

The amount of milliseconds in a year.


<pre><code><b>const</b> <a href="constants.md#0x0_constants_YEAR_MS">YEAR_MS</a>: u64 = 31536000000;
</code></pre>



<a name="0x0_constants_sui_tld"></a>

## Function `sui_tld`

Top level domain for SUI as a String.


<pre><code><b>public</b> <b>fun</b> <a href="constants.md#0x0_constants_sui_tld">sui_tld</a>(): <a href="_String">string::String</a>
</code></pre>


<a name="0x0_constants_default_image"></a>

## Function `default_image`

Default value for the image_url.


<pre><code><b>public</b> <b>fun</b> <a href="constants.md#0x0_constants_default_image">default_image</a>(): <a href="_String">string::String</a>
</code></pre>


<a name="0x0_constants_mist_per_sui"></a>

## Function `mist_per_sui`

The amount of MIST in 1 SUI.


<pre><code><b>public</b> <b>fun</b> <a href="constants.md#0x0_constants_mist_per_sui">mist_per_sui</a>(): u64
</code></pre>


<a name="0x0_constants_min_domain_length"></a>

## Function `min_domain_length`

The minimum length of a domain name.


<pre><code><b>public</b> <b>fun</b> <a href="constants.md#0x0_constants_min_domain_length">min_domain_length</a>(): u8
</code></pre>


<a name="0x0_constants_max_domain_length"></a>

## Function `max_domain_length`

The maximum length of a domain name.


<pre><code><b>public</b> <b>fun</b> <a href="constants.md#0x0_constants_max_domain_length">max_domain_length</a>(): u8
</code></pre>


<a name="0x0_constants_max_bps"></a>

## Function `max_bps`

Maximum value for basis points.


<pre><code><b>public</b> <b>fun</b> <a href="constants.md#0x0_constants_max_bps">max_bps</a>(): u16
</code></pre>


<a name="0x0_constants_year_ms"></a>

## Function `year_ms`

The amount of milliseconds in a year.


<pre><code><b>public</b> <b>fun</b> <a href="constants.md#0x0_constants_year_ms">year_ms</a>(): u64
</code></pre>


<a name="0x0_constants_grace_period_ms"></a>

## Function `grace_period_ms`

Grace period in milliseconds after which the domain expires.


<pre><code><b>public</b> <b>fun</b> <a href="constants.md#0x0_constants_grace_period_ms">grace_period_ms</a>(): u64
</code></pre>
