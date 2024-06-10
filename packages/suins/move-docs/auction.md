
<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction"></a>

# Module `0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94::auction`

Implementation of auction module.
More information in: ../../../docs


-  [Struct `App`](#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_App)
-  [Resource `AuctionHouse`](#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_AuctionHouse)
-  [Struct `Auction`](#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_Auction)
-  [Struct `AuctionStartedEvent`](#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_AuctionStartedEvent)
-  [Struct `AuctionFinalizedEvent`](#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_AuctionFinalizedEvent)
-  [Struct `BidEvent`](#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_BidEvent)
-  [Struct `AuctionExtendedEvent`](#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_AuctionExtendedEvent)
-  [Constants](#@Constants_0)
-  [Function `init`](#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_init)
-  [Function `start_auction_and_place_bid`](#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_start_auction_and_place_bid)
-  [Function `place_bid`](#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_place_bid)
-  [Function `claim`](#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_claim)
-  [Function `get_auction_metadata`](#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_get_auction_metadata)
-  [Function `collect_winning_auction_fund`](#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_collect_winning_auction_fund)
-  [Function `admin_withdraw_funds`](#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_admin_withdraw_funds)
-  [Function `admin_finalize_auction`](#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_admin_finalize_auction)
-  [Function `admin_finalize_auction_internal`](#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_admin_finalize_auction_internal)
-  [Function `admin_try_finalize_auctions`](#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_admin_try_finalize_auctions)


<pre><code><b>use</b> <a href="dependencies/move-stdlib/option.md#0x1_option">0x1::option</a>;
<b>use</b> <a href="dependencies/move-stdlib/string.md#0x1_string">0x1::string</a>;
<b>use</b> <a href="dependencies/sui-framework/balance.md#0x2_balance">0x2::balance</a>;
<b>use</b> <a href="dependencies/sui-framework/clock.md#0x2_clock">0x2::clock</a>;
<b>use</b> <a href="dependencies/sui-framework/coin.md#0x2_coin">0x2::coin</a>;
<b>use</b> <a href="dependencies/sui-framework/event.md#0x2_event">0x2::event</a>;
<b>use</b> <a href="dependencies/sui-framework/linked_table.md#0x2_linked_table">0x2::linked_table</a>;
<b>use</b> <a href="dependencies/sui-framework/object.md#0x2_object">0x2::object</a>;
<b>use</b> <a href="dependencies/sui-framework/sui.md#0x2_sui">0x2::sui</a>;
<b>use</b> <a href="dependencies/sui-framework/transfer.md#0x2_transfer">0x2::transfer</a>;
<b>use</b> <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context">0x2::tx_context</a>;
<b>use</b> <a href="config.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_config">0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94::config</a>;
<b>use</b> <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94::domain</a>;
<b>use</b> <a href="registry.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_registry">0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94::registry</a>;
<b>use</b> <a href="suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94::suins</a>;
<b>use</b> <a href="suins_registration.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_registration">0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94::suins_registration</a>;
</code></pre>



<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_App"></a>

## Struct `App`

Authorization witness to call protected functions of suins.


<pre><code><b>struct</b> <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_App">App</a> <b>has</b> drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>dummy_field: bool</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_AuctionHouse"></a>

## Resource `AuctionHouse`

The AuctionHouse application.


<pre><code><b>struct</b> <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_AuctionHouse">AuctionHouse</a> <b>has</b> store, key
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>id: <a href="dependencies/sui-framework/object.md#0x2_object_UID">object::UID</a></code>
</dt>
<dd>

</dd>
<dt>
<code><a href="dependencies/sui-framework/balance.md#0x2_balance">balance</a>: <a href="dependencies/sui-framework/balance.md#0x2_balance_Balance">balance::Balance</a>&lt;<a href="dependencies/sui-framework/sui.md#0x2_sui_SUI">sui::SUI</a>&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>auctions: <a href="dependencies/sui-framework/linked_table.md#0x2_linked_table_LinkedTable">linked_table::LinkedTable</a>&lt;<a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_Domain">domain::Domain</a>, <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_Auction">auction::Auction</a>&gt;</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_Auction"></a>

## Struct `Auction`

The Auction application.


<pre><code><b>struct</b> <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_Auction">Auction</a> <b>has</b> store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code><a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a>: <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_Domain">domain::Domain</a></code>
</dt>
<dd>

</dd>
<dt>
<code>start_timestamp_ms: u64</code>
</dt>
<dd>

</dd>
<dt>
<code>end_timestamp_ms: u64</code>
</dt>
<dd>

</dd>
<dt>
<code>winner: <b>address</b></code>
</dt>
<dd>

</dd>
<dt>
<code>current_bid: <a href="dependencies/sui-framework/coin.md#0x2_coin_Coin">coin::Coin</a>&lt;<a href="dependencies/sui-framework/sui.md#0x2_sui_SUI">sui::SUI</a>&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>nft: <a href="suins_registration.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_registration_SuinsRegistration">suins_registration::SuinsRegistration</a></code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_AuctionStartedEvent"></a>

## Struct `AuctionStartedEvent`



<pre><code><b>struct</b> <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_AuctionStartedEvent">AuctionStartedEvent</a> <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code><a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a>: <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_Domain">domain::Domain</a></code>
</dt>
<dd>

</dd>
<dt>
<code>start_timestamp_ms: u64</code>
</dt>
<dd>

</dd>
<dt>
<code>end_timestamp_ms: u64</code>
</dt>
<dd>

</dd>
<dt>
<code>starting_bid: u64</code>
</dt>
<dd>

</dd>
<dt>
<code>bidder: <b>address</b></code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_AuctionFinalizedEvent"></a>

## Struct `AuctionFinalizedEvent`



<pre><code><b>struct</b> <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_AuctionFinalizedEvent">AuctionFinalizedEvent</a> <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code><a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a>: <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_Domain">domain::Domain</a></code>
</dt>
<dd>

</dd>
<dt>
<code>start_timestamp_ms: u64</code>
</dt>
<dd>

</dd>
<dt>
<code>end_timestamp_ms: u64</code>
</dt>
<dd>

</dd>
<dt>
<code>winning_bid: u64</code>
</dt>
<dd>

</dd>
<dt>
<code>winner: <b>address</b></code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_BidEvent"></a>

## Struct `BidEvent`



<pre><code><b>struct</b> <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_BidEvent">BidEvent</a> <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code><a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a>: <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_Domain">domain::Domain</a></code>
</dt>
<dd>

</dd>
<dt>
<code>bid: u64</code>
</dt>
<dd>

</dd>
<dt>
<code>bidder: <b>address</b></code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_AuctionExtendedEvent"></a>

## Struct `AuctionExtendedEvent`



<pre><code><b>struct</b> <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_AuctionExtendedEvent">AuctionExtendedEvent</a> <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code><a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a>: <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_Domain">domain::Domain</a></code>
</dt>
<dd>

</dd>
<dt>
<code>end_timestamp_ms: u64</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="@Constants_0"></a>

## Constants


<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_ENoProfits"></a>



<pre><code><b>const</b> <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_ENoProfits">ENoProfits</a>: u64 = 13;
</code></pre>



<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_AUCTION_BIDDING_PERIOD_MS"></a>

The auction bidding period is 2 days.


<pre><code><b>const</b> <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_AUCTION_BIDDING_PERIOD_MS">AUCTION_BIDDING_PERIOD_MS</a>: u64 = 172800000;
</code></pre>



<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_AUCTION_MIN_QUIET_PERIOD_MS"></a>

The auction quiet period is 10 minutes.


<pre><code><b>const</b> <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_AUCTION_MIN_QUIET_PERIOD_MS">AUCTION_MIN_QUIET_PERIOD_MS</a>: u64 = 600000;
</code></pre>



<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_DEFAULT_DURATION"></a>

One year is the default duration for a domain.


<pre><code><b>const</b> <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_DEFAULT_DURATION">DEFAULT_DURATION</a>: u8 = 1;
</code></pre>



<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_EAuctionEnded"></a>



<pre><code><b>const</b> <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_EAuctionEnded">EAuctionEnded</a>: u64 = 9;
</code></pre>



<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_EAuctionNotEndedYet"></a>



<pre><code><b>const</b> <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_EAuctionNotEndedYet">EAuctionNotEndedYet</a>: u64 = 8;
</code></pre>



<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_EAuctionNotStarted"></a>

Placing a bid in a not started


<pre><code><b>const</b> <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_EAuctionNotStarted">EAuctionNotStarted</a>: u64 = 7;
</code></pre>



<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_EAuctionStarted"></a>

Trying to start an action but it's already started.


<pre><code><b>const</b> <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_EAuctionStarted">EAuctionStarted</a>: u64 = 1;
</code></pre>



<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_EBidAmountTooLow"></a>



<pre><code><b>const</b> <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_EBidAmountTooLow">EBidAmountTooLow</a>: u64 = 12;
</code></pre>



<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_EInvalidBidValue"></a>

The bid value is too low (compared to min_bid or previous bid).


<pre><code><b>const</b> <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_EInvalidBidValue">EInvalidBidValue</a>: u64 = 0;
</code></pre>



<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_ENotWinner"></a>



<pre><code><b>const</b> <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_ENotWinner">ENotWinner</a>: u64 = 10;
</code></pre>



<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_EWinnerCannotPlaceBid"></a>



<pre><code><b>const</b> <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_EWinnerCannotPlaceBid">EWinnerCannotPlaceBid</a>: u64 = 11;
</code></pre>



<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_init"></a>

## Function `init`



<pre><code><b>fun</b> <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_init">init</a>(ctx: &<b>mut</b> <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_init">init</a>(ctx: &<b>mut</b> TxContext) {
    sui::transfer::share_object(<a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_AuctionHouse">AuctionHouse</a> {
        id: <a href="dependencies/sui-framework/object.md#0x2_object_new">object::new</a>(ctx),
        <a href="dependencies/sui-framework/balance.md#0x2_balance">balance</a>: <a href="dependencies/sui-framework/balance.md#0x2_balance_zero">balance::zero</a>(),
        auctions: <a href="dependencies/sui-framework/linked_table.md#0x2_linked_table_new">linked_table::new</a>(ctx),
    });
}
</code></pre>



</details>

<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_start_auction_and_place_bid"></a>

## Function `start_auction_and_place_bid`

Start an auction if it's not started yet; and make the first bid.


<pre><code><b>public</b> <b>fun</b> <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_start_auction_and_place_bid">start_auction_and_place_bid</a>(self: &<b>mut</b> <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_AuctionHouse">auction::AuctionHouse</a>, <a href="suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>: &<b>mut</b> <a href="suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_SuiNS">suins::SuiNS</a>, domain_name: <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>, bid: <a href="dependencies/sui-framework/coin.md#0x2_coin_Coin">coin::Coin</a>&lt;<a href="dependencies/sui-framework/sui.md#0x2_sui_SUI">sui::SUI</a>&gt;, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &<a href="dependencies/sui-framework/clock.md#0x2_clock_Clock">clock::Clock</a>, ctx: &<b>mut</b> <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_start_auction_and_place_bid">start_auction_and_place_bid</a>(
    self: &<b>mut</b> <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_AuctionHouse">AuctionHouse</a>,
    <a href="suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>: &<b>mut</b> SuiNS,
    domain_name: String,
    bid: Coin&lt;SUI&gt;,
    <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &Clock,
    ctx: &<b>mut</b> TxContext,
) {
    <a href="suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>.assert_app_is_authorized&lt;<a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_App">App</a>&gt;();

    <b>let</b> <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a> = <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_new">domain::new</a>(domain_name);

    // make sure the <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a> is a .<a href="dependencies/sui-framework/sui.md#0x2_sui">sui</a> <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a> and not a subdomain
    <a href="config.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_config_assert_valid_user_registerable_domain">config::assert_valid_user_registerable_domain</a>(&<a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a>);

    <b>assert</b>!(!self.auctions.contains(<a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a>), <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_EAuctionStarted">EAuctionStarted</a>);

    // The minimum price only applies <b>to</b> newly created auctions
    <b>let</b> <a href="config.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_config">config</a> = <a href="suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>.get_config&lt;Config&gt;();
    <b>let</b> label = <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a>.sld();
    <b>let</b> min_price = <a href="config.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_config">config</a>.calculate_price((label.length() <b>as</b> u8), <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_DEFAULT_DURATION">DEFAULT_DURATION</a>);
    <b>assert</b>!(bid.value() &gt;= min_price, <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_EInvalidBidValue">EInvalidBidValue</a>);

    <b>let</b> <a href="registry.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_registry">registry</a> = <a href="suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_app_registry_mut">suins::app_registry_mut</a>&lt;<a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_App">App</a>, Registry&gt;(<a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_App">App</a> {}, <a href="suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>);
    <b>let</b> nft = <a href="registry.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_registry">registry</a>.add_record(<a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a>, <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_DEFAULT_DURATION">DEFAULT_DURATION</a>, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>, ctx);
    <b>let</b> starting_bid = bid.value();

    <b>let</b> <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction">auction</a> = <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_Auction">Auction</a> {
        <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a>,
        start_timestamp_ms: <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>.timestamp_ms(),
        end_timestamp_ms: <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>.timestamp_ms() + <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_AUCTION_BIDDING_PERIOD_MS">AUCTION_BIDDING_PERIOD_MS</a>,
        winner: ctx.sender(),
        current_bid: bid,
        nft,
    };

    <a href="dependencies/sui-framework/event.md#0x2_event_emit">event::emit</a>(<a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_AuctionStartedEvent">AuctionStartedEvent</a> {
        <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a>,
        start_timestamp_ms: <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction">auction</a>.start_timestamp_ms,
        end_timestamp_ms: <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction">auction</a>.end_timestamp_ms,
        starting_bid,
        bidder: <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction">auction</a>.winner,
    });

    self.auctions.push_front(<a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a>, <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction">auction</a>)
}
</code></pre>



</details>

<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_place_bid"></a>

## Function `place_bid`


<a name="@Notice_1"></a>

###### Notice

Bidders use this function to place a new bid.

Panics
Panics if <code><a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a></code> is invalid
or there isn't an auction for <code><a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a></code>
or <code>bid</code> is too low,


<pre><code><b>public</b> <b>fun</b> <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_place_bid">place_bid</a>(self: &<b>mut</b> <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_AuctionHouse">auction::AuctionHouse</a>, domain_name: <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>, bid: <a href="dependencies/sui-framework/coin.md#0x2_coin_Coin">coin::Coin</a>&lt;<a href="dependencies/sui-framework/sui.md#0x2_sui_SUI">sui::SUI</a>&gt;, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &<a href="dependencies/sui-framework/clock.md#0x2_clock_Clock">clock::Clock</a>, ctx: &<b>mut</b> <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_place_bid">place_bid</a>(
    self: &<b>mut</b> <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_AuctionHouse">AuctionHouse</a>,
    domain_name: String,
    bid: Coin&lt;SUI&gt;,
    <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &Clock,
    ctx: &<b>mut</b> TxContext
) {
    <b>let</b> <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a> = <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_new">domain::new</a>(domain_name);
    <b>let</b> bidder = ctx.sender();

    <b>assert</b>!(self.auctions.contains(<a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a>), <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_EAuctionNotStarted">EAuctionNotStarted</a>);

    <b>let</b> <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_Auction">Auction</a> {
        <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a>,
        start_timestamp_ms,
        <b>mut</b> end_timestamp_ms,
        winner,
        current_bid,
        nft,
    } = self.auctions.remove(<a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a>);

    // Ensure that the <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction">auction</a> is not over
    <b>assert</b>!(<a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>.timestamp_ms() &lt;= end_timestamp_ms, <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_EAuctionEnded">EAuctionEnded</a>);
    // Ensure the bidder isn't already the winner
    <b>assert</b>!(bidder != winner, <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_EWinnerCannotPlaceBid">EWinnerCannotPlaceBid</a>);

    // get the current highest bid and ensure that the new bid is greater than the current winning bid
    <b>let</b> current_winning_bid = current_bid.value();
    <b>let</b> bid_amount = bid.value();
    <b>assert</b>!(bid_amount &gt; current_winning_bid, <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_EBidAmountTooLow">EBidAmountTooLow</a>);

    // Return the previous winner their bid
    sui::transfer::public_transfer(current_bid, winner);

    <a href="dependencies/sui-framework/event.md#0x2_event_emit">event::emit</a>(<a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_BidEvent">BidEvent</a> {
        <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a>,
        bid: bid_amount,
        bidder,
    });

    // If there is less than `<a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_AUCTION_MIN_QUIET_PERIOD_MS">AUCTION_MIN_QUIET_PERIOD_MS</a>` time left on the <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction">auction</a>
    // then extend the <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction">auction</a> so that there is `<a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_AUCTION_MIN_QUIET_PERIOD_MS">AUCTION_MIN_QUIET_PERIOD_MS</a>` left.
    // Auctions can't be finished until there is at least `<a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_AUCTION_MIN_QUIET_PERIOD_MS">AUCTION_MIN_QUIET_PERIOD_MS</a>`
    // time <b>where</b> there are no bids.
    <b>if</b> (end_timestamp_ms - <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>.timestamp_ms() &lt; <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_AUCTION_MIN_QUIET_PERIOD_MS">AUCTION_MIN_QUIET_PERIOD_MS</a>) {
        <b>let</b> new_end_timestamp_ms = <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>.timestamp_ms() + <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_AUCTION_MIN_QUIET_PERIOD_MS">AUCTION_MIN_QUIET_PERIOD_MS</a>;

        // Only extend the <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction">auction</a> <b>if</b> the new <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction">auction</a> end time is before
        // the NFT's expiration timestamp
        <b>if</b> (new_end_timestamp_ms &lt; nft.expiration_timestamp_ms()) {
            end_timestamp_ms = new_end_timestamp_ms;

            <a href="dependencies/sui-framework/event.md#0x2_event_emit">event::emit</a>(<a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_AuctionExtendedEvent">AuctionExtendedEvent</a> {
                <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a>,
                end_timestamp_ms: end_timestamp_ms,
            });
        }
    };

    <b>let</b> <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction">auction</a> = <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_Auction">Auction</a> {
        <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a>,
        start_timestamp_ms,
        end_timestamp_ms,
        winner: <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context_sender">tx_context::sender</a>(ctx),
        current_bid: bid,
        nft,
    };

    self.auctions.push_front(<a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a>, <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction">auction</a>);
}
</code></pre>



</details>

<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_claim"></a>

## Function `claim`


<a name="@Notice_2"></a>

###### Notice

Auction winner can come and claim the NFT

Panics
sender is not the winner


<pre><code><b>public</b> <b>fun</b> <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_claim">claim</a>(self: &<b>mut</b> <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_AuctionHouse">auction::AuctionHouse</a>, domain_name: <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &<a href="dependencies/sui-framework/clock.md#0x2_clock_Clock">clock::Clock</a>, ctx: &<b>mut</b> <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context_TxContext">tx_context::TxContext</a>): <a href="suins_registration.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_registration_SuinsRegistration">suins_registration::SuinsRegistration</a>
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_claim">claim</a>(
    self: &<b>mut</b> <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_AuctionHouse">AuctionHouse</a>,
    domain_name: String,
    <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &Clock,
    ctx: &<b>mut</b> TxContext
): SuinsRegistration {
    <b>let</b> <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a> = <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_new">domain::new</a>(domain_name);

    <b>let</b> <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_Auction">Auction</a> {
        <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a>: _,
        start_timestamp_ms,
        end_timestamp_ms,
        winner,
        current_bid,
        nft,
    } = self.auctions.remove(<a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a>);

    // Ensure that the <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction">auction</a> is over
    <b>assert</b>!(<a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>.timestamp_ms() &gt; end_timestamp_ms, <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_EAuctionNotEndedYet">EAuctionNotEndedYet</a>);

    // Ensure the sender is the winner
    <b>assert</b>!(ctx.sender() == winner, <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_ENotWinner">ENotWinner</a>);

    <a href="dependencies/sui-framework/event.md#0x2_event_emit">event::emit</a>(<a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_AuctionFinalizedEvent">AuctionFinalizedEvent</a> {
        <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a>,
        start_timestamp_ms,
        end_timestamp_ms,
        winning_bid: <a href="dependencies/sui-framework/coin.md#0x2_coin_value">coin::value</a>(&current_bid),
        winner,
    });

    // Extract the NFT and their bid, returning the NFT <b>to</b> the user
    // and sending the proceeds of the <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction">auction</a> <b>to</b> <a href="suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins">suins</a>
    self.<a href="dependencies/sui-framework/balance.md#0x2_balance">balance</a>.join(current_bid.into_balance());
    nft
}
</code></pre>



</details>

<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_get_auction_metadata"></a>

## Function `get_auction_metadata`


<a name="@Notice_3"></a>

###### Notice

Get metadata of an auction


<a name="@Params_4"></a>

###### Params

The domain name being auctioned.


<a name="@Return_5"></a>

###### Return

(<code>start_timestamp_ms</code>, <code>end_timestamp_ms</code>, <code>winner</code>, <code>highest_amount</code>)


<pre><code><b>public</b> <b>fun</b> <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_get_auction_metadata">get_auction_metadata</a>(self: &<a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_AuctionHouse">auction::AuctionHouse</a>, domain_name: <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>): (<a href="dependencies/move-stdlib/option.md#0x1_option_Option">option::Option</a>&lt;u64&gt;, <a href="dependencies/move-stdlib/option.md#0x1_option_Option">option::Option</a>&lt;u64&gt;, <a href="dependencies/move-stdlib/option.md#0x1_option_Option">option::Option</a>&lt;<b>address</b>&gt;, <a href="dependencies/move-stdlib/option.md#0x1_option_Option">option::Option</a>&lt;u64&gt;)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_get_auction_metadata">get_auction_metadata</a>(
    self: &<a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_AuctionHouse">AuctionHouse</a>,
    domain_name: String,
): (Option&lt;u64&gt;, Option&lt;u64&gt;, Option&lt;<b>address</b>&gt;, Option&lt;u64&gt;) {
    <b>let</b> <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a> = <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_new">domain::new</a>(domain_name);

    <b>if</b> (self.auctions.contains(<a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a>)) {
        <b>let</b> <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction">auction</a> = &self.auctions[<a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a>];
        <b>let</b> highest_amount = <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction">auction</a>.current_bid.value();
        <b>return</b> (
            some(<a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction">auction</a>.start_timestamp_ms),
            some(<a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction">auction</a>.end_timestamp_ms),
            some(<a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction">auction</a>.winner),
            some(highest_amount)
        )
    };
    (none(), none(), none(), none())
}
</code></pre>



</details>

<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_collect_winning_auction_fund"></a>

## Function `collect_winning_auction_fund`



<pre><code><b>public</b> <b>fun</b> <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_collect_winning_auction_fund">collect_winning_auction_fund</a>(self: &<b>mut</b> <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_AuctionHouse">auction::AuctionHouse</a>, domain_name: <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &<a href="dependencies/sui-framework/clock.md#0x2_clock_Clock">clock::Clock</a>, ctx: &<b>mut</b> <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context_TxContext">tx_context::TxContext</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_collect_winning_auction_fund">collect_winning_auction_fund</a>(
    self: &<b>mut</b> <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_AuctionHouse">AuctionHouse</a>,
    domain_name: String,
    <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &Clock,
    ctx: &<b>mut</b> TxContext,
) {
    <b>let</b> <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a> = <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_new">domain::new</a>(domain_name);
    <b>let</b> <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction">auction</a> = &<b>mut</b> self.auctions[<a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a>];
    // Ensure that the <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction">auction</a> is over
    <b>assert</b>!(<a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>.timestamp_ms() &gt; <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction">auction</a>.end_timestamp_ms, <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_EAuctionNotEndedYet">EAuctionNotEndedYet</a>);

    <b>let</b> amount = <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction">auction</a>.current_bid.value();
    self.<a href="dependencies/sui-framework/balance.md#0x2_balance">balance</a>.join(<a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction">auction</a>.current_bid.split(amount, ctx).into_balance());
}
</code></pre>



</details>

<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_admin_withdraw_funds"></a>

## Function `admin_withdraw_funds`



<pre><code><b>public</b> <b>fun</b> <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_admin_withdraw_funds">admin_withdraw_funds</a>(_: &<a href="suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_AdminCap">suins::AdminCap</a>, self: &<b>mut</b> <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_AuctionHouse">auction::AuctionHouse</a>, ctx: &<b>mut</b> <a href="dependencies/sui-framework/tx_context.md#0x2_tx_context_TxContext">tx_context::TxContext</a>): <a href="dependencies/sui-framework/coin.md#0x2_coin_Coin">coin::Coin</a>&lt;<a href="dependencies/sui-framework/sui.md#0x2_sui_SUI">sui::SUI</a>&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_admin_withdraw_funds">admin_withdraw_funds</a>(
    _: &AdminCap,
    self: &<b>mut</b> <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_AuctionHouse">AuctionHouse</a>,
    ctx: &<b>mut</b> TxContext,
): Coin&lt;SUI&gt; {
    <b>let</b> amount = self.<a href="dependencies/sui-framework/balance.md#0x2_balance">balance</a>.value();
    <b>assert</b>!(amount &gt; 0, <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_ENoProfits">ENoProfits</a>);
    <a href="dependencies/sui-framework/coin.md#0x2_coin_take">coin::take</a>(&<b>mut</b> self.<a href="dependencies/sui-framework/balance.md#0x2_balance">balance</a>, amount, ctx)
}
</code></pre>



</details>

<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_admin_finalize_auction"></a>

## Function `admin_finalize_auction`

Admin functionality used to finalize a single auction.

An <code>operation_limit</code> limit must be provided which controls how many
individual operations to perform. This allows the admin to be able to
make forward progress in finalizing auctions even in the presence of
thousands of bids.

This will attempt to do as much as possible of the following
based on the provided <code>operation_limit</code>:
- claim the winning bid and place in <code><a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_AuctionHouse">AuctionHouse</a>.<a href="dependencies/sui-framework/balance.md#0x2_balance">balance</a></code>
- push the <code>SuinsRegistration</code> to the winner
- push loosing bids back to their respective account owners

Once all of the above has been done the auction is destroyed,
freeing on-chain storage.


<pre><code><b>public</b> <b>fun</b> <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_admin_finalize_auction">admin_finalize_auction</a>(<a href="admin.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_admin">admin</a>: &<a href="suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_AdminCap">suins::AdminCap</a>, self: &<b>mut</b> <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_AuctionHouse">auction::AuctionHouse</a>, <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a>: <a href="dependencies/move-stdlib/string.md#0x1_string_String">string::String</a>, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &<a href="dependencies/sui-framework/clock.md#0x2_clock_Clock">clock::Clock</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_admin_finalize_auction">admin_finalize_auction</a>(
    <a href="admin.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_admin">admin</a>: &AdminCap,
    self: &<b>mut</b> <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_AuctionHouse">AuctionHouse</a>,
    <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a>: String,
    <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &Clock,
) {
    <b>let</b> <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a> = <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_new">domain::new</a>(<a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a>);
    <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_admin_finalize_auction_internal">admin_finalize_auction_internal</a>(<a href="admin.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_admin">admin</a>, self, <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a>, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>);
}
</code></pre>



</details>

<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_admin_finalize_auction_internal"></a>

## Function `admin_finalize_auction_internal`



<pre><code><b>fun</b> <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_admin_finalize_auction_internal">admin_finalize_auction_internal</a>(_: &<a href="suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_AdminCap">suins::AdminCap</a>, self: &<b>mut</b> <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_AuctionHouse">auction::AuctionHouse</a>, <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a>: <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain_Domain">domain::Domain</a>, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &<a href="dependencies/sui-framework/clock.md#0x2_clock_Clock">clock::Clock</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>fun</b> <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_admin_finalize_auction_internal">admin_finalize_auction_internal</a>(
    _: &AdminCap,
    self: &<b>mut</b> <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_AuctionHouse">AuctionHouse</a>,
    <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a>: Domain,
    <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &Clock,
) {
    <b>let</b> <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_Auction">Auction</a> {
        <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a>: _,
        start_timestamp_ms,
        end_timestamp_ms,
        winner,
        current_bid,
        nft,
    } = self.auctions.remove(<a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a>);

    // Ensure that the <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction">auction</a> is over
    <b>assert</b>!(<a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>.timestamp_ms() &gt; end_timestamp_ms, <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_EAuctionNotEndedYet">EAuctionNotEndedYet</a>);

    <a href="dependencies/sui-framework/event.md#0x2_event_emit">event::emit</a>(<a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_AuctionFinalizedEvent">AuctionFinalizedEvent</a> {
        <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a>,
        start_timestamp_ms,
        end_timestamp_ms,
        winning_bid: <a href="dependencies/sui-framework/coin.md#0x2_coin_value">coin::value</a>(&current_bid),
        winner,
    });

    self.<a href="dependencies/sui-framework/balance.md#0x2_balance">balance</a>.join(current_bid.into_balance());
    <a href="dependencies/sui-framework/transfer.md#0x2_transfer_public_transfer">transfer::public_transfer</a>(nft, winner);
}
</code></pre>



</details>

<a name="0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_admin_try_finalize_auctions"></a>

## Function `admin_try_finalize_auctions`

Admin functionality used to finalize an arbitrary number of auctions.

An <code>operation_limit</code> limit must be provided which controls how many
individual operations to perform. This allows the admin to be able to
make forward progress in finalizing auctions even in the presence of
thousands of auctions/bids.


<pre><code><b>public</b> <b>fun</b> <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_admin_try_finalize_auctions">admin_try_finalize_auctions</a>(<a href="admin.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_admin">admin</a>: &<a href="suins.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_suins_AdminCap">suins::AdminCap</a>, self: &<b>mut</b> <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_AuctionHouse">auction::AuctionHouse</a>, operation_limit: u64, <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &<a href="dependencies/sui-framework/clock.md#0x2_clock_Clock">clock::Clock</a>)
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_admin_try_finalize_auctions">admin_try_finalize_auctions</a>(
    <a href="admin.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_admin">admin</a>: &AdminCap,
    self: &<b>mut</b> <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_AuctionHouse">AuctionHouse</a>,
    <b>mut</b> operation_limit: u64,
    <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>: &Clock,
) {
    <b>let</b> <b>mut</b> next_domain = *self.auctions.back();

    <b>while</b> (is_some(&next_domain)) {
        <b>if</b> (operation_limit == 0) {
            <b>return</b>
        };
        operation_limit = operation_limit - 1;

        <b>let</b> <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a> = <a href="dependencies/move-stdlib/option.md#0x1_option_extract">option::extract</a>(&<b>mut</b> next_domain);
        next_domain = *self.auctions.prev(<a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a>);

        <b>let</b> <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction">auction</a> = &self.auctions[<a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a>];

        // If the <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction">auction</a> <b>has</b> ended, then try <b>to</b> finalize it
        <b>if</b> (<a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>.timestamp_ms() &gt; <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction">auction</a>.end_timestamp_ms) {
            <a href="auction.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_auction_admin_finalize_auction_internal">admin_finalize_auction_internal</a>(
                <a href="admin.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_admin">admin</a>,
                self,
                <a href="domain.md#0xba51681ecaf0a6e961ed95a6cfb9a5978cc607c43e2a41ef92b9a091abc73d94_domain">domain</a>,
                <a href="dependencies/sui-framework/clock.md#0x2_clock">clock</a>
            );
        };
    };
}
</code></pre>



</details>
