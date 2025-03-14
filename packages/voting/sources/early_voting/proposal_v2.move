module suins_voting::proposal_v2;

// === imports ===

use std::string::String;
use sui::balance::{Balance};
use sui::clock::Clock;
use sui::coin::Coin;
use sui::event;
use sui::linked_table::{Self, LinkedTable};
use sui::vec_map::{Self, VecMap};
use sui::vec_set::VecSet;
use suins_voting::constants::{min_voting_period_ms, max_voting_period_ms};
use suins_voting::leaderboard::{Self, Leaderboard};
use suins_voting::voting_option::{Self, VotingOption, abstain_option};
use token::ns::NS;
use suins_voting::{
    staking_batch::{StakingBatch},
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
const EVoterNotFound: vector<u8> = b"Voter not found.";
#[error]
const ENotEnoughOptions: vector<u8> =
    b"Not enough options. Each proposal must have at least 2 options (and abstain).";
#[error]
const EBatchIsVoting: vector<u8> = b"Batch is already being used to vote.";

// === constants ===

// Our limit is 1024, but keeping this 250 at a time, and someone can just
// batch 8 operations. Makes the risk of this becoming unusable lower.
const MAX_RETURNS_PER_TX: u64 = 125;

// === structs ===

/// A proposal object. A proposal holds:
/// 1. A title and a description
/// 2. The total tokens saved for a given vote.
/// 3. The total votes for each option.
/// 4. A list of the unique addresses, and coins they've put for voting options.
/// 5. The timestamp up to which when the proposal can accept votes.
public struct ProposalV2 has key {
    /// We keep UID as we'll be adding proposals as DOFs, to easily look them up
    /// (not having to do DF queries).
    /// We'll also create a Display for these proposals.
    id: UID,
    /// The serial number of the proposal.
    serial_no: u64,
    /// The minimum threshold for the proposal to be accepted.
    threshold: u64,
    /// The title of the proposal.
    title: String,
    /// The description of the proposal.
    description: String,
    /// VecMap of votes, each holding the total voted balance and staked power for the option.
    votes: VecMap<VotingOption, u64>,
    /// The winning vote, that gets decided after the proposal is closed
    /// (permissionless-ly).
    winning_option: Option<VotingOption>,
    /// The leaderboard for most votes per option.
    vote_leaderboards: VecMap<VotingOption, Leaderboard>,
    /// Voter addresses and how much power they voted with on each option.
    /// It's a LinkedTable to allow permissionless distribution of rewards.
    voters: LinkedTable<address, VecMap<VotingOption, u64>>,
    /// The timestamp when the proposal was created.
    start_time_ms: u64,
    /// The timestamp up to which when the proposal can accept votes.
    end_time_ms: u64,
    /// The NS to reward voters proportionally to their share of total voting power.
    reward: Balance<NS>,
    /// The sum of all NS balance and all staked power used to vote in this proposal.
    total_power: u64,
    /// The initial value of `ProposalV2.reward`.
    total_reward: u64,
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
        title,
        description,
        serial_no: 0,
        threshold: 0,
        votes,
        vote_leaderboards,
        voters: linked_table::new(ctx),
        winning_option: option::none(),
        start_time_ms: clock.timestamp_ms(),
        end_time_ms,
        reward: reward.into_balance(),
        total_power: 0,
        total_reward,
    }
}

/// Vote for a given proposal.
public fun vote(
    proposal: &mut ProposalV2,
    opt: String,
    vote_staked: &mut vector<StakingBatch>,
    staking_config: &StakingConfig,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    let option = voting_option::new(opt);
    assert!(proposal.votes.contains(&option), ENotAvailableOption);

    // validate that the proposal is still open in terms of time.
    assert!(!proposal.is_end_time_reached(clock), EVotingPeriodExpired);

    // calculate total voting power in this vote (NS balance + staked power)
    let mut new_power = 0;
    vote_staked.do_mut!(|batch| {
        assert!(!batch.is_voting(clock), EBatchIsVoting);
        batch.set_voting_until_ms(proposal.end_time_ms, clock);
        new_power = new_power + batch.power(staking_config, clock);
    });

    // update total voting power for the option
    let total = proposal.votes.get_mut(&option);
    *total = *total + new_power;

    // update total voting power in the proposal
    proposal.total_power = proposal.total_power + new_power;

    // add the voter if not already present
    if (!proposal.voters.contains(ctx.sender())) {
        proposal.voters.push_back(ctx.sender(), vec_map::empty());
    };

    let leaderboard = proposal.vote_leaderboards.get_mut(&option);

    let votes = proposal.voters.borrow_mut(ctx.sender());

    if (!votes.contains(&option)) {
        votes.insert(option, new_power);
        leaderboard.add_if_eligible(ctx.sender(), new_power);
    } else {
        let vote = votes.get_mut(&option);
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

/// Permissionless-ly return the tokens for a given proposal, after
/// the proposal is completed. It also completes the proposal if it hasn't been
/// completed.
public fun return_tokens_bulk(
    proposal: &mut ProposalV2,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    proposal.finalize_internal(clock);

    let mut total_transfers = 0;

    while (
        !proposal.voters.is_empty() && total_transfers < MAX_RETURNS_PER_TX
    ) {
        let voter = *proposal.voters.back().borrow();
        // transfer the balance (as coin) back to the voter.
        transfer::public_transfer(
            proposal.return_reward(voter, ctx),
            voter,
        );

        // increment the total transfers.
        total_transfers = total_transfers + 1;
    };
}

/// Allow user to get their tokens back, if the proposal is completed.
public fun return_tokens(
    proposal: &mut ProposalV2,
    clock: &Clock,
    ctx: &mut TxContext,
): Coin<NS> {
    proposal.finalize_internal(clock);
    proposal.return_reward(ctx.sender(), ctx)
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

// === package functions ===

public(package) fun is_end_time_reached(
    proposal: &ProposalV2,
    clock: &Clock,
): bool {
    clock.timestamp_ms() >= proposal.end_time_ms
}

public(package) fun is_threshold_reached(proposal: &ProposalV2): bool {
    let (_, values) = proposal.votes.into_keys_values();
    let total_vote_value = values.fold!(0, |acc, val| acc + val);

    total_vote_value >= proposal.threshold
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

/// Remove the voter from the proposal and return a coin with a NS reward
/// proportional to their share of total voting power.
fun return_reward(
    proposal: &mut ProposalV2,
    voter: address,
    ctx: &mut TxContext,
): Coin<NS> {
    assert!(proposal.voters.contains(voter), EVoterNotFound);

    // all the options the user voted on
    let mut user_options = proposal.voters.remove(voter);
    // the power from all the options
    let mut user_power: u64 = 0;

    while(!user_options.is_empty()) {
        let (_option, power) = user_options.pop();
        user_power = user_power + power;
    };
    user_options.destroy_empty();

    // add the reward to the user's balance
    let reward = take_reward(proposal, user_power).into_coin(ctx);

    event::emit(ReturnTokenEvent {
        voter,
        amount: reward.value(),
    });

    reward
}

fun take_reward(
    proposal: &mut ProposalV2,
    user_power: u64,
): Balance<NS> {
    let total_reward = proposal.total_reward as u128;
    let total_power = proposal.total_power as u128;
    let reward_value = (user_power as u128) * total_reward / total_power;
    proposal.reward.split(reward_value as u64)
}
