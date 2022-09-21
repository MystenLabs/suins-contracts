# SuiNS-C
Implementation of SuiNS Contracts

### Set up environment

You may simply [install Sui](https://github.com/MystenLabs/sui/blob/devnet/doc/src/build/install.md) and then request test tokens as described in the install docs. To use the Sui Devnet, you will need:

1. Sui [test coins (tokens)](https://github.com/MystenLabs/sui/blob/devnet/doc/src/build/devnet.md#request-gas-tokens) requested through [Discord](https://discordapp.com/channels/916379725201563759/971488439931392130).
1. the [`git` command line interface](https://git-scm.com/download/).
1. [Sui binaries](https://github.com/MystenLabs/sui/blob/devnet/doc/src/build/install.md#binaries) in your PATH environment variable, particularly `sui`.

Remember, you can confirm the existence of a command in your PATH by running `which` followed by the command, for example:

```shell
$ which sui
```
You should see the path to the command. Otherwise, reinstall.

> **Tip:** To reliably test Devnet with the latest Sui binaries, re-install them at least weekly.

In addition, to conduct advanced work such as publishing a Move module or making a Move call, also obtain the [Sui source code](https://github.com/MystenLabs/sui/blob/devnet/doc/src/build/install.md#source-code); for simplicity, we recommend installing in `~/sui` or using an environment variable.

### Set up Sui CLI client, connect to gateway

Now set up your Sui CLI client and connect to Devnet. Note you can manually change the Gateway URL if you have already configured a Sui CLI client.

 To connect the Sui client to the Devnet, run the following command:
```shell
$ sui client
```
The Sui CLI will print the following line if the client is starting up for the first time:
```shell
Config file ["/Users/dir/.sui/sui_config/client.yaml"] doesn't exist, do you want to connect to a Sui RPC server [y/n]?
```
Type `y` and then press `Enter`. You should see the following output:
```shell
Sui RPC server Url (Default to Sui Devnet if not specified) :
```
The Sui client will prompt for the RPC server URL; press 'Enter' and it will default to Devnet.
Or enter a custom URL to connect to a server hosted elsewhere.

If you have used the Sui client before with a local network, you will have an existing `client.yaml` configuration
file needing update. Change the configured RPC server URL to Devnet by using:
```shell
$ sui client switch --gateway https://gateway.devnet.sui.io:443
```

> **Tip:** If you run into issues, reset the Sui configuration by removing its directory, by default located at `~/.sui/sui_config`. Then reinstall [Sui binaries](https://github.com/MystenLabs/sui/blob/devnet/doc/src/build/install.md#binaries).


### How to build

```shell
$ sui move build
```

### How to test

```shell
$ sui move test
```

You will see this output:
```shell
INCLUDING DEPENDENCY MoveStdlib
INCLUDING DEPENDENCY Sui
BUILDING SuiNS-C
Running Move unit tests
[ PASS    ] 0x0::chat_tests::test_chat
Test result: OK. Total tests: 1; passed: 1; failed: 0
```

### How to publish

This Move package can be published as follows (assuming you installed the source code in `~sui` as advised in set up):
```shell
$ sui client publish --gas-budget 30000
```

You will see this output:
```shell
----- Certificate ----
Transaction Hash: LD/CZcfcaVBXPwzY7WjKPTUssQqg9JNWHfFN80JpCIQ=
Transaction Signature: AA==@tudnbvtclJL9ho4qOXyp8Zs9yECik7sj2Np/UnDkTgDR1PsyebSeF2fjxL0ZFMsC9mrZ23f/jnDnsCwoIpR4BA==@jHyyt3lPIcRIFtkDKcdAOLJgpBS+kqyl1qzY4L8lsvI=
Signed Authorities Bitmap: RoaringBitmap<[1, 2, 3]>
Transaction Kind : Publish
----- Transaction Effects ----
Status : Success
Created Objects:
  - ID: 0xc55c2ef444395b6d7d079b3a3413a85bddd81982 , Owner: Immutable
Mutated Objects:
  - ID: 0x289122420ba80976d91fd0799bc7bcb77c4c4f96 , Owner: Account Address ( 0x50d356fa6193a6f5479024490d574e42ee2b9c68 )
----- Publish Results ----
The newly published package object ID: 0xc55c2ef444395b6d7d079b3a3413a85bddd81982

Updated Gas : Coin { id: 0x289122420ba80976d91fd0799bc7bcb77c4c4f96, value: 48170 }
```
