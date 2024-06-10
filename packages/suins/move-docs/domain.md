
<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain"></a>

# Module `0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94::domain`

Defines the <code><a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_Domain">Domain</a></code> type and helper functions.

Domains are structured similar to their web2 counterpart and the rules
determining what a valid domain is can be found here:
https://en.wikipedia.org/wiki/Domain_name#Domain_name_syntax


-  [Struct `Domain`](#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_Domain)
-  [Constants](#@Constants_0)
-  [Function `new`](#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_new)
-  [Function `to_string`](#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_to_string)
-  [Function `label`](#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_label)
-  [Function `tld`](#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_tld)
-  [Function `sld`](#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_sld)
-  [Function `number_of_levels`](#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_number_of_levels)
-  [Function `is_subdomain`](#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_is_subdomain)
-  [Function `parent`](#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_parent)
-  [Function `is_parent_of`](#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_is_parent_of)
-  [Function `validate_labels`](#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_validate_labels)
-  [Function `is_valid_label`](#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_is_valid_label)
-  [Function `split_by_dot`](#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_split_by_dot)


<pre><code><b>use</b> <a href="dependencies/move-stdlib/string.md#0x1_string">0x1::string</a>;
<b>use</b> <a href="dependencies/move-stdlib/vector.md#0x1_vector">0x1::vector</a>;
</code></pre>



<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_Domain"></a>

## Struct `Domain`

Representation of a valid SuiNS <code><a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_Domain">Domain</a></code>.


<pre><code><b>struct</b> <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_Domain">Domain</a> <b>has</b> <b>copy</b>, drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>labels: <a href="dependencies/move-stdlib/vector.md#0x1_vector">vector</a>&lt;<a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>&gt;</code>
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


<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_EInvalidDomain"></a>



<pre><code><b>const</b> <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_EInvalidDomain">EInvalidDomain</a>: u64 = 0;
</code></pre>



<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_MAX_DOMAIN_LENGTH"></a>

The maximum length of a full domain


<pre><code><b>const</b> <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_MAX_DOMAIN_LENGTH">MAX_DOMAIN_LENGTH</a>: u64 = 235;
</code></pre>



<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_MAX_LABEL_LENGTH"></a>

The maximum length of an individual label in a domain.


<pre><code><b>const</b> <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_MAX_LABEL_LENGTH">MAX_LABEL_LENGTH</a>: u64 = 63;
</code></pre>



<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_MIN_LABEL_LENGTH"></a>

The minimum length of an individual label in a domain.


<pre><code><b>const</b> <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_MIN_LABEL_LENGTH">MIN_LABEL_LENGTH</a>: u64 = 1;
</code></pre>



<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_new"></a>

## Function `new`



<pre><code><b>public</b> <b>fun</b> <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_new">new</a>(<a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a>: <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>): <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_Domain">domain::Domain</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_new">new</a>(<a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a>: String): <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_Domain">Domain</a> {
    <b>assert</b>!(<a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a>.length() &lt;= <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_MAX_DOMAIN_LENGTH">MAX_DOMAIN_LENGTH</a>, <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_EInvalidDomain">EInvalidDomain</a>);

    <b>let</b> <b>mut</b> labels = <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_split_by_dot">split_by_dot</a>(<a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a>);
    <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_validate_labels">validate_labels</a>(&labels);
    labels.reverse();
    <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_Domain">Domain</a> {
        labels
    }
}
</code></pre>



</details>

<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_to_string"></a>

## Function `to_string`

Converts a domain into a fully-qualified string representation.


<pre><code><b>public</b> <b>fun</b> <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_to_string">to_string</a>(self: &<a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_Domain">domain::Domain</a>): <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_to_string">to_string</a>(self: &<a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_Domain">Domain</a>): String {
    <b>let</b> dot = utf8(b".");
    <b>let</b> len = self.labels.length();
    <b>let</b> <b>mut</b> i = 0;
    <b>let</b> <b>mut</b> out = <a href="dependencies/move-stdlib/string.md#0x1_string_utf8">string::utf8</a>(<a href="dependencies/move-stdlib/vector.md#0x1_vector_empty">vector::empty</a>());

    <b>while</b> (i &lt; len) {
        <b>let</b> part = &self.labels[(len - i) - 1];
        out.append(*part);

        i = i + 1;
        <b>if</b> (i != len) {
            out.append(dot);
        }
    };

    out
}
</code></pre>



</details>

<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_label"></a>

## Function `label`

Returns the <code>label</code> in a domain specified by <code>level</code>.

Given the domain "pay.name.sui" the individual labels have the following levels:
- "pay" - <code>2</code>
- "name" - <code>1</code>
- "sui" - <code>0</code>

This means that the TLD will always be at level <code>0</code>.


<pre><code><b>public</b> <b>fun</b> <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_label">label</a>(self: &<a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_Domain">domain::Domain</a>, level: u64): &<a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_label">label</a>(self: &<a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_Domain">Domain</a>, level: u64): &String {
    &self.labels[level]
}
</code></pre>



</details>

<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_tld"></a>

## Function `tld`

Returns the TLD (Top-Level Domain) of a <code><a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_Domain">Domain</a></code>.

"name.sui" -> "sui"


<pre><code><b>public</b> <b>fun</b> <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_tld">tld</a>(self: &<a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_Domain">domain::Domain</a>): &<a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_tld">tld</a>(self: &<a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_Domain">Domain</a>): &String {
    <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_label">label</a>(self, 0)
}
</code></pre>



</details>

<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_sld"></a>

## Function `sld`

Returns the SLD (Second-Level Domain) of a <code><a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_Domain">Domain</a></code>.

"name.sui" -> "sui"


<pre><code><b>public</b> <b>fun</b> <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_sld">sld</a>(self: &<a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_Domain">domain::Domain</a>): &<a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_sld">sld</a>(self: &<a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_Domain">Domain</a>): &String {
    <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_label">label</a>(self, 1)
}
</code></pre>



</details>

<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_number_of_levels"></a>

## Function `number_of_levels`



<pre><code><b>public</b> <b>fun</b> <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_number_of_levels">number_of_levels</a>(self: &<a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_Domain">domain::Domain</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_number_of_levels">number_of_levels</a>(self: &<a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_Domain">Domain</a>): u64 {
    self.labels.length()
}
</code></pre>



</details>

<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_is_subdomain"></a>

## Function `is_subdomain`



<pre><code><b>public</b> <b>fun</b> <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_is_subdomain">is_subdomain</a>(<a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a>: &<a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_Domain">domain::Domain</a>): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_is_subdomain">is_subdomain</a>(<a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a>: &<a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_Domain">Domain</a>): bool {
    <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_number_of_levels">number_of_levels</a>(<a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a>) &gt; 2
}
</code></pre>



</details>

<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_parent"></a>

## Function `parent`

Derive the parent of a subdomain.
e.g. <code>subdomain.example.<a href="dependencies/sui-framework/sui.md#0x2_sui">sui</a></code> -> <code>example.<a href="dependencies/sui-framework/sui.md#0x2_sui">sui</a></code>


<pre><code><b>public</b> <b>fun</b> <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_parent">parent</a>(<a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a>: &<a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_Domain">domain::Domain</a>): <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_Domain">domain::Domain</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_parent">parent</a>(<a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a>: &<a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_Domain">Domain</a>): <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_Domain">Domain</a> {
    <b>let</b> <b>mut</b> labels = <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a>.labels;
    // we pop the last element and construct the parent from the remaining labels.
    labels.pop_back();

    <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_Domain">Domain</a> {
        labels
    }
}
</code></pre>



</details>

<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_is_parent_of"></a>

## Function `is_parent_of`

Checks if <code>parent</code> domain is a valid parent for <code>child</code>.


<pre><code><b>public</b> <b>fun</b> <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_is_parent_of">is_parent_of</a>(parent: &<a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_Domain">domain::Domain</a>, child: &<a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_Domain">domain::Domain</a>): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_is_parent_of">is_parent_of</a>(parent: &<a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_Domain">Domain</a>, child: &<a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_Domain">Domain</a>): bool {
    <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_number_of_levels">number_of_levels</a>(parent) &lt; <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_number_of_levels">number_of_levels</a>(child) &&
    &<a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_parent">parent</a>(child).labels == &parent.labels
}
</code></pre>



</details>

<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_validate_labels"></a>

## Function `validate_labels`



<pre><code><b>fun</b> <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_validate_labels">validate_labels</a>(labels: &<a href="dependencies/move-stdlib/vector.md#0x1_vector">vector</a>&lt;<a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_validate_labels">validate_labels</a>(labels: &<a href="dependencies/move-stdlib/vector.md#0x1_vector">vector</a>&lt;String&gt;) {
    <b>assert</b>!(!labels.is_empty(), <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_EInvalidDomain">EInvalidDomain</a>);

    <b>let</b> len = labels.length();
    <b>let</b> <b>mut</b> index = 0;

    <b>while</b> (index &lt; len) {
        <b>let</b> label = &labels[index];
        <b>assert</b>!(<a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_is_valid_label">is_valid_label</a>(label), <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_EInvalidDomain">EInvalidDomain</a>);
        index = index + 1;
    }
}
</code></pre>



</details>

<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_is_valid_label"></a>

## Function `is_valid_label`



<pre><code><b>fun</b> <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_is_valid_label">is_valid_label</a>(label: &<a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_is_valid_label">is_valid_label</a>(label: &String): bool {
    <b>let</b> len = label.length();
    <b>let</b> label_bytes = label.bytes();
    <b>let</b> <b>mut</b> index = 0;

    <b>if</b> (!(len &gt;= <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_MIN_LABEL_LENGTH">MIN_LABEL_LENGTH</a> && len &lt;= <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_MAX_LABEL_LENGTH">MAX_LABEL_LENGTH</a>)) {
        <b>return</b> <b>false</b>
    };

    <b>while</b> (index &lt; len) {
        <b>let</b> character = label_bytes[index];
        <b>let</b> is_valid_character =
            (0x61 &lt;= character && character &lt;= 0x7A)                   // a-z
            || (0x30 &lt;= character && character &lt;= 0x39)                // 0-9
            || (character == 0x2D && index != 0 && index != len - 1);  // '-' not at beginning or end

        <b>if</b> (!is_valid_character) {
            <b>return</b> <b>false</b>
        };

        index = index + 1;
    };

    <b>true</b>
}
</code></pre>



</details>

<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_split_by_dot"></a>

## Function `split_by_dot`

Splits a string <code>s</code> by the character <code>.</code> into a vector of subslices, excluding the <code>.</code>


<pre><code><b>fun</b> <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_split_by_dot">split_by_dot</a>(s: <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>): <a href="dependencies/move-stdlib/vector.md#0x1_vector">vector</a>&lt;<a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_split_by_dot">split_by_dot</a>(<b>mut</b> s: String): <a href="dependencies/move-stdlib/vector.md#0x1_vector">vector</a>&lt;String&gt; {
    <b>let</b> dot = utf8(b".");
    <b>let</b> <b>mut</b> parts: <a href="dependencies/move-stdlib/vector.md#0x1_vector">vector</a>&lt;String&gt; = <a href="dependencies/move-stdlib/vector.md#0x1_vector">vector</a>[];
    <b>while</b> (!s.is_empty()) {
        <b>let</b> index_of_next_dot = s.index_of(&dot);
        <b>let</b> part = s.sub_string(0, index_of_next_dot);
        parts.push_back(part);

        <b>let</b> len = s.length();
        <b>let</b> start_of_next_part = <b>if</b> (index_of_next_dot == len) {
            len
        } <b>else</b> {
            index_of_next_dot + 1
        };

        s = s.sub_string(start_of_next_part, len);
    };

    parts
}
</code></pre>



</details>
