module suins::base_registry {
    use sui::event;
    use sui::object::{Self, UID, ID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::url::{Self, Url};
    use sui::vec_map;
    use std::string;
    use std::option::Option;
    use std::option;
    use std::string::String;

    // TODO: we don't have suins image atm, so temporarily use sui image instead
    const DEFAULT_URL: vector<u8> = b"ipfs://bafkreibngqhl3gaa7daob4i2vccziay2jjlp435cf66vhono7nrvww53ty";

    // errors in the range of 101..200 indicate Registry errors
    const EUnauthorized: u64 = 101;

    // https://examples.sui.io/patterns/capability.html
    struct AdminCap has key { id: UID }

    struct TransferEvent has copy, drop {
        node: String,
        owner: address,
    }

    struct NewOwnerEvent has copy, drop {
        node: String,
        owner: address,
    }

    struct NewResolverEvent has copy, drop {
        node: String,
        resolver: address,
    }

    struct NewTTLEvent has copy, drop {
        node: String,
        ttl: u64,
    }

    struct NewRecordEvent has copy, drop {
        node: String,
        owner: address,
        resolver: address,
        ttl: u64,
    }

    // send to owner of a domain, not store in registry
    struct RecordNFT has key {
        id: UID,
        node: String,
        // name and url fields have special meaning in sui explorer and extension
        // if url is a ipfs image, this image is showed on sui explorer and extension
        url: Url,
    }

    // objects of this type are stored in the registry's map
    struct Record has store, drop {
        node: String,
        owner: address,
        resolver: address,
        ttl: u64,
        nft_id: ID,
    }

    struct Registry has key {
        id: UID,
        records: vec_map::VecMap<String, Record>,
    }

    fun init(ctx: &mut TxContext) {
        transfer::transfer(AdminCap {
            id: object::new(ctx)
        }, tx_context::sender(ctx));

        transfer::share_object(Registry {
            id: object::new(ctx),
            records: vec_map::empty(),
        });
    }

    public(friend) fun get_registry_len(registry: &Registry): u64 {
        vec_map::size(&registry.records)
    }

    public(friend) fun get_record_NFT_node(record: &RecordNFT): String {
        record.node
    }

    public(friend) fun get_record_node(record: &Record): String {
        record.node
    }

    public(friend) fun get_record_owner(record: &Record): address {
        record.owner
    }

    public(friend) fun get_record_resolver(record: &Record): address {
        record.resolver
    }

    public(friend) fun get_record_ttl(record: &Record): u64 {
        record.ttl
    }

    // only registrar is allowed to call this
    public(friend) fun set_record(
        _: & AdminCap,
        registry: &mut Registry,
        node: vector<u8>,
        owner: address,
        resolver: address,
        ttl: u64,
        url: Option<Url>,
        ctx: &mut TxContext
    ) {
        let node = string::utf8(node);
        let _result = set_owner_or_create_record(
            registry,
            node,
            owner,
            option::some(resolver),
            option::some(ttl),
            url,
            ctx
        );
        // TODO: transfer subnode NFT to new owner if result == 0, delete subnode NFT if result == 2
        set_resolver_and_TTL(registry, node, resolver, ttl);
    }

    public(friend) fun set_subnode_record(
        _: & AdminCap,
        registry: &mut Registry,
        node: String,
        label: vector<u8>,
        owner: address,
        resolver: address,
        ttl: u64,
        url: Option<Url>,
        ctx: &mut TxContext
    ) {
        let subnode = make_subnode(label, node);
        let _result = set_owner_or_create_record(
            registry,
            subnode,
            owner,
            option::some(resolver),
            option::some(ttl),
            url,
            ctx
        );
        // TODO: transfer subnode NFT to new owner if result == true, delete subnode NFT if result == false
        set_resolver_and_TTL(registry, subnode, resolver, ttl);
    }

    // need to take ownership of RecordNFT to be able to delete it
    public entry fun set_owner(registry: &mut Registry, record_nft: RecordNFT, owner: address) {
        if (!authorised(registry, &record_nft)) {
            // this NFT is expired, so delete it
            let RecordNFT { id, node: _, url: _ } = record_nft;
            object::delete(id);
            return
        };

        let record = vec_map::get_mut(&mut registry.records, &record_nft.node);
        if (record.owner != owner) {
            record.owner = owner;
            event::emit(TransferEvent { node: record_nft.node, owner });
        };
        transfer::transfer(record_nft, owner)
    }

    public entry fun set_subnode_owner(
        registry: &mut Registry,
        record_nft: RecordNFT,
        label: vector<u8>,
        owner: address,
        ctx: &mut TxContext,
    ) {
        if (!authorised(registry, &record_nft)) {
            // this NFT is expired, so delete it
            let RecordNFT { id, node: _, url: _ } = record_nft;
            object::delete(id);
            return
        };
        let subnode = make_subnode(label, record_nft.node);
        set_owner_or_create_record(
            registry,
            subnode,
            owner,
            option::none<address>(),
            option::none<u64>(),
            option::none<Url>(),
            ctx,
        );
        transfer::transfer(record_nft, tx_context::sender(ctx));
        // TODO: transfer subnode NFT to new owner if result == 0, delete subnode NFT if result == 2
        // if (result == 0) transfer::transfer(T, owner);
    }

    public entry fun set_resolver(registry: &mut Registry, record_nft: RecordNFT, resolver: address, ctx: &mut TxContext) {
        if (!authorised(registry, &record_nft)) {
            // this NFT is expired, so delete it
            let RecordNFT { id, node: _, url: _ } = record_nft;
            object::delete(id);
            return
        };

        let record = vec_map::get_mut(&mut registry.records, &record_nft.node);
        if (record.resolver != resolver) {
            record.resolver = resolver;
            event::emit(NewResolverEvent { node: record.node, resolver });
        };
        transfer::transfer(record_nft, tx_context::sender(ctx));
    }

    public entry fun set_TTL(registry: &mut Registry, record_nft: RecordNFT, ttl: u64, ctx: &mut TxContext) {
        if (!authorised(registry, &record_nft)) {
            // this NFT is expired, so delete it
            let RecordNFT { id, node: _, url: _ } = record_nft;
            object::delete(id);
            return
        };

        let record = vec_map::get_mut(&mut registry.records, &record_nft.node);
        if (record.ttl != ttl) {
            record.ttl = ttl;
            event::emit(NewTTLEvent { node: record.node, ttl });
        };
        transfer::transfer(record_nft, tx_context::sender(ctx));
    }

    public fun owner(registry: &Registry, node: vector<u8>): address{
        if (record_exists(registry, node)) {
            return vec_map::get(&registry.records, &string::utf8(node)).owner
        };
        @0x0
    }

    public fun resolver(registry: &Registry, node: vector<u8>): address{
        if (record_exists(registry, node)) {
            return vec_map::get(&registry.records, &string::utf8(node)).resolver
        };
        @0x0
    }

    public fun ttl(registry: &Registry, node: vector<u8>): u64{
        if (record_exists(registry, node)) {
            return vec_map::get(&registry.records, &string::utf8(node)).ttl
        };
        0
    }

    public fun record_exists(registry: &Registry, node: vector<u8>): bool{
        vec_map::contains(&registry.records, &string::utf8(node))
    }

    fun set_resolver_and_TTL(registry: &mut Registry, node: String, resolver: address, ttl: u64) {
        let record = vec_map::get_mut(&mut registry.records, &node);

        if (record.resolver != resolver) {
            record.resolver = resolver;
            event::emit(NewResolverEvent { node, resolver });
        };

        if (record.ttl != ttl) {
            record.ttl = ttl;
            event::emit(NewTTLEvent { node, ttl });
        };
    }

    // return value == true: node is in Registry, the NFT must be transfered to new owner if base_node
    // return value == false: the NFT is expiried and must be deleted if base_node
    fun set_owner_or_create_record(
        registry: &mut Registry,
        node: String,
        owner: address,
        resolver: Option<address>,
        ttl: Option<u64>,
        url: Option<Url>,
        ctx: &mut TxContext
    ): bool {
        if (vec_map::contains(&registry.records, &node)) {
            let record = vec_map::get_mut(&mut registry.records, &node);
            record.owner = owner;
            return true
        };
        // create a new NFT and sent to owner
        if (option::is_none(&resolver)) option::fill(&mut resolver, @0x0);
        if (option::is_none(&ttl)) option::fill(&mut ttl, 0);
        if (option::is_none(&url)) option::fill(&mut url, url::new_unsafe_from_bytes(DEFAULT_URL));
        new_record(
            registry,
            node,
            owner,
            option::extract(&mut resolver),
            option::extract(&mut ttl),
            option::extract(&mut url),
            ctx
        );
        false
    }

    fun new_record(
        registry: &mut Registry,
        node: String,
        owner: address,
        resolver: address,
        ttl: u64,
        url: Url,
        ctx: &mut TxContext
    ) {
        let record_nft = RecordNFT {
            id: object::new(ctx),
            node,
            url,
        };

        let record = Record {
            node,
            owner,
            resolver,
            ttl,
            nft_id: object::id(&record_nft)
        };
        vec_map::insert(&mut registry.records, record.node, record);

        transfer::transfer(record_nft, owner);
        event::emit(NewRecordEvent {
            node,
            owner,
            resolver,
            ttl,
        })
    }

    fun make_subnode(label: vector<u8>, node: String): String {
        let subnode = string::utf8(label);
        string::append(&mut subnode, string::utf8(b"."));
        string::append(&mut subnode, node);
        subnode
    }

    fun authorised(registry: &Registry, record_nft: &RecordNFT): bool {
        vec_map::contains(&registry.records, &record_nft.node)
    }

    #[test_only]
    public(friend) fun get_record_at_index(registry: &Registry, index: u64): (&String, &Record) {
        vec_map::get_entry_by_idx(&registry.records, index)
    }

    #[test_only]
    public(friend) fun delete_record_by_key(registry: &mut Registry, node: String): (String, Record) {
        vec_map::remove(&mut registry.records, &node)
    }

    #[test_only]
    friend suins::registry_tests;
    #[test_only]
    /// Wrapper of module initializer for testing
    public fun test_init(ctx: &mut TxContext) {
        init(ctx)
    }
}
