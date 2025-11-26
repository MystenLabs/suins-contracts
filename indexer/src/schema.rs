// @generated automatically by Diesel CLI.

pub mod sql_types {
    #[derive(diesel::query_builder::QueryId, diesel::sql_types::SqlType)]
    #[diesel(postgres_type(name = "auctionstatus"))]
    pub struct Auctionstatus;

    #[derive(diesel::query_builder::QueryId, diesel::sql_types::SqlType)]
    #[diesel(postgres_type(name = "listingstatus"))]
    pub struct Listingstatus;

    #[derive(diesel::query_builder::QueryId, diesel::sql_types::SqlType)]
    #[diesel(postgres_type(name = "offerstatus"))]
    pub struct Offerstatus;
}

diesel::table! {
    accept_counter_offer (id) {
        id -> Int4,
        domain_name -> Varchar,
        address -> Varchar,
        value -> Varchar,
        created_at -> Timestamptz,
        tx_digest -> Varchar,
        token -> Varchar,
    }
}

diesel::table! {
    use diesel::sql_types::*;
    use super::sql_types::Auctionstatus;

    auctions (auction_id) {
        auction_id -> Varchar,
        domain_name -> Varchar,
        owner -> Varchar,
        start_time -> Int8,
        end_time -> Int8,
        min_bid -> Varchar,
        winner -> Nullable<Varchar>,
        amount -> Nullable<Varchar>,
        status -> Auctionstatus,
        updated_at -> Timestamptz,
        created_at -> Timestamptz,
        last_tx_digest -> Varchar,
        token -> Varchar,
        reserve_price_encrypted -> Nullable<Bytea>,
        reserve_price -> Nullable<Int8>,
    }
}

diesel::table! {
    bids (id) {
        id -> Int4,
        auction_id -> Varchar,
        domain_name -> Varchar,
        bidder -> Varchar,
        amount -> Varchar,
        created_at -> Timestamptz,
        tx_digest -> Varchar,
        token -> Varchar,
    }
}

diesel::table! {
    domains (name) {
        name -> Varchar,
        parent -> Varchar,
        expiration_timestamp_ms -> Int8,
        nft_id -> Varchar,
        field_id -> Varchar,
        target_address -> Nullable<Varchar>,
        data -> Json,
        last_checkpoint_updated -> Int8,
        subdomain_wrapper_id -> Nullable<Varchar>,
    }
}

diesel::table! {
    use diesel::sql_types::*;
    use super::sql_types::Listingstatus;

    listings (listing_id) {
        listing_id -> Varchar,
        domain_name -> Varchar,
        owner -> Varchar,
        price -> Varchar,
        buyer -> Nullable<Varchar>,
        status -> Listingstatus,
        updated_at -> Timestamptz,
        created_at -> Timestamptz,
        last_tx_digest -> Varchar,
        token -> Varchar,
        expires_at -> Nullable<Int8>,
    }
}

diesel::table! {
    make_counter_offer (id) {
        id -> Int4,
        domain_name -> Varchar,
        address -> Varchar,
        owner -> Varchar,
        value -> Varchar,
        created_at -> Timestamptz,
        tx_digest -> Varchar,
        token -> Varchar,
    }
}

diesel::table! {
    offer_accepted (id) {
        id -> Int4,
        domain_name -> Varchar,
        address -> Varchar,
        owner -> Varchar,
        value -> Varchar,
        created_at -> Timestamptz,
        tx_digest -> Varchar,
        token -> Varchar,
    }
}

diesel::table! {
    offer_cancelled (id) {
        id -> Int4,
        domain_name -> Varchar,
        address -> Varchar,
        value -> Varchar,
        created_at -> Timestamptz,
        tx_digest -> Varchar,
        token -> Varchar,
    }
}

diesel::table! {
    offer_declined (id) {
        id -> Int4,
        domain_name -> Varchar,
        address -> Varchar,
        owner -> Varchar,
        value -> Varchar,
        created_at -> Timestamptz,
        tx_digest -> Varchar,
        token -> Varchar,
    }
}

diesel::table! {
    offer_placed (id) {
        id -> Int4,
        domain_name -> Varchar,
        address -> Varchar,
        value -> Varchar,
        created_at -> Timestamptz,
        tx_digest -> Varchar,
        token -> Varchar,
    }
}

diesel::table! {
    use diesel::sql_types::*;
    use super::sql_types::Offerstatus;

    offers (id) {
        id -> Int4,
        domain_name -> Varchar,
        buyer -> Varchar,
        initial_value -> Varchar,
        value -> Varchar,
        owner -> Nullable<Varchar>,
        status -> Offerstatus,
        updated_at -> Timestamptz,
        created_at -> Timestamptz,
        last_tx_digest -> Varchar,
        token -> Varchar,
        expires_at -> Nullable<Int8>,
    }
}

diesel::table! {
    set_seal_config (id) {
        id -> Int4,
        key_servers -> Array<Nullable<Text>>,
        public_keys -> Array<Nullable<Bytea>>,
        threshold -> Int2,
        created_at -> Timestamptz,
        tx_digest -> Varchar,
    }
}

diesel::table! {
    set_service_fee (id) {
        id -> Int4,
        service_fee -> Varchar,
        created_at -> Timestamptz,
        tx_digest -> Varchar,
    }
}

diesel::table! {
    watermarks (pipeline) {
        pipeline -> Text,
        epoch_hi_inclusive -> Int8,
        checkpoint_hi_inclusive -> Int8,
        tx_hi -> Int8,
        timestamp_ms_hi_inclusive -> Int8,
        reader_lo -> Int8,
        pruner_timestamp -> Timestamp,
        pruner_hi -> Int8,
    }
}

diesel::joinable!(bids -> auctions (auction_id));

diesel::allow_tables_to_appear_in_same_query!(
    accept_counter_offer,
    auctions,
    bids,
    domains,
    listings,
    make_counter_offer,
    offer_accepted,
    offer_cancelled,
    offer_declined,
    offer_placed,
    offers,
    set_seal_config,
    set_service_fee,
    watermarks,
);
