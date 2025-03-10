/// The governance module for SuiNS.
///
/// The governance module is used to:
/// 1. Store the NS token reserves
/// 2. Store the UpgradeCap for SuiNS protocol
/// 3. Store the AdminCap for SuiNS protocol
/// 4. Store the Governance votes & Proposals for SuiNS protocol
/// 5. Apply verified proposals to the SuiNS protocol using these caps
/// 6. Store the UpgradeCap of the NSGovernance protocol
///   - Upgrades to the governance protocol go through typical voting, similar
/// to the SuiNS protocol.
///
/// In the initial phase of the release, this only supports "early_voting" which
/// is a simple voting mechanism, without complex actions.
module suins_voting::governance;

use sui::dynamic_field as df;
use sui::package;

use fun df::add as UID.add;
use fun df::borrow as UID.borrow;
use fun df::borrow_mut as UID.borrow_mut;
use fun df::remove as UID.remove;
use fun df::exists_with_type as UID.exists_with_type;

const EInvalidVersion: u64 = 1;

/// active version of the protocol.
const VERSION: u16 = 1;

/// Total supply of NS tokens is 500M. Hardcoded since this is fixed and known.
const NS_TOTAL_SUPPLY: u64 = 500_000_000 * 1_000_000;

/// The quorum threshold for the governance system.
const QUORUM_THRESHOLD: u64 = 1_500_000 * 1_000_000;

// One-time Witness to claim publisher.
public struct GOVERNANCE has drop {}

/// The KEY for any application stored under the governance object.
public struct Application<phantom K> has copy, store, drop {}

/// The NSGovernance object, which holds all the governance related objects /
/// capabilities.
public struct NSGovernance has key {
    id: UID,
    /// the version of the protocol. Allows us to upgrade the governance
    /// contract.
    version: u16,
    // The total NS supply. Useful to calculate thresholds.
    ns_total_supply: u64,
    // Total NS token vote needed for quorum.
    quorum_threshold: u64,
}

/// The governance cap for the NSGovernance object.
/// This cap is held by the foundation in a multisig, and is initially used for
/// adding proposals to early voting.
/// This will also most likely be re-used to add proposals in the more complex
/// system too,
public struct NSGovernanceCap has key, store {
    id: UID,
}

fun init(otw: GOVERNANCE, ctx: &mut TxContext) {
    package::claim_and_keep(otw, ctx);
    transfer::share_object(new(ctx));
    transfer::public_transfer(
        NSGovernanceCap {
            id: object::new(ctx),
        },
        ctx.sender(),
    );
}

public(package) fun new(ctx: &mut TxContext): NSGovernance {
    NSGovernance {
        id: object::new(ctx),
        version: VERSION,
        ns_total_supply: NS_TOTAL_SUPPLY,
        quorum_threshold: QUORUM_THRESHOLD,
    }
}

public fun ns_total_supply(governance: &NSGovernance): u64 {
    governance.ns_total_supply
}

public fun is_valid_version(governance: &NSGovernance): bool {
    governance.version == VERSION
}

public fun quorum_threshold(governance: &NSGovernance): u64 {
    governance.quorum_threshold
}

/// Allows admin to set the quorum threshold.
public fun set_quorum_threshold(
    _: &NSGovernanceCap,
    governance: &mut NSGovernance,
    threshold: u64,
) {
    governance.quorum_threshold = threshold;
}

// In the initial version, applications attached to the governance object
// are only controlled internally from the package (public(package) visibility).
// See `early_voting.move` for reference.

/// allows adding an application to the governance object.
public(package) fun add_app<V: store>(governance: &mut NSGovernance, value: V) {
    governance.assert_is_valid_version();
    governance.id.add(Application<V> {}, value);
}

/// allows borrowing an application (immutably) from the governance object.
public(package) fun app<V: store>(governance: &NSGovernance): &V {
    governance.assert_is_valid_version();
    governance.id.borrow(Application<V> {})
}

/// allows adding an application to the governance object.
public(package) fun app_mut<V: store>(governance: &mut NSGovernance): &mut V {
    governance.assert_is_valid_version();
    governance.id.borrow_mut(Application<V> {})
}

/// Allows checking if an application exists in the governance object.
public(package) fun has_app<V: store>(governance: &NSGovernance): bool {
    governance.assert_is_valid_version();
    governance.id.exists_with_type<_, V>(Application<V> {})
}

/// Allows removing an application from the governance object.
public(package) fun remove_app<V: store>(governance: &mut NSGovernance): V {
    governance.assert_is_valid_version();
    governance.id.remove(Application<V> {})
}

fun assert_is_valid_version(governance: &NSGovernance) {
    assert!(governance.is_valid_version(), EInvalidVersion);
}

#[test_only]
public fun init_for_testing(ctx: &mut TxContext) {
    init(GOVERNANCE {}, ctx)
}
