
<a name="0x0_auction"></a>

# Module `0x0::auction`

Implementation of auction module.


-  [Struct `BidDetail`](#0x0_auction_BidDetail)
-  [Struct `AuctionEntry`](#0x0_auction_AuctionEntry)
-  [Resource `Auction`](#0x0_auction_Auction)
-  [Struct `NodeRegisteredEvent`](#0x0_auction_NodeRegisteredEvent)
-  [Struct `NewBidEvent`](#0x0_auction_NewBidEvent)
-  [Struct `BidRevealedEvent`](#0x0_auction_BidRevealedEvent)
-  [Struct `AuctionStartedEvent`](#0x0_auction_AuctionStartedEvent)
-  [Constants](#@Constants_0)
-  [Function `configure_auction`](#0x0_auction_configure_auction)
-  [Function `start_an_auction`](#0x0_auction_start_an_auction)
-  [Function `place_bid`](#0x0_auction_place_bid)
-  [Function `reveal_bid`](#0x0_auction_reveal_bid)
-  [Function `finalize_auction`](#0x0_auction_finalize_auction)
-  [Function `withdraw`](#0x0_auction_withdraw)
-  [Function `make_seal_bid`](#0x0_auction_make_seal_bid)
-  [Function `get_entry`](#0x0_auction_get_entry)
-  [Function `state`](#0x0_auction_state)
-  [Function `auction_close_at`](#0x0_auction_auction_close_at)
-  [Function `is_auction_label_available_for_controller`](#0x0_auction_is_auction_label_available_for_controller)
-  [Function `init`](#0x0_auction_init)
-  [Function `seal_bid_exists`](#0x0_auction_seal_bid_exists)


<pre><code><b>use</b> <a href="base_registrar.md#0x0_base_registrar">0x0::base_registrar</a>;
<b>use</b> <a href="base_registry.md#0x0_base_registry">0x0::base_registry</a>;
<b>use</b> <a href="coin_util.md#0x0_coin_util">0x0::coin_util</a>;
<b>use</b> <a href="configuration.md#0x0_configuration">0x0::configuration</a>;
<b>use</b> <a href="emoji.md#0x0_emoji">0x0::emoji</a>;
<b>use</b> <a href="">0x1::bcs</a>;
<b>use</b> <a href="">0x1::option</a>;
<b>use</b> <a href="">0x1::string</a>;
<b>use</b> <a href="">0x1::vector</a>;
<b>use</b> <a href="">0x2::balance</a>;
<b>use</b> <a href="">0x2::coin</a>;
<b>use</b> <a href="">0x2::event</a>;
<b>use</b> <a href="">0x2::hash</a>;
<b>use</b> <a href="">0x2::object</a>;
<b>use</b> <a href="">0x2::sui</a>;
<b>use</b> <a href="">0x2::table</a>;
<b>use</b> <a href="">0x2::transfer</a>;
<b>use</b> <a href="">0x2::tx_context</a>;
</code></pre>



<a name="0x0_auction_BidDetail"></a>

## Struct `BidDetail`



<pre><code><b>struct</b> <a href="auction.md#0x0_auction_BidDetail">BidDetail</a> <b>has</b> <b>copy</b>, drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>bidder: <b>address</b></code>
</dt>
<dd>

</dd>
<dt>
<code>bid_value_mask: u64</code>
</dt>
<dd>

</dd>
<dt>
<code>bid_value: u64</code>
</dt>
<dd>

</dd>
<dt>
<code>label: <a href="_String">string::String</a></code>
</dt>
<dd>

</dd>
<dt>
<code>created_at: u64</code>
</dt>
<dd>

</dd>
<dt>
<code>sealed_bid: <a href="">vector</a>&lt;u8&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>is_unsealed: bool</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0x0_auction_AuctionEntry"></a>

## Struct `AuctionEntry`

Metadata of auction for a domain name


<pre><code><b>struct</b> <a href="auction.md#0x0_auction_AuctionEntry">AuctionEntry</a> <b>has</b> drop, store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>start_at: u64</code>
</dt>
<dd>

</dd>
<dt>
<code>highest_bid: u64</code>
</dt>
<dd>

</dd>
<dt>
<code>second_highest_bid: u64</code>
</dt>
<dd>

</dd>
<dt>
<code>winner: <b>address</b></code>
</dt>
<dd>

</dd>
<dt>
<code>is_finalized: bool</code>
</dt>
<dd>

</dd>
<dt>
<code>bid_detail_created_at: u64</code>
</dt>
<dd>
 the created_at property of the current winning bid
 if 2 bidders bid same value, we choose the one who called <code>new_bid</code> first
</dd>
</dl>


</details>

<a name="0x0_auction_Auction"></a>

## Resource `Auction`



<pre><code><b>struct</b> <a href="auction.md#0x0_auction_Auction">Auction</a> <b>has</b> key
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
<code>bid_details_by_bidder: <a href="_Table">table::Table</a>&lt;<b>address</b>, <a href="">vector</a>&lt;<a href="auction.md#0x0_auction_BidDetail">auction::BidDetail</a>&gt;&gt;</code>
</dt>
<dd>
 bid_details_by_bidder: {
   0xabc: [bid1, bid2],
   0x123: [bid3, bid4],
 }
</dd>
<dt>
<code>entries: <a href="_Table">table::Table</a>&lt;<a href="_String">string::String</a>, <a href="auction.md#0x0_auction_AuctionEntry">auction::AuctionEntry</a>&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code><a href="">balance</a>: <a href="_Balance">balance::Balance</a>&lt;<a href="_SUI">sui::SUI</a>&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>open_at: u64</code>
</dt>
<dd>

</dd>
<dt>
<code>close_at: u64</code>
</dt>
<dd>
 last epoch where auction for domains can be started
 the auction really ends at = start_auction_end_at + BIDDING_PERIOD + REVEAL_PERIOD + FINALIZING_PERIOD
</dd>
</dl>


</details>

<a name="0x0_auction_NodeRegisteredEvent"></a>

## Struct `NodeRegisteredEvent`



<pre><code><b>struct</b> <a href="auction.md#0x0_auction_NodeRegisteredEvent">NodeRegisteredEvent</a> <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>label: <a href="_String">string::String</a></code>
</dt>
<dd>

</dd>
<dt>
<code>tld: <a href="_String">string::String</a></code>
</dt>
<dd>

</dd>
<dt>
<code>winner: <b>address</b></code>
</dt>
<dd>

</dd>
<dt>
<code>amount: u64</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0x0_auction_NewBidEvent"></a>

## Struct `NewBidEvent`



<pre><code><b>struct</b> <a href="auction.md#0x0_auction_NewBidEvent">NewBidEvent</a> <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>bidder: <b>address</b></code>
</dt>
<dd>

</dd>
<dt>
<code>sealed_bid: <a href="">vector</a>&lt;u8&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>bid_value_mask: u64</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0x0_auction_BidRevealedEvent"></a>

## Struct `BidRevealedEvent`



<pre><code><b>struct</b> <a href="auction.md#0x0_auction_BidRevealedEvent">BidRevealedEvent</a> <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>label: <a href="_String">string::String</a></code>
</dt>
<dd>

</dd>
<dt>
<code>bidder: <b>address</b></code>
</dt>
<dd>

</dd>
<dt>
<code>bid_value: u64</code>
</dt>
<dd>

</dd>
<dt>
<code>created_at: u64</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0x0_auction_AuctionStartedEvent"></a>

## Struct `AuctionStartedEvent`



<pre><code><b>struct</b> <a href="auction.md#0x0_auction_AuctionStartedEvent">AuctionStartedEvent</a> <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>label: <a href="_String">string::String</a></code>
</dt>
<dd>

</dd>
<dt>
<code>start_at: u64</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="@Constants_0"></a>

## Constants


<a name="0x0_auction_AUCTION_STATE_BIDDING"></a>



<pre><code><b>const</b> <a href="auction.md#0x0_auction_AUCTION_STATE_BIDDING">AUCTION_STATE_BIDDING</a>: u8 = 3;
</code></pre>



<a name="0x0_auction_AUCTION_STATE_FINALIZING"></a>



<pre><code><b>const</b> <a href="auction.md#0x0_auction_AUCTION_STATE_FINALIZING">AUCTION_STATE_FINALIZING</a>: u8 = 5;
</code></pre>



<a name="0x0_auction_AUCTION_STATE_NOT_AVAILABLE"></a>



<pre><code><b>const</b> <a href="auction.md#0x0_auction_AUCTION_STATE_NOT_AVAILABLE">AUCTION_STATE_NOT_AVAILABLE</a>: u8 = 0;
</code></pre>



<a name="0x0_auction_AUCTION_STATE_OPEN"></a>



<pre><code><b>const</b> <a href="auction.md#0x0_auction_AUCTION_STATE_OPEN">AUCTION_STATE_OPEN</a>: u8 = 1;
</code></pre>



<a name="0x0_auction_AUCTION_STATE_OWNED"></a>



<pre><code><b>const</b> <a href="auction.md#0x0_auction_AUCTION_STATE_OWNED">AUCTION_STATE_OWNED</a>: u8 = 6;
</code></pre>



<a name="0x0_auction_AUCTION_STATE_PENDING"></a>



<pre><code><b>const</b> <a href="auction.md#0x0_auction_AUCTION_STATE_PENDING">AUCTION_STATE_PENDING</a>: u8 = 2;
</code></pre>



<a name="0x0_auction_AUCTION_STATE_REOPENED"></a>



<pre><code><b>const</b> <a href="auction.md#0x0_auction_AUCTION_STATE_REOPENED">AUCTION_STATE_REOPENED</a>: u8 = 7;
</code></pre>



<a name="0x0_auction_AUCTION_STATE_REVEAL"></a>



<pre><code><b>const</b> <a href="auction.md#0x0_auction_AUCTION_STATE_REVEAL">AUCTION_STATE_REVEAL</a>: u8 = 4;
</code></pre>



<a name="0x0_auction_BIDDING_PERIOD"></a>



<pre><code><b>const</b> <a href="auction.md#0x0_auction_BIDDING_PERIOD">BIDDING_PERIOD</a>: u64 = 3;
</code></pre>



<a name="0x0_auction_EAlreadyFinalized"></a>



<pre><code><b>const</b> <a href="auction.md#0x0_auction_EAlreadyFinalized">EAlreadyFinalized</a>: u64 = 811;
</code></pre>



<a name="0x0_auction_EAlreadyUnsealed"></a>



<pre><code><b>const</b> <a href="auction.md#0x0_auction_EAlreadyUnsealed">EAlreadyUnsealed</a>: u64 = 812;
</code></pre>



<a name="0x0_auction_EAuctionNotAvailable"></a>



<pre><code><b>const</b> <a href="auction.md#0x0_auction_EAuctionNotAvailable">EAuctionNotAvailable</a>: u64 = 803;
</code></pre>



<a name="0x0_auction_EBidAlreadyStart"></a>



<pre><code><b>const</b> <a href="auction.md#0x0_auction_EBidAlreadyStart">EBidAlreadyStart</a>: u64 = 806;
</code></pre>



<a name="0x0_auction_EBidExisted"></a>



<pre><code><b>const</b> <a href="auction.md#0x0_auction_EBidExisted">EBidExisted</a>: u64 = 804;
</code></pre>



<a name="0x0_auction_EInvalidBid"></a>



<pre><code><b>const</b> <a href="auction.md#0x0_auction_EInvalidBid">EInvalidBid</a>: u64 = 805;
</code></pre>



<a name="0x0_auction_EInvalidBidMask"></a>



<pre><code><b>const</b> <a href="auction.md#0x0_auction_EInvalidBidMask">EInvalidBidMask</a>: u64 = 807;
</code></pre>



<a name="0x0_auction_EInvalidBidValue"></a>



<pre><code><b>const</b> <a href="auction.md#0x0_auction_EInvalidBidValue">EInvalidBidValue</a>: u64 = 807;
</code></pre>



<a name="0x0_auction_EInvalidConfigParam"></a>



<pre><code><b>const</b> <a href="auction.md#0x0_auction_EInvalidConfigParam">EInvalidConfigParam</a>: u64 = 808;
</code></pre>



<a name="0x0_auction_EInvalidPhase"></a>



<pre><code><b>const</b> <a href="auction.md#0x0_auction_EInvalidPhase">EInvalidPhase</a>: u64 = 802;
</code></pre>



<a name="0x0_auction_EInvalidRegistrar"></a>



<pre><code><b>const</b> <a href="auction.md#0x0_auction_EInvalidRegistrar">EInvalidRegistrar</a>: u64 = 809;
</code></pre>



<a name="0x0_auction_ESealBidNotExists"></a>



<pre><code><b>const</b> <a href="auction.md#0x0_auction_ESealBidNotExists">ESealBidNotExists</a>: u64 = 813;
</code></pre>



<a name="0x0_auction_EShouldNotHappen"></a>



<pre><code><b>const</b> <a href="auction.md#0x0_auction_EShouldNotHappen">EShouldNotHappen</a>: u64 = 810;
</code></pre>



<a name="0x0_auction_EXTRA_PERIOD"></a>

time period from end_at, so winner have time to claim their winning


<pre><code><b>const</b> <a href="auction.md#0x0_auction_EXTRA_PERIOD">EXTRA_PERIOD</a>: u64 = 30;
</code></pre>



<a name="0x0_auction_FEE_PER_YEAR"></a>



<pre><code><b>const</b> <a href="auction.md#0x0_auction_FEE_PER_YEAR">FEE_PER_YEAR</a>: u64 = 10000;
</code></pre>



<a name="0x0_auction_MIN_PRICE"></a>



<pre><code><b>const</b> <a href="auction.md#0x0_auction_MIN_PRICE">MIN_PRICE</a>: u64 = 1000;
</code></pre>



<a name="0x0_auction_REVEAL_PERIOD"></a>



<pre><code><b>const</b> <a href="auction.md#0x0_auction_REVEAL_PERIOD">REVEAL_PERIOD</a>: u64 = 3;
</code></pre>



<a name="0x0_auction_configure_auction"></a>

## Function `configure_auction`


<a name="@Notice_1"></a>

###### Notice

The admin uses this function to establish configuration parameters.
It is intended solely for use during the development phase.


<a name="@Dev_2"></a>

###### Dev

The <code>open_at</code> and <code>close_at</code> properties of Auction share object are updated.


<a name="@Params_3"></a>

###### Params

<code>open_at</code>: epoch at which all names are available for auction.
<code>close_at</code>: the last epoch at which all names remain available for auction.
Once this epoch has passed, the entries that have a winner but haven't yet being finalized
have an additional <code>EXTRA_CLAIM_PERIOD</code> epochs for the winner to finalize.


<a name="@Panics_4"></a>

###### Panics

Panics if <code>open_at</code> is less than <code>close_at</code>
or current epoch is less than or equal <code>open_at</code>


<pre><code><b>public</b> entry <b>fun</b> <a href="auction.md#0x0_auction_configure_auction">configure_auction</a>(_: &<a href="base_registry.md#0x0_base_registry_AdminCap">base_registry::AdminCap</a>, <a href="auction.md#0x0_auction">auction</a>: &<b>mut</b> <a href="auction.md#0x0_auction_Auction">auction::Auction</a>, open_at: u64, close_at: u64, ctx: &<b>mut</b> <a href="_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="auction.md#0x0_auction_configure_auction">configure_auction</a>(
    _: &AdminCap,
    <a href="auction.md#0x0_auction">auction</a>: &<b>mut</b> <a href="auction.md#0x0_auction_Auction">Auction</a>,
    open_at: u64,
    close_at: u64,
    ctx: &<b>mut</b> TxContext
) {
    <b>assert</b>!(open_at &lt; close_at, <a href="auction.md#0x0_auction_EInvalidConfigParam">EInvalidConfigParam</a>);
    <b>assert</b>!(epoch(ctx) &lt;= open_at, <a href="auction.md#0x0_auction_EInvalidConfigParam">EInvalidConfigParam</a>);

    <a href="auction.md#0x0_auction">auction</a>.open_at = open_at;
    <a href="auction.md#0x0_auction">auction</a>.close_at = close_at;
}
</code></pre>



</details>

<a name="0x0_auction_start_an_auction"></a>

## Function `start_an_auction`


<a name="@Notice_5"></a>

###### Notice

This function initiates the auction process for a <code>.<a href="">sui</a></code> node.
However, the caller must still call <code>place_bid</code> to place his/her bid.
When the auction starts, a new entry is created in the <code>PENDING</code> state.
In the next epoch, it moves to the <code>BIDDING</code> state.
The caller also transfers a payment of coins worth <code><a href="auction.md#0x0_auction_FEE_PER_YEAR">FEE_PER_YEAR</a></code>.


<a name="@Dev_6"></a>

###### Dev

New <code>Entry</code> record is created.
If <code>Entry</code> record exists and in the <code>REOPENED</code> state, it is remove and reinitialize.


<a name="@Params_7"></a>

###### Params

<code>label</code>: label of the node being auctioned, the node has the form <code>label</code>.sui


<a name="@Panics_8"></a>

###### Panics

Panics if current epoch is outside of auction time period
or the node is already opened
or the node is not eligible for auction.
or the length of the label must be within the range of 3-6 characters.


<pre><code><b>public</b> entry <b>fun</b> <a href="auction.md#0x0_auction_start_an_auction">start_an_auction</a>(<a href="auction.md#0x0_auction">auction</a>: &<b>mut</b> <a href="auction.md#0x0_auction_Auction">auction::Auction</a>, config: &<a href="configuration.md#0x0_configuration_Configuration">configuration::Configuration</a>, label: <a href="">vector</a>&lt;u8&gt;, payment: &<b>mut</b> <a href="_Coin">coin::Coin</a>&lt;<a href="_SUI">sui::SUI</a>&gt;, ctx: &<b>mut</b> <a href="_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="auction.md#0x0_auction_start_an_auction">start_an_auction</a>(
    <a href="auction.md#0x0_auction">auction</a>: &<b>mut</b> <a href="auction.md#0x0_auction_Auction">Auction</a>,
    config: &Configuration,
    label: <a href="">vector</a>&lt;u8&gt;,
    payment: &<b>mut</b> Coin&lt;SUI&gt;,
    ctx: &<b>mut</b> TxContext
) {
    // TODO: should we enforce the current epoch &lt;= <a href="auction.md#0x0_auction">auction</a>.close_at - <a href="auction.md#0x0_auction_BIDDING_PERIOD">BIDDING_PERIOD</a> - <a href="auction.md#0x0_auction_REVEAL_PERIOD">REVEAL_PERIOD</a>?
    <b>assert</b>!(
        <a href="auction.md#0x0_auction">auction</a>.open_at &lt;= epoch(ctx) && epoch(ctx) &lt;= <a href="auction.md#0x0_auction">auction</a>.close_at,
        <a href="auction.md#0x0_auction_EAuctionNotAvailable">EAuctionNotAvailable</a>,
    );
    <b>let</b> emoji_config = <a href="configuration.md#0x0_configuration_emoji_config">configuration::emoji_config</a>(config);
    <a href="emoji.md#0x0_emoji_validate_label_with_emoji">emoji::validate_label_with_emoji</a>(emoji_config, label, 3, 6);

    <b>let</b> state = <a href="auction.md#0x0_auction_state">state</a>(<a href="auction.md#0x0_auction">auction</a>, label, epoch(ctx));
    <b>assert</b>!(state == <a href="auction.md#0x0_auction_AUCTION_STATE_OPEN">AUCTION_STATE_OPEN</a> || state == <a href="auction.md#0x0_auction_AUCTION_STATE_REOPENED">AUCTION_STATE_REOPENED</a>, <a href="auction.md#0x0_auction_EInvalidPhase">EInvalidPhase</a>);

    <b>let</b> label = utf8(label);
    <b>if</b> (state == <a href="auction.md#0x0_auction_AUCTION_STATE_REOPENED">AUCTION_STATE_REOPENED</a>) {
        // added in below statement
        // TODO: reset fields instead of removing them
        <b>let</b> _ = <a href="_remove">table::remove</a>(&<b>mut</b> <a href="auction.md#0x0_auction">auction</a>.entries, label);
    };
    <b>let</b> start_at = epoch(ctx) + 1;
    <b>let</b> entry = <a href="auction.md#0x0_auction_AuctionEntry">AuctionEntry</a> {
        start_at,
        highest_bid: 0,
        second_highest_bid: 0,
        winner: @0x0,
        is_finalized: <b>false</b>,
        bid_detail_created_at: 0,
    };
    <a href="_add">table::add</a>(&<b>mut</b> <a href="auction.md#0x0_auction">auction</a>.entries, label, entry);
    <a href="_emit">event::emit</a>(<a href="auction.md#0x0_auction_AuctionStartedEvent">AuctionStartedEvent</a> { label, start_at });

    <a href="coin_util.md#0x0_coin_util_user_transfer_to_contract">coin_util::user_transfer_to_contract</a>(payment, <a href="auction.md#0x0_auction_FEE_PER_YEAR">FEE_PER_YEAR</a>, &<b>mut</b> <a href="auction.md#0x0_auction">auction</a>.<a href="">balance</a>)
}
</code></pre>



</details>

<a name="0x0_auction_place_bid"></a>

## Function `place_bid`


<a name="@Notice_9"></a>

###### Notice

Bidders use this function to place a new bid.
They transfer a payment of coins with a value equal to the bid value mask to hide the actual bid amount.


<a name="@Dev_10"></a>

###### Dev

New bid detail is created.


<a name="@Params_11"></a>

###### Params

<code>sealed_bid</code>: return value of <code>make_seal_bid</code>
<code>bid_value_mask</code>: upper bound of actual bid value


<a name="@Panics_12"></a>

###### Panics

Panics if current epoch is less than end_at
or <code>bid_value_mask</code> is less than <code><a href="auction.md#0x0_auction_MIN_PRICE">MIN_PRICE</a></code>
or the sealed bid exists
or payment doesn't have enough coin


<pre><code><b>public</b> entry <b>fun</b> <a href="auction.md#0x0_auction_place_bid">place_bid</a>(<a href="auction.md#0x0_auction">auction</a>: &<b>mut</b> <a href="auction.md#0x0_auction_Auction">auction::Auction</a>, sealed_bid: <a href="">vector</a>&lt;u8&gt;, bid_value_mask: u64, payment: &<b>mut</b> <a href="_Coin">coin::Coin</a>&lt;<a href="_SUI">sui::SUI</a>&gt;, ctx: &<b>mut</b> <a href="_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="auction.md#0x0_auction_place_bid">place_bid</a>(
    <a href="auction.md#0x0_auction">auction</a>: &<b>mut</b> <a href="auction.md#0x0_auction_Auction">Auction</a>,
    sealed_bid: <a href="">vector</a>&lt;u8&gt;,
    bid_value_mask: u64,
    payment: &<b>mut</b> Coin&lt;SUI&gt;,
    ctx: &<b>mut</b> TxContext
) {
    // TODO: should we enforce the current epoch &lt;= <a href="auction.md#0x0_auction">auction</a>.close_at - <a href="auction.md#0x0_auction_REVEAL_PERIOD">REVEAL_PERIOD</a>?
    <b>assert</b>!(
        <a href="auction.md#0x0_auction">auction</a>.open_at &lt;= epoch(ctx) && epoch(ctx) &lt;= <a href="auction.md#0x0_auction">auction</a>.close_at,
        <a href="auction.md#0x0_auction_EAuctionNotAvailable">EAuctionNotAvailable</a>,
    );
    <b>assert</b>!(bid_value_mask &gt;= <a href="auction.md#0x0_auction_MIN_PRICE">MIN_PRICE</a>, <a href="auction.md#0x0_auction_EInvalidBid">EInvalidBid</a>);

    <b>if</b> (!<a href="_contains">table::contains</a>(&<a href="auction.md#0x0_auction">auction</a>.bid_details_by_bidder, sender(ctx))) {
        <a href="_add">table::add</a>(&<b>mut</b> <a href="auction.md#0x0_auction">auction</a>.bid_details_by_bidder, sender(ctx), <a href="">vector</a>[]);
    };

    <b>let</b> bids_by_sender = <a href="_borrow_mut">table::borrow_mut</a>(&<b>mut</b> <a href="auction.md#0x0_auction">auction</a>.bid_details_by_bidder, sender(ctx));
    <b>assert</b>!(<a href="_is_none">option::is_none</a>(&<a href="auction.md#0x0_auction_seal_bid_exists">seal_bid_exists</a>(bids_by_sender, sealed_bid)), <a href="auction.md#0x0_auction_EBidExisted">EBidExisted</a>);

    <b>let</b> bidder = sender(ctx);
    <b>let</b> bid = <a href="auction.md#0x0_auction_BidDetail">BidDetail</a> {
        bidder,
        bid_value_mask,
        bid_value: 0,
        label: utf8(<a href="">vector</a>[]),
        created_at: epoch(ctx),
        sealed_bid,
        is_unsealed: <b>false</b>,
    };
    <a href="_push_back">vector::push_back</a>(bids_by_sender, bid);
    <a href="_emit">event::emit</a>(<a href="auction.md#0x0_auction_NewBidEvent">NewBidEvent</a> { bidder, sealed_bid, bid_value_mask });

    <a href="coin_util.md#0x0_coin_util_user_transfer_to_contract">coin_util::user_transfer_to_contract</a>(payment, bid_value_mask, &<b>mut</b> <a href="auction.md#0x0_auction">auction</a>.<a href="">balance</a>)
}
</code></pre>



</details>

<a name="0x0_auction_reveal_bid"></a>

## Function `reveal_bid`


<a name="@Notice_13"></a>

###### Notice

Bidders use this function to reveal the true parameters of their sealed bids.
No payment is returned in this function.
Bidders can retrieve their payment by using either the <code>finalize_auction</code> or <code>withdraw</code> function.


<a name="@Dev_14"></a>

###### Dev

The <code>Entry</code> record represeting the <code>label</code> is updated with the new bid value if <code>value</code> is either the highest
or second highest value.
The <code>label</code> and <code>bid_value</code> properties of the bid detail are updated.


<a name="@Params_15"></a>

###### Params

<code>label</code>: label of the node being auctioned, the node has the form <code>label</code>.sui
<code>value</code>: auctual value that bidder wants to spend
<code>salt</code>: random string used when hashing the sealed bid


<a name="@Panics_16"></a>

###### Panics

Panics if auction is not in <code>REVEAL</code> state
or sender has never ever placed a bid
or the parameters don't match any sealed bid
or the sealed bid has already been unsealed
or <code>label</code> hasn't been started


<pre><code><b>public</b> entry <b>fun</b> <a href="auction.md#0x0_auction_reveal_bid">reveal_bid</a>(<a href="auction.md#0x0_auction">auction</a>: &<b>mut</b> <a href="auction.md#0x0_auction_Auction">auction::Auction</a>, label: <a href="">vector</a>&lt;u8&gt;, value: u64, salt: <a href="">vector</a>&lt;u8&gt;, ctx: &<b>mut</b> <a href="_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="auction.md#0x0_auction_reveal_bid">reveal_bid</a>(
    <a href="auction.md#0x0_auction">auction</a>: &<b>mut</b> <a href="auction.md#0x0_auction_Auction">Auction</a>,
    label: <a href="">vector</a>&lt;u8&gt;,
    value: u64,
    salt: <a href="">vector</a>&lt;u8&gt;,
    ctx: &<b>mut</b> TxContext
) {
    <b>assert</b>!(
        <a href="auction.md#0x0_auction">auction</a>.open_at &lt;= epoch(ctx) && epoch(ctx) &lt;= <a href="auction.md#0x0_auction">auction</a>.close_at,
        <a href="auction.md#0x0_auction_EAuctionNotAvailable">EAuctionNotAvailable</a>,
    );
    // TODO: do we need <b>to</b> validate domain here?
    <b>let</b> auction_state = <a href="auction.md#0x0_auction_state">state</a>(<a href="auction.md#0x0_auction">auction</a>, label, epoch(ctx));
    <b>assert</b>!(auction_state == <a href="auction.md#0x0_auction_AUCTION_STATE_REVEAL">AUCTION_STATE_REVEAL</a>, <a href="auction.md#0x0_auction_EInvalidPhase">EInvalidPhase</a>);

    <b>let</b> seal_bid = <a href="auction.md#0x0_auction_make_seal_bid">make_seal_bid</a>(label, sender(ctx), value, salt); // <a href="">hash</a> from label, owner, value, salt
    <b>let</b> bids_by_sender = <a href="_borrow_mut">table::borrow_mut</a>(&<b>mut</b> <a href="auction.md#0x0_auction">auction</a>.bid_details_by_bidder, sender(ctx));
    <b>let</b> index = <a href="auction.md#0x0_auction_seal_bid_exists">seal_bid_exists</a>(bids_by_sender, seal_bid);
    <b>assert</b>!(<a href="_is_some">option::is_some</a>(&index), <a href="auction.md#0x0_auction_ESealBidNotExists">ESealBidNotExists</a>);

    <b>let</b> bid_detail = <a href="_borrow_mut">vector::borrow_mut</a>(bids_by_sender, <a href="_extract">option::extract</a>(&<b>mut</b> index));
    <b>assert</b>!(!bid_detail.is_unsealed, <a href="auction.md#0x0_auction_EAlreadyUnsealed">EAlreadyUnsealed</a>);

    <b>let</b> label = utf8(label);
    <a href="_emit">event::emit</a>(<a href="auction.md#0x0_auction_BidRevealedEvent">BidRevealedEvent</a> {
        label,
        bidder: sender(ctx),
        bid_value: value,
        created_at: bid_detail.created_at,
    });

    <b>let</b> entry = <a href="_borrow_mut">table::borrow_mut</a>(&<b>mut</b> <a href="auction.md#0x0_auction">auction</a>.entries, *&label);
    <b>if</b> (
        bid_detail.bid_value_mask &lt; value
            || value &lt; <a href="auction.md#0x0_auction_MIN_PRICE">MIN_PRICE</a>
            || bid_detail.created_at &lt; entry.start_at
            || entry.start_at + <a href="auction.md#0x0_auction_BIDDING_PERIOD">BIDDING_PERIOD</a> &lt;= bid_detail.created_at
    ) {
        // invalid bid
        // TODO: what <b>to</b> do now?
    } <b>else</b> <b>if</b> (value &gt; entry.highest_bid) {
        // Vickrey <a href="auction.md#0x0_auction">auction</a>, winner pays the second highest_bid
        entry.second_highest_bid = entry.highest_bid;
        entry.highest_bid = value;
        entry.winner = bid_detail.bidder;
        entry.bid_detail_created_at = bid_detail.created_at;
    } <b>else</b> <b>if</b> (value == entry.highest_bid && bid_detail.created_at &lt; entry.bid_detail_created_at) {
        // <b>if</b> same value and same created_at, we <b>choose</b> first one who reveals bid.
        // TODO: could be combined <b>with</b> the previous check
        entry.second_highest_bid = entry.highest_bid;
        entry.highest_bid = value;
        entry.winner = bid_detail.bidder;
        entry.bid_detail_created_at = bid_detail.created_at;
    } <b>else</b> <b>if</b> (value &gt; entry.second_highest_bid) {
        // not winner, but affects second place
        entry.second_highest_bid = value;
    } <b>else</b> {
        // bid doesn't affect <a href="auction.md#0x0_auction">auction</a>
        // TODO: what <b>to</b> do now?
    };
    bid_detail.bid_value = value;
    bid_detail.label = label;
    bid_detail.is_unsealed = <b>true</b>;
}
</code></pre>



</details>

<a name="0x0_auction_finalize_auction"></a>

## Function `finalize_auction`


<a name="@Notice_17"></a>

###### Notice

Bidders use this function to claim the NFT or withdraw payment of their bids on <code>label</code>.
If being called by the winner, he/she retrieve the payment that are the difference between bid mask and bid value.
He/she also get the NFT representing the ownership of <code>label</code>.sui node.
If not the winner, he/she get back the payment that he/her deposited when place the bid.
We allow bidders to have multiple bids on one domain, this function checks every of them.


<a name="@Dev_18"></a>

###### Dev

All bid details that are considered in this function are removed.


<a name="@Params_19"></a>

###### Params

label label of the node beinng auctioned, the node has the form <code>label</code>.sui
resolver address of the resolver share object that the winner wants to set for his/her new NFT


<a name="@Panics_20"></a>

###### Panics

Panics if auction state is not <code>FINALIZING</code>, <code>REOPENED</code> or <code>OWNED</code>
or sender has never ever placed a bid
or <code>label</code> hasn't been started
or the auction has already been finalized and sender is the winner


<pre><code><b>public</b> entry <b>fun</b> <a href="auction.md#0x0_auction_finalize_auction">finalize_auction</a>(<a href="auction.md#0x0_auction">auction</a>: &<b>mut</b> <a href="auction.md#0x0_auction_Auction">auction::Auction</a>, registrar: &<b>mut</b> <a href="base_registrar.md#0x0_base_registrar_BaseRegistrar">base_registrar::BaseRegistrar</a>, registry: &<b>mut</b> <a href="base_registry.md#0x0_base_registry_Registry">base_registry::Registry</a>, config: &<a href="configuration.md#0x0_configuration_Configuration">configuration::Configuration</a>, label: <a href="">vector</a>&lt;u8&gt;, <a href="resolver.md#0x0_resolver">resolver</a>: <b>address</b>, ctx: &<b>mut</b> <a href="_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="auction.md#0x0_auction_finalize_auction">finalize_auction</a>(
    <a href="auction.md#0x0_auction">auction</a>: &<b>mut</b> <a href="auction.md#0x0_auction_Auction">Auction</a>,
    registrar: &<b>mut</b> BaseRegistrar,
    registry: &<b>mut</b> Registry,
    config: &Configuration,
    label: <a href="">vector</a>&lt;u8&gt;,
    <a href="resolver.md#0x0_resolver">resolver</a>: <b>address</b>,
    ctx: &<b>mut</b> TxContext
) {
    <b>assert</b>!(
        <a href="auction.md#0x0_auction">auction</a>.open_at &lt;= epoch(ctx) && epoch(ctx) &lt;= <a href="auction.md#0x0_auction">auction</a>.close_at + <a href="auction.md#0x0_auction_EXTRA_PERIOD">EXTRA_PERIOD</a>,
        <a href="auction.md#0x0_auction_EAuctionNotAvailable">EAuctionNotAvailable</a>,
    );
    <b>assert</b>!(<a href="base_registrar.md#0x0_base_registrar_base_node_bytes">base_registrar::base_node_bytes</a>(registrar) == b"<a href="">sui</a>", <a href="auction.md#0x0_auction_EInvalidRegistrar">EInvalidRegistrar</a>);
    <b>let</b> auction_state = <a href="auction.md#0x0_auction_state">state</a>(<a href="auction.md#0x0_auction">auction</a>, label, epoch(ctx));
    // the reveal phase is over in all of these phases and have received bids
    <b>assert</b>!(
        auction_state == <a href="auction.md#0x0_auction_AUCTION_STATE_FINALIZING">AUCTION_STATE_FINALIZING</a>
            || auction_state == <a href="auction.md#0x0_auction_AUCTION_STATE_REOPENED">AUCTION_STATE_REOPENED</a>
            || auction_state == <a href="auction.md#0x0_auction_AUCTION_STATE_OWNED">AUCTION_STATE_OWNED</a>,
        <a href="auction.md#0x0_auction_EInvalidPhase">EInvalidPhase</a>
    );

    <b>let</b> label_str = utf8(label);
    <b>let</b> entry = <a href="_borrow_mut">table::borrow_mut</a>(&<b>mut</b> <a href="auction.md#0x0_auction">auction</a>.entries, label_str);
    <b>assert</b>!(!(entry.is_finalized && entry.winner == sender(ctx)), <a href="auction.md#0x0_auction_EAlreadyFinalized">EAlreadyFinalized</a>);

    <b>let</b> bids_of_sender = <a href="_borrow_mut">table::borrow_mut</a>(&<b>mut</b> <a href="auction.md#0x0_auction">auction</a>.bid_details_by_bidder, sender(ctx));

    // Refund all the bids
    // TODO: consider removing bids_of_sender <b>if</b> being empty
    <b>let</b> len = <a href="_length">vector::length</a>(bids_of_sender);
    <b>let</b> index = 0;
    <b>while</b> (index &lt; len) {
        <b>if</b> (<a href="_borrow">vector::borrow</a>(bids_of_sender, index).label != label_str) {
            index = index + 1;
            <b>continue</b>
        };

        <b>let</b> detail = <a href="_remove">vector::remove</a>(bids_of_sender, index);
        len = len - 1;
        <b>if</b> (
            entry.winner == detail.bidder
                && entry.highest_bid == detail.bid_value
                && detail.bid_value_mask - detail.bid_value &gt; 0
        ) {
            <b>if</b> (entry.second_highest_bid != 0) {
                <a href="coin_util.md#0x0_coin_util_contract_transfer_to_address">coin_util::contract_transfer_to_address</a>(
                    &<b>mut</b> <a href="auction.md#0x0_auction">auction</a>.<a href="">balance</a>,
                    detail.bid_value_mask - entry.second_highest_bid,
                    detail.bidder,
                    ctx
                );
            } <b>else</b> {
                // winner is the only one who bided
                <a href="coin_util.md#0x0_coin_util_contract_transfer_to_address">coin_util::contract_transfer_to_address</a>(
                    &<b>mut</b> <a href="auction.md#0x0_auction">auction</a>.<a href="">balance</a>,
                    detail.bid_value_mask - detail.bid_value,
                    detail.bidder,
                    ctx
                );
            }
        } <b>else</b> {
            // TODO: charge paymennt <b>as</b> punishmennt
            <a href="coin_util.md#0x0_coin_util_contract_transfer_to_address">coin_util::contract_transfer_to_address</a>(
                &<b>mut</b> <a href="auction.md#0x0_auction">auction</a>.<a href="">balance</a>,
                detail.bid_value_mask,
                detail.bidder,
                ctx
            );
        };
    };
    <b>if</b> (entry.winner != sender(ctx)) <b>return</b>;
    entry.is_finalized = <b>true</b>;

    <a href="base_registrar.md#0x0_base_registrar_register">base_registrar::register</a>(registrar, registry, config, label, entry.winner, 365, <a href="resolver.md#0x0_resolver">resolver</a>, ctx);

    <a href="_emit">event::emit</a>(<a href="auction.md#0x0_auction_NodeRegisteredEvent">NodeRegisteredEvent</a> {
        label: label_str,
        tld: utf8(b"<a href="">sui</a>"),
        winner: entry.winner,
        amount: entry.second_highest_bid
    })
}
</code></pre>



</details>

<a name="0x0_auction_withdraw"></a>

## Function `withdraw`


<a name="@Notice_21"></a>

###### Notice

Bidders use this function to withdraw all their remaining bids.
If there is any entry in which the sender is the winner and not yet finalized and still in <code><a href="auction.md#0x0_auction_EXTRA_PERIOD">EXTRA_PERIOD</a></code>,
skip that winning bid (For these bids, bidders have to call <code>finalize_auction</code> to get their extra payment and NFT).


<a name="@Dev_22"></a>

###### Dev

The admin doesn't use this function to withdraw balance.
All bid details that are considered are removed.


<a name="@Panics_23"></a>

###### Panics

Panics if current epoch is less than or equal end_at
or sender has never ever placed a bid


<pre><code><b>public</b> entry <b>fun</b> <a href="auction.md#0x0_auction_withdraw">withdraw</a>(<a href="auction.md#0x0_auction">auction</a>: &<b>mut</b> <a href="auction.md#0x0_auction_Auction">auction::Auction</a>, ctx: &<b>mut</b> <a href="_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> entry <b>fun</b> <a href="auction.md#0x0_auction_withdraw">withdraw</a>(<a href="auction.md#0x0_auction">auction</a>: &<b>mut</b> <a href="auction.md#0x0_auction_Auction">Auction</a>, ctx: &<b>mut</b> TxContext) {
    <b>assert</b>!(epoch(ctx) &gt; <a href="auction.md#0x0_auction">auction</a>.close_at, <a href="auction.md#0x0_auction_EInvalidPhase">EInvalidPhase</a>);

    <b>let</b> bid_details = <a href="_borrow_mut">table::borrow_mut</a>(&<b>mut</b> <a href="auction.md#0x0_auction">auction</a>.bid_details_by_bidder, sender(ctx));
    <b>let</b> len = <a href="_length">vector::length</a>(bid_details);
    <b>let</b> index = 0;

    <b>while</b> (index &lt; len) {
        <b>let</b> detail = <a href="_borrow">vector::borrow</a>(bid_details, index);

        <b>if</b> (<a href="_contains">table::contains</a>(&<a href="auction.md#0x0_auction">auction</a>.entries, detail.label)) {
            <b>let</b> entry = <a href="_borrow">table::borrow</a>(&<a href="auction.md#0x0_auction">auction</a>.entries, detail.label);
            <b>if</b> (
                !entry.is_finalized
                    && entry.winner == sender(ctx)
                    && <a href="auction.md#0x0_auction">auction</a>.close_at + <a href="auction.md#0x0_auction_EXTRA_PERIOD">EXTRA_PERIOD</a> &gt; epoch(ctx)
                    && detail.bid_value == entry.highest_bid // bidder can bid multiple times on same domain
            ) {
                index = index + 1;
                <b>continue</b>
            };
        };
        // TODO: <a href="">transfer</a> all balances at once
        <a href="coin_util.md#0x0_coin_util_contract_transfer_to_address">coin_util::contract_transfer_to_address</a>(
            &<b>mut</b> <a href="auction.md#0x0_auction">auction</a>.<a href="">balance</a>,
            detail.bid_value_mask,
            detail.bidder,
            ctx
        );
        <a href="_remove">vector::remove</a>(bid_details, index);
        len = len - 1;
    };
    // TODO: consider removing `sender(ctx)` key from `bid_details_by_bidder` <b>if</b> `bid_details` is empty
}
</code></pre>



</details>

<a name="0x0_auction_make_seal_bid"></a>

## Function `make_seal_bid`


<a name="@Notice_24"></a>

###### Notice

Generate the sealed bid that is used when placing a new bid


<a name="@Params_25"></a>

###### Params

<code>label</code>: label of the node being auctioned, the node has the form <code>label</code>.sui
<code>owner</code>: address of the bidder
<code>value</code>: bid value
<code>salt</code>: a random string


<a name="@Return_26"></a>

###### Return

Hashed string using keccak256


<pre><code><b>public</b> <b>fun</b> <a href="auction.md#0x0_auction_make_seal_bid">make_seal_bid</a>(label: <a href="">vector</a>&lt;u8&gt;, owner: <b>address</b>, value: u64, salt: <a href="">vector</a>&lt;u8&gt;): <a href="">vector</a>&lt;u8&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="auction.md#0x0_auction_make_seal_bid">make_seal_bid</a>(label: <a href="">vector</a>&lt;u8&gt;, owner: <b>address</b>, value: u64, salt: <a href="">vector</a>&lt;u8&gt;): <a href="">vector</a>&lt;u8&gt; {
    <b>let</b> owner = <a href="_to_bytes">bcs::to_bytes</a>(&owner);
    <a href="_append">vector::append</a>(&<b>mut</b> label, owner);
    <b>let</b> value = <a href="_to_bytes">bcs::to_bytes</a>(&value);
    <a href="_append">vector::append</a>(&<b>mut</b> label, value);
    <a href="_append">vector::append</a>(&<b>mut</b> label, salt);
    keccak256(&label)
}
</code></pre>



</details>

<a name="0x0_auction_get_entry"></a>

## Function `get_entry`


<a name="@Notice_27"></a>

###### Notice

Get metadata of an auction


<a name="@Params_28"></a>

###### Params

label label of the node being auctioned, the node has the form <code>label</code>.sui


<a name="@Return_29"></a>

###### Return

(<code>start_at</code>, <code>highest_bid</code>, <code>second_highest_bid</code>, <code>winner</code>, <code>is_finalized</code>)


<pre><code><b>public</b> <b>fun</b> <a href="auction.md#0x0_auction_get_entry">get_entry</a>(<a href="auction.md#0x0_auction">auction</a>: &<a href="auction.md#0x0_auction_Auction">auction::Auction</a>, label: <a href="">vector</a>&lt;u8&gt;): (<a href="_Option">option::Option</a>&lt;u64&gt;, <a href="_Option">option::Option</a>&lt;u64&gt;, <a href="_Option">option::Option</a>&lt;u64&gt;, <a href="_Option">option::Option</a>&lt;<b>address</b>&gt;, <a href="_Option">option::Option</a>&lt;bool&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="auction.md#0x0_auction_get_entry">get_entry</a>(
    <a href="auction.md#0x0_auction">auction</a>: &<a href="auction.md#0x0_auction_Auction">Auction</a>,
    label: <a href="">vector</a>&lt;u8&gt;
): (Option&lt;u64&gt;, Option&lt;u64&gt;, Option&lt;u64&gt;, Option&lt;<b>address</b>&gt;, Option&lt;bool&gt;) {
    <b>let</b> label = utf8(label);
    <b>if</b> (<a href="_contains">table::contains</a>(&<a href="auction.md#0x0_auction">auction</a>.entries, label)) {
        <b>let</b> entry = <a href="_borrow">table::borrow</a>(&<a href="auction.md#0x0_auction">auction</a>.entries, label);
        <b>return</b> (
            some(entry.start_at),
            some(entry.highest_bid),
            some(entry.second_highest_bid),
            some(entry.winner),
            some(entry.is_finalized),
        )
    };
    (none(), none(), none(), none(), none())
}
</code></pre>



</details>

<a name="0x0_auction_state"></a>

## Function `state`


<a name="@Notice_30"></a>

###### Notice

Get state of an auction
State transitions for node can be found at <code>../../../docs/README.md</code>


<a name="@Params_31"></a>

###### Params

label label of the node being auctioned, the node has the form <code>label</code>.sui


<a name="@Return_32"></a>

###### Return

either [
AUCTION_STATE_NOT_AVAILABLE | AUCTION_STATE_OPEN | AUCTION_STATE_PENDING | AUCTION_STATE_BIDDING |
AUCTION_STATE_REVEAL | AUCTION_STATE_FINALIZING | AUCTION_STATE_OWNED | AUCTION_STATE_REOPENED
]


<pre><code><b>public</b> <b>fun</b> <a href="auction.md#0x0_auction_state">state</a>(<a href="auction.md#0x0_auction">auction</a>: &<a href="auction.md#0x0_auction_Auction">auction::Auction</a>, label: <a href="">vector</a>&lt;u8&gt;, current_epoch: u64): u8
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="auction.md#0x0_auction_state">state</a>(<a href="auction.md#0x0_auction">auction</a>: &<a href="auction.md#0x0_auction_Auction">Auction</a>, label: <a href="">vector</a>&lt;u8&gt;, current_epoch: u64): u8 {
    <b>let</b> label = utf8(label);
    <b>if</b> (current_epoch &lt; <a href="auction.md#0x0_auction">auction</a>.open_at || current_epoch &gt; <a href="auction.md#0x0_auction">auction</a>.close_at + <a href="auction.md#0x0_auction_EXTRA_PERIOD">EXTRA_PERIOD</a>) <b>return</b> <a href="auction.md#0x0_auction_AUCTION_STATE_NOT_AVAILABLE">AUCTION_STATE_NOT_AVAILABLE</a>;
    <b>let</b> is_entry_existed = <a href="_contains">table::contains</a>(&<a href="auction.md#0x0_auction">auction</a>.entries, label);
    // TODO: start_an_auction doesn't enforce the current epoch <b>to</b> guarantee a valid <a href="auction.md#0x0_auction">auction</a> entry.
    <b>if</b> (current_epoch &gt; <a href="auction.md#0x0_auction">auction</a>.close_at && is_entry_existed) {
        <b>let</b> entry = <a href="_borrow">table::borrow</a>(&<a href="auction.md#0x0_auction">auction</a>.entries, label);

        <b>if</b> (entry.is_finalized) <b>return</b> <a href="auction.md#0x0_auction_AUCTION_STATE_OWNED">AUCTION_STATE_OWNED</a>;
        <b>if</b> (current_epoch &lt; entry.start_at + <a href="auction.md#0x0_auction_BIDDING_PERIOD">BIDDING_PERIOD</a> + <a href="auction.md#0x0_auction_REVEAL_PERIOD">REVEAL_PERIOD</a>) <b>return</b> <a href="auction.md#0x0_auction_AUCTION_STATE_NOT_AVAILABLE">AUCTION_STATE_NOT_AVAILABLE</a>;
        <b>if</b> (entry.highest_bid == 0) <b>return</b> <a href="auction.md#0x0_auction_AUCTION_STATE_NOT_AVAILABLE">AUCTION_STATE_NOT_AVAILABLE</a>;
        <b>return</b> <a href="auction.md#0x0_auction_AUCTION_STATE_FINALIZING">AUCTION_STATE_FINALIZING</a>
    };

    <b>if</b> (is_entry_existed) {
        <b>let</b> entry = <a href="_borrow">table::borrow</a>(&<a href="auction.md#0x0_auction">auction</a>.entries, label);

        <b>if</b> (entry.is_finalized) <b>return</b> <a href="auction.md#0x0_auction_AUCTION_STATE_OWNED">AUCTION_STATE_OWNED</a>;
        <b>if</b> (current_epoch == entry.start_at - 1) <b>return</b> <a href="auction.md#0x0_auction_AUCTION_STATE_PENDING">AUCTION_STATE_PENDING</a>;
        <b>if</b> (current_epoch &lt; entry.start_at + <a href="auction.md#0x0_auction_BIDDING_PERIOD">BIDDING_PERIOD</a>) <b>return</b> <a href="auction.md#0x0_auction_AUCTION_STATE_BIDDING">AUCTION_STATE_BIDDING</a>;
        <b>if</b> (current_epoch &lt; entry.start_at + <a href="auction.md#0x0_auction_BIDDING_PERIOD">BIDDING_PERIOD</a> + <a href="auction.md#0x0_auction_REVEAL_PERIOD">REVEAL_PERIOD</a>) <b>return</b> <a href="auction.md#0x0_auction_AUCTION_STATE_REVEAL">AUCTION_STATE_REVEAL</a>;
        // TODO: because <a href="auction.md#0x0_auction">auction</a> can be reopened, there is a case
        // TODO: <b>where</b> only 1 user places bid and his bid is invalid
        <b>if</b> (entry.highest_bid == 0) <b>return</b> <a href="auction.md#0x0_auction_AUCTION_STATE_REOPENED">AUCTION_STATE_REOPENED</a>;
        <b>return</b> <a href="auction.md#0x0_auction_AUCTION_STATE_FINALIZING">AUCTION_STATE_FINALIZING</a>
    };
    <b>if</b> (current_epoch &gt; <a href="auction.md#0x0_auction">auction</a>.close_at) <b>return</b> <a href="auction.md#0x0_auction_AUCTION_STATE_NOT_AVAILABLE">AUCTION_STATE_NOT_AVAILABLE</a>;
    <a href="auction.md#0x0_auction_AUCTION_STATE_OPEN">AUCTION_STATE_OPEN</a>
}
</code></pre>



</details>

<a name="0x0_auction_auction_close_at"></a>

## Function `auction_close_at`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="auction.md#0x0_auction_auction_close_at">auction_close_at</a>(<a href="auction.md#0x0_auction">auction</a>: &<a href="auction.md#0x0_auction_Auction">auction::Auction</a>): u64
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="auction.md#0x0_auction_auction_close_at">auction_close_at</a>(<a href="auction.md#0x0_auction">auction</a>: &<a href="auction.md#0x0_auction_Auction">Auction</a>): u64 {
    <a href="auction.md#0x0_auction">auction</a>.close_at
}
</code></pre>



</details>

<a name="0x0_auction_is_auction_label_available_for_controller"></a>

## Function `is_auction_label_available_for_controller`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="auction.md#0x0_auction_is_auction_label_available_for_controller">is_auction_label_available_for_controller</a>(<a href="auction.md#0x0_auction">auction</a>: &<a href="auction.md#0x0_auction_Auction">auction::Auction</a>, label: <a href="_String">string::String</a>, ctx: &<a href="_TxContext">tx_context::TxContext</a>): bool
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="auction.md#0x0_auction_is_auction_label_available_for_controller">is_auction_label_available_for_controller</a>(<a href="auction.md#0x0_auction">auction</a>: &<a href="auction.md#0x0_auction_Auction">Auction</a>, label: String, ctx: &TxContext): bool {
    <b>if</b> (<a href="auction.md#0x0_auction">auction</a>.close_at &gt;= epoch(ctx)) <b>return</b> <b>false</b>;
    <b>if</b> (<a href="auction.md#0x0_auction">auction</a>.close_at + <a href="auction.md#0x0_auction_EXTRA_PERIOD">EXTRA_PERIOD</a> &lt; epoch(ctx)) <b>return</b> <b>true</b>;
    <b>if</b> (<a href="_contains">table::contains</a>(&<a href="auction.md#0x0_auction">auction</a>.entries, label)) {
        <b>let</b> entry = <a href="_borrow">table::borrow</a>(&<a href="auction.md#0x0_auction">auction</a>.entries, label);
        <b>if</b> (!entry.is_finalized) <b>return</b> <b>false</b>
    };
    <b>true</b>
}
</code></pre>



</details>

<a name="0x0_auction_init"></a>

## Function `init`



<pre><code><b>fun</b> <a href="auction.md#0x0_auction_init">init</a>(ctx: &<b>mut</b> <a href="_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="auction.md#0x0_auction_init">init</a>(ctx: &<b>mut</b> TxContext) {
    <a href="_share_object">transfer::share_object</a>(<a href="auction.md#0x0_auction_Auction">Auction</a> {
        id: <a href="_new">object::new</a>(ctx),
        bid_details_by_bidder: <a href="_new">table::new</a>(ctx),
        entries: <a href="_new">table::new</a>(ctx),
        <a href="">balance</a>: <a href="_zero">balance::zero</a>(),
        open_at: 0,
        close_at: 0,
    });
}
</code></pre>



</details>

<a name="0x0_auction_seal_bid_exists"></a>

## Function `seal_bid_exists`

Return index of bid if exists


<pre><code><b>fun</b> <a href="auction.md#0x0_auction_seal_bid_exists">seal_bid_exists</a>(bids: &<a href="">vector</a>&lt;<a href="auction.md#0x0_auction_BidDetail">auction::BidDetail</a>&gt;, seal_bid: <a href="">vector</a>&lt;u8&gt;): <a href="_Option">option::Option</a>&lt;u64&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="auction.md#0x0_auction_seal_bid_exists">seal_bid_exists</a>(bids: &<a href="">vector</a>&lt;<a href="auction.md#0x0_auction_BidDetail">BidDetail</a>&gt;, seal_bid: <a href="">vector</a>&lt;u8&gt;): Option&lt;u64&gt; {
    <b>let</b> len = <a href="_length">vector::length</a>(bids);
    <b>let</b> index = 0;

    <b>while</b> (index &lt; len) {
        <b>let</b> detail = <a href="_borrow">vector::borrow</a>(bids, index);
        <b>if</b> (detail.sealed_bid == seal_bid) {
            <b>return</b> some(index)
        };
        index = index + 1;
    };
    none()
}
</code></pre>



</details>
