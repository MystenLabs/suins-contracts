
<a name="0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_day_one"></a>

# Module `0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d::day_one`

This module defines the <code><a href="day_one.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_day_one_DayOne">DayOne</a></code> Object airdropped to early supporters of the SuiNS project.


-  [Resource `DropList`](#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_day_one_DropList)
-  [Resource `SetupCap`](#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_day_one_SetupCap)
-  [Struct `DAY_ONE`](#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_day_one_DAY_ONE)
-  [Resource `DayOne`](#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_day_one_DayOne)
-  [Constants](#@Constants_0)
-  [Function `init`](#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_day_one_init)
-  [Function `mint`](#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_day_one_mint)
-  [Function `setup`](#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_day_one_setup)
-  [Function `activate`](#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_day_one_activate)
-  [Function `uid`](#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_day_one_uid)
-  [Function `uid_mut`](#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_day_one_uid_mut)
-  [Function `is_active`](#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_day_one_is_active)


<pre><code><b>use</b> <a href="dependencies/move-stdlib/option.md#0x1_option">0x1::option</a>;
<b>use</b> <a href="dependencies/sui-framework/address.md#0x2_address">0x2::address</a>;
<b>use</b> <a href="dependencies/sui-framework/bcs.md#0x2_bcs">0x2::bcs</a>;
<b>use</b> <a href="dependencies/sui-framework/dynamic_field.md#0x2_dynamic_field">0x2::dynamic_field</a>;
<b>use</b> <a href="dependencies/sui-framework/hash.md#0x2_hash">0x2::hash</a>;
<b>use</b> <a href="dependencies/sui-framework/object.md#0x2_object">0x2::object</a>;
<b>use</b> <a href="dependencies/sui-framework/package.md#0x2_package">0x2::package</a>;
<b>use</b> <a href="dependencies/sui-framework/transfer.md#0x2_transfer">0x2::transfer</a>;
<b>use</b> <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context">0x2::tx_context</a>;
</code></pre>



<a name="0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_day_one_DropList"></a>

## Resource `DropList`

We mark as friend just the BOGO module.
This is the only one that can activate a DayOne object.
This is a one-time operation that won't happen from any other modules.
The shared object that stores the receivers destination.


<pre><code><b>struct</b> <a href="day_one.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_day_one_DropList">DropList</a> <b>has</b> key
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
<code>total_minted: u32</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_day_one_SetupCap"></a>

## Resource `SetupCap`

The Setup Capability for the airdrop module. Sent to the publisher on
publish. Consumed in the setup call.


<pre><code><b>struct</b> <a href="day_one.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_day_one_SetupCap">SetupCap</a> <b>has</b> key
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>id: <a href="dependencies/sui-framework/object.md#0x2_object_UID">object::UID</a></code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_day_one_DAY_ONE"></a>

## Struct `DAY_ONE`

OTW for the Publisher object


<pre><code><b>struct</b> <a href="day_one.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_day_one_DAY_ONE">DAY_ONE</a> <b>has</b> drop
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

<a name="0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_day_one_DayOne"></a>

## Resource `DayOne`

The DayOne object, granting participants special offers in
different future promotions.


<pre><code><b>struct</b> <a href="day_one.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_day_one_DayOne">DayOne</a> <b>has</b> store, key
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
<code>active: bool</code>
</dt>
<dd>

</dd>
<dt>
<code>serial: u32</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="@Constants_0"></a>

## Constants


<a name="0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_day_one_ENotFound"></a>

== ERRORS ==


<pre><code><b>const</b> <a href="day_one.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_day_one_ENotFound">ENotFound</a>: u64 = 0;
</code></pre>



<a name="0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_day_one_ETooManyHashes"></a>



<pre><code><b>const</b> <a href="day_one.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_day_one_ETooManyHashes">ETooManyHashes</a>: u64 = 1;
</code></pre>



<a name="0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_day_one_init"></a>

## Function `init`

Share the <code><a href="day_one.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_day_one_DropList">DropList</a></code> object, send the <code><a href="day_one.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_day_one_SetupCap">SetupCap</a></code> to the publisher.


<pre><code><b>fun</b> <a href="day_one.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_day_one_init">init</a>(otw: <a href="day_one.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_day_one_DAY_ONE">day_one::DAY_ONE</a>, ctx: &<b>mut</b> <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="day_one.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_day_one_init">init</a>(otw: <a href="day_one.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_day_one_DAY_ONE">DAY_ONE</a>, ctx: &<b>mut</b> TxContext) {
    // Claim the `Publisher` for the <a href="dependencies/sui-framework/package.md#0x2_package">package</a>!
    <a href="dependencies/sui-framework/package.md#0x2_package_claim_and_keep">package::claim_and_keep</a>(otw, ctx);

    <a href="dependencies/sui-framework/transfer.md#0x2_transfer_share_object">transfer::share_object</a>(<a href="day_one.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_day_one_DropList">DropList</a> { id: <a href="dependencies/sui-framework/object.md#0x2_object_new">object::new</a>(ctx), total_minted: 0 });
    // For SuiNS, we need 1 <a href="day_one.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_day_one_SetupCap">SetupCap</a> <b>to</b> manage all the required addresses. We'll be setting up around 75K addresses.
    // We can mint 2K objects per run!
    <a href="dependencies/sui-framework/transfer.md#0x2_transfer_transfer">transfer::transfer</a>(<a href="day_one.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_day_one_SetupCap">SetupCap</a> { id: <a href="dependencies/sui-framework/object.md#0x2_object_new">object::new</a>(ctx) }, ctx.sender());
}
</code></pre>



</details>

<a name="0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_day_one_mint"></a>

## Function `mint`

Mint the DayOne objects for the recipients. Can be triggered by anyone.
The only functionality it has is mint the DayOne & send it to the an address
that is part of the list.


<pre><code><b>public</b> <b>fun</b> <a href="day_one.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_day_one_mint">mint</a>(self: &<b>mut</b> <a href="day_one.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_day_one_DropList">day_one::DropList</a>, recipients: <a href="dependencies/move-stdlib/vector.md#0x1_vector">vector</a>&lt;<b>address</b>&gt;, ctx: &<b>mut</b> <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="day_one.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_day_one_mint">mint</a>(
    self: &<b>mut</b> <a href="day_one.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_day_one_DropList">DropList</a>,
    <b>mut</b> recipients: <a href="dependencies/move-stdlib/vector.md#0x1_vector">vector</a>&lt;<b>address</b>&gt;,
    ctx: &<b>mut</b> TxContext
) {

    <b>let</b> bytes = <a href="dependencies/move-stdlib/bcs.md#0x1_bcs_to_bytes">bcs::to_bytes</a>(&recipients);
    <b>let</b> <a href="dependencies/sui-framework/hash.md#0x2_hash">hash</a> = <a href="dependencies/sui-framework/hash.md#0x2_hash_blake2b256">hash::blake2b256</a>(&bytes);

    // fails <b>if</b> not found.
    <b>let</b> lookup = df::remove_if_exists(&<b>mut</b> self.id, sui::address::from_bytes(<a href="dependencies/sui-framework/hash.md#0x2_hash">hash</a>));
    <b>assert</b>!(lookup.is_some&lt;bool&gt;(), <a href="day_one.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_day_one_ENotFound">ENotFound</a>);

    <b>let</b> <b>mut</b> i: u32 = self.total_minted;

    <b>while</b> (<a href="dependencies/move-stdlib/vector.md#0x1_vector_length">vector::length</a>(&recipients) &gt; 0) {
        <b>let</b> recipient = recipients.pop_back();
        <a href="dependencies/sui-framework/transfer.md#0x2_transfer_public_transfer">transfer::public_transfer</a>(<a href="day_one.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_day_one_DayOne">DayOne</a> {
            id: <a href="dependencies/sui-framework/object.md#0x2_object_new">object::new</a>(ctx),
            active: <b>false</b>,
            serial: i + 1
        }, recipient);
        i = i + 1;
    };

    // assign i <b>to</b> total_minted.
    self.total_minted = i
}
</code></pre>



</details>

<a name="0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_day_one_setup"></a>

## Function `setup`

Setup the airdrop module. This is called by the publisher.
Hashes can be a vector of up to 1000 elements.
Hashes needs to be generated by the <code>buffer</code> module.


<pre><code><b>public</b> <b>fun</b> <a href="day_one.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_day_one_setup">setup</a>(self: &<b>mut</b> <a href="day_one.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_day_one_DropList">day_one::DropList</a>, cap: <a href="day_one.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_day_one_SetupCap">day_one::SetupCap</a>, hashes: <a href="dependencies/move-stdlib/vector.md#0x1_vector">vector</a>&lt;<b>address</b>&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="day_one.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_day_one_setup">setup</a>(
    self: &<b>mut</b> <a href="day_one.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_day_one_DropList">DropList</a>,
    cap: <a href="day_one.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_day_one_SetupCap">SetupCap</a>,
    <b>mut</b> hashes: <a href="dependencies/move-stdlib/vector.md#0x1_vector">vector</a>&lt;<b>address</b>&gt;,
) {
    // verify we only pass less than 1000 hashes at the setup.
    // That's the max amount of DFs we can create in a single run.
    <b>assert</b>!(hashes.length() &lt;= 1000, <a href="day_one.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_day_one_ETooManyHashes">ETooManyHashes</a>);

    <b>let</b> <a href="day_one.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_day_one_SetupCap">SetupCap</a> { id } = cap;
    id.delete();

    // attach every <a href="dependencies/sui-framework/hash.md#0x2_hash">hash</a> <b>as</b> a dynamic field <b>to</b> the `<a href="day_one.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_day_one_DropList">DropList</a>` <a href="dependencies/sui-framework/object.md#0x2_object">object</a>;
    <b>while</b> (hashes.length() &gt; 0) {
        df::add(&<b>mut</b> self.id, hashes.pop_back(), <b>true</b>);
    };
}
</code></pre>



</details>

<a name="0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_day_one_activate"></a>

## Function `activate`

Private helper to activate the DayOne object
Will only be called by the <code><a href="bogo.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_bogo">bogo</a></code> module (friend), which marks the
beggining of the DayOne promotions.


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="day_one.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_day_one_activate">activate</a>(self: &<b>mut</b> <a href="day_one.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_day_one_DayOne">day_one::DayOne</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<a href="dependencies/sui-framework/package.md#0x2_package">package</a>) <b>fun</b> <a href="day_one.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_day_one_activate">activate</a>(self: &<b>mut</b> <a href="day_one.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_day_one_DayOne">DayOne</a>) {
    self.active = <b>true</b>
}
</code></pre>



</details>

<a name="0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_day_one_uid"></a>

## Function `uid`

Get the immutable reference to the UID of the DayOne object.


<pre><code><b>public</b> <b>fun</b> <a href="day_one.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_day_one_uid">uid</a>(self: &<a href="day_one.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_day_one_DayOne">day_one::DayOne</a>): &<a href="dependencies/sui-framework/object.md#0x2_object_UID">object::UID</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="day_one.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_day_one_uid">uid</a>(self: &<a href="day_one.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_day_one_DayOne">DayOne</a>): &UID { &self.id }
</code></pre>



</details>

<a name="0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_day_one_uid_mut"></a>

## Function `uid_mut`

Get the mutable reference to the UID of the DayOne object.


<pre><code><b>public</b> <b>fun</b> <a href="day_one.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_day_one_uid_mut">uid_mut</a>(self: &<b>mut</b> <a href="day_one.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_day_one_DayOne">day_one::DayOne</a>): &<b>mut</b> <a href="dependencies/sui-framework/object.md#0x2_object_UID">object::UID</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="day_one.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_day_one_uid_mut">uid_mut</a>(self: &<b>mut</b> <a href="day_one.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_day_one_DayOne">DayOne</a>): &<b>mut</b> UID { &<b>mut</b> self.id }
</code></pre>



</details>

<a name="0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_day_one_is_active"></a>

## Function `is_active`

Get if a day_one object is active. Used for future promotions
of the DayOne Object


<pre><code><b>public</b> <b>fun</b> <a href="day_one.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_day_one_is_active">is_active</a>(self: &<a href="day_one.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_day_one_DayOne">day_one::DayOne</a>): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="day_one.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_day_one_is_active">is_active</a>(self: &<a href="day_one.md#0xbf417a054f5a4cf90a3fb12b71fcfe44d3d0892ac97a86725c0e91b4e05f655d_day_one_DayOne">DayOne</a>): bool {
    self.active
}
</code></pre>



</details>
