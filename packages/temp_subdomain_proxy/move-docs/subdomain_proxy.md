
<a name="0x16248d179910aa3ebc140b87dd0fd83b9b7c64341616af376dd790242e8dd014_subdomain_proxy"></a>

# Module `0x16248d179910aa3ebc140b87dd0fd83b9b7c64341616af376dd790242e8dd014::subdomain_proxy`

A <code>temporary</code> proxy used to proxy subdomain requests
because we can't use references in a PTB.

Module has no tests as it's a plain proxy for other function calls.
All validation happens on those functions.

This package will stop being used when we've implemented references in PTBs.


-  [Function `new`](#0x16248d179910aa3ebc140b87dd0fd83b9b7c64341616af376dd790242e8dd014_subdomain_proxy_new)
-  [Function `new_leaf`](#0x16248d179910aa3ebc140b87dd0fd83b9b7c64341616af376dd790242e8dd014_subdomain_proxy_new_leaf)
-  [Function `remove_leaf`](#0x16248d179910aa3ebc140b87dd0fd83b9b7c64341616af376dd790242e8dd014_subdomain_proxy_remove_leaf)
-  [Function `edit_setup`](#0x16248d179910aa3ebc140b87dd0fd83b9b7c64341616af376dd790242e8dd014_subdomain_proxy_edit_setup)
-  [Function `set_target_address`](#0x16248d179910aa3ebc140b87dd0fd83b9b7c64341616af376dd790242e8dd014_subdomain_proxy_set_target_address)
-  [Function `set_user_data`](#0x16248d179910aa3ebc140b87dd0fd83b9b7c64341616af376dd790242e8dd014_subdomain_proxy_set_user_data)
-  [Function `unset_user_data`](#0x16248d179910aa3ebc140b87dd0fd83b9b7c64341616af376dd790242e8dd014_subdomain_proxy_unset_user_data)


<pre><code><b>use</b> <a href="dependencies/move-stdlib/option.md#0x1_option">0x1::option</a>;
<b>use</b> <a href="dependencies/move-stdlib/string.md#0x1_string">0x1::string</a>;
<b>use</b> <a href="dependencies/sui-framework/clock.md#0x2_clock">0x2::clock</a>;
<b>use</b> <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context">0x2::tx_context</a>;
<b>use</b> <a href="dependencies/suins/subdomain_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_subdomain_registration">0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b::subdomain_registration</a>;
<b>use</b> <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b::suins</a>;
<b>use</b> <a href="dependencies/suins/suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration">0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b::suins_registration</a>;
<b>use</b> <a href="dependencies/utils/direct_setup.md#0x42cff5d07eca51e9dcef278c9c3a8b98a0f70f06977868614f6eab1a22d9bd89_direct_setup">0x42cff5d07eca51e9dcef278c9c3a8b98a0f70f06977868614f6eab1a22d9bd89::direct_setup</a>;
<b>use</b> <a href="dependencies/subdomains/subdomains.md#0x592c74fa94d44dd22059b3907cec280384847f8025e33aff7930cdff0111bac4_subdomains">0x592c74fa94d44dd22059b3907cec280384847f8025e33aff7930cdff0111bac4::subdomains</a>;
</code></pre>



<a name="0x16248d179910aa3ebc140b87dd0fd83b9b7c64341616af376dd790242e8dd014_subdomain_proxy_new"></a>

## Function `new`



<pre><code><b>public</b> <b>fun</b> <a href="subdomain_proxy.md#0x16248d179910aa3ebc140b87dd0fd83b9b7c64341616af376dd790242e8dd014_subdomain_proxy_new">new</a>(<a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>: &<b>mut</b> <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_SuiNS">suins::SuiNS</a>, subdomain: &<a href="dependencies/suins/subdomain_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_subdomain_registration_SubDomainRegistration">subdomain_registration::SubDomainRegistration</a>, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &<a href="dependencies/sui-framework/clock.md#0x2_clock_Clock">clock::Clock</a>, subdomain_name: <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>, expiration_timestamp_ms: u64, allow_creation: bool, allow_time_extension: bool, ctx: &<b>mut</b> <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context_TxContext">tx_context::TxContext</a>): <a href="dependencies/suins/subdomain_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_subdomain_registration_SubDomainRegistration">subdomain_registration::SubDomainRegistration</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="subdomain_proxy.md#0x16248d179910aa3ebc140b87dd0fd83b9b7c64341616af376dd790242e8dd014_subdomain_proxy_new">new</a>(
    <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>: &<b>mut</b> SuiNS,
    subdomain: &SubDomainRegistration,
    <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &Clock,
    subdomain_name: String,
    expiration_timestamp_ms: u64,
    allow_creation: bool,
    allow_time_extension: bool,
    ctx: &<b>mut</b> TxContext
): SubDomainRegistration {
    <a href="dependencies/subdomains/subdomains.md#0x592c74fa94d44dd22059b3907cec280384847f8025e33aff7930cdff0111bac4_subdomains_new">subdomains::new</a>(
        <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>,
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

<a name="0x16248d179910aa3ebc140b87dd0fd83b9b7c64341616af376dd790242e8dd014_subdomain_proxy_new_leaf"></a>

## Function `new_leaf`



<pre><code><b>public</b> <b>fun</b> <a href="subdomain_proxy.md#0x16248d179910aa3ebc140b87dd0fd83b9b7c64341616af376dd790242e8dd014_subdomain_proxy_new_leaf">new_leaf</a>(<a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>: &<b>mut</b> <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_SuiNS">suins::SuiNS</a>, subdomain: &<a href="dependencies/suins/subdomain_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_subdomain_registration_SubDomainRegistration">subdomain_registration::SubDomainRegistration</a>, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &<a href="dependencies/sui-framework/clock.md#0x2_clock_Clock">clock::Clock</a>, subdomain_name: <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>, target: <b>address</b>, ctx: &<b>mut</b> <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="subdomain_proxy.md#0x16248d179910aa3ebc140b87dd0fd83b9b7c64341616af376dd790242e8dd014_subdomain_proxy_new_leaf">new_leaf</a>(
    <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>: &<b>mut</b> SuiNS,
    subdomain: &SubDomainRegistration,
    <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &Clock,
    subdomain_name: String,
    target: <b>address</b>,
    ctx: &<b>mut</b> TxContext
){
    <a href="dependencies/subdomains/subdomains.md#0x592c74fa94d44dd22059b3907cec280384847f8025e33aff7930cdff0111bac4_subdomains_new_leaf">subdomains::new_leaf</a>(
        <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>,
        subdomain.nft(),
        <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>,
        subdomain_name,
        target,
        ctx
    );
}
</code></pre>



</details>

<a name="0x16248d179910aa3ebc140b87dd0fd83b9b7c64341616af376dd790242e8dd014_subdomain_proxy_remove_leaf"></a>

## Function `remove_leaf`



<pre><code><b>public</b> <b>fun</b> <a href="subdomain_proxy.md#0x16248d179910aa3ebc140b87dd0fd83b9b7c64341616af376dd790242e8dd014_subdomain_proxy_remove_leaf">remove_leaf</a>(<a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>: &<b>mut</b> <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_SuiNS">suins::SuiNS</a>, subdomain: &<a href="dependencies/suins/subdomain_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_subdomain_registration_SubDomainRegistration">subdomain_registration::SubDomainRegistration</a>, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &<a href="dependencies/sui-framework/clock.md#0x2_clock_Clock">clock::Clock</a>, subdomain_name: <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="subdomain_proxy.md#0x16248d179910aa3ebc140b87dd0fd83b9b7c64341616af376dd790242e8dd014_subdomain_proxy_remove_leaf">remove_leaf</a>(
    <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>: &<b>mut</b> SuiNS,
    subdomain: &SubDomainRegistration,
    <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &Clock,
    subdomain_name: String,
) {
    <a href="dependencies/subdomains/subdomains.md#0x592c74fa94d44dd22059b3907cec280384847f8025e33aff7930cdff0111bac4_subdomains_remove_leaf">subdomains::remove_leaf</a>(
        <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>,
        subdomain.nft(),
        <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>,
        subdomain_name,
    );
}
</code></pre>



</details>

<a name="0x16248d179910aa3ebc140b87dd0fd83b9b7c64341616af376dd790242e8dd014_subdomain_proxy_edit_setup"></a>

## Function `edit_setup`



<pre><code><b>public</b> <b>fun</b> <a href="subdomain_proxy.md#0x16248d179910aa3ebc140b87dd0fd83b9b7c64341616af376dd790242e8dd014_subdomain_proxy_edit_setup">edit_setup</a>(<a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>: &<b>mut</b> <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_SuiNS">suins::SuiNS</a>, parent: &<a href="dependencies/suins/subdomain_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_subdomain_registration_SubDomainRegistration">subdomain_registration::SubDomainRegistration</a>, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &<a href="dependencies/sui-framework/clock.md#0x2_clock_Clock">clock::Clock</a>, subdomain_name: <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>, allow_creation: bool, allow_time_extension: bool)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="subdomain_proxy.md#0x16248d179910aa3ebc140b87dd0fd83b9b7c64341616af376dd790242e8dd014_subdomain_proxy_edit_setup">edit_setup</a>(
    <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>: &<b>mut</b> SuiNS,
    parent: &SubDomainRegistration,
    <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &Clock,
    subdomain_name: String,
    allow_creation: bool,
    allow_time_extension: bool
) {
    <a href="dependencies/subdomains/subdomains.md#0x592c74fa94d44dd22059b3907cec280384847f8025e33aff7930cdff0111bac4_subdomains_edit_setup">subdomains::edit_setup</a>(
        <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>,
        parent.nft(),
        <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>,
        subdomain_name,
        allow_creation,
        allow_time_extension
    );
}
</code></pre>



</details>

<a name="0x16248d179910aa3ebc140b87dd0fd83b9b7c64341616af376dd790242e8dd014_subdomain_proxy_set_target_address"></a>

## Function `set_target_address`



<pre><code><b>public</b> <b>fun</b> <a href="subdomain_proxy.md#0x16248d179910aa3ebc140b87dd0fd83b9b7c64341616af376dd790242e8dd014_subdomain_proxy_set_target_address">set_target_address</a>(<a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>: &<b>mut</b> <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_SuiNS">suins::SuiNS</a>, subdomain: &<a href="dependencies/suins/subdomain_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_subdomain_registration_SubDomainRegistration">subdomain_registration::SubDomainRegistration</a>, new_target: <a href="dependencies/move-stdlib/option.md#0x1_option_Option">option::Option</a>&lt;<b>address</b>&gt;, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &<a href="dependencies/sui-framework/clock.md#0x2_clock_Clock">clock::Clock</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="subdomain_proxy.md#0x16248d179910aa3ebc140b87dd0fd83b9b7c64341616af376dd790242e8dd014_subdomain_proxy_set_target_address">set_target_address</a>(
    <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>: &<b>mut</b> SuiNS,
    subdomain: &SubDomainRegistration,
    new_target: Option&lt;<b>address</b>&gt;,
    <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &Clock,
) {
    <a href="dependencies/utils/direct_setup.md#0x42cff5d07eca51e9dcef278c9c3a8b98a0f70f06977868614f6eab1a22d9bd89_direct_setup_set_target_address">direct_setup::set_target_address</a>(
        <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>,
        subdomain.nft(),
        new_target,
        <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>,
    );
}
</code></pre>



</details>

<a name="0x16248d179910aa3ebc140b87dd0fd83b9b7c64341616af376dd790242e8dd014_subdomain_proxy_set_user_data"></a>

## Function `set_user_data`



<pre><code><b>public</b> <b>fun</b> <a href="subdomain_proxy.md#0x16248d179910aa3ebc140b87dd0fd83b9b7c64341616af376dd790242e8dd014_subdomain_proxy_set_user_data">set_user_data</a>(<a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>: &<b>mut</b> <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_SuiNS">suins::SuiNS</a>, subdomain: &<a href="dependencies/suins/subdomain_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_subdomain_registration_SubDomainRegistration">subdomain_registration::SubDomainRegistration</a>, key: <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>, value: <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &<a href="dependencies/sui-framework/clock.md#0x2_clock_Clock">clock::Clock</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="subdomain_proxy.md#0x16248d179910aa3ebc140b87dd0fd83b9b7c64341616af376dd790242e8dd014_subdomain_proxy_set_user_data">set_user_data</a>(
    <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>: &<b>mut</b> SuiNS,
    subdomain: &SubDomainRegistration,
    key: String,
    value: String,
    <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &Clock
) {
    <a href="dependencies/utils/direct_setup.md#0x42cff5d07eca51e9dcef278c9c3a8b98a0f70f06977868614f6eab1a22d9bd89_direct_setup_set_user_data">direct_setup::set_user_data</a>(
        <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>,
        subdomain.nft(),
        key,
        value,
        <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>
    );
}
</code></pre>



</details>

<a name="0x16248d179910aa3ebc140b87dd0fd83b9b7c64341616af376dd790242e8dd014_subdomain_proxy_unset_user_data"></a>

## Function `unset_user_data`



<pre><code><b>public</b> <b>fun</b> <a href="subdomain_proxy.md#0x16248d179910aa3ebc140b87dd0fd83b9b7c64341616af376dd790242e8dd014_subdomain_proxy_unset_user_data">unset_user_data</a>(<a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>: &<b>mut</b> <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_SuiNS">suins::SuiNS</a>, subdomain: &<a href="dependencies/suins/subdomain_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_subdomain_registration_SubDomainRegistration">subdomain_registration::SubDomainRegistration</a>, key: <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &<a href="dependencies/sui-framework/clock.md#0x2_clock_Clock">clock::Clock</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="subdomain_proxy.md#0x16248d179910aa3ebc140b87dd0fd83b9b7c64341616af376dd790242e8dd014_subdomain_proxy_unset_user_data">unset_user_data</a>(
    <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>: &<b>mut</b> SuiNS,
    subdomain: &SubDomainRegistration,
    key: String,
    <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &Clock
) {
    <a href="dependencies/utils/direct_setup.md#0x42cff5d07eca51e9dcef278c9c3a8b98a0f70f06977868614f6eab1a22d9bd89_direct_setup_unset_user_data">direct_setup::unset_user_data</a>(
        <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>,
        subdomain.nft(),
        key,
        <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>
    );
}
</code></pre>



</details>
