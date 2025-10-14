// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

use crate::models::sui::dynamic_field::Field;
use crate::models::suins::domain::Domain;
use crate::models::suins::name_record::NameRecord;
use crate::schema::domains;
use crate::schema::*;
use diesel::internal::derives::multiconnection::chrono::{DateTime, Utc};
use diesel::prelude::*;
use diesel::{AsExpression, FromSqlRow};
use move_binding_derive::move_contract;
use serde::{Deserialize, Serialize};
use std::collections::{HashMap, HashSet};
use sui_indexer_alt_framework::FieldCount;
use sui_name_service::Domain as NsDomain;
use sui_types::base_types::ObjectID;

move_contract! {alias = "sui", package = "0x2", base_path = crate::models}
move_contract! {alias = "suins", package = "@suins/core", base_path = crate::models}

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

impl VerifiedDomain {
    pub fn merge(self, other: VerifiedDomain) -> VerifiedDomain {
        let (mut new, old) = if self.last_checkpoint_updated > other.last_checkpoint_updated {
            (self, other)
        } else {
            (other, self)
        };
        if new.subdomain_wrapper_id.is_none() {
            new.subdomain_wrapper_id = old.subdomain_wrapper_id;
        }
        new
    }
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

#[derive(Insertable, Debug, FieldCount, Clone)]
#[diesel(table_name = offer_placed)]
#[diesel(check_for_backend(diesel::pg::Pg))]
pub struct OfferPlaced {
    pub domain_name: String,
    pub address: String,
    pub value: String,
    pub created_at: DateTime<Utc>,
    pub tx_digest: String,
    pub token: String,
}

#[derive(Insertable, Debug, FieldCount, Clone)]
#[diesel(table_name = offer_cancelled)]
#[diesel(check_for_backend(diesel::pg::Pg))]
pub struct OfferCancelled {
    pub domain_name: String,
    pub address: String,
    pub value: String,
    pub created_at: DateTime<Utc>,
    pub tx_digest: String,
    pub token: String,
}

#[derive(Insertable, Debug, FieldCount, Clone)]
#[diesel(table_name = offer_accepted)]
#[diesel(check_for_backend(diesel::pg::Pg))]
pub struct OfferAccepted {
    pub domain_name: String,
    pub address: String,
    pub owner: String,
    pub value: String,
    pub created_at: DateTime<Utc>,
    pub tx_digest: String,
    pub token: String,
}

#[derive(Insertable, Debug, FieldCount, Clone)]
#[diesel(table_name = offer_declined)]
#[diesel(check_for_backend(diesel::pg::Pg))]
pub struct OfferDeclined {
    pub domain_name: String,
    pub address: String,
    pub owner: String,
    pub value: String,
    pub created_at: DateTime<Utc>,
    pub tx_digest: String,
    pub token: String,
}

#[derive(Insertable, Debug, FieldCount, Clone)]
#[diesel(table_name = make_counter_offer)]
#[diesel(check_for_backend(diesel::pg::Pg))]
pub struct MakeCounterOffer {
    pub domain_name: String,
    pub address: String,
    pub owner: String,
    pub value: String,
    pub created_at: DateTime<Utc>,
    pub tx_digest: String,
    pub token: String,
}

#[derive(Insertable, Debug, FieldCount, Clone)]
#[diesel(table_name = accept_counter_offer)]
#[diesel(check_for_backend(diesel::pg::Pg))]
pub struct AcceptCounterOffer {
    pub domain_name: String,
    pub address: String,
    pub value: String,
    pub created_at: DateTime<Utc>,
    pub tx_digest: String,
    pub token: String,
}

#[derive(Debug, Clone, Queryable, Selectable, Insertable, Serialize, Deserialize)]
#[diesel(table_name = offers)]
pub struct Offer {
    pub domain_name: String,
    pub buyer: String,
    pub initial_value: String,
    pub value: String,
    pub owner: Option<String>,
    pub status: OfferStatus,
    pub updated_at: DateTime<Utc>,
    pub created_at: DateTime<Utc>,
    pub last_tx_digest: String,
    pub token: String,
}

#[derive(Debug, Clone, AsChangeset, Serialize, Deserialize)]
#[diesel(table_name = offers)]
pub struct UpdateOffer {
    pub value: String,
    pub owner: Option<Option<String>>,
    pub status: OfferStatus,
    pub updated_at: DateTime<Utc>,
    pub last_tx_digest: String,
}

#[derive(
    Debug, Clone, Copy, PartialEq, Eq, Hash, AsExpression, FromSqlRow, Serialize, Deserialize,
)]
#[diesel(sql_type = crate::schema::sql_types::Offerstatus)]
pub enum OfferStatus {
    Placed,
    Cancelled,
    Accepted,
    Declined,
    Countered,
    AcceptedCountered,
}

#[derive(Debug, Clone, Queryable, Selectable, Insertable, Serialize, Deserialize)]
#[diesel(table_name = auctions)]
pub struct Auction {
    pub auction_id: String,
    pub domain_name: String,
    pub owner: String,
    pub start_time: i64,
    pub end_time: i64,
    pub min_bid: String,
    pub winner: Option<String>,
    pub amount: Option<String>,
    pub status: AuctionStatus,
    pub updated_at: DateTime<Utc>,
    pub created_at: DateTime<Utc>,
    pub last_tx_digest: String,
    pub token: String,
}

#[derive(Debug, Clone, AsChangeset, Serialize, Deserialize)]
#[diesel(table_name = auctions)]
pub struct UpdateAuction {
    pub winner: Option<String>,
    pub amount: Option<String>,
    pub status: AuctionStatus,
    pub updated_at: DateTime<Utc>,
    pub last_tx_digest: String,
}

#[derive(Debug, Clone, Queryable, Selectable, Insertable, Serialize, Deserialize)]
#[diesel(table_name = bids)]
pub struct Bid {
    pub auction_id: String,
    pub domain_name: String,
    pub bidder: String,
    pub amount: String,
    pub created_at: DateTime<Utc>,
    pub tx_digest: String,
    pub token: String,
}

#[derive(
    Debug, Clone, Copy, PartialEq, Eq, Hash, AsExpression, FromSqlRow, Serialize, Deserialize,
)]
#[diesel(sql_type = crate::schema::sql_types::Auctionstatus)]
pub enum AuctionStatus {
    Created,
    Cancelled,
    Finalized,
}

impl diesel::serialize::ToSql<sql_types::Offerstatus, diesel::pg::Pg> for OfferStatus {
    fn to_sql<'b>(
        &'b self,
        out: &mut diesel::serialize::Output<'b, '_, diesel::pg::Pg>,
    ) -> diesel::serialize::Result {
        let value = match self {
            OfferStatus::Placed => "placed",
            OfferStatus::Cancelled => "cancelled",
            OfferStatus::Accepted => "accepted",
            OfferStatus::Declined => "declined",
            OfferStatus::Countered => "countered",
            OfferStatus::AcceptedCountered => "accepted-countered",
        };
        <str as diesel::serialize::ToSql<diesel::sql_types::Text, diesel::pg::Pg>>::to_sql(
            value,
            &mut out.reborrow(),
        )
    }
}

impl diesel::deserialize::FromSql<sql_types::Offerstatus, diesel::pg::Pg> for OfferStatus {
    fn from_sql(
        bytes: <diesel::pg::Pg as diesel::backend::Backend>::RawValue<'_>,
    ) -> diesel::deserialize::Result<Self> {
        let value = <String as diesel::deserialize::FromSql<
            diesel::sql_types::Text,
            diesel::pg::Pg,
        >>::from_sql(bytes)?;
        match value.as_str() {
            "placed" => Ok(OfferStatus::Placed),
            "cancelled" => Ok(OfferStatus::Cancelled),
            "accepted" => Ok(OfferStatus::Accepted),
            "declined" => Ok(OfferStatus::Declined),
            "countered" => Ok(OfferStatus::Countered),
            "accepted-countered" => Ok(OfferStatus::AcceptedCountered),
            _ => Err("Unrecognized enum variant".into()),
        }
    }
}

impl diesel::serialize::ToSql<sql_types::Auctionstatus, diesel::pg::Pg> for AuctionStatus {
    fn to_sql<'b>(
        &'b self,
        out: &mut diesel::serialize::Output<'b, '_, diesel::pg::Pg>,
    ) -> diesel::serialize::Result {
        let value = match self {
            AuctionStatus::Created => "created",
            AuctionStatus::Cancelled => "cancelled",
            AuctionStatus::Finalized => "finalized",
        };
        <str as diesel::serialize::ToSql<diesel::sql_types::Text, diesel::pg::Pg>>::to_sql(
            value,
            &mut out.reborrow(),
        )
    }
}

impl diesel::deserialize::FromSql<sql_types::Auctionstatus, diesel::pg::Pg> for AuctionStatus {
    fn from_sql(
        bytes: <diesel::pg::Pg as diesel::backend::Backend>::RawValue<'_>,
    ) -> diesel::deserialize::Result<Self> {
        let value = <String as diesel::deserialize::FromSql<
            diesel::sql_types::Text,
            diesel::pg::Pg,
        >>::from_sql(bytes)?;
        match value.as_str() {
            "created" => Ok(AuctionStatus::Created),
            "cancelled" => Ok(AuctionStatus::Cancelled),
            "finalized" => Ok(AuctionStatus::Finalized),
            _ => Err("Unrecognized enum variant".into()),
        }
    }
}
