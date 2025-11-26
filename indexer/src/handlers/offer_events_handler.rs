use crate::events::{
    convert_domain_name, try_deserialize_event, AcceptCounterOfferEvent, MakeCounterOfferEvent,
    OfferAcceptedEvent, OfferCancelledEvent, OfferDeclinedEvent, OfferPlacedEvent, SetSealConfig,
    SetServiceFee,
};
use crate::models::{
    AcceptCounterOffer, MakeCounterOffer, OfferAccepted, OfferCancelled, OfferDeclined,
    OfferPlaced, SetSealConfigModel, SetServiceFeeModel,
};
use crate::schema::{
    accept_counter_offer, make_counter_offer, offer_accepted, offer_cancelled, offer_declined,
    offer_placed, set_seal_config, set_service_fee,
};
use anyhow::Context;
use async_trait::async_trait;
use diesel::internal::derives::multiconnection::chrono::{DateTime, Utc};
use diesel_async::RunQueryDsl;
use log::{error, info};
use std::sync::Arc;
use sui_indexer_alt_framework::pipeline::concurrent::Handler;
use sui_indexer_alt_framework::pipeline::Processor;
use sui_indexer_alt_framework::postgres::{Connection, Db};
use sui_indexer_alt_framework::types::full_checkpoint_content::CheckpointData;
use sui_indexer_alt_framework::FieldCount;
use sui_indexer_alt_framework::Result;
use sui_types::base_types::SuiAddress;
use sui_types::event::Event;

pub enum OfferEventModel {
    Placed(OfferPlaced),
    Cancelled(OfferCancelled),
    Accepted(OfferAccepted),
    Declined(OfferDeclined),
    MakeCounterOffer(MakeCounterOffer),
    AcceptCounterOffer(AcceptCounterOffer),
    SetSealConfig(SetSealConfigModel),
    SetServiceFee(SetServiceFeeModel),
}

#[derive(FieldCount)]
pub struct OfferHandlerValue {
    pub placed: Vec<OfferPlaced>,
    pub cancelled: Vec<OfferCancelled>,
    pub accepted: Vec<OfferAccepted>,
    pub declined: Vec<OfferDeclined>,
    pub make_counter_offer: Vec<MakeCounterOffer>,
    pub accept_counter_offer: Vec<AcceptCounterOffer>,
    pub set_seal_config: Vec<SetSealConfigModel>,
    pub set_service_fee: Vec<SetServiceFeeModel>,
    pub checkpoint: u64,
}

pub struct OfferEventsHandlerPipeline {
    contract_package_id: String,
}

impl Processor for OfferEventsHandlerPipeline {
    const NAME: &'static str = "offer_events";

    type Value = OfferHandlerValue;

    fn process(&self, checkpoint: &Arc<CheckpointData>) -> Result<Vec<Self::Value>> {
        let timestamp_ms: u64 = checkpoint.checkpoint_summary.timestamp_ms.into();
        let timestamp_i64 =
            i64::try_from(timestamp_ms).context("Timestamp too large to convert to i64")?;
        let created_at: DateTime<Utc> =
            DateTime::<Utc>::from_timestamp_millis(timestamp_i64).context("invalid timestamp")?;

        let mut placed = Vec::new();
        let mut cancelled = Vec::new();
        let mut accepted = Vec::new();
        let mut declined = Vec::new();
        let mut make_counter_offer = Vec::new();
        let mut accept_counter_offer = Vec::new();
        let mut set_seal_config = Vec::new();
        let mut set_service_fee = Vec::new();

        for tx in &checkpoint.transactions {
            let tx_digest = tx.transaction.digest().to_string();
            if let Some(events) = &tx.events {
                for event in &events.data {
                    match self.process_event(event, &tx_digest, created_at) {
                        Ok(Some(OfferEventModel::Placed(offer))) => {
                            info!("Processing placed offer for domain: {}", offer.domain_name);
                            placed.push(offer);
                        }
                        Ok(Some(OfferEventModel::Cancelled(offer))) => {
                            info!(
                                "Processing cancelled offer for domain: {}",
                                offer.domain_name
                            );
                            cancelled.push(offer);
                        }
                        Ok(Some(OfferEventModel::Accepted(offer))) => {
                            info!(
                                "Processing accepted offer for domain: {}",
                                offer.domain_name
                            );
                            accepted.push(offer);
                        }
                        Ok(Some(OfferEventModel::Declined(offer))) => {
                            info!(
                                "Processing declined offer for domain: {}",
                                offer.domain_name
                            );
                            declined.push(offer);
                        }
                        Ok(Some(OfferEventModel::MakeCounterOffer(offer))) => {
                            info!(
                                "Processing make counter offer for domain: {}",
                                offer.domain_name
                            );
                            make_counter_offer.push(offer);
                        }
                        Ok(Some(OfferEventModel::AcceptCounterOffer(offer))) => {
                            info!(
                                "Processing accept counter offer for domain: {}",
                                offer.domain_name
                            );
                            accept_counter_offer.push(offer);
                        }
                        Ok(Some(OfferEventModel::SetSealConfig(config))) => {
                            info!("Processing SetSealConfig event");
                            set_seal_config.push(config);
                        }
                        Ok(Some(OfferEventModel::SetServiceFee(fee))) => {
                            info!("Processing SetServiceFee event");
                            set_service_fee.push(fee);
                        }
                        Ok(None) => {
                            // No event to process
                        }
                        Err(e) => {
                            error!("Error processing event: {}", e);
                            return Err(e);
                        }
                    }
                }
            }
        }

        let result = vec![OfferHandlerValue {
            placed,
            cancelled,
            accepted,
            declined,
            make_counter_offer,
            accept_counter_offer,
            set_seal_config,
            set_service_fee,
            checkpoint: checkpoint.checkpoint_summary.sequence_number,
        }];

        Ok(result)
    }
}

#[async_trait]
impl Handler for OfferEventsHandlerPipeline {
    type Store = Db;

    async fn commit<'a>(values: &[Self::Value], conn: &mut Connection<'a>) -> Result<usize> {
        let mut changes = 0usize;

        for value in values.iter() {
            if !value.placed.is_empty() {
                info!("Inserting {} offers", value.placed.len());

                for (j, offer) in value.placed.iter().enumerate() {
                    info!(
                        "Offer {}: domain={}, address={}, value={}",
                        j, offer.domain_name, offer.address, offer.value
                    );
                }
                match diesel::insert_into(offer_placed::table)
                    .values(&value.placed)
                    .execute(conn)
                    .await
                {
                    Ok(count) => {
                        info!("Successfully inserted {} offers", count);
                        changes += count;
                    }
                    Err(e) => {
                        error!("Failed to insert offers: {}", e);
                        return Err(e.into());
                    }
                }
            }

            if !value.cancelled.is_empty() {
                info!("Inserting {} cancellations", value.cancelled.len());
                for (j, cancellation) in value.cancelled.iter().enumerate() {
                    info!(
                        "Cancellation {}: domain={}, address={}, value={}",
                        j, cancellation.domain_name, cancellation.address, cancellation.value
                    );
                }
                match diesel::insert_into(offer_cancelled::table)
                    .values(&value.cancelled)
                    .execute(conn)
                    .await
                {
                    Ok(count) => {
                        info!("Successfully inserted {} cancellations", count);
                        changes += count;
                    }
                    Err(e) => {
                        error!("Failed to insert cancellations: {}", e);
                        return Err(e.into());
                    }
                }
            }

            if !value.accepted.is_empty() {
                info!("Inserting {} accepted", value.accepted.len());
                for (j, accepted) in value.accepted.iter().enumerate() {
                    info!(
                        "Accepted {}: domain={}, owner={}, address={}, value={}",
                        j, accepted.domain_name, accepted.address, accepted.owner, accepted.value
                    );
                }
                match diesel::insert_into(offer_accepted::table)
                    .values(&value.accepted)
                    .execute(conn)
                    .await
                {
                    Ok(count) => {
                        info!("Successfully inserted {} accepted", count);
                        changes += count;
                    }
                    Err(e) => {
                        error!("Failed to insert accepted: {}", e);
                        return Err(e.into());
                    }
                }
            }

            if !value.declined.is_empty() {
                info!("Inserting {} declined", value.declined.len());
                for (j, declined) in value.declined.iter().enumerate() {
                    info!(
                        "Declined {}: domain={}, owner={}, address={}, value={}",
                        j, declined.domain_name, declined.address, declined.owner, declined.value
                    );
                }
                match diesel::insert_into(offer_declined::table)
                    .values(&value.declined)
                    .execute(conn)
                    .await
                {
                    Ok(count) => {
                        info!("Successfully inserted {} declined", count);
                        changes += count;
                    }
                    Err(e) => {
                        error!("Failed to insert declined: {}", e);
                        return Err(e.into());
                    }
                }
            }

            if !value.make_counter_offer.is_empty() {
                info!(
                    "Inserting {} make counter offer",
                    value.make_counter_offer.len()
                );
                for (j, make_counter_offer) in value.make_counter_offer.iter().enumerate() {
                    info!(
                        "Declined {}: domain={}, owner={}, address={}, value={}",
                        j,
                        make_counter_offer.domain_name,
                        make_counter_offer.address,
                        make_counter_offer.owner,
                        make_counter_offer.value
                    );
                }
                match diesel::insert_into(make_counter_offer::table)
                    .values(&value.make_counter_offer)
                    .execute(conn)
                    .await
                {
                    Ok(count) => {
                        info!("Successfully inserted {} make counter offer", count);
                        changes += count;
                    }
                    Err(e) => {
                        error!("Failed to insert make counter offer: {}", e);
                        return Err(e.into());
                    }
                }
            }

            if !value.accept_counter_offer.is_empty() {
                info!(
                    "Inserting {} accept counter offer",
                    value.accept_counter_offer.len()
                );
                for (j, accept_counter_offer) in value.accept_counter_offer.iter().enumerate() {
                    info!(
                        "Declined {}: domain={}, address={}, value={}",
                        j,
                        accept_counter_offer.domain_name,
                        accept_counter_offer.address,
                        accept_counter_offer.value
                    );
                }
                match diesel::insert_into(accept_counter_offer::table)
                    .values(&value.accept_counter_offer)
                    .execute(conn)
                    .await
                {
                    Ok(count) => {
                        info!("Successfully inserted {} accept counter offer", count);
                        changes += count;
                    }
                    Err(e) => {
                        error!("Failed to insert accept counter offer: {}", e);
                        return Err(e.into());
                    }
                }
            }

            if !value.set_seal_config.is_empty() {
                info!("Inserting {} set seal config", value.set_seal_config.len());
                for (j, config) in value.set_seal_config.iter().enumerate() {
                    info!(
                        "SetSealConfig {}: key_servers count={}, threshold={}",
                        j,
                        config.key_servers.len(),
                        config.threshold
                    );
                }
                match diesel::insert_into(set_seal_config::table)
                    .values(&value.set_seal_config)
                    .execute(conn)
                    .await
                {
                    Ok(count) => {
                        info!("Successfully inserted {} set seal config", count);
                        changes += count;
                    }
                    Err(e) => {
                        error!("Failed to insert set seal config: {}", e);
                        return Err(e.into());
                    }
                }
            }

            if !value.set_service_fee.is_empty() {
                info!("Inserting {} set service fee", value.set_service_fee.len());
                for (j, fee) in value.set_service_fee.iter().enumerate() {
                    info!(
                        "SetServiceFee {}: service_fee={}",
                        j,
                        fee.service_fee
                    );
                }
                match diesel::insert_into(set_service_fee::table)
                    .values(&value.set_service_fee)
                    .execute(conn)
                    .await
                {
                    Ok(count) => {
                        info!("Successfully inserted {} set service fee", count);
                        changes += count;
                    }
                    Err(e) => {
                        error!("Failed to insert set service fee: {}", e);
                        return Err(e.into());
                    }
                }
            }
        }

        Ok(changes)
    }
}

impl OfferEventsHandlerPipeline {
    pub fn new(auction_contract_id: SuiAddress) -> Self {
        Self {
            contract_package_id: auction_contract_id.to_string(),
        }
    }

    fn process_event(
        &self,
        event: &Event,
        tx_digest: &str,
        created_at: DateTime<Utc>,
    ) -> Result<Option<OfferEventModel>> {
        let event_type = event.type_.to_string();
        if event_type.starts_with(&self.contract_package_id) {
            if event_type.ends_with("::OfferPlacedEvent") {
                let offer_event: OfferPlacedEvent = try_deserialize_event(&event.contents)?;

                let offer = OfferPlaced {
                    domain_name: convert_domain_name(&offer_event.domain_name),
                    address: offer_event.address.to_string(),
                    value: offer_event.value.to_string(),
                    created_at,
                    tx_digest: tx_digest.to_string(),
                    token: offer_event.token.to_string(),
                };

                return Ok(Some(OfferEventModel::Placed(offer)));
            } else if event_type.ends_with("::OfferCancelledEvent") {
                let cancel_event: OfferCancelledEvent = try_deserialize_event(&event.contents)?;

                let cancellation = OfferCancelled {
                    domain_name: convert_domain_name(&cancel_event.domain_name),
                    address: cancel_event.address.to_string(),
                    value: cancel_event.value.to_string(),
                    created_at,
                    tx_digest: tx_digest.to_string(),
                    token: cancel_event.token.to_string(),
                };

                return Ok(Some(OfferEventModel::Cancelled(cancellation)));
            } else if event_type.ends_with("::OfferAcceptedEvent") {
                let accepted_event: OfferAcceptedEvent = try_deserialize_event(&event.contents)?;

                let accepted = OfferAccepted {
                    domain_name: convert_domain_name(&accepted_event.domain_name),
                    address: accepted_event.buyer.to_string(),
                    owner: accepted_event.owner.to_string(),
                    value: accepted_event.value.to_string(),
                    created_at,
                    tx_digest: tx_digest.to_string(),
                    token: accepted_event.token.to_string(),
                };

                return Ok(Some(OfferEventModel::Accepted(accepted)));
            } else if event_type.ends_with("::OfferDeclinedEvent") {
                let declined_event: OfferDeclinedEvent = try_deserialize_event(&event.contents)?;

                let decline = OfferDeclined {
                    domain_name: convert_domain_name(&declined_event.domain_name),
                    address: declined_event.buyer.to_string(),
                    owner: declined_event.owner.to_string(),
                    value: declined_event.value.to_string(),
                    created_at,
                    tx_digest: tx_digest.to_string(),
                    token: declined_event.token.to_string(),
                };

                return Ok(Some(OfferEventModel::Declined(decline)));
            } else if event_type.ends_with("::MakeCounterOfferEvent") {
                let make_counter_offer_event: MakeCounterOfferEvent =
                    try_deserialize_event(&event.contents)?;

                let make_counter_offer = MakeCounterOffer {
                    domain_name: convert_domain_name(&make_counter_offer_event.domain_name),
                    address: make_counter_offer_event.buyer.to_string(),
                    owner: make_counter_offer_event.owner.to_string(),
                    value: make_counter_offer_event.value.to_string(),
                    created_at,
                    tx_digest: tx_digest.to_string(),
                    token: make_counter_offer_event.token.to_string(),
                };

                return Ok(Some(OfferEventModel::MakeCounterOffer(make_counter_offer)));
            } else if event_type.ends_with("::AcceptCounterOfferEvent") {
                let accept_counter_offer_event: AcceptCounterOfferEvent =
                    try_deserialize_event(&event.contents)?;

                let accept_counter_offer = AcceptCounterOffer {
                    domain_name: convert_domain_name(&accept_counter_offer_event.domain_name),
                    address: accept_counter_offer_event.buyer.to_string(),
                    value: accept_counter_offer_event.value.to_string(),
                    created_at,
                    tx_digest: tx_digest.to_string(),
                    token: accept_counter_offer_event.token.to_string(),
                };

                return Ok(Some(OfferEventModel::AcceptCounterOffer(
                    accept_counter_offer,
                )));
            } else if event_type.ends_with("::SetSealConfig") {
                let seal_config_event: SetSealConfig = try_deserialize_event(&event.contents)?;

                let seal_config = SetSealConfigModel {
                    key_servers: seal_config_event
                        .key_servers
                        .iter()
                        .map(|addr| addr.to_string())
                        .collect(),
                    public_keys: seal_config_event.public_keys,
                    threshold: seal_config_event.threshold as i16,
                    created_at,
                    tx_digest: tx_digest.to_string(),
                };

                return Ok(Some(OfferEventModel::SetSealConfig(seal_config)));
            } else if event_type.ends_with("::SetServiceFee") {
                let service_fee_event: SetServiceFee = try_deserialize_event(&event.contents)?;

                let service_fee = SetServiceFeeModel {
                    service_fee: service_fee_event.service_fee.to_string(),
                    created_at,
                    tx_digest: tx_digest.to_string(),
                };

                return Ok(Some(OfferEventModel::SetServiceFee(service_fee)));
            }
        }

        Ok(None)
    }
}
