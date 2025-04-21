# Discounts Package

This directory contains the denylist package. The package provides support for managing name restrictions within the SuiNS system.

You can find more information
[in the docs page](https://docs.suins.io/).

### Overview

The denylist module extends the SuiNS Core Package by enforcing name restrictions within the Sui Name Service. It allows administrators to maintain two lists of restricted names — reserved and blocked — ensuring that inappropriate or protected names cannot be registered.

Reserved names are used to restrict second-level domain (SLD) registrations, while blocked names apply more broadly, including subdomain registrations. This module is designed for integration into public-facing naming systems to enforce policy-based controls on name availability.

### Modules

denylist: Maintains two separate lists of restricted names — reserved and blocked — to enforce naming policies. Supports admin-only operations for adding or removing names, and exposes public read functions to check restrictions.

## Installing

### [Move Registry CLI](https://docs.suins.io/move-registry)

```bash
mvr add @suins/denylist --network testnet

# or for mainnet
mvr add @suins/denylist --network mainnet
```
