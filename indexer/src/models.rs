// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

use crate::models::sui::dynamic_field::Field;
use crate::models::suins::domain::Domain;
use crate::models::suins::name_record::NameRecord;
use crate::schema::domains;
use diesel::prelude::*;
use move_binding_derive::move_contract;
use std::collections::{HashMap, HashSet};
use sui_indexer_alt_framework::FieldCount;
use sui_name_service::Domain as NsDomain;
use sui_types::base_types::ObjectID;

move_contract! {alias = "sui", package = "0x2"}
move_contract! {alias = "suins", package = "@suins/core", deps = [crate::models::sui]}

#[derive(Queryable, Selectable, Insertable, AsChangeset, Debug, FieldCount, Clone)]
#[diesel(table_name = domains)]
#[diesel(check_for_backend(diesel::pg::Pg))]
pub struct VerifiedDomain {
    pub field_id: String,
    pub name: String,
    pub parent: String,
    pub expiration_timestamp_ms: i64,
    pub nft_id: String,
    pub target_address: Option<String>,
    pub data: serde_json::Value,
    pub last_checkpoint_updated: i64,
    pub subdomain_wrapper_id: Option<String>,
}

#[derive(FieldCount, Clone)]
pub struct SuinsCheckpointData {
    pub updates: Vec<VerifiedDomain>,
    pub removals: Vec<String>,
    pub checkpoint: u64,
}

#[derive(Default)]
pub struct SuinsIndexerCheckpoint {
    /// A list of name records that have been updated in the checkpoint.
    pub name_records: HashMap<ObjectID, NameRecordChange>,
    /// A list of subdomain wrappers that have been created in the checkpoint.
    pub subdomain_wrappers: HashMap<String, String>,
    /// A list of name records that have been deleted in the checkpoint.
    pub removals: HashSet<ObjectID>,
}

impl SuinsIndexerCheckpoint {
    /// Prepares a vector of `VerifiedDomain`s to be inserted into the DB, taking in account
    /// the list of subdomain wrappers created as well as the checkpoint's sequence number.
    pub fn prepare_db_updates(&self, checkpoint_sequence_number: u64) -> Vec<VerifiedDomain> {
        let mut updates: Vec<VerifiedDomain> = vec![];

        for (field_id, name_record_change) in self.name_records.iter() {
            let name_record = &name_record_change.0;

            let name = to_ns_domain(&name_record.name);
            let parent = name.parent().to_string();
            let nft_id = name_record.value.nft_id.to_string();

            updates.push(VerifiedDomain {
                field_id: field_id.to_string(),
                name: name.to_string(),
                parent,
                expiration_timestamp_ms: name_record.value.expiration_timestamp_ms as i64,
                nft_id,
                target_address: name_record.value.target_address.map(|a| a.to_string()),
                // unwrapping must be safe as `value.data` is an on-chain value with VecMap<String,String> type.
                data: serde_json::to_value(&name_record.value.data).unwrap(),
                last_checkpoint_updated: checkpoint_sequence_number as i64,
                subdomain_wrapper_id: self.subdomain_wrappers.get(&name.to_string()).cloned(),
            });
        }

        updates
    }
}

fn to_ns_domain(domain: &Domain) -> NsDomain {
    // both structs models the same move struct, safe to unwrap.
    // Todo: better ways to handle this? Maybe add support for type override in move_binding.
    bcs::from_bytes(&bcs::to_bytes(&domain).unwrap()).unwrap()
}

pub struct NameRecordChange(pub Field<Domain, NameRecord>);
