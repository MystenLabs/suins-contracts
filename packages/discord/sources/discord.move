// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

module discord::discord{
    use std::string::{Self, String};
    use std::vector;

    use sui::vec_map::{Self, VecMap};
    use sui::object::{Self, UID};
    use sui::table::{Self, Table};
    use sui::tx_context::{TxContext, sender};
    use sui::transfer;
    use sui::ecdsa_k1;
    use sui::address;


    // Errors

    const EInvalidPublicKey: u64 = 0;
    const EInvalidDiscount: u64 = 1;
    const ERoleAlreadyExists: u64 = 2;
    const EDiscordIdNotFound: u64 = 3;
    const ENoRolesFound: u64 = 4;
    const ERoleNotExists: u64 = 5;
    const ERoleAlreadyAssigned: u64 = 6;
    const ESignatureNotMatch: u64 = 7; // invalid signature supplied.

    // authorization struct, to allow the app to create coupons in the coupon system.
    struct DiscordApp has drop {}
    // Capability for Discord Application.
    struct DiscordCap has key, store {
        id: UID
    }

    // A Discord Member profile.
    struct Member has copy, store, drop {
        available_points: u64,
        roles: vector<u8>,
        coupons_claimed: u64
    }

    // Discord Shared Object.
    struct Discord has key, store {
        id: UID,
        public_key: vector<u8>, // A public key, the backend signs messages that this key can verify.
        discord_roles: VecMap<u8, u8>, // mapping a roleId -> percentage discount ([0,100]) (Up to 256 roles)
        users: Table<String, Member>, //  String -> DiscordId
        address_mapping: Table<address, String> // address -> discordId
    }

    fun init(ctx: &mut TxContext){
        transfer::share_object(Discord {
            id: object::new(ctx),
            public_key: vector::empty(),
            discord_roles: vec_map::empty(),
            users: table::new(ctx),
            address_mapping: table::new(ctx)
        });

        transfer::public_transfer(DiscordCap {
            id: object::new(ctx)
        }, sender(ctx));
    }

    // A signature protected route, which the BE signs, which allows adding roles.
    // Can be called by anyone, only works for the discord_id / roles mapping.
    public fun attach_roles(self: &mut Discord, signature: vector<u8>, discord_id: String, roles: vector<u8>) {

        let msg_bytes = vector::empty<u8>();
        vector::append(&mut msg_bytes, *string::bytes(&discord_id));
        vector::append(&mut msg_bytes, roles);

        // verify that the signed message is valid.
        // The signed message should contain a valid `discord_id : roles` mapping
        assert!(ecdsa_k1::secp256k1_verify(&signature, &self.public_key, &msg_bytes, 1), ESignatureNotMatch);

        let member: Member;
        if (table::contains(&self.users, discord_id)) {
            member = table::remove(&mut self.users, discord_id); // remove the table 
        }else {
            member = new_member_internal();
        };

        table::add(&mut self.users, discord_id, add_roles_internal(member, roles, self.discord_roles));
    }

    // A function to set the address mapping for a DiscordID <-> Address.
    // Can be called only by anyone, only works for a specific pair (address -> discordId)
    // which is signed by the BE.
    public fun set_address(self: &mut Discord, signature: vector<u8>, discord_id: String, addr: address) {

        let msg_bytes = vector::empty<u8>();
        vector::append(&mut msg_bytes, *string::bytes(&discord_id));
        vector::append(&mut msg_bytes, address::to_bytes(addr));

        // verify that the signed message is the address of the user.
        assert!(ecdsa_k1::secp256k1_verify(&signature, &self.public_key, &msg_bytes, 1), ESignatureNotMatch);

        // IF there's a value, remove it and replace it with the new one.
        if(table::contains(&self.address_mapping, addr)){
            table::remove(&mut self.address_mapping, addr);
        };

        table::add(&mut self.address_mapping, addr, discord_id);
    }


    // A user protected function to generate a coupon based on Membership data.
    // Only claimable if there's a mapping {discord_id -> address (which needs to be the sender)}
    // public fun claim_coupon(discord_id: String, amount: u64)


    // Admin Actions
    public fun set_public_key(_: &DiscordCap, self: &mut Discord, key: vector<u8>, ) {
        assert!(vector::length(&key) > 0, EInvalidPublicKey);
        self.public_key = key;
    }

    // We allow adding discord roles, but not removing one.
    // This way we make sure that unique role_ids are mapped per Member.
    // We can simply ignore (not sign) any messages tht include this role.
    public fun add_discord_role(_: &DiscordCap, self: &mut Discord, role_id: u8, discount: u8){
        // check if discount amount is valid.
        assert_is_valid_discount(discount);
        assert!(!vec_map::contains(&self.discord_roles, &role_id), ERoleAlreadyExists);
        vec_map::insert(&mut self.discord_roles, role_id, discount);
    }


    // discount is in range [0,100]
    public fun assert_is_valid_discount(discount: u8) {
        assert!(discount >= 0 && discount <= 100, EInvalidDiscount);
    }



    // internal function to add roles to a member.
    // Aborts if the member already had these roles.
    // Also saves points.
    fun add_roles_internal(member: Member, roles: vector<u8>, discord_roles: VecMap<u8, u8>): Member {
        // checks if new roles vector is empty.
        assert!(!vector::is_empty(&roles), ENoRolesFound);

        while(!vector::is_empty(&roles)){
            let role = vector::pop_back(&mut roles);
            // we need to check:
            // 1. Member shouldn't have this role
            assert!(!vector::contains(&member.roles, &role), ERoleAlreadyAssigned);

            // 2. This role needs to be valid (exist in discord_roles)
            assert!(vec_map::contains(&discord_roles, &role), ERoleNotExists);

            // add role to the member.
            vector::push_back(&mut member.roles, role);
            // add discount to the member's available points. We can cast u8 to u64 safely.
            member.available_points = member.available_points + (*vec_map::get(&discord_roles, &role) as u64);
        };

        member
    }

    fun new_member_internal(): Member {
        Member {
            available_points: 0,
            roles: vector::empty(),
            coupons_claimed: 0
        }
    }

}
