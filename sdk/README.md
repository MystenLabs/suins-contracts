# SuiNS SDK

> Note 1: You do not need to use the SDK for name resolution (name -> address, address -> name).
> That is already covered by JSONRPC & GraphQL.

> SuiNS SDK is mostly functional on testnet, and will become available on mainnet after the release
> of subnames.

SuiNS SDK is a convenient wrapper for querying more detailed information and building transactions
towards the Name Service.

You can find docs [by clicking here](https://docs.suins.io).

## Testing

To run e2e tests, you need to first run a local sui network with the simplest setup.
You'd need the sui repository installed, and you could run the following command on the `sui` root folder.

```sh
cargo build --bin sui-test-validator --bin sui --profile dev && cross-env RUST_LOG=info,sui=error,anemo_tower=warn,consensus=off cargo run --bin sui-test-validator -- --epoch-duration-ms 300000
```

And then you can execute the tests (using a new terminal) by running:

```sh
pnpm test:e2e
```
