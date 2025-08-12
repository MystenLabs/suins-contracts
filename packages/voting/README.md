# SuiNS Governance & Staking

This contract combines the voting and staking functionality.

## Governance

A modified version of the original governance contract. Originally voting was done with
plain NS coins, now voting is done with staked NS.

## Staking

- Staking
    - Minimum amount required to stake is 0.1 NS
    - Users who stake their tokens will receive voting power equal to 1 NS = 1 Vote for the first 30 Days
        - For each following set of 30 days, users will receive an additional 10% voting power boost on staked tokens up to 360 Days
            - e.g.
                - Day 1-30: 1 NS = 1 Vote
                - Day 31-60: 1 NS = 1.1 Votes
                - Day 61-90: 1 NS = 1.21 Votes
                - Day 331-360: 1 NS = 2.85 Votes
                - Day 361-390: 1 NS = 2.85 Votes
        - Users can continue staking after month 12 for as long as they wish, however their voting power will cap at 2.85X multiplier
        - If a user has already staked tokens, they can continue to stake new tokens as a new batch of staked tokens with a starting voting power equivalent to Day 1
        - Each batch of staked tokens will be viewable on the website for the user to see an itemized view of staking power (number of tokens, staked time, current voting power)
    - Unstake / Cool Down
        - Unstake requires 3 days cool down period
        - Once the cool down period has been reached the user can unstake their tokens
        - Batches in the cool down period (3 days) or cooled down (after 3 days) cannot participate in votes
- Locking
    - Users can lock their tokens from 1-12 months
        - When locking tokens the voting power of locked tokens on Day 1 and beyond is equivalent to the total lock time.
            - E.g.
            - 1 month lock: 1 NS = 1.1 Vote for all days
            - 2 month lock: 1 NS = 1.21 Votes for all Epochs
            - 11 month lock: 1 NS = 2.85 Votes for all Epochs
            - 12 month lock: 1 NS = 3 Votes (additional .15 bonus applied to full 12 month lock)
        - Users will be allowed to lock additional tokens into new locked batches just as the same methodology we follow with staked batches of new tokens
        - When the lock period is finished, the tokens become unlocked and staked and they will keep their existing voting power in that particular batch (based on length of time and staking rules, not locking rules) and accrue additional voting power according to the stake logic (if it applies)
        - Users will be able to increase the length of their locked tokens at anytime utilizing the existing voting power they have already accrued from locking
        - Users will be able to turn their staked tokens to a locked batch utilizing the existing voting power they have already accrued from staking as long as the staked batch is not participating in a vote or in a “cool down” period
- Rewards
    - Rewards will be distributed  at the end of each vote, sent directly to users wallet
    - If a user votes with 1 or more batches they receive a single $NS reward payment that covers all batches that participated in voting
    - Unstaking a batch (after a vote) does not prevent the user from receiving rewards for having voted in the previous proposal with that batch
    - if threshold is not reached, return reward to the proposal creator
- Voting
    - Only staked/locked tokens can participate in a vote
    - Staked/Locked batches become unusable (unable to unstake/lock) when participating in a vote
    - “Cooling Down” or “Cooled Down” batches cannot participate in a vote
    - Voting Power is not transferrable.
- Data Tracking
    - Total TVL
    - TVL per user
    - User Lifetime Rewards
    - User Voting History
