/// Default implementation for a resolver module.
/// Its purpose is to store external data, such as content hash, default name, etc.
/// Third-party resolvers have to follow the public function specified in this module.
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

    struct BaseResolver has key {
        id: UID,
        /// records: {
        ///   'suins.sui': {
        ///     'contenthash': 'QmNZiPk974vDsPmQii3YbrMKfi12KTSNM7XMiYyiea4VYZ',
        ///     'addr': 0xabc123,
        ///     'text': {
        ///        'key': 'abc',
        ///      }
        ///   },
        ///   'ab123.addr.reverse': {
        ///     'name': 'suins.sui',
        ///
        ///  },
        /// }
        records: Table<String, Bag>,
    }

    /// #### Notice
    /// This funtions allows owner of `node` to set content hash url.
    ///
    /// #### Dev
    /// Create 'contenthash' key if not exist.
    /// `hash` isn't validated.
    ///
    /// #### Params
    /// `node`: node to be updated
    /// `hash`: content hash url
    ///
    /// Panics
    /// Panics if caller isn't the owner of `node`
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

    /// #### Notice
    /// This funtions allows owner of `node` to unset content hash url.
    ///
    /// #### Params
    /// `node`: node to be updated
    ///
    /// Panics
    /// Panics if caller isn't the owner of `node`
    /// or `node` doesn't exist.
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

    /// #### Notice
    /// This funtions allows owner of `sender_addr`.addr.reverse` to set default domain name which is mapped to the sender address.
    /// The node is identified by the sender address with format: `sender_addr`.addr.reverse.
    ///
    /// #### Dev
    /// Create 'name' key if not exist.
    /// `new_name` isn't validated.
    ///
    /// #### Params
    /// `node`: node to be updated
    /// `new_name`: new domain name to be set
    ///
    /// Panics
    /// Panics if caller isn't the owner of `sender_addr`.addr.reverse.
    public entry fun set_name(
        base_resolver: &mut BaseResolver,
        registry: &Registry,
        addr: address,
        new_name: vector<u8>,
        ctx: &mut TxContext
    ) {
        let label = converter::address_to_string(addr);
        let node = base_registry::make_node(label, utf8(ADDR_REVERSE_BASE_NODE));
        // TODO: do we have to authorised this?
        base_registry::authorised(registry, *string::bytes(&node), ctx);

        let new_name = utf8(new_name);
        let addr_str = utf8(label);

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

    /// #### Notice
    /// This funtions allows owner of `addr`.addr.reverse to unset default name.
    ///
    /// #### Params
    /// `addr`: node to be unset with format `addr`.addr.reverse.
    ///
    /// Panics
    /// Panics if caller isn't the owner of `node`
    /// or `addr`.addr.reverse doesn't exist.
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

    /// #### Notice
    /// This funtions allows owner of `node` to set text record.
    /// Text record is an object.
    ///
    /// #### Params
    /// `node`: node to be updated
    /// `key`: key of text record object
    /// `new_value`: new value for the key
    ///
    /// Panics
    /// Panics if caller isn't the owner of `node`
    public entry fun set_text(
        base_resolver: &mut BaseResolver,
        registry: &Registry,
        node: vector<u8>,
        key: vector<u8>,
        new_value: vector<u8>,
        ctx: &mut TxContext
    ) {
        // TODO: we don't have unset_text function
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

    /// #### Notice
    /// This funtions allows owner of `node` to set default addr.
    ///
    /// #### Params
    /// `node`: node to be updated
    /// `new_addr`: new address value
    ///
    /// Panics
    /// Panics if caller isn't the owner of `node`
    public entry fun set_addr(
        base_resolver: &mut BaseResolver,
        registry: &Registry,
        node: vector<u8>,
        new_addr: address,
        ctx: &mut TxContext
    ) {
        // TODO: we don't have unset_addr function
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

    // === Public Functions ===

    /// #### Notice
    /// Get content hash of a `node`.
    ///
    /// #### Dev
    /// Returns empty string if `node` or `contenthash` key doesn't exist.
    ///
    /// #### Params
    /// `node`: node to find the content hash
    public fun contenthash(base_resolver: &BaseResolver, node: vector<u8>): String {
        if (table::contains(&base_resolver.records, utf8(node))) {
            let record = table::borrow(&base_resolver.records, utf8(node));
            if (bag::contains(record, utf8(CONTENTHASH))) {
                return *bag::borrow<String, String>(record, utf8(CONTENTHASH))
            };
        };
        utf8(b"")
    }

    /// #### Notice
    /// Get default name of a `node`.
    ///
    /// #### Dev
    /// Returns empty string if `node` or `name` key doesn't exist.
    ///
    /// #### Params
    /// `node`: node to find the default name
    public fun name(base_resolver: &BaseResolver, addr: address): String {
        // FIXME: returns empty for consistency
        let addr_str = utf8(converter::address_to_string(addr));
        let record = table::borrow(&base_resolver.records, addr_str);
        *bag::borrow<String, String>(record, utf8(NAME))
    }

    /// #### Notice
    /// Get value of a key in text record object.
    ///
    /// #### Dev
    /// Returns empty string if not exists.
    ///
    /// #### Params
    /// `node`: node to find the text record key.
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

    /// #### Notice
    /// Get `addr` of a `node`.
    ///
    /// #### Dev
    /// Returns @0x0 address if not exists.
    ///
    /// #### Params
    /// `node`: node to find the default addr.
    public fun addr(base_resolver: &BaseResolver, node: vector<u8>): address {
        if (table::contains(&base_resolver.records, utf8(node))) {
            let record = table::borrow(&base_resolver.records, utf8(node));
            if (bag::contains(record, utf8(ADDR))) {
                return *bag::borrow<String, address>(record, utf8(ADDR))
            };
        };
        @0x0
    }
    /// #### Notice
    /// Get `(text, addr, content_hash)` of a `node`.
    ///
    /// #### Dev
    /// Returns empty string and @0x0 address if not exists.
    ///
    /// #### Params
    /// `node`: node to find the data.
    public fun all_data(base_resolver: &BaseResolver, node: vector<u8>, key: vector<u8>): (String, address, String) {
        let empty_str = utf8(b"");
        if (table::contains(&base_resolver.records, utf8(node))) {
            let record = table::borrow(&base_resolver.records, utf8(node));
            let text = *&empty_str;
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
            let content_hash = *&empty_str;
            if (bag::contains(record, utf8(CONTENTHASH))) {
                content_hash = *bag::borrow<String, String>(record, utf8(CONTENTHASH));
            };
            return (text, addr, content_hash)
        };
        (*&empty_str, @0x0, *&empty_str)
    }

    // === Private Functions ===

    fun init(ctx: &mut TxContext) {
        transfer::share_object(BaseResolver {
            id: object::new(ctx),
            records: table::new<String, Bag>(ctx),
        });
    }

    // === Testing Functions ===

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
