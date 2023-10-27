// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// A module to help with authentication of D3 package.
/// It's here to avoid having overly large modules (split it so it is easier to read).
module d3::auth {
    use std::vector;

    use sui::object::{Self, UID, ID};
    use sui::balance::{Self, Balance};
    use sui::sui::SUI;
    use sui::tx_context::{TxContext};
    use sui::transfer;

    use suins::suins::{Self, SuiNS, AdminCap};
    use suins::registry::{Registry};

     // will be removed when `public(package)` is supported.
    friend d3::d3;

    /// The cap is not authorized to mint names.
    const ECapNotAuthorized: u64 = 1;

    /// Authorization token for the app.
    struct DThreeApp has drop {}

    /// A cap that D3's backend address will use.
    /// We hold a list of the authorized ones in the contract too
    /// to be able to deauthorize them in case of keys being lost.
    struct DThreeCap has key { 
        id: UID
    }

    /// A config object that holds a list of authorized D3 caps.
    /// We use to to make sure that we can deauthorize them if a key is lost in a backend breach.
    /// 
    /// We also hold a balance, which will be used in a future version of this package to convert a simple
    /// SuinsRegistration object into a D3 compliant one (and pay the fee).
    struct DThreeConfig has store {
        allowed_keys: vector<ID>,
        balance: Balance<SUI>
    }

    /// Sets up the D3 configuration object.
    /// We are ok to abort with default system errors (no reason to add custom error in case config exists)
    public fun setup(suins: &mut SuiNS, cap: &AdminCap) {
        suins::add_registry(cap, suins, DThreeConfig {
            allowed_keys: vector::empty(),
            balance: balance::zero()
        })
    }

    /// === Minting Names === 
    ///
    /// Mints a new DThreeCap by admin. Authorizes it in the allowed_keys vector.
    public fun mint_cap(suins: &mut SuiNS, _: &AdminCap, addr: address, ctx: &mut TxContext) {
        let cap = DThreeCap {
                id: object::new(ctx)
        };

        vector::push_back(d3_allowed_keys_mut(suins), object::id(&cap));
        transfer::transfer(cap, addr);
    }

    /// Admin of SuiNS can deauthorize a Cap. 
    /// Used in case of a cap leak from D3's BE.
    public fun deauthorize_cap(suins: &mut SuiNS, _: &AdminCap, id: ID) {
        let (cap_exists, index) = vector::index_of(d3_allowed_keys(suins), &id);
    
        if(cap_exists){
            let _id = vector::remove(d3_allowed_keys_mut(suins), index);
        }else {
            abort ECapNotAuthorized
        }
    }

    /// These all will become public(package) when it is available.
    /// === Getters / Mut getters === 

    public fun d3_balance(suins: &SuiNS): &Balance<SUI> {
        &d3_config(suins).balance
    }

    public(friend) fun d3_balance_mut(suins: &mut SuiNS): &mut Balance<SUI> {
        &mut d3_config_mut(suins).balance
    }

    public fun d3_allowed_keys(suins: &SuiNS): &vector<ID> {
        &d3_config(suins).allowed_keys
    }

    public(friend) fun d3_allowed_keys_mut(suins: &mut SuiNS): &mut vector<ID> {
        &mut d3_config_mut(suins).allowed_keys
    }

    public fun d3_config(suins: &SuiNS): &DThreeConfig {
        suins::registry(suins)
    }

    public(friend) fun d3_config_mut(suins: &mut SuiNS): &mut DThreeConfig {
        suins::app_registry_mut<DThreeApp, DThreeConfig>(DThreeApp {}, suins)
    }

    public fun registry(suins: &SuiNS): &Registry {
        suins::registry(suins)
    }

    /// Will be converted to `public(package)` once available.
    public(friend) fun registry_mut(suins: &mut SuiNS): &mut Registry {
        suins::app_registry_mut<DThreeApp, Registry>(DThreeApp {}, suins)
    }

    public fun assert_app_authorized(suins: &SuiNS) {
        suins::assert_app_is_authorized<DThreeApp>(suins);
    }
}
