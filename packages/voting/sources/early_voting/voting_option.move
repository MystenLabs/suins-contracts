// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

module suins_voting::voting_option;

use std::string::String;
use sui::vec_set::{Self, VecSet};

const YES_OPTION: vector<u8> = b"Yes";
const NO_OPTION: vector<u8> = b"No";
const ABSTAIN_OPTION: vector<u8> = b"Abstain";
const THRESHOLD_NOT_REACHED: vector<u8> = b"Threshold not reached";
const TIE_REJECTED: vector<u8> = b"Vote rejected due to tie";

public struct VotingOption(String) has copy, drop, store;

/// The default voting is YES, NO, Abstain.
public fun default_options(): VecSet<VotingOption> {
    let mut options = vec_set::empty();
    options.insert(abstain_option());
    options.insert(yes_option());
    options.insert(no_option());

    options
}

public fun value(option: &VotingOption): String {
    option.0
}

public(package) fun new(option: String): VotingOption {
    VotingOption(option)
}

public(package) fun yes_option(): VotingOption {
    VotingOption(YES_OPTION.to_string())
}

public(package) fun no_option(): VotingOption {
    VotingOption(NO_OPTION.to_string())
}

public(package) fun abstain_option(): VotingOption {
    VotingOption(ABSTAIN_OPTION.to_string())
}

public(package) fun threshold_not_reached(): VotingOption {
    VotingOption(THRESHOLD_NOT_REACHED.to_string())
}

public(package) fun tie_rejected(): VotingOption {
    VotingOption(TIE_REJECTED.to_string())
}
