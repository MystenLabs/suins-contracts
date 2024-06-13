// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// The overall concept of the discord system is a way to
/// reward discord community members, who get specific roles on discord based on their actions.

/// The approach is that we have a Discord shared object.
/// We define a specific role-set off-chain, and we save it in the format:
/// role_id (0-256) (corresponds to off-chain naming ~ e.g. 0 -> Master, 1 -> Another_Role) | discount_percentage

/// After the setup has been done, the BE can sign messages to:
/// 1. Attach roles to a discordId. DiscordID is our "unique" trusted actor here,
///    since the users will be able to call the BE only through a discord bot, which can recognize their discord id.
/// 2. Set the user's address. That helps map a discordId to an on-chain address, so that this address can convert the points to coupons.

/// After any setup has been made, a user, whose address belongs to a mapping, can come in and
/// claim coupons based on the available points.
/// E.g., if the `Member` has 100 points, the user can come and claim any amount of coupons that count up to 100%.
/// The moment the coupon is generated, the address can't change.

/// The coupon's format that is being generated is calculated based on hash(discord_id + claim_idx)
module discord::discord {
    use std::string::String;
    use sui:: {
        vec_map::{Self, VecMap},
        vec_set::{Self, VecSet},
        bcs,
        table::{Self, Table},
        ecdsa_k1,
        address,
        hash::blake2b256 as hash,
    };
    use coupons::{
        coupon_house,
        rules,
        range,
        constants::{percentage_discount_type},
    };
    use suins::suins::SuiNS;

    /// Errors

    /// Public Key is not valid (empty array)
    const EInvalidPublicKey: u64 = 0;
    /// Discount not in range [0,100]
    const EInvalidDiscount: u64 = 1;
    /// Member already has that role attached
    const ERoleAlreadyExists: u64 = 2;
    /// Discord ID not found, even though mapping exists.
    const EDiscordIdNotFound: u64 = 3;
    /// Tries to attach empty vector of roles.
    const ENoRolesFound: u64 = 4;
    /// Tries to attach a non existing role to a member
    const ERoleNotExists: u64 = 5;
    /// Tries to attach a role which the member has already claimed the rewards for.
    const ERoleAlreadyAssigned: u64 = 6;
    /// Not a matching signature, can't do any attaching
    const ESignatureNotMatch: u64 = 7;
    /// Tries to claim a coupon without being in the system
    const EAddressNoMapping: u64 = 8;
    /// Tries to claim a coupon higher than the available points.
    const ENotEnoughPoints: u64 = 9;

    /// authorization struct, to allow the app to create coupons in the coupon system.
    public struct DiscordApp has drop {}

    /// Capability for Discord Application.
    public struct DiscordCap has key, store { id: UID }

    public struct Owner has store, drop { 
        updates: u32,
        addr: Option<address>
    }

    /// A Discord Member profile.
    public struct Member has store, drop {
        /// Available points that can be converted into coupon codes. 1 point -> 1% discount.
        available_points: u64,
        /// Roles already assigned to a member. Helps us verify we never give the same rewards twice.
        roles: VecSet<u8>,
        /// List of coupons claimed by the user.
        claimed_coupons: vector<String>,
        /// Mapping of DiscordId -> Address
        owner: Owner
    }

    /// Discord Shared Object.
    public struct Discord has key {
        id: UID,
        /// A public key, the backend signs messages that this key can verify.
        public_key: vector<u8>, 
        /// mapping a roleId -> percentage discount ([0,100]) (Up to 256 roles)
        discord_roles: VecMap<u8, u8>, 

        /// DiscordId -> Member
        users: Table<String, Member>, 
        // /// Mapping of DiscordId -> Address
        // address_mapping: Table<String, AddressMapping> 
    }

    fun init(ctx: &mut TxContext){
        transfer::share_object(Discord {
            id: object::new(ctx),
            public_key: vector::empty(),
            discord_roles: vec_map::empty(),
            users: table::new(ctx),
        });

        transfer::transfer(DiscordCap {
            id: object::new(ctx)
        }, ctx.sender());
    }

    /// A signature protected route, which the BE signs, which allows adding roles.
    /// Can be called by anyone, only works for the { discord_id -> roles[] } mapping.
    public fun attach_roles(discord: &mut Discord, signature: vector<u8>, discord_id: String, roles: vector<u8>) {
        let mut msg_bytes = vector::empty<u8>();
        msg_bytes.append(b"roles_");
        msg_bytes.append(*discord_id.bytes());
        msg_bytes.append(roles);

        // Verify that the signed message is valid.
        // The signed message should contain a valid `discord_id : roles` mapping
        assert!(ecdsa_k1::secp256k1_verify(&signature, &discord.public_key, &msg_bytes, 1), ESignatureNotMatch);

        // if the table doens't contain that discord membership,add it.
        if (!discord.users.contains(discord_id)) discord.users.add(discord_id, new_member());

        let member = discord.users.borrow_mut(discord_id); // borrow a mutable reference. 
        member.add_roles_internal(roles, &discord.discord_roles);
    }

    /// A function to set the address mapping for a DiscordID <-> Address.
    /// Can be called only by anyone, only works for a specific pair (address -> discordId)
    /// which is signed by the BE.
    public fun set_address(discord: &mut Discord, signature: vector<u8>, discord_id: String, addr: address) {
        let member = if (!discord.users.contains(discord_id)) {
            discord.users.add(discord_id, new_member());
            discord.users.borrow_mut(discord_id)
        } else {
            discord.users.borrow_mut(discord_id)
        };

        let updates_count = member.owner.updates;

        // set the mapping address!
        member.owner.addr = option::some(addr);
        member.owner.updates = updates_count + 1;

        let mut msg_bytes = vector::empty<u8>();

        msg_bytes.append(b"address_");
        msg_bytes.append(bcs::to_bytes(&updates_count));
        msg_bytes.append(*discord_id.bytes());
        msg_bytes.append(addr.to_bytes());

        // verify that the signed message is the address of the user.
        assert!(ecdsa_k1::secp256k1_verify(&signature, &discord.public_key, &msg_bytes, 1), ESignatureNotMatch); 
    }

    /// A user protected function to generate a coupon based on Membership data.
    /// Only claimable if there's a mapping {discord_id -> address (which needs to be the sender)}
    public fun claim_coupon(discord: &mut Discord, suins: &mut SuiNS, discord_id: String, amount: u8, ctx: &mut TxContext) {
        let coupon_code = discord.claim_coupon_internal(discord_id, amount, ctx);
        let app = coupon_house::app_data_mut(suins, DiscordApp {});

        // Generates the coupon code.
        // A percentage off coupon that's only valid for that user, and has 1 claim.
        coupon_house::app_add_coupon(
            app,
            coupon_code, 
            percentage_discount_type(),
            (amount as u64),
            rules::new_coupon_rules(
                option::none(), // Available for all domain sizes.
                option::some(1), // Available only for one claim
                option::some(ctx.sender()), // Specific to the transaction sender.
                option::none(), // expiration timestamp
                option::some(range::new(1,1)) // available years -> Only 1 year registrations.
            ),
            ctx
        );
    }

    /// Admin Actions
    public fun set_public_key(_: &DiscordCap, discord: &mut Discord, key: vector<u8>, ) {
        assert!(key.length() > 0, EInvalidPublicKey);
        discord.public_key = key;
    }

    /// We allow adding discord roles, but not removing one.
    /// This way we make sure that unique role_ids are mapped per Member.
    /// We can simply ignore (not sign) any messages tht include this role.
    public fun add_discord_role(_: &DiscordCap, discord: &mut Discord, role_id: u8, discount: u8){
        // check if discount amount is valid.
        assert_is_valid_discount(discount);
        assert!(!discord.discord_roles.contains(&role_id), ERoleAlreadyExists);
        discord.discord_roles.insert(role_id, discount);
    }

    /// discount is in range (0,100]
    public fun assert_is_valid_discount(discount: u8) {
        assert!(discount > 0 && discount <= 100, EInvalidDiscount);
    }

    /// internal function to add roles to a member and save the points.
    /// Aborts if the member already had these roles.
    fun add_roles_internal(member: &mut Member, mut roles: vector<u8>, discord_roles: &VecMap<u8, u8>) {
        // checks if new roles vector is empty.
        assert!(!roles.is_empty(), ENoRolesFound);

        while(!roles.is_empty()){
            let role = roles.pop_back();
            // 1. Member shouldn't have this role
            assert!(!member.roles.contains(&role), ERoleAlreadyAssigned);

            // 2. This role needs to be valid (exist in discord_roles)
            assert!(discord_roles.contains(&role), ERoleNotExists);

            member.roles.insert(role);

            // add discount to the member's available points. We can cast u8 to u64 safely.
            member.available_points = member.available_points + (discord_roles[&role] as u64);
        };
    }

    /// Getters
    public fun available_points(member: &Member): u64 {
        member.available_points
    }

    public fun member_roles(member: &Member): VecSet<u8> {
        member.roles
    }

    public fun member(discord: &Discord, discord_id: String): &Member {
        discord.users.borrow(discord_id)
    }

    /// An internal coupon claim handler that validates data, creates the coupon code, updates membership details
    /// and returns the `coupon_code` to be registered.
    public(package) fun claim_coupon_internal(discord: &mut Discord, discord_id: String, amount: u8, ctx: &TxContext): String {
        // check the amount asked is valid.
        assert_is_valid_discount(amount);

        // Verify that the discord_id exists on both the mapping and the users.
        assert!(discord.users.contains(discord_id), EDiscordIdNotFound);

        // Find the user mapped to that discord id.
        let mapping = &discord.users[discord_id];
        assert!(mapping.owner.addr.is_some() && mapping.owner.addr.borrow() == ctx.sender(), EAddressNoMapping);

        let member = &mut discord.users[discord_id];
        assert!(member.available_points >= (amount as u64), ENotEnoughPoints);

        // Generate a predictable coupon code
        // We generate it by the hash(discord_id + total coupons claimed)
        // so for first it's discord_id+0, second is discord_id+1 ...
        // That way, we could predict the copon codes off-chain too.
        let coupon_code = address::to_string(address::from_bytes(
            hash(
                &bcs::to_bytes(&vector[bcs::to_bytes(&discord_id), bcs::to_bytes(&member.claimed_coupons.length())
            ])
        )));

        member.available_points = member.available_points - (amount as u64);
        member.claimed_coupons.push_back(coupon_code); // save coupon in the users claimed list.

        coupon_code
    }

    fun new_member(): Member {
        Member {
            available_points: 0,
            roles: vec_set::empty(),
            claimed_coupons: vector::empty(),
            owner: Owner {
                updates: 0,
                addr: option::none()
            }
        }
    }

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(ctx)
    }
}
