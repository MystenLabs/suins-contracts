/// Module that keeps `coin_util` coin tracking logic.
/// TODO: consider removing completely.
module suins::coin_tracker {
    friend suins::suins;
    friend suins::auction;
    friend suins::controller;

    struct PaymentTransferredEvent has copy, drop {
        to: address,
        amount: u64,
    }

    public(friend) fun track(to: address, amount: u64) {
        sui::event::emit(PaymentTransferredEvent { to, amount })
    }
}
