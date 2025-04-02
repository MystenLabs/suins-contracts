// TODO (maybe): add Stats: user lifetime rewards, rewards per proposal
// TODO: add events
module suins_voting::proposal_v2;

// === imports ===

use std::{
    string::{String},
};
use sui::{
    balance::{Self, Balance},
    clock::{Clock},
    coin::{Coin},
    linked_table::{Self, LinkedTable},
    vec_map::{Self, VecMap},
    vec_set::{VecSet},
};
use suins_voting::{
    constants::{min_voting_period_ms, max_voting_period_ms},
    leaderboard::{Self, Leaderboard},
    voting_option::{Self, VotingOption, abstain_option},
};
use suins_token::{
    ns::{NS},
};
use suins_voting::{
    staking_batch::{StakingBatch},
    staking_config::{StakingConfig},
};

// === errors ===

const ENotAvailableOption: u64 = 0;
const EVotingPeriodExpired: u64 = 1;
const ETooShortVotingPeriod: u64 = 2;
const ETooLongVotingPeriod: u64 = 3;
const EEndTimeNotReached: u64 = 4;
const EProposalAlreadyFinalized: u64 = 5;
const ENotEnoughOptions: u64 = 6;
const EBatchIsVoting: u64 = 7;
const EBatchInCooldown: u64 = 8;
const EVoterNotFound: u64 = 9;

// === constants ===

// Limit is 1024, but setting it lower to reduce the risk of this becoming unusable.
// While the limit is 1024, someone can just batch 8 operations.
const MAX_RETURNS_PER_TX: u64 = 125;

// === structs ===

public struct ProposalV2 has key {
    /* Fields identical to v1 */

    /// We add proposals as DOFs, so UID allows us to look them up without DF queries
    id: UID,
    /// Serial number
    serial_no: u64,
    /// Minimum voting power required for the proposal to be accepted
    threshold: u64,
    /// Short title
    title: String,
    /// Longer description
    description: String,
    /// Winning option is set when the proposal is finalized
    winning_option: Option<VotingOption>,
    /// Top voters per option
    vote_leaderboards: VecMap<VotingOption, Leaderboard>,
    /// When the proposal was created
    start_time_ms: u64,
    /// Until when the proposal can accept votes
    end_time_ms: u64,
    /// Voting power per option. Determines the winning option.
    votes: VecMap<VotingOption, u64>,

    /* Modified fields in v2 */

    /// Voting power per user and option.
    voters: LinkedTable<address, VecMap<VotingOption, u64>>,

    /* New fields in v2 */

    /// Total voting power per user. Becomes empty once all rewards have been distributed.
    voter_powers: LinkedTable<address, u64>,
    /// Total voting power that voted in this proposal.
    total_power: u64,
    /// NS to reward batches proportionally to their share of total voting power
    reward: Balance<NS>,
    /// Initial value of `ProposalV2.reward` (reward.value() decreases as we distribute it)
    total_reward: u64,
}

// === public functions ===

/// Create a new proposal with the given options.
/// Validation of logic is delegated to the calling function.
///
/// Anyone can call this, but it can only be shared through the module,
/// so it's only callable by the governance module.
public fun new(
    title: String,
    description: String,
    end_time_ms: u64,
    mut options: VecSet<VotingOption>,
    reward: Coin<NS>,
    clock: &Clock,
    ctx: &mut TxContext,
): ProposalV2 {
    // min voting period checks
    assert!(
        end_time_ms >= clock.timestamp_ms() + min_voting_period_ms!(),
        ETooShortVotingPeriod,
    );

    // max voting period checks.
    assert!(
        end_time_ms <= clock.timestamp_ms() + max_voting_period_ms!(),
        ETooLongVotingPeriod,
    );

    // always include the abstain option in all proposals.
    if (!options.contains(&abstain_option())) {
        options.insert(abstain_option());
    };

    assert!(options.size() > 2, ENotEnoughOptions);

    let mut votes: VecMap<VotingOption, u64> = vec_map::empty();

    let mut vote_leaderboards: VecMap<
        VotingOption,
        Leaderboard,
    > = vec_map::empty();

    options.into_keys().do!(|opt| {
        votes.insert(opt, 0);
        vote_leaderboards.insert(opt, leaderboard::new(10));
    });

    let total_reward = reward.value();
    ProposalV2 {
        id: object::new(ctx),
        serial_no: 0,
        threshold: 0,
        title,
        description,
        votes,
        winning_option: option::none(),
        vote_leaderboards,
        start_time_ms: clock.timestamp_ms(),
        end_time_ms,
        total_power: 0,
        voters: linked_table::new(ctx),
        voter_powers: linked_table::new(ctx),
        reward: reward.into_balance(),
        total_reward,
    }
}

/// Vote for a given proposal.
public fun vote(
    proposal: &mut ProposalV2,
    opt: String,
    batch: &mut StakingBatch,
    staking_config: &StakingConfig,
    clock: &Clock,
    ctx: &TxContext,
) {
    let option = voting_option::new(opt);
    assert!(proposal.votes.contains(&option), ENotAvailableOption);
    assert!(!proposal.is_end_time_reached(clock), EVotingPeriodExpired);

    // prevent double voting
    assert!(!batch.is_voting(clock), EBatchIsVoting);
    batch.set_voting_until_ms(proposal.end_time_ms, clock);

    // batches that have requested cooldown can vote, but only before cooldown ends
    assert!(!batch.is_cooldown_over(clock), EBatchInCooldown);

    let batch_power = batch.power(staking_config, clock);

    // update proposal voting power
    proposal.total_power = proposal.total_power + batch_power;

    // update option voting power
    let option_power = proposal.votes.get_mut(&option);
    *option_power = *option_power + batch_power;

    // add new voter
    if (!proposal.voters.contains(ctx.sender())) {
        proposal.voters.push_back(ctx.sender(), vec_map::empty());
        proposal.voter_powers.push_back(ctx.sender(), 0);
    };

    // update user voting power and leaderboard

    let user_votes = proposal.voters.borrow_mut(ctx.sender());
    let leaderboard = proposal.vote_leaderboards.get_mut(&option);

    if (!user_votes.contains(&option)) {
        user_votes.insert(option, batch_power);
        leaderboard.add_if_eligible(ctx.sender(), batch_power);
    } else {
        let vote = user_votes.get_mut(&option);
        *vote = *vote + batch_power;
        leaderboard.add_if_eligible(ctx.sender(), *vote);
    };

    // update total user power
    let user_power = proposal.voter_powers.borrow_mut(ctx.sender());
    *user_power = *user_power + batch_power;
}

/// Finalize the proposal after the end time is reached and the threshold is
/// reached. The winning option is the one with the highest votes, except for
/// the abstain option which is ignored.
public fun finalize(
    proposal: &mut ProposalV2,
    clock: &Clock,
) {
    assert!(proposal.winning_option.is_none(), EProposalAlreadyFinalized);
    proposal.finalize_internal(clock);
}

/// Distribute NS rewards to all voters once voting has ended.
/// Also finalize the proposal if needed.
#[allow(lint(self_transfer))]
public fun distribute_rewards(
    proposal: &mut ProposalV2,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    proposal.finalize_internal(clock);

    let mut transfers: u64 = 0;
    while (transfers < MAX_RETURNS_PER_TX && !proposal.voter_powers.is_empty()) {
        let voter_addr = *proposal.voter_powers.front().borrow();
        let reward_coin = get_user_reward(proposal, voter_addr).into_coin(ctx);
        transfer::public_transfer(reward_coin, voter_addr);
        transfers = transfers + 1;
    };

    // once all rewards have been distributed, send any remaining NS to the caller
    if (proposal.voter_powers.is_empty() && proposal.reward.value() > 0) {
        let dust_value = proposal.reward.value();
        let dust_coin = proposal.reward.split(dust_value).into_coin(ctx);
        transfer::public_transfer(dust_coin, ctx.sender());
    }
}

/// Allow users to claim their own rewards.
/// Also finalize the proposal if needed.
public fun claim_reward(
    proposal: &mut ProposalV2,
    clock: &Clock,
    ctx: &mut TxContext,
): Balance<NS> {
    proposal.finalize_internal(clock);
    get_user_reward(proposal, ctx.sender())
}

// === package functions ===

public(package) fun is_end_time_reached(
    proposal: &ProposalV2,
    clock: &Clock,
): bool {
    clock.timestamp_ms() >= proposal.end_time_ms
}

public(package) fun is_threshold_reached(proposal: &ProposalV2): bool {
    proposal.total_power >= proposal.threshold
}

/// Only callable by `early_voting` module.
public(package) fun set_serial_no(proposal: &mut ProposalV2, serial_no: u64) {
    proposal.serial_no = serial_no;
}

/// Only callable by `early_voting` module.
public(package) fun set_threshold(proposal: &mut ProposalV2, threshold: u64) {
    proposal.threshold = threshold;
}

/// Sharing is only allowed internally, so even if someone can create a
/// proposal, they can't do anything with it.
///
/// Important: Make sure this is never a public function.
public(package) fun share(proposal: ProposalV2) {
    transfer::share_object(proposal);
}

// === private functions ===

/// Finalizes a proposal after the end time is reached.
/// If the proposal has already been finalized, it does nothing.
fun finalize_internal(proposal: &mut ProposalV2, clock: &Clock) {
    assert!(proposal.is_end_time_reached(clock), EEndTimeNotReached);

    // if the proposal has already been finalized, do nothing.
    if (proposal.winning_option.is_some()) return;

    // handle no threshold reached case.
    if (!proposal.is_threshold_reached()) {
        proposal.winning_option.fill(voting_option::threshold_not_reached());
        return
    };

    let mut votes = *&proposal.votes;

    let (mut winning_option, mut winning_votes) = votes.pop();
    if (winning_option == abstain_option()) winning_votes = 0;
    let mut is_tied = false;

    while (!votes.is_empty()) {
        let (opt, total) = votes.pop();
        if (opt == abstain_option()) continue;

        if (total > winning_votes) {
            winning_votes = total;
            winning_option = opt;
            is_tied = false; // Reset tie status
        } else if (total == winning_votes) {
            is_tied = true;
        };
    };
    if (is_tied) {
        // If there's a tie for the top option, reject the vote
        proposal.winning_option.fill(voting_option::tie_rejected());
    } else {
        proposal.winning_option.fill(winning_option);
    }
}

/// Remove the voter from proposal.voter_powers, and return his reward
fun get_user_reward(
    proposal: &mut ProposalV2,
    user_addr: address,
): Balance<NS> {
    assert!(proposal.voter_powers.contains(user_addr), EVoterNotFound);

    let user_power = proposal.voter_powers.remove(user_addr);

    let reward_value = calculate_reward(proposal, user_power);

    if (reward_value > 0) {
        proposal.reward.split(reward_value)
    } else {
        balance::zero()
    }
}

/// A voter's reward is proportional to their share of the total voting power.
fun calculate_reward(
    proposal: &ProposalV2,
    user_power: u64,
): u64 {
    if (proposal.total_power == 0) return 0;
    let total_reward = proposal.total_reward as u128;
    let total_power = proposal.total_power as u128;
    let reward_value = (user_power as u128) * total_reward / total_power;
    return reward_value as u64
}

// === accessors ===

public fun id(proposal: &ProposalV2): ID { proposal.id.to_inner() }
public fun serial_no(proposal: &ProposalV2): u64 { proposal.serial_no }
public fun threshold(proposal: &ProposalV2): u64 { proposal.threshold }
public fun title(proposal: &ProposalV2): &String { &proposal.title }
public fun description(proposal: &ProposalV2): &String { &proposal.description }
public fun winning_option(proposal: &ProposalV2): &Option<VotingOption> { &proposal.winning_option }
public fun vote_leaderboards(proposal: &ProposalV2): &VecMap<VotingOption, Leaderboard> { &proposal.vote_leaderboards }
public fun start_time_ms(proposal: &ProposalV2): u64 { proposal.start_time_ms }
public fun end_time_ms(proposal: &ProposalV2): u64 { proposal.end_time_ms }
public fun votes(proposal: &ProposalV2): &VecMap<VotingOption, u64> { &proposal.votes }
public fun voters(proposal: &ProposalV2): &LinkedTable<address, VecMap<VotingOption, u64>> { &proposal.voters }
public fun voter_powers(proposal: &ProposalV2): &LinkedTable<address, u64> { &proposal.voter_powers }
public fun total_power(proposal: &ProposalV2): u64 { proposal.total_power }
public fun reward(proposal: &ProposalV2): &Balance<NS> { &proposal.reward }
public fun total_reward(proposal: &ProposalV2): u64 { proposal.total_reward }
