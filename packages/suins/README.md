# SuiNS Package

This directory contains the main suins package.

You can find the latest addresses for this package and more information
[in the docs page](https://docs.suins.io/).

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

use suins::registry;
use suins::suins::SuiNS;

public fun do(suins: &mut SuiNS) {
    let _ = registry::lookup(registry, domain);
}
```
