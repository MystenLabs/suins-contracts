
<a name="0x0_managed"></a>

# Module `0x0::managed`

A simple wrapper to allow having a <code>third-party</code> managed <code>SuinsRegistration</code> object
without the danger of losing it.

It's particularly useful for <code>Enoki&lt;-&gt;SuiNS</code>, where the <code>SuinsRegistration</code> object
will be owned by a multi-sig address (for any company), and Enoki addresses will be able to
borrow it for creating subdomains.

Also, instead of going the <code>cap</code> way, we go with the <code><b>address</b></code> way to remove any chance of
equivocation, both for Enoki Backends + owner actions on the domain.

Since <code>SuiNS</code> is required as a parameter to create subdomains anyways,
we're also using it to store the managed names (to avoid using separate shared objects).



-  [Struct `ManagedNamesApp`](#0x0_managed_ManagedNamesApp)
-  [Struct `ManagedNames`](#0x0_managed_ManagedNames)
-  [Struct `ManagedName`](#0x0_managed_ManagedName)
-  [Struct `ReturnPromise`](#0x0_managed_ReturnPromise)
-  [Constants](#@Constants_0)
-  [Function `setup`](#0x0_managed_setup)
-  [Function `attach_managed_name`](#0x0_managed_attach_managed_name)
-  [Function `remove_attached_name`](#0x0_managed_remove_attached_name)
-  [Function `allow_addresses`](#0x0_managed_allow_addresses)
-  [Function `revoke_addresses`](#0x0_managed_revoke_addresses)
-  [Function `borrow_val`](#0x0_managed_borrow_val)
-  [Function `return_val`](#0x0_managed_return_val)
-  [Function `internal_get_managed_name`](#0x0_managed_internal_get_managed_name)
-  [Function `is_owner`](#0x0_managed_is_owner)
-  [Function `is_authorized_address`](#0x0_managed_is_authorized_address)
-  [Function `managed_names_mut`](#0x0_managed_managed_names_mut)


<pre><code><b>use</b> <a href="dependencies/move-stdlib/option.md#0x1_option">0x1::option</a>;
<b>use</b> <a href="dependencies/move-stdlib/string.md#0x1_string">0x1::string</a>;
<b>use</b> <a href="dependencies/move-stdlib/vector.md#0x1_vector">0x1::vector</a>;
<b>use</b> <a href="dependencies/sui-framework/clock.md#0x2_clock">0x2::clock</a>;
<b>use</b> <a href="dependencies/sui-framework/object.md#0x2_object">0x2::object</a>;
<b>use</b> <a href="dependencies/sui-framework/table.md#0x2_table">0x2::table</a>;
<b>use</b> <a href="dependencies/sui-framework/transfer.md#0x2_transfer">0x2::transfer</a>;
<b>use</b> <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context">0x2::tx_context</a>;
<b>use</b> <a href="dependencies/suins/domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94::domain</a>;
<b>use</b> <a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94::suins</a>;
<b>use</b> <a href="dependencies/suins/suins_registration.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_registration">0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94::suins_registration</a>;
</code></pre>



<a name="0x0_managed_ManagedNamesApp"></a>

## Struct `ManagedNamesApp`

Authorizes the <code><a href="managed.md#0x0_managed_ManagedNames">ManagedNames</a></code> to add a <code><a href="dependencies/suins/registry.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_registry">registry</a></code> under the main SuiNS object.


<pre><code><b>struct</b> <a href="managed.md#0x0_managed_ManagedNamesApp">ManagedNamesApp</a> <b>has</b> drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>dummy_field: bool</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0x0_managed_ManagedNames"></a>

## Struct `ManagedNames`

The <code><a href="dependencies/suins/registry.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_registry">registry</a></code> that holds the managed names per domain.
To simplify, we can only hold a single managed name per domain.
If a valid NFT is passed, the previous name is returned to the owner (who can burn it, as it's an expired one).


<pre><code><b>struct</b> <a href="managed.md#0x0_managed_ManagedNames">ManagedNames</a> <b>has</b> store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>names: <a href="dependencies/sui-framework/table.md#0x2_table_Table">table::Table</a>&lt;<a href="dependencies/suins/domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_Domain">domain::Domain</a>, <a href="managed.md#0x0_managed_ManagedName">managed::ManagedName</a>&gt;</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0x0_managed_ManagedName"></a>

## Struct `ManagedName`

A managed name.
<code>owner</code>: the only address that can get the <code>NFT</code> back
<code>allowlist</code>: A list of allowed addresses (that can borrow + return the <code>NFT</code>)
<code>nft</code>: The <code>SuinsRegistration</code> object that can be borrowed.


<pre><code><b>struct</b> <a href="managed.md#0x0_managed_ManagedName">ManagedName</a> <b>has</b> store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>owner: <b>address</b></code>
</dt>
<dd>

</dd>
<dt>
<code>allowed_addresses: <a href="dependencies/move-stdlib/vector.md#0x1_vector">vector</a>&lt;<b>address</b>&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>nft: <a href="dependencies/move-stdlib/option.md#0x1_option_Option">option::Option</a>&lt;<a href="dependencies/suins/suins_registration.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_registration_SuinsRegistration">suins_registration::SuinsRegistration</a>&gt;</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0x0_managed_ReturnPromise"></a>

## Struct `ReturnPromise`

A hot-potato promise that the NFT will be returned upon borrowing.


<pre><code><b>struct</b> <a href="managed.md#0x0_managed_ReturnPromise">ReturnPromise</a>
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>id: <a href="dependencies/sui-framework/object.md#0x2_object_ID">object::ID</a></code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="@Constants_0"></a>

## Constants


<a name="0x0_managed_ENotAuthorized"></a>

Tries to do an unauthorized action on a name.


<pre><code><b>const</b> <a href="managed.md#0x0_managed_ENotAuthorized">ENotAuthorized</a>: u64 = 4;
</code></pre>



<a name="0x0_managed_EAlreadyExists"></a>

Tries to add a name that already exists (that's impossible but protecting anyways).


<pre><code><b>const</b> <a href="managed.md#0x0_managed_EAlreadyExists">EAlreadyExists</a>: u64 = 2;
</code></pre>



<a name="0x0_managed_EExpiredNFT"></a>

Tries to add an NFT that has expired.


<pre><code><b>const</b> <a href="managed.md#0x0_managed_EExpiredNFT">EExpiredNFT</a>: u64 = 1;
</code></pre>



<a name="0x0_managed_EInvalidReturnedNFT"></a>

Tries to return an NFT that doesn't match the promise.


<pre><code><b>const</b> <a href="managed.md#0x0_managed_EInvalidReturnedNFT">EInvalidReturnedNFT</a>: u64 = 5;
</code></pre>



<a name="0x0_managed_ENameNotExists"></a>

Tries to borrow a name that doesn't exist in the managed registry


<pre><code><b>const</b> <a href="managed.md#0x0_managed_ENameNotExists">ENameNotExists</a>: u64 = 3;
</code></pre>



<a name="0x0_managed_setup"></a>

## Function `setup`



<pre><code><b>public</b> <b>fun</b> <a href="managed.md#0x0_managed_setup">setup</a>(self: &<b>mut</b> <a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_SuiNS">suins::SuiNS</a>, cap: &<a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_AdminCap">suins::AdminCap</a>, ctx: &<b>mut</b> <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="managed.md#0x0_managed_setup">setup</a>(self: &<b>mut</b> SuiNS, cap: &AdminCap, ctx: &<b>mut</b> TxContext) {
    <a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_add_registry">suins::add_registry</a>(cap, self, <a href="managed.md#0x0_managed_ManagedNames">ManagedNames</a> {
        names: <a href="dependencies/sui-framework/table.md#0x2_table_new">table::new</a>(ctx)
    });
}
</code></pre>



</details>

<a name="0x0_managed_attach_managed_name"></a>

## Function `attach_managed_name`

Attaches a <code>SuinsRegistration</code> object for usability from third-party addresses.


<pre><code><b>public</b> <b>fun</b> <a href="managed.md#0x0_managed_attach_managed_name">attach_managed_name</a>(<a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>: &<b>mut</b> <a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_SuiNS">suins::SuiNS</a>, nft: <a href="dependencies/suins/suins_registration.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_registration_SuinsRegistration">suins_registration::SuinsRegistration</a>, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &<a href="dependencies/sui-framework/clock.md#0x2_clock_Clock">clock::Clock</a>, allowed_addresses: <a href="dependencies/move-stdlib/vector.md#0x1_vector">vector</a>&lt;<b>address</b>&gt;, ctx: &<b>mut</b> <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="managed.md#0x0_managed_attach_managed_name">attach_managed_name</a>(
    <a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>: &<b>mut</b> SuiNS,
    nft: SuinsRegistration,
    <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &Clock,
    allowed_addresses: <a href="dependencies/move-stdlib/vector.md#0x1_vector">vector</a>&lt;<b>address</b>&gt;,
    ctx: &<b>mut</b> TxContext
) {
    <b>assert</b>!(!nft.has_expired(<a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>), <a href="managed.md#0x0_managed_EExpiredNFT">EExpiredNFT</a>);

    <b>let</b> managed_names = <a href="managed.md#0x0_managed_managed_names_mut">managed_names_mut</a>(<a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>);

    <b>let</b> <a href="dependencies/suins/domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a> = nft.<a href="dependencies/suins/domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a>();

    // <b>if</b> the name exists. We check <b>if</b> it's expired, and <b>return</b> it <b>to</b> the owner.
    <b>if</b>(<a href="dependencies/sui-framework/table.md#0x2_table_contains">table::contains</a>(&managed_names.names, <a href="dependencies/suins/domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a>)) {
        <b>let</b> existing = <a href="dependencies/sui-framework/table.md#0x2_table_remove">table::remove</a>(&<b>mut</b> managed_names.names, <a href="dependencies/suins/domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a>);

        <b>let</b> <a href="managed.md#0x0_managed_ManagedName">ManagedName</a> { nft, allowed_addresses: _, owner } = existing;

        <b>let</b> existing_nft = <a href="dependencies/move-stdlib/option.md#0x1_option_destroy_some">option::destroy_some</a>(nft);

        <b>assert</b>!(existing_nft.has_expired(<a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>), <a href="managed.md#0x0_managed_EAlreadyExists">EAlreadyExists</a>);
        // <a href="dependencies/sui-framework/transfer.md#0x2_transfer">transfer</a> it back <b>to</b> the owner.
        <a href="dependencies/sui-framework/transfer.md#0x2_transfer_public_transfer">transfer::public_transfer</a>(existing_nft, owner);
    };

    // add the name <b>to</b> the <a href="managed.md#0x0_managed">managed</a> names list.
    managed_names.names.add(<a href="dependencies/suins/domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a>, <a href="managed.md#0x0_managed_ManagedName">ManagedName</a> {
        owner: sender(ctx),
        allowed_addresses,
        nft: <a href="dependencies/move-stdlib/option.md#0x1_option_some">option::some</a>(nft)
    });
}
</code></pre>



</details>

<a name="0x0_managed_remove_attached_name"></a>

## Function `remove_attached_name`

Allows the <code>owner</code> to remove a name from the managed system.


<pre><code><b>public</b> <b>fun</b> <a href="managed.md#0x0_managed_remove_attached_name">remove_attached_name</a>(<a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>: &<b>mut</b> <a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_SuiNS">suins::SuiNS</a>, name: <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>, ctx: &<b>mut</b> <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context_TxContext">tx_context::TxContext</a>): <a href="dependencies/suins/suins_registration.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_registration_SuinsRegistration">suins_registration::SuinsRegistration</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="managed.md#0x0_managed_remove_attached_name">remove_attached_name</a>(
    <a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>: &<b>mut</b> SuiNS,
    name: String,
    ctx: &<b>mut</b> TxContext
): SuinsRegistration {
    <b>let</b> managed_names = <a href="managed.md#0x0_managed_managed_names_mut">managed_names_mut</a>(<a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>);
    <b>let</b> <a href="dependencies/suins/domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a> = <a href="dependencies/suins/domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_new">domain::new</a>(name);

    <b>assert</b>!(<a href="dependencies/sui-framework/table.md#0x2_table_contains">table::contains</a>(&managed_names.names, <a href="dependencies/suins/domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a>), <a href="managed.md#0x0_managed_ENameNotExists">ENameNotExists</a>);
    <b>let</b> existing = managed_names.names.remove(<a href="dependencies/suins/domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a>);

    <b>assert</b>!(<a href="managed.md#0x0_managed_is_owner">is_owner</a>(&existing, sender(ctx)), <a href="managed.md#0x0_managed_ENotAuthorized">ENotAuthorized</a>);

    <b>let</b> <a href="managed.md#0x0_managed_ManagedName">ManagedName</a> { nft, allowed_addresses: _, owner: _ } = existing;

    <a href="dependencies/move-stdlib/option.md#0x1_option_destroy_some">option::destroy_some</a>(nft)
}
</code></pre>



</details>

<a name="0x0_managed_allow_addresses"></a>

## Function `allow_addresses`

Allow a list of addresses to borrow the <code>SuinsRegistration</code> object.


<pre><code><b>public</b> <b>fun</b> <a href="managed.md#0x0_managed_allow_addresses">allow_addresses</a>(<a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>: &<b>mut</b> <a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_SuiNS">suins::SuiNS</a>, name: <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>, addresses: <a href="dependencies/move-stdlib/vector.md#0x1_vector">vector</a>&lt;<b>address</b>&gt;, ctx: &<b>mut</b> <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="managed.md#0x0_managed_allow_addresses">allow_addresses</a>(
    <a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>: &<b>mut</b> SuiNS,
    name: String,
    <b>mut</b> addresses: <a href="dependencies/move-stdlib/vector.md#0x1_vector">vector</a>&lt;<b>address</b>&gt;,
    ctx: &<b>mut</b> TxContext
) {
    <b>let</b> existing = <a href="managed.md#0x0_managed_internal_get_managed_name">internal_get_managed_name</a>(<a href="managed.md#0x0_managed_managed_names_mut">managed_names_mut</a>(<a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>), <a href="dependencies/suins/domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_new">domain::new</a>(name));
    <b>assert</b>!(<a href="managed.md#0x0_managed_is_owner">is_owner</a>(existing, sender(ctx)), <a href="managed.md#0x0_managed_ENotAuthorized">ENotAuthorized</a>);

    <b>while</b>(addresses.length() &gt; 0) {
        <b>let</b> addr = addresses.pop_back();

        <b>if</b>(!existing.allowed_addresses.contains(&addr)) {
            existing.allowed_addresses.push_back(addr);
        }
    }
}
</code></pre>



</details>

<a name="0x0_managed_revoke_addresses"></a>

## Function `revoke_addresses`



<pre><code><b>public</b> <b>fun</b> <a href="managed.md#0x0_managed_revoke_addresses">revoke_addresses</a>(<a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>: &<b>mut</b> <a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_SuiNS">suins::SuiNS</a>, name: <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>, addresses: <a href="dependencies/move-stdlib/vector.md#0x1_vector">vector</a>&lt;<b>address</b>&gt;, ctx: &<b>mut</b> <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="managed.md#0x0_managed_revoke_addresses">revoke_addresses</a>(
    <a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>: &<b>mut</b> SuiNS,
    name: String,
    <b>mut</b> addresses: <a href="dependencies/move-stdlib/vector.md#0x1_vector">vector</a>&lt;<b>address</b>&gt;,
    ctx: &<b>mut</b> TxContext
) {
    <b>let</b> existing = <a href="managed.md#0x0_managed_internal_get_managed_name">internal_get_managed_name</a>(<a href="managed.md#0x0_managed_managed_names_mut">managed_names_mut</a>(<a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>), <a href="dependencies/suins/domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_new">domain::new</a>(name));
    <b>assert</b>!(<a href="managed.md#0x0_managed_is_owner">is_owner</a>(existing, sender(ctx)), <a href="managed.md#0x0_managed_ENotAuthorized">ENotAuthorized</a>);

    <b>while</b>(addresses.length() &gt; 0) {
        <b>let</b> addr = addresses.pop_back();

        <b>let</b> (has_address, index) = existing.allowed_addresses.index_of(&addr);

        <b>if</b> (has_address) {
            existing.allowed_addresses.remove(index);
        }
    }
}
</code></pre>



</details>

<a name="0x0_managed_borrow_val"></a>

## Function `borrow_val`

Borrows the <code>SuinsRegistration</code> object.


<pre><code><b>public</b> <b>fun</b> <a href="managed.md#0x0_managed_borrow_val">borrow_val</a>(<a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>: &<b>mut</b> <a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_SuiNS">suins::SuiNS</a>, name: <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>, ctx: &<b>mut</b> <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context_TxContext">tx_context::TxContext</a>): (<a href="dependencies/suins/suins_registration.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_registration_SuinsRegistration">suins_registration::SuinsRegistration</a>, <a href="managed.md#0x0_managed_ReturnPromise">managed::ReturnPromise</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="managed.md#0x0_managed_borrow_val">borrow_val</a>(
    <a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>: &<b>mut</b> SuiNS,
    name: String,
    ctx: &<b>mut</b> TxContext
): (SuinsRegistration, <a href="managed.md#0x0_managed_ReturnPromise">ReturnPromise</a>) {
    <b>let</b> existing = <a href="managed.md#0x0_managed_internal_get_managed_name">internal_get_managed_name</a>(<a href="managed.md#0x0_managed_managed_names_mut">managed_names_mut</a>(<a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>), <a href="dependencies/suins/domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_new">domain::new</a>(name));

    <b>assert</b>!(<a href="managed.md#0x0_managed_is_authorized_address">is_authorized_address</a>(existing, sender(ctx)), <a href="managed.md#0x0_managed_ENotAuthorized">ENotAuthorized</a>);

    <b>let</b> nft = <a href="dependencies/move-stdlib/option.md#0x1_option_extract">option::extract</a>(&<b>mut</b> existing.nft);
    <b>let</b> id = <a href="dependencies/sui-framework/object.md#0x2_object_id">object::id</a>(&nft);

    (nft, <a href="managed.md#0x0_managed_ReturnPromise">ReturnPromise</a> {
        id
    })
}
</code></pre>



</details>

<a name="0x0_managed_return_val"></a>

## Function `return_val`

Returns the <code>SuinsRegistration</code> object back with the promise.


<pre><code><b>public</b> <b>fun</b> <a href="managed.md#0x0_managed_return_val">return_val</a>(<a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>: &<b>mut</b> <a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_SuiNS">suins::SuiNS</a>, nft: <a href="dependencies/suins/suins_registration.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_registration_SuinsRegistration">suins_registration::SuinsRegistration</a>, promise: <a href="managed.md#0x0_managed_ReturnPromise">managed::ReturnPromise</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="managed.md#0x0_managed_return_val">return_val</a>(
    <a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>: &<b>mut</b> SuiNS,
    nft: SuinsRegistration,
    promise: <a href="managed.md#0x0_managed_ReturnPromise">ReturnPromise</a>
) {
    <b>let</b> <a href="managed.md#0x0_managed_ReturnPromise">ReturnPromise</a> { id } = promise;
    <b>assert</b>!(<a href="dependencies/sui-framework/object.md#0x2_object_id">object::id</a>(&nft) == id, <a href="managed.md#0x0_managed_EInvalidReturnedNFT">EInvalidReturnedNFT</a>);

    <b>let</b> existing = <a href="managed.md#0x0_managed_internal_get_managed_name">internal_get_managed_name</a>(<a href="managed.md#0x0_managed_managed_names_mut">managed_names_mut</a>(<a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>), nft.<a href="dependencies/suins/domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a>());

    // <b>return</b> the NFT back.
    <a href="dependencies/move-stdlib/option.md#0x1_option_fill">option::fill</a>(&<b>mut</b> existing.nft, nft)
}
</code></pre>



</details>

<a name="0x0_managed_internal_get_managed_name"></a>

## Function `internal_get_managed_name`



<pre><code><b>fun</b> <a href="managed.md#0x0_managed_internal_get_managed_name">internal_get_managed_name</a>(managed_names: &<b>mut</b> <a href="managed.md#0x0_managed_ManagedNames">managed::ManagedNames</a>, <a href="dependencies/suins/domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a>: <a href="dependencies/suins/domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_Domain">domain::Domain</a>): &<b>mut</b> <a href="managed.md#0x0_managed_ManagedName">managed::ManagedName</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="managed.md#0x0_managed_internal_get_managed_name">internal_get_managed_name</a>(managed_names: &<b>mut</b> <a href="managed.md#0x0_managed_ManagedNames">ManagedNames</a>, <a href="dependencies/suins/domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a>: Domain): &<b>mut</b> <a href="managed.md#0x0_managed_ManagedName">ManagedName</a> {
    <b>assert</b>!(managed_names.names.contains(<a href="dependencies/suins/domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a>), <a href="managed.md#0x0_managed_ENameNotExists">ENameNotExists</a>);

    &<b>mut</b> managed_names.names[<a href="dependencies/suins/domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a>]
}
</code></pre>



</details>

<a name="0x0_managed_is_owner"></a>

## Function `is_owner`



<pre><code><b>fun</b> <a href="managed.md#0x0_managed_is_owner">is_owner</a>(self: &<a href="managed.md#0x0_managed_ManagedName">managed::ManagedName</a>, addr: <b>address</b>): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="managed.md#0x0_managed_is_owner">is_owner</a>(self: &<a href="managed.md#0x0_managed_ManagedName">ManagedName</a>, addr: <b>address</b>): bool {
    self.owner == addr
}
</code></pre>



</details>

<a name="0x0_managed_is_authorized_address"></a>

## Function `is_authorized_address`

Check if an address is authorized for borrowing.


<pre><code><b>fun</b> <a href="managed.md#0x0_managed_is_authorized_address">is_authorized_address</a>(self: &<a href="managed.md#0x0_managed_ManagedName">managed::ManagedName</a>, addr: <b>address</b>): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="managed.md#0x0_managed_is_authorized_address">is_authorized_address</a>(self: &<a href="managed.md#0x0_managed_ManagedName">ManagedName</a>, addr: <b>address</b>): bool {
    self.owner == addr || self.allowed_addresses.contains(&addr)
}
</code></pre>



</details>

<a name="0x0_managed_managed_names_mut"></a>

## Function `managed_names_mut`

a mutable reference to the registry


<pre><code><b>fun</b> <a href="managed.md#0x0_managed_managed_names_mut">managed_names_mut</a>(self: &<b>mut</b> <a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_SuiNS">suins::SuiNS</a>): &<b>mut</b> <a href="managed.md#0x0_managed_ManagedNames">managed::ManagedNames</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="managed.md#0x0_managed_managed_names_mut">managed_names_mut</a>(self: &<b>mut</b> SuiNS): &<b>mut</b> <a href="managed.md#0x0_managed_ManagedNames">ManagedNames</a> {
    <a href="dependencies/suins/suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_app_registry_mut">suins::app_registry_mut</a>&lt;<a href="managed.md#0x0_managed_ManagedNamesApp">ManagedNamesApp</a>, <a href="managed.md#0x0_managed_ManagedNames">ManagedNames</a>&gt;(<a href="managed.md#0x0_managed_ManagedNamesApp">ManagedNamesApp</a> {}, self)
}
</code></pre>



</details>
