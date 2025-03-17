module suins_voting::proposal_v2;

// === imports ===

use std::string::String;
use sui::balance::{Balance};
use sui::clock::Clock;
use sui::coin::Coin;
use sui::linked_table::{Self, LinkedTable};
use sui::vec_map::{Self, VecMap};
use sui::vec_set::VecSet;
use suins_voting::constants::{min_voting_period_ms, max_voting_period_ms};
use suins_voting::leaderboard::{Self, Leaderboard};
use suins_voting::voting_option::{Self, VotingOption, abstain_option};
use token::ns::NS;
use suins_voting::{
    staking_batch::{Self, StakingBatch},
    staking_config::{StakingConfig},
};

// === errors ===

#[error]
const ENotAvailableOption: vector<u8> =
    b"Tries to vote for an option that is not available.";
#[error]
const EVotingPeriodExpired: vector<u8> = b"Voting period has expired.";
#[error]
const ETooShortVotingPeriod: vector<u8> =
    b"Tries to create a proposal with a voting period shorter than the minimum period.";
#[error]
const ETooLongVotingPeriod: vector<u8> =
    b"Tries to create a proposal with a voting period longer than the maximum period.";
#[error]
const EEndTimeNotReached: vector<u8> = b"Proposal end time not reached.";
#[error]
const EProposalAlreadyFinalized: vector<u8> = b"Proposal already finalized.";
#[error]
const ENotEnoughOptions: vector<u8> =
    b"Not enough options. Each proposal must have at least 2 options (and abstain).";
#[error]
const EBatchIsVoting: vector<u8> = b"Batch is already being used to vote.";

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
    /// Total voting power for each option
    votes: VecMap<VotingOption, u64>,
    /// Winning option is set when the proposal is finalized
    winning_option: Option<VotingOption>,
    /// Top voters per option
    vote_leaderboards: VecMap<VotingOption, Leaderboard>,
    /// When the proposal was created
    start_time_ms: u64,
    /// Until when the proposal can accept votes
    end_time_ms: u64,

    /* New or modified fields in v2 */

    /// Voter addresses and how much power they voted with on each option
    voters: LinkedTable<address, VecMap<VotingOption, u64>>,
    /// Batches used to vote, and their voting power
    batches: LinkedTable<address, u64>,
    /// NS to reward voters proportionally to their share of total voting power
    reward: Balance<NS>,
    /// Initial value of `ProposalV2.reward` (.reward.value() will decrease as we distribute it)
    total_reward: u64,
    /// Sum of all voting power used to vote in this proposal
    total_power: u64,
}

public(package) fun demo_send_reward( // TODO remove
    proposal: &mut ProposalV2,
    recipient: address,
    value: u64,
    ctx: &mut TxContext,
) {
    let reward_balance = proposal.reward.split(value);
    staking_batch::send_reward(reward_balance, recipient, ctx);
}

// === events ===

public struct ReturnTokenEvent has copy, drop {
    voter: address,
    amount: u64,
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
        voters: linked_table::new(ctx),
        batches: linked_table::new(ctx),
        reward: reward.into_balance(),
        total_reward,
        total_power: 0,
    }
}

/// Vote for a given proposal.
public fun vote(
    proposal: &mut ProposalV2,
    opt: String,
    voting_batches: &mut vector<StakingBatch>,
    staking_config: &StakingConfig,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    let option = voting_option::new(opt);
    assert!(proposal.votes.contains(&option), ENotAvailableOption);
    assert!(!proposal.is_end_time_reached(clock), EVotingPeriodExpired);

    // calculate the total voting power in this vote
    let mut new_power = 0;
    voting_batches.do_mut!(|batch| {
        assert!(!batch.is_voting(clock), EBatchIsVoting);
        batch.set_voting_until_ms(proposal.end_time_ms, clock);
        let batch_power = batch.power(staking_config, clock);
        new_power = new_power + batch_power;
        proposal.batches.push_back(batch.id().to_address(), batch_power);
    });

    // update total voting power in the proposal
    proposal.total_power = proposal.total_power + new_power;

    // update voting power for the option
    let option_power = proposal.votes.get_mut(&option);
    *option_power = *option_power + new_power;

    // add the voter if not already present
    if (!proposal.voters.contains(ctx.sender())) {
        proposal.voters.push_back(ctx.sender(), vec_map::empty());
    };

    // save the vote and update the leaderboard
    let user_votes = proposal.voters.borrow_mut(ctx.sender());
    let leaderboard = proposal.vote_leaderboards.get_mut(&option);
    if (!user_votes.contains(&option)) {
        user_votes.insert(option, new_power);
        leaderboard.add_if_eligible(ctx.sender(), new_power);
    } else {
        let vote = user_votes.get_mut(&option);
        *vote = *vote + new_power;
        leaderboard.add_if_eligible(ctx.sender(), *vote);
    };
}

/// Finalize the proposal after the end time is reached and the threshold is
/// reached. The winning option is the one with the highest votes, except for
/// the abstain option which is ignored.
public fun finalize(
    proposal: &mut ProposalV2,
    clock: &Clock,
    _ctx: &mut TxContext,
) {
    assert!(proposal.winning_option.is_none(), EProposalAlreadyFinalized);
    proposal.finalize_internal(clock);
}

/// Permissionlessly distribute staked NS rewards to voting batches once voting has ended.
/// It also finalizes the proposal if needed.
public fun distribute_rewards_bulk(
    proposal: &mut ProposalV2,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    proposal.finalize_internal(clock);

    let mut i = 0;
    while (i < MAX_RETURNS_PER_TX && !proposal.batches.is_empty()) {
        let (batch_addr, batch_power) = proposal.batches.pop_front();
        let reward_value = calculate_reward(proposal, batch_power);
        let reward_balance = proposal.reward.split(reward_value);
        staking_batch::send_reward(reward_balance, batch_addr, ctx);
        i = i + 1;
    };
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

fun calculate_reward(
    proposal: &ProposalV2,
    batch_power: u64,
): u64 {
    let total_reward = proposal.total_reward as u128;
    let total_power = proposal.total_power as u128;
    let reward_value = (batch_power as u128) * total_reward / total_power;
    return reward_value as u64
}

// === accessors ===

/// Get the ID of the proposal. Helpful for receiver syntax.
public fun id(proposal: &ProposalV2): ID { proposal.id.to_inner() }

public fun end_time_ms(proposal: &ProposalV2): u64 { proposal.end_time_ms }

public fun start_time_ms(proposal: &ProposalV2): u64 { proposal.start_time_ms }

public fun serial_no(proposal: &ProposalV2): u64 { proposal.serial_no }

public fun winning_option(proposal: &ProposalV2): Option<VotingOption> {
    proposal.winning_option
}

public fun voters_count(proposal: &ProposalV2): u64 { proposal.voters.length() }
public fun batches_count(proposal: &ProposalV2): u64 { proposal.batches.length() }
