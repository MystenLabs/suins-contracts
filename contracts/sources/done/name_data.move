/// User data management for the name record. Allows attaching/detaching
/// custom data to/from the name record.
///
/// Is module is relevant as long as the SuiNS is using the `name_record`
/// module to store the information about the name record. If the record format
/// (type) changes, the module should be updated accordingly.
module suins::name_data {
    use std::string::String;
    use sui::vec_map::VecMap;
    use sui::tx_context::TxContext;

    use suins::name_record::{Self, NameRecord};
    use suins::suins::{Self, SuiNS};

    /// Get the data from the NameRecord.
    public fun get(
        suins: &SuiNS,
        domain_name: String
    ): &VecMap<String, String> {
        name_record::data(suins::name_record<NameRecord>(suins, domain_name))
    }

    /// Set the data in the NameRecord.
    public fun set(
        suins: &mut SuiNS,
        domain_name: String,
        data: VecMap<String, String>,
        ctx: &mut TxContext
    ) {
        let record_mut = suins::name_record_mut(suins, domain_name, ctx);
        name_record::set_data(record_mut, data)
    }
}
