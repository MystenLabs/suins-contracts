
<a name="0x0_converter"></a>

# Module `0x0::converter`



-  [Constants](#@Constants_0)
-  [Function `address_to_string`](#0x0_converter_address_to_string)
-  [Function `string_to_number`](#0x0_converter_string_to_number)


<pre><code><b>use</b> <a href="">0x1::bcs</a>;
<b>use</b> <a href="">0x1::string</a>;
</code></pre>



<a name="@Constants_0"></a>

## Constants


<a name="0x0_converter_EInvalidNumber"></a>



<pre><code><b>const</b> <a href="converter.md#0x0_converter_EInvalidNumber">EInvalidNumber</a>: u64 = 601;
</code></pre>



<a name="0x0_converter_REGISTRATION_FEE_PER_YEAR"></a>



<pre><code><b>const</b> <a href="converter.md#0x0_converter_REGISTRATION_FEE_PER_YEAR">REGISTRATION_FEE_PER_YEAR</a>: u64 = 1000000;
</code></pre>



<a name="0x0_converter_address_to_string"></a>

## Function `address_to_string`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="converter.md#0x0_converter_address_to_string">address_to_string</a>(addr: <b>address</b>): <a href="">vector</a>&lt;u8&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="converter.md#0x0_converter_address_to_string">address_to_string</a>(addr: <b>address</b>): <a href="">vector</a>&lt;u8&gt; {
    <b>let</b> bytes = <a href="_to_bytes">bcs::to_bytes</a>(&addr);
    <b>let</b> len = <a href="_length">vector::length</a>(&bytes);
    <b>let</b> index = 0;
    <b>let</b> result: <a href="">vector</a>&lt;u8&gt; = <a href="">vector</a>[];

    <b>while</b>(index &lt; len) {
        <b>let</b> byte = *<a href="_borrow">vector::borrow</a>(&bytes, index);

        <b>let</b> first: u8 = (byte &gt;&gt; 4) & 0xF;
        // a in HEX == 10 in DECIMAL
        // 'a' in CHAR  == 97 in DECIMAL
        // 8 in HEX == 8 in DECIMAL
        // '8' in CHAR  == 56 in DECIMAL
        <b>if</b> (first &gt; 9) first = first + 87
        <b>else</b> first = first + 48;

        <b>let</b> second: u8 = byte & 0xF;
        <b>if</b> (second &gt; 9) second = second + 87
        <b>else</b> second = second + 48;

        <a href="_push_back">vector::push_back</a>(&<b>mut</b> result, first);
        <a href="_push_back">vector::push_back</a>(&<b>mut</b> result, second);

        index = index + 1;
    };

    result
}
</code></pre>



</details>

<a name="0x0_converter_string_to_number"></a>

## Function `string_to_number`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="converter.md#0x0_converter_string_to_number">string_to_number</a>(str: <a href="_String">string::String</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="converter.md#0x0_converter_string_to_number">string_to_number</a>(str: String): u64 {
    <b>let</b> bytes = <a href="_bytes">string::bytes</a>(&str);
    // count from 1 because Move doesn't have negative number atm
    <b>let</b> index = <a href="_length">vector::length</a>(bytes);
    <b>let</b> result: u64 = 0;
    <b>let</b> base = 1;

    <b>while</b> (index &gt; 0) {
        <b>let</b> byte = *<a href="_borrow">vector::borrow</a>(bytes, index - 1);
        <b>assert</b>!(byte &gt;= 0x30 && byte &lt;= 0x39, <a href="converter.md#0x0_converter_EInvalidNumber">EInvalidNumber</a>); // 0-9
        result = result + ((byte <b>as</b> u64) - 0x30) * base;
        // avoid overflow <b>if</b> input is MAX_U64
        <b>if</b> (index != 1) base = base * 10;
        index = index - 1;
    };
    result
}
</code></pre>



</details>
