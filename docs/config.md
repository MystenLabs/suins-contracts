
<a name="0x0_config"></a>

# Module `0x0::config`

Module holding the application configuration for the V1 of the SuiNS
application. Responsible for providing the configuration type <code><a href="config.md#0x0_config_Config">Config</a></code> as
well as methods to read it. Additionally, implements necessary input checks
to lessen the chance of a mistake during deployment / configuration stages.

Contains no access-control checks and all methods are public for the
following reasons:
- configuration can only be attached by the application Admin;
- attached to the SuiNS object directly and can only be *read* by other parts of the system;

Notes:
- set_* methods are currently not used;
- a simpler way to update the configuration would be to remove it completely
and set again within the same Programmable Transaction Block (can only be
performed by Admin)


-  [Struct `Config`](#0x0_config_Config)
-  [Constants](#@Constants_0)
-  [Function `new`](#0x0_config_new)
-  [Function `set_public_key`](#0x0_config_set_public_key)
-  [Function `set_three_char_price`](#0x0_config_set_three_char_price)
-  [Function `set_four_char_price`](#0x0_config_set_four_char_price)
-  [Function `set_five_plus_char_price`](#0x0_config_set_five_plus_char_price)
-  [Function `calculate_price`](#0x0_config_calculate_price)
-  [Function `public_key`](#0x0_config_public_key)
-  [Function `three_char_price`](#0x0_config_three_char_price)
-  [Function `four_char_price`](#0x0_config_four_char_price)
-  [Function `five_plus_char_price`](#0x0_config_five_plus_char_price)
-  [Function `assert_valid_user_registerable_domain`](#0x0_config_assert_valid_user_registerable_domain)
-  [Function `check_price`](#0x0_config_check_price)


<pre><code><b>use</b> <a href="constants.md#0x0_constants">0x0::constants</a>;
<b>use</b> <a href="domain.md#0x0_domain">0x0::domain</a>;
<b>use</b> <a href="">0x1::string</a>;
</code></pre>



<a name="0x0_config_Config"></a>

## Struct `Config`

The configuration object, holds current settings of the SuiNS
application. Does not carry any business logic and can easily
be replaced with any other module providing similar interface
and fitting the needs of the application.


<pre><code><b>struct</b> <a href="config.md#0x0_config_Config">Config</a> <b>has</b> drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>public_key: <a href="">vector</a>&lt;u8&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>three_char_price: u64</code>
</dt>
<dd>

</dd>
<dt>
<code>four_char_price: u64</code>
</dt>
<dd>

</dd>
<dt>
<code>five_plus_char_price: u64</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="@Constants_0"></a>

## Constants


<a name="0x0_config_EInvalidDomain"></a>

Trying to register a subdomain (only *.sui is currently allowed).


<pre><code><b>const</b> <a href="config.md#0x0_config_EInvalidDomain">EInvalidDomain</a>: u64 = 5;
</code></pre>



<a name="0x0_config_EInvalidPrice"></a>

The price value is invalid.


<pre><code><b>const</b> <a href="config.md#0x0_config_EInvalidPrice">EInvalidPrice</a>: u64 = 2;
</code></pre>



<a name="0x0_config_EInvalidPublicKey"></a>

The public key is not a Secp256k1 public key which is of length 33 bytes


<pre><code><b>const</b> <a href="config.md#0x0_config_EInvalidPublicKey">EInvalidPublicKey</a>: u64 = 3;
</code></pre>



<a name="0x0_config_EInvalidTld"></a>

Trying to register a domain name in a different TLD (not .sui).


<pre><code><b>const</b> <a href="config.md#0x0_config_EInvalidTld">EInvalidTld</a>: u64 = 6;
</code></pre>



<a name="0x0_config_ELabelTooLong"></a>

A label is too long to be registered.


<pre><code><b>const</b> <a href="config.md#0x0_config_ELabelTooLong">ELabelTooLong</a>: u64 = 1;
</code></pre>



<a name="0x0_config_ELabelTooShort"></a>

A label is too short to be registered.


<pre><code><b>const</b> <a href="config.md#0x0_config_ELabelTooShort">ELabelTooShort</a>: u64 = 0;
</code></pre>



<a name="0x0_config_ENoYears"></a>

Incorrect number of years passed to the function.


<pre><code><b>const</b> <a href="config.md#0x0_config_ENoYears">ENoYears</a>: u64 = 4;
</code></pre>



<a name="0x0_config_new"></a>

## Function `new`

Create a new instance of the configuration object.
Define all properties from the start.


<pre><code><b>public</b> <b>fun</b> <a href="config.md#0x0_config_new">new</a>(public_key: <a href="">vector</a>&lt;u8&gt;, three_char_price: u64, four_char_price: u64, five_plus_char_price: u64): <a href="config.md#0x0_config_Config">config::Config</a>
</code></pre>


<a name="0x0_config_set_public_key"></a>

## Function `set_public_key`

Change the value of the <code>public_key</code> field.


<pre><code><b>public</b> <b>fun</b> <a href="config.md#0x0_config_set_public_key">set_public_key</a>(self: &<b>mut</b> <a href="config.md#0x0_config_Config">config::Config</a>, value: <a href="">vector</a>&lt;u8&gt;)
</code></pre>


<a name="0x0_config_set_three_char_price"></a>

## Function `set_three_char_price`

Change the value of the <code>three_char_price</code> field.


<pre><code><b>public</b> <b>fun</b> <a href="config.md#0x0_config_set_three_char_price">set_three_char_price</a>(self: &<b>mut</b> <a href="config.md#0x0_config_Config">config::Config</a>, value: u64)
</code></pre>


<a name="0x0_config_set_four_char_price"></a>

## Function `set_four_char_price`

Change the value of the <code>four_char_price</code> field.


<pre><code><b>public</b> <b>fun</b> <a href="config.md#0x0_config_set_four_char_price">set_four_char_price</a>(self: &<b>mut</b> <a href="config.md#0x0_config_Config">config::Config</a>, value: u64)
</code></pre>


<a name="0x0_config_set_five_plus_char_price"></a>

## Function `set_five_plus_char_price`

Change the value of the <code>five_plus_char_price</code> field.


<pre><code><b>public</b> <b>fun</b> <a href="config.md#0x0_config_set_five_plus_char_price">set_five_plus_char_price</a>(self: &<b>mut</b> <a href="config.md#0x0_config_Config">config::Config</a>, value: u64)
</code></pre>


<a name="0x0_config_calculate_price"></a>

## Function `calculate_price`

Calculate the price of a label.


<pre><code><b>public</b> <b>fun</b> <a href="config.md#0x0_config_calculate_price">calculate_price</a>(self: &<a href="config.md#0x0_config_Config">config::Config</a>, length: u8, years: u8): u64
</code></pre>


<a name="0x0_config_public_key"></a>

## Function `public_key`

Get the value of the <code>public_key</code> field.


<pre><code><b>public</b> <b>fun</b> <a href="config.md#0x0_config_public_key">public_key</a>(self: &<a href="config.md#0x0_config_Config">config::Config</a>): &<a href="">vector</a>&lt;u8&gt;
</code></pre>


<a name="0x0_config_three_char_price"></a>

## Function `three_char_price`

Get the value of the <code>three_char_price</code> field.


<pre><code><b>public</b> <b>fun</b> <a href="config.md#0x0_config_three_char_price">three_char_price</a>(self: &<a href="config.md#0x0_config_Config">config::Config</a>): u64
</code></pre>


<a name="0x0_config_four_char_price"></a>

## Function `four_char_price`

Get the value of the <code>four_char_price</code> field.


<pre><code><b>public</b> <b>fun</b> <a href="config.md#0x0_config_four_char_price">four_char_price</a>(self: &<a href="config.md#0x0_config_Config">config::Config</a>): u64
</code></pre>


<a name="0x0_config_five_plus_char_price"></a>

## Function `five_plus_char_price`

Get the value of the <code>five_plus_char_price</code> field.


<pre><code><b>public</b> <b>fun</b> <a href="config.md#0x0_config_five_plus_char_price">five_plus_char_price</a>(self: &<a href="config.md#0x0_config_Config">config::Config</a>): u64
</code></pre>


<a name="0x0_config_assert_valid_user_registerable_domain"></a>

## Function `assert_valid_user_registerable_domain`

Asserts that a domain is registerable by a user:
- TLD is "sui"
- only has 1 label, "name", other than the TLD
- "name" is >= 3 characters long


<pre><code><b>public</b> <b>fun</b> <a href="config.md#0x0_config_assert_valid_user_registerable_domain">assert_valid_user_registerable_domain</a>(<a href="domain.md#0x0_domain">domain</a>: &<a href="domain.md#0x0_domain_Domain">domain::Domain</a>)
</code></pre>


<a name="0x0_config_check_price"></a>

## Function `check_price`

Assert that the price is within the allowed range (1-1M).
TODO: revisit, are we sure we can't use less than 1 SUI?


<pre><code><b>fun</b> <a href="config.md#0x0_config_check_price">check_price</a>(price: u64)
</code></pre>