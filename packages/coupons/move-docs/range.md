
<a name="0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_range"></a>

# Module `0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8::range`

A module to introduce <code><a href="range.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_range">range</a></code> checks for the rules.


-  [Struct `Range`](#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_range_Range)
-  [Constants](#@Constants_0)
-  [Function `new`](#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_range_new)
-  [Function `is_in_range`](#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_range_is_in_range)
-  [Function `from`](#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_range_from)
-  [Function `to`](#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_range_to)


<pre><code></code></pre>



<a name="0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_range_Range"></a>

## Struct `Range`

A Range for u8 helper


<pre><code><b>struct</b> <a href="range.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_range_Range">Range</a> <b>has</b> <b>copy</b>, drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>vec: <a href="dependencies/move-stdlib/vector.md#0x1_vector">vector</a>&lt;u8&gt;</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="@Constants_0"></a>

## Constants


<a name="0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_range_EInvalidRange"></a>

Invalid [from, to] setup in the range!
<code><b>to</b></code> parameter has to be >= <code>from</code>


<pre><code><b>const</b> <a href="range.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_range_EInvalidRange">EInvalidRange</a>: u64 = 0;
</code></pre>



<a name="0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_range_new"></a>

## Function `new`

a new Range constructor[from, to]


<pre><code><b>public</b> <b>fun</b> <a href="range.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_range_new">new</a>(from: u8, <b>to</b>: u8): <a href="range.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_range_Range">range::Range</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="range.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_range_new">new</a>(from: u8, <b>to</b>: u8): <a href="range.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_range_Range">Range</a> {
    <b>assert</b>!(<b>to</b> &gt;= from, <a href="range.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_range_EInvalidRange">EInvalidRange</a>);

    <a href="range.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_range_Range">Range</a> {
        vec: <a href="dependencies/move-stdlib/vector.md#0x1_vector">vector</a>[from, <b>to</b>]
    }
}
</code></pre>



</details>

<a name="0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_range_is_in_range"></a>

## Function `is_in_range`



<pre><code><b>public</b> <b>fun</b> <a href="range.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_range_is_in_range">is_in_range</a>(<a href="range.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_range">range</a>: &<a href="range.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_range_Range">range::Range</a>, number: u8): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="range.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_range_is_in_range">is_in_range</a>(<a href="range.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_range">range</a>: &<a href="range.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_range_Range">Range</a>, number: u8): bool {
    number &gt;= <a href="range.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_range_from">from</a>(<a href="range.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_range">range</a>) && number &lt;= <b>to</b>(<a href="range.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_range">range</a>)
}
</code></pre>



</details>

<a name="0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_range_from"></a>

## Function `from`

Get floor limit for the range.


<pre><code><b>public</b> <b>fun</b> <a href="range.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_range_from">from</a>(<a href="range.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_range">range</a>: &<a href="range.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_range_Range">range::Range</a>): u8
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="range.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_range_from">from</a>(<a href="range.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_range">range</a>: &<a href="range.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_range_Range">Range</a>): u8 {
    <a href="range.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_range">range</a>.vec[0]
}
</code></pre>



</details>

<a name="0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_range_to"></a>

## Function `to`

Get upper limit for the range.


<pre><code><b>public</b> <b>fun</b> <b>to</b>(<a href="range.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_range">range</a>: &<a href="range.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_range_Range">range::Range</a>): u8
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <b>to</b>(<a href="range.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_range">range</a>: &<a href="range.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_range_Range">Range</a>): u8 {
    <a href="range.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_range">range</a>.vec[1]
}
</code></pre>



</details>