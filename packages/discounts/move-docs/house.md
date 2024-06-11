
<a name="0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_house"></a>

# Module `0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d::house`

A base module that holds a shared object for the configuration of the package
and exports some package utilities for the 2 systems to use.


-  [Struct `DiscountHouseApp`](#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_house_DiscountHouseApp)
-  [Resource `DiscountHouse`](#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_house_DiscountHouse)
-  [Constants](#@Constants_0)
-  [Function `init`](#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_house_init)
-  [Function `set_version`](#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_house_set_version)
-  [Function `assert_version_is_valid`](#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_house_assert_version_is_valid)
-  [Function `friend_add_registry_entry`](#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_house_friend_add_registry_entry)
-  [Function `uid_mut`](#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_house_uid_mut)
-  [Function `suins_app_auth`](#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_house_suins_app_auth)


<pre><code><b>use</b> <a href="dependencies/sui-framework/clock.md#0x2_clock">0x2::clock</a>;
<b>use</b> <a href="dependencies/sui-framework/object.md#0x2_object">0x2::object</a>;
<b>use</b> <a href="dependencies/sui-framework/transfer.md#0x2_transfer">0x2::transfer</a>;
<b>use</b> <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context">0x2::tx_context</a>;
<b>use</b> <a href="dependencies/suins/config.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_config">0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b::config</a>;
<b>use</b> <a href="dependencies/suins/domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b::domain</a>;
<b>use</b> <a href="dependencies/suins/registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry">0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b::registry</a>;
<b>use</b> <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b::suins</a>;
<b>use</b> <a href="dependencies/suins/suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration">0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b::suins_registration</a>;
</code></pre>



<a name="0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_house_DiscountHouseApp"></a>

## Struct `DiscountHouseApp`

A key to authorize DiscountHouse to register names on SuiNS.


<pre><code><b>struct</b> <a href="house.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_house_DiscountHouseApp">DiscountHouseApp</a> <b>has</b> drop
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

<a name="0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_house_DiscountHouse"></a>

## Resource `DiscountHouse`



<pre><code><b>struct</b> <a href="house.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_house_DiscountHouse">DiscountHouse</a> <b>has</b> store, key
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
<code>version: u8</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="@Constants_0"></a>

## Constants


<a name="0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_house_ENotValidVersion"></a>

Tries to register with invalid version of the app


<pre><code><b>const</b> <a href="house.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_house_ENotValidVersion">ENotValidVersion</a>: u64 = 1;
</code></pre>



<a name="0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_house_REGISTRATION_YEARS"></a>

All promotions in this package are valid only for 1 year


<pre><code><b>const</b> <a href="house.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_house_REGISTRATION_YEARS">REGISTRATION_YEARS</a>: u8 = 1;
</code></pre>



<a name="0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_house_VERSION"></a>

A version handler that allows us to upgrade the app in the future.


<pre><code><b>const</b> <a href="house.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_house_VERSION">VERSION</a>: u8 = 1;
</code></pre>



<a name="0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_house_init"></a>

## Function `init`

Share the house.
This will hold DFs with the configuration for different types.


<pre><code><b>fun</b> <a href="house.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_house_init">init</a>(ctx: &<b>mut</b> <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="house.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_house_init">init</a>(ctx: &<b>mut</b> TxContext){
    <a href="dependencies/sui-framework/transfer.md#0x2_transfer_public_share_object">transfer::public_share_object</a>(<a href="house.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_house_DiscountHouse">DiscountHouse</a> {
        id: <a href="dependencies/sui-framework/object.md#0x2_object_new">object::new</a>(ctx),
        version: <a href="house.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_house_VERSION">VERSION</a>
    })
}
</code></pre>



</details>

<a name="0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_house_set_version"></a>

## Function `set_version`

An admin helper to set the version of the shared object.
Registrations are only possible if the latest version is being used.


<pre><code><b>public</b> <b>fun</b> <a href="house.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_house_set_version">set_version</a>(_: &<a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_AdminCap">suins::AdminCap</a>, self: &<b>mut</b> <a href="house.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_house_DiscountHouse">house::DiscountHouse</a>, version: u8)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="house.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_house_set_version">set_version</a>(_: &AdminCap, self: &<b>mut</b> <a href="house.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_house_DiscountHouse">DiscountHouse</a>, version: u8) {
    self.version = version;
}
</code></pre>



</details>

<a name="0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_house_assert_version_is_valid"></a>

## Function `assert_version_is_valid`

Validate that the version of the app is the latest.


<pre><code><b>public</b> <b>fun</b> <a href="house.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_house_assert_version_is_valid">assert_version_is_valid</a>(self: &<a href="house.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_house_DiscountHouse">house::DiscountHouse</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="house.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_house_assert_version_is_valid">assert_version_is_valid</a>(self: &<a href="house.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_house_DiscountHouse">DiscountHouse</a>) {
    <b>assert</b>!(self.version == <a href="house.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_house_VERSION">VERSION</a>, <a href="house.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_house_ENotValidVersion">ENotValidVersion</a>);
}
</code></pre>



</details>

<a name="0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_house_friend_add_registry_entry"></a>

## Function `friend_add_registry_entry`

A function to save a new SuiNS name in the registry.
Helps re-use the same code for all discounts based on type T of the package.


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="house.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_house_friend_add_registry_entry">friend_add_registry_entry</a>(<a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>: &<b>mut</b> <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_SuiNS">suins::SuiNS</a>, <a href="dependencies/suins/domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>: <a href="dependencies/suins/domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain_Domain">domain::Domain</a>, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &<a href="dependencies/sui-framework/clock.md#0x2_clock_Clock">clock::Clock</a>, ctx: &<b>mut</b> <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context_TxContext">tx_context::TxContext</a>): <a href="dependencies/suins/suins_registration.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_registration_SuinsRegistration">suins_registration::SuinsRegistration</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<a href="dependencies/sui-framework/package.md#0x2_package">package</a>) <b>fun</b> <a href="house.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_house_friend_add_registry_entry">friend_add_registry_entry</a>(
    <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>: &<b>mut</b> SuiNS,
    <a href="dependencies/suins/domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>: Domain,
    <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &Clock,
    ctx: &<b>mut</b> TxContext
): SuinsRegistration {
    // Verify that app is authorized <b>to</b> register names.
    <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>.assert_app_is_authorized&lt;<a href="house.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_house_DiscountHouseApp">DiscountHouseApp</a>&gt;();

    // Validate that the name can be registered.
    <a href="dependencies/suins/config.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_config_assert_valid_user_registerable_domain">config::assert_valid_user_registerable_domain</a>(&<a href="dependencies/suins/domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>);

    <b>let</b> <a href="dependencies/suins/registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry">registry</a> = <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins_app_registry_mut">suins::app_registry_mut</a>&lt;<a href="house.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_house_DiscountHouseApp">DiscountHouseApp</a>, Registry&gt;(<a href="house.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_house_DiscountHouseApp">DiscountHouseApp</a> {}, <a href="dependencies/suins/suins.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_suins">suins</a>);
    <a href="dependencies/suins/registry.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_registry">registry</a>.add_record(<a href="dependencies/suins/domain.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_domain">domain</a>, <a href="house.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_house_REGISTRATION_YEARS">REGISTRATION_YEARS</a>, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>, ctx)
}
</code></pre>



</details>

<a name="0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_house_uid_mut"></a>

## Function `uid_mut`

Returns the UID of the shared object so we can add custom configuration.
from different modules we have. but keep using the same shared object.


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="house.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_house_uid_mut">uid_mut</a>(self: &<b>mut</b> <a href="house.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_house_DiscountHouse">house::DiscountHouse</a>): &<b>mut</b> <a href="dependencies/sui-framework/object.md#0x2_object_UID">object::UID</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<a href="dependencies/sui-framework/package.md#0x2_package">package</a>) <b>fun</b> <a href="house.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_house_uid_mut">uid_mut</a>(self: &<b>mut</b> <a href="house.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_house_DiscountHouse">DiscountHouse</a>): &<b>mut</b> UID {
    &<b>mut</b> self.id
}
</code></pre>



</details>

<a name="0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_house_suins_app_auth"></a>

## Function `suins_app_auth`

Allows the friend modules to call functions to the SuiNS registry.


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="house.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_house_suins_app_auth">suins_app_auth</a>(): <a href="house.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_house_DiscountHouseApp">house::DiscountHouseApp</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<a href="dependencies/sui-framework/package.md#0x2_package">package</a>) <b>fun</b> <a href="house.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_house_suins_app_auth">suins_app_auth</a>(): <a href="house.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_house_DiscountHouseApp">DiscountHouseApp</a> {
    <a href="house.md#0x81ea63a946e5e8ca433b554f9b7f1fbe4ca1bd5b5d2b040bae42c3fcb73ceb2d_house_DiscountHouseApp">DiscountHouseApp</a> {}
}
</code></pre>



</details>
