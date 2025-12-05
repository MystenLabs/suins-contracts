module suins_auction::decryption;

use seal::bf_hmac_encryption::{
    decrypt,
    EncryptedObject,
    new_public_key,
    PublicKey,
    VerifiedDerivedKey,
    verify_derived_keys,
};
use sui::{
    bcs,
    bls12381::g1_from_bytes
};

const EIncorrectKeys: u64 = 0;
const ENotEnoughKeys: u64 = 1;
const EKeyNotFound: u64 = 2;

// The id has start_date to prevent older encrypted data to be used in place of new one for the same domain
public fun get_encryption_id(start_time: u64, domain_name: vector<u8>): vector<u8> {
    let mut full_id = vector[];
    full_id.append(bcs::to_bytes(&start_time));
    full_id.append(domain_name);
    full_id
}

public(package) fun decrypt_reserve_price(
    config_key_servers: vector<address>,
    config_public_keys: vector<vector<u8>>,
    threshold: u8,
    start_time: u64,
    domain_name: vector<u8>,
    reserve_price: EncryptedObject,
    derived_keys: &vector<vector<u8>>,
    key_servers: &vector<address>
): u64 {
    assert!(key_servers.length() == derived_keys.length(), EIncorrectKeys);
    assert!(derived_keys.length() as u8 >= threshold, ENotEnoughKeys);

    // Public keys for the given derived keys
    // Verify the derived keys
    let verified_derived_keys: vector<VerifiedDerivedKey> = verify_derived_keys(
        &derived_keys.map_ref!(|k| g1_from_bytes(k)),
        @suins_auction,
        get_encryption_id(start_time, domain_name),
        &key_servers
            .map_ref!(|ks1| config_key_servers.find_index!(|ks2| ks1 == ks2).destroy_or!(abort EKeyNotFound))
            .map!(|i| new_public_key(config_key_servers[i].to_id(), config_public_keys[i])),
    );

    // Public keys for all key servers
    let all_public_keys: vector<PublicKey> = config_key_servers
        .zip_map!(config_public_keys, |ks, pk| new_public_key(ks.to_id(), pk));

    let decrypted = decrypt(&reserve_price, &verified_derived_keys, &all_public_keys).extract();

    bcs::new(decrypted).peel_u64()
}
