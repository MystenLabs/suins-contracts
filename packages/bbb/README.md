# Buy Back & Burn (BBB)

A permissionless token buyback and burn mechanism for SuiNS, enabling automated conversion of collected fees into NS tokens for burning.

## Features

- Uses Aftermath AMM for swaps.
- Uses Pyth for slippage protection.
- Supports arbitrary swap pairs and burn types.
- Admin configures swap pairs and burn types dynamically.
- Anyone can trigger swaps and burns permissionlessly.

## Flow

1. Payments package deposits USDC/SUI/NS into the shared `BBBVault` (see [../payments](../payments)).
2. CLI tool swaps `USDC → SUI → NS` and then burns the NS tokens by sending them to `0x0`.

## CLI Tool

A command-line interface is provided to configure the system and execute swaps and burns.

See [scripts/README.md](scripts/README.md) for more details.
