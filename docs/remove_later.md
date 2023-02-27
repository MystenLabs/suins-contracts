
<a name="0x0_remove_later"></a>

# Module `0x0::remove_later`

These funtionalities are supposed to be supported by the Sui SDK in the future
we will remove it as soon as SDK's support is ready


-  [Struct `DiscountCode`](#0x0_remove_later_DiscountCode)
-  [Constants](#@Constants_0)
-  [Function `deserialize_image_msg`](#0x0_remove_later_deserialize_image_msg)
-  [Function `deserialize_reserve_domains`](#0x0_remove_later_deserialize_reserve_domains)
-  [Function `deserialize_new_discount_code_batch`](#0x0_remove_later_deserialize_new_discount_code_batch)
-  [Function `deserialize_remove_discount_code_batch`](#0x0_remove_later_deserialize_remove_discount_code_batch)
-  [Function `get_discount_fields`](#0x0_remove_later_get_discount_fields)
-  [Function `deserialize_discount_code`](#0x0_remove_later_deserialize_discount_code)


<pre><code><b>use</b> <a href="converter.md#0x0_converter">0x0::converter</a>;
<b>use</b> <a href="">0x1::ascii</a>;
<b>use</b> <a href="">0x1::string</a>;
<b>use</b> <a href="">0x1::vector</a>;
</code></pre>



<a name="0x0_remove_later_DiscountCode"></a>

## Struct `DiscountCode`



<pre><code><b>struct</b> <a href="remove_later.md#0x0_remove_later_DiscountCode">DiscountCode</a> <b>has</b> drop
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

<a name="@Constants_0"></a>

## Constants


<a name="0x0_remove_later_EInvalidDiscountCodeBatch"></a>



<pre><code><b>const</b> <a href="remove_later.md#0x0_remove_later_EInvalidDiscountCodeBatch">EInvalidDiscountCodeBatch</a>: u64 = 501;
</code></pre>



<a name="0x0_remove_later_deserialize_image_msg"></a>

## Function `deserialize_image_msg`

<code>msg</code> format: <ipfs_url>,<node>,<expiry>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="remove_later.md#0x0_remove_later_deserialize_image_msg">deserialize_image_msg</a>(msg: <a href="">vector</a>&lt;u8&gt;): (<a href="_String">string::String</a>, <a href="_String">string::String</a>, u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="remove_later.md#0x0_remove_later_deserialize_image_msg">deserialize_image_msg</a>(msg: <a href="">vector</a>&lt;u8&gt;): (String, String, u64) {
    // `msg` now: ipfs_url,owner,expiry
    <b>let</b> msg = utf8(msg);
    <b>let</b> comma = utf8(b",");

    <b>let</b> index_of_next_comma = <a href="_index_of">string::index_of</a>(&msg, &comma);
    <b>let</b> ipfs = <a href="_sub_string">string::sub_string</a>(&msg, 0, index_of_next_comma);

    // `msg` now: owner,expiry
    msg = <a href="_sub_string">string::sub_string</a>(&msg, index_of_next_comma + 1, <a href="_length">string::length</a>(&msg));

    index_of_next_comma = <a href="_index_of">string::index_of</a>(&msg, &comma);
    <b>let</b> node = <a href="_sub_string">string::sub_string</a>(&msg, 0, index_of_next_comma);
    // `msg` now: expiry
    <b>let</b> expiry = <a href="_sub_string">string::sub_string</a>(&msg, index_of_next_comma + 1, <a href="_length">string::length</a>(&msg));

    (ipfs, node, <a href="converter.md#0x0_converter_string_to_number">converter::string_to_number</a>(expiry))
}
</code></pre>



</details>

<a name="0x0_remove_later_deserialize_reserve_domains"></a>

## Function `deserialize_reserve_domains`

This funtion doesn't validate domains
<code>domains</code> format: domain1;domain2;


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="remove_later.md#0x0_remove_later_deserialize_reserve_domains">deserialize_reserve_domains</a>(domains: <a href="">vector</a>&lt;u8&gt;): <a href="">vector</a>&lt;<a href="_String">string::String</a>&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="remove_later.md#0x0_remove_later_deserialize_reserve_domains">deserialize_reserve_domains</a>(domains: <a href="">vector</a>&lt;u8&gt;): <a href="">vector</a>&lt;String&gt; {
    <b>let</b> last_character = <a href="_borrow">vector::borrow</a>(&domains, <a href="_length">vector::length</a>(&domains) - 1);
    // add a semicolon <b>to</b> the end of `discount_code_batch` <b>to</b> make every code have the same layout
    <b>if</b> (*last_character != 59) {
        <a href="_push_back">vector::push_back</a>(&<b>mut</b> domains, 59);
    };
    <b>let</b> reserve_domains: <a href="">vector</a>&lt;String&gt; = <a href="">vector</a>[];
    <b>let</b> semi_colon = utf8(b";");
    <b>let</b> domains = utf8(domains);

    <b>let</b> index_of_next_semi_colon = <a href="_index_of">string::index_of</a>(&domains, &semi_colon);
    <b>let</b> len = <a href="_length">string::length</a>(&domains);
    <b>while</b> (index_of_next_semi_colon != len) {
        <b>let</b> domain = <a href="_sub_string">string::sub_string</a>(&domains, 0, index_of_next_semi_colon);
        <a href="_push_back">vector::push_back</a>(&<b>mut</b> reserve_domains, domain);

        domains = <a href="_sub_string">string::sub_string</a>(&domains, index_of_next_semi_colon + 1, len);
        len = len - index_of_next_semi_colon - 1;
        index_of_next_semi_colon = <a href="_index_of">string::index_of</a>(&domains, &semi_colon);
    };

    reserve_domains
}
</code></pre>



</details>

<a name="0x0_remove_later_deserialize_new_discount_code_batch"></a>

## Function `deserialize_new_discount_code_batch`

<code>discount_code_batch</code> format: code1,rate1,owner1;code2,rate2,owner2;
owner must have '0x'


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="remove_later.md#0x0_remove_later_deserialize_new_discount_code_batch">deserialize_new_discount_code_batch</a>(discount_code_batch: <a href="">vector</a>&lt;u8&gt;): <a href="">vector</a>&lt;<a href="remove_later.md#0x0_remove_later_DiscountCode">remove_later::DiscountCode</a>&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="remove_later.md#0x0_remove_later_deserialize_new_discount_code_batch">deserialize_new_discount_code_batch</a>(discount_code_batch: <a href="">vector</a>&lt;u8&gt;): <a href="">vector</a>&lt;<a href="remove_later.md#0x0_remove_later_DiscountCode">DiscountCode</a>&gt; {
    <b>let</b> last_character = <a href="_borrow">vector::borrow</a>(&discount_code_batch, <a href="_length">vector::length</a>(&discount_code_batch) - 1);
    // add a semicolon <b>to</b> the end of `discount_code_batch` <b>to</b> make every code have the same layout
    <b>if</b> (*last_character != 59) {
        <a href="_push_back">vector::push_back</a>(&<b>mut</b> discount_code_batch, 59);
    };
    <b>let</b> discount_codes: <a href="">vector</a>&lt;<a href="remove_later.md#0x0_remove_later_DiscountCode">DiscountCode</a>&gt; = <a href="">vector</a>[];
    <b>let</b> semi_colon = utf8(b";");
    // convert <b>to</b> UTF8 <a href="">string</a> because ASCII <a href="">string</a> doesn't have `sub_string`
    // the deserialized codes are in ASCII
    <b>let</b> discount_code_batch = utf8(discount_code_batch);

    <b>let</b> index_of_next_semi_colon = <a href="_index_of">string::index_of</a>(&discount_code_batch, &semi_colon);
    <b>let</b> len = <a href="_length">string::length</a>(&discount_code_batch);
    <b>while</b> (index_of_next_semi_colon != len) {
        <b>let</b> discount_code_str = <a href="_sub_string">string::sub_string</a>(&discount_code_batch, 0, index_of_next_semi_colon);
        <b>let</b> discount = <a href="remove_later.md#0x0_remove_later_deserialize_discount_code">deserialize_discount_code</a>(discount_code_str);
        <a href="_push_back">vector::push_back</a>(&<b>mut</b> discount_codes, discount);

        discount_code_batch = <a href="_sub_string">string::sub_string</a>(&discount_code_batch, index_of_next_semi_colon + 1, len);
        len = len - index_of_next_semi_colon - 1;
        index_of_next_semi_colon = <a href="_index_of">string::index_of</a>(&discount_code_batch, &semi_colon);
    };

    discount_codes
}
</code></pre>



</details>

<a name="0x0_remove_later_deserialize_remove_discount_code_batch"></a>

## Function `deserialize_remove_discount_code_batch`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="remove_later.md#0x0_remove_later_deserialize_remove_discount_code_batch">deserialize_remove_discount_code_batch</a>(discount_code_batch: <a href="">vector</a>&lt;u8&gt;): <a href="">vector</a>&lt;<a href="_String">ascii::String</a>&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="remove_later.md#0x0_remove_later_deserialize_remove_discount_code_batch">deserialize_remove_discount_code_batch</a>(discount_code_batch: <a href="">vector</a>&lt;u8&gt;): <a href="">vector</a>&lt;<a href="_String">ascii::String</a>&gt; {
    <b>let</b> last_character = <a href="_borrow">vector::borrow</a>(&discount_code_batch, <a href="_length">vector::length</a>(&discount_code_batch) - 1);
    // add a semicolon <b>to</b> the end of `discount_code_batch` <b>to</b> make every code have the same layout
    <b>if</b> (*last_character != 59) {
        <a href="_push_back">vector::push_back</a>(&<b>mut</b> discount_code_batch, 59);
    };
    <b>let</b> codes: <a href="">vector</a>&lt;<a href="_String">ascii::String</a>&gt; = <a href="">vector</a>[];
    <b>let</b> semi_colon = utf8(b";");
    // convert <b>to</b> UTF8 <a href="">string</a> because ASCII <a href="">string</a> doesn't have `sub_string` and `index`
    // the deserialized codes are in ASCII
    <b>let</b> discount_code_batch = utf8(discount_code_batch);

    <b>let</b> index_of_next_semi_colon = <a href="_index_of">string::index_of</a>(&discount_code_batch, &semi_colon);
    <b>let</b> len = <a href="_length">string::length</a>(&discount_code_batch);
    <b>while</b> (index_of_next_semi_colon != len) {
        <b>let</b> code_str = <a href="_sub_string">string::sub_string</a>(&discount_code_batch, 0, index_of_next_semi_colon);
        <b>let</b> code_bytes = <a href="_bytes">string::bytes</a>(&code_str);
        <b>let</b> code_str = <a href="_string">ascii::string</a>(*code_bytes);
        <b>assert</b>!(<a href="_all_characters_printable">ascii::all_characters_printable</a>(&code_str), <a href="remove_later.md#0x0_remove_later_EInvalidDiscountCodeBatch">EInvalidDiscountCodeBatch</a>);
        <a href="_push_back">vector::push_back</a>(&<b>mut</b> codes, code_str);

        discount_code_batch = <a href="_sub_string">string::sub_string</a>(&discount_code_batch, index_of_next_semi_colon + 1, len);
        len = len - index_of_next_semi_colon - 1;
        index_of_next_semi_colon = <a href="_index_of">string::index_of</a>(&discount_code_batch, &semi_colon);
    };

    codes
}
</code></pre>



</details>

<a name="0x0_remove_later_get_discount_fields"></a>

## Function `get_discount_fields`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="remove_later.md#0x0_remove_later_get_discount_fields">get_discount_fields</a>(discount_code: &<a href="remove_later.md#0x0_remove_later_DiscountCode">remove_later::DiscountCode</a>): (<a href="_String">ascii::String</a>, u8, <a href="_String">ascii::String</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="remove_later.md#0x0_remove_later_get_discount_fields">get_discount_fields</a>(discount_code: &<a href="remove_later.md#0x0_remove_later_DiscountCode">DiscountCode</a>): (<a href="_String">ascii::String</a>, u8, <a href="_String">ascii::String</a>) {
    (discount_code.code, discount_code.rate, discount_code.owner)
}
</code></pre>



</details>

<a name="0x0_remove_later_deserialize_discount_code"></a>

## Function `deserialize_discount_code`

<code>str</code> format: code1,rate1,owner1


<pre><code><b>fun</b> <a href="remove_later.md#0x0_remove_later_deserialize_discount_code">deserialize_discount_code</a>(str: <a href="_String">string::String</a>): <a href="remove_later.md#0x0_remove_later_DiscountCode">remove_later::DiscountCode</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="remove_later.md#0x0_remove_later_deserialize_discount_code">deserialize_discount_code</a>(str: String): <a href="remove_later.md#0x0_remove_later_DiscountCode">DiscountCode</a> {
    // `str` now: code,rate,owner
    <b>let</b> comma = utf8(b",");

    <b>let</b> index_of_next_comma = <a href="_index_of">string::index_of</a>(&str, &comma);
    <b>let</b> code = <a href="_sub_string">string::sub_string</a>(&str, 0, index_of_next_comma);
    <b>let</b> code_bytes = <a href="_bytes">string::bytes</a>(&code);
    <b>let</b> code = <a href="_string">ascii::string</a>(*code_bytes);
    <b>assert</b>!(<a href="_all_characters_printable">ascii::all_characters_printable</a>(&code), <a href="remove_later.md#0x0_remove_later_EInvalidDiscountCodeBatch">EInvalidDiscountCodeBatch</a>);

    // all processed parts are removed because `<a href="_index_of">string::index_of</a>` only returns first index
    // also remove colon character
    // `str` now: rate:owner
    str = <a href="_sub_string">string::sub_string</a>(&str, index_of_next_comma + 1, <a href="_length">string::length</a>(&str));
    index_of_next_comma = <a href="_index_of">string::index_of</a>(&str, &comma);
    // rate cannot <b>has</b> more than 3 characters
    // index_of_next_colon == 0: rate is not included
    <b>assert</b>!((0 &lt; index_of_next_comma || index_of_next_comma &lt; 3), <a href="remove_later.md#0x0_remove_later_EInvalidDiscountCodeBatch">EInvalidDiscountCodeBatch</a>);
    <b>let</b> rate_str = <a href="_sub_string">string::sub_string</a>(&str, 0, index_of_next_comma);
    <b>let</b> rate: u8;
    // 3 characters means it <b>has</b> <b>to</b> be 100
    <b>if</b> (index_of_next_comma == 3) {
        <b>assert</b>!(rate_str == utf8(b"100"), <a href="remove_later.md#0x0_remove_later_EInvalidDiscountCodeBatch">EInvalidDiscountCodeBatch</a>);
        rate = 100
    } <b>else</b> rate = (<a href="converter.md#0x0_converter_string_to_number">converter::string_to_number</a>(rate_str) <b>as</b> u8);

    // `str` now: owner
    str = <a href="_sub_string">string::sub_string</a>(&str, index_of_next_comma + 1, <a href="_length">string::length</a>(&str));
    // TODO: check start <b>with</b> 0x
    <b>let</b> hex_prefix = <a href="_sub_string">string::sub_string</a>(&str, 0, 2);
    <b>assert</b>!(hex_prefix == utf8(b"0x"), <a href="remove_later.md#0x0_remove_later_EInvalidDiscountCodeBatch">EInvalidDiscountCodeBatch</a>);
    <b>let</b> owner = <a href="_sub_string">string::sub_string</a>(&str, 2, <a href="_length">string::length</a>(&str));
    <b>let</b> owner_bytes = *<a href="_bytes">string::bytes</a>(&owner);
    <b>let</b> index = 0;
    <b>let</b> len = <a href="_length">vector::length</a>(&owner_bytes);
    <b>while</b>(index &lt; len) {
        <b>let</b> byte = <a href="_borrow_mut">vector::borrow_mut</a>(&<b>mut</b> owner_bytes, index);
        // hack for the `<b>assert</b>` statement below
        <b>let</b> byte_tmp = *byte;
        <b>assert</b>!(
            (0x61 &lt;= byte_tmp && byte_tmp &lt;= 0x66)                           // a-f
                || (0x41 &lt;= byte_tmp && byte_tmp &lt;= 0x46)                    // A-F
                || (0x30 &lt;= byte_tmp && byte_tmp &lt;= 0x39),                   // 0-9
            <a href="remove_later.md#0x0_remove_later_EInvalidDiscountCodeBatch">EInvalidDiscountCodeBatch</a>
        );
        <b>if</b> (0x41 &lt;= byte_tmp && byte_tmp &lt;= 0x46) {
            *byte = *byte + 32;
        };
        index = index + 1;
    };
    <b>let</b> owner: <a href="">vector</a>&lt;u8&gt; = <a href="">vector</a>[];
    // padding leading '0'
    <b>while</b> (len &lt; 40) {
        <a href="_push_back">vector::push_back</a>(&<b>mut</b> owner, 0x30);
        len = len + 1;
    };
    <a href="_append">vector::append</a>(&<b>mut</b> owner, owner_bytes);
    <a href="remove_later.md#0x0_remove_later_DiscountCode">DiscountCode</a> { code, rate, owner: <a href="_string">ascii::string</a>(owner) }
}
</code></pre>



</details>
