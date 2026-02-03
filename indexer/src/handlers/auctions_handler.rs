use crate::events::{
    convert_domain_name, try_deserialize_event, AuctionCancelledEvent, AuctionCreatedEvent,
    AuctionFinalizedEvent, BidPlacedEvent, SetSealConfig, SetServiceFee,
};
use crate::models::{
    Auction, AuctionStatus, Bid, SetSealConfigModel, SetServiceFeeModel, UpdateAuction,
};
use crate::schema::{auctions, bids, set_seal_config, set_service_fee};
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
    SetSealConfig(SetSealConfig),
    SetServiceFee(SetServiceFee),
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

    const MAX_BATCH_CHECKPOINTS: usize = 5 * 10;

    fn batch(batch: &mut Self::Batch, values: Vec<Self::Value>) {
        batch.extend(values);
    }

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
                            token: created_event.token.to_string(),
                            reserve_price_encrypted: created_event.reserve_price.clone(),
                            reserve_price: None,
                        }])
                        .on_conflict(auctions::auction_id)
                        .do_update()
                        .set((
                            auctions::domain_name.eq(excluded(auctions::domain_name)),
                            auctions::owner.eq(excluded(auctions::owner)),
                            auctions::start_time.eq(excluded(auctions::start_time)),
                            auctions::end_time.eq(excluded(auctions::end_time)),
                            auctions::min_bid.eq(excluded(auctions::min_bid)),
                            auctions::status.eq(excluded(auctions::status)),
                            auctions::updated_at.eq(excluded(auctions::updated_at)),
                            auctions::created_at.eq(excluded(auctions::created_at)),
                            auctions::last_tx_digest.eq(excluded(auctions::last_tx_digest)),
                            auctions::token.eq(excluded(auctions::token)),
                            auctions::reserve_price_encrypted
                                .eq(excluded(auctions::reserve_price_encrypted)),
                        ))
                        .filter(auctions::updated_at.le(excluded(auctions::updated_at)))
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

                    diesel::update(QueryDsl::filter(
                        auctions::table,
                        auctions::auction_id
                            .eq(auction_cancelled.auction_id.to_string())
                            .and(auctions::updated_at.le(value.created_at)),
                    ))
                    .set(UpdateAuction {
                        reserve_price: None, // Don't update reserve_price on cancel
                        winner: None,        // Don't update winner on cancel
                        amount: None,        // Don't update amount on cancel
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
                        auction_finalized.auction_id, domain_name, auction_finalized.highest_bidder
                    );

                    diesel::update(QueryDsl::filter(
                        auctions::table,
                        auctions::auction_id
                            .eq(auction_finalized.auction_id.to_string())
                            .and(auctions::updated_at.le(value.created_at)),
                    ))
                    .set(UpdateAuction {
                        reserve_price: Some(Some(auction_finalized.reserve_price as i64)),
                        winner: Some(Some(auction_finalized.highest_bidder.to_string())),
                        amount: Some(Some(auction_finalized.amount.to_string())),
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
                            token: bid_event.token.to_string(),
                        }])
                        .execute(conn)
                        .await
                        .map_err(Into::<Error>::into)?;
                }
                AuctionEvent::SetSealConfig(seal_config_event) => {
                    info!(
                        "SetSealConfig: key_servers count={}, threshold={}",
                        seal_config_event.key_servers.len(),
                        seal_config_event.threshold
                    );

                    diesel::insert_into(set_seal_config::table)
                        .values(vec![SetSealConfigModel {
                            key_servers: seal_config_event
                                .key_servers
                                .iter()
                                .map(|addr| addr.to_string())
                                .collect(),
                            public_keys: seal_config_event.public_keys.clone(),
                            threshold: seal_config_event.threshold as i16,
                            created_at: value.created_at,
                            tx_digest: value.tx_digest.clone(),
                        }])
                        .execute(conn)
                        .await
                        .map_err(Into::<Error>::into)?;
                }
                AuctionEvent::SetServiceFee(service_fee_event) => {
                    info!(
                        "SetServiceFee: service_fee={}",
                        service_fee_event.service_fee
                    );

                    diesel::insert_into(set_service_fee::table)
                        .values(vec![SetServiceFeeModel {
                            service_fee: service_fee_event.service_fee.to_string(),
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

                let created_event: AuctionCreatedEvent = try_deserialize_event(&event.contents)
                    .inspect_err(|error| {
                        error!("Could not deserialize AuctionCreatedEvent: {}", error)
                    })?;

                return Ok(Some(AuctionEvent::Created(created_event)));
            } else if event_type.ends_with("::AuctionCancelledEvent") {
                info!("Found Auction event: {} ", event_type);

                let cancel_event: AuctionCancelledEvent = try_deserialize_event(&event.contents)
                    .inspect_err(|error| {
                        error!("Could not deserialize AuctionCancelledEvent: {}", error)
                    })?;

                return Ok(Some(AuctionEvent::Cancelled(cancel_event)));
            } else if event_type.ends_with("::AuctionFinalizedEvent") {
                info!("Found Auction event: {} ", event_type);

                let finalized_event: AuctionFinalizedEvent = try_deserialize_event(&event.contents)
                    .inspect_err(|error| {
                        error!("Could not deserialize AuctionFinalizedEvent: {}", error)
                    })?;

                return Ok(Some(AuctionEvent::Finalized(finalized_event)));
            } else if event_type.ends_with("::BidPlacedEvent") {
                info!("Found Bid event: {} ", event_type);

                let bid_event: BidPlacedEvent = try_deserialize_event(&event.contents)
                    .inspect_err(|error| {
                        error!("Could not deserialize BidPlacedEvent: {}", error)
                    })?;

                return Ok(Some(AuctionEvent::Bid(bid_event)));
            } else if event_type.ends_with("::SetSealConfig") {
                let seal_config_event: SetSealConfig = try_deserialize_event(&event.contents)
                    .inspect_err(|error| {
                        error!("Could not deserialize SetSealConfig: {}", error)
                    })?;

                return Ok(Some(AuctionEvent::SetSealConfig(seal_config_event)));
            } else if event_type.ends_with("::SetServiceFee") {
                let service_fee_event: SetServiceFee = try_deserialize_event(&event.contents)
                    .inspect_err(|error| {
                        error!("Could not deserialize SetServiceFee: {}", error)
                    })?;

                return Ok(Some(AuctionEvent::SetServiceFee(service_fee_event)));
            }
        }

        Ok(None)
    }
}
