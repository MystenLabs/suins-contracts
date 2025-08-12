## Contract

Currently here:
https://github.com/juzybits/suins-contracts/tree/staking/packages/voting

But we should merge it into:
https://github.com/MystenLabs/suins-contracts

## App

Currently here:
https://github.com/juzybits/suins-governance

But we should merge it into:
https://github.com/sui-foundation/suins-governance

## Deployment process

This is a new package, not an upgrade (even though we reused a lot of the original governance code, some changes are not backward compatible).

I've already removed the original `${contract_repo}/packages/voting/Move.lock`.

Publish to mainnet as usual:
```shell
cd ${contract_repo}/packages/voting/
sui client publish --json | tee publish.json
```

Commit the new `Move.lock` file.

Update `SUINS_PACKAGES.mainnet` in the app config `${app_repo}/src/constants/endpoints.ts`:
- votingPkgId: the published packageId
- governanceObjId: the created `…::governance::NSGovernance` objectId
- stakingConfigObjId: the created `…::staking_config::StakingConfig` objectId
- statsObjId: the created `…::stats::Stats` objectId
- coinType: remains the same

Publishing the contract gives you these admin objects:
- UpgradeCap and Publisher: standard Sui admin objects.
- NSGovernanceCap:
  - Same as in the original version of the contract.
  - Grants the power to add proposals (`early_voting::add_proposal_v2`).
  - Grants the power to configure the quorum threshold (`governance::set_quorum_threshold`).
- StakingAdminCap:
  - It's a new admin cap for staking-related operations.
  - Grants the power to configure staking parameters (`config::{set_cooldown_ms|set_max_lock_months|set_max_boost_bps|set_monthly_boost_bps|set_min_balance|set_all}`).
  - Grants the power to create and transfer staked `Batch` objects with an arbitrary start time (`batch::admin_new`). This is required to execute the airdrop (see `${app_repo}/scripts/`).
