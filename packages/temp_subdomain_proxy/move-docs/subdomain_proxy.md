
<a name="0xae5f3d861bf8217f8a68e416d586e868887c8933b43034c31c1800e892105ecb_subdomain_proxy"></a>

# Module `0xae5f3d861bf8217f8a68e416d586e868887c8933b43034c31c1800e892105ecb::subdomain_proxy`

A <code>temporary</code> proxy used to proxy subdomain requests
because we can't use references in a PTB.

Module has no tests as it's a plain proxy for other function calls.
All validation happens on those functions.

This package will stop being used when we've implemented references in PTBs.


-  [Function `new`](#0xae5f3d861bf8217f8a68e416d586e868887c8933b43034c31c1800e892105ecb_subdomain_proxy_new)
-  [Function `new_leaf`](#0xae5f3d861bf8217f8a68e416d586e868887c8933b43034c31c1800e892105ecb_subdomain_proxy_new_leaf)
-  [Function `remove_leaf`](#0xae5f3d861bf8217f8a68e416d586e868887c8933b43034c31c1800e892105ecb_subdomain_proxy_remove_leaf)
-  [Function `edit_setup`](#0xae5f3d861bf8217f8a68e416d586e868887c8933b43034c31c1800e892105ecb_subdomain_proxy_edit_setup)
-  [Function `set_target_address`](#0xae5f3d861bf8217f8a68e416d586e868887c8933b43034c31c1800e892105ecb_subdomain_proxy_set_target_address)
-  [Function `set_user_data`](#0xae5f3d861bf8217f8a68e416d586e868887c8933b43034c31c1800e892105ecb_subdomain_proxy_set_user_data)
-  [Function `unset_user_data`](#0xae5f3d861bf8217f8a68e416d586e868887c8933b43034c31c1800e892105ecb_subdomain_proxy_unset_user_data)


<pre><code><b>use</b> <a href="dependencies/move-stdlib/option.md#0x1_option">0x1::option</a>;
<b>use</b> <a href="dependencies/move-stdlib/string.md#0x1_string">0x1::string</a>;
<b>use</b> <a href="dependencies/sui-framework/clock.md#0x2_clock">0x2::clock</a>;
<b>use</b> <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context">0x2::tx_context</a>;
<b>use</b> <a href="dependencies/subdomains/subdomains.md#0x42f86f6582fcf0ee56efea33f13427e4f4cbe2f6b87686809073ac898a1a91d3_subdomains">0x42f86f6582fcf0ee56efea33f13427e4f4cbe2f6b87686809073ac898a1a91d3::subdomains</a>;
<b>use</b> <a href="dependencies/suins/subdomain_registration.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_subdomain_registration">0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94::subdomain_registration</a>;
<b>use</b> <a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94::suins</a>;
<b>use</b> <a href="dependencies/suins/suins_registration.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_registration">0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94::suins_registration</a>;
<b>use</b> <a href="dependencies/utils/direct_setup.md#0xe52fa8c249c9f303c6ecfff976cdfe68ae7906552725c8a9155756a9a53ad41e_direct_setup">0xe52fa8c249c9f303c6ecfff976cdfe68ae7906552725c8a9155756a9a53ad41e::direct_setup</a>;
</code></pre>



<a name="0xae5f3d861bf8217f8a68e416d586e868887c8933b43034c31c1800e892105ecb_subdomain_proxy_new"></a>

## Function `new`



<pre><code><b>public</b> <b>fun</b> <a href="subdomain_proxy.md#0xae5f3d861bf8217f8a68e416d586e868887c8933b43034c31c1800e892105ecb_subdomain_proxy_new">new</a>(<a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>: &<b>mut</b> <a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_SuiNS">suins::SuiNS</a>, subdomain: &<a href="dependencies/suins/subdomain_registration.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_subdomain_registration_SubDomainRegistration">subdomain_registration::SubDomainRegistration</a>, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &<a href="dependencies/sui-framework/clock.md#0x2_clock_Clock">clock::Clock</a>, subdomain_name: <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>, expiration_timestamp_ms: u64, allow_creation: bool, allow_time_extension: bool, ctx: &<b>mut</b> <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context_TxContext">tx_context::TxContext</a>): <a href="dependencies/suins/subdomain_registration.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_subdomain_registration_SubDomainRegistration">subdomain_registration::SubDomainRegistration</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="subdomain_proxy.md#0xae5f3d861bf8217f8a68e416d586e868887c8933b43034c31c1800e892105ecb_subdomain_proxy_new">new</a>(
    <a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>: &<b>mut</b> SuiNS,
    subdomain: &SubDomainRegistration,
    <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &Clock,
    subdomain_name: String,
    expiration_timestamp_ms: u64,
    allow_creation: bool,
    allow_time_extension: bool,
    ctx: &<b>mut</b> TxContext
): SubDomainRegistration {
    <a href="dependencies/subdomains/subdomains.md#0x42f86f6582fcf0ee56efea33f13427e4f4cbe2f6b87686809073ac898a1a91d3_subdomains_new">subdomains::new</a>(
        <a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>,
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

<a name="0xae5f3d861bf8217f8a68e416d586e868887c8933b43034c31c1800e892105ecb_subdomain_proxy_new_leaf"></a>

## Function `new_leaf`



<pre><code><b>public</b> <b>fun</b> <a href="subdomain_proxy.md#0xae5f3d861bf8217f8a68e416d586e868887c8933b43034c31c1800e892105ecb_subdomain_proxy_new_leaf">new_leaf</a>(<a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>: &<b>mut</b> <a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_SuiNS">suins::SuiNS</a>, subdomain: &<a href="dependencies/suins/subdomain_registration.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_subdomain_registration_SubDomainRegistration">subdomain_registration::SubDomainRegistration</a>, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &<a href="dependencies/sui-framework/clock.md#0x2_clock_Clock">clock::Clock</a>, subdomain_name: <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>, target: <b>address</b>, ctx: &<b>mut</b> <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="subdomain_proxy.md#0xae5f3d861bf8217f8a68e416d586e868887c8933b43034c31c1800e892105ecb_subdomain_proxy_new_leaf">new_leaf</a>(
    <a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>: &<b>mut</b> SuiNS,
    subdomain: &SubDomainRegistration,
    <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &Clock,
    subdomain_name: String,
    target: <b>address</b>,
    ctx: &<b>mut</b> TxContext
){
    <a href="dependencies/subdomains/subdomains.md#0x42f86f6582fcf0ee56efea33f13427e4f4cbe2f6b87686809073ac898a1a91d3_subdomains_new_leaf">subdomains::new_leaf</a>(
        <a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>,
        subdomain.nft(),
        <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>,
        subdomain_name,
        target,
        ctx
    );
}
</code></pre>



</details>

<a name="0xae5f3d861bf8217f8a68e416d586e868887c8933b43034c31c1800e892105ecb_subdomain_proxy_remove_leaf"></a>

## Function `remove_leaf`



<pre><code><b>public</b> <b>fun</b> <a href="subdomain_proxy.md#0xae5f3d861bf8217f8a68e416d586e868887c8933b43034c31c1800e892105ecb_subdomain_proxy_remove_leaf">remove_leaf</a>(<a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>: &<b>mut</b> <a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_SuiNS">suins::SuiNS</a>, subdomain: &<a href="dependencies/suins/subdomain_registration.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_subdomain_registration_SubDomainRegistration">subdomain_registration::SubDomainRegistration</a>, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &<a href="dependencies/sui-framework/clock.md#0x2_clock_Clock">clock::Clock</a>, subdomain_name: <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="subdomain_proxy.md#0xae5f3d861bf8217f8a68e416d586e868887c8933b43034c31c1800e892105ecb_subdomain_proxy_remove_leaf">remove_leaf</a>(
    <a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>: &<b>mut</b> SuiNS,
    subdomain: &SubDomainRegistration,
    <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &Clock,
    subdomain_name: String,
) {
    <a href="dependencies/subdomains/subdomains.md#0x42f86f6582fcf0ee56efea33f13427e4f4cbe2f6b87686809073ac898a1a91d3_subdomains_remove_leaf">subdomains::remove_leaf</a>(
        <a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>,
        subdomain.nft(),
        <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>,
        subdomain_name,
    );
}
</code></pre>



</details>

<a name="0xae5f3d861bf8217f8a68e416d586e868887c8933b43034c31c1800e892105ecb_subdomain_proxy_edit_setup"></a>

## Function `edit_setup`



<pre><code><b>public</b> <b>fun</b> <a href="subdomain_proxy.md#0xae5f3d861bf8217f8a68e416d586e868887c8933b43034c31c1800e892105ecb_subdomain_proxy_edit_setup">edit_setup</a>(<a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>: &<b>mut</b> <a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_SuiNS">suins::SuiNS</a>, parent: &<a href="dependencies/suins/subdomain_registration.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_subdomain_registration_SubDomainRegistration">subdomain_registration::SubDomainRegistration</a>, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &<a href="dependencies/sui-framework/clock.md#0x2_clock_Clock">clock::Clock</a>, subdomain_name: <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>, allow_creation: bool, allow_time_extension: bool)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="subdomain_proxy.md#0xae5f3d861bf8217f8a68e416d586e868887c8933b43034c31c1800e892105ecb_subdomain_proxy_edit_setup">edit_setup</a>(
    <a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>: &<b>mut</b> SuiNS,
    parent: &SubDomainRegistration,
    <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &Clock,
    subdomain_name: String,
    allow_creation: bool,
    allow_time_extension: bool
) {
    <a href="dependencies/subdomains/subdomains.md#0x42f86f6582fcf0ee56efea33f13427e4f4cbe2f6b87686809073ac898a1a91d3_subdomains_edit_setup">subdomains::edit_setup</a>(
        <a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>,
        parent.nft(),
        <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>,
        subdomain_name,
        allow_creation,
        allow_time_extension
    );
}
</code></pre>



</details>

<a name="0xae5f3d861bf8217f8a68e416d586e868887c8933b43034c31c1800e892105ecb_subdomain_proxy_set_target_address"></a>

## Function `set_target_address`



<pre><code><b>public</b> <b>fun</b> <a href="subdomain_proxy.md#0xae5f3d861bf8217f8a68e416d586e868887c8933b43034c31c1800e892105ecb_subdomain_proxy_set_target_address">set_target_address</a>(<a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>: &<b>mut</b> <a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_SuiNS">suins::SuiNS</a>, subdomain: &<a href="dependencies/suins/subdomain_registration.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_subdomain_registration_SubDomainRegistration">subdomain_registration::SubDomainRegistration</a>, new_target: <a href="dependencies/move-stdlib/option.md#0x1_option_Option">option::Option</a>&lt;<b>address</b>&gt;, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &<a href="dependencies/sui-framework/clock.md#0x2_clock_Clock">clock::Clock</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="subdomain_proxy.md#0xae5f3d861bf8217f8a68e416d586e868887c8933b43034c31c1800e892105ecb_subdomain_proxy_set_target_address">set_target_address</a>(
    <a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>: &<b>mut</b> SuiNS,
    subdomain: &SubDomainRegistration,
    new_target: Option&lt;<b>address</b>&gt;,
    <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &Clock,
) {
    <a href="dependencies/utils/direct_setup.md#0xe52fa8c249c9f303c6ecfff976cdfe68ae7906552725c8a9155756a9a53ad41e_direct_setup_set_target_address">direct_setup::set_target_address</a>(
        <a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>,
        subdomain.nft(),
        new_target,
        <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>,
    );
}
</code></pre>



</details>

<a name="0xae5f3d861bf8217f8a68e416d586e868887c8933b43034c31c1800e892105ecb_subdomain_proxy_set_user_data"></a>

## Function `set_user_data`



<pre><code><b>public</b> <b>fun</b> <a href="subdomain_proxy.md#0xae5f3d861bf8217f8a68e416d586e868887c8933b43034c31c1800e892105ecb_subdomain_proxy_set_user_data">set_user_data</a>(<a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>: &<b>mut</b> <a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_SuiNS">suins::SuiNS</a>, subdomain: &<a href="dependencies/suins/subdomain_registration.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_subdomain_registration_SubDomainRegistration">subdomain_registration::SubDomainRegistration</a>, key: <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>, value: <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &<a href="dependencies/sui-framework/clock.md#0x2_clock_Clock">clock::Clock</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="subdomain_proxy.md#0xae5f3d861bf8217f8a68e416d586e868887c8933b43034c31c1800e892105ecb_subdomain_proxy_set_user_data">set_user_data</a>(
    <a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>: &<b>mut</b> SuiNS,
    subdomain: &SubDomainRegistration,
    key: String,
    value: String,
    <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &Clock
) {
    <a href="dependencies/utils/direct_setup.md#0xe52fa8c249c9f303c6ecfff976cdfe68ae7906552725c8a9155756a9a53ad41e_direct_setup_set_user_data">direct_setup::set_user_data</a>(
        <a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>,
        subdomain.nft(),
        key,
        value,
        <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>
    );
}
</code></pre>



</details>

<a name="0xae5f3d861bf8217f8a68e416d586e868887c8933b43034c31c1800e892105ecb_subdomain_proxy_unset_user_data"></a>

## Function `unset_user_data`



<pre><code><b>public</b> <b>fun</b> <a href="subdomain_proxy.md#0xae5f3d861bf8217f8a68e416d586e868887c8933b43034c31c1800e892105ecb_subdomain_proxy_unset_user_data">unset_user_data</a>(<a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>: &<b>mut</b> <a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_SuiNS">suins::SuiNS</a>, subdomain: &<a href="dependencies/suins/subdomain_registration.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_subdomain_registration_SubDomainRegistration">subdomain_registration::SubDomainRegistration</a>, key: <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &<a href="dependencies/sui-framework/clock.md#0x2_clock_Clock">clock::Clock</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="subdomain_proxy.md#0xae5f3d861bf8217f8a68e416d586e868887c8933b43034c31c1800e892105ecb_subdomain_proxy_unset_user_data">unset_user_data</a>(
    <a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>: &<b>mut</b> SuiNS,
    subdomain: &SubDomainRegistration,
    key: String,
    <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &Clock
) {
    <a href="dependencies/utils/direct_setup.md#0xe52fa8c249c9f303c6ecfff976cdfe68ae7906552725c8a9155756a9a53ad41e_direct_setup_unset_user_data">direct_setup::unset_user_data</a>(
        <a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>,
        subdomain.nft(),
        key,
        <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>
    );
}
</code></pre>



</details>
