// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0


// The overall concept of the discord system is a way to
// reward discord community members, who get specific roles on discord based on their actions.

// The approach is that we have a Discord shared object.
// We define a specific role-set off-chain, and we save it in the format:
// role_id (0-256) (corresponds to off-chain naming ~ e.g. 0 -> Master, 1 -> Another_Role) | discount_percentage

// After the setup has been done, the BE can sign messages to:
// 1. Attach roles to a discordId. DiscordID is our "unique" trusted actor here,
//    since the users will be able to call the BE only through a discord bot, which can recognize their discord id internally.
// 2. Set the user's address. That helps map a discordId to an on-chain address, so that this address can convert the points to coupons.

// After any setup has been made, a user, whose address belongs to a mapping, can come in and
// claim coupons based on the available points.
// E.g., if the `Member` has 100 points, the user can come and claim any amount of coupons that count up to 100%.
// The moment the coupon is generated, the address can't change.

// The coupon's format that is being generated is `ds_{discord_id}_{coupons_claimed}`. 
// That help us have a unique set of coupon names, with no collision chances.

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

    // Public Key is not valid (empty array)
    const EInvalidPublicKey: u64 = 0;
    // Discount not in range [0,100]
    const EInvalidDiscount: u64 = 1;
    // Member already has that role attached
    const ERoleAlreadyExists: u64 = 2;
    // Discord ID not found, even though mapping exists.
    const EDiscordIdNotFound: u64 = 3;
    // Tries to attach empty vector of roles.
    const ENoRolesFound: u64 = 4;
    // Tries to attach a non existing role to a member
    const ERoleNotExists: u64 = 5;
    // Tries to attach a role which the member has already claimed the rewards for.
    const ERoleAlreadyAssigned: u64 = 6;
    // Not a matching signature, can't do any attaching
    const ESignatureNotMatch: u64 = 7;
    // Tries to claim a coupon without being in the system
    const EAddressNoMapping: u64 = 8;
    // Tries to claim a coupon higher than the available points.
    const ENotEnoughPoints: u64 = 9;

    // authorization struct, to allow the app to create coupons in the coupon system.
    struct DiscordApp has drop {}

    // Capability for Discord Application.
    struct DiscordCap has key, store {
        id: UID
    }

    // A Discord Member profile.
    struct Member has store {
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
    // Can be called by anyone, only works for the { discord_id -> roles[] } mapping.
    public fun attach_roles(self: &mut Discord, signature: vector<u8>, discord_id: String, roles: vector<u8>) {

        let msg_bytes = vector::empty<u8>();
        vector::append(&mut msg_bytes, *string::bytes(&discord_id));
        vector::append(&mut msg_bytes, roles);

        // Verify that the signed message is valid.
        // The signed message should contain a valid `discord_id : roles` mapping
        assert!(ecdsa_k1::secp256k1_verify(&signature, &self.public_key, &msg_bytes, 1), ESignatureNotMatch);

        // if the table doens't contain that discord membership,add it.
        if (!table::contains(&self.users, discord_id)) table::add(&mut self.users, discord_id, new_member_internal());

        let member = table::borrow_mut(&mut self.users, discord_id); // borrow a mutable reference. 

        add_roles_internal(member, roles, &self.discord_roles);
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
    public fun claim_coupon(self: &mut Discord, amount: u8, ctx: &mut TxContext) {

        // TODO: First check should be an authorization check that we can indeed create a coupon.

        // check the amount asked is valid.
        assert_is_valid_discount(amount);

        // check that the address mapping has a discord id.
        assert!(table::contains(&self.address_mapping, sender(ctx)), EAddressNoMapping);

        // borrow discord id from table
        let discord_id = *table::borrow(&self.address_mapping, sender(ctx));
        assert!(table::contains(&self.users, discord_id), EDiscordIdNotFound);

        let member = table::borrow_mut(&mut self.users, discord_id);
        assert!(member.available_points >= (amount as u64), ENotEnoughPoints);

        member.available_points = member.available_points - (amount as u64);
        member.coupons_claimed = member.coupons_claimed + 1;

        // TODO: CREATE A COUPON BASED ON THE AMOUNT, USING THE COUPONS SYSTEM.
        // STEPS TO ACCOMPLISH:
        // 1. Add `coupons` dependency.
        // 2. Authorize `DiscordApp` to be able to create new coupons there.
        // 3. Generate the coupon code based on discord.

    }

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


    // internal function to add roles to a member and save the points.
    // Aborts if the member already had these roles.
    fun add_roles_internal(member: &mut Member, roles: vector<u8>, discord_roles: &VecMap<u8, u8>) {
        // checks if new roles vector is empty.
        assert!(!vector::is_empty(&roles), ENoRolesFound);

        while(!vector::is_empty(&roles)){
            let role = vector::pop_back(&mut roles);
            // 1. Member shouldn't have this role
            assert!(!vector::contains(&member.roles, &role), ERoleAlreadyAssigned);

            // 2. This role needs to be valid (exist in discord_roles)
            assert!(vec_map::contains(discord_roles, &role), ERoleNotExists);

            // add role to the member.
            vector::push_back(&mut member.roles, role);
            // add discount to the member's available points. We can cast u8 to u64 safely.
            member.available_points = member.available_points + (*vec_map::get(discord_roles, &role) as u64);
        };
    }

    // fn to generate a new Member.
    fun new_member_internal(): Member {
        Member {
            available_points: 0,
            roles: vector::empty(),
            coupons_claimed: 0
        }
    }

    // Getters

    public fun coupons_claimed(member: &Member): u64 {
        member.coupons_claimed
    }

    public fun available_points(member: &Member): u64 {
        member.available_points
    }

    public fun roles(member: &Member): vector<u8> {
        member.roles
    }

    public fun get_member(self: &Discord, discord_id: &String): &Member {
        table::borrow(&self.users, *discord_id)
    }

    public fun get_discord_roles(self: &Discord): &VecMap<u8,u8> {
        &self.discord_roles
    }

    public fun get_discord_users(self: &Discord): &Table<String, Member> {
        &self.users
    }

    public fun get_addresses_mapping(self: &Discord): &Table<address, String> {
        &self.address_mapping
    }

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(ctx)
    }
}
