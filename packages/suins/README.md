# SuiNS Package

This directory contains the main suins package.



## Mainnet Addresses



- V2: `0xb7004c7914308557f7afbaf0dca8dd258e18e306cb7a45b28019f3d0a693f162`

V2 rev: 2d985a3
Introduced `uid` & `uid_mut` for `SuinsRegistration` object.


V1 rev: (was testnet)
V1: `0xd22b24490e0bae52676651b4f56660a5ff8022a2576e0089f79b3c88d44e08f0`

## Testnet Addresses

Update (15-01-2024): We'll need a full testnet re-deployment to support our new subdomain structure + changes.
However, a regular package upgrade will work perfectly fine on mainnet.
- V5: `0x8ea50d1974a257d3ed8e94fbe4f280d8df1a0a9b1eb511773e74d613d2c2afe3`
Adds subdomain wrapper. V4 + V5 will be a single deployment on mainnet.

- V4: `0x36547dd95b52fa8ea478dc667ff158c65e6cd7cfad6c92d53e68cb8046d628db`
Adds first bits of Subdomains

- V3: `0x7e1ed011b9e68f5144d9b12f756a3fb34a5a5d71f294629722214ffa92767487`
rev: `d9bcbb2`

Introduces `uid` & `uid_mut` for `SuinsRegistration` object.

rev: `a2af559`
- V2: `0x0cf216d6964d17c08e35bd85d3c57bee7413209c63f659567b7b44ce125bc44f`

Introduced `register.move` file on testnet. We'll move it to a separate package on mainnet.


- V1: `0x701b8ca1c40f11288a1ed2de0a9a2713e972524fbab748a7e6c137225361653f`

Introduced all base modules (incl. auction) on testnet.

