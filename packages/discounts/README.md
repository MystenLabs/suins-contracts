# Discounts Package

This directory contains the discounts package. The package supports registration/renewal using discount NFTs.

You can find more information
[in the docs page](https://docs.suins.io/).

## Overview

The suins_discounts package introduces an extensible system for applying dynamic discounts and free claims on domain registrations in SuiNS. Discounts are determined by ownership of specific object types (e.g., NFTs) and are governed by per-type configuration stored in the DiscountHouse shared object.

This framework supports both:

1. Percentage-based discounts, where registration costs are reduced by a percentage.
2. Free claims, which allow certain users to register eligible names for free once per promotion.

The system is designed to be flexible, enabling custom promotions with tightly scoped rules. Admins can authorize or deauthorize object types for discounts or free claims.

## Modules

discounts: Supports configurable percentage-based discounts by object type (e.g., promotions, partner NFTs). Applies discounts dynamically based on domain length. Includes special handling for DayOne objects with active status.

free_claims: Enables one-time free domain registrations for users who present an eligible object. Ensures the domain falls within a configured length range and is limited to 1-year registrations. Tracks used objects to prevent reuse.

house: Core shared object (DiscountHouse) that stores discount and free claim configurations keyed by object type. Handles versioning and exposes shared utilities for internal module use.

## Installing

### [Move Registry CLI](https://docs.suins.io/move-registry)

```bash
mvr add @suins/discounts --network testnet

# or for mainnet
mvr add @suins/discounts --network mainnet
```
