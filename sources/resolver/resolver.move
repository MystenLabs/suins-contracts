module suins::resolver {

    use sui::bag::{Self, Bag};
    use sui::event;
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::TxContext;
    use suins::base_registry::{Self, Registry};
    use suins::converter;
    use std::string::{Self, String, utf8};
    use sui::table::{Self, Table};

    const ADDR_REVERSE_BASE_NODE: vector<u8> = b"addr.reverse";
    const NAME: vector<u8> = b"name";
    const ADDR: vector<u8> = b"addr";
    const TEXT: vector<u8> = b"text";
    const AVATAR: vector<u8> = b"avatar";
    const CONTENTHASH: vector<u8> = b"contenthash";

    struct NameChangedEvent has copy, drop {
        addr: address,
        name: String,
    }

    struct NameRemovedEvent has copy, drop {
        addr: address,
    }

    struct TextRecordChangedEvent has copy, drop {
        node: String,
        key: String,
        value: String
    }
    
    struct ContenthashChangedEvent has copy, drop {
        node: String,
        contenthash: String,
    }

    struct ContenthashRemovedEvent has copy, drop {
        node: String,
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
        if (table::contains(&base_resolver.records, utf8(node))) {
            let record = table::borrow(&base_resolver.records, utf8(node));
            if (bag::contains(record, utf8(TEXT))) {
                let text_record: &Table<String, String> = bag::borrow(record, utf8(TEXT));
                if (table::contains(text_record, utf8(key))) {
                    return *table::borrow(text_record, utf8(key))
                }
            };
        };
        utf8(b"")
    }

    public fun addr(base_resolver: &BaseResolver, node: vector<u8>): address {
        if (table::contains(&base_resolver.records, utf8(node))) {
            let record = table::borrow(&base_resolver.records, utf8(node));
            if (bag::contains(record, utf8(ADDR))) {
                return *bag::borrow<String, address>(record, utf8(ADDR))
            };
        };
        @0x0
    }

    public fun contenthash(base_resolver: &BaseResolver, node: vector<u8>): String {
        if (table::contains(&base_resolver.records, utf8(node))) {
            let record = table::borrow(&base_resolver.records, utf8(node));
            if (bag::contains(record, utf8(CONTENTHASH))) {
                return *bag::borrow<String, String>(record, utf8(CONTENTHASH))
            };
        };
        utf8(b"")
    }

    // returns (text, addr, content_hash)
    public fun all_data(base_resolver: &BaseResolver, node: vector<u8>, key: vector<u8>): (String, address, String) {
        let record = table::borrow(&base_resolver.records, utf8(node));
        let text = utf8(b"");
        if (bag::contains(record, utf8(TEXT))) {
            let text_record: &Table<String, String> = bag::borrow(record, utf8(TEXT));
            if (table::contains(text_record, utf8(key))) {
                text = *table::borrow(text_record, utf8(key));
            }
        };
        let addr = @0x0;
        if (bag::contains(record, utf8(ADDR))) {
            addr = *bag::borrow<String, address>(record, utf8(ADDR));
        };
        let content_hash = utf8(b"");
        if (bag::contains(record, utf8(CONTENTHASH))) {
            content_hash = *bag::borrow<String, String>(record, utf8(CONTENTHASH));
        };
        (text, addr, content_hash)
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
            let record = table::borrow_mut(&mut base_resolver.records, node);
            if (bag::contains_with_type<String, String>(record, utf8(CONTENTHASH))) {
                // `node` and `contenthash` exist
                let current_contenthash = bag::borrow_mut<String, String>(record, utf8(CONTENTHASH));
                *current_contenthash = new_hash;
            } else {
                // `node` exists but `contenthash` doesn't
                bag::add<String, String>(record, utf8(CONTENTHASH), new_hash);
            }
        } else {
            // `node` not exist
            let new_record = bag::new(ctx);
            bag::add<String, String>(&mut new_record, utf8(CONTENTHASH), new_hash);
            table::add(&mut base_resolver.records, node, new_record);
        };

        event::emit(ContenthashChangedEvent { node, contenthash: new_hash });
    }

    public entry fun unset_contenthash(
        base_resolver: &mut BaseResolver,
        registry: &Registry,
        node: vector<u8>,
        ctx: &mut TxContext
    ) {
        base_registry::authorised(registry, node, ctx);

        let node = utf8(node);
        let record = table::borrow_mut(&mut base_resolver.records, node);
        bag::remove<String, String>(record, utf8(CONTENTHASH));
        event::emit(ContenthashRemovedEvent { node });
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
            let record = table::borrow_mut(&mut base_resolver.records, addr_str);
            if (bag::contains_with_type<String, String>(record, utf8(NAME))) {
                // `node` and `name` exist
                let current_name = bag::borrow_mut<String, String>(record, utf8(NAME));
                *current_name = new_name;
            } else {
                // `node` exists but `name` doesn't
                bag::add<String, String>(record, utf8(NAME), new_name);
            }
        } else {
            // `node` not exist
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
        let record = table::borrow_mut(&mut base_resolver.records, addr_str);
        bag::remove<String, String>(record, addr_str);
        event::emit(NameRemovedEvent { addr });
    }

    public entry fun set_text(
        base_resolver: &mut BaseResolver,
        registry: &Registry,
        node: vector<u8>,
        key: vector<u8>,
        new_value: vector<u8>,
        ctx: &mut TxContext
    ) {
        base_registry::authorised(registry, node, ctx);
        let node = utf8(node);
        let new_value = utf8(new_value);
        let key = utf8(key);

        if (table::contains(&base_resolver.records, node)) {
            let record = table::borrow_mut(&mut base_resolver.records, node);
            if (bag::contains_with_type<String, Table<String, String>>(record, utf8(TEXT))) {
                let text_record: &mut Table<String, String> = bag::borrow_mut(record, utf8(TEXT));
                if (table::contains(text_record, *&key)) {
                    // `node`, `text` and `key` exist
                    let current_value = table::borrow_mut(text_record, key);
                    *current_value = new_value;
                } else {
                    // `node`, `text` exists but `key` doesn't
                    table::add(text_record, key, new_value);
                }
            } else {
                // `text` not exists
                let text_record: Table<String, String> = table::new(ctx);
                table::add(&mut text_record, key, new_value);
                bag::add(record, utf8(TEXT), text_record);
            }
        } else {
            // `node` not exist
            let text_record: Table<String, String> = table::new(ctx);
            table::add(&mut text_record, key, new_value);

            let new_record = bag::new(ctx);
            bag::add(&mut new_record, utf8(TEXT), text_record);
            table::add(&mut base_resolver.records, node, new_record);
        };

        event::emit(TextRecordChangedEvent { node, key, value: new_value });
    }

    public entry fun set_addr(
        base_resolver: &mut BaseResolver,
        registry: &Registry,
        node: vector<u8>,
        new_addr: address,
        ctx: &mut TxContext
    ) {
        base_registry::authorised(registry, node, ctx);
        let node = utf8(node);

        if (table::contains(&base_resolver.records, node)) {
            let record = table::borrow_mut(&mut base_resolver.records, node);
            if (bag::contains_with_type<String, address>(record, utf8(ADDR))) {
                let current_addr = bag::borrow_mut<String, address>(record, utf8(ADDR));
                *current_addr = new_addr;
            } else {
                // `node` exists but `key` doesn't
                bag::add<String, address>(record, utf8(ADDR), new_addr);
            }
        } else {
            let new_record = bag::new(ctx);
            bag::add<String, address>(&mut new_record, utf8(ADDR), new_addr);
            table::add(&mut base_resolver.records, node, new_record);
        };

        event::emit(AddrChangedEvent { node, addr: new_addr });
    }

    #[test_only]
    public fun is_contenthash_existed(base_resolver: &BaseResolver, node: vector<u8>): bool {
        let record = table::borrow(&base_resolver.records, utf8(node));
        bag::contains_with_type<String, String>(record, utf8(CONTENTHASH))
    }

    #[test_only]
    /// Wrapper of module initializer for testing
    public fun test_init(ctx: &mut TxContext) {
        // mimic logic in `init`
        transfer::share_object(BaseResolver {
            id: object::new(ctx),
            records: table::new<String, Bag>(ctx),
        });
    }
}
