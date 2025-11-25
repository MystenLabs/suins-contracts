use move_core_types::language_storage::StructTag as MoveStructTag;
use std::str::FromStr;
use sui_sdk_types::StructTag;

pub mod domain_handler;
pub mod offer_events_handler;
pub mod offers_handler;
pub mod auctions_handler;
pub mod listings_handler;

// Convert rust sdk struct tag to move struct tag.
pub fn convert_struct_tag(tag: StructTag) -> MoveStructTag {
    MoveStructTag::from_str(&tag.to_string()).unwrap()
}
