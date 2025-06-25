# Buy Back & Burn CLI tool

## Installation

1. Install [Bun](https://bun.sh/docs/installation)
2. Install dependencies: `bun i`

## Initial onchain configuration

This can only be executed by the `BBBAdminCap` holder.

```shell
bun src/cli.ts init
```

## Buy Back & Burn

Anyone can execute this.

```shell
bun src/cli.ts swap-and-burn >> log.txt
```
