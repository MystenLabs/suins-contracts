module suins::resolver {

    use sui::bag::{Self, Bag};
    use sui::event;
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::TxContext;
    use suins::base_registry::{Self, Registry};
    use suins::converter;
    use std::string::{Self, String, utf8};
    use sui::table;
    use sui::table::Table;

    // errors in the range of 401..500 indicate Resolver errors
    const EInvalidTextRecordKey: u64 = 401;

    const ADDR_REVERSE_BASE_NODE: vector<u8> = b"addr.reverse";
    const NAME: vector<u8> = b"name";
    const ADDR: vector<u8> = b"addr";
    const TEXT: vector<u8> = b"text";
    const AVATAR: vector<u8> = b"avatar";
    const CONTENT_HASH: vector<u8> = b"contenthash";

    struct NameChangedEvent has copy, drop {
        addr: address,
        name: String,
    }

    struct NameRemovedEvent has copy, drop {
        addr: address,
    }

    struct AvatarChangedEvent has copy, drop {
        node: String,
        avatar: String,
    }

    struct ContenthashChangedEvent has copy, drop {
        node: String,
        contenthash: String,
    }

    struct AddrChangedEvent has copy, drop {
        node: String,
        addr: address,
    }

    // this share object is used by many type of resolver, e.g., text resolver, addr resolver,...
    struct BaseResolver has key {
        id: UID,
        records: Table<String, Bag>,
    }

    fun init(ctx: &mut TxContext) {
        // each `record` looks like:
        // ```
        // "suins.sui": {
        //   "name": "suins.sui",
        //   "addr": "0x2",
        //   "contenthash": "ipfs://QmfWrgbTZqwzqsvdeNc3NKacggMuTaN83sQ8V7Bs2nXKRD",
        //   "text": {
        //     "avatar": "0x03"
        //   }
        // }
        // ```
        transfer::share_object(BaseResolver {
            id: object::new(ctx),
            records: table::new<String, Bag>(ctx),
        });
    }

    public fun name(base_resolver: &BaseResolver, addr: address): String {
        let addr_str = utf8(converter::address_to_string(addr));
        let record = table::borrow(&base_resolver.records, addr_str);
        *bag::borrow<String, String>(record, utf8(NAME))
    }

    public fun text(base_resolver: &BaseResolver, node: vector<u8>, key: vector<u8>): String {
        let record = table::borrow(&base_resolver.records, utf8(node));
        let text_record = bag::borrow<String, Bag>(record, utf8(TEXT));
        *bag::borrow<String, String>(text_record, utf8(key))
    }

    public fun addr(base_resolver: &BaseResolver, node: vector<u8>): address {
        let record = table::borrow(&base_resolver.records, utf8(node));
        *bag::borrow<String, address>(record, utf8(ADDR))
    }

    public fun contenthash(base_resolver: &BaseResolver, node: vector<u8>): String {
        let record = table::borrow(&base_resolver.records, utf8(node));
        *bag::borrow<String, String>(record, utf8(CONTENT_HASH))
    }

    public entry fun set_contenthash(
        base_resolver: &mut BaseResolver,
        registry: &Registry,
        node: vector<u8>,
        hash: vector<u8>,
        ctx: &mut TxContext
    ) {
        base_registry::authorised(registry, node, ctx);

        let node = utf8(node);
        let new_hash = utf8(hash);

        if (table::contains(&base_resolver.records, node)) {
            let record = table::borrow_mut<String, Bag>(&mut base_resolver.records, node);
            let current_contenthash = bag::borrow_mut<String, String>(record, utf8(CONTENT_HASH));
            *current_contenthash = new_hash;
        } else {
            let new_record = bag::new(ctx);
            bag::add<String, String>(&mut new_record, utf8(CONTENT_HASH), new_hash);
            table::add(&mut base_resolver.records, node, new_record);
        };

        event::emit(ContenthashChangedEvent { node, contenthash: new_hash });
    }

    public entry fun set_name(
        base_resolver: &mut BaseResolver,
        registry: &Registry,
        addr: address,
        new_name: vector<u8>,
        ctx: &mut TxContext
    ) {
        let label = converter::address_to_string(addr);
        let node = base_registry::make_node(label, utf8(ADDR_REVERSE_BASE_NODE));
        base_registry::authorised(registry, *string::bytes(&node), ctx);

        let new_name = utf8(new_name);
        let addr_str = utf8(converter::address_to_string(addr));
        if (table::contains(&base_resolver.records, addr_str)) {
            let record = table::borrow_mut<String, Bag>(&mut base_resolver.records, addr_str);
            let current_name = bag::borrow_mut<String, String>(record, utf8(NAME));
            *current_name = new_name;
        } else {
            let new_record = bag::new(ctx);
            bag::add<String, String>(&mut new_record, utf8(NAME), new_name);
            table::add(&mut base_resolver.records, addr_str, new_record);
        };

        event::emit(NameChangedEvent { addr, name: new_name });
    }

    public entry fun unset_name(
        base_resolver: &mut BaseResolver,
        registry: &Registry,
        addr: address,
        ctx: &mut TxContext
    ) {
        let label = converter::address_to_string(addr);
        let node = base_registry::make_node(label, utf8(ADDR_REVERSE_BASE_NODE));
        base_registry::authorised(registry, *string::bytes(&node), ctx);

        let addr_str = utf8(converter::address_to_string(addr));
        let record = table::borrow_mut<String, Bag>(&mut base_resolver.records, addr_str);
        bag::remove<String, String>(record, addr_str);
        event::emit(NameRemovedEvent { addr });
    }

    // only allow set avatar for domain atm
    public entry fun set_text(
        base_resolver: &mut BaseResolver,
        registry: &Registry,
        node: vector<u8>,
        key: vector<u8>,
        new_value: vector<u8>,
        ctx: &mut TxContext
    ) {
        assert!(is_text_record_key(key), EInvalidTextRecordKey);
        base_registry::authorised(registry, node, ctx);

        let node = utf8(node);
        let new_value = utf8(new_value);
        if (table::contains(&base_resolver.records, node)) {
            let record = table::borrow_mut<String, Bag>(&mut base_resolver.records, node);
            let current_value = bag::borrow_mut<String, String>(record, utf8(key));
            *current_value = new_value;
        } else {
            let text_record = bag::new(ctx);
            bag::add<String, String>(&mut text_record, utf8(key), new_value);

            let new_record = bag::new(ctx);
            bag::add<String, Bag>(&mut new_record, utf8(TEXT), text_record);
            table::add(&mut base_resolver.records, node, new_record);
        };

        event::emit(AvatarChangedEvent { node, avatar: new_value });
    }

    fun is_text_record_key(key: vector<u8>): bool { key == AVATAR }

    public entry fun set_addr(
        base_resolver: &mut BaseResolver,
        registry: &Registry,
        node: vector<u8>,
        new_addr: address,
        ctx: &mut TxContext
    ) {
        base_registry::authorised(registry, node, ctx);

        let node = utf8(node);
        if (table::contains(&mut base_resolver.records, node)) {
            let record = table::borrow_mut<String, Bag>(&mut base_resolver.records, node);
            let current_addr = bag::borrow_mut<String, address>(record, utf8(ADDR));
            *current_addr = new_addr;
        } else {
            let new_record = bag::new(ctx);
            bag::add<String, address>(&mut new_record, utf8(ADDR), new_addr);
            table::add(&mut base_resolver.records, node, new_record);
        };

        event::emit(AddrChangedEvent { node, addr: new_addr });
    }

    #[test_only]
    /// Wrapper of module initializer for testing
    public fun test_init(ctx: &mut TxContext) { init(ctx) }
}
