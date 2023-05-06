module suins::nft_policy {
    use kiosk::royalty_rule;

    use sui::tx_context::{Self, TxContext};
    use sui::transfer_policy;
    use sui::transfer;
    use sui::package::Publisher;

    use suins::registration_nft::RegistrationNFT;

    /// Admin should only call this function once
    public entry fun init_policy(
        publisher: &Publisher,
        ctx: &mut TxContext
    ) {
        let (policy, policy_cap) = transfer_policy::new<RegistrationNFT>(publisher, ctx);

        royalty_rule::add(&mut policy, &policy_cap, 250, 0);

        transfer::public_share_object(policy);
        transfer::public_transfer(policy_cap, tx_context::sender(ctx));
    }

    // === Friend and Private Functions ===

    #[test_only] struct Rule has drop {}

    #[test_only]
    public fun new_rule_for_testing(): Rule {
        Rule {}
    }
}
