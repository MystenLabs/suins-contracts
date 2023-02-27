
<a name="0x0_controller"></a>

# Module `0x0::controller`

Its job is to charge payment, add validation and apply referral and discount code
when registering and extend experation of domanin names.
The real logic of mint a NFT and store the record in blockchain is done in Registrar and Registry contract.
Domain name registration can only occur using the Controller and Auction contracts.
During auction period, only domains with 7 to 63 characters can be registered via the Controller,
but after the auction has ended, all domains can be registered.


-  [Resource `BaseController`](#0x0_controller_BaseController)
-  [Struct `NameRegisteredEvent`](#0x0_controller_NameRegisteredEvent)
-  [Struct `DefaultResolverChangedEvent`](#0x0_controller_DefaultResolverChangedEvent)
-  [Struct `NameRenewedEvent`](#0x0_controller_NameRenewedEvent)
-  [Constants](#@Constants_0)
-  [Function `set_default_resolver`](#0x0_controller_set_default_resolver)
-  [Function `commit`](#0x0_controller_commit)
-  [Function `register`](#0x0_controller_register)
-  [Function `register_with_image`](#0x0_controller_register_with_image)
-  [Function `register_with_config`](#0x0_controller_register_with_config)
-  [Function `register_with_config_and_image`](#0x0_controller_register_with_config_and_image)
-  [Function `register_with_code`](#0x0_controller_register_with_code)
-  [Function `register_with_code_and_image`](#0x0_controller_register_with_code_and_image)
-  [Function `register_with_config_and_code`](#0x0_controller_register_with_config_and_code)
-  [Function `register_with_config_and_code_and_image`](#0x0_controller_register_with_config_and_code_and_image)
-  [Function `renew`](#0x0_controller_renew)
-  [Function `renew_with_image`](#0x0_controller_renew_with_image)
-  [Function `withdraw`](#0x0_controller_withdraw)
-  [Function `renew_internal`](#0x0_controller_renew_internal)
-  [Function `register_internal`](#0x0_controller_register_internal)
-  [Function `apply_referral_code`](#0x0_controller_apply_referral_code)
-  [Function `apply_discount_code`](#0x0_controller_apply_discount_code)
-  [Function `remove_outdated_commitments`](#0x0_controller_remove_outdated_commitments)
-  [Function `consume_commitment`](#0x0_controller_consume_commitment)
-  [Function `make_commitment`](#0x0_controller_make_commitment)
-  [Function `validate_codes`](#0x0_controller_validate_codes)
-  [Function `init`](#0x0_controller_init)


<pre><code><b>use</b> <a href="auction.md#0x0_auction">0x0::auction</a>;
<b>use</b> <a href="base_registrar.md#0x0_base_registrar">0x0::base_registrar</a>;
<b>use</b> <a href="base_registry.md#0x0_base_registry">0x0::base_registry</a>;
<b>use</b> <a href="coin_util.md#0x0_coin_util">0x0::coin_util</a>;
<b>use</b> <a href="configuration.md#0x0_configuration">0x0::configuration</a>;
<b>use</b> <a href="emoji.md#0x0_emoji">0x0::emoji</a>;
<b>use</b> <a href="">0x1::ascii</a>;
<b>use</b> <a href="">0x1::bcs</a>;
<b>use</b> <a href="">0x1::option</a>;
<b>use</b> <a href="">0x1::string</a>;
<b>use</b> <a href="">0x1::vector</a>;
<b>use</b> <a href="">0x2::balance</a>;
<b>use</b> <a href="">0x2::coin</a>;
<b>use</b> <a href="">0x2::event</a>;
<b>use</b> <a href="">0x2::hash</a>;
<b>use</b> <a href="">0x2::linked_table</a>;
<b>use</b> <a href="">0x2::object</a>;
<b>use</b> <a href="">0x2::sui</a>;
<b>use</b> <a href="">0x2::transfer</a>;
<b>use</b> <a href="">0x2::tx_context</a>;
<b>use</b> <a href="">0x2::url</a>;
</code></pre>



<a name="0x0_controller_BaseController"></a>

## Resource `BaseController`



<pre><code><b>struct</b> <a href="controller.md#0x0_controller_BaseController">BaseController</a> <b>has</b> key
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>id: <a href="_UID">object::UID</a></code>
</dt>
<dd>

</dd>
<dt>
<code>commitments: <a href="_LinkedTable">linked_table::LinkedTable</a>&lt;<a href="">vector</a>&lt;u8&gt;, u64&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code><a href="">balance</a>: <a href="_Balance">balance::Balance</a>&lt;<a href="_SUI">sui::SUI</a>&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>default_addr_resolver: <b>address</b></code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0x0_controller_NameRegisteredEvent"></a>

## Struct `NameRegisteredEvent`



<pre><code><b>struct</b> <a href="controller.md#0x0_controller_NameRegisteredEvent">NameRegisteredEvent</a> <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>node: <a href="_String">string::String</a></code>
</dt>
<dd>

</dd>
<dt>
<code>label: <a href="_String">string::String</a></code>
</dt>
<dd>

</dd>
<dt>
<code>owner: <b>address</b></code>
</dt>
<dd>

</dd>
<dt>
<code>cost: u64</code>
</dt>
<dd>

</dd>
<dt>
<code>expiry: u64</code>
</dt>
<dd>

</dd>
<dt>
<code>nft_id: <a href="_ID">object::ID</a></code>
</dt>
<dd>

</dd>
<dt>
<code><a href="resolver.md#0x0_resolver">resolver</a>: <b>address</b></code>
</dt>
<dd>

</dd>
<dt>
<code>referral_code: <a href="_Option">option::Option</a>&lt;<a href="_String">ascii::String</a>&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>discount_code: <a href="_Option">option::Option</a>&lt;<a href="_String">ascii::String</a>&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code><a href="">url</a>: <a href="_Url">url::Url</a></code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0x0_controller_DefaultResolverChangedEvent"></a>

## Struct `DefaultResolverChangedEvent`



<pre><code><b>struct</b> <a href="controller.md#0x0_controller_DefaultResolverChangedEvent">DefaultResolverChangedEvent</a> <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code><a href="resolver.md#0x0_resolver">resolver</a>: <b>address</b></code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0x0_controller_NameRenewedEvent"></a>

## Struct `NameRenewedEvent`



<pre><code><b>struct</b> <a href="controller.md#0x0_controller_NameRenewedEvent">NameRenewedEvent</a> <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>node: <a href="_String">string::String</a></code>
</dt>
<dd>

</dd>
<dt>
<code>label: <a href="_String">string::String</a></code>
</dt>
<dd>

</dd>
<dt>
<code>cost: u64</code>
</dt>
<dd>

</dd>
<dt>
<code>duration: u64</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="@Constants_0"></a>

## Constants


<a name="0x0_controller_EInvalidDuration"></a>



<pre><code><b>const</b> <a href="controller.md#0x0_controller_EInvalidDuration">EInvalidDuration</a>: u64 = 306;
</code></pre>



<a name="0x0_controller_ELabelUnAvailable"></a>



<pre><code><b>const</b> <a href="controller.md#0x0_controller_ELabelUnAvailable">ELabelUnAvailable</a>: u64 = 308;
</code></pre>



<a name="0x0_controller_ECommitmentNotExists"></a>



<pre><code><b>const</b> <a href="controller.md#0x0_controller_ECommitmentNotExists">ECommitmentNotExists</a>: u64 = 302;
</code></pre>



<a name="0x0_controller_ECommitmentNotValid"></a>



<pre><code><b>const</b> <a href="controller.md#0x0_controller_ECommitmentNotValid">ECommitmentNotValid</a>: u64 = 303;
</code></pre>



<a name="0x0_controller_ECommitmentTooOld"></a>



<pre><code><b>const</b> <a href="controller.md#0x0_controller_ECommitmentTooOld">ECommitmentTooOld</a>: u64 = 304;
</code></pre>



<a name="0x0_controller_EInvalidCode"></a>



<pre><code><b>const</b> <a href="controller.md#0x0_controller_EInvalidCode">EInvalidCode</a>: u64 = 311;
</code></pre>



<a name="0x0_controller_EInvalidResolverAddress"></a>



<pre><code><b>const</b> <a href="controller.md#0x0_controller_EInvalidResolverAddress">EInvalidResolverAddress</a>: u64 = 301;
</code></pre>



<a name="0x0_controller_ENoProfits"></a>



<pre><code><b>const</b> <a href="controller.md#0x0_controller_ENoProfits">ENoProfits</a>: u64 = 310;
</code></pre>



<a name="0x0_controller_ENotEnoughFee"></a>



<pre><code><b>const</b> <a href="controller.md#0x0_controller_ENotEnoughFee">ENotEnoughFee</a>: u64 = 305;
</code></pre>



<a name="0x0_controller_ERegistrationIsDisabled"></a>



<pre><code><b>const</b> <a href="controller.md#0x0_controller_ERegistrationIsDisabled">ERegistrationIsDisabled</a>: u64 = 312;
</code></pre>



<a name="0x0_controller_set_default_resolver"></a>

## Function `set_default_resolver`


<a name="@Notice_1"></a>

###### Notice

The admin uses this function to set default resolver address,
which is the default value when registering without config.


<a name="@Dev_2"></a>

###### Dev

The <code>default_addr_resolver</code> property of Controller share object is updated.


<a name="@Params_3"></a>

###### Params

<code><a href="resolver.md#0x0_resolver">resolver</a></code>: address of new default resolver.


<pre><code><b>public</b> entry <b>fun</b> <a href="controller.md#0x0_controller_set_default_resolver">set_default_resolver</a>(_: &<a href="base_registry.md#0x0_base_registry_AdminCap">base_registry::AdminCap</a>, <a href="controller.md#0x0_controller">controller</a>: &<b>mut</b> <a href="controller.md#0x0_controller_BaseController">controller::BaseController</a>, <a href="resolver.md#0x0_resolver">resolver</a>: <b>address</b>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="controller.md#0x0_controller_set_default_resolver">set_default_resolver</a>(_: &AdminCap, <a href="controller.md#0x0_controller">controller</a>: &<b>mut</b> <a href="controller.md#0x0_controller_BaseController">BaseController</a>, <a href="resolver.md#0x0_resolver">resolver</a>: <b>address</b>) {
    <a href="controller.md#0x0_controller">controller</a>.default_addr_resolver = <a href="resolver.md#0x0_resolver">resolver</a>;
    <a href="_emit">event::emit</a>(<a href="controller.md#0x0_controller_DefaultResolverChangedEvent">DefaultResolverChangedEvent</a> { <a href="resolver.md#0x0_resolver">resolver</a> })
}
</code></pre>



</details>

<a name="0x0_controller_commit"></a>

## Function `commit`


<a name="@Notice_4"></a>

###### Notice

This function is the first step in the commit/reveal process, which is implemented to prevent front-running.


<a name="@Dev_5"></a>

###### Dev

This also removes outdated commentments.


<a name="@Params_6"></a>

###### Params

<code>commitment</code>: hash from <code>make_commitment</code>


<pre><code><b>public</b> entry <b>fun</b> <a href="controller.md#0x0_controller_commit">commit</a>(<a href="controller.md#0x0_controller">controller</a>: &<b>mut</b> <a href="controller.md#0x0_controller_BaseController">controller::BaseController</a>, commitment: <a href="">vector</a>&lt;u8&gt;, ctx: &<b>mut</b> <a href="_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="controller.md#0x0_controller_commit">commit</a>(
    <a href="controller.md#0x0_controller">controller</a>: &<b>mut</b> <a href="controller.md#0x0_controller_BaseController">BaseController</a>,
    commitment: <a href="">vector</a>&lt;u8&gt;,
    ctx: &<b>mut</b> TxContext,
) {
    <a href="controller.md#0x0_controller_remove_outdated_commitments">remove_outdated_commitments</a>(<a href="controller.md#0x0_controller">controller</a>, ctx);
    <a href="_push_back">linked_table::push_back</a>(&<b>mut</b> <a href="controller.md#0x0_controller">controller</a>.commitments, commitment, epoch(ctx));
}
</code></pre>



</details>

<a name="0x0_controller_register"></a>

## Function `register`


<a name="@Notice_7"></a>

###### Notice

This function is the second step in the commit/reveal process, which is implemented to prevent front-running.
It acts as a gatekeeper for the <code>Registrar::Controller</code>, responsible for node validation and charging payment.


<a name="@Dev_8"></a>

###### Dev

This function uses default resolver address.


<a name="@Params_9"></a>

###### Params

<code>label</code>: label of the node being registered, the node has the form <code>label</code>.sui
<code>owner</code>: owner address of created NFT
<code>no_years</code>: in years
<code>secret</code>: the value used to create commitment in the first step


<a name="@Panic_10"></a>

###### Panic

Panic if new registration is disabled
or <code>label</code> contains characters that are not allowed
or <code>label</code> is waiting to be finalized in auction
or label length isn't outside of the permitted range
or <code>payment</code> doesn't have enough coins
or either <code>referral_code</code> or <code>discount_code</code> is invalid


<pre><code><b>public</b> entry <b>fun</b> <a href="controller.md#0x0_controller_register">register</a>(<a href="controller.md#0x0_controller">controller</a>: &<b>mut</b> <a href="controller.md#0x0_controller_BaseController">controller::BaseController</a>, registrar: &<b>mut</b> <a href="base_registrar.md#0x0_base_registrar_BaseRegistrar">base_registrar::BaseRegistrar</a>, registry: &<b>mut</b> <a href="base_registry.md#0x0_base_registry_Registry">base_registry::Registry</a>, config: &<b>mut</b> <a href="configuration.md#0x0_configuration_Configuration">configuration::Configuration</a>, <a href="auction.md#0x0_auction">auction</a>: &<a href="auction.md#0x0_auction_Auction">auction::Auction</a>, label: <a href="">vector</a>&lt;u8&gt;, owner: <b>address</b>, no_years: u64, secret: <a href="">vector</a>&lt;u8&gt;, payment: &<b>mut</b> <a href="_Coin">coin::Coin</a>&lt;<a href="_SUI">sui::SUI</a>&gt;, ctx: &<b>mut</b> <a href="_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="controller.md#0x0_controller_register">register</a>(
    <a href="controller.md#0x0_controller">controller</a>: &<b>mut</b> <a href="controller.md#0x0_controller_BaseController">BaseController</a>,
    registrar: &<b>mut</b> BaseRegistrar,
    registry: &<b>mut</b> Registry,
    config: &<b>mut</b> Configuration,
    <a href="auction.md#0x0_auction">auction</a>: &Auction,
    label: <a href="">vector</a>&lt;u8&gt;,
    owner: <b>address</b>,
    no_years: u64,
    secret: <a href="">vector</a>&lt;u8&gt;,
    payment: &<b>mut</b> Coin&lt;SUI&gt;,
    ctx: &<b>mut</b> TxContext,
) {
    <b>let</b> <a href="resolver.md#0x0_resolver">resolver</a> = <a href="controller.md#0x0_controller">controller</a>.default_addr_resolver;
    <a href="controller.md#0x0_controller_register_internal">register_internal</a>(
        <a href="controller.md#0x0_controller">controller</a>,
        registrar,
        registry,
        config,
        <a href="auction.md#0x0_auction">auction</a>,
        label,
        owner,
        no_years,
        secret,
        <a href="resolver.md#0x0_resolver">resolver</a>,
        payment,
        <a href="_none">option::none</a>(),
        <a href="_none">option::none</a>(),
        <a href="">vector</a>[],
        <a href="">vector</a>[],
        <a href="">vector</a>[],
        ctx,
    );
}
</code></pre>



</details>

<a name="0x0_controller_register_with_image"></a>

## Function `register_with_image`


<a name="@Notice_11"></a>

###### Notice

This function is the second step in the commit/reveal process, which is implemented to prevent front-running.
It acts as a gatekeeper for the <code>Registrar::Controller</code>, responsible for node validation and charging payment.


<a name="@Dev_12"></a>

###### Dev

This function uses default resolver address.


<a name="@Params_13"></a>

###### Params

<code>label</code>: label of the node being registered, the node has the form <code>label</code>.sui
<code>owner</code>: owner address of created NFT
<code>no_years</code>: in years
<code>secret</code>: the value used to create commitment in the first step
<code>signature</code>: secp256k1 of <code>hashed_msg</code>
<code>hashed_msg</code>: sha256 of <code>raw_msg</code>
<code>raw_msg</code>: the data to verify and update image url, with format: <ipfs_url>,<owner>,<expiry>.
Note: <code>owner</code> is a 40 hexadecimal string without <code>0x</code> prefix

Panic
Panic if new registration is disabled
or <code>label</code> contains characters that are not allowed
or <code>label</code> is pending to be finalized by the winner of auction
or label length isn't outside of the permitted range
or <code>payment</code> doesn't have enough coins
or either <code>referral_code</code> or <code>discount_code</code> is invalid


<pre><code><b>public</b> entry <b>fun</b> <a href="controller.md#0x0_controller_register_with_image">register_with_image</a>(<a href="controller.md#0x0_controller">controller</a>: &<b>mut</b> <a href="controller.md#0x0_controller_BaseController">controller::BaseController</a>, registrar: &<b>mut</b> <a href="base_registrar.md#0x0_base_registrar_BaseRegistrar">base_registrar::BaseRegistrar</a>, registry: &<b>mut</b> <a href="base_registry.md#0x0_base_registry_Registry">base_registry::Registry</a>, config: &<b>mut</b> <a href="configuration.md#0x0_configuration_Configuration">configuration::Configuration</a>, <a href="auction.md#0x0_auction">auction</a>: &<a href="auction.md#0x0_auction_Auction">auction::Auction</a>, label: <a href="">vector</a>&lt;u8&gt;, owner: <b>address</b>, no_years: u64, secret: <a href="">vector</a>&lt;u8&gt;, payment: &<b>mut</b> <a href="_Coin">coin::Coin</a>&lt;<a href="_SUI">sui::SUI</a>&gt;, signature: <a href="">vector</a>&lt;u8&gt;, hashed_msg: <a href="">vector</a>&lt;u8&gt;, raw_msg: <a href="">vector</a>&lt;u8&gt;, ctx: &<b>mut</b> <a href="_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="controller.md#0x0_controller_register_with_image">register_with_image</a>(
    <a href="controller.md#0x0_controller">controller</a>: &<b>mut</b> <a href="controller.md#0x0_controller_BaseController">BaseController</a>,
    registrar: &<b>mut</b> BaseRegistrar,
    registry: &<b>mut</b> Registry,
    config: &<b>mut</b> Configuration,
    <a href="auction.md#0x0_auction">auction</a>: &Auction,
    label: <a href="">vector</a>&lt;u8&gt;,
    owner: <b>address</b>,
    no_years: u64,
    secret: <a href="">vector</a>&lt;u8&gt;,
    payment: &<b>mut</b> Coin&lt;SUI&gt;,
    signature: <a href="">vector</a>&lt;u8&gt;,
    hashed_msg: <a href="">vector</a>&lt;u8&gt;,
    raw_msg: <a href="">vector</a>&lt;u8&gt;,
    ctx: &<b>mut</b> TxContext,
) {
    <a href="base_registrar.md#0x0_base_registrar_assert_image_msg_not_empty">base_registrar::assert_image_msg_not_empty</a>(&signature, &hashed_msg, &raw_msg);
    <b>let</b> <a href="resolver.md#0x0_resolver">resolver</a> = <a href="controller.md#0x0_controller">controller</a>.default_addr_resolver;

    <a href="controller.md#0x0_controller_register_internal">register_internal</a>(
        <a href="controller.md#0x0_controller">controller</a>,
        registrar,
        registry,
        config,
        <a href="auction.md#0x0_auction">auction</a>,
        label,
        owner,
        no_years,
        secret,
        <a href="resolver.md#0x0_resolver">resolver</a>,
        payment,
        <a href="_none">option::none</a>(),
        <a href="_none">option::none</a>(),
        signature,
        hashed_msg,
        raw_msg,
        ctx,
    );
}
</code></pre>



</details>

<a name="0x0_controller_register_with_config"></a>

## Function `register_with_config`


<a name="@Notice_14"></a>

###### Notice

Similar to the <code>register</code> function, with an added <code><a href="resolver.md#0x0_resolver">resolver</a></code> parameter.


<a name="@Dev_15"></a>

###### Dev

Use <code><a href="resolver.md#0x0_resolver">resolver</a></code> parameter for resolver address.


<a name="@Params_16"></a>

###### Params

<code><a href="resolver.md#0x0_resolver">resolver</a></code>: address of the resolver


<pre><code><b>public</b> entry <b>fun</b> <a href="controller.md#0x0_controller_register_with_config">register_with_config</a>(<a href="controller.md#0x0_controller">controller</a>: &<b>mut</b> <a href="controller.md#0x0_controller_BaseController">controller::BaseController</a>, registrar: &<b>mut</b> <a href="base_registrar.md#0x0_base_registrar_BaseRegistrar">base_registrar::BaseRegistrar</a>, registry: &<b>mut</b> <a href="base_registry.md#0x0_base_registry_Registry">base_registry::Registry</a>, config: &<b>mut</b> <a href="configuration.md#0x0_configuration_Configuration">configuration::Configuration</a>, <a href="auction.md#0x0_auction">auction</a>: &<a href="auction.md#0x0_auction_Auction">auction::Auction</a>, label: <a href="">vector</a>&lt;u8&gt;, owner: <b>address</b>, no_years: u64, secret: <a href="">vector</a>&lt;u8&gt;, <a href="resolver.md#0x0_resolver">resolver</a>: <b>address</b>, payment: &<b>mut</b> <a href="_Coin">coin::Coin</a>&lt;<a href="_SUI">sui::SUI</a>&gt;, ctx: &<b>mut</b> <a href="_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="controller.md#0x0_controller_register_with_config">register_with_config</a>(
    <a href="controller.md#0x0_controller">controller</a>: &<b>mut</b> <a href="controller.md#0x0_controller_BaseController">BaseController</a>,
    registrar: &<b>mut</b> BaseRegistrar,
    registry: &<b>mut</b> Registry,
    config: &<b>mut</b> Configuration,
    <a href="auction.md#0x0_auction">auction</a>: &Auction,
    label: <a href="">vector</a>&lt;u8&gt;,
    owner: <b>address</b>,
    no_years: u64,
    secret: <a href="">vector</a>&lt;u8&gt;,
    <a href="resolver.md#0x0_resolver">resolver</a>: <b>address</b>,
    payment: &<b>mut</b> Coin&lt;SUI&gt;,
    ctx: &<b>mut</b> TxContext,
) {
    <a href="controller.md#0x0_controller_register_internal">register_internal</a>(
        <a href="controller.md#0x0_controller">controller</a>,
        registrar,
        registry,
        config,
        <a href="auction.md#0x0_auction">auction</a>,
        label,
        owner,
        no_years,
        secret,
        <a href="resolver.md#0x0_resolver">resolver</a>,
        payment,
        <a href="_none">option::none</a>(),
        <a href="_none">option::none</a>(),
        <a href="">vector</a>[],
        <a href="">vector</a>[],
        <a href="">vector</a>[],
        ctx
    );
}
</code></pre>



</details>

<a name="0x0_controller_register_with_config_and_image"></a>

## Function `register_with_config_and_image`


<a name="@Notice_17"></a>

###### Notice

Similar to the <code>register_with_image</code> function, with an added <code><a href="resolver.md#0x0_resolver">resolver</a></code> parameter.


<a name="@Dev_18"></a>

###### Dev

Use <code><a href="resolver.md#0x0_resolver">resolver</a></code> parameter for resolver address.


<a name="@Params_19"></a>

###### Params

<code><a href="resolver.md#0x0_resolver">resolver</a></code>: address of the resolver
<code>signature</code>: secp256k1 of <code>hashed_msg</code>
<code>hashed_msg</code>: sha256 of <code>raw_msg</code>
<code>raw_msg</code>: the data to verify and update image url, with format: <ipfs_url>,<owner>,<expiry>.
Note: <code>owner</code> is a 40 hexadecimal string without <code>0x</code> prefix


<pre><code><b>public</b> entry <b>fun</b> <a href="controller.md#0x0_controller_register_with_config_and_image">register_with_config_and_image</a>(<a href="controller.md#0x0_controller">controller</a>: &<b>mut</b> <a href="controller.md#0x0_controller_BaseController">controller::BaseController</a>, registrar: &<b>mut</b> <a href="base_registrar.md#0x0_base_registrar_BaseRegistrar">base_registrar::BaseRegistrar</a>, registry: &<b>mut</b> <a href="base_registry.md#0x0_base_registry_Registry">base_registry::Registry</a>, config: &<b>mut</b> <a href="configuration.md#0x0_configuration_Configuration">configuration::Configuration</a>, <a href="auction.md#0x0_auction">auction</a>: &<a href="auction.md#0x0_auction_Auction">auction::Auction</a>, label: <a href="">vector</a>&lt;u8&gt;, owner: <b>address</b>, no_years: u64, secret: <a href="">vector</a>&lt;u8&gt;, <a href="resolver.md#0x0_resolver">resolver</a>: <b>address</b>, payment: &<b>mut</b> <a href="_Coin">coin::Coin</a>&lt;<a href="_SUI">sui::SUI</a>&gt;, signature: <a href="">vector</a>&lt;u8&gt;, hashed_msg: <a href="">vector</a>&lt;u8&gt;, raw_msg: <a href="">vector</a>&lt;u8&gt;, ctx: &<b>mut</b> <a href="_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="controller.md#0x0_controller_register_with_config_and_image">register_with_config_and_image</a>(
    <a href="controller.md#0x0_controller">controller</a>: &<b>mut</b> <a href="controller.md#0x0_controller_BaseController">BaseController</a>,
    registrar: &<b>mut</b> BaseRegistrar,
    registry: &<b>mut</b> Registry,
    config: &<b>mut</b> Configuration,
    <a href="auction.md#0x0_auction">auction</a>: &Auction,
    label: <a href="">vector</a>&lt;u8&gt;,
    owner: <b>address</b>,
    no_years: u64,
    secret: <a href="">vector</a>&lt;u8&gt;,
    <a href="resolver.md#0x0_resolver">resolver</a>: <b>address</b>,
    payment: &<b>mut</b> Coin&lt;SUI&gt;,
    signature: <a href="">vector</a>&lt;u8&gt;,
    hashed_msg: <a href="">vector</a>&lt;u8&gt;,
    raw_msg: <a href="">vector</a>&lt;u8&gt;,
    ctx: &<b>mut</b> TxContext,
) {
    <a href="base_registrar.md#0x0_base_registrar_assert_image_msg_not_empty">base_registrar::assert_image_msg_not_empty</a>(&signature, &hashed_msg, &raw_msg);

    <a href="controller.md#0x0_controller_register_internal">register_internal</a>(
        <a href="controller.md#0x0_controller">controller</a>,
        registrar,
        registry,
        config,
        <a href="auction.md#0x0_auction">auction</a>,
        label,
        owner,
        no_years,
        secret,
        <a href="resolver.md#0x0_resolver">resolver</a>,
        payment,
        <a href="_none">option::none</a>(),
        <a href="_none">option::none</a>(),
        signature,
        hashed_msg,
        raw_msg,
        ctx
    );
}
</code></pre>



</details>

<a name="0x0_controller_register_with_code"></a>

## Function `register_with_code`


<a name="@Notice_20"></a>

###### Notice

Similar to the <code>register</code> function, with added <code>referral_code</code> and <code>discount_code</code> parameters.
Can use one or two codes at the same time.
<code>discount_code</code> is applied first before <code>referral_code</code> if use both.


<a name="@Dev_21"></a>

###### Dev

Use empty string for unused code, however, at least one code must be used.
Remove <code>discount_code</code> after this function returns.


<a name="@Params_22"></a>

###### Params

<code>referral_code</code>: referral code to be used
<code>discount_code</code>: discount code to be used


<pre><code><b>public</b> entry <b>fun</b> <a href="controller.md#0x0_controller_register_with_code">register_with_code</a>(<a href="controller.md#0x0_controller">controller</a>: &<b>mut</b> <a href="controller.md#0x0_controller_BaseController">controller::BaseController</a>, registrar: &<b>mut</b> <a href="base_registrar.md#0x0_base_registrar_BaseRegistrar">base_registrar::BaseRegistrar</a>, registry: &<b>mut</b> <a href="base_registry.md#0x0_base_registry_Registry">base_registry::Registry</a>, config: &<b>mut</b> <a href="configuration.md#0x0_configuration_Configuration">configuration::Configuration</a>, <a href="auction.md#0x0_auction">auction</a>: &<a href="auction.md#0x0_auction_Auction">auction::Auction</a>, label: <a href="">vector</a>&lt;u8&gt;, owner: <b>address</b>, no_years: u64, secret: <a href="">vector</a>&lt;u8&gt;, payment: &<b>mut</b> <a href="_Coin">coin::Coin</a>&lt;<a href="_SUI">sui::SUI</a>&gt;, referral_code: <a href="">vector</a>&lt;u8&gt;, discount_code: <a href="">vector</a>&lt;u8&gt;, ctx: &<b>mut</b> <a href="_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="controller.md#0x0_controller_register_with_code">register_with_code</a>(
    <a href="controller.md#0x0_controller">controller</a>: &<b>mut</b> <a href="controller.md#0x0_controller_BaseController">BaseController</a>,
    registrar: &<b>mut</b> BaseRegistrar,
    registry: &<b>mut</b> Registry,
    config: &<b>mut</b> Configuration,
    <a href="auction.md#0x0_auction">auction</a>: &Auction,
    label: <a href="">vector</a>&lt;u8&gt;,
    owner: <b>address</b>,
    no_years: u64,
    secret: <a href="">vector</a>&lt;u8&gt;,
    payment: &<b>mut</b> Coin&lt;SUI&gt;,
    referral_code: <a href="">vector</a>&lt;u8&gt;,
    discount_code: <a href="">vector</a>&lt;u8&gt;,
    ctx: &<b>mut</b> TxContext,
) {
    <b>let</b> (referral_code, discount_code) = <a href="controller.md#0x0_controller_validate_codes">validate_codes</a>(referral_code, discount_code);
    <b>let</b> <a href="resolver.md#0x0_resolver">resolver</a> = <a href="controller.md#0x0_controller">controller</a>.default_addr_resolver;

    <a href="controller.md#0x0_controller_register_internal">register_internal</a>(
        <a href="controller.md#0x0_controller">controller</a>,
        registrar,
        registry,
        config,
        <a href="auction.md#0x0_auction">auction</a>,
        label,
        owner,
        no_years,
        secret,
        <a href="resolver.md#0x0_resolver">resolver</a>,
        payment,
        referral_code,
        discount_code,
        <a href="">vector</a>[],
        <a href="">vector</a>[],
        <a href="">vector</a>[],
        ctx,
    );
}
</code></pre>



</details>

<a name="0x0_controller_register_with_code_and_image"></a>

## Function `register_with_code_and_image`


<a name="@Notice_23"></a>

###### Notice

Similar to the <code>register</code> function, with added <code>referral_code</code> and <code>discount_code</code> parameters.
Can use one or two codes at the same time.
<code>discount_code</code> is applied first before <code>referral_code</code> if use both.


<a name="@Dev_24"></a>

###### Dev

Use empty string for unused code, however, at least one code must be used.
Remove <code>discount_code</code> after this function returns.


<a name="@Params_25"></a>

###### Params

<code>referral_code</code>: referral code to be used
<code>discount_code</code>: discount code to be used
<code>signature</code>: secp256k1 of <code>hashed_msg</code>
<code>hashed_msg</code>: sha256 of <code>raw_msg</code>
<code>raw_msg</code>: the data to verify and update image url, with format: <ipfs_url>,<owner>,<expiry>.
Note: <code>owner</code> is a 40 hexadecimal string without <code>0x</code> prefix


<pre><code><b>public</b> entry <b>fun</b> <a href="controller.md#0x0_controller_register_with_code_and_image">register_with_code_and_image</a>(<a href="controller.md#0x0_controller">controller</a>: &<b>mut</b> <a href="controller.md#0x0_controller_BaseController">controller::BaseController</a>, registrar: &<b>mut</b> <a href="base_registrar.md#0x0_base_registrar_BaseRegistrar">base_registrar::BaseRegistrar</a>, registry: &<b>mut</b> <a href="base_registry.md#0x0_base_registry_Registry">base_registry::Registry</a>, config: &<b>mut</b> <a href="configuration.md#0x0_configuration_Configuration">configuration::Configuration</a>, <a href="auction.md#0x0_auction">auction</a>: &<a href="auction.md#0x0_auction_Auction">auction::Auction</a>, label: <a href="">vector</a>&lt;u8&gt;, owner: <b>address</b>, no_years: u64, secret: <a href="">vector</a>&lt;u8&gt;, payment: &<b>mut</b> <a href="_Coin">coin::Coin</a>&lt;<a href="_SUI">sui::SUI</a>&gt;, referral_code: <a href="">vector</a>&lt;u8&gt;, discount_code: <a href="">vector</a>&lt;u8&gt;, signature: <a href="">vector</a>&lt;u8&gt;, hashed_msg: <a href="">vector</a>&lt;u8&gt;, raw_msg: <a href="">vector</a>&lt;u8&gt;, ctx: &<b>mut</b> <a href="_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="controller.md#0x0_controller_register_with_code_and_image">register_with_code_and_image</a>(
    <a href="controller.md#0x0_controller">controller</a>: &<b>mut</b> <a href="controller.md#0x0_controller_BaseController">BaseController</a>,
    registrar: &<b>mut</b> BaseRegistrar,
    registry: &<b>mut</b> Registry,
    config: &<b>mut</b> Configuration,
    <a href="auction.md#0x0_auction">auction</a>: &Auction,
    label: <a href="">vector</a>&lt;u8&gt;,
    owner: <b>address</b>,
    no_years: u64,
    secret: <a href="">vector</a>&lt;u8&gt;,
    payment: &<b>mut</b> Coin&lt;SUI&gt;,
    referral_code: <a href="">vector</a>&lt;u8&gt;,
    discount_code: <a href="">vector</a>&lt;u8&gt;,
    signature: <a href="">vector</a>&lt;u8&gt;,
    hashed_msg: <a href="">vector</a>&lt;u8&gt;,
    raw_msg: <a href="">vector</a>&lt;u8&gt;,
    ctx: &<b>mut</b> TxContext,
) {
    <a href="base_registrar.md#0x0_base_registrar_assert_image_msg_not_empty">base_registrar::assert_image_msg_not_empty</a>(&signature, &hashed_msg, &raw_msg);
    <b>let</b> (referral_code, discount_code) = <a href="controller.md#0x0_controller_validate_codes">validate_codes</a>(referral_code, discount_code);
    <b>let</b> <a href="resolver.md#0x0_resolver">resolver</a> = <a href="controller.md#0x0_controller">controller</a>.default_addr_resolver;

    <a href="controller.md#0x0_controller_register_internal">register_internal</a>(
        <a href="controller.md#0x0_controller">controller</a>,
        registrar,
        registry,
        config,
        <a href="auction.md#0x0_auction">auction</a>,
        label,
        owner,
        no_years,
        secret,
        <a href="resolver.md#0x0_resolver">resolver</a>,
        payment,
        referral_code,
        discount_code,
        signature,
        hashed_msg,
        raw_msg,
        ctx,
    );
}
</code></pre>



</details>

<a name="0x0_controller_register_with_config_and_code"></a>

## Function `register_with_config_and_code`


<a name="@Notice_26"></a>

###### Notice

Similar to the <code>register_with_config</code> function, with added <code>referral_code</code> and <code>discount_code</code> parameters.
Can use one or two codes at the same time.
<code>discount_code</code> is applied first before <code>referral_code</code> if use both.


<a name="@Dev_27"></a>

###### Dev

Use empty string for unused code, however, at least one code must be used.
Remove <code>discount_code</code> after this function returns.


<a name="@Params_28"></a>

###### Params

<code>referral_code</code>: referral code to be used
<code>discount_code</code>: discount code to be used


<pre><code><b>public</b> entry <b>fun</b> <a href="controller.md#0x0_controller_register_with_config_and_code">register_with_config_and_code</a>(<a href="controller.md#0x0_controller">controller</a>: &<b>mut</b> <a href="controller.md#0x0_controller_BaseController">controller::BaseController</a>, registrar: &<b>mut</b> <a href="base_registrar.md#0x0_base_registrar_BaseRegistrar">base_registrar::BaseRegistrar</a>, registry: &<b>mut</b> <a href="base_registry.md#0x0_base_registry_Registry">base_registry::Registry</a>, config: &<b>mut</b> <a href="configuration.md#0x0_configuration_Configuration">configuration::Configuration</a>, <a href="auction.md#0x0_auction">auction</a>: &<a href="auction.md#0x0_auction_Auction">auction::Auction</a>, label: <a href="">vector</a>&lt;u8&gt;, owner: <b>address</b>, no_years: u64, secret: <a href="">vector</a>&lt;u8&gt;, <a href="resolver.md#0x0_resolver">resolver</a>: <b>address</b>, payment: &<b>mut</b> <a href="_Coin">coin::Coin</a>&lt;<a href="_SUI">sui::SUI</a>&gt;, referral_code: <a href="">vector</a>&lt;u8&gt;, discount_code: <a href="">vector</a>&lt;u8&gt;, ctx: &<b>mut</b> <a href="_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="controller.md#0x0_controller_register_with_config_and_code">register_with_config_and_code</a>(
    <a href="controller.md#0x0_controller">controller</a>: &<b>mut</b> <a href="controller.md#0x0_controller_BaseController">BaseController</a>,
    registrar: &<b>mut</b> BaseRegistrar,
    registry: &<b>mut</b> Registry,
    config: &<b>mut</b> Configuration,
    <a href="auction.md#0x0_auction">auction</a>: &Auction,
    label: <a href="">vector</a>&lt;u8&gt;,
    owner: <b>address</b>,
    no_years: u64,
    secret: <a href="">vector</a>&lt;u8&gt;,
    <a href="resolver.md#0x0_resolver">resolver</a>: <b>address</b>,
    payment: &<b>mut</b> Coin&lt;SUI&gt;,
    referral_code: <a href="">vector</a>&lt;u8&gt;,
    discount_code: <a href="">vector</a>&lt;u8&gt;,
    ctx: &<b>mut</b> TxContext,
) {
    <b>let</b> (referral_code, discount_code) = <a href="controller.md#0x0_controller_validate_codes">validate_codes</a>(referral_code, discount_code);

    <a href="controller.md#0x0_controller_register_internal">register_internal</a>(
        <a href="controller.md#0x0_controller">controller</a>,
        registrar,
        registry,
        config,
        <a href="auction.md#0x0_auction">auction</a>,
        label,
        owner,
        no_years,
        secret,
        <a href="resolver.md#0x0_resolver">resolver</a>,
        payment,
        referral_code,
        discount_code,
        <a href="">vector</a>[],
        <a href="">vector</a>[],
        <a href="">vector</a>[],
        ctx,
    );
}
</code></pre>



</details>

<a name="0x0_controller_register_with_config_and_code_and_image"></a>

## Function `register_with_config_and_code_and_image`


<a name="@Notice_29"></a>

###### Notice

Similar to the <code>register_with_config</code> function, with added <code>referral_code</code> and <code>discount_code</code> parameters.
Can use one or two codes at the same time.
<code>discount_code</code> is applied first before <code>referral_code</code> if use both.


<a name="@Dev_30"></a>

###### Dev

Use empty string for unused code, however, at least one code must be used.
Remove <code>discount_code</code> after this function returns.


<a name="@Params_31"></a>

###### Params

<code>referral_code</code>: referral code to be used
<code>discount_code</code>: discount code to be used
<code>signature</code>: secp256k1 of <code>hashed_msg</code>
<code>hashed_msg</code>: sha256 of <code>raw_msg</code>
<code>raw_msg</code>: the data to verify and update image url, with format: <ipfs_url>,<owner>,<expiry>.
Note: <code>owner</code> is a 40 hexadecimal string without <code>0x</code> prefix


<pre><code><b>public</b> entry <b>fun</b> <a href="controller.md#0x0_controller_register_with_config_and_code_and_image">register_with_config_and_code_and_image</a>(<a href="controller.md#0x0_controller">controller</a>: &<b>mut</b> <a href="controller.md#0x0_controller_BaseController">controller::BaseController</a>, registrar: &<b>mut</b> <a href="base_registrar.md#0x0_base_registrar_BaseRegistrar">base_registrar::BaseRegistrar</a>, registry: &<b>mut</b> <a href="base_registry.md#0x0_base_registry_Registry">base_registry::Registry</a>, config: &<b>mut</b> <a href="configuration.md#0x0_configuration_Configuration">configuration::Configuration</a>, <a href="auction.md#0x0_auction">auction</a>: &<a href="auction.md#0x0_auction_Auction">auction::Auction</a>, label: <a href="">vector</a>&lt;u8&gt;, owner: <b>address</b>, no_years: u64, secret: <a href="">vector</a>&lt;u8&gt;, <a href="resolver.md#0x0_resolver">resolver</a>: <b>address</b>, payment: &<b>mut</b> <a href="_Coin">coin::Coin</a>&lt;<a href="_SUI">sui::SUI</a>&gt;, referral_code: <a href="">vector</a>&lt;u8&gt;, discount_code: <a href="">vector</a>&lt;u8&gt;, signature: <a href="">vector</a>&lt;u8&gt;, hashed_msg: <a href="">vector</a>&lt;u8&gt;, raw_msg: <a href="">vector</a>&lt;u8&gt;, ctx: &<b>mut</b> <a href="_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="controller.md#0x0_controller_register_with_config_and_code_and_image">register_with_config_and_code_and_image</a>(
    <a href="controller.md#0x0_controller">controller</a>: &<b>mut</b> <a href="controller.md#0x0_controller_BaseController">BaseController</a>,
    registrar: &<b>mut</b> BaseRegistrar,
    registry: &<b>mut</b> Registry,
    config: &<b>mut</b> Configuration,
    <a href="auction.md#0x0_auction">auction</a>: &Auction,
    label: <a href="">vector</a>&lt;u8&gt;,
    owner: <b>address</b>,
    no_years: u64,
    secret: <a href="">vector</a>&lt;u8&gt;,
    <a href="resolver.md#0x0_resolver">resolver</a>: <b>address</b>,
    payment: &<b>mut</b> Coin&lt;SUI&gt;,
    referral_code: <a href="">vector</a>&lt;u8&gt;,
    discount_code: <a href="">vector</a>&lt;u8&gt;,
    signature: <a href="">vector</a>&lt;u8&gt;,
    hashed_msg: <a href="">vector</a>&lt;u8&gt;,
    raw_msg: <a href="">vector</a>&lt;u8&gt;,
    ctx: &<b>mut</b> TxContext,
) {
    <a href="base_registrar.md#0x0_base_registrar_assert_image_msg_not_empty">base_registrar::assert_image_msg_not_empty</a>(&signature, &hashed_msg, &raw_msg);
    <b>let</b> (referral_code, discount_code) = <a href="controller.md#0x0_controller_validate_codes">validate_codes</a>(referral_code, discount_code);

    <a href="controller.md#0x0_controller_register_internal">register_internal</a>(
        <a href="controller.md#0x0_controller">controller</a>,
        registrar,
        registry,
        config,
        <a href="auction.md#0x0_auction">auction</a>,
        label,
        owner,
        no_years,
        secret,
        <a href="resolver.md#0x0_resolver">resolver</a>,
        payment,
        referral_code,
        discount_code,
        signature,
        hashed_msg,
        raw_msg,
        ctx,
    );
}
</code></pre>



</details>

<a name="0x0_controller_renew"></a>

## Function `renew`


<a name="@Notice_32"></a>

###### Notice

Anyone can use this function to extend expiration of a node. The TLD comes from BaseRegistrar::tld.
It acts as a gatekeeper for the <code>Registrar::Renew</code>, responsible for charging payment.


<a name="@Params_33"></a>

###### Params

<code>label</code>: label of the node being registered, the node has the form <code>label</code>.sui
<code>no_years</code>: in years

Panic
Panic if node doesn't exist
or <code>payment</code> doesn't have enough coins


<pre><code><b>public</b> entry <b>fun</b> <a href="controller.md#0x0_controller_renew">renew</a>(<a href="controller.md#0x0_controller">controller</a>: &<b>mut</b> <a href="controller.md#0x0_controller_BaseController">controller::BaseController</a>, registrar: &<b>mut</b> <a href="base_registrar.md#0x0_base_registrar_BaseRegistrar">base_registrar::BaseRegistrar</a>, label: <a href="">vector</a>&lt;u8&gt;, no_years: u64, payment: &<b>mut</b> <a href="_Coin">coin::Coin</a>&lt;<a href="_SUI">sui::SUI</a>&gt;, ctx: &<b>mut</b> <a href="_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="controller.md#0x0_controller_renew">renew</a>(
    <a href="controller.md#0x0_controller">controller</a>: &<b>mut</b> <a href="controller.md#0x0_controller_BaseController">BaseController</a>,
    registrar: &<b>mut</b> BaseRegistrar,
    label: <a href="">vector</a>&lt;u8&gt;,
    no_years: u64,
    payment: &<b>mut</b> Coin&lt;SUI&gt;,
    ctx: &<b>mut</b> TxContext,
) {
    <a href="controller.md#0x0_controller_renew_internal">renew_internal</a>(<a href="controller.md#0x0_controller">controller</a>, registrar, label, no_years, payment, ctx)
}
</code></pre>



</details>

<a name="0x0_controller_renew_with_image"></a>

## Function `renew_with_image`


<a name="@Notice_34"></a>

###### Notice

Anyone can use this function to extend expiration of a node. The TLD comes from BaseRegistrar::tld.
It acts as a gatekeeper for the <code>Registrar::renew</code>, responsible for charging payment.
The image url of the <code>nft</code> is updated.


<a name="@Params_35"></a>

###### Params

<code>label</code>: label of the node being registered, the node has the form <code>label</code>.sui
<code>no_years</code>: in years

Panic
Panic if node doesn't exist
or <code>payment</code> doesn't have enough coins
or <code>signature</code> is empty
or <code>hashed_msg</code> is empty
or <code>msg</code> is empty


<pre><code><b>public</b> entry <b>fun</b> <a href="controller.md#0x0_controller_renew_with_image">renew_with_image</a>(<a href="controller.md#0x0_controller">controller</a>: &<b>mut</b> <a href="controller.md#0x0_controller_BaseController">controller::BaseController</a>, registrar: &<b>mut</b> <a href="base_registrar.md#0x0_base_registrar_BaseRegistrar">base_registrar::BaseRegistrar</a>, config: &<a href="configuration.md#0x0_configuration_Configuration">configuration::Configuration</a>, label: <a href="">vector</a>&lt;u8&gt;, no_years: u64, payment: &<b>mut</b> <a href="_Coin">coin::Coin</a>&lt;<a href="_SUI">sui::SUI</a>&gt;, nft: &<b>mut</b> <a href="base_registrar.md#0x0_base_registrar_RegistrationNFT">base_registrar::RegistrationNFT</a>, signature: <a href="">vector</a>&lt;u8&gt;, hashed_msg: <a href="">vector</a>&lt;u8&gt;, raw_msg: <a href="">vector</a>&lt;u8&gt;, ctx: &<b>mut</b> <a href="_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="controller.md#0x0_controller_renew_with_image">renew_with_image</a>(
    <a href="controller.md#0x0_controller">controller</a>: &<b>mut</b> <a href="controller.md#0x0_controller_BaseController">BaseController</a>,
    registrar: &<b>mut</b> BaseRegistrar,
    config: &Configuration,
    label: <a href="">vector</a>&lt;u8&gt;,
    no_years: u64,
    payment: &<b>mut</b> Coin&lt;SUI&gt;,
    nft: &<b>mut</b> RegistrationNFT,
    signature: <a href="">vector</a>&lt;u8&gt;,
    hashed_msg: <a href="">vector</a>&lt;u8&gt;,
    raw_msg: <a href="">vector</a>&lt;u8&gt;,
    ctx: &<b>mut</b> TxContext,
) {
    // NFT and imag_msg are validated in `update_image_url`
    <a href="controller.md#0x0_controller_renew_internal">renew_internal</a>(<a href="controller.md#0x0_controller">controller</a>, registrar, label, no_years, payment, ctx);
    <a href="base_registrar.md#0x0_base_registrar_update_image_url">base_registrar::update_image_url</a>(registrar, config, nft, signature, hashed_msg, raw_msg, ctx);
}
</code></pre>



</details>

<a name="0x0_controller_withdraw"></a>

## Function `withdraw`


<a name="@Notice_36"></a>

###### Notice

Admin use this function to withdraw the payment.


<a name="@Panics_37"></a>

###### Panics

Panics if no profits has been created.


<pre><code><b>public</b> entry <b>fun</b> <a href="controller.md#0x0_controller_withdraw">withdraw</a>(_: &<a href="base_registry.md#0x0_base_registry_AdminCap">base_registry::AdminCap</a>, <a href="controller.md#0x0_controller">controller</a>: &<b>mut</b> <a href="controller.md#0x0_controller_BaseController">controller::BaseController</a>, ctx: &<b>mut</b> <a href="_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="controller.md#0x0_controller_withdraw">withdraw</a>(_: &AdminCap, <a href="controller.md#0x0_controller">controller</a>: &<b>mut</b> <a href="controller.md#0x0_controller_BaseController">BaseController</a>, ctx: &<b>mut</b> TxContext) {
    <b>let</b> amount = <a href="_value">balance::value</a>(&<a href="controller.md#0x0_controller">controller</a>.<a href="">balance</a>);
    <b>assert</b>!(amount &gt; 0, <a href="controller.md#0x0_controller_ENoProfits">ENoProfits</a>);

    <a href="coin_util.md#0x0_coin_util_contract_transfer_to_address">coin_util::contract_transfer_to_address</a>(&<b>mut</b> <a href="controller.md#0x0_controller">controller</a>.<a href="">balance</a>, amount, sender(ctx), ctx);
}
</code></pre>



</details>

<a name="0x0_controller_renew_internal"></a>

## Function `renew_internal`



<pre><code><b>fun</b> <a href="controller.md#0x0_controller_renew_internal">renew_internal</a>(<a href="controller.md#0x0_controller">controller</a>: &<b>mut</b> <a href="controller.md#0x0_controller_BaseController">controller::BaseController</a>, registrar: &<b>mut</b> <a href="base_registrar.md#0x0_base_registrar_BaseRegistrar">base_registrar::BaseRegistrar</a>, label: <a href="">vector</a>&lt;u8&gt;, no_years: u64, payment: &<b>mut</b> <a href="_Coin">coin::Coin</a>&lt;<a href="_SUI">sui::SUI</a>&gt;, ctx: &<b>mut</b> <a href="_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="controller.md#0x0_controller_renew_internal">renew_internal</a>(
    <a href="controller.md#0x0_controller">controller</a>: &<b>mut</b> <a href="controller.md#0x0_controller_BaseController">BaseController</a>,
    registrar: &<b>mut</b> BaseRegistrar,
    label: <a href="">vector</a>&lt;u8&gt;,
    no_years: u64,
    payment: &<b>mut</b> Coin&lt;SUI&gt;,
    ctx: &<b>mut</b> TxContext
) {
    <b>let</b> renew_fee = price_for_node(no_years);
    <b>assert</b>!(<a href="_value">coin::value</a>(payment) &gt;= renew_fee, <a href="controller.md#0x0_controller_ENotEnoughFee">ENotEnoughFee</a>);
    <a href="coin_util.md#0x0_coin_util_user_transfer_to_contract">coin_util::user_transfer_to_contract</a>(payment, renew_fee, &<b>mut</b> <a href="controller.md#0x0_controller">controller</a>.<a href="">balance</a>);

    <b>let</b> duration = no_years * 365;
    <a href="base_registrar.md#0x0_base_registrar_renew">base_registrar::renew</a>(registrar, label, duration, ctx);

    <a href="_emit">event::emit</a>(<a href="controller.md#0x0_controller_NameRenewedEvent">NameRenewedEvent</a> {
        node: <a href="base_registrar.md#0x0_base_registrar_base_node">base_registrar::base_node</a>(registrar),
        label: <a href="_utf8">string::utf8</a>(label),
        cost: renew_fee,
        duration,
    });
}
</code></pre>



</details>

<a name="0x0_controller_register_internal"></a>

## Function `register_internal`



<pre><code><b>fun</b> <a href="controller.md#0x0_controller_register_internal">register_internal</a>(<a href="controller.md#0x0_controller">controller</a>: &<b>mut</b> <a href="controller.md#0x0_controller_BaseController">controller::BaseController</a>, registrar: &<b>mut</b> <a href="base_registrar.md#0x0_base_registrar_BaseRegistrar">base_registrar::BaseRegistrar</a>, registry: &<b>mut</b> <a href="base_registry.md#0x0_base_registry_Registry">base_registry::Registry</a>, config: &<b>mut</b> <a href="configuration.md#0x0_configuration_Configuration">configuration::Configuration</a>, <a href="auction.md#0x0_auction">auction</a>: &<a href="auction.md#0x0_auction_Auction">auction::Auction</a>, label: <a href="">vector</a>&lt;u8&gt;, owner: <b>address</b>, no_years: u64, secret: <a href="">vector</a>&lt;u8&gt;, <a href="resolver.md#0x0_resolver">resolver</a>: <b>address</b>, payment: &<b>mut</b> <a href="_Coin">coin::Coin</a>&lt;<a href="_SUI">sui::SUI</a>&gt;, referral_code: <a href="_Option">option::Option</a>&lt;<a href="_String">ascii::String</a>&gt;, discount_code: <a href="_Option">option::Option</a>&lt;<a href="_String">ascii::String</a>&gt;, signature: <a href="">vector</a>&lt;u8&gt;, hashed_msg: <a href="">vector</a>&lt;u8&gt;, raw_msg: <a href="">vector</a>&lt;u8&gt;, ctx: &<b>mut</b> <a href="_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="controller.md#0x0_controller_register_internal">register_internal</a>(
    <a href="controller.md#0x0_controller">controller</a>: &<b>mut</b> <a href="controller.md#0x0_controller_BaseController">BaseController</a>,
    registrar: &<b>mut</b> BaseRegistrar,
    registry: &<b>mut</b> Registry,
    config: &<b>mut</b> Configuration,
    <a href="auction.md#0x0_auction">auction</a>: &Auction,
    label: <a href="">vector</a>&lt;u8&gt;,
    owner: <b>address</b>,
    no_years: u64,
    secret: <a href="">vector</a>&lt;u8&gt;,
    <a href="resolver.md#0x0_resolver">resolver</a>: <b>address</b>,
    payment: &<b>mut</b> Coin&lt;SUI&gt;,
    referral_code: Option&lt;<a href="_String">ascii::String</a>&gt;,
    discount_code: Option&lt;<a href="_String">ascii::String</a>&gt;,
    signature: <a href="">vector</a>&lt;u8&gt;,
    hashed_msg: <a href="">vector</a>&lt;u8&gt;,
    raw_msg: <a href="">vector</a>&lt;u8&gt;,
    ctx: &<b>mut</b> TxContext,
) {
    <b>assert</b>!(<a href="configuration.md#0x0_configuration_is_enable_controller">configuration::is_enable_controller</a>(config), <a href="controller.md#0x0_controller_ERegistrationIsDisabled">ERegistrationIsDisabled</a>);
    <b>let</b> emoji_config = <a href="configuration.md#0x0_configuration_emoji_config">configuration::emoji_config</a>(config);
    <b>let</b> label_str = utf8(label);

    <b>if</b> (epoch(ctx) &lt;= <a href="auction.md#0x0_auction_auction_close_at">auction::auction_close_at</a>(<a href="auction.md#0x0_auction">auction</a>)) {
        // <a href="auction.md#0x0_auction">auction</a> time, cann't register short names
        validate_label_with_emoji(
            emoji_config,
            label,
            min_non_auction_domain_length(config),
            max_domain_length(config)
        )
    } <b>else</b> {
        <b>assert</b>!(<a href="auction.md#0x0_auction_is_auction_label_available_for_controller">auction::is_auction_label_available_for_controller</a>(<a href="auction.md#0x0_auction">auction</a>, label_str, ctx), <a href="controller.md#0x0_controller_ELabelUnAvailable">ELabelUnAvailable</a>);
        validate_label_with_emoji(emoji_config, label, min_domain_length(config), max_domain_length(config))
    };
    <b>let</b> commitment = <a href="controller.md#0x0_controller_make_commitment">make_commitment</a>(registrar, label, owner, secret);
    <a href="controller.md#0x0_controller_consume_commitment">consume_commitment</a>(<a href="controller.md#0x0_controller">controller</a>, registrar, label, commitment, ctx);

    <b>let</b> registration_fee = price_for_node(no_years);
    <b>assert</b>!(<a href="_value">coin::value</a>(payment) &gt;= registration_fee, <a href="controller.md#0x0_controller_ENotEnoughFee">ENotEnoughFee</a>);

    // can <b>apply</b> both discount and referral codes at the same time
    <b>if</b> (<a href="_is_some">option::is_some</a>(&discount_code)) {
        registration_fee =
            <a href="controller.md#0x0_controller_apply_discount_code">apply_discount_code</a>(config, registration_fee, <a href="_borrow">option::borrow</a>(&discount_code), ctx);
    };
    <b>if</b> (<a href="_is_some">option::is_some</a>(&referral_code)) {
        registration_fee =
            <a href="controller.md#0x0_controller_apply_referral_code">apply_referral_code</a>(config, payment, registration_fee, <a href="_borrow">option::borrow</a>(&referral_code), ctx);
    };

    <b>let</b> duration = no_years * 365;
    <b>let</b> (nft_id, <a href="">url</a>) = <a href="base_registrar.md#0x0_base_registrar_register_with_image">base_registrar::register_with_image</a>(
        registrar,
        registry,
        config,
        label,
        owner,
        duration,
        <a href="resolver.md#0x0_resolver">resolver</a>,
        signature,
        hashed_msg,
        raw_msg,
        ctx
    );
    <a href="coin_util.md#0x0_coin_util_user_transfer_to_contract">coin_util::user_transfer_to_contract</a>(payment, registration_fee, &<b>mut</b> <a href="controller.md#0x0_controller">controller</a>.<a href="">balance</a>);

    <a href="_emit">event::emit</a>(<a href="controller.md#0x0_controller_NameRegisteredEvent">NameRegisteredEvent</a> {
        node: <a href="base_registrar.md#0x0_base_registrar_base_node">base_registrar::base_node</a>(registrar),
        label: label_str,
        owner,
        cost: price_for_node(no_years),
        expiry: epoch(ctx) + duration,
        nft_id,
        <a href="resolver.md#0x0_resolver">resolver</a>,
        referral_code,
        discount_code,
        <a href="">url</a>,
    });
}
</code></pre>



</details>

<a name="0x0_controller_apply_referral_code"></a>

## Function `apply_referral_code`



<pre><code><b>fun</b> <a href="controller.md#0x0_controller_apply_referral_code">apply_referral_code</a>(config: &<a href="configuration.md#0x0_configuration_Configuration">configuration::Configuration</a>, payment: &<b>mut</b> <a href="_Coin">coin::Coin</a>&lt;<a href="_SUI">sui::SUI</a>&gt;, original_fee: u64, referral_code: &<a href="_String">ascii::String</a>, ctx: &<b>mut</b> <a href="_TxContext">tx_context::TxContext</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="controller.md#0x0_controller_apply_referral_code">apply_referral_code</a>(
    config: &Configuration,
    payment: &<b>mut</b> Coin&lt;SUI&gt;,
    original_fee: u64,
    referral_code: &<a href="_String">ascii::String</a>,
    ctx: &<b>mut</b> TxContext
): u64 {
    <b>let</b> (rate, partner) = <a href="configuration.md#0x0_configuration_use_referral_code">configuration::use_referral_code</a>(config, referral_code);
    <b>let</b> remaining_fee = (original_fee / 100) * (100 - rate <b>as</b> u64);
    <b>let</b> payback_amount = original_fee - remaining_fee;
    <a href="coin_util.md#0x0_coin_util_user_transfer_to_address">coin_util::user_transfer_to_address</a>(payment, payback_amount, partner, ctx);

    remaining_fee
}
</code></pre>



</details>

<a name="0x0_controller_apply_discount_code"></a>

## Function `apply_discount_code`



<pre><code><b>fun</b> <a href="controller.md#0x0_controller_apply_discount_code">apply_discount_code</a>(config: &<b>mut</b> <a href="configuration.md#0x0_configuration_Configuration">configuration::Configuration</a>, original_fee: u64, referral_code: &<a href="_String">ascii::String</a>, ctx: &<b>mut</b> <a href="_TxContext">tx_context::TxContext</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="controller.md#0x0_controller_apply_discount_code">apply_discount_code</a>(
    config: &<b>mut</b> Configuration,
    original_fee: u64,
    referral_code: &<a href="_String">ascii::String</a>,
    ctx: &<b>mut</b> TxContext,
): u64 {
    <b>let</b> rate = <a href="configuration.md#0x0_configuration_use_discount_code">configuration::use_discount_code</a>(config, referral_code, ctx);
    (original_fee / 100) * (100 - rate <b>as</b> u64)
}
</code></pre>



</details>

<a name="0x0_controller_remove_outdated_commitments"></a>

## Function `remove_outdated_commitments`



<pre><code><b>fun</b> <a href="controller.md#0x0_controller_remove_outdated_commitments">remove_outdated_commitments</a>(<a href="controller.md#0x0_controller">controller</a>: &<b>mut</b> <a href="controller.md#0x0_controller_BaseController">controller::BaseController</a>, ctx: &<b>mut</b> <a href="_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="controller.md#0x0_controller_remove_outdated_commitments">remove_outdated_commitments</a>(<a href="controller.md#0x0_controller">controller</a>: &<b>mut</b> <a href="controller.md#0x0_controller_BaseController">BaseController</a>, ctx: &<b>mut</b> TxContext) {
    <b>let</b> front_element = <a href="_front">linked_table::front</a>(&<a href="controller.md#0x0_controller">controller</a>.commitments);
    <b>let</b> i = 0;

    <b>while</b> (<a href="_is_some">option::is_some</a>(front_element) && i &lt; no_outdated_commitments_to_remove()) {
        i = i + 1;

        <b>let</b> created_at = <a href="_borrow">linked_table::borrow</a>(&<a href="controller.md#0x0_controller">controller</a>.commitments, *<a href="_borrow">option::borrow</a>(front_element));
        <b>if</b> (*created_at + max_commitment_age() &lt;= epoch(ctx)) {
            <a href="_pop_front">linked_table::pop_front</a>(&<b>mut</b> <a href="controller.md#0x0_controller">controller</a>.commitments);
            front_element = <a href="_front">linked_table::front</a>(&<a href="controller.md#0x0_controller">controller</a>.commitments);
        } <b>else</b> <b>break</b>;
    };
}
</code></pre>



</details>

<a name="0x0_controller_consume_commitment"></a>

## Function `consume_commitment`



<pre><code><b>fun</b> <a href="controller.md#0x0_controller_consume_commitment">consume_commitment</a>(<a href="controller.md#0x0_controller">controller</a>: &<b>mut</b> <a href="controller.md#0x0_controller_BaseController">controller::BaseController</a>, registrar: &<a href="base_registrar.md#0x0_base_registrar_BaseRegistrar">base_registrar::BaseRegistrar</a>, label: <a href="">vector</a>&lt;u8&gt;, commitment: <a href="">vector</a>&lt;u8&gt;, ctx: &<a href="_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="controller.md#0x0_controller_consume_commitment">consume_commitment</a>(
    <a href="controller.md#0x0_controller">controller</a>: &<b>mut</b> <a href="controller.md#0x0_controller_BaseController">BaseController</a>,
    registrar: &BaseRegistrar,
    label: <a href="">vector</a>&lt;u8&gt;,
    commitment: <a href="">vector</a>&lt;u8&gt;,
    ctx: &TxContext,
) {
    <b>assert</b>!(<a href="_contains">linked_table::contains</a>(&<a href="controller.md#0x0_controller">controller</a>.commitments, commitment), <a href="controller.md#0x0_controller_ECommitmentNotExists">ECommitmentNotExists</a>);
    // TODO: remove later when timestamp is introduced
    // <b>assert</b>!(
    //     *<a href="_get">vec_map::get</a>(&<a href="controller.md#0x0_controller">controller</a>.commitments, &commitment) + MIN_COMMITMENT_AGE &lt;= <a href="_epoch">tx_context::epoch</a>(ctx),
    //     <a href="controller.md#0x0_controller_ECommitmentNotValid">ECommitmentNotValid</a>
    // );
    <b>assert</b>!(
        *<a href="_borrow">linked_table::borrow</a>(&<a href="controller.md#0x0_controller">controller</a>.commitments, commitment) + <a href="configuration.md#0x0_configuration_max_commitment_age">configuration::max_commitment_age</a>() &gt; epoch(ctx),
        <a href="controller.md#0x0_controller_ECommitmentTooOld">ECommitmentTooOld</a>
    );
    <b>assert</b>!(<a href="base_registrar.md#0x0_base_registrar_is_available">base_registrar::is_available</a>(registrar, <a href="_utf8">string::utf8</a>(label), ctx), <a href="controller.md#0x0_controller_ELabelUnAvailable">ELabelUnAvailable</a>);
    <a href="_remove">linked_table::remove</a>(&<b>mut</b> <a href="controller.md#0x0_controller">controller</a>.commitments, commitment);
}
</code></pre>



</details>

<a name="0x0_controller_make_commitment"></a>

## Function `make_commitment`



<pre><code><b>fun</b> <a href="controller.md#0x0_controller_make_commitment">make_commitment</a>(registrar: &<a href="base_registrar.md#0x0_base_registrar_BaseRegistrar">base_registrar::BaseRegistrar</a>, label: <a href="">vector</a>&lt;u8&gt;, owner: <b>address</b>, secret: <a href="">vector</a>&lt;u8&gt;): <a href="">vector</a>&lt;u8&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="controller.md#0x0_controller_make_commitment">make_commitment</a>(registrar: &BaseRegistrar, label: <a href="">vector</a>&lt;u8&gt;, owner: <b>address</b>, secret: <a href="">vector</a>&lt;u8&gt;): <a href="">vector</a>&lt;u8&gt; {
    <b>let</b> node = label;
    <a href="_append">vector::append</a>(&<b>mut</b> node, b".");
    <a href="_append">vector::append</a>(&<b>mut</b> node, <a href="base_registrar.md#0x0_base_registrar_base_node_bytes">base_registrar::base_node_bytes</a>(registrar));

    <b>let</b> owner_bytes = <a href="_to_bytes">bcs::to_bytes</a>(&owner);
    <a href="_append">vector::append</a>(&<b>mut</b> node, owner_bytes);
    <a href="_append">vector::append</a>(&<b>mut</b> node, secret);
    keccak256(&node)
}
</code></pre>



</details>

<a name="0x0_controller_validate_codes"></a>

## Function `validate_codes`



<pre><code><b>fun</b> <a href="controller.md#0x0_controller_validate_codes">validate_codes</a>(referral_code: <a href="">vector</a>&lt;u8&gt;, discount_code: <a href="">vector</a>&lt;u8&gt;): (<a href="_Option">option::Option</a>&lt;<a href="_String">ascii::String</a>&gt;, <a href="_Option">option::Option</a>&lt;<a href="_String">ascii::String</a>&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="controller.md#0x0_controller_validate_codes">validate_codes</a>(
    referral_code: <a href="">vector</a>&lt;u8&gt;,
    discount_code: <a href="">vector</a>&lt;u8&gt;
): (Option&lt;<a href="_String">ascii::String</a>&gt;, Option&lt;<a href="_String">ascii::String</a>&gt;) {
    <b>let</b> referral_len = <a href="_length">vector::length</a>(&referral_code);
    <b>let</b> discount_len = <a href="_length">vector::length</a>(&discount_code);
    // doesn't have a format for codes right now, so any non-empty code is considered valid
    <b>assert</b>!(referral_len &gt; 0 || discount_len &gt; 0, <a href="controller.md#0x0_controller_EInvalidCode">EInvalidCode</a>);

    <b>let</b> referral = <a href="_none">option::none</a>();
    <b>let</b> discount = <a href="_none">option::none</a>();
    <b>if</b> (referral_len &gt; 0) referral = <a href="_some">option::some</a>(<a href="_string">ascii::string</a>(referral_code));
    <b>if</b> (discount_len &gt; 0) discount = <a href="_some">option::some</a>(<a href="_string">ascii::string</a>(discount_code));

    (referral, discount)
}
</code></pre>



</details>

<a name="0x0_controller_init"></a>

## Function `init`



<pre><code><b>fun</b> <a href="controller.md#0x0_controller_init">init</a>(ctx: &<b>mut</b> <a href="_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="controller.md#0x0_controller_init">init</a>(ctx: &<b>mut</b> TxContext) {
    <a href="_share_object">transfer::share_object</a>(<a href="controller.md#0x0_controller_BaseController">BaseController</a> {
        id: <a href="_new">object::new</a>(ctx),
        commitments: <a href="_new">linked_table::new</a>(ctx),
        <a href="">balance</a>: <a href="_zero">balance::zero</a>(),
        // cannot get the ID of name_resolver in `init`, admin need <b>to</b> <b>update</b> this by calling `set_default_resolver`
        default_addr_resolver: @0x0,
    });
}
</code></pre>



</details>
