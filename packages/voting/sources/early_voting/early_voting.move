// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// Early voting is the simplest form of voting, where proposals are voted on by
/// the community.
/// This is a simple voting mechanism, without complex actions.
module suins_voting::early_voting;

use sui::event::emit;
use suins_voting::{governance::{NSGovernance, NSGovernanceCap}, proposal_v2::ProposalV2};

const ECannotHaveParallelProposals: u64 = 1000;

public struct ProposalPointer has store {
    proposal_id: ID,
    end_time: u64,
}

/// The list of proposals in the early voting system.
public struct EarlyVoting(vector<ProposalPointer>) has store;

/// There were 3 v1 proposals
public(package) macro fun serial_no_offset(): u64 {
    3
}

/// Called by the `NSGovernance` holder to add a proposal to the early voting
/// system.
/// The proposal ID is saved in the proposals vector (from earlier to latest),
/// and becomes shared.
///
/// SAFETY: We do not worry about the vector exceeding size limits,
/// as the number of proposals is expected to be low in this iteration.
public fun add_proposal_v2(
    _: &NSGovernanceCap,
    governance: &mut NSGovernance,
    mut proposal: ProposalV2,
) {
    let pointer = ProposalPointer {
        proposal_id: proposal.id(),
        end_time: proposal.end_time_ms(),
    };
    add_early_voting_proposal(governance, pointer, proposal.start_time_ms());

    let early_voting: &mut EarlyVoting = governance.app_mut();
    proposal.set_serial_no(early_voting.0.length() + serial_no_offset!());
    proposal.set_threshold(governance.quorum_threshold());

    emit(EventAddProposal {
        proposal_id: proposal.id(),
        serial_no: proposal.serial_no(),
        start_time: proposal.start_time_ms(),
        end_time: proposal.end_time_ms(),
        version: 2,
        reward: proposal.reward().value(),
    });

    proposal.share();
}

// === private functions ===

fun add_early_voting_proposal(
    governance: &mut NSGovernance,
    pointer: ProposalPointer,
    start_time_ms: u64,
) {
    // Self-spawn the early voting app if it is not there yet.
    if (!governance.has_app<EarlyVoting>()) {
        governance.add_app(EarlyVoting(vector[]))
    };

    let early_voting: &mut EarlyVoting = governance.app_mut();

    // avoid 2 parallel proposals.
    if (early_voting.0.length() > 0) {
        let last_proposal = early_voting.0.borrow(early_voting.0.length() - 1);
        assert!(last_proposal.end_time < start_time_ms, ECannotHaveParallelProposals);
    };

    early_voting.0.push_back(pointer);
}

// === devInspect functions ===

/// get proposal IDs from newest to oldest
public(package) fun get_proposal_ids(gov: &NSGovernance, offset: u64, limit: u64): vector<address> {
    if (!gov.has_app<EarlyVoting>()) {
        return vector[]
    };
    let early_voting: &EarlyVoting = gov.app();

    let total = early_voting.0.length();
    if (offset >= total) {
        return vector[]
    };

    let mut proposals = vector<address>[];
    let mut i = total - offset;
    while (i > 0 && proposals.length() < limit) {
        i = i - 1;
        let proposal = early_voting.0.borrow(i);
        proposals.push_back(proposal.proposal_id.to_address());
    };

    proposals
}

// === events ===

public struct EventAddProposal has copy, drop {
    proposal_id: ID,
    serial_no: u64,
    start_time: u64,
    end_time: u64,
    version: u8,
    reward: u64,
}
