use crate::models::sui::dynamic_field::Field;
use crate::models::suins::domain::Domain;
use crate::models::suins::name_record::NameRecord;
use crate::models::suins::subdomain_registration::SubDomainRegistration;
use crate::models::{NameRecordChange, SuinsCheckpointData, SuinsIndexerCheckpoint};
use anyhow::anyhow;
use async_trait::async_trait;
use diesel::dsl::case_when;
use diesel::upsert::excluded;
use diesel::{BoolExpressionMethods, ExpressionMethods};
use diesel_async::scoped_futures::ScopedFutureExt;
use diesel_async::{AsyncConnection, RunQueryDsl};
use futures::future::try_join_all;
use move_core_types::language_storage::StructTag;
use std::collections::HashSet;
use std::sync::Arc;
use sui_indexer_alt_framework::pipeline::concurrent::Handler;
use sui_indexer_alt_framework::pipeline::Processor;
use sui_pg_db::{Connection, Db};
use sui_types::base_types::SuiAddress;
use sui_types::full_checkpoint_content::{CheckpointData, CheckpointTransaction};
use sui_types::object::Object;

#[macro_export]
macro_rules! update_field_query {
    ($field:ident) => {{
        case_when(
            excluded(last_checkpoint_updated).gt(last_checkpoint_updated),
            excluded($field),
        )
        .otherwise($field)
    }};
}

pub struct DomainHandler {
    registry_table_id: SuiAddress,
    subdomain_wrapper_type: StructTag,
    name_record_type: StructTag,
}

impl DomainHandler {
    pub fn new(
        registry_table_id: SuiAddress,
        subdomain_wrapper_type: StructTag,
        name_record_type: StructTag,
    ) -> Self {
        Self {
            registry_table_id,
            name_record_type,
            subdomain_wrapper_type,
        }
    }

    /// Filter by the dynamic field value type.
    /// A valid name record for an object has the type `Field<Domain,NameRecord>,
    /// and the parent of it is the `registry` table id.
    pub fn is_name_record(&self, object: &Object) -> bool {
        object
            .get_single_owner()
            .is_some_and(|owner| owner == self.registry_table_id)
            && object
                .struct_tag()
                .is_some_and(|tag| tag == self.name_record_type)
    }

    /// Checks if the object referenced is a subdomain wrapper.
    /// For subdomain wrappers, we're saving the ID of the wrapper object,
    /// to make it easy to locate the NFT (since the base NFT gets wrapped and indexing won't work there).
    pub fn is_subdomain_wrapper(&self, object: &Object) -> bool {
        object
            .struct_tag()
            .is_some_and(|tag| tag == self.subdomain_wrapper_type)
    }

    /// Parses the name record changes + subdomain wraps.
    /// and pushes them into the supplied vector + hashmap.
    ///
    /// It is implemented in a way to do just a single iteration over the objects.
    pub fn parse_record_changes(
        &self,
        results: &mut SuinsIndexerCheckpoint,
        objects: &[Object],
    ) -> anyhow::Result<()> {
        for object in objects {
            // Parse all the changes to a `NameRecord`
            if self.is_name_record(object) {
                let name_record: Field<Domain, NameRecord> = object
                    .to_rust()
                    .ok_or_else(|| anyhow!("Failed to parse name record for {:?}", object))?;

                let id = object.id();

                // Remove from the removals list if it's there.
                // The reason it might have been there is that the same name record might have been
                // deleted in a previous transaction in the same checkpoint, and now it got re-created.
                results.removals.remove(&id);

                results
                    .name_records
                    .insert(id, NameRecordChange(name_record));
            }
            // Parse subdomain wrappers and save them in our hashmap.
            // Later, we'll save the id of the wrapper in the name record.
            // NameRecords & their equivalent SubdomainWrappers are always created in the same PTB, so we can safely assume
            // that the wrapper will be created on the same checkpoint as the name record and vice versa.
            if self.is_subdomain_wrapper(object) {
                let sub_domain: SubDomainRegistration = object.to_rust().ok_or_else(|| {
                    anyhow!(
                        "Failed to deserialize SubDomainRegistration object {:?}",
                        object
                    )
                })?;
                results
                    .subdomain_wrappers
                    .insert(sub_domain.nft.domain_name, sub_domain.id.to_string());
            };
        }
        Ok(())
    }

    /// Parses a list of the deletions in the checkpoint and adds them to the removals list.
    /// Also removes any name records from the updates, if they ended up being deleted in the same checkpoint.
    pub fn parse_record_deletions(
        &self,
        results: &mut SuinsIndexerCheckpoint,
        transaction: &CheckpointTransaction,
    ) {
        // a list of all the deleted objects in the transaction.
        let deleted_objects: HashSet<_> = transaction
            .effects
            .all_tombstones()
            .into_iter()
            .map(|(id, _)| id)
            .collect();

        for input in transaction.input_objects.iter() {
            if self.is_name_record(input) && deleted_objects.contains(&input.id()) {
                // since this record was deleted, we need to remove it from the name_records hashmap.
                // that catches a case where a name record was edited on a previous transaction in the checkpoint
                // and deleted from a different tx later in the checkpoint.
                results.name_records.remove(&input.id());

                // add it in the list of removals
                results.removals.insert(input.id());
            }
        }
    }
}

#[async_trait]
impl Handler for DomainHandler {
    type Store = Db;

    async fn commit<'a>(
        values: &[Self::Value],
        conn: &mut Connection<'a>,
    ) -> anyhow::Result<usize> {
        use crate::schema::domains::*;
        // split data
        let (updates, removals) =
            values
                .iter()
                .fold((vec![], vec![]), |(mut updates, mut removals), value| {
                    updates.extend(value.updates.clone());
                    removals.push((value.checkpoint, value.removals.clone()));
                    (updates, removals)
                });

        Ok(conn
            .transaction(|conn| {
                async move {
                    if updates.is_empty() && removals.is_empty() {
                        return Ok::<_, anyhow::Error>(0);
                    }
                    // commit all Verified Domains
                    let mut changes = 0usize;
                    if !updates.is_empty() {
                        // Bulk insert all updates and override with data.
                        changes += diesel::insert_into(table)
                            .values(updates)
                            .on_conflict(name)
                            .do_update()
                            .set((
                                expiration_timestamp_ms
                                    .eq(update_field_query!(expiration_timestamp_ms)),
                                nft_id.eq(update_field_query!(nft_id)),
                                target_address.eq(update_field_query!(target_address)),
                                data.eq(update_field_query!(data)),
                                last_checkpoint_updated
                                    .eq(update_field_query!(last_checkpoint_updated)),
                                field_id.eq(update_field_query!(field_id)),
                                // We always want to respect the subdomain_wrapper re-assignment, even if the checkpoint is older.
                                // That prevents a scenario where we first process a later checkpoint that did an update to the name record (e..g change target address),
                                // without first executing the checkpoint that created the subdomain wrapper.
                                // Since wrapper re-assignment can only happen every 2 days, we can't write invalid data here.
                                subdomain_wrapper_id.eq(case_when(
                                    excluded(subdomain_wrapper_id).is_not_null(),
                                    excluded(subdomain_wrapper_id),
                                )
                                .otherwise(subdomain_wrapper_id)),
                            ))
                            .execute(conn)
                            .await?;
                    }

                    // Update removals for each checkpoint
                    changes += try_join_all(removals.iter().map(|(checkpoint, removals)| {
                        // We want to remove from the database all name records that were removed in the checkpoint
                        // but only if the checkpoint is newer than the last time the name record was updated.
                        diesel::delete(table)
                            .filter(
                                field_id
                                    .eq_any(removals)
                                    .and(last_checkpoint_updated.le(*checkpoint as i64)),
                            )
                            .execute(conn)
                    }))
                    .await?
                    .iter()
                    .sum::<usize>();

                    Ok(changes)
                }
                .scope_boxed()
            })
            .await?)
    }
}

impl Processor for DomainHandler {
    const NAME: &'static str = "Domain";
    type Value = SuinsCheckpointData;

    fn process(&self, checkpoint: &Arc<CheckpointData>) -> anyhow::Result<Vec<Self::Value>> {
        let data = checkpoint.transactions.iter().try_fold(
            SuinsIndexerCheckpoint::default(),
            |mut results, tx| {
                // loop through all the transactions in the checkpoint
                // Since the transactions are sequenced inside the checkpoint, we can safely assume
                // that we have the latest data for each name record in the end of the loop.
                // Add all name record changes to the name_records HashMap.
                // Remove any removals that got re-created.
                self.parse_record_changes(&mut results, &tx.output_objects)?;

                // Gather all removals from the transaction,
                // and delete any name records from the name_records if it got deleted.
                self.parse_record_deletions(&mut results, tx);
                Ok::<_, anyhow::Error>(results)
            },
        )?;

        // Convert our name_records & wrappers into a list of updates for the DB.
        Ok(vec![SuinsCheckpointData {
            updates: data.prepare_db_updates(checkpoint.checkpoint_summary.sequence_number),
            removals: data
                .removals
                .into_iter()
                .map(|id| id.to_hex_uncompressed())
                .collect(),
            checkpoint: checkpoint.checkpoint_summary.sequence_number,
        }])
    }
}
