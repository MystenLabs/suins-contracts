use crate::events::{
    convert_domain_name, try_deserialize_event, ListingBoughtEvent, ListingCancelledEvent,
    ListingCreatedEvent,
};
use crate::models::{Listing, ListingStatus, UpdateListing};
use crate::schema::listings;
use anyhow::{Context, Error};
use async_trait::async_trait;
use diesel::internal::derives::multiconnection::chrono::{DateTime, Utc};
use diesel::query_dsl::methods::FilterDsl;
use diesel::upsert::excluded;
use diesel::{BoolExpressionMethods, ExpressionMethods, QueryDsl};
use diesel_async::RunQueryDsl;
use log::{error, info};
use std::sync::Arc;
use sui_indexer_alt_framework::pipeline::sequential::Handler;
use sui_indexer_alt_framework::pipeline::Processor;
use sui_indexer_alt_framework::postgres::{Connection, Db};
use sui_indexer_alt_framework::types::full_checkpoint_content::Checkpoint;
use sui_indexer_alt_framework::FieldCount;
use sui_types::base_types::SuiAddress;
use sui_types::event::Event;

#[derive(Clone)]
pub enum ListingEvent {
    Created(ListingCreatedEvent),
    Bought(ListingBoughtEvent),
    Cancelled(ListingCancelledEvent),
}

#[derive(FieldCount, Clone)]
pub struct ListingValue {
    event: ListingEvent,
    created_at: DateTime<Utc>,
    tx_digest: String,
}

pub struct ListingsHandlerPipeline {
    contract_package_id: String,
}

#[async_trait]
impl Processor for ListingsHandlerPipeline {
    const NAME: &'static str = "listings";

    type Value = ListingValue;

    async fn process(&self, checkpoint: &Arc<Checkpoint>) -> anyhow::Result<Vec<Self::Value>> {
        let timestamp_ms: u64 = checkpoint.summary.timestamp_ms.into();
        let timestamp_i64 =
            i64::try_from(timestamp_ms).context("Timestamp too large to convert to i64")?;
        let created_at: DateTime<Utc> =
            DateTime::<Utc>::from_timestamp_millis(timestamp_i64).context("invalid timestamp")?;

        Ok(checkpoint
            .transactions
            .iter()
            .filter_map(|tx| {
                let mut values = Vec::new();

                let tx_digest = tx.transaction.digest().to_string();

                if let Some(events) = &tx.events {
                    for event in &events.data {
                        match self.process_event(event) {
                            Ok(Some(event)) => {
                                values.push(ListingValue {
                                    event,
                                    tx_digest: tx_digest.clone(),
                                    created_at,
                                });
                            }
                            Ok(None) => {
                                // No event to process
                            }
                            Err(e) => {
                                // Should not be reached
                                error!("Error processing event: {}", e);
                                panic!("Error processing event: {}", e);
                            }
                        }
                    }
                }

                if values.is_empty() {
                    return None;
                }

                Some(values)
            })
            .flatten()
            .collect())
    }
}

#[async_trait]
impl Handler for ListingsHandlerPipeline {
    type Store = Db;
    type Batch = Vec<Self::Value>;

    fn batch(&self, batch: &mut Self::Batch, values: std::vec::IntoIter<Self::Value>) {
        batch.extend(values);
    }

    async fn commit<'a>(
        &self,
        batch: &Self::Batch,
        conn: &mut Connection<'a>,
    ) -> anyhow::Result<usize> {
        if batch.is_empty() {
            return Ok(0);
        }

        let len = batch.len();

        info!("Processing {} listing events", len);

        for value in batch {
            match &value.event {
                ListingEvent::Created(created_event) => {
                    let domain_name = convert_domain_name(&created_event.domain_name);

                    diesel::insert_into(listings::table)
                        .values(Listing {
                            listing_id: created_event.listing_id.to_string(),
                            domain_name,
                            owner: created_event.owner.to_string(),
                            price: created_event.price.to_string(),
                            buyer: None,
                            status: ListingStatus::Created,
                            updated_at: value.created_at,
                            created_at: value.created_at,
                            last_tx_digest: value.tx_digest.clone(),
                            token: created_event.token.to_string(),
                            expires_at: created_event.expires_at.map(|e| e as i64),
                        })
                        .on_conflict(listings::listing_id)
                        .do_update()
                        .set((
                            listings::domain_name.eq(excluded(listings::domain_name)),
                            listings::owner.eq(excluded(listings::owner)),
                            listings::price.eq(excluded(listings::price)),
                            listings::status.eq(excluded(listings::status)),
                            listings::updated_at.eq(excluded(listings::updated_at)),
                            listings::created_at.eq(excluded(listings::created_at)),
                            listings::last_tx_digest.eq(excluded(listings::last_tx_digest)),
                            listings::token.eq(excluded(listings::token)),
                            listings::expires_at.eq(excluded(listings::expires_at)),
                        ))
                        .filter(listings::updated_at.le(excluded(listings::updated_at)))
                        .execute(conn)
                        .await
                        .map_err(Into::<Error>::into)?;
                }
                ListingEvent::Bought(bought_event) => {
                    let domain_name = convert_domain_name(&bought_event.domain_name);

                    info!(
                        "Bought listing {} for domain {}, buyer {}",
                        bought_event.listing_id, domain_name, bought_event.buyer
                    );

                    diesel::update(QueryDsl::filter(
                        listings::table,
                        listings::listing_id
                            .eq(bought_event.listing_id.to_string())
                            .and(listings::updated_at.le(value.created_at)),
                    ))
                    .set(UpdateListing {
                        buyer: Some(Some(bought_event.buyer.to_string())),
                        status: ListingStatus::Bought,
                        updated_at: value.created_at,
                        last_tx_digest: value.tx_digest.clone(),
                    })
                    .execute(conn)
                    .await?;
                }
                ListingEvent::Cancelled(cancelled_event) => {
                    let domain_name = convert_domain_name(&cancelled_event.domain_name);

                    info!(
                        "Cancelled listing {} for domain {}, owner {}",
                        cancelled_event.listing_id, domain_name, cancelled_event.owner
                    );

                    diesel::update(QueryDsl::filter(
                        listings::table,
                        listings::listing_id
                            .eq(cancelled_event.listing_id.to_string())
                            .and(listings::updated_at.le(value.created_at)),
                    ))
                    .set(UpdateListing {
                        buyer: None,
                        status: ListingStatus::Cancelled,
                        updated_at: value.created_at,
                        last_tx_digest: value.tx_digest.clone(),
                    })
                    .execute(conn)
                    .await?;
                }
            }
        }

        Ok(len)
    }
}

impl ListingsHandlerPipeline {
    pub fn new(auction_contract_id: SuiAddress) -> Self {
        Self {
            contract_package_id: auction_contract_id.to_string(),
        }
    }

    fn process_event(&self, event: &Event) -> anyhow::Result<Option<ListingEvent>> {
        let event_type = event.type_.to_string();
        if event_type.starts_with(&self.contract_package_id) {
            if event_type.ends_with("::ListingCreatedEvent") {
                info!("Found Listing event: {} ", event_type);

                let listing_event: ListingCreatedEvent = try_deserialize_event(&event.contents)?;

                return Ok(Some(ListingEvent::Created(listing_event)));
            } else if event_type.ends_with("::ListingBoughtEvent") {
                info!("Found Listing event: {} ", event_type);

                let bought_event: ListingBoughtEvent = try_deserialize_event(&event.contents)?;

                return Ok(Some(ListingEvent::Bought(bought_event)));
            } else if event_type.ends_with("::ListingCancelledEvent") {
                info!("Found Listing event: {} ", event_type);

                let cancelled_event: ListingCancelledEvent =
                    try_deserialize_event(&event.contents)?;

                return Ok(Some(ListingEvent::Cancelled(cancelled_event)));
            }
        }

        Ok(None)
    }
}
