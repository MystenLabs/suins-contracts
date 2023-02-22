/// Default implementation for a resolver module.
/// Its purpose is to store external data, such as content hash, default name, etc.
/// Third-party resolvers have to follow the public function specified in this module.
module suins::resolver {

    use sui::dynamic_field as field;
    use sui::event;
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::TxContext;
    use suins::base_registry::{Self, Registry};
    use suins::converter;
    use std::string::{Self, String, utf8};
    use sui::vec_map::VecMap;
    use sui::vec_map;

    const ADDR_REVERSE_BASE_NODE: vector<u8> = b"addr.reverse";
    const NAME: vector<u8> = b"name";
    const ADDR: vector<u8> = b"addr";
    const AVATAR: vector<u8> = b"avatar";
    const CONTENTHASH: vector<u8> = b"contenthash";

    const EInvalidKey: u64 = 701;

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
        addr: String,
    }

    /// Mapping domain name to its VecMap resources.
    /// Each record is a dynamic field of this share object,.
    /// Records's format:
    /// 'suins.sui': {
    ///   'contenthash': 'QmNZiPk974vDsPmQii3YbrMKfi12KTSNM7XMiYyiea4VYZ',
    ///   'addr': 'abc123',
    ///   'avatar': 'QmfWrgbTZqwzqsvdeNc3NKacggMuTaN83sQ8V7Bs2nXKRD',
    ///   'key': 'abc',
    /// },
    /// 'ab123.addr.reverse': {
    ///   'name': 'suins.sui',
    /// }
    struct BaseResolver has key {
        id: UID,
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
        let key = utf8(CONTENTHASH);

        if (field::exists_with_type<String, VecMap<String, String>>(&base_resolver.id, node)) {
            let record = field::borrow_mut<String, VecMap<String, String>>(&mut base_resolver.id, node);
            if (vec_map::contains(record, &key)) {
                // `node` and `contenthash` exist
                let current_contenthash = vec_map::get_mut(record, &key);
                *current_contenthash = new_hash;
            } else {
                // `node` exists but `contenthash` doesn't
                vec_map::insert(record, key, new_hash);
            }
        } else {
            // `node` not exist
            let new_record = vec_map::empty<String, String>();
            vec_map::insert(&mut new_record, key, new_hash);
            field::add(&mut base_resolver.id, node, new_record);
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
        let record = field::borrow_mut<String, VecMap<String, String>>(&mut base_resolver.id, node);
        vec_map::remove(record, &utf8(CONTENTHASH));
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
        let key = utf8(NAME);

        if (field::exists_with_type<String, VecMap<String, String>>(&base_resolver.id, node)) {
            let record = field::borrow_mut<String, VecMap<String, String>>(&mut base_resolver.id, node);
            if (vec_map::contains(record, &key)) {
                // `node` and `name` exist
                let current_name = vec_map::get_mut(record, &key);
                *current_name = new_name;
            } else {
                // `node` exists but `name` doesn't
                vec_map::insert(record, key, new_name);
            }
        } else {
            // `node` not exist
            let new_record = vec_map::empty<String, String>();
            vec_map::insert(&mut new_record, key, new_name);
            field::add(&mut base_resolver.id, node, new_record);
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

        let record = field::borrow_mut(&mut base_resolver.id, node);
        vec_map::remove<String, String>(record, &node);

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
        assert!(key != CONTENTHASH && key != ADDR && key != AVATAR && key != NAME, EInvalidKey);
        // TODO: we don't have unset_text function
        base_registry::authorised(registry, node, ctx);
        let node = utf8(node);
        let new_value = utf8(new_value);
        let key = utf8(key);

        if (field::exists_with_type<String, VecMap<String, String>>(&base_resolver.id, node)) {
            let record = field::borrow_mut<String, VecMap<String, String>>(&mut base_resolver.id, node);
            if (vec_map::contains(record, &key)) {
                // `node` and `key` exist
                let current_value = vec_map::get_mut(record, &key);
                *current_value = new_value;
            } else {
                // `node` exists but `key` doesn't
                vec_map::insert(record, key, new_value);
            }
        } else {
            // `node` not exist
            let new_record = vec_map::empty<String, String>();
            vec_map::insert(&mut new_record, key, new_value);
            field::add(&mut base_resolver.id, node, new_record);
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
        let key = utf8(ADDR);
        let new_addr = utf8(converter::address_to_string(new_addr));

        if (field::exists_with_type<String, VecMap<String, String>>(&base_resolver.id, node)) {
            let record = field::borrow_mut<String, VecMap<String, String>>(&mut base_resolver.id, node);
            if (vec_map::contains(record, &key)) {
                let current_addr = vec_map::get_mut(record, &key);
                *current_addr = new_addr;
            } else {
                // `node` exists but `key` doesn't
                vec_map::insert(record, key, new_addr);
            }
        } else {
            let new_record = vec_map::empty<String, String>();
            vec_map::insert(&mut new_record, key, new_addr);
            field::add(&mut base_resolver.id, node, new_record);
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
        let key = utf8(CONTENTHASH);
        let node = utf8(node);

        if (field::exists_with_type<String, VecMap<String, String>>(&base_resolver.id, node)) {
            let record = field::borrow<String, VecMap<String, String>>(&base_resolver.id, node);
            if (vec_map::contains(record, &key)) {
                return *vec_map::get(record, &key)
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
        let label = converter::address_to_string(addr);
        let node = base_registry::make_node(label, utf8(ADDR_REVERSE_BASE_NODE));
        let key = utf8(NAME);

        if (field::exists_with_type<String, VecMap<String, String>>(&base_resolver.id, node)) {
            let record = field::borrow<String, VecMap<String, String>>(&base_resolver.id, node);
            if (vec_map::contains(record, &key)) {
                return *vec_map::get(record, &key)
            };
        };
        utf8(b"")
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
        let key = utf8(key);
        let node = utf8(node);

        if (field::exists_with_type<String, VecMap<String, String>>(&base_resolver.id, node)) {
            let record = field::borrow<String, VecMap<String, String>>(&base_resolver.id, node);
            if (vec_map::contains(record, &key)) {
                return *vec_map::get(record, &key)
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
    public fun addr(base_resolver: &BaseResolver, node: vector<u8>): String {
        let node = utf8(node);
        let key = utf8(ADDR);

        if (field::exists_with_type<String, VecMap<String, String>>(&base_resolver.id, node)) {
            let record = field::borrow<String, VecMap<String, String>>(&base_resolver.id, node);
            if (vec_map::contains(record, &key)) {
                return *vec_map::get(record, &key)
            };
        };
        utf8(b"")
    }

    /// #### Notice
    /// Get `(contenthash, addr, avatar, name)` of a `node`.
    ///
    /// #### Dev
    /// Returns empty string and @0x0 address if not exists.
    ///
    /// #### Params
    /// `node`: node to find the data.
    public fun all_data(
        base_resolver: &BaseResolver,
        node: vector<u8>,
    ): (String, String, String, String) {
        let empty_str = utf8(b"");
        let node = utf8(node);

        if (field::exists_with_type<String, VecMap<String, String>>(&base_resolver.id, node)) {
            let record = field::borrow<String, VecMap<String, String>>(&base_resolver.id, node);

            let contenthash = empty_str;
            if (vec_map::contains(record, &utf8(CONTENTHASH))) {
                contenthash = *vec_map::get(record, &utf8(CONTENTHASH));
            };

            let addr = empty_str;
            if (vec_map::contains(record, &utf8(ADDR))) {
                addr = *vec_map::get(record, &utf8(ADDR));
            };

            let avatar = empty_str;
            if (vec_map::contains(record, &utf8(AVATAR))) {
                avatar = *vec_map::get(record, &utf8(AVATAR));
            };

            let name = empty_str;
            if (vec_map::contains(record, &utf8(NAME))) {
                name = *vec_map::get(record, &utf8(NAME));
            };
            return (contenthash, addr, avatar, name)
        };
        (empty_str, empty_str, empty_str, empty_str)
    }

    // === Private Functions ===

    fun init(ctx: &mut TxContext) {
        transfer::share_object(BaseResolver {
            id: object::new(ctx),
        });
    }

    // === Testing Functions ===

    #[test_only]
    public fun is_contenthash_existed(base_resolver: &BaseResolver, node: vector<u8>): bool {
        let record = field::borrow<String, VecMap<String, String>>(&base_resolver.id, utf8(node));
        vec_map::contains(record, &utf8(CONTENTHASH))
    }

    #[test_only]
    /// Wrapper of module initializer for testing
    public fun test_init(ctx: &mut TxContext) {
        transfer::share_object(BaseResolver {
            id: object::new(ctx),
        });
    }
}
