
<a name="0x0_auction"></a>

# Module `0x0::auction`

Implementation of auction module.
More information in: ../../../docs


-  [Struct `App`](#0x0_auction_App)
-  [Resource `AuctionHouse`](#0x0_auction_AuctionHouse)
-  [Struct `Auction`](#0x0_auction_Auction)
-  [Struct `AuctionStartedEvent`](#0x0_auction_AuctionStartedEvent)
-  [Struct `AuctionFinalizedEvent`](#0x0_auction_AuctionFinalizedEvent)
-  [Struct `BidEvent`](#0x0_auction_BidEvent)
-  [Struct `AuctionExtendedEvent`](#0x0_auction_AuctionExtendedEvent)
-  [Constants](#@Constants_0)
-  [Function `init`](#0x0_auction_init)
-  [Function `start_auction_and_place_bid`](#0x0_auction_start_auction_and_place_bid)
-  [Function `place_bid`](#0x0_auction_place_bid)
-  [Function `claim`](#0x0_auction_claim)
-  [Function `get_auction_metadata`](#0x0_auction_get_auction_metadata)
-  [Function `collect_winning_auction_fund`](#0x0_auction_collect_winning_auction_fund)
-  [Function `admin_withdraw_funds`](#0x0_auction_admin_withdraw_funds)
-  [Function `admin_finalize_auction`](#0x0_auction_admin_finalize_auction)
-  [Function `admin_finalize_auction_internal`](#0x0_auction_admin_finalize_auction_internal)
-  [Function `admin_try_finalize_auctions`](#0x0_auction_admin_try_finalize_auctions)


<pre><code><b>use</b> <a href="config.md#0x0_config">0x0::config</a>;
<b>use</b> <a href="domain.md#0x0_domain">0x0::domain</a>;
<b>use</b> <a href="registration_nft.md#0x0_registration_nft">0x0::registration_nft</a>;
<b>use</b> <a href="registry.md#0x0_registry">0x0::registry</a>;
<b>use</b> <a href="suins.md#0x0_suins">0x0::suins</a>;
<b>use</b> <a href="">0x1::option</a>;
<b>use</b> <a href="">0x1::string</a>;
<b>use</b> <a href="">0x2::balance</a>;
<b>use</b> <a href="">0x2::clock</a>;
<b>use</b> <a href="">0x2::coin</a>;
<b>use</b> <a href="">0x2::event</a>;
<b>use</b> <a href="">0x2::linked_table</a>;
<b>use</b> <a href="">0x2::object</a>;
<b>use</b> <a href="">0x2::sui</a>;
<b>use</b> <a href="">0x2::transfer</a>;
<b>use</b> <a href="">0x2::tx_context</a>;
</code></pre>



<a name="0x0_auction_App"></a>

## Struct `App`

Authorization witness to call protected functions of suins.


<pre><code><b>struct</b> <a href="auction.md#0x0_auction_App">App</a> <b>has</b> drop
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

<a name="0x0_auction_AuctionHouse"></a>

## Resource `AuctionHouse`

The AuctionHouse application.


<pre><code><b>struct</b> <a href="auction.md#0x0_auction_AuctionHouse">AuctionHouse</a> <b>has</b> store, key
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
<code><a href="">balance</a>: <a href="_Balance">balance::Balance</a>&lt;<a href="_SUI">sui::SUI</a>&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>auctions: <a href="_LinkedTable">linked_table::LinkedTable</a>&lt;<a href="domain.md#0x0_domain_Domain">domain::Domain</a>, <a href="auction.md#0x0_auction_Auction">auction::Auction</a>&gt;</code>
</dt>
<dd>

</dd>
</dl>


</details>

<a name="0x0_auction_Auction"></a>

## Struct `Auction`

The Auction application.


<pre><code><b>struct</b> <a href="auction.md#0x0_auction_Auction">Auction</a> <b>has</b> store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code><a href="domain.md#0x0_domain">domain</a>: <a href="domain.md#0x0_domain_Domain">domain::Domain</a></code>
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
<code>current_bid: <a href="_Coin">coin::Coin</a>&lt;<a href="_SUI">sui::SUI</a>&gt;</code>
</dt>
<dd>

</dd>
<dt>
<code>nft: <a href="registration_nft.md#0x0_registration_nft_RegistrationNFT">registration_nft::RegistrationNFT</a></code>
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
<code><a href="domain.md#0x0_domain">domain</a>: <a href="domain.md#0x0_domain_Domain">domain::Domain</a></code>
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

<a name="0x0_auction_AuctionFinalizedEvent"></a>

## Struct `AuctionFinalizedEvent`



<pre><code><b>struct</b> <a href="auction.md#0x0_auction_AuctionFinalizedEvent">AuctionFinalizedEvent</a> <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code><a href="domain.md#0x0_domain">domain</a>: <a href="domain.md#0x0_domain_Domain">domain::Domain</a></code>
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

<a name="0x0_auction_BidEvent"></a>

## Struct `BidEvent`



<pre><code><b>struct</b> <a href="auction.md#0x0_auction_BidEvent">BidEvent</a> <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code><a href="domain.md#0x0_domain">domain</a>: <a href="domain.md#0x0_domain_Domain">domain::Domain</a></code>
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

<a name="0x0_auction_AuctionExtendedEvent"></a>

## Struct `AuctionExtendedEvent`



<pre><code><b>struct</b> <a href="auction.md#0x0_auction_AuctionExtendedEvent">AuctionExtendedEvent</a> <b>has</b> <b>copy</b>, drop
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code><a href="domain.md#0x0_domain">domain</a>: <a href="domain.md#0x0_domain_Domain">domain::Domain</a></code>
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


<a name="0x0_auction_ENoProfits"></a>



<pre><code><b>const</b> <a href="auction.md#0x0_auction_ENoProfits">ENoProfits</a>: u64 = 13;
</code></pre>



<a name="0x0_auction_AUCTION_BIDDING_PERIOD_MS"></a>

The auction bidding period is 2 days.


<pre><code><b>const</b> <a href="auction.md#0x0_auction_AUCTION_BIDDING_PERIOD_MS">AUCTION_BIDDING_PERIOD_MS</a>: u64 = 172800000;
</code></pre>



<a name="0x0_auction_AUCTION_MIN_QUIET_PERIOD_MS"></a>

The auction quiet period is 10 minutes.


<pre><code><b>const</b> <a href="auction.md#0x0_auction_AUCTION_MIN_QUIET_PERIOD_MS">AUCTION_MIN_QUIET_PERIOD_MS</a>: u64 = 600000;
</code></pre>



<a name="0x0_auction_DEFAULT_DURATION"></a>

One year is the default duration for a domain.


<pre><code><b>const</b> <a href="auction.md#0x0_auction_DEFAULT_DURATION">DEFAULT_DURATION</a>: u8 = 1;
</code></pre>



<a name="0x0_auction_EAuctionEnded"></a>



<pre><code><b>const</b> <a href="auction.md#0x0_auction_EAuctionEnded">EAuctionEnded</a>: u64 = 9;
</code></pre>



<a name="0x0_auction_EAuctionNotEndedYet"></a>



<pre><code><b>const</b> <a href="auction.md#0x0_auction_EAuctionNotEndedYet">EAuctionNotEndedYet</a>: u64 = 8;
</code></pre>



<a name="0x0_auction_EAuctionNotStarted"></a>

Placing a bid in a not started


<pre><code><b>const</b> <a href="auction.md#0x0_auction_EAuctionNotStarted">EAuctionNotStarted</a>: u64 = 7;
</code></pre>



<a name="0x0_auction_EAuctionStarted"></a>

Trying to start an action but it's already started.


<pre><code><b>const</b> <a href="auction.md#0x0_auction_EAuctionStarted">EAuctionStarted</a>: u64 = 1;
</code></pre>



<a name="0x0_auction_EBidAmountTooLow"></a>



<pre><code><b>const</b> <a href="auction.md#0x0_auction_EBidAmountTooLow">EBidAmountTooLow</a>: u64 = 12;
</code></pre>



<a name="0x0_auction_EInvalidBidValue"></a>

The bid value is too low (compared to min_bid or previous bid).


<pre><code><b>const</b> <a href="auction.md#0x0_auction_EInvalidBidValue">EInvalidBidValue</a>: u64 = 0;
</code></pre>



<a name="0x0_auction_ENotWinner"></a>



<pre><code><b>const</b> <a href="auction.md#0x0_auction_ENotWinner">ENotWinner</a>: u64 = 10;
</code></pre>



<a name="0x0_auction_EWinnerCannotPlaceBid"></a>



<pre><code><b>const</b> <a href="auction.md#0x0_auction_EWinnerCannotPlaceBid">EWinnerCannotPlaceBid</a>: u64 = 11;
</code></pre>



<a name="0x0_auction_init"></a>

## Function `init`



<pre><code><b>fun</b> <a href="auction.md#0x0_auction_init">init</a>(ctx: &<b>mut</b> <a href="_TxContext">tx_context::TxContext</a>)
</code></pre>


<a name="0x0_auction_start_auction_and_place_bid"></a>

## Function `start_auction_and_place_bid`

Start an auction if it's not started yet; and make the first bid.


<pre><code><b>public</b> <b>fun</b> <a href="auction.md#0x0_auction_start_auction_and_place_bid">start_auction_and_place_bid</a>(self: &<b>mut</b> <a href="auction.md#0x0_auction_AuctionHouse">auction::AuctionHouse</a>, <a href="suins.md#0x0_suins">suins</a>: &<b>mut</b> <a href="suins.md#0x0_suins_SuiNS">suins::SuiNS</a>, domain_name: <a href="_String">string::String</a>, bid: <a href="_Coin">coin::Coin</a>&lt;<a href="_SUI">sui::SUI</a>&gt;, <a href="">clock</a>: &<a href="_Clock">clock::Clock</a>, ctx: &<b>mut</b> <a href="_TxContext">tx_context::TxContext</a>)
</code></pre>


<a name="0x0_auction_place_bid"></a>

## Function `place_bid`


<a name="@Notice_1"></a>

###### Notice

Bidders use this function to place a new bid.

Panics
Panics if <code><a href="domain.md#0x0_domain">domain</a></code> is invalid
or there isn't an auction for <code><a href="domain.md#0x0_domain">domain</a></code>
or <code>bid</code> is too low,


<pre><code><b>public</b> <b>fun</b> <a href="auction.md#0x0_auction_place_bid">place_bid</a>(self: &<b>mut</b> <a href="auction.md#0x0_auction_AuctionHouse">auction::AuctionHouse</a>, domain_name: <a href="_String">string::String</a>, bid: <a href="_Coin">coin::Coin</a>&lt;<a href="_SUI">sui::SUI</a>&gt;, <a href="">clock</a>: &<a href="_Clock">clock::Clock</a>, ctx: &<b>mut</b> <a href="_TxContext">tx_context::TxContext</a>)
</code></pre>


<a name="0x0_auction_claim"></a>

## Function `claim`


<a name="@Notice_2"></a>

###### Notice

Auction winner can come and claim the NFT

Panics
sender is not the winner


<pre><code><b>public</b> <b>fun</b> <a href="auction.md#0x0_auction_claim">claim</a>(self: &<b>mut</b> <a href="auction.md#0x0_auction_AuctionHouse">auction::AuctionHouse</a>, domain_name: <a href="_String">string::String</a>, <a href="">clock</a>: &<a href="_Clock">clock::Clock</a>, ctx: &<b>mut</b> <a href="_TxContext">tx_context::TxContext</a>): <a href="registration_nft.md#0x0_registration_nft_RegistrationNFT">registration_nft::RegistrationNFT</a>
</code></pre>


<a name="0x0_auction_get_auction_metadata"></a>

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


<pre><code><b>public</b> <b>fun</b> <a href="auction.md#0x0_auction_get_auction_metadata">get_auction_metadata</a>(self: &<a href="auction.md#0x0_auction_AuctionHouse">auction::AuctionHouse</a>, domain_name: <a href="_String">string::String</a>): (<a href="_Option">option::Option</a>&lt;u64&gt;, <a href="_Option">option::Option</a>&lt;u64&gt;, <a href="_Option">option::Option</a>&lt;<b>address</b>&gt;, <a href="_Option">option::Option</a>&lt;u64&gt;)
</code></pre>


<a name="0x0_auction_collect_winning_auction_fund"></a>

## Function `collect_winning_auction_fund`



<pre><code><b>public</b> <b>fun</b> <a href="auction.md#0x0_auction_collect_winning_auction_fund">collect_winning_auction_fund</a>(self: &<b>mut</b> <a href="auction.md#0x0_auction_AuctionHouse">auction::AuctionHouse</a>, domain_name: <a href="_String">string::String</a>, <a href="">clock</a>: &<a href="_Clock">clock::Clock</a>, ctx: &<b>mut</b> <a href="_TxContext">tx_context::TxContext</a>)
</code></pre>


<a name="0x0_auction_admin_withdraw_funds"></a>

## Function `admin_withdraw_funds`



<pre><code><b>public</b> <b>fun</b> <a href="auction.md#0x0_auction_admin_withdraw_funds">admin_withdraw_funds</a>(_: &<a href="suins.md#0x0_suins_AdminCap">suins::AdminCap</a>, self: &<b>mut</b> <a href="auction.md#0x0_auction_AuctionHouse">auction::AuctionHouse</a>, ctx: &<b>mut</b> <a href="_TxContext">tx_context::TxContext</a>): <a href="_Coin">coin::Coin</a>&lt;<a href="_SUI">sui::SUI</a>&gt;
</code></pre>


<a name="0x0_auction_admin_finalize_auction"></a>

## Function `admin_finalize_auction`

Admin functionality used to finalize a single auction.

An <code>operation_limit</code> limit must be provided which controls how many
individual operations to perform. This allows the admin to be able to
make forward progress in finalizing auctions even in the presence of
thousands of bids.

This will attempt to do as much as possible of the following
based on the provided <code>operation_limit</code>:
- claim the winning bid and place in <code><a href="auction.md#0x0_auction_AuctionHouse">AuctionHouse</a>.<a href="">balance</a></code>
- push the <code>RegistrationNFT</code> to the winner
- push loosing bids back to their respective account owners

Once all of the above has been done the auction is destroyed,
freeing on-chain storage.


<pre><code><b>public</b> <b>fun</b> <a href="auction.md#0x0_auction_admin_finalize_auction">admin_finalize_auction</a>(<a href="admin.md#0x0_admin">admin</a>: &<a href="suins.md#0x0_suins_AdminCap">suins::AdminCap</a>, self: &<b>mut</b> <a href="auction.md#0x0_auction_AuctionHouse">auction::AuctionHouse</a>, <a href="domain.md#0x0_domain">domain</a>: <a href="_String">string::String</a>, <a href="">clock</a>: &<a href="_Clock">clock::Clock</a>)
</code></pre>


<a name="0x0_auction_admin_finalize_auction_internal"></a>

## Function `admin_finalize_auction_internal`



<pre><code><b>fun</b> <a href="auction.md#0x0_auction_admin_finalize_auction_internal">admin_finalize_auction_internal</a>(_: &<a href="suins.md#0x0_suins_AdminCap">suins::AdminCap</a>, self: &<b>mut</b> <a href="auction.md#0x0_auction_AuctionHouse">auction::AuctionHouse</a>, <a href="domain.md#0x0_domain">domain</a>: <a href="domain.md#0x0_domain_Domain">domain::Domain</a>, <a href="">clock</a>: &<a href="_Clock">clock::Clock</a>)
</code></pre>


<a name="0x0_auction_admin_try_finalize_auctions"></a>

## Function `admin_try_finalize_auctions`

Admin functionality used to finalize an arbitrary number of auctions.

An <code>operation_limit</code> limit must be provided which controls how many
individual operations to perform. This allows the admin to be able to
make forward progress in finalizing auctions even in the presence of
thousands of auctions/bids.


<pre><code><b>public</b> <b>fun</b> <a href="auction.md#0x0_auction_admin_try_finalize_auctions">admin_try_finalize_auctions</a>(<a href="admin.md#0x0_admin">admin</a>: &<a href="suins.md#0x0_suins_AdminCap">suins::AdminCap</a>, self: &<b>mut</b> <a href="auction.md#0x0_auction_AuctionHouse">auction::AuctionHouse</a>, operation_limit: u64, <a href="">clock</a>: &<a href="_Clock">clock::Clock</a>)
</code></pre>
