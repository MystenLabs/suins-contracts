/// These funtionalities are supposed to be supported by the Sui SDK in the future
/// we will remove it as soon as SDK's support is ready
module suins::remove_later {

    use std::string::{Self, utf8, String};
    use suins::string_utils;

    friend suins::registrar;

    /// `msg` format: <ipfs_url>,<domain_name>,<expired_at>,<data>
    public(friend) fun deserialize_image_msg(msg: vector<u8>): (String, String, u64, String) {
        // `msg` now: ipfs_url,domain_name,expired_at,data
        let msg = utf8(msg);
        let comma = utf8(b",");

        let index_of_next_comma = string::index_of(&msg, &comma);
        let ipfs = string::sub_string(&msg, 0, index_of_next_comma);
        // `msg` now: domain_name,expired_at,data
        msg = string::sub_string(&msg, index_of_next_comma + 1, string::length(&msg));
        index_of_next_comma = string::index_of(&msg, &comma);
        let domain_name = string::sub_string(&msg, 0, index_of_next_comma);

        // `msg` now: expired_at,data
        msg = string::sub_string(&msg, index_of_next_comma + 1, string::length(&msg));
        index_of_next_comma = string::index_of(&msg, &comma);
        let expired_at = string::sub_string(&msg, 0, index_of_next_comma);

        // `msg` now: data
        msg = string::sub_string(&msg, index_of_next_comma + 1, string::length(&msg));
        (ipfs, domain_name, string_utils::string_to_number(expired_at), msg)
    }
}
