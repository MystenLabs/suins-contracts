
<a name="0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules"></a>

# Module `0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46::rules`



-  [Struct `CouponRules`](#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_CouponRules)
-  [Constants](#@Constants_0)
-  [Function `new_coupon_rules`](#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_new_coupon_rules)
-  [Function `new_empty_rules`](#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_new_empty_rules)
-  [Function `decrease_available_claims`](#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_decrease_available_claims)
-  [Function `has_available_claims`](#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_has_available_claims)
-  [Function `assert_coupon_valid_for_domain_years`](#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_assert_coupon_valid_for_domain_years)
-  [Function `is_coupon_valid_for_domain_years`](#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_is_coupon_valid_for_domain_years)
-  [Function `assert_is_valid_discount_type`](#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_assert_is_valid_discount_type)
-  [Function `assert_is_valid_amount`](#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_assert_is_valid_amount)
-  [Function `assert_coupon_valid_for_domain_size`](#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_assert_coupon_valid_for_domain_size)
-  [Function `is_coupon_valid_for_domain_size`](#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_is_coupon_valid_for_domain_size)
-  [Function `assert_coupon_valid_for_address`](#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_assert_coupon_valid_for_address)
-  [Function `is_coupon_valid_for_address`](#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_is_coupon_valid_for_address)
-  [Function `assert_coupon_is_not_expired`](#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_assert_coupon_is_not_expired)
-  [Function `is_coupon_expired`](#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_is_coupon_expired)
-  [Function `is_valid_years_range`](#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_is_valid_years_range)
-  [Function `is_valid_length_range`](#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_is_valid_length_range)


<pre><code><b>use</b> <a href="dependencies/move-stdlib/option.md#0x1_option">0x1::option</a>;
<b>use</b> <a href="dependencies/move-stdlib/vector.md#0x1_vector">0x1::vector</a>;
<b>use</b> <a href="dependencies/sui-framework/clock.md#0x2_clock">0x2::clock</a>;
<b>use</b> <a href="dependencies/suins/constants.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_constants">0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94::constants</a>;
<b>use</b> <a href="constants.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_constants">0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46::constants</a>;
<b>use</b> <a href="range.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_range">0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46::range</a>;
</code></pre>



<a name="0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_CouponRules"></a>

## Struct `CouponRules`

The Struct that holds the coupon's rules.
All rules are combined in <code>AND</code> fashion.
All of the checks have to pass for a coupon to be used.


<pre><code><b>struct</b> <a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_CouponRules">CouponRules</a> <b>has</b> <b>copy</b>, drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>length: <a href="dependencies/move-stdlib/option.md#0x1_option_Option">option::Option</a>&lt;<a href="range.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_range_Range">range::Range</a>&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>available_claims: <a href="dependencies/move-stdlib/option.md#0x1_option_Option">option::Option</a>&lt;u64&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>user: <a href="dependencies/move-stdlib/option.md#0x1_option_Option">option::Option</a>&lt;<b>address</b>&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>expiration: <a href="dependencies/move-stdlib/option.md#0x1_option_Option">option::Option</a>&lt;u64&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>years: <a href="dependencies/move-stdlib/option.md#0x1_option_Option">option::Option</a>&lt;<a href="range.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_range_Range">range::Range</a>&gt;</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="@Constants_0"></a>

## Constants


<a name="0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_ECouponExpired"></a>

Error when coupon has expired


<pre><code><b>const</b> <a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_ECouponExpired">ECouponExpired</a>: u64 = 7;
</code></pre>



<a name="0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_EInvalidAmount"></a>

Error when you try to create a percentage discount coupon with invalid percentage amount.


<pre><code><b>const</b> <a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_EInvalidAmount">EInvalidAmount</a>: u64 = 4;
</code></pre>



<a name="0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_EInvalidAvailableClaims"></a>

Available claims can't be 0.


<pre><code><b>const</b> <a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_EInvalidAvailableClaims">EInvalidAvailableClaims</a>: u64 = 9;
</code></pre>



<a name="0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_EInvalidForDomainLength"></a>

Error when you try to use a coupon which doesn't match to the domain's size.


<pre><code><b>const</b> <a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_EInvalidForDomainLength">EInvalidForDomainLength</a>: u64 = 2;
</code></pre>



<a name="0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_EInvalidLengthRule"></a>

Error when you try to create a DomainLengthRule with invalid type.


<pre><code><b>const</b> <a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_EInvalidLengthRule">EInvalidLengthRule</a>: u64 = 0;
</code></pre>



<a name="0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_EInvalidType"></a>

Error when you try to create a coupon with invalid type.


<pre><code><b>const</b> <a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_EInvalidType">EInvalidType</a>: u64 = 5;
</code></pre>



<a name="0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_EInvalidUser"></a>

Error when you try to use a coupon without the matching address


<pre><code><b>const</b> <a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_EInvalidUser">EInvalidUser</a>: u64 = 6;
</code></pre>



<a name="0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_EInvalidYears"></a>

Error when creating years range.


<pre><code><b>const</b> <a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_EInvalidYears">EInvalidYears</a>: u64 = 8;
</code></pre>



<a name="0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_ENoMoreAvailableClaims"></a>

Error when you try to use a domain that has used all it's available claims.


<pre><code><b>const</b> <a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_ENoMoreAvailableClaims">ENoMoreAvailableClaims</a>: u64 = 3;
</code></pre>



<a name="0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_ENotValidYears"></a>

Error when you try to use a coupon that isn't valid for these years.


<pre><code><b>const</b> <a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_ENotValidYears">ENotValidYears</a>: u64 = 1;
</code></pre>



<a name="0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_new_coupon_rules"></a>

## Function `new_coupon_rules`

This is used in a PTB when creating a coupon.
Creates a CouponRules object to be used to create a coupon.
All rules are optional, and can be chained (<code>AND</code>) format.
1. Length: The name has to be in range [from, to]
2. Max available claims
3. Only for a specific address
4. Might have an expiration date.
5. Might be valid only for registrations in a range [from, to]


<pre><code><b>public</b> <b>fun</b> <a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_new_coupon_rules">new_coupon_rules</a>(length: <a href="dependencies/move-stdlib/option.md#0x1_option_Option">option::Option</a>&lt;<a href="range.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_range_Range">range::Range</a>&gt;, available_claims: <a href="dependencies/move-stdlib/option.md#0x1_option_Option">option::Option</a>&lt;u64&gt;, user: <a href="dependencies/move-stdlib/option.md#0x1_option_Option">option::Option</a>&lt;<b>address</b>&gt;, expiration: <a href="dependencies/move-stdlib/option.md#0x1_option_Option">option::Option</a>&lt;u64&gt;, years: <a href="dependencies/move-stdlib/option.md#0x1_option_Option">option::Option</a>&lt;<a href="range.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_range_Range">range::Range</a>&gt;): <a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_CouponRules">rules::CouponRules</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_new_coupon_rules">new_coupon_rules</a>(
    length: Option&lt;Range&gt;,
    available_claims: Option&lt;u64&gt;,
    user: Option&lt;<b>address</b>&gt;,
    expiration: Option&lt;u64&gt;,
    years: Option&lt;Range&gt;
): <a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_CouponRules">CouponRules</a> {
    <b>assert</b>!(<a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_is_valid_years_range">is_valid_years_range</a>(&years), <a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_EInvalidYears">EInvalidYears</a>);
    <b>assert</b>!(<a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_is_valid_length_range">is_valid_length_range</a>(&length), <a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_EInvalidLengthRule">EInvalidLengthRule</a>);
    <b>assert</b>!(available_claims.is_none() || (*available_claims.borrow() &gt; 0), <a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_EInvalidAvailableClaims">EInvalidAvailableClaims</a>);
    <a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_CouponRules">CouponRules</a> {
        length, available_claims, user, expiration, years
    }
}
</code></pre>



</details>

<a name="0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_new_empty_rules"></a>

## Function `new_empty_rules`



<pre><code><b>public</b> <b>fun</b> <a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_new_empty_rules">new_empty_rules</a>(): <a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_CouponRules">rules::CouponRules</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_new_empty_rules">new_empty_rules</a>(): <a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_CouponRules">CouponRules</a> {
    <a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_CouponRules">CouponRules</a> {
        length: <a href="dependencies/move-stdlib/option.md#0x1_option_none">option::none</a>(),
        available_claims: <a href="dependencies/move-stdlib/option.md#0x1_option_none">option::none</a>(),
        user: <a href="dependencies/move-stdlib/option.md#0x1_option_none">option::none</a>(),
        expiration: <a href="dependencies/move-stdlib/option.md#0x1_option_none">option::none</a>(),
        years: <a href="dependencies/move-stdlib/option.md#0x1_option_none">option::none</a>()
    }
}
</code></pre>



</details>

<a name="0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_decrease_available_claims"></a>

## Function `decrease_available_claims`

If the rules count <code>available_claims</code>, we decrease it.
Aborts if there are no more available claims on that coupon.
We shouldn't get here ever, as we're checking this on the coupon creation, but
keeping it as a sanity check (e.g. created a coupon with 0 available claims).


<pre><code><b>public</b> <b>fun</b> <a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_decrease_available_claims">decrease_available_claims</a>(<a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules">rules</a>: &<b>mut</b> <a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_CouponRules">rules::CouponRules</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_decrease_available_claims">decrease_available_claims</a>(<a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules">rules</a>: &<b>mut</b> <a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_CouponRules">CouponRules</a>) {
    <b>if</b>(<a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules">rules</a>.available_claims.is_some()){
        <b>assert</b>!(<a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_has_available_claims">has_available_claims</a>(<a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules">rules</a>), <a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_ENoMoreAvailableClaims">ENoMoreAvailableClaims</a>);
           // Decrease available claims by 1.
        <b>let</b> available_claims = *<a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules">rules</a>.available_claims.borrow();
        <a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules">rules</a>.available_claims.swap(available_claims - 1);
    }
}
</code></pre>



</details>

<a name="0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_has_available_claims"></a>

## Function `has_available_claims`



<pre><code><b>public</b> <b>fun</b> <a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_has_available_claims">has_available_claims</a>(<a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules">rules</a>: &<a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_CouponRules">rules::CouponRules</a>): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_has_available_claims">has_available_claims</a>(<a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules">rules</a>: &<a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_CouponRules">CouponRules</a>): bool {
    <b>if</b>(<a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules">rules</a>.available_claims.is_none()) <b>return</b> <b>true</b>;
    *<a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules">rules</a>.available_claims.borrow() &gt; 0
}
</code></pre>



</details>

<a name="0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_assert_coupon_valid_for_domain_years"></a>

## Function `assert_coupon_valid_for_domain_years`



<pre><code><b>public</b> <b>fun</b> <a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_assert_coupon_valid_for_domain_years">assert_coupon_valid_for_domain_years</a>(<a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules">rules</a>: &<a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_CouponRules">rules::CouponRules</a>, target: u8)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_assert_coupon_valid_for_domain_years">assert_coupon_valid_for_domain_years</a>(<a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules">rules</a>: &<a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_CouponRules">CouponRules</a>, target: u8) {
    <b>assert</b>!(<a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_is_coupon_valid_for_domain_years">is_coupon_valid_for_domain_years</a>(<a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules">rules</a>, target), <a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_ENotValidYears">ENotValidYears</a>);
}
</code></pre>



</details>

<a name="0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_is_coupon_valid_for_domain_years"></a>

## Function `is_coupon_valid_for_domain_years`



<pre><code><b>public</b> <b>fun</b> <a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_is_coupon_valid_for_domain_years">is_coupon_valid_for_domain_years</a>(<a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules">rules</a>: &<a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_CouponRules">rules::CouponRules</a>, target: u8): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_is_coupon_valid_for_domain_years">is_coupon_valid_for_domain_years</a>(<a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules">rules</a>: &<a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_CouponRules">CouponRules</a>, target: u8): bool {
    <b>if</b>(<a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules">rules</a>.years.is_none()) <b>return</b> <b>true</b>;

    <a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules">rules</a>.years.borrow().is_in_range(target)
}
</code></pre>



</details>

<a name="0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_assert_is_valid_discount_type"></a>

## Function `assert_is_valid_discount_type`



<pre><code><b>public</b> <b>fun</b> <a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_assert_is_valid_discount_type">assert_is_valid_discount_type</a>(type: u8)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_assert_is_valid_discount_type">assert_is_valid_discount_type</a>(`type`: u8) {
    <b>assert</b>!(constants::discount_rule_types().contains(&`type`), <a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_EInvalidType">EInvalidType</a>);
}
</code></pre>



</details>

<a name="0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_assert_is_valid_amount"></a>

## Function `assert_is_valid_amount`



<pre><code><b>public</b> <b>fun</b> <a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_assert_is_valid_amount">assert_is_valid_amount</a>(type: u8, amount: u64)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_assert_is_valid_amount">assert_is_valid_amount</a>(`type`: u8, amount: u64) {
    <b>assert</b>!(amount &gt; 0, <a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_EInvalidAmount">EInvalidAmount</a>); // protect from division by 0. 0 doesn't make sense in any scenario.
    <b>if</b>(`type` == constants::percentage_discount_type()){
        <b>assert</b>!(amount&lt;=100, <a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_EInvalidAmount">EInvalidAmount</a>)
    }
}
</code></pre>



</details>

<a name="0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_assert_coupon_valid_for_domain_size"></a>

## Function `assert_coupon_valid_for_domain_size`



<pre><code><b>public</b> <b>fun</b> <a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_assert_coupon_valid_for_domain_size">assert_coupon_valid_for_domain_size</a>(<a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules">rules</a>: &<a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_CouponRules">rules::CouponRules</a>, length: u8)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_assert_coupon_valid_for_domain_size">assert_coupon_valid_for_domain_size</a>(<a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules">rules</a>: &<a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_CouponRules">CouponRules</a>, length: u8) {
    <b>assert</b>!(<a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_is_coupon_valid_for_domain_size">is_coupon_valid_for_domain_size</a>(<a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules">rules</a>, length), <a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_EInvalidForDomainLength">EInvalidForDomainLength</a>)
}
</code></pre>



</details>

<a name="0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_is_coupon_valid_for_domain_size"></a>

## Function `is_coupon_valid_for_domain_size`

We check the length of the name based on the domain length rule


<pre><code><b>public</b> <b>fun</b> <a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_is_coupon_valid_for_domain_size">is_coupon_valid_for_domain_size</a>(<a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules">rules</a>: &<a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_CouponRules">rules::CouponRules</a>, length: u8): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_is_coupon_valid_for_domain_size">is_coupon_valid_for_domain_size</a>(<a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules">rules</a>: &<a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_CouponRules">CouponRules</a>, length: u8): bool {
    // If the vec is not set, we pass this rule test.
    <b>if</b>(<a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules">rules</a>.length.is_none()) <b>return</b> <b>true</b>;

    <a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules">rules</a>.length.borrow().is_in_range(length)
}
</code></pre>



</details>

<a name="0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_assert_coupon_valid_for_address"></a>

## Function `assert_coupon_valid_for_address`

Throws <code><a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_EInvalidUser">EInvalidUser</a></code> error if it has expired.


<pre><code><b>public</b> <b>fun</b> <a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_assert_coupon_valid_for_address">assert_coupon_valid_for_address</a>(<a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules">rules</a>: &<a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_CouponRules">rules::CouponRules</a>, user: <b>address</b>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_assert_coupon_valid_for_address">assert_coupon_valid_for_address</a>(<a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules">rules</a>: &<a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_CouponRules">CouponRules</a>, user: <b>address</b>) {
    <b>assert</b>!(<a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_is_coupon_valid_for_address">is_coupon_valid_for_address</a>(<a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules">rules</a>, user), <a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_EInvalidUser">EInvalidUser</a>);
}
</code></pre>



</details>

<a name="0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_is_coupon_valid_for_address"></a>

## Function `is_coupon_valid_for_address`

Check that the domain is valid for the specified address


<pre><code><b>public</b> <b>fun</b> <a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_is_coupon_valid_for_address">is_coupon_valid_for_address</a>(<a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules">rules</a>: &<a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_CouponRules">rules::CouponRules</a>, user: <b>address</b>): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_is_coupon_valid_for_address">is_coupon_valid_for_address</a>(<a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules">rules</a>: &<a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_CouponRules">CouponRules</a>, user: <b>address</b>): bool {
    <b>if</b>(<a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules">rules</a>.user.is_none()) <b>return</b> <b>true</b>;
    <a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules">rules</a>.user.borrow() == user
}
</code></pre>



</details>

<a name="0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_assert_coupon_is_not_expired"></a>

## Function `assert_coupon_is_not_expired`

Simple assertion for the coupon expiration.
Throws <code><a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_ECouponExpired">ECouponExpired</a></code> error if it has expired.


<pre><code><b>public</b> <b>fun</b> <a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_assert_coupon_is_not_expired">assert_coupon_is_not_expired</a>(<a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules">rules</a>: &<a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_CouponRules">rules::CouponRules</a>, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &<a href="dependencies/sui-framework/clock.md#0x2_clock_Clock">clock::Clock</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_assert_coupon_is_not_expired">assert_coupon_is_not_expired</a>(<a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules">rules</a>: &<a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_CouponRules">CouponRules</a>, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &Clock) {
    <b>assert</b>!(!<a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_is_coupon_expired">is_coupon_expired</a>(<a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules">rules</a>, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>), <a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_ECouponExpired">ECouponExpired</a>);
}
</code></pre>



</details>

<a name="0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_is_coupon_expired"></a>

## Function `is_coupon_expired`

Check whether a coupon has expired


<pre><code><b>public</b> <b>fun</b> <a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_is_coupon_expired">is_coupon_expired</a>(<a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules">rules</a>: &<a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_CouponRules">rules::CouponRules</a>, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &<a href="dependencies/sui-framework/clock.md#0x2_clock_Clock">clock::Clock</a>): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_is_coupon_expired">is_coupon_expired</a>(<a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules">rules</a>: &<a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_CouponRules">CouponRules</a>, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &Clock): bool {
    <b>if</b>(<a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules">rules</a>.expiration.is_none()){
        <b>return</b> <b>false</b>
    };

    <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>.timestamp_ms() &gt; *<a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules">rules</a>.expiration.borrow()
}
</code></pre>



</details>

<a name="0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_is_valid_years_range"></a>

## Function `is_valid_years_range`



<pre><code><b>fun</b> <a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_is_valid_years_range">is_valid_years_range</a>(<a href="range.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_range">range</a>: &<a href="dependencies/move-stdlib/option.md#0x1_option_Option">option::Option</a>&lt;<a href="range.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_range_Range">range::Range</a>&gt;): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_is_valid_years_range">is_valid_years_range</a>(<a href="range.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_range">range</a>: &Option&lt;Range&gt;): bool {
    <b>if</b>(<a href="range.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_range">range</a>.is_none()) <b>return</b> <b>true</b>;
    <b>let</b> <a href="range.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_range">range</a> = <a href="range.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_range">range</a>.borrow();
    <a href="range.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_range">range</a>.from() &gt;= 1 && <a href="range.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_range">range</a>.<b>to</b>() &lt;= 5
}
</code></pre>



</details>

<a name="0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_is_valid_length_range"></a>

## Function `is_valid_length_range`



<pre><code><b>fun</b> <a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_is_valid_length_range">is_valid_length_range</a>(<a href="range.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_range">range</a>: &<a href="dependencies/move-stdlib/option.md#0x1_option_Option">option::Option</a>&lt;<a href="range.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_range_Range">range::Range</a>&gt;): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="rules.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_rules_is_valid_length_range">is_valid_length_range</a>(<a href="range.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_range">range</a>: &Option&lt;Range&gt;): bool {
    <b>if</b>(<a href="range.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_range">range</a>.is_none()) <b>return</b> <b>true</b>;
    <b>let</b> <a href="range.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_range">range</a> = <a href="range.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_range">range</a>.borrow();
    <a href="range.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_range">range</a>.from() &gt;= suins_constants::min_domain_length() && <a href="range.md#0xf6859389182791bf8f218ee869ba8225e1d46ea967b301f5c4da6b38d1ba1b46_range">range</a>.<b>to</b>() &lt;= suins_constants::max_domain_length()
}
</code></pre>



</details>
