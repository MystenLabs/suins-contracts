use crate::events::{
    convert_domain_name, try_deserialize_event, AcceptCounterOfferEvent, MakeCounterOfferEvent,
    OfferAcceptedEvent, OfferCancelledEvent, OfferDeclinedEvent, OfferPlacedEvent,
};
use crate::models::{Offer, OfferStatus, UpdateOffer};
use crate::schema::offers;
use anyhow::{Context, Error};
use async_trait::async_trait;
use diesel::internal::derives::multiconnection::chrono::{DateTime, Utc};
use diesel::prelude::*;
use diesel::{ExpressionMethods, QueryDsl};
use diesel_async::RunQueryDsl;
use log::{error, info, warn};
use std::sync::Arc;
use sui_indexer_alt_framework::postgres::{Connection, Db};
use sui_indexer_alt_framework::pipeline::sequential::Handler;
use sui_indexer_alt_framework::pipeline::Processor;
use sui_indexer_alt_framework::types::full_checkpoint_content::CheckpointData;
use sui_indexer_alt_framework::FieldCount;
use sui_indexer_alt_framework::Result;
use sui_types::base_types::SuiAddress;
use sui_types::event::Event;

#[derive(Clone)]
pub enum OfferEvent {
    Placed(OfferPlacedEvent),
    Cancelled(OfferCancelledEvent),
    Accepted(OfferAcceptedEvent),
    Declined(OfferDeclinedEvent),
    MakeCounterOffer(MakeCounterOfferEvent),
    AcceptCounterOffer(AcceptCounterOfferEvent),
}

#[derive(FieldCount, Clone)]
pub struct OfferValue {
    event: OfferEvent,
    created_at: DateTime<Utc>,
    tx_digest: String,
}

pub struct OffersHandlerPipeline {
    contract_package_id: String,
}

impl Processor for OffersHandlerPipeline {
    const NAME: &'static str = "offers";

    type Value = OfferValue;

    fn process(&self, checkpoint: &Arc<CheckpointData>) -> Result<Vec<Self::Value>> {
        let timestamp_ms: u64 = checkpoint.checkpoint_summary.timestamp_ms.into();
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
                                values.push(OfferValue {
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
impl Handler for OffersHandlerPipeline {
    type Store = Db;
    type Batch = Vec<Self::Value>;

    fn batch(batch: &mut Self::Batch, values: Vec<Self::Value>) {
        batch.extend(values);
    }

    async fn commit<'a>(batch: &Self::Batch, conn: &mut Connection<'a>) -> Result<usize> {
        if batch.is_empty() {
            return Ok(0);
        }

        let len = batch.len();

        info!("Processing {} offer events", len);

        for value in batch {
            match &value.event {
                OfferEvent::Placed(placed_event) => {
                    let domain_name = convert_domain_name(&placed_event.domain_name);

                    diesel::insert_into(offers::table)
                        .values(vec![Offer {
                            domain_name,
                            buyer: placed_event.address.to_string(),
                            initial_value: placed_event.value.to_string(),
                            value: placed_event.value.to_string(),
                            owner: None,
                            status: OfferStatus::Placed,
                            updated_at: value.created_at,
                            created_at: value.created_at,
                            last_tx_digest: value.tx_digest.clone(),
                            token: placed_event.token.to_string(),
                        }])
                        .execute(conn)
                        .await
                        .map_err(Into::<Error>::into)?;
                }
                OfferEvent::Cancelled(offer_cancelled) => {
                    let domain_name = convert_domain_name(&offer_cancelled.domain_name);

                    let latest_offer_id =
                        Self::get_latest_offer_id(conn, &offer_cancelled.address, &domain_name)
                            .await?;

                    // Then update if found
                    if let Some(id) = latest_offer_id {
                        info!(
                            "Cancelling offer for domain {} and buyer {}",
                            domain_name, offer_cancelled.address
                        );

                        diesel::update(offers::table.filter(offers::id.eq(id)))
                            .set(UpdateOffer {
                                value: offer_cancelled.value.to_string(),
                                owner: None, // won't be updated
                                status: OfferStatus::Cancelled,
                                updated_at: value.created_at,
                                last_tx_digest: value.tx_digest.clone(),
                            })
                            .execute(conn)
                            .await?;
                    }
                }
                OfferEvent::Accepted(offer_accepted) => {
                    let domain_name = convert_domain_name(&offer_accepted.domain_name);

                    let latest_offer_id =
                        Self::get_latest_offer_id(conn, &offer_accepted.buyer, &domain_name)
                            .await?;

                    if let Some(id) = latest_offer_id {
                        info!(
                            "Accepting offer for domain {} and buyer {}, owner {}",
                            domain_name, offer_accepted.buyer, offer_accepted.owner
                        );

                        diesel::update(offers::table.filter(offers::id.eq(id)))
                            .set(UpdateOffer {
                                value: offer_accepted.value.to_string(),
                                owner: Some(Some(offer_accepted.owner.to_string())),
                                status: OfferStatus::Accepted,
                                updated_at: value.created_at,
                                last_tx_digest: value.tx_digest.clone(),
                            })
                            .execute(conn)
                            .await?;
                    }
                }
                OfferEvent::Declined(offer_declined) => {
                    let domain_name = convert_domain_name(&offer_declined.domain_name);

                    let latest_offer_id =
                        Self::get_latest_offer_id(conn, &offer_declined.buyer, &domain_name)
                            .await?;

                    if let Some(id) = latest_offer_id {
                        info!(
                            "Declined offer for domain {} and buyer {}, owner {}",
                            domain_name, offer_declined.buyer, offer_declined.owner
                        );

                        diesel::update(offers::table.filter(offers::id.eq(id)))
                            .set(UpdateOffer {
                                value: offer_declined.value.to_string(),
                                owner: Some(Some(offer_declined.owner.to_string())),
                                status: OfferStatus::Declined,
                                updated_at: value.created_at,
                                last_tx_digest: value.tx_digest.clone(),
                            })
                            .execute(conn)
                            .await?;
                    }
                }
                OfferEvent::MakeCounterOffer(make_counter_offer) => {
                    let domain_name = convert_domain_name(&make_counter_offer.domain_name);

                    let latest_offer_id =
                        Self::get_latest_offer_id(conn, &make_counter_offer.buyer, &domain_name)
                            .await?;

                    if let Some(id) = latest_offer_id {
                        info!(
                            "Make counter offer for domain {} and buyer {}, owner {}",
                            domain_name, make_counter_offer.buyer, make_counter_offer.owner
                        );

                        diesel::update(offers::table.filter(offers::id.eq(id)))
                            .set(UpdateOffer {
                                value: make_counter_offer.value.to_string(),
                                owner: Some(Some(make_counter_offer.owner.to_string())),
                                status: OfferStatus::Countered,
                                updated_at: value.created_at,
                                last_tx_digest: value.tx_digest.clone(),
                            })
                            .execute(conn)
                            .await?;
                    }
                }
                OfferEvent::AcceptCounterOffer(accept_counter_offer) => {
                    let domain_name = convert_domain_name(&accept_counter_offer.domain_name);

                    let latest_offer_id =
                        Self::get_latest_offer_id(conn, &accept_counter_offer.buyer, &domain_name)
                            .await?;

                    if let Some(id) = latest_offer_id {
                        info!(
                            "Accepted counter offer for domain {} and buyer {}",
                            domain_name, accept_counter_offer.buyer
                        );

                        diesel::update(offers::table.filter(offers::id.eq(id)))
                            .set(UpdateOffer {
                                value: accept_counter_offer.value.to_string(),
                                owner: None,
                                status: OfferStatus::AcceptedCountered,
                                updated_at: value.created_at,
                                last_tx_digest: value.tx_digest.clone(),
                            })
                            .execute(conn)
                            .await?;
                    }
                }
            }
        }

        Ok(len)
    }
}

impl OffersHandlerPipeline {
    pub fn new(auction_contract_id: SuiAddress) -> Self {
        Self {
            contract_package_id: auction_contract_id.to_string(),
        }
    }

    fn process_event(&self, event: &Event) -> Result<Option<OfferEvent>> {
        let event_type = event.type_.to_string();
        if event_type.starts_with(&self.contract_package_id) {
            if event_type.ends_with("::OfferPlacedEvent") {
                info!("Found Offer event: {} ", event_type);

                let offer_event: OfferPlacedEvent = try_deserialize_event(&event.contents)?;

                return Ok(Some(OfferEvent::Placed(offer_event)));
            } else if event_type.ends_with("::OfferCancelledEvent") {
                info!("Found Offer event: {} ", event_type);

                let cancel_event: OfferCancelledEvent = try_deserialize_event(&event.contents)?;

                return Ok(Some(OfferEvent::Cancelled(cancel_event)));
            } else if event_type.ends_with("::OfferAcceptedEvent") {
                info!("Found Offer event: {} ", event_type);

                let accepted_event: OfferAcceptedEvent = try_deserialize_event(&event.contents)?;

                return Ok(Some(OfferEvent::Accepted(accepted_event)));
            } else if event_type.ends_with("::OfferDeclinedEvent") {
                info!("Found Offer event: {} ", event_type);

                let declined_event: OfferDeclinedEvent = try_deserialize_event(&event.contents)?;

                return Ok(Some(OfferEvent::Declined(declined_event)));
            } else if event_type.ends_with("::MakeCounterOfferEvent") {
                info!("Found Offer event: {} ", event_type);

                let make_counter_offer_event: MakeCounterOfferEvent =
                    try_deserialize_event(&event.contents)?;

                return Ok(Some(OfferEvent::MakeCounterOffer(make_counter_offer_event)));
            } else if event_type.ends_with("::AcceptCounterOfferEvent") {
                info!("Found Offer event: {} ", event_type);

                let accept_counter_offer_event: AcceptCounterOfferEvent =
                    try_deserialize_event(&event.contents)?;

                return Ok(Some(OfferEvent::AcceptCounterOffer(
                    accept_counter_offer_event,
                )));
            }
        }

        Ok(None)
    }

    async fn get_latest_offer_id<'a>(
        conn: &mut Connection<'a>,
        buyer: &SuiAddress,
        domain_name: &String,
    ) -> Result<Option<i32>> {
        let result = offers::table
            .select(offers::id)
            .filter(offers::domain_name.eq(&domain_name))
            .filter(offers::buyer.eq(&buyer.to_string()))
            .order(offers::updated_at.desc())
            .first(conn)
            .await
            .optional()?;

        if result.is_none() {
            warn!(
                "Could not find matching offer for domain {} and buyer {}",
                domain_name, buyer
            );
        }

        Ok(result)
    }
}
