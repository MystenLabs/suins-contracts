# Subnames Package

This directory contains the subnames package. The package supports creating and updating subnames.

You can find the more information
[in the docs page](https://docs.suins.io/developer/subnames).

## Overview

The subdomains package provides a comprehensive framework for managing subdomains within the Sui Name Service (SuiNS). It enables domain holders to create and control subdomains, define their expiration rules, and enforce configurable policies such as depth limits, label lengths, and permissioned actions like time extension or nested name creation.

This package ensures subdomain behavior remains flexible yet secure, supports leaf subdomains managed directly by a parent domain’s NFT, and allows full-featured node subdomains with their own NFTs. It is designed with upgradeability and modular authorization in mind, ensuring robust interoperability with the SuiNS core system.

## Modules

config: Defines the SubDomainConfig object, containing rules and validation constraints for subdomain creation. This includes the list of allowed TLDs, maximum depth for subdomains, minimum label length, and minimum duration. Provides validation utilities to enforce these rules during subdomain creation.

subdomains: Implements the core logic for subdomain management. Handles creation and removal of both node and leaf subdomains, extension of subdomain expiration times, and metadata-based permission management (e.g. whether a subdomain allows children or renewal). Uses dynamic fields to link parent NFTs with subdomain NFTs and relies on core SuiNS authorization for secure registry access.

## Installing

### [Move Registry CLI](https://docs.suins.io/move-registry)

```bash
mvr add @suins/subnames --network testnet

# or for mainnet
mvr add @suins/subnames --network mainnet
```
