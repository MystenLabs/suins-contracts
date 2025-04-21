# Coupons Package

This directory contains the coupons package. The package supports registration/renewal using coupon codes.

You can find more information
[in the docs page](https://docs.suins.io/).

## Overview

The coupons module adds support for discount-based registrations within the SuiNS system. It enables both core and external applications (e.g., Discord bots) to issue, validate, and consume coupon codes that apply dynamic discounts to name registrations.

Each coupon follows a defined set of rules (see the rules module), such as domain length, expiration, usage limits, or specific addresses. The module ensures that all conditions are met before applying a discount and supports both admin-issued and app-issued coupons.

## Modules

constants: Defines coupon-related constants, including supported discount types (e.g. percentage discounts). Also provides public getters for use across the coupons package.

coupon_house: Manages the lifecycle of coupons, including creation, validation, and redemption. Supports both admin and app-level issuance of coupons, version control, and enforcement of coupon rules during registration.

coupon: Defines the Coupon struct, which represents a discount offer with a type (e.g. percentage), value, and attached rules. Handles coupon creation, discount validation, and internal logic tied to discount type enforcement.

data: Internal storage module for managing all active coupons. Exposes controlled access to add or remove coupons from a protected container, preventing unauthorized modifications.

range: Provides the Range struct and helper functions to validate numeric ranges, used extensively in coupon rules (e.g. valid domain lengths, registration years).

rules: Implements CouponRules, which define the conditions under which a coupon can be redeemed. Rules include domain length restrictions, expiration dates, usage limits, specific user targeting, and valid registration year ranges.

## Installing

### [Move Registry CLI](https://docs.suins.io/move-registry)

```bash
mvr add @suins/coupons --network testnet

# or for mainnet
mvr add @suins/coupons --network mainnet
```
