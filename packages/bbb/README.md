# Buy Back & Burn (BBB)

A permissionless token buyback and burn mechanism for SuiNS, enabling automated conversion of collected fees into NS tokens for burning.

## Features

- Uses Pyth for slippage protection.
- Supports Cetus and Aftermath for swaps.
- Supports arbitrary swap pairs and burn types.
- Admin can configure swaps and burn dynamically.
- Anyone can execute swaps and burns permissionlessly.

## Flow

1. Payments package deposits USDC/SUI/NS into the shared `BBBVault` (see [../payments](../payments)).
2. CLI tool swaps `USDC → SUI → NS` and then burns the NS tokens by sending them to `0x0`.

## CLI Tool

A command-line interface is provided to configure the system and execute swaps and burns.

See [scripts/README.md](scripts/README.md) for more details.
