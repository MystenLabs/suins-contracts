# Subnames Proxy Package

This directory contains the subnames proxy package. This is a temporary proxy used to proxy subdomain requests because we can't use references in a PTB.

You can find more information
[in the docs page](https://docs.suins.io/).

## Overview

The temp_subdomain_proxy package provides a temporary utility layer that enables interaction with subdomain management functions in SuiNS without requiring references, which are currently unsupported in Programmable Transaction Blocks (PTBs). It acts as a pass-through to the main subdomain and controller modules, forwarding calls while preserving the intended permissions and logic.

This proxy will be deprecated once reference support is enabled in PTBs, at which point direct function calls will be used instead of intermediary wrappers.

## Modules

subdomain_proxy: A temporary proxy module designed to forward calls for subdomain creation, removal, metadata editing, and address updates. It wraps subdomain management and controller functions using SubDomainRegistration objects and delegates execution to the appropriate core modules (suins_subdomains and controller). The module contains no internal logic or validations, those are performed by the destination modules it proxies.

## Installing

### [Move Registry CLI](https://docs.suins.io/move-registry)

```bash
mvr add @suins/temp-subnames-proxy --network testnet

# or for mainnet
mvr add @suins/temp-subnames-proxy --network mainnet
```
