module suins_voting::leaderboard;

#[error]
const EInvalidMaxSize: vector<u8> =
    b"Maximum leaderboard size cannot exceed 100 entries.";

/// The maximum number of entries in the leaderboard
/// Added to preserve size limits.
const MAX_ENTRIES: u64 = 100;

public struct LeaderboardEntry(address, u64) has copy, store, drop;

public struct Leaderboard has store, drop {
    entries: vector<LeaderboardEntry>,
    max_size: u64,
}

public(package) fun new(max_size: u64): Leaderboard {
    assert!(max_size > 0 && max_size <= MAX_ENTRIES, EInvalidMaxSize);
    Leaderboard {
        entries: vector[],
        max_size,
    }
}

public fun addr(entry: &LeaderboardEntry): address {
    entry.0
}

public fun value(entry: &LeaderboardEntry): u64 {
    entry.1
}

public fun entries(leaderboard: &Leaderboard): vector<LeaderboardEntry> {
    leaderboard.entries
}

/// Function to insert a new entry into the leaderboard if it is eligible,
/// or add extra votes to an existing entry.
///
/// If the address exists in the leaderboard, we know that the new value
/// is greater than the existing value (so it should belong here),
/// so we can just update it.
public fun add_if_eligible(
    leaderboard: &mut Leaderboard,
    addr: address,
    value: u64,
) {
    // If the address is already in the leaderboard, add the value to the
    // existing entry
    let mut addr_idx = leaderboard
        .entries()
        .find_index!(|val| val.addr() == addr);

    if (addr_idx.is_some()) {
        leaderboard.entries[addr_idx.extract()].1 = value;
        leaderboard.sort();
        return
    };

    // remove address from leaderboard if exists.
    let is_full = leaderboard.entries.length() >= leaderboard.max_size;

    // If the leaderboard is full and the last entry is greater than the
    // entry we try to insert, we can skip the insertion
    if (
        is_full &&
        leaderboard.entries[leaderboard.max_size - 1].1 >= value
    ) return;

    // If the leaderboard is full, remove the last entry
    if (is_full) {
        let _ = leaderboard.entries.pop_back();
    };

    leaderboard.entries.push_back(LeaderboardEntry(addr, value));
    leaderboard.sort();
}

/// Sort the leaderboard in DESC order of `value`.
public fun sort(leaderboard: &mut Leaderboard) {
    let mut i = 1;

    while (i < leaderboard.entries.length()) {
        let mut j = i;
        while (
            j > 0 && leaderboard.entries[j-1].value() < leaderboard.entries[j].value()
        ) {
            leaderboard.entries.swap(j-1, j);
            j = j - 1;
        };
        i = i + 1;
    }
}
