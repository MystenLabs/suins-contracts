
<a name="0x0_config"></a>

# Module `0x0::config`



-  [Struct `SubDomainConfig`](#0x0_config_SubDomainConfig)
-  [Constants](#@Constants_0)
-  [Function `default`](#0x0_config_default)
-  [Function `new`](#0x0_config_new)
-  [Function `assert_is_valid_subdomain`](#0x0_config_assert_is_valid_subdomain)
-  [Function `minimum_duration`](#0x0_config_minimum_duration)
-  [Function `has_valid_depth`](#0x0_config_has_valid_depth)
-  [Function `is_valid_tld`](#0x0_config_is_valid_tld)
-  [Function `is_valid_label`](#0x0_config_is_valid_label)


<pre><code><b>use</b> <a href="dependencies/move-stdlib/string.md#0x1_string">0x1::string</a>;
<b>use</b> <a href="dependencies/suins/constants.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_constants">0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0::constants</a>;
<b>use</b> <a href="dependencies/suins/domain.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_domain">0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0::domain</a>;
</code></pre>



<a name="0x0_config_SubDomainConfig"></a>

## Struct `SubDomainConfig`

A Subdomain configuration object.
Holds the allow-listed tlds, the max depth and the minimum label size.


<pre><code><b>struct</b> <a href="config.md#0x0_config_SubDomainConfig">SubDomainConfig</a> <b>has</b> <b>copy</b>, drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>allowed_tlds: <a href="dependencies/move-stdlib/vector.md#0x1_vector">vector</a>&lt;<a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>max_depth: u8</code>
</dt>
<dd>

</dd>
<dt>
<code>min_label_size: u8</code>
</dt>
<dd>

</dd>
<dt>
<code>minimum_duration: u64</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="@Constants_0"></a>

## Constants


<a name="0x0_config_EDepthOutOfLimit"></a>

tries to register a subdomain with a depth more than the one allowed.


<pre><code><b>const</b> <a href="config.md#0x0_config_EDepthOutOfLimit">EDepthOutOfLimit</a>: u64 = 1;
</code></pre>



<a name="0x0_config_EInvalidLabelSize"></a>

tries to register a label of size less than 3.


<pre><code><b>const</b> <a href="config.md#0x0_config_EInvalidLabelSize">EInvalidLabelSize</a>: u64 = 3;
</code></pre>



<a name="0x0_config_EInvalidParent"></a>

tries to register a subdomain with the wrong parent (based on name)


<pre><code><b>const</b> <a href="config.md#0x0_config_EInvalidParent">EInvalidParent</a>: u64 = 2;
</code></pre>



<a name="0x0_config_ENotSupportedTLD"></a>

tries to register a domain with an unsupported tld.


<pre><code><b>const</b> <a href="config.md#0x0_config_ENotSupportedTLD">ENotSupportedTLD</a>: u64 = 4;
</code></pre>



<a name="0x0_config_MAX_SUBDOMAIN_DEPTH"></a>

the maximum depth a subdomain can have -> 8 (+ 2 for TLD, SLD)


<pre><code><b>const</b> <a href="config.md#0x0_config_MAX_SUBDOMAIN_DEPTH">MAX_SUBDOMAIN_DEPTH</a>: u8 = 10;
</code></pre>



<a name="0x0_config_MINIMUM_SUBDOMAIN_DURATION"></a>

Minimum duration for a subdomain in milliseconds. (1 day)


<pre><code><b>const</b> <a href="config.md#0x0_config_MINIMUM_SUBDOMAIN_DURATION">MINIMUM_SUBDOMAIN_DURATION</a>: u64 = 86400000;
</code></pre>



<a name="0x0_config_MIN_LABEL_SIZE"></a>

the minimum size a subdomain label can have.


<pre><code><b>const</b> <a href="config.md#0x0_config_MIN_LABEL_SIZE">MIN_LABEL_SIZE</a>: u8 = 3;
</code></pre>



<a name="0x0_config_default"></a>

## Function `default`



<pre><code><b>public</b> <b>fun</b> <a href="config.md#0x0_config_default">default</a>(): <a href="config.md#0x0_config_SubDomainConfig">config::SubDomainConfig</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="config.md#0x0_config_default">default</a>(): <a href="config.md#0x0_config_SubDomainConfig">SubDomainConfig</a> {
    <a href="config.md#0x0_config_SubDomainConfig">SubDomainConfig</a> {
        allowed_tlds: <a href="dependencies/move-stdlib/vector.md#0x1_vector">vector</a>[sui_tld()],
        max_depth: <a href="config.md#0x0_config_MAX_SUBDOMAIN_DEPTH">MAX_SUBDOMAIN_DEPTH</a>,
        min_label_size: <a href="config.md#0x0_config_MIN_LABEL_SIZE">MIN_LABEL_SIZE</a>,
        minimum_duration: <a href="config.md#0x0_config_MINIMUM_SUBDOMAIN_DURATION">MINIMUM_SUBDOMAIN_DURATION</a>
    }
}
</code></pre>



</details>

<a name="0x0_config_new"></a>

## Function `new`



<pre><code><b>public</b> <b>fun</b> <a href="config.md#0x0_config_new">new</a>(allowed_tlds: <a href="dependencies/move-stdlib/vector.md#0x1_vector">vector</a>&lt;<a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>&gt;, max_depth: u8, min_label_size: u8, minimum_duration: u64): <a href="config.md#0x0_config_SubDomainConfig">config::SubDomainConfig</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="config.md#0x0_config_new">new</a>(
    allowed_tlds: <a href="dependencies/move-stdlib/vector.md#0x1_vector">vector</a>&lt;String&gt;,
    max_depth: u8,
    min_label_size: u8,
    minimum_duration: u64
): <a href="config.md#0x0_config_SubDomainConfig">SubDomainConfig</a> {
    <a href="config.md#0x0_config_SubDomainConfig">SubDomainConfig</a> {
        allowed_tlds,
        max_depth,
        min_label_size,
        minimum_duration
    }
}
</code></pre>



</details>

<a name="0x0_config_assert_is_valid_subdomain"></a>

## Function `assert_is_valid_subdomain`

Validates that the child name is a valid child for parent.


<pre><code><b>public</b> <b>fun</b> <a href="config.md#0x0_config_assert_is_valid_subdomain">assert_is_valid_subdomain</a>(parent: &<a href="dependencies/suins/domain.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_domain_Domain">domain::Domain</a>, child: &<a href="dependencies/suins/domain.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_domain_Domain">domain::Domain</a>, <a href="config.md#0x0_config">config</a>: &<a href="config.md#0x0_config_SubDomainConfig">config::SubDomainConfig</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="config.md#0x0_config_assert_is_valid_subdomain">assert_is_valid_subdomain</a>(parent: &Domain, child: &Domain, <a href="config.md#0x0_config">config</a>: &<a href="config.md#0x0_config_SubDomainConfig">SubDomainConfig</a>) {
    <b>assert</b>!(<a href="config.md#0x0_config_is_valid_tld">is_valid_tld</a>(child, <a href="config.md#0x0_config">config</a>), <a href="config.md#0x0_config_ENotSupportedTLD">ENotSupportedTLD</a>);
    <b>assert</b>!(<a href="config.md#0x0_config_is_valid_label">is_valid_label</a>(child, <a href="config.md#0x0_config">config</a>), <a href="config.md#0x0_config_EInvalidLabelSize">EInvalidLabelSize</a>);
    <b>assert</b>!(<a href="config.md#0x0_config_has_valid_depth">has_valid_depth</a>(child, <a href="config.md#0x0_config">config</a>), <a href="config.md#0x0_config_EDepthOutOfLimit">EDepthOutOfLimit</a>);
    <b>assert</b>!(is_parent_of(parent, child), <a href="config.md#0x0_config_EInvalidParent">EInvalidParent</a>);
}
</code></pre>



</details>

<a name="0x0_config_minimum_duration"></a>

## Function `minimum_duration`



<pre><code><b>public</b> <b>fun</b> <a href="config.md#0x0_config_minimum_duration">minimum_duration</a>(<a href="config.md#0x0_config">config</a>: &<a href="config.md#0x0_config_SubDomainConfig">config::SubDomainConfig</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="config.md#0x0_config_minimum_duration">minimum_duration</a>(<a href="config.md#0x0_config">config</a>: &<a href="config.md#0x0_config_SubDomainConfig">SubDomainConfig</a>): u64 {
    <a href="config.md#0x0_config">config</a>.minimum_duration
}
</code></pre>



</details>

<a name="0x0_config_has_valid_depth"></a>

## Function `has_valid_depth`

Validate that the depth of the subdomain is with the allowed range.


<pre><code><b>public</b> <b>fun</b> <a href="config.md#0x0_config_has_valid_depth">has_valid_depth</a>(<a href="dependencies/suins/domain.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_domain">domain</a>: &<a href="dependencies/suins/domain.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_domain_Domain">domain::Domain</a>, <a href="config.md#0x0_config">config</a>: &<a href="config.md#0x0_config_SubDomainConfig">config::SubDomainConfig</a>): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="config.md#0x0_config_has_valid_depth">has_valid_depth</a>(<a href="dependencies/suins/domain.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_domain">domain</a>: &Domain, <a href="config.md#0x0_config">config</a>: &<a href="config.md#0x0_config_SubDomainConfig">SubDomainConfig</a>): bool {
    <a href="dependencies/suins/domain.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_domain">domain</a>.number_of_levels() &lt;= (<a href="config.md#0x0_config">config</a>.max_depth <b>as</b> u64)
}
</code></pre>



</details>

<a name="0x0_config_is_valid_tld"></a>

## Function `is_valid_tld`

Validates that the TLD of the domain is supported for subdomains.
In the beggining, only .sui names will be supported but we might
want to add support for others (or not allow).
(E.g., with <code>.<b>move</b></code> service, we might want to restrict how subdomains are created)


<pre><code><b>public</b> <b>fun</b> <a href="config.md#0x0_config_is_valid_tld">is_valid_tld</a>(<a href="dependencies/suins/domain.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_domain">domain</a>: &<a href="dependencies/suins/domain.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_domain_Domain">domain::Domain</a>, <a href="config.md#0x0_config">config</a>: &<a href="config.md#0x0_config_SubDomainConfig">config::SubDomainConfig</a>): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="config.md#0x0_config_is_valid_tld">is_valid_tld</a>(<a href="dependencies/suins/domain.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_domain">domain</a>: &Domain, <a href="config.md#0x0_config">config</a>: &<a href="config.md#0x0_config_SubDomainConfig">SubDomainConfig</a>): bool {
    <b>let</b> <b>mut</b> i=0;
    <b>while</b> (i &lt; <a href="config.md#0x0_config">config</a>.allowed_tlds.length()) {
        <b>if</b> (<a href="dependencies/suins/domain.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_domain">domain</a>.tld() == &<a href="config.md#0x0_config">config</a>.allowed_tlds[i]) {
            <b>return</b> <b>true</b>
        };
        i = i + 1;
    };
    <b>return</b> <b>false</b>
}
</code></pre>



</details>

<a name="0x0_config_is_valid_label"></a>

## Function `is_valid_label`

Validate that the subdomain label (e.g. <code>sub</code> in <code>sub.example.<a href="dependencies/sui-framework/sui.md#0x2_sui">sui</a></code>) is valid.
We do not need to check for max length (64), as this is already checked
in the <code>Domain</code> construction.


<pre><code><b>public</b> <b>fun</b> <a href="config.md#0x0_config_is_valid_label">is_valid_label</a>(<a href="dependencies/suins/domain.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_domain">domain</a>: &<a href="dependencies/suins/domain.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_domain_Domain">domain::Domain</a>, <a href="config.md#0x0_config">config</a>: &<a href="config.md#0x0_config_SubDomainConfig">config::SubDomainConfig</a>): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="config.md#0x0_config_is_valid_label">is_valid_label</a>(<a href="dependencies/suins/domain.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_domain">domain</a>: &Domain, <a href="config.md#0x0_config">config</a>: &<a href="config.md#0x0_config_SubDomainConfig">SubDomainConfig</a>): bool {
    // our label is the last <a href="dependencies/move-stdlib/vector.md#0x1_vector">vector</a> element, <b>as</b> labels are stored in reverse order.
    <b>let</b> label = <a href="dependencies/suins/domain.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_domain">domain</a>.label(<a href="dependencies/suins/domain.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_domain">domain</a>.number_of_levels() - 1);
    label.length() &gt;= (<a href="config.md#0x0_config">config</a>.min_label_size <b>as</b> u64)
}
</code></pre>



</details>
