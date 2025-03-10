/// Early voting is the simplest form of voting, where proposals are voted on by
/// the community.
/// This is a simple voting mechanism, without complex actions.
module suins_voting::early_voting;

use suins_voting::governance::{NSGovernance, NSGovernanceCap};
use suins_voting::proposal::Proposal;

#[error]
const ECannotHaveParallelProposals: vector<u8> =
    b"Cannot have parallel proposals";

public struct ProposalPointer has store {
    proposal_id: ID,
    end_time: u64,
}

/// The list of proposals in the early voting system.
public struct EarlyVoting(vector<ProposalPointer>) has store;

/// Called by the `NSGovernanceCap` holder to add a proposal to the early voting
/// system.
/// The proposal ID is saved in the proposals vector (from earlier to latest),
/// and becomes shared.
///
/// SAFETY: We do not worry about the vector exceeding size limits,
/// as the number of proposals is expected to be low in this iteration.
public fun add_proposal(
    _: &NSGovernanceCap,
    governance: &mut NSGovernance,
    mut proposal: Proposal,
) {
    // Self-spawn the early voting app if it is not there yet.
    if (!governance.has_app<EarlyVoting>()) {
        governance.add_app(EarlyVoting(vector[]))
    };

    let early_voting: &mut EarlyVoting = governance.app_mut();

    // avoid 2 parallel proposals.
    if (early_voting.0.length() > 0) {
        let last_proposal = early_voting.0.borrow(early_voting.0.length() - 1);
        assert!(
            last_proposal.end_time < proposal.start_time_ms(),
            ECannotHaveParallelProposals,
        );
    };

    early_voting
        .0
        .push_back(ProposalPointer {
            proposal_id: proposal.id(),
            end_time: proposal.end_time_ms(),
        });

    proposal.set_serial_no(early_voting.0.length());
    proposal.set_threshold(governance.quorum_threshold());

    proposal.share();
}
