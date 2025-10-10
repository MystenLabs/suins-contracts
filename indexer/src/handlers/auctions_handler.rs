use crate::events::{
    convert_domain_name, try_deserialize_event, AuctionCancelledEvent, AuctionCreatedEvent,
    AuctionFinalizedEvent, BidPlacedEvent,
};
use crate::models::{Auction, AuctionStatus, Bid, UpdateAuction};
use crate::schema::{auctions, bids};
use anyhow::{Context, Error};
use async_trait::async_trait;
use diesel::internal::derives::multiconnection::chrono::{DateTime, Utc};
use diesel::{ExpressionMethods, QueryDsl};
use diesel_async::RunQueryDsl;
use log::{error, info};
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
pub enum AuctionEvent {
    Created(AuctionCreatedEvent),
    Cancelled(AuctionCancelledEvent),
    Finalized(AuctionFinalizedEvent),
    Bid(BidPlacedEvent),
}

#[derive(FieldCount, Clone)]
pub struct AuctionValue {
    event: AuctionEvent,
    created_at: DateTime<Utc>,
    tx_digest: String,
}

pub struct AuctionsHandlerPipeline {
    contract_package_id: String,
}

impl Processor for AuctionsHandlerPipeline {
    const NAME: &'static str = "auctions";

    type Value = AuctionValue;

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
                                values.push(AuctionValue {
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
impl Handler for AuctionsHandlerPipeline {
    type Store = Db;
    type Batch = Vec<Self::Value>;

    fn batch(batch: &mut Self::Batch, values: Vec<Self::Value>) {
        batch.extend(values);
    }

    // Execute everything inside a transaction for efficiency and for the fact that if something errors, the whole batch will be reverted to not wind up with invalid data in the database
    async fn commit<'a>(batch: &Self::Batch, conn: &mut Connection<'a>) -> Result<usize> {
        if batch.is_empty() {
            return Ok(0);
        }

        let len = batch.len();

        info!("Processing {} auction events", len);

        for value in batch {
            match &value.event {
                AuctionEvent::Created(created_event) => {
                    let domain_name = convert_domain_name(&created_event.domain_name);

                    diesel::insert_into(auctions::table)
                        .values(vec![Auction {
                            auction_id: created_event.auction_id.to_string(),
                            domain_name,
                            owner: created_event.owner.to_string(),
                            start_time: created_event.start_time as i64,
                            end_time: created_event.end_time as i64,
                            min_bid: created_event.min_bid.to_string(),
                            winner: None,
                            amount: None,
                            status: AuctionStatus::Created,
                            updated_at: value.created_at,
                            created_at: value.created_at,
                            last_tx_digest: value.tx_digest.clone(),
                        }])
                        .execute(conn)
                        .await
                        .map_err(Into::<Error>::into)?;
                }
                AuctionEvent::Cancelled(auction_cancelled) => {
                    let domain_name = convert_domain_name(&auction_cancelled.domain_name);

                    info!(
                        "Cancelling auction {} for domain {} and owner {}",
                        auction_cancelled.auction_id, domain_name, auction_cancelled.owner
                    );

                    diesel::update(
                        auctions::table
                            .filter(auctions::auction_id.eq(auction_cancelled.auction_id.to_string())),
                    )
                    .set(UpdateAuction {
                        winner: None,
                        amount: None,
                        status: AuctionStatus::Cancelled,
                        updated_at: value.created_at,
                        last_tx_digest: value.tx_digest.clone(),
                    })
                    .execute(conn)
                    .await?;
                }
                AuctionEvent::Finalized(auction_finalized) => {
                    let domain_name = convert_domain_name(&auction_finalized.domain_name);

                    info!(
                        "Finalized auction {} for domain {}, winner {}",
                        auction_finalized.auction_id, domain_name, auction_finalized.winner
                    );

                    diesel::update(
                        auctions::table
                            .filter(auctions::auction_id.eq(auction_finalized.auction_id.to_string())),
                    )
                    .set(UpdateAuction {
                        winner: Some(auction_finalized.winner.to_string()),
                        amount: Some(auction_finalized.amount.to_string()),
                        status: AuctionStatus::Finalized,
                        updated_at: value.created_at,
                        last_tx_digest: value.tx_digest.clone(),
                    })
                    .execute(conn)
                    .await?;
                }
                AuctionEvent::Bid(bid_event) => {
                    let domain_name = convert_domain_name(&bid_event.domain_name);

                    info!(
                        "Bid placed for domain {}, auction id {}, bidder {}",
                        domain_name, bid_event.auction_id, bid_event.bidder
                    );

                    diesel::insert_into(bids::table)
                        .values(vec![Bid {
                            auction_id: bid_event.auction_id.to_string(),
                            domain_name,
                            bidder: bid_event.bidder.to_string(),
                            amount: bid_event.amount.to_string(),
                            created_at: value.created_at,
                            tx_digest: value.tx_digest.clone(),
                        }])
                        .execute(conn)
                        .await
                        .map_err(Into::<Error>::into)?;
                }
            }
        }

        Ok(len)
    }
}

impl AuctionsHandlerPipeline {
    pub fn new(auction_contract_id: SuiAddress) -> Self {
        Self {
            contract_package_id: auction_contract_id.to_string(),
        }
    }

    fn process_event(&self, event: &Event) -> Result<Option<AuctionEvent>> {
        let event_type = event.type_.to_string();
        if event_type.starts_with(&self.contract_package_id) {
            if event_type.ends_with("::AuctionCreatedEvent") {
                info!("Found Auction event: {} ", event_type);

                let created_event: AuctionCreatedEvent = try_deserialize_event(&event.contents)?;

                return Ok(Some(AuctionEvent::Created(created_event)));
            } else if event_type.ends_with("::AuctionCancelledEvent") {
                info!("Found Auction event: {} ", event_type);

                let cancel_event: AuctionCancelledEvent = try_deserialize_event(&event.contents)?;

                return Ok(Some(AuctionEvent::Cancelled(cancel_event)));
            } else if event_type.ends_with("::AuctionFinalizedEvent ") {
                info!("Found Auction event: {} ", event_type);

                let finalized_event: AuctionFinalizedEvent =
                    try_deserialize_event(&event.contents)?;

                return Ok(Some(AuctionEvent::Finalized(finalized_event)));
            } else if event_type.ends_with("::BidPlacedEvent ") {
                info!("Found Bid event: {} ", event_type);

                let bid_event: BidPlacedEvent = try_deserialize_event(&event.contents)?;

                return Ok(Some(AuctionEvent::Bid(bid_event)));
            }
        }

        Ok(None)
    }
}
