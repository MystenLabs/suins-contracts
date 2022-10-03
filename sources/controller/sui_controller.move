module suins::sui_controller {

    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::vec_map::{Self, VecMap};
    use sui::crypto::keccak256;
    use std::bcs;
    use std::vector;

    // errors in the range of 301..400 indicate Sui Controller errors
    const EInvalidResolverAddress: u64 = 301;

    struct SuiController has key {
        id: UID,
        commitments: VecMap<vector<u8>, u64>,
    }

    fun init(ctx: &mut TxContext) {
        transfer::share_object(SuiController {
            id: object::new(ctx),
            commitments: vec_map::empty(),
        });
    }

    public entry fun make_commitment(
        controller: &mut SuiController,
        label: vector<u8>,
        owner: address,
        secret: vector<u8>,
        ctx: &mut TxContext,
    ) {
        make_commitment_with_config(controller, label, owner, secret, @0x0, @0x0, ctx);

    }

    public entry fun make_commitment_with_config(
        controller: &mut SuiController,
        label: vector<u8>,
        owner: address,
        secret: vector<u8>,
        resolver: address,
        addr: address,
        ctx: &mut TxContext,
    ) {
        // TODO: only serialize input atm,
        // wait for https://github.com/move-language/move/pull/408 to be merged for encoding
        if (resolver == @0x0 && addr == @0x0) {
            let owner_bytes = bcs::to_bytes(&owner);
            vector::append(&mut label, owner_bytes);
            vector::append(&mut label, secret);
        } else {
            assert!(resolver != @0x0, EInvalidResolverAddress);

            let owner_bytes = bcs::to_bytes(&owner);
            let resolver_bytes = bcs::to_bytes(&resolver);
            let addr_bytes = bcs::to_bytes(&addr);

            vector::append(&mut label, owner_bytes);
            vector::append(&mut label, resolver_bytes);
            vector::append(&mut label, addr_bytes);
            vector::append(&mut label, secret);
        };
        let commitment = keccak256(label);
        vec_map::insert(&mut controller.commitments, commitment, tx_context::epoch(ctx));
    }

    #[test_only]
    public fun len(controller: &SuiController): u64 {
        vec_map::size(&controller.commitments)
    }
    #[test_only]
    /// Wrapper of module initializer for testing
    public fun test_init(ctx: &mut TxContext) { init(ctx) }
}