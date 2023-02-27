
<a name="0x0_coin_util"></a>

# Module `0x0::coin_util`



-  [Function `user_transfer_to_address`](#0x0_coin_util_user_transfer_to_address)
-  [Function `user_transfer_to_contract`](#0x0_coin_util_user_transfer_to_contract)
-  [Function `contract_transfer_to_address`](#0x0_coin_util_contract_transfer_to_address)


<pre><code><b>use</b> <a href="">0x2::balance</a>;
<b>use</b> <a href="">0x2::coin</a>;
<b>use</b> <a href="">0x2::sui</a>;
<b>use</b> <a href="">0x2::transfer</a>;
<b>use</b> <a href="">0x2::tx_context</a>;
</code></pre>



<a name="0x0_coin_util_user_transfer_to_address"></a>

## Function `user_transfer_to_address`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="coin_util.md#0x0_coin_util_user_transfer_to_address">user_transfer_to_address</a>(payment: &<b>mut</b> <a href="_Coin">coin::Coin</a>&lt;<a href="_SUI">sui::SUI</a>&gt;, amount: u64, receiver: <b>address</b>, ctx: &<b>mut</b> <a href="_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="coin_util.md#0x0_coin_util_user_transfer_to_address">user_transfer_to_address</a>(payment: &<b>mut</b> Coin&lt;SUI&gt;, amount: u64, receiver: <b>address</b>, ctx: &<b>mut</b> TxContext) {
    <b>let</b> paid = <a href="_split">coin::split</a>(payment, amount, ctx);
    <a href="_transfer">transfer::transfer</a>(paid, receiver);
}
</code></pre>



</details>

<a name="0x0_coin_util_user_transfer_to_contract"></a>

## Function `user_transfer_to_contract`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="coin_util.md#0x0_coin_util_user_transfer_to_contract">user_transfer_to_contract</a>(payment: &<b>mut</b> <a href="_Coin">coin::Coin</a>&lt;<a href="_SUI">sui::SUI</a>&gt;, amount: u64, receiver: &<b>mut</b> <a href="_Balance">balance::Balance</a>&lt;<a href="_SUI">sui::SUI</a>&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="coin_util.md#0x0_coin_util_user_transfer_to_contract">user_transfer_to_contract</a>(payment: &<b>mut</b> Coin&lt;SUI&gt;, amount: u64, receiver: &<b>mut</b> Balance&lt;SUI&gt;) {
    <b>let</b> coin_balance = <a href="_balance_mut">coin::balance_mut</a>(payment);
    <b>let</b> paid = <a href="_split">balance::split</a>(coin_balance, amount);
    <a href="_join">balance::join</a>(receiver, paid);
}
</code></pre>



</details>

<a name="0x0_coin_util_contract_transfer_to_address"></a>

## Function `contract_transfer_to_address`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="coin_util.md#0x0_coin_util_contract_transfer_to_address">contract_transfer_to_address</a>(<a href="">balance</a>: &<b>mut</b> <a href="_Balance">balance::Balance</a>&lt;<a href="_SUI">sui::SUI</a>&gt;, amount: u64, receiver: <b>address</b>, ctx: &<b>mut</b> <a href="_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="coin_util.md#0x0_coin_util_contract_transfer_to_address">contract_transfer_to_address</a>(<a href="">balance</a>: &<b>mut</b> Balance&lt;SUI&gt;, amount: u64, receiver: <b>address</b>, ctx: &<b>mut</b> TxContext) {
    <b>let</b> <a href="">coin</a> = <a href="_take">coin::take</a>(<a href="">balance</a>, amount, ctx);
    <a href="_transfer">transfer::transfer</a>(<a href="">coin</a>, receiver);
}
</code></pre>



</details>
