# Buy Back & Burn CLI tool

## Installation

1. Install [Bun](https://bun.sh/docs/installation)
2. Install dependencies: `bun i`

## Update onchain config according to config.ts

This can only be executed by the `BBBAdminCap` holder.

```shell
bun src/cli.ts sync-config
```

## Execute a Buy Back & Burn transaction

Anyone can execute this.

```shell
bun src/cli.ts swap-and-burn >> log.txt
```
