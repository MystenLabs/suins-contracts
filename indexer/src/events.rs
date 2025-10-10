use log::error;
use serde::Deserialize;

#[derive(serde::Deserialize, Debug, Clone)]
pub struct OfferPlacedEvent {
    pub domain_name: Vec<u8>,
    pub address: sui_types::base_types::SuiAddress,
    pub value: u64,
}

#[derive(serde::Deserialize, Debug, Clone)]
pub struct OfferCancelledEvent {
    pub domain_name: Vec<u8>,
    pub address: sui_types::base_types::SuiAddress,
    pub value: u64,
}

#[derive(serde::Deserialize, Debug, Clone)]
pub struct OfferAcceptedEvent {
    pub domain_name: Vec<u8>,
    pub owner: sui_types::base_types::SuiAddress,
    pub buyer: sui_types::base_types::SuiAddress,
    pub value: u64,
}

#[derive(serde::Deserialize, Debug, Clone)]
pub struct OfferDeclinedEvent {
    pub domain_name: Vec<u8>,
    pub owner: sui_types::base_types::SuiAddress,
    pub buyer: sui_types::base_types::SuiAddress,
    pub value: u64,
}

// owner can create a counter offer
#[derive(serde::Deserialize, Debug, Clone)]
pub struct MakeCounterOfferEvent {
    pub domain_name: Vec<u8>,
    pub owner: sui_types::base_types::SuiAddress,
    pub buyer: sui_types::base_types::SuiAddress,
    pub value: u64,
}

// buyer can accept counter offer
#[derive(serde::Deserialize, Debug, Clone)]
pub struct AcceptCounterOfferEvent {
    pub domain_name: Vec<u8>,
    pub buyer: sui_types::base_types::SuiAddress,
    pub value: u64,
}

#[derive(serde::Deserialize, Debug, Clone)]
pub struct AuctionCreatedEvent {
    pub auction_id: sui_types::base_types::ObjectID,
    pub domain_name: Vec<u8>,
    pub owner: sui_types::base_types::SuiAddress,
    pub start_time: u64,
    pub end_time: u64,
    pub min_bid: u64,
}

#[derive(serde::Deserialize, Debug, Clone)]
pub struct BidPlacedEvent {
    pub auction_id: sui_types::base_types::ObjectID,
    pub domain_name: Vec<u8>,
    pub bidder: sui_types::base_types::SuiAddress,
    pub amount: u64,
}

#[derive(serde::Deserialize, Debug, Clone)]
pub struct AuctionFinalizedEvent {
    pub auction_id: sui_types::base_types::ObjectID,
    pub domain_name: Vec<u8>,
    pub winner: sui_types::base_types::SuiAddress,
    pub amount: u64,
}

#[derive(serde::Deserialize, Debug, Clone)]
pub struct AuctionCancelledEvent {
    pub auction_id: sui_types::base_types::ObjectID,
    pub domain_name: Vec<u8>,
    pub owner: sui_types::base_types::SuiAddress,
}

pub fn try_deserialize_event<T: for<'a> Deserialize<'a>>(
    contents: &[u8],
) -> anyhow::Result<T, anyhow::Error> {
    match bcs::from_bytes::<T>(contents) {
        Ok(event) => Ok(event),
        Err(e) => {
            error!(
                    "Failed to deserialize: {}. Event contents: {:?}",
                    e, contents
                );
            Err(e.into())
        }
    }
}

pub fn convert_domain_name(domain_name: &[u8]) -> String {
    String::from_utf8_lossy(domain_name).to_string()
}