
<a name="0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_data"></a>

# Module `0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8::data`



-  [Struct `Data`](#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_data_Data)
-  [Constants](#@Constants_0)
-  [Function `new`](#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_data_new)
-  [Function `save_coupon`](#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_data_save_coupon)
-  [Function `remove_coupon`](#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_data_remove_coupon)
-  [Function `coupons`](#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_data_coupons)
-  [Function `coupons_mut`](#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_data_coupons_mut)


<pre><code><b>use</b> <a href="dependencies/move-stdlib/string.md#0x1_string">0x1::string</a>;
<b>use</b> <a href="dependencies/sui-framework/bag.md#0x2_bag">0x2::bag</a>;
<b>use</b> <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context">0x2::tx_context</a>;
<b>use</b> <a href="coupon.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon">0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8::coupon</a>;
</code></pre>



<a name="0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_data_Data"></a>

## Struct `Data`

Create a <code><a href="data.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_data_Data">Data</a></code> struct that only authorized apps can get mutable access to.
We don't save the coupon's table directly on the shared object, because we want authorized apps to only perform
certain actions with the table (and not give full <code><b>mut</b></code> access to it).


<pre><code><b>struct</b> <a href="data.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_data_Data">Data</a> <b>has</b> store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>coupons: <a href="dependencies/sui-framework/bag.md#0x2_bag_Bag">bag::Bag</a></code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="@Constants_0"></a>

## Constants


<a name="0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_data_ECouponAlreadyExists"></a>



<pre><code><b>const</b> <a href="data.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_data_ECouponAlreadyExists">ECouponAlreadyExists</a>: u64 = 1;
</code></pre>



<a name="0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_data_ECouponDoesNotExist"></a>



<pre><code><b>const</b> <a href="data.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_data_ECouponDoesNotExist">ECouponDoesNotExist</a>: u64 = 2;
</code></pre>



<a name="0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_data_new"></a>

## Function `new`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="data.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_data_new">new</a>(ctx: &<b>mut</b> <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context_TxContext">tx_context::TxContext</a>): <a href="data.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_data_Data">data::Data</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<a href="dependencies/sui-framework/package.md#0x2_package">package</a>) <b>fun</b> <a href="data.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_data_new">new</a>(ctx: &<b>mut</b> TxContext): <a href="data.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_data_Data">Data</a> {
    <a href="data.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_data_Data">Data</a> {
        coupons: <a href="dependencies/sui-framework/bag.md#0x2_bag_new">bag::new</a>(ctx)
    }
}
</code></pre>



</details>

<a name="0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_data_save_coupon"></a>

## Function `save_coupon`

Private internal functions
An internal function to save the coupon in the shared object's config.


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="data.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_data_save_coupon">save_coupon</a>(self: &<b>mut</b> <a href="data.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_data_Data">data::Data</a>, code: <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>, <a href="coupon.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon">coupon</a>: <a href="coupon.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon_Coupon">coupon::Coupon</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<a href="dependencies/sui-framework/package.md#0x2_package">package</a>) <b>fun</b> <a href="data.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_data_save_coupon">save_coupon</a>(
    self: &<b>mut</b> <a href="data.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_data_Data">Data</a>,
    code: String,
    <a href="coupon.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon">coupon</a>: Coupon
) {
    <b>assert</b>!(!self.coupons.contains(code), <a href="data.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_data_ECouponAlreadyExists">ECouponAlreadyExists</a>);
    self.coupons.add(code, <a href="coupon.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_coupon">coupon</a>);
}
</code></pre>



</details>

<a name="0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_data_remove_coupon"></a>

## Function `remove_coupon`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="data.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_data_remove_coupon">remove_coupon</a>(self: &<b>mut</b> <a href="data.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_data_Data">data::Data</a>, code: <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<a href="dependencies/sui-framework/package.md#0x2_package">package</a>) <b>fun</b> <a href="data.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_data_remove_coupon">remove_coupon</a>(self: &<b>mut</b> <a href="data.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_data_Data">Data</a>, code: String) {
    <b>assert</b>!(self.coupons.contains(code), <a href="data.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_data_ECouponDoesNotExist">ECouponDoesNotExist</a>);
    <b>let</b> _: Coupon = self.coupons.remove(code);
}
</code></pre>



</details>

<a name="0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_data_coupons"></a>

## Function `coupons`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="data.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_data_coupons">coupons</a>(<a href="data.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_data">data</a>: &<a href="data.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_data_Data">data::Data</a>): &<a href="dependencies/sui-framework/bag.md#0x2_bag_Bag">bag::Bag</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<a href="dependencies/sui-framework/package.md#0x2_package">package</a>) <b>fun</b> <a href="data.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_data_coupons">coupons</a>(<a href="data.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_data">data</a>: &<a href="data.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_data_Data">Data</a>): &Bag {
    &<a href="data.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_data">data</a>.coupons
}
</code></pre>



</details>

<a name="0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_data_coupons_mut"></a>

## Function `coupons_mut`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="data.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_data_coupons_mut">coupons_mut</a>(<a href="data.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_data">data</a>: &<b>mut</b> <a href="data.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_data_Data">data::Data</a>): &<b>mut</b> <a href="dependencies/sui-framework/bag.md#0x2_bag_Bag">bag::Bag</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<a href="dependencies/sui-framework/package.md#0x2_package">package</a>) <b>fun</b> <a href="data.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_data_coupons_mut">coupons_mut</a>(<a href="data.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_data">data</a>: &<b>mut</b> <a href="data.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_data_Data">Data</a>): &<b>mut</b> Bag {
    &<b>mut</b> <a href="data.md#0xb14b7077dafce4f7a0725cfc6e25fe39bfd76720ab8acefc0c00a8eb12f528f8_data">data</a>.coupons
}
</code></pre>



</details>
