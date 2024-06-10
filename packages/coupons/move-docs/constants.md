
<a name="0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_constants"></a>

# Module `0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46::constants`



-  [Constants](#@Constants_0)
-  [Function `percentage_discount_type`](#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_constants_percentage_discount_type)
-  [Function `fixed_price_discount_type`](#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_constants_fixed_price_discount_type)
-  [Function `discount_rule_types`](#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_constants_discount_rule_types)


<pre><code></code></pre>



<a name="@Constants_0"></a>

## Constants


<a name="0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_constants_FIXED_PRICE_DISCOUNT"></a>

Fixed MIST discount (e.g. -5 SUI)


<pre><code><b>const</b> <a href="constants.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_constants_FIXED_PRICE_DISCOUNT">FIXED_PRICE_DISCOUNT</a>: u8 = 1;
</code></pre>



<a name="0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_constants_PERCENTAGE_DISCOUNT"></a>

discount types
Percentage discount (0,100]


<pre><code><b>const</b> <a href="constants.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_constants_PERCENTAGE_DISCOUNT">PERCENTAGE_DISCOUNT</a>: u8 = 0;
</code></pre>



<a name="0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_constants_percentage_discount_type"></a>

## Function `percentage_discount_type`

A getter for the percentage discount type.


<pre><code><b>public</b> <b>fun</b> <a href="constants.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_constants_percentage_discount_type">percentage_discount_type</a>(): u8
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="constants.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_constants_percentage_discount_type">percentage_discount_type</a>(): u8 { <a href="constants.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_constants_PERCENTAGE_DISCOUNT">PERCENTAGE_DISCOUNT</a>  }
</code></pre>



</details>

<a name="0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_constants_fixed_price_discount_type"></a>

## Function `fixed_price_discount_type`

A getter for the fixed price discount type.


<pre><code><b>public</b> <b>fun</b> <a href="constants.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_constants_fixed_price_discount_type">fixed_price_discount_type</a>(): u8
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="constants.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_constants_fixed_price_discount_type">fixed_price_discount_type</a>(): u8 { <a href="constants.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_constants_FIXED_PRICE_DISCOUNT">FIXED_PRICE_DISCOUNT</a> }
</code></pre>



</details>

<a name="0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_constants_discount_rule_types"></a>

## Function `discount_rule_types`

A vector with all the discount rule types.


<pre><code><b>public</b> <b>fun</b> <a href="constants.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_constants_discount_rule_types">discount_rule_types</a>(): <a href="dependencies/move-stdlib/vector.md#0x1_vector">vector</a>&lt;u8&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="constants.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_constants_discount_rule_types">discount_rule_types</a>(): <a href="dependencies/move-stdlib/vector.md#0x1_vector">vector</a>&lt;u8&gt; { <a href="dependencies/move-stdlib/vector.md#0x1_vector">vector</a>[<a href="constants.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_constants_PERCENTAGE_DISCOUNT">PERCENTAGE_DISCOUNT</a>, <a href="constants.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_constants_FIXED_PRICE_DISCOUNT">FIXED_PRICE_DISCOUNT</a>] }
</code></pre>



</details>
