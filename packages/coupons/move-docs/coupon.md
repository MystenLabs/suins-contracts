
<a name="0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon"></a>

# Module `0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8::coupon`



-  [Struct `Coupon`](#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_Coupon)
-  [Function `new`](#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_new)
-  [Function `rules`](#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_rules)
-  [Function `rules_mut`](#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_rules_mut)
-  [Function `calculate_sale_price`](#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_calculate_sale_price)


<pre><code><b>use</b> <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context">0x2::tx_context</a>;
<b>use</b> <a href="constants.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_constants">0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8::constants</a>;
<b>use</b> <a href="rules.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_rules">0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8::rules</a>;
</code></pre>



<a name="0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_Coupon"></a>

## Struct `Coupon`

A Coupon has a type, a value and a ruleset.
- <code>Rules</code> are defined on the module <code><a href="rules.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_rules">rules</a></code>, and covers a variety of everything we needed for the service.
- <code>kind</code> is a u8 constant, defined on <code><a href="dependencies/suins/constants.md#0x2b10a05147fd7ab35d05314031e5821e9ad1718e4962552d659273b711c0961b_constants">constants</a></code> which makes a coupon fixed price or discount percentage
- <code>value</code> is a u64 constant, which can be in the range of (0,100] for discount percentage, or any value > 0 for fixed price.


<pre><code><b>struct</b> <a href="coupon.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_Coupon">Coupon</a> <b>has</b> <b>copy</b>, drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>kind: u8</code>
</dt>
<dd>

</dd>
<dt>
<code>amount: u64</code>
</dt>
<dd>

</dd>
<dt>
<code><a href="rules.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_rules">rules</a>: <a href="rules.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_rules_CouponRules">rules::CouponRules</a></code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_new"></a>

## Function `new`

An internal function to create a coupon object.


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="coupon.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_new">new</a>(kind: u8, amount: u64, <a href="rules.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_rules">rules</a>: <a href="rules.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_rules_CouponRules">rules::CouponRules</a>, _ctx: &<b>mut</b> <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context_TxContext">tx_context::TxContext</a>): <a href="coupon.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_Coupon">coupon::Coupon</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<a href="dependencies/sui-framework/package.md#0x2_package">package</a>) <b>fun</b> <a href="coupon.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_new">new</a>(
    kind: u8,
    amount: u64,
    <a href="rules.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_rules">rules</a>: CouponRules,
    _ctx: &<b>mut</b> TxContext
): <a href="coupon.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_Coupon">Coupon</a> {
    <a href="rules.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_rules_assert_is_valid_amount">rules::assert_is_valid_amount</a>(kind, amount);
    <a href="rules.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_rules_assert_is_valid_discount_type">rules::assert_is_valid_discount_type</a>(kind);
    <a href="coupon.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_Coupon">Coupon</a> {
        kind, amount, <a href="rules.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_rules">rules</a>
    }
}
</code></pre>



</details>

<a name="0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_rules"></a>

## Function `rules`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="rules.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_rules">rules</a>(<a href="coupon.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon">coupon</a>: &<a href="coupon.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_Coupon">coupon::Coupon</a>): &<a href="rules.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_rules_CouponRules">rules::CouponRules</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<a href="dependencies/sui-framework/package.md#0x2_package">package</a>) <b>fun</b> <a href="rules.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_rules">rules</a>(<a href="coupon.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon">coupon</a>: &<a href="coupon.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_Coupon">Coupon</a>): &CouponRules {
    &<a href="coupon.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon">coupon</a>.<a href="rules.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_rules">rules</a>
}
</code></pre>



</details>

<a name="0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_rules_mut"></a>

## Function `rules_mut`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="coupon.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_rules_mut">rules_mut</a>(<a href="coupon.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon">coupon</a>: &<b>mut</b> <a href="coupon.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_Coupon">coupon::Coupon</a>): &<b>mut</b> <a href="rules.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_rules_CouponRules">rules::CouponRules</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<a href="dependencies/sui-framework/package.md#0x2_package">package</a>) <b>fun</b> <a href="coupon.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_rules_mut">rules_mut</a>(<a href="coupon.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon">coupon</a>: &<b>mut</b> <a href="coupon.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_Coupon">Coupon</a>): &<b>mut</b> CouponRules {
    &<b>mut</b> <a href="coupon.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon">coupon</a>.<a href="rules.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_rules">rules</a>
}
</code></pre>



</details>

<a name="0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_calculate_sale_price"></a>

## Function `calculate_sale_price`

A helper to calculate the final price after the discount.


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="coupon.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_calculate_sale_price">calculate_sale_price</a>(<a href="coupon.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon">coupon</a>: &<a href="coupon.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_Coupon">coupon::Coupon</a>, price: u64): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<a href="dependencies/sui-framework/package.md#0x2_package">package</a>) <b>fun</b> <a href="coupon.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_calculate_sale_price">calculate_sale_price</a>(<a href="coupon.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon">coupon</a>: &<a href="coupon.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_Coupon">Coupon</a>, price: u64): u64 {
    // If it's fixed price, we just deduce the amount.
    <b>if</b>(<a href="coupon.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon">coupon</a>.kind == constants::fixed_price_discount_type()){
        <b>if</b>(<a href="coupon.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon">coupon</a>.amount &gt; price) <b>return</b> 0; // protect underflow case.
        <b>return</b> price - <a href="coupon.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon">coupon</a>.amount
    };

    // If it's discount price, we calculate the discount
    <b>let</b> discount =  (((price <b>as</b> u128) * (<a href="coupon.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon">coupon</a>.amount <b>as</b> u128) / 100) <b>as</b> u64);
    // then remove it from the sale price.
    price - discount
}
</code></pre>



</details>
