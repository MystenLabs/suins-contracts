
<a name="0x0_configuration"></a>

# Module `0x0::configuration`



-  [Struct `NetworkFirstDayChangedEvent`](#0x0_configuration_NetworkFirstDayChangedEvent)
-  [Struct `ReferralCodeAddedEvent`](#0x0_configuration_ReferralCodeAddedEvent)
-  [Struct `DiscountCodeAddedEvent`](#0x0_configuration_DiscountCodeAddedEvent)
-  [Struct `ReserveDomainAddedEvent`](#0x0_configuration_ReserveDomainAddedEvent)
-  [Struct `ReferralCodeRemovedEvent`](#0x0_configuration_ReferralCodeRemovedEvent)
-  [Struct `DiscountCodeRemovedEvent`](#0x0_configuration_DiscountCodeRemovedEvent)
-  [Struct `ReferralValue`](#0x0_configuration_ReferralValue)
-  [Struct `DiscountValue`](#0x0_configuration_DiscountValue)
-  [Resource `Configuration`](#0x0_configuration_Configuration)
-  [Constants](#@Constants_0)
-  [Function `set_public_key`](#0x0_configuration_set_public_key)
-  [Function `new_reserve_domains`](#0x0_configuration_new_reserve_domains)
-  [Function `remove_reserve_domains`](#0x0_configuration_remove_reserve_domains)
-  [Function `new_referral_code`](#0x0_configuration_new_referral_code)
-  [Function `remove_referral_code`](#0x0_configuration_remove_referral_code)
-  [Function `new_discount_code`](#0x0_configuration_new_discount_code)
-  [Function `new_discount_code_batch`](#0x0_configuration_new_discount_code_batch)
-  [Function `remove_discount_code`](#0x0_configuration_remove_discount_code)
-  [Function `remove_discount_code_batch`](#0x0_configuration_remove_discount_code_batch)
-  [Function `use_discount_code`](#0x0_configuration_use_discount_code)
-  [Function `use_referral_code`](#0x0_configuration_use_referral_code)
-  [Function `emoji_config`](#0x0_configuration_emoji_config)
-  [Function `public_key`](#0x0_configuration_public_key)
-  [Function `init`](#0x0_configuration_init)


<pre><code><b>use</b> <a href="base_registry.md#0x0_base_registry">0x0::base_registry</a>;
<b>use</b> <a href="converter.md#0x0_converter">0x0::converter</a>;
<b>use</b> <a href="emoji.md#0x0_emoji">0x0::emoji</a>;
<b>use</b> <a href="remove_later.md#0x0_remove_later">0x0::remove_later</a>;
<b>use</b> <a href="">0x1::ascii</a>;
<b>use</b> <a href="">0x1::string</a>;
<b>use</b> <a href="">0x2::dynamic_field</a>;
<b>use</b> <a href="">0x2::event</a>;
<b>use</b> <a href="">0x2::object</a>;
<b>use</b> <a href="">0x2::transfer</a>;
<b>use</b> <a href="">0x2::tx_context</a>;
<b>use</b> <a href="">0x2::vec_map</a>;
</code></pre>



<a name="0x0_configuration_NetworkFirstDayChangedEvent"></a>

## Struct `NetworkFirstDayChangedEvent`



<pre><code><b>struct</b> <a href="configuration.md#0x0_configuration_NetworkFirstDayChangedEvent">NetworkFirstDayChangedEvent</a> <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>new_day: u64</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0x0_configuration_ReferralCodeAddedEvent"></a>

## Struct `ReferralCodeAddedEvent`



<pre><code><b>struct</b> <a href="configuration.md#0x0_configuration_ReferralCodeAddedEvent">ReferralCodeAddedEvent</a> <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>code: <a href="_String">ascii::String</a></code>
</dt>
<dd>

</dd>
<dt>
<code>rate: u8</code>
</dt>
<dd>

</dd>
<dt>
<code>partner: <b>address</b></code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0x0_configuration_DiscountCodeAddedEvent"></a>

## Struct `DiscountCodeAddedEvent`



<pre><code><b>struct</b> <a href="configuration.md#0x0_configuration_DiscountCodeAddedEvent">DiscountCodeAddedEvent</a> <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>code: <a href="_String">ascii::String</a></code>
</dt>
<dd>

</dd>
<dt>
<code>rate: u8</code>
</dt>
<dd>

</dd>
<dt>
<code>owner: <a href="_String">ascii::String</a></code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0x0_configuration_ReserveDomainAddedEvent"></a>

## Struct `ReserveDomainAddedEvent`



<pre><code><b>struct</b> <a href="configuration.md#0x0_configuration_ReserveDomainAddedEvent">ReserveDomainAddedEvent</a> <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>domain: <a href="_String">string::String</a></code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0x0_configuration_ReferralCodeRemovedEvent"></a>

## Struct `ReferralCodeRemovedEvent`



<pre><code><b>struct</b> <a href="configuration.md#0x0_configuration_ReferralCodeRemovedEvent">ReferralCodeRemovedEvent</a> <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>code: <a href="_String">ascii::String</a></code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0x0_configuration_DiscountCodeRemovedEvent"></a>

## Struct `DiscountCodeRemovedEvent`



<pre><code><b>struct</b> <a href="configuration.md#0x0_configuration_DiscountCodeRemovedEvent">DiscountCodeRemovedEvent</a> <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>code: <a href="_String">ascii::String</a></code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0x0_configuration_ReferralValue"></a>

## Struct `ReferralValue`



<pre><code><b>struct</b> <a href="configuration.md#0x0_configuration_ReferralValue">ReferralValue</a> <b>has</b> drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>rate: u8</code>
</dt>
<dd>

</dd>
<dt>
<code>partner: <b>address</b></code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0x0_configuration_DiscountValue"></a>

## Struct `DiscountValue`



<pre><code><b>struct</b> <a href="configuration.md#0x0_configuration_DiscountValue">DiscountValue</a> <b>has</b> drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>rate: u8</code>
</dt>
<dd>

</dd>
<dt>
<code>owner: <a href="_String">ascii::String</a></code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0x0_configuration_Configuration"></a>

## Resource `Configuration`

This share object is the parent of reverse_domains
The keys of dynamic child objects may or may not contain TLD.
If it doesn't, it means we reserve both .sui and .move


<pre><code><b>struct</b> <a href="configuration.md#0x0_configuration_Configuration">Configuration</a> <b>has</b> key
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
<code>referral_codes: <a href="_VecMap">vec_map::VecMap</a>&lt;<a href="_String">ascii::String</a>, <a href="configuration.md#0x0_configuration_ReferralValue">configuration::ReferralValue</a>&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>discount_codes: <a href="_VecMap">vec_map::VecMap</a>&lt;<a href="_String">ascii::String</a>, <a href="configuration.md#0x0_configuration_DiscountValue">configuration::DiscountValue</a>&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>emoji_config: <a href="emoji.md#0x0_emoji_EmojiConfiguration">emoji::EmojiConfiguration</a></code>
</dt>
<dd>

</dd>
<dt>
<code>public_key: <a href="">vector</a>&lt;u8&gt;</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="@Constants_0"></a>

## Constants


<a name="0x0_configuration_EDiscountCodeNotExists"></a>



<pre><code><b>const</b> <a href="configuration.md#0x0_configuration_EDiscountCodeNotExists">EDiscountCodeNotExists</a>: u64 = 405;
</code></pre>



<a name="0x0_configuration_EInvalidDiscountCode"></a>



<pre><code><b>const</b> <a href="configuration.md#0x0_configuration_EInvalidDiscountCode">EInvalidDiscountCode</a>: u64 = 403;
</code></pre>



<a name="0x0_configuration_EInvalidRate"></a>



<pre><code><b>const</b> <a href="configuration.md#0x0_configuration_EInvalidRate">EInvalidRate</a>: u64 = 401;
</code></pre>



<a name="0x0_configuration_EInvalidReferralCode"></a>



<pre><code><b>const</b> <a href="configuration.md#0x0_configuration_EInvalidReferralCode">EInvalidReferralCode</a>: u64 = 402;
</code></pre>



<a name="0x0_configuration_EOwnerUnauthorized"></a>



<pre><code><b>const</b> <a href="configuration.md#0x0_configuration_EOwnerUnauthorized">EOwnerUnauthorized</a>: u64 = 404;
</code></pre>



<a name="0x0_configuration_EReferralCodeNotExists"></a>



<pre><code><b>const</b> <a href="configuration.md#0x0_configuration_EReferralCodeNotExists">EReferralCodeNotExists</a>: u64 = 406;
</code></pre>



<a name="0x0_configuration_EmojiConfig"></a>



<pre><code><b>const</b> <a href="configuration.md#0x0_configuration_EmojiConfig">EmojiConfig</a>: <a href="">vector</a>&lt;u8&gt; = [101, 109, 111, 106, 105, 95, 99, 111, 110, 102, 105, 103];
</code></pre>



<a name="0x0_configuration_set_public_key"></a>

## Function `set_public_key`



<pre><code><b>public</b> entry <b>fun</b> <a href="configuration.md#0x0_configuration_set_public_key">set_public_key</a>(_: &<a href="base_registry.md#0x0_base_registry_AdminCap">base_registry::AdminCap</a>, config: &<b>mut</b> <a href="configuration.md#0x0_configuration_Configuration">configuration::Configuration</a>, new_public_key: <a href="">vector</a>&lt;u8&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="configuration.md#0x0_configuration_set_public_key">set_public_key</a>(_: &AdminCap, config: &<b>mut</b> <a href="configuration.md#0x0_configuration_Configuration">Configuration</a>, new_public_key: <a href="">vector</a>&lt;u8&gt;) {
    config.public_key = new_public_key
}
</code></pre>



</details>

<a name="0x0_configuration_new_reserve_domains"></a>

## Function `new_reserve_domains`



<pre><code><b>public</b> entry <b>fun</b> <a href="configuration.md#0x0_configuration_new_reserve_domains">new_reserve_domains</a>(_: &<a href="base_registry.md#0x0_base_registry_AdminCap">base_registry::AdminCap</a>, config: &<b>mut</b> <a href="configuration.md#0x0_configuration_Configuration">configuration::Configuration</a>, domains: <a href="">vector</a>&lt;u8&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="configuration.md#0x0_configuration_new_reserve_domains">new_reserve_domains</a>(_: &AdminCap, config: &<b>mut</b> <a href="configuration.md#0x0_configuration_Configuration">Configuration</a>, domains: <a href="">vector</a>&lt;u8&gt;) {
    <b>let</b> domains = <a href="remove_later.md#0x0_remove_later_deserialize_reserve_domains">remove_later::deserialize_reserve_domains</a>(domains);
    <b>let</b> len = <a href="_length">vector::length</a>(&domains);
    <b>let</b> index = 0;

    <b>while</b> (index &lt; len) {
        <b>let</b> domain = <a href="_borrow">vector::borrow</a>(&domains, index);
        // TODO: validate or not?
        <b>if</b> (!field::exists_with_type&lt;String, bool&gt;(&config.id, *domain)) {
            field::add(&<b>mut</b> config.id, *domain, <b>true</b>);
        };
        <a href="_emit">event::emit</a>(<a href="configuration.md#0x0_configuration_ReserveDomainAddedEvent">ReserveDomainAddedEvent</a> { domain: *domain });
        index = index + 1;
    };
}
</code></pre>



</details>

<a name="0x0_configuration_remove_reserve_domains"></a>

## Function `remove_reserve_domains`



<pre><code><b>public</b> entry <b>fun</b> <a href="configuration.md#0x0_configuration_remove_reserve_domains">remove_reserve_domains</a>(_: &<a href="base_registry.md#0x0_base_registry_AdminCap">base_registry::AdminCap</a>, config: &<b>mut</b> <a href="configuration.md#0x0_configuration_Configuration">configuration::Configuration</a>, domains: <a href="">vector</a>&lt;u8&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="configuration.md#0x0_configuration_remove_reserve_domains">remove_reserve_domains</a>(_: &AdminCap, config: &<b>mut</b> <a href="configuration.md#0x0_configuration_Configuration">Configuration</a>, domains: <a href="">vector</a>&lt;u8&gt;) {
    <b>let</b> domains = <a href="remove_later.md#0x0_remove_later_deserialize_reserve_domains">remove_later::deserialize_reserve_domains</a>(domains);
    <b>let</b> len = <a href="_length">vector::length</a>(&domains);
    <b>let</b> index = 0;

    <b>while</b> (index &lt; len) {
        <b>let</b> domain = <a href="_borrow">vector::borrow</a>(&domains, index);
        <b>if</b> (field::exists_with_type&lt;String, bool&gt;(&config.id, *domain)) {
            field::remove&lt;String, bool&gt;(&<b>mut</b> config.id, *domain);
        };
        <a href="_emit">event::emit</a>(<a href="configuration.md#0x0_configuration_ReserveDomainAddedEvent">ReserveDomainAddedEvent</a> { domain: *domain });
        index = index + 1;
    };
}
</code></pre>



</details>

<a name="0x0_configuration_new_referral_code"></a>

## Function `new_referral_code`



<pre><code><b>public</b> entry <b>fun</b> <a href="configuration.md#0x0_configuration_new_referral_code">new_referral_code</a>(_: &<a href="base_registry.md#0x0_base_registry_AdminCap">base_registry::AdminCap</a>, config: &<b>mut</b> <a href="configuration.md#0x0_configuration_Configuration">configuration::Configuration</a>, code: <a href="">vector</a>&lt;u8&gt;, rate: u8, partner: <b>address</b>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="configuration.md#0x0_configuration_new_referral_code">new_referral_code</a>(_: &AdminCap, config: &<b>mut</b> <a href="configuration.md#0x0_configuration_Configuration">Configuration</a>, code: <a href="">vector</a>&lt;u8&gt;, rate: u8, partner: <b>address</b>) {
    <b>assert</b>!(0 &lt; rate && rate &lt;= 100, <a href="configuration.md#0x0_configuration_EInvalidRate">EInvalidRate</a>);
    <b>let</b> code = <a href="_string">ascii::string</a>(code);
    <b>assert</b>!(<a href="_all_characters_printable">ascii::all_characters_printable</a>(&code), <a href="configuration.md#0x0_configuration_EInvalidReferralCode">EInvalidReferralCode</a>);

    <b>let</b> new_value = <a href="configuration.md#0x0_configuration_ReferralValue">ReferralValue</a> { rate, partner };
    <b>if</b> (<a href="_contains">vec_map::contains</a>(&config.referral_codes, &code)) {
        <b>let</b> current_value = <a href="_get_mut">vec_map::get_mut</a>(&<b>mut</b> config.referral_codes, &code);
        *current_value = new_value;
    } <b>else</b> {
        <a href="_insert">vec_map::insert</a>(&<b>mut</b> config.referral_codes, code, new_value);
    };
    <a href="_emit">event::emit</a>(<a href="configuration.md#0x0_configuration_ReferralCodeAddedEvent">ReferralCodeAddedEvent</a> { code, rate, partner })
}
</code></pre>



</details>

<a name="0x0_configuration_remove_referral_code"></a>

## Function `remove_referral_code`



<pre><code><b>public</b> entry <b>fun</b> <a href="configuration.md#0x0_configuration_remove_referral_code">remove_referral_code</a>(_: &<a href="base_registry.md#0x0_base_registry_AdminCap">base_registry::AdminCap</a>, config: &<b>mut</b> <a href="configuration.md#0x0_configuration_Configuration">configuration::Configuration</a>, code: <a href="">vector</a>&lt;u8&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="configuration.md#0x0_configuration_remove_referral_code">remove_referral_code</a>(_: &AdminCap, config: &<b>mut</b> <a href="configuration.md#0x0_configuration_Configuration">Configuration</a>, code: <a href="">vector</a>&lt;u8&gt;) {
    <b>let</b> code = <a href="_string">ascii::string</a>(code);
    <a href="_remove">vec_map::remove</a>(&<b>mut</b> config.referral_codes, &code);
    <a href="_emit">event::emit</a>(<a href="configuration.md#0x0_configuration_ReferralCodeRemovedEvent">ReferralCodeRemovedEvent</a> { code })
}
</code></pre>



</details>

<a name="0x0_configuration_new_discount_code"></a>

## Function `new_discount_code`



<pre><code><b>public</b> entry <b>fun</b> <a href="configuration.md#0x0_configuration_new_discount_code">new_discount_code</a>(_: &<a href="base_registry.md#0x0_base_registry_AdminCap">base_registry::AdminCap</a>, config: &<b>mut</b> <a href="configuration.md#0x0_configuration_Configuration">configuration::Configuration</a>, code: <a href="">vector</a>&lt;u8&gt;, rate: u8, owner: <b>address</b>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="configuration.md#0x0_configuration_new_discount_code">new_discount_code</a>(_: &AdminCap, config: &<b>mut</b> <a href="configuration.md#0x0_configuration_Configuration">Configuration</a>, code: <a href="">vector</a>&lt;u8&gt;, rate: u8, owner: <b>address</b>) {
    <b>assert</b>!(0 &lt; rate && rate &lt;= 100, <a href="configuration.md#0x0_configuration_EInvalidRate">EInvalidRate</a>);
    <b>let</b> code = <a href="_string">ascii::string</a>(code);
    <b>assert</b>!(<a href="_all_characters_printable">ascii::all_characters_printable</a>(&code), <a href="configuration.md#0x0_configuration_EInvalidDiscountCode">EInvalidDiscountCode</a>);

    <b>let</b> owner = <a href="_string">ascii::string</a>(<a href="converter.md#0x0_converter_address_to_string">converter::address_to_string</a>(owner));
    <b>let</b> new_value = <a href="configuration.md#0x0_configuration_DiscountValue">DiscountValue</a> { rate, owner };
    <b>if</b> (<a href="_contains">vec_map::contains</a>(&config.discount_codes, &code)) {
        <b>let</b> current_value = <a href="_get_mut">vec_map::get_mut</a>(&<b>mut</b> config.discount_codes, &code);
        *current_value = new_value;
    } <b>else</b> {
        <a href="_insert">vec_map::insert</a>(&<b>mut</b> config.discount_codes, code, new_value);
    };
    <a href="_emit">event::emit</a>(<a href="configuration.md#0x0_configuration_DiscountCodeAddedEvent">DiscountCodeAddedEvent</a> { code, rate, owner })
}
</code></pre>



</details>

<a name="0x0_configuration_new_discount_code_batch"></a>

## Function `new_discount_code_batch`



<pre><code><b>public</b> entry <b>fun</b> <a href="configuration.md#0x0_configuration_new_discount_code_batch">new_discount_code_batch</a>(_: &<a href="base_registry.md#0x0_base_registry_AdminCap">base_registry::AdminCap</a>, config: &<b>mut</b> <a href="configuration.md#0x0_configuration_Configuration">configuration::Configuration</a>, code_batch: <a href="">vector</a>&lt;u8&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="configuration.md#0x0_configuration_new_discount_code_batch">new_discount_code_batch</a>(_: &AdminCap, config: &<b>mut</b> <a href="configuration.md#0x0_configuration_Configuration">Configuration</a>, code_batch: <a href="">vector</a>&lt;u8&gt;) {
    <b>let</b> discount_codes = <a href="remove_later.md#0x0_remove_later_deserialize_new_discount_code_batch">remove_later::deserialize_new_discount_code_batch</a>(code_batch);
    <b>let</b> len = <a href="_length">vector::length</a>(&discount_codes);
    <b>let</b> index = 0;

    <b>while</b>(index &lt; len) {
        <b>let</b> discount_code = <a href="_borrow">vector::borrow</a>(&discount_codes, index);
        <b>let</b> (code, rate, owner) = <a href="remove_later.md#0x0_remove_later_get_discount_fields">remove_later::get_discount_fields</a>(discount_code);
        <b>let</b> new_value = <a href="configuration.md#0x0_configuration_DiscountValue">DiscountValue</a> { rate, owner };

        <b>if</b> (<a href="_contains">vec_map::contains</a>(&config.discount_codes, &code)) {
            <b>let</b> current_value = <a href="_get_mut">vec_map::get_mut</a>(&<b>mut</b> config.discount_codes, &code);
            *current_value = new_value;
        } <b>else</b> {
            <a href="_insert">vec_map::insert</a>(&<b>mut</b> config.discount_codes, code, new_value);
        };
        <a href="_emit">event::emit</a>(<a href="configuration.md#0x0_configuration_DiscountCodeAddedEvent">DiscountCodeAddedEvent</a> { code, rate, owner });
        index = index + 1;
    };
}
</code></pre>



</details>

<a name="0x0_configuration_remove_discount_code"></a>

## Function `remove_discount_code`



<pre><code><b>public</b> entry <b>fun</b> <a href="configuration.md#0x0_configuration_remove_discount_code">remove_discount_code</a>(_: &<a href="base_registry.md#0x0_base_registry_AdminCap">base_registry::AdminCap</a>, config: &<b>mut</b> <a href="configuration.md#0x0_configuration_Configuration">configuration::Configuration</a>, code: <a href="">vector</a>&lt;u8&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="configuration.md#0x0_configuration_remove_discount_code">remove_discount_code</a>(_: &AdminCap, config: &<b>mut</b> <a href="configuration.md#0x0_configuration_Configuration">Configuration</a>, code: <a href="">vector</a>&lt;u8&gt;) {
    <b>let</b> code = <a href="_string">ascii::string</a>(code);
    <a href="_remove">vec_map::remove</a>(&<b>mut</b> config.discount_codes, &code);
    <a href="_emit">event::emit</a>(<a href="configuration.md#0x0_configuration_DiscountCodeRemovedEvent">DiscountCodeRemovedEvent</a> { code })
}
</code></pre>



</details>

<a name="0x0_configuration_remove_discount_code_batch"></a>

## Function `remove_discount_code_batch`



<pre><code><b>public</b> entry <b>fun</b> <a href="configuration.md#0x0_configuration_remove_discount_code_batch">remove_discount_code_batch</a>(_: &<a href="base_registry.md#0x0_base_registry_AdminCap">base_registry::AdminCap</a>, config: &<b>mut</b> <a href="configuration.md#0x0_configuration_Configuration">configuration::Configuration</a>, code_batch: <a href="">vector</a>&lt;u8&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="configuration.md#0x0_configuration_remove_discount_code_batch">remove_discount_code_batch</a>(_: &AdminCap, config: &<b>mut</b> <a href="configuration.md#0x0_configuration_Configuration">Configuration</a>, code_batch: <a href="">vector</a>&lt;u8&gt;) {
    <b>let</b> codes = <a href="remove_later.md#0x0_remove_later_deserialize_remove_discount_code_batch">remove_later::deserialize_remove_discount_code_batch</a>(code_batch);
    <b>let</b> len = <a href="_length">vector::length</a>(&codes);
    <b>let</b> index = 0;

    <b>while</b>(index &lt; len) {
        <b>let</b> code = <a href="_borrow">vector::borrow</a>(&codes, index);
        <a href="_remove">vec_map::remove</a>(&<b>mut</b> config.discount_codes, code);
        <a href="_emit">event::emit</a>(<a href="configuration.md#0x0_configuration_DiscountCodeRemovedEvent">DiscountCodeRemovedEvent</a> { code: *code });
        index = index + 1;
    };
}
</code></pre>



</details>

<a name="0x0_configuration_use_discount_code"></a>

## Function `use_discount_code`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="configuration.md#0x0_configuration_use_discount_code">use_discount_code</a>(config: &<b>mut</b> <a href="configuration.md#0x0_configuration_Configuration">configuration::Configuration</a>, code: &<a href="_String">ascii::String</a>, ctx: &<a href="_TxContext">tx_context::TxContext</a>): u8
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="configuration.md#0x0_configuration_use_discount_code">use_discount_code</a>(config: &<b>mut</b> <a href="configuration.md#0x0_configuration_Configuration">Configuration</a>, code: &<a href="_String">ascii::String</a>, ctx: &TxContext): u8 {
    <b>assert</b>!(<a href="_contains">vec_map::contains</a>(&config.discount_codes, code), <a href="configuration.md#0x0_configuration_EDiscountCodeNotExists">EDiscountCodeNotExists</a>);

    <b>let</b> value = <a href="_get">vec_map::get</a>(&config.discount_codes, code);
    <b>let</b> owner = value.owner;
    <b>let</b> sender = <a href="converter.md#0x0_converter_address_to_string">converter::address_to_string</a>(sender(ctx));
    <b>assert</b>!(owner == <a href="_string">ascii::string</a>(sender), <a href="configuration.md#0x0_configuration_EOwnerUnauthorized">EOwnerUnauthorized</a>);

    <b>let</b> rate = value.rate;
    <a href="_remove">vec_map::remove</a>(&<b>mut</b> config.discount_codes, code);
    rate
}
</code></pre>



</details>

<a name="0x0_configuration_use_referral_code"></a>

## Function `use_referral_code`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="configuration.md#0x0_configuration_use_referral_code">use_referral_code</a>(config: &<a href="configuration.md#0x0_configuration_Configuration">configuration::Configuration</a>, code: &<a href="_String">ascii::String</a>): (u8, <b>address</b>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="configuration.md#0x0_configuration_use_referral_code">use_referral_code</a>(config: &<a href="configuration.md#0x0_configuration_Configuration">Configuration</a>, code: &<a href="_String">ascii::String</a>): (u8, <b>address</b>) {
    <b>assert</b>!(<a href="_contains">vec_map::contains</a>(&config.referral_codes, code), <a href="configuration.md#0x0_configuration_EReferralCodeNotExists">EReferralCodeNotExists</a>);
    <b>let</b> value = <a href="_get">vec_map::get</a>(&config.referral_codes, code);
    (value.rate, value.partner)
}
</code></pre>



</details>

<a name="0x0_configuration_emoji_config"></a>

## Function `emoji_config`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="configuration.md#0x0_configuration_emoji_config">emoji_config</a>(config: &<a href="configuration.md#0x0_configuration_Configuration">configuration::Configuration</a>): &<a href="emoji.md#0x0_emoji_EmojiConfiguration">emoji::EmojiConfiguration</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="configuration.md#0x0_configuration_emoji_config">emoji_config</a>(config: &<a href="configuration.md#0x0_configuration_Configuration">Configuration</a>): &EmojiConfiguration {
    &config.emoji_config
}
</code></pre>



</details>

<a name="0x0_configuration_public_key"></a>

## Function `public_key`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="configuration.md#0x0_configuration_public_key">public_key</a>(config: &<a href="configuration.md#0x0_configuration_Configuration">configuration::Configuration</a>): &<a href="">vector</a>&lt;u8&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="configuration.md#0x0_configuration_public_key">public_key</a>(config: &<a href="configuration.md#0x0_configuration_Configuration">Configuration</a>): &<a href="">vector</a>&lt;u8&gt; {
    &config.public_key
}
</code></pre>



</details>

<a name="0x0_configuration_init"></a>

## Function `init`



<pre><code><b>fun</b> <a href="configuration.md#0x0_configuration_init">init</a>(ctx: &<b>mut</b> <a href="_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="configuration.md#0x0_configuration_init">init</a>(ctx: &<b>mut</b> TxContext) {
    <a href="_share_object">transfer::share_object</a>(<a href="configuration.md#0x0_configuration_Configuration">Configuration</a> {
        id: <a href="_new">object::new</a>(ctx),
        referral_codes: <a href="_empty">vec_map::empty</a>(),
        discount_codes: <a href="_empty">vec_map::empty</a>(),
        emoji_config: <a href="emoji.md#0x0_emoji_init_emoji_config">emoji::init_emoji_config</a>(),
        public_key: <a href="_empty">vector::empty</a>(),
    });
}
</code></pre>



</details>
