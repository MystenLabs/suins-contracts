# Payments Package

This directory contains the payments package. The package supports registration/renewal payments.

You can find more information
[in the docs page](https://docs.suins.io/).

## Overview

The payments package enables flexible and secure multi-currency payment handling for domain registrations in SuiNS. It supports both base currency payments (USDC) and oracle-based conversions for alternative tokens using Pyth price feeds. The module also includes support for applying discounts based on payment token type and ensures users are protected via client-specified price guard values.

This payment infrastructure allows developers to support seamless pricing, discounts, and conversions across a variety of supported coin types, with admin-configured rules on discounts, price feeds, and acceptable age for oracle data.

## Modules

payments: Handles domain registration payments in multiple coin types. Supports conversion via Pyth price feeds, discounts based on payment token, and guards against price slippage via user_price_guard. Includes configuration logic for accepted coin types and discount percentages, as well as base currency designation and validation utilities.

## Installing

### [Move Registry CLI](https://docs.suins.io/move-registry)

```bash
mvr add @suins/payments --network testnet

# or for mainnet
mvr add @suins/payments --network mainnet
```
