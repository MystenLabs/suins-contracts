# SuiNS Package

This directory contains the main suins package.

You can find the latest addresses for this package and more information
[in the docs page](https://docs.suins.io/).

## Overview

The SuiNS Core Package is the foundational component of the Sui Name Service (SuiNS), providing essential on-chain functionality for name resolution within the Sui ecosystem. It enables developers to integrate human-readable names into their applications, facilitating both forward (name-to-address) and reverse (address-to-name) lookups.

For on-chain integrations, it’s recommended to depend solely on the core package, as utility packages may change over time, potentially affecting functionality.

Developers can integrate the core package into their Move-based projects by adding the appropriate dependency.

## Modules

admin: Provides reserved functions for managing domain registrations and configurations via the authorized AdminCap. Intended to be used by SuiNS administrators or deployers.

constants: Centralized module defining system-wide constants (e.g. domain length bounds, TLDs, grace periods) and helper getters.

controller: Exposes user-facing functionality such as reverse lookup setup, metadata editing, and burning expired records. Requires app-level authorization (ControllerV2).

core_config: Defines the domain validation logic and payment configuration for registration and renewals. Stores constraints like label length and supported TLDs.

domain: Defines the Domain type and helper utilities for parsing, validating, and manipulating domain structures (e.g. parent/subdomain relationships).

name_record: Represents the on-chain record for a registered domain, including its target address, expiration, and custom metadata. Used by the registry for name management.

registry: Manages the mapping between Domain and NameRecord, as well as reverse lookups from address to domain. Supports adding, removing, and burning domain records.

subdomain_registration: Wraps SuinsRegistration objects to represent subdomains. Adds structure for distinguishing and managing subdomain NFTs while maintaining compatibility with the registry.

suins_registration: Defines the SuinsRegistration NFT representing ownership of a registered domain. Tracks metadata like domain name, expiration timestamp, and optional image URL.

suins: Core module of the SuiNS application. Defines the SuiNS object and authorization logic. Provides shared registry and config access for authorized apps via generic dynamic fields.

## Installing

### [Move Registry CLI](https://docs.suins.io/move-registry)

```bash
mvr add @suins/core --network testnet

# or for mainnet
mvr add @suins/core --network mainnet
```

### Example

In your code, import and use the package as:

```move
module my::awesome_project;

use suins::suins::SuiNS;
use suins::domain;
use suins::name_record::NameRecord;
use suins::registry::{Registry, lookup};
use std::string::String;

public fun target_address(suins: &mut SuiNS, domain_name: String) {
    let registry = suins.registry<Registry>();
    let domain = domain::new(domain_name);
    let name_record = registry.lookup(domain).borrow<NameRecord>();
    let target_address = name_record.target_address();
    ...
}
```
