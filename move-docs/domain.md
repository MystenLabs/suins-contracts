
<a name="0x0_domain"></a>

# Module `0x0::domain`

Defines the <code><a href="domain.md#0x0_domain_Domain">Domain</a></code> type and helper functions.

Domains are structured similar to their web2 counterpart and the rules
determining what a valid domain is can be found here:
https://en.wikipedia.org/wiki/Domain_name#Domain_name_syntax


-  [Struct `Domain`](#0x0_domain_Domain)
-  [Constants](#@Constants_0)
-  [Function `new`](#0x0_domain_new)
-  [Function `to_string`](#0x0_domain_to_string)
-  [Function `label`](#0x0_domain_label)
-  [Function `tld`](#0x0_domain_tld)
-  [Function `sld`](#0x0_domain_sld)
-  [Function `number_of_levels`](#0x0_domain_number_of_levels)
-  [Function `validate_labels`](#0x0_domain_validate_labels)
-  [Function `is_valid_label`](#0x0_domain_is_valid_label)
-  [Function `split_by_dot`](#0x0_domain_split_by_dot)


<pre><code><b>use</b> <a href="">0x1::string</a>;
<b>use</b> <a href="">0x1::vector</a>;
</code></pre>



<a name="0x0_domain_Domain"></a>

## Struct `Domain`

Representation of a valid SuiNS <code><a href="domain.md#0x0_domain_Domain">Domain</a></code>.


<pre><code><b>struct</b> <a href="domain.md#0x0_domain_Domain">Domain</a> <b>has</b> <b>copy</b>, drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>labels: <a href="">vector</a>&lt;<a href="_String">string::String</a>&gt;</code>
</dt>
<dd>
 Vector of labels that make up a domain.

 Labels are stored in reverse order such that the TLD is always in position <code>0</code>.
 e.g. domain "pay.name.sui" will be stored in the vector as ["sui", "name", "pay"].
</dd>
</dl>


</details>

<a name="@Constants_0"></a>

## Constants


<a name="0x0_domain_EInvalidDomain"></a>



<pre><code><b>const</b> <a href="domain.md#0x0_domain_EInvalidDomain">EInvalidDomain</a>: u64 = 0;
</code></pre>



<a name="0x0_domain_MAX_DOMAIN_LENGTH"></a>

The maximum length of a full domain


<pre><code><b>const</b> <a href="domain.md#0x0_domain_MAX_DOMAIN_LENGTH">MAX_DOMAIN_LENGTH</a>: u64 = 200;
</code></pre>



<a name="0x0_domain_MAX_LABEL_LENGTH"></a>

The maximum length of an individual label in a domain.


<pre><code><b>const</b> <a href="domain.md#0x0_domain_MAX_LABEL_LENGTH">MAX_LABEL_LENGTH</a>: u64 = 63;
</code></pre>



<a name="0x0_domain_MIN_LABEL_LENGTH"></a>

The minimum length of an individual label in a domain.


<pre><code><b>const</b> <a href="domain.md#0x0_domain_MIN_LABEL_LENGTH">MIN_LABEL_LENGTH</a>: u64 = 1;
</code></pre>



<a name="0x0_domain_new"></a>

## Function `new`



<pre><code><b>public</b> <b>fun</b> <a href="domain.md#0x0_domain_new">new</a>(<a href="domain.md#0x0_domain">domain</a>: <a href="_String">string::String</a>): <a href="domain.md#0x0_domain_Domain">domain::Domain</a>
</code></pre>


<a name="0x0_domain_to_string"></a>

## Function `to_string`

Converts a domain into a fully-qualified string representation.


<pre><code><b>public</b> <b>fun</b> <a href="domain.md#0x0_domain_to_string">to_string</a>(self: &<a href="domain.md#0x0_domain_Domain">domain::Domain</a>): <a href="_String">string::String</a>
</code></pre>


<a name="0x0_domain_label"></a>

## Function `label`

Returns the <code>label</code> in a domain specified by <code>level</code>.

Given the domain "pay.name.sui" the individual labels have the following levels:
- "pay" - <code>2</code>
- "name" - <code>1</code>
- "sui" - <code>0</code>

This means that the TLD will always be at level <code>0</code>.


<pre><code><b>public</b> <b>fun</b> <a href="domain.md#0x0_domain_label">label</a>(self: &<a href="domain.md#0x0_domain_Domain">domain::Domain</a>, level: u64): &<a href="_String">string::String</a>
</code></pre>


<a name="0x0_domain_tld"></a>

## Function `tld`

Returns the TLD (Top-Level Domain) of a <code><a href="domain.md#0x0_domain_Domain">Domain</a></code>.

"name.sui" -> "sui"


<pre><code><b>public</b> <b>fun</b> <a href="domain.md#0x0_domain_tld">tld</a>(self: &<a href="domain.md#0x0_domain_Domain">domain::Domain</a>): &<a href="_String">string::String</a>
</code></pre>


<a name="0x0_domain_sld"></a>

## Function `sld`

Returns the SLD (Second-Level Domain) of a <code><a href="domain.md#0x0_domain_Domain">Domain</a></code>.

"name.sui" -> "sui"


<pre><code><b>public</b> <b>fun</b> <a href="domain.md#0x0_domain_sld">sld</a>(self: &<a href="domain.md#0x0_domain_Domain">domain::Domain</a>): &<a href="_String">string::String</a>
</code></pre>


<a name="0x0_domain_number_of_levels"></a>

## Function `number_of_levels`



<pre><code><b>public</b> <b>fun</b> <a href="domain.md#0x0_domain_number_of_levels">number_of_levels</a>(self: &<a href="domain.md#0x0_domain_Domain">domain::Domain</a>): u64
</code></pre>


<a name="0x0_domain_validate_labels"></a>

## Function `validate_labels`



<pre><code><b>fun</b> <a href="domain.md#0x0_domain_validate_labels">validate_labels</a>(labels: &<a href="">vector</a>&lt;<a href="_String">string::String</a>&gt;)
</code></pre>


<a name="0x0_domain_is_valid_label"></a>

## Function `is_valid_label`



<pre><code><b>fun</b> <a href="domain.md#0x0_domain_is_valid_label">is_valid_label</a>(label: &<a href="_String">string::String</a>): bool
</code></pre>


<a name="0x0_domain_split_by_dot"></a>

## Function `split_by_dot`

Splits a string <code>s</code> by the character <code>.</code> into a vector of subslices, excluding the <code>.</code>


<pre><code><b>fun</b> <a href="domain.md#0x0_domain_split_by_dot">split_by_dot</a>(s: <a href="_String">string::String</a>): <a href="">vector</a>&lt;<a href="_String">string::String</a>&gt;
</code></pre>
