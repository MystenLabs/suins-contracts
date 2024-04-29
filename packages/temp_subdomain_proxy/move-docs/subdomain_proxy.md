
<a name="0x0_subdomain_proxy"></a>

# Module `0x0::subdomain_proxy`

A <code>temporary</code> proxy used to proxy subdomain requests
because we can't use references in a PTB.

Module has no tests as it's a plain proxy for other function calls.
All validation happens on those functions.

This package will stop being used when we've implemented references in PTBs.


-  [Function `new`](#0x0_subdomain_proxy_new)
-  [Function `new_leaf`](#0x0_subdomain_proxy_new_leaf)
-  [Function `remove_leaf`](#0x0_subdomain_proxy_remove_leaf)
-  [Function `set_target_address`](#0x0_subdomain_proxy_set_target_address)


<pre><code><b>use</b> <a href="dependencies/utils/direct_setup.md#0x0_direct_setup">0x0::direct_setup</a>;
<b>use</b> <a href="dependencies/subdomains/subdomains.md#0x0_subdomains">0x0::subdomains</a>;
<b>use</b> <a href="dependencies/move-stdlib/option.md#0x1_option">0x1::option</a>;
<b>use</b> <a href="dependencies/move-stdlib/string.md#0x1_string">0x1::string</a>;
<b>use</b> <a href="dependencies/sui-framework/clock.md#0x2_clock">0x2::clock</a>;
<b>use</b> <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context">0x2::tx_context</a>;
<b>use</b> <a href="dependencies/suins/subdomain_registration.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_subdomain_registration">0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0::subdomain_registration</a>;
<b>use</b> <a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0::suins</a>;
<b>use</b> <a href="dependencies/suins/suins_registration.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins_registration">0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0::suins_registration</a>;
</code></pre>



<a name="0x0_subdomain_proxy_new"></a>

## Function `new`



<pre><code><b>public</b> <b>fun</b> <a href="subdomain_proxy.md#0x0_subdomain_proxy_new">new</a>(<a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>: &<b>mut</b> <a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins_SuiNS">suins::SuiNS</a>, subdomain: &<a href="dependencies/suins/subdomain_registration.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_subdomain_registration_SubDomainRegistration">subdomain_registration::SubDomainRegistration</a>, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &<a href="dependencies/sui-framework/clock.md#0x2_clock_Clock">clock::Clock</a>, subdomain_name: <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>, expiration_timestamp_ms: u64, allow_creation: bool, allow_time_extension: bool, ctx: &<b>mut</b> <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context_TxContext">tx_context::TxContext</a>): <a href="dependencies/suins/subdomain_registration.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_subdomain_registration_SubDomainRegistration">subdomain_registration::SubDomainRegistration</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="subdomain_proxy.md#0x0_subdomain_proxy_new">new</a>(
    <a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>: &<b>mut</b> SuiNS,
    subdomain: &SubDomainRegistration,
    <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &Clock,
    subdomain_name: String,
    expiration_timestamp_ms: u64,
    allow_creation: bool,
    allow_time_extension: bool,
    ctx: &<b>mut</b> TxContext
): SubDomainRegistration {
    <a href="dependencies/subdomains/subdomains.md#0x0_subdomains_new">subdomains::new</a>(
        <a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>,
        subdomain.nft(),
        <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>,
        subdomain_name,
        expiration_timestamp_ms,
        allow_creation,
        allow_time_extension,
        ctx
    )
}
</code></pre>



</details>

<a name="0x0_subdomain_proxy_new_leaf"></a>

## Function `new_leaf`



<pre><code><b>public</b> <b>fun</b> <a href="subdomain_proxy.md#0x0_subdomain_proxy_new_leaf">new_leaf</a>(<a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>: &<b>mut</b> <a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins_SuiNS">suins::SuiNS</a>, subdomain: &<a href="dependencies/suins/subdomain_registration.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_subdomain_registration_SubDomainRegistration">subdomain_registration::SubDomainRegistration</a>, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &<a href="dependencies/sui-framework/clock.md#0x2_clock_Clock">clock::Clock</a>, subdomain_name: <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>, target: <b>address</b>, ctx: &<b>mut</b> <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="subdomain_proxy.md#0x0_subdomain_proxy_new_leaf">new_leaf</a>(
    <a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>: &<b>mut</b> SuiNS,
    subdomain: &SubDomainRegistration,
    <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &Clock,
    subdomain_name: String,
    target: <b>address</b>,
    ctx: &<b>mut</b> TxContext
){
    <a href="dependencies/subdomains/subdomains.md#0x0_subdomains_new_leaf">subdomains::new_leaf</a>(
        <a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>,
        subdomain.nft(),
        <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>,
        subdomain_name,
        target,
        ctx
    );
}
</code></pre>



</details>

<a name="0x0_subdomain_proxy_remove_leaf"></a>

## Function `remove_leaf`



<pre><code><b>public</b> <b>fun</b> <a href="subdomain_proxy.md#0x0_subdomain_proxy_remove_leaf">remove_leaf</a>(<a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>: &<b>mut</b> <a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins_SuiNS">suins::SuiNS</a>, subdomain: &<a href="dependencies/suins/subdomain_registration.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_subdomain_registration_SubDomainRegistration">subdomain_registration::SubDomainRegistration</a>, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &<a href="dependencies/sui-framework/clock.md#0x2_clock_Clock">clock::Clock</a>, subdomain_name: <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="subdomain_proxy.md#0x0_subdomain_proxy_remove_leaf">remove_leaf</a>(
    <a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>: &<b>mut</b> SuiNS,
    subdomain: &SubDomainRegistration,
    <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &Clock,
    subdomain_name: String,
) {
    <a href="dependencies/subdomains/subdomains.md#0x0_subdomains_remove_leaf">subdomains::remove_leaf</a>(
        <a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>,
        subdomain.nft(),
        <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>,
        subdomain_name,
    );
}
</code></pre>



</details>

<a name="0x0_subdomain_proxy_set_target_address"></a>

## Function `set_target_address`



<pre><code><b>public</b> <b>fun</b> <a href="subdomain_proxy.md#0x0_subdomain_proxy_set_target_address">set_target_address</a>(<a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>: &<b>mut</b> <a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins_SuiNS">suins::SuiNS</a>, subdomain: &<a href="dependencies/suins/subdomain_registration.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_subdomain_registration_SubDomainRegistration">subdomain_registration::SubDomainRegistration</a>, new_target: <a href="dependencies/move-stdlib/option.md#0x1_option_Option">option::Option</a>&lt;<b>address</b>&gt;, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &<a href="dependencies/sui-framework/clock.md#0x2_clock_Clock">clock::Clock</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="subdomain_proxy.md#0x0_subdomain_proxy_set_target_address">set_target_address</a>(
    <a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>: &<b>mut</b> SuiNS,
    subdomain: &SubDomainRegistration,
    new_target: Option&lt;<b>address</b>&gt;,
    <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &Clock,
) {
    <a href="dependencies/utils/direct_setup.md#0x0_direct_setup_set_target_address">direct_setup::set_target_address</a>(
        <a href="dependencies/suins/suins.md#0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0_suins">suins</a>,
        subdomain.nft(),
        new_target,
        <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>,
    );
}
</code></pre>



</details>
