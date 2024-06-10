
<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_subdomain_registration"></a>

# Module `0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94::subdomain_registration`

A wrapper for <code>SuinsRegistration</code> subdomain objects.

With the wrapper, we are allowing easier distinction between second
level names & subdomains in RPC Querying | filtering.

We maintain all core functionality unchanged for registry, expiration etc.


-  [Resource `SubDomainRegistration`](#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_subdomain_registration_SubDomainRegistration)
-  [Constants](#@Constants_0)
-  [Function `new`](#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_subdomain_registration_new)
-  [Function `burn`](#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_subdomain_registration_burn)
-  [Function `nft`](#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_subdomain_registration_nft)
-  [Function `nft_mut`](#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_subdomain_registration_nft_mut)


<pre><code><b>use</b> <a href="dependencies/sui-framework/clock.md#0x2_clock">0x2::clock</a>;
<b>use</b> <a href="dependencies/sui-framework/object.md#0x2_object">0x2::object</a>;
<b>use</b> <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context">0x2::tx_context</a>;
<b>use</b> <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94::domain</a>;
<b>use</b> <a href="suins_registration.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_registration">0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94::suins_registration</a>;
</code></pre>



<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_subdomain_registration_SubDomainRegistration"></a>

## Resource `SubDomainRegistration`

A wrapper for SuinsRegistration object specifically for SubNames.


<pre><code><b>struct</b> <a href="subdomain_registration.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_subdomain_registration_SubDomainRegistration">SubDomainRegistration</a> <b>has</b> store, key
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
<code>nft: <a href="suins_registration.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_registration_SuinsRegistration">suins_registration::SuinsRegistration</a></code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="@Constants_0"></a>

## Constants


<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_subdomain_registration_EExpired"></a>

=== Error codes ===

NFT is expired.


<pre><code><b>const</b> <a href="subdomain_registration.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_subdomain_registration_EExpired">EExpired</a>: u64 = 1;
</code></pre>



<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_subdomain_registration_ENameNotExpired"></a>

Tries to destroy a subdomain that has not expired.


<pre><code><b>const</b> <a href="subdomain_registration.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_subdomain_registration_ENameNotExpired">ENameNotExpired</a>: u64 = 3;
</code></pre>



<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_subdomain_registration_ENotSubdomain"></a>

NFT is not a subdomain.


<pre><code><b>const</b> <a href="subdomain_registration.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_subdomain_registration_ENotSubdomain">ENotSubdomain</a>: u64 = 2;
</code></pre>



<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_subdomain_registration_new"></a>

## Function `new`

Creates a <code>SubName</code> wrapper for SuinsRegistration object
(as long as it's used for a subdomain).


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="subdomain_registration.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_subdomain_registration_new">new</a>(nft: <a href="suins_registration.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_registration_SuinsRegistration">suins_registration::SuinsRegistration</a>, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &<a href="dependencies/sui-framework/clock.md#0x2_clock_Clock">clock::Clock</a>, ctx: &<b>mut</b> <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context_TxContext">tx_context::TxContext</a>): <a href="subdomain_registration.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_subdomain_registration_SubDomainRegistration">subdomain_registration::SubDomainRegistration</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<a href="dependencies/sui-framework/package.md#0x2_package">package</a>) <b>fun</b> <a href="subdomain_registration.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_subdomain_registration_new">new</a>(nft: SuinsRegistration, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &Clock, ctx: &<b>mut</b> TxContext): <a href="subdomain_registration.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_subdomain_registration_SubDomainRegistration">SubDomainRegistration</a> {
    // Can't wrap a non-subdomain NFT.
    <b>assert</b>!(nft.<a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a>().is_subdomain(), <a href="subdomain_registration.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_subdomain_registration_ENotSubdomain">ENotSubdomain</a>);
    // Can't wrap an expired NFT.
    <b>assert</b>!(!nft.has_expired(<a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>), <a href="subdomain_registration.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_subdomain_registration_EExpired">EExpired</a>);

    <a href="subdomain_registration.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_subdomain_registration_SubDomainRegistration">SubDomainRegistration</a> {
        id: <a href="dependencies/sui-framework/object.md#0x2_object_new">object::new</a>(ctx),
        nft: nft
    }
}
</code></pre>



</details>

<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_subdomain_registration_burn"></a>

## Function `burn`

Destroys the wrapper and returns the SuinsRegistration object.
Fails if the subname is not expired.


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="subdomain_registration.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_subdomain_registration_burn">burn</a>(name: <a href="subdomain_registration.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_subdomain_registration_SubDomainRegistration">subdomain_registration::SubDomainRegistration</a>, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &<a href="dependencies/sui-framework/clock.md#0x2_clock_Clock">clock::Clock</a>): <a href="suins_registration.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_registration_SuinsRegistration">suins_registration::SuinsRegistration</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<a href="dependencies/sui-framework/package.md#0x2_package">package</a>) <b>fun</b> <a href="subdomain_registration.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_subdomain_registration_burn">burn</a>(name: <a href="subdomain_registration.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_subdomain_registration_SubDomainRegistration">SubDomainRegistration</a>, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &Clock): SuinsRegistration {
    // tries <b>to</b> unwrap a non-expired subname.
    <b>assert</b>!(name.nft.has_expired(<a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>), <a href="subdomain_registration.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_subdomain_registration_ENameNotExpired">ENameNotExpired</a>);

    <b>let</b> <a href="subdomain_registration.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_subdomain_registration_SubDomainRegistration">SubDomainRegistration</a> {
        id, nft
    } = name;

    id.delete();
    nft
}
</code></pre>



</details>

<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_subdomain_registration_nft"></a>

## Function `nft`



<pre><code><b>public</b> <b>fun</b> <a href="subdomain_registration.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_subdomain_registration_nft">nft</a>(name: &<a href="subdomain_registration.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_subdomain_registration_SubDomainRegistration">subdomain_registration::SubDomainRegistration</a>): &<a href="suins_registration.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_registration_SuinsRegistration">suins_registration::SuinsRegistration</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="subdomain_registration.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_subdomain_registration_nft">nft</a>(name: &<a href="subdomain_registration.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_subdomain_registration_SubDomainRegistration">SubDomainRegistration</a>): &SuinsRegistration {
    &name.nft
}
</code></pre>



</details>

<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_subdomain_registration_nft_mut"></a>

## Function `nft_mut`



<pre><code><b>public</b> <b>fun</b> <a href="subdomain_registration.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_subdomain_registration_nft_mut">nft_mut</a>(name: &<b>mut</b> <a href="subdomain_registration.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_subdomain_registration_SubDomainRegistration">subdomain_registration::SubDomainRegistration</a>): &<b>mut</b> <a href="suins_registration.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_registration_SuinsRegistration">suins_registration::SuinsRegistration</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="subdomain_registration.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_subdomain_registration_nft_mut">nft_mut</a>(name: &<b>mut</b> <a href="subdomain_registration.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_subdomain_registration_SubDomainRegistration">SubDomainRegistration</a>): &<b>mut</b> SuinsRegistration {
    &<b>mut</b> name.nft
}
</code></pre>



</details>
