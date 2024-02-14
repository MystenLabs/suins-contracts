// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

// This module:
// 1. Acts as a proxy for authorized apps to be able to register paying reseller fees (paying commission)
// 2. Allows admin to authorize resellers with a specified fee.
// 3. Allows authorized resellers to get their earnings by presenting the `ResellerCap`.
module suins::reseller {

    use std::option::{Self, Option};
    use std::string::{String};

    use sui::table::{Self, Table};
    use sui::object::{Self, UID};
    use sui::balance::{Self, Balance};
    use sui::sui::SUI;
    use sui::tx_context::{TxContext};
    use sui::coin::{Self, Coin};

    use suins::suins::{Self, SuiNS, AdminCap};

    /// The specified reseller already exists.
    const EAlreadyExists: u64 = 1;
    /// The specified reseller doesn't exist.
    const EResellerNotExists: u64 = 2;
    /// The specified commission is invalid (not in range [1, 10_000])
    const EInvalidComission: u64 = 3;
    /// Tries to handle payment with a disabled reseller code.
    const EResellerDisabled: u64 = 4;

    /// The ResellerCap, which allows access to withdraw funds as a reseller.
    /// We can only have 1 of these per authorized reseller.
    struct ResellerCap has key, store {
        id: UID,
        for: String
    }

    /// The configuration for each reseller. Each reseller has:
    /// `balance`: It keeps the commission fees
    /// `enabled`: Whether this reseller code is still enabled
    /// `commission` The commission percentage (2 digit precision)
    struct ResellerConfig has store {
        enabled: bool,
        balance: Balance<SUI>,
        // 10_000 = 100% | 9_999 -> 99.99%
        commission: u16 // [1, 10_000]. Works with 2 digit precision.
    }

    /// The shared object that holds information about the resellers.
    struct ResellerBoard has store {
        resellers: Table<String, ResellerConfig>
    }

    // Authorizes reseller app to use `ResellerBoard` registry from SuiNS shared object.
    struct ResellerApp has drop {}

    /// Called once by an admin to set up the ResellerBoard.
    public fun setup(self: &mut SuiNS, cap: &AdminCap, ctx: &mut TxContext) {
        suins::add_registry(cap, self, ResellerBoard {
            resellers: table::new(ctx)
        });
    }

    /// Authorizes a new reseller in the system as an admin.
    /// Returns a `ResellerCap` which can be transferred to the partner for winnings withdrawing.
    public fun authorize(self: &mut SuiNS, _: &AdminCap, reseller: String, commission: u16, ctx: &mut TxContext): ResellerCap {
        let board = reseller_board_mut(self);

        validate_commission(commission);
        // validate that this reseller doesn't already exist.
        assert!(!table::contains(&board.resellers, reseller), EAlreadyExists);

        table::add(&mut board.resellers, reseller, ResellerConfig {
            enabled: true,
            balance: balance::zero(),
            commission
        });

        ResellerCap {
            id: object::new(ctx),
            for: reseller
        }
    }

    /// Withdraw all commissions earned as a reseller.
    public fun withdraw(self: &mut SuiNS, cap: &ResellerCap, ctx: &mut TxContext): Coin<SUI> {

        let board = reseller_board_mut(self);
        // that's a sanity check since we don't have a way to remove a reseller (and do not plan to)
        assert!(table::contains(&board.resellers, cap.for), EResellerNotExists);

        let config = table::borrow_mut(&mut board.resellers, cap.for);
        let total = balance::value(&config.balance);
        coin::take(&mut config.balance, total, ctx)
    }

    /// Handles a payment for reselling system. 
    /// Now, on our authorized modules, instead of calling `app_add_balance`, we can call this payment handler 
    /// instead, which supports reseller codes.
    /// This module on its own has no authorization, it just proxies the authorization from an authorized one.
    /// `A` must be an authorized app on its own. This just proxies the payment.
    /// This method also doesn't offer validation. Price checking & amount checking should be 
    /// done on modules that call this.
    public fun handle_payment<A: drop>(
        app: A,
        self: &mut SuiNS,
        payment: Coin<SUI>,
        reseller: Option<String>,
        ctx: &mut TxContext
    ) {
        // If we have a reseller code, we take the commission fee.
        if(option::is_some(&reseller)){
            let board = reseller_board_mut(self);
            let code = *option::borrow(&reseller);
            assert!(table::contains(&board.resellers, code), EResellerNotExists);

            let settings = table::borrow_mut(&mut board.resellers, code);

            assert!(settings.enabled, EResellerDisabled);
            let value = coin::value(&payment);
            let commission = coin::split(&mut payment, calculate_comission_fee(value, settings.commission), ctx);

            balance::join(&mut settings.balance, coin::into_balance(commission));
        };
        suins::app_add_balance(app, self, coin::into_balance(payment))
    }

    /// Allows to set the enabled (enable or disable) a reseller code.
    public fun set_enabled(self: &mut SuiNS, _: &AdminCap, reseller: String, enabled: bool) {
        let board = reseller_board_mut(self);
        assert!(table::contains(&board.resellers, reseller), EResellerNotExists);

        let config = table::borrow_mut(&mut board.resellers, reseller);
        config.enabled = enabled
    }

    /// Set the commission rate for the reseller code.
    public fun set_commission(self: &mut SuiNS, _: &AdminCap, reseller: String, commission: u16) {
        let board = reseller_board_mut(self);
         assert!(table::contains(&board.resellers, reseller), EResellerNotExists);
         validate_commission(commission);
        
        let config = table::borrow_mut(&mut board.resellers, reseller);
        config.commission = commission
    }

    /// Calculates the commission fee due to payment to the reseller.
    public fun calculate_comission_fee(payment: u64, commission: u16): u64 {
        let amount = (((payment as u128) * (commission as u128) / 10_000) as u64);
        amount
    }

    /// Valiates the commission is valid (is in range [1, 10_000])
    fun validate_commission(commission: u16) {
        assert!(commission > 0 && commission <= 10_000, EInvalidComission)
    }

    /// Private immutable accessor for the Resellers registry
    fun reseller_board(self: &SuiNS): &ResellerBoard {
        suins::registry<ResellerBoard>(self)
    }

    /// Private mutable accessor for the Resellers registry
    fun reseller_board_mut(self: &mut SuiNS): &mut ResellerBoard {
        suins::app_registry_mut<ResellerApp, ResellerBoard>(ResellerApp {}, self)
    }
}
