# Vendored Aftermath AMM interfaces

Copies of two packages from
[AftermathFinance/move-interfaces](https://github.com/AftermathFinance/move-interfaces)
at commit `82ec9858667343f35528f0e0ea7cd759249b2b18` (Apache-2.0), with the
published addresses updated. `suins_bbb` depends on them instead of the upstream
repository.

| Directory   | Upstream path           | Linked version | `published-at`                                                       |
| ----------- | ----------------------- | -------------- | -------------------------------------------------------------------- |
| `amm/`      | `packages/amm/amm`      | v5 (was v2)    | `0x93056cd889839d7186498c5e86d3087cb79dacb08ae0e18b9b2c42ebe06d7be7` |
| `amm-math/` | `packages/amm/amm-math` | v2 (was v1)    | `0xbc7b2c577ad9362fbb0dba397d17f3bcc81bf7aa916559f99a77eaee05d0947c` |

## Why

On 2026-11-13 Aftermath upgraded its AMM and raised `PoolRegistry.protocol_version`
from 2 to 4. Older AMM package versions now abort every swap with code 40 in
`swap::assert_protocol_version`. `suins_bbb` v3 links AMM v2, so its Aftermath swaps
stopped working.

The fix is to upgrade `suins_bbb` so that it links AMM v5. The Move sources do not
change: the functions `suins_bbb` calls have the same signatures in every AMM version.

The upstream repository still declares AMM v2 in its `Move.toml`, and Sui (checked up
to 1.84.1) cannot override the published address of a dependency from the dependent
package. Vendoring is the only way to state the address in this repository.

`amm-math` is vendored because AMM v5 links AMM math v2. A package must link each
transitive dependency at a version no older than the one its dependencies link.

## What differs from upstream

- `amm/Move.toml`: `published-at`, and `ProtocolFeeVault` is a git dependency on the
  upstream repository instead of a sibling directory.
- `amm-math/Move.toml`: `published-at`.
- `amm/Move.lock` is not copied.

Everything under `sources/` is identical to upstream.

## Checking the addresses

The addresses are the latest versions on mainnet of the packages whose original IDs
are in the `[addresses]` sections. AMM v5's own linkage table lists AMM math v2.

## Removing this

Once upstream declares the current addresses, point `amm` in `../../Move.toml` back
at the upstream repository and delete this directory.

After any later Aftermath AMM upgrade that raises the protocol version, update
`published-at` here and upgrade `suins_bbb` again.
