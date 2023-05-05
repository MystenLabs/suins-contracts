/// User data management for the name record. Allows attaching/detaching
/// custom data to/from the name record.
///
/// Is module is relevant as long as the SuiNS is using the `name_record`
/// module to store the information about the name record. If the record format
/// (type) changes, the module should be updated accordingly.
module suins_v2::name_data {
    use std::string::String;
    use sui::vec_map::VecMap;
    // use sui::clock::Clock;

    use suins::name_record::{Self, NameRecord};
    // use suins::registration_nft::RegistrationNFT;
    use suins::suins::{Self, SuiNS};
    use suins::domain;

    /// Get the data from the NameRecord.
    public fun get(
        suins: &SuiNS,
        domain_name: String
    ): &VecMap<String, String> {
        name_record::data(suins::name_record<NameRecord>(suins, domain::new(domain_name)))
    }

    // /// Set the data in the NameRecord.
    // public fun set(
    //     suins: &mut SuiNS,
    //     token: &RegistrationNFT,
    //     clock: &Clock,
    //     data: VecMap<String, String>
    // ) {
    //     let record_mut = suins::name_record_mut(suins, token, clock);
    //     name_record::set_data(record_mut, data)
    // }
}
