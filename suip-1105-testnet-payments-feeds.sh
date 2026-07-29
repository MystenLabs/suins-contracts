#!/usr/bin/env bash
#
# SUIP-1105 — toggle the testnet PaymentsConfig between the pre-Pro and post-Pro Pyth feed ids.
#
# WHY THIS EXISTS
#   The Pyth Core->Pro cutover changes which feed ids testnet uses (Pro serves one endpoint for
#   both networks, so testnet's SUI/NS feed ids move to the global/mainnet ones). The on-chain
#   PaymentsConfig stores a price_feed_id per coin and asserts it against the PriceInfoObject the
#   client sends (EPriceFeedIdMismatch otherwise). So testnet needs its stored feed ids swapped.
#
#   But we can't just flip it and walk away:
#     - "post" (Pro) unblocks the ts-sdks testnet e2e, but BREAKS every client still on Core Pyth
#       (including the testnet.suins.io app itself) until the new SDK ships.
#     - "pre" (Core) is the currently-live, working state for those clients.
#   So we toggle: set "post", run the SDK e2e, set "pre" again to restore live apps. The permanent
#   flip to "post" happens right before the new SDK is published.
#
# TRADEOFFS
#   - Brief testnet downtime during the post<->pre window. Acceptable: low traffic, testnet.
#   - Mainnet is unaffected (its stored feed ids already equal the Pro ids), so no mainnet action
#     and no mainnet downtime.
#   - Full config re-seed, not a surgical edit: PaymentsConfig has no per-field setter, so we
#     remove_config + rebuild + add_config in one atomic PTB. Everything except the two feed ids
#     (coin types, discounts, base currency, max_age, burn_bps) is identical between the two states.
#
# WHY BASH/CLI (not the TS scripts)
#   The repo's TS admin scripts are on the old SDK and would need migrating to run; not worth it for
#   a throwaway toggle. This drives the `sui` CLI directly. You must have the testnet admin key
#   imported in your CLI keystore and selected as the active address.
#
# USAGE
#   ./suip-1105-testnet-payments-feeds.sh post            # establish Pro (post-cutover) feed ids
#   ./suip-1105-testnet-payments-feeds.sh pre             # restore Core (pre-cutover) feed ids
#   ./suip-1105-testnet-payments-feeds.sh post --dry-run  # preview without executing
#
set -euo pipefail

MODE="${1:-}"
DRY=""
[ "${2:-}" = "--dry-run" ] && DRY="--dry-run"
case "$MODE" in
  pre|post) ;;
  *) echo "usage: $0 <pre|post> [--dry-run]"; exit 1 ;;
esac

# --- fixed on-chain ids (testnet) ---
ADMIN=0xfe09cf0b3d77678b99250572624bf74fe3b12af915c5db95f0ed5d755612eb68
ADMIN_CAP=0x5def5bd9dc94b7d418d081a91c533ec619fb4350e6c4e4602aea96fd49331b15
SUINS=0x300369e8909b9a6464da265b9a5a9ab6fe2158a040e84e808628cde7a07ee5a3
SUINS_PKG=0x40eee27b014a872f5c3330dcd5329aa55c7fe0fcc6e70c6498852e2e3727172e   # suins LATEST published-at: MoveCall target (add_config/remove_config). V1 is superseded -> InvalidLinkage
PAY=0xc391c200188dd1a363ff12dcffe07eaac5cf28ad1cd8dc0fcc18f2f8625f0da2         # payments ORIGINAL id: type identity only (never moves across upgrades)
PAY_LATEST=0x4f33a0e1e30530f2aa500a41b9e3d502f8af3ef2c20bd0a1e42374e329da7cb0  # payments latest published-at (v2, post Pyth-Pro): MoveCall target

# --- coin config (testnet) — identical across both states except the feed ids ---
SUI_COIN_TYPE=0x0000000000000000000000000000000000000000000000000000000000000002::sui::SUI
NS_COIN_TYPE=0xb48aac3f53bab328e1eb4c5b3c34f55e760f2fb3f2305ee1a474878d80f650f0::TESTNS::TESTNS
USDC_COIN_TYPE=0xb48aac3f53bab328e1eb4c5b3c34f55e760f2fb3f2305ee1a474878d80f650f0::TESTUSDC::TESTUSDC
# CoinMetadata<T> objects — new_coin_type_data reads each coin's `decimals` from these.
SUI_COIN_METADATA=0x587c29de216efd4219573e08a1f6964d4fa7cb714518c2c8a0f29abfa264327d
NS_COIN_METADATA=0xaa8b452c0b45dbda946aeb65ee050da5a32b5a4f18abff8b4020bfd041cc17d3
USDC_COIN_METADATA=0xd7ec3e9792cf4b3282238d64b96197a18f3e972f311800c485900b02e85ef62c
SUI_DISCOUNT=0
NS_DISCOUNT=25
USDC_DISCOUNT=0
BASE_CURRENCY_COIN_TYPE="$USDC_COIN_TYPE"   # USDC is the base currency (no feed)
MAX_AGE=60
BURN_BPS=8000

# --- the only thing that differs between the two states: the feed ids ---
if [ "$MODE" = post ]; then
  SUI_FEED=0x23d7315113f5b1d3ba7a83604c44b94d79f4fd69af77f804fc7f920a6dc65744   # Crypto.SUI/USD (Pro, unified)
  NS_FEED=0xbb5ff26e47a3a6cc7ec2fce1db996c2a145300edc5acaabe43bf9ff7c5dd5d32    # Crypto.NS/USD  (Pro, real NS feed)
else
  SUI_FEED=0x50c67b3fd225db8912a424dd4baed60ffdde625ed2feaaf283724f9608fea266   # Crypto.SUI/USD (Core, testnet-specific)
  NS_FEED=0x99137a18354efa7fb6840889d059fdb04c46a6ce21be97ab60d9ad93e91ac758    # Crypto.HFT/USD (Core, Hashflow stand-in)
fi

# hex string -> `[b0,b1,...]` decimal u8 list for --make-move-vec <u8>
hex_to_u8_vec() {
  local hex="${1#0x}" out="" i
  for ((i=0; i<${#hex}; i+=2)); do out+="$((16#${hex:i:2})),"; done
  echo "[${out%,}]"
}
SUI_FEED_VEC="$(hex_to_u8_vec "$SUI_FEED")"
NS_FEED_VEC="$(hex_to_u8_vec "$NS_FEED")"
USDC_FEED_VEC="[]"   # base currency: empty feed

# --- guards: must be testnet + the admin address ---
[ "$(sui client active-env)" = testnet ] || { echo "active env must be 'testnet'"; exit 1; }
[ "$(sui client active-address)" = "$ADMIN" ] || { echo "active address must be the admin $ADMIN"; exit 1; }

echo "mode=$MODE ${DRY:+(dry-run)}  SUI_FEED=$SUI_FEED  NS_FEED=$NS_FEED"

# One atomic PTB: remove the old PaymentsConfig, rebuild it with the selected feeds, add it back.
sui client ptb $DRY --gas-budget 300000000 \
  --move-call "${SUINS_PKG}::suins::remove_config" "<${PAY}::payments::PaymentsConfig>" @"$ADMIN_CAP" @"$SUINS" \
  \
  --make-move-vec "<u8>" "$SUI_FEED_VEC"  --assign feed_sui \
  --move-call "${PAY_LATEST}::payments::new_coin_type_data" "<${SUI_COIN_TYPE}>"  @"$SUI_COIN_METADATA"  $SUI_DISCOUNT  feed_sui  --assign cd_sui \
  \
  --make-move-vec "<u8>" "$NS_FEED_VEC"   --assign feed_ns \
  --move-call "${PAY_LATEST}::payments::new_coin_type_data" "<${NS_COIN_TYPE}>"   @"$NS_COIN_METADATA"   $NS_DISCOUNT  feed_ns   --assign cd_ns \
  \
  --make-move-vec "<u8>" "$USDC_FEED_VEC" --assign feed_usdc \
  --move-call "${PAY_LATEST}::payments::new_coin_type_data" "<${USDC_COIN_TYPE}>" @"$USDC_COIN_METADATA" $USDC_DISCOUNT feed_usdc --assign cd_usdc \
  \
  --make-move-vec "<${PAY}::payments::CoinTypeData>" "[cd_usdc,cd_sui,cd_ns]" --assign setups \
  --move-call 0x1::type_name::get "<${BASE_CURRENCY_COIN_TYPE}>" --assign base_tn \
  --move-call "${PAY_LATEST}::payments::new_payments_config" setups base_tn $MAX_AGE $BURN_BPS --assign cfg \
  \
  --move-call "${SUINS_PKG}::suins::add_config" "<${PAY}::payments::PaymentsConfig>" @"$ADMIN_CAP" @"$SUINS" cfg
