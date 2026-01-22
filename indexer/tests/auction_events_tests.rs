use chrono::NaiveDateTime;
use fastcrypto::hash::{HashFunction, Sha256};
use insta::assert_json_snapshot;
use serde_json::Value;
use sqlx::{Column, PgPool, Row, ValueRef};
use std::fs;
use std::path::Path;
use std::str::FromStr;
use std::sync::Arc;
use sui_indexer_alt_framework::pipeline::sequential::Handler;
use sui_indexer_alt_framework::pipeline::Processor;
use sui_pg_db::Db;
use sui_pg_db::DbArgs;
use sui_storage::blob::Blob;
use sui_types::base_types::SuiAddress;
use sui_types::full_checkpoint_content::Checkpoint;
use sui_types::full_checkpoint_content::CheckpointData;
use suins_indexer::handlers::auctions_handler::AuctionsHandlerPipeline;
use suins_indexer::handlers::listings_handler::ListingsHandlerPipeline;
use suins_indexer::MIGRATIONS;
use testcontainers::runners::AsyncRunner;
use testcontainers_modules::postgres::Postgres;
use url::Url;

/// Contract package ID for the auction contract on testnet (original-published-id).
/// Events are emitted with this package ID.
const TEST_AUCTION_CONTRACT_ID: &str =
    "0xd421a8ebd93c4f93a4020e733b98108db3498be90a0d62ffed1ef926434aa569";

// ============================================================================
// LISTINGS HANDLER TESTS
// ============================================================================

/// Checkpoint 285250134: Contains a ListingCreatedEvent
/// Domain: 0555def.sui listed for 300000000 MIST
#[tokio::test]
async fn process_285250134_listing_created() -> Result<(), anyhow::Error> {
    let handler = get_listings_handler();
    data_test("process_285250134_checkpoint", handler, ["listings"]).await
}

/// Checkpoint 285250163: Contains a ListingCancelledEvent
/// Domain: 0555def.sui listing cancelled
#[tokio::test]
async fn process_285250163_listing_cancelled() -> Result<(), anyhow::Error> {
    // Need to process listing created first, then cancelled
    let handler = get_listings_handler();
    data_test_multi(
        "process_285250163_listing_cancelled",
        handler,
        ["listings"],
        &["process_285250134_checkpoint", "process_285250163_checkpoint"],
    )
    .await
}

// ============================================================================
// AUCTIONS HANDLER TESTS
// ============================================================================

/// Checkpoint 284204878: Contains SetSealConfig event
/// Sets up the SEAL encryption configuration for auctions
#[tokio::test]
async fn process_284204878_set_seal_config() -> Result<(), anyhow::Error> {
    let handler = get_auctions_handler();
    data_test_auctions("process_284204878_checkpoint", handler, ["set_seal_config"]).await
}

/// Checkpoint 284214191: Contains AuctionCreatedEvent
/// Creates a new auction for a domain
#[tokio::test]
async fn process_284214191_auction_created() -> Result<(), anyhow::Error> {
    let handler = get_auctions_handler();
    data_test_auctions("process_284214191_checkpoint", handler, ["auctions"]).await
}

/// Checkpoint 284221705: Contains BidPlacedEvent
/// Places a bid on auction 0x580d...91df for domain nopass01.sui
/// Requires auction creation from checkpoint 284221405
#[tokio::test]
async fn process_284221705_bid_placed() -> Result<(), anyhow::Error> {
    // Need to process auction created first (checkpoint 284221405), then bid (284221705)
    let handler = get_auctions_handler();
    data_test_auctions_multi(
        "process_284221705_bid_placed",
        handler,
        ["auctions", "bids"],
        &["process_284221405_checkpoint", "process_284221705_checkpoint"],
    )
    .await
}

/// Checkpoint 284219783: Contains AuctionCancelledEvent
/// Cancels an existing auction
#[tokio::test]
async fn process_284219783_auction_cancelled() -> Result<(), anyhow::Error> {
    // Need to process auction created first, then cancelled
    let handler = get_auctions_handler();
    data_test_auctions_multi(
        "process_284219783_auction_cancelled",
        handler,
        ["auctions"],
        &["process_284214191_checkpoint", "process_284219783_checkpoint"],
    )
    .await
}

/// Checkpoint 284306978: Contains AuctionFinalizedEvent
/// Finalizes an auction with a winner
#[tokio::test]
async fn process_284306978_auction_finalized() -> Result<(), anyhow::Error> {
    // Need to process auction created first, then finalized
    let handler = get_auctions_handler();
    data_test_auctions_multi(
        "process_284306978_auction_finalized",
        handler,
        ["auctions"],
        &["process_284214191_checkpoint", "process_284306978_checkpoint"],
    )
    .await
}

// ============================================================================
// HANDLER FACTORIES
// ============================================================================

fn get_listings_handler() -> ListingsHandlerPipeline {
    let contract_id = SuiAddress::from_str(TEST_AUCTION_CONTRACT_ID).unwrap();
    ListingsHandlerPipeline::new(contract_id)
}

fn get_auctions_handler() -> AuctionsHandlerPipeline {
    let contract_id = SuiAddress::from_str(TEST_AUCTION_CONTRACT_ID).unwrap();
    AuctionsHandlerPipeline::new(contract_id)
}

// ============================================================================
// TEST INFRASTRUCTURE
// ============================================================================

/// Run a listings handler data test with a single checkpoint directory
async fn data_test(
    test_name: &str,
    handler: ListingsHandlerPipeline,
    tables_to_check: impl IntoIterator<Item = &'static str>,
) -> Result<(), anyhow::Error> {
    data_test_listings_multi(test_name, handler, tables_to_check, &[test_name]).await
}

/// Run a listings handler data test with multiple checkpoint directories
async fn data_test_multi(
    test_name: &str,
    handler: ListingsHandlerPipeline,
    tables_to_check: impl IntoIterator<Item = &'static str>,
    checkpoint_dirs: &[&str],
) -> Result<(), anyhow::Error> {
    data_test_listings_multi(test_name, handler, tables_to_check, checkpoint_dirs).await
}

/// Run a listings handler data test with multiple checkpoint directories
async fn data_test_listings_multi(
    test_name: &str,
    handler: ListingsHandlerPipeline,
    tables_to_check: impl IntoIterator<Item = &'static str>,
    checkpoint_dirs: &[&str],
) -> Result<(), anyhow::Error> {
    // Start PostgreSQL container
    let container = Postgres::default().start().await?;
    let port = container.get_host_port_ipv4(5432).await?;

    let database_url = format!("postgres://postgres:postgres@localhost:{}/postgres", port);

    // Set up database connection and run migrations
    let url = Url::parse(&database_url)?;
    let db = Arc::new(Db::for_write(url, DbArgs::default()).await?);
    db.run_migrations(Some(&MIGRATIONS)).await?;
    let mut conn = db.connect().await?;

    // Process all checkpoint directories in order
    for checkpoint_dir in checkpoint_dirs {
        let test_path = Path::new("tests/checkpoints").join(checkpoint_dir);
        let checkpoints = get_checkpoints_in_folder(&test_path)?;

        for checkpoint_path in checkpoints {
            let bytes = fs::read(&checkpoint_path)?;
            let data = Blob::from_bytes::<CheckpointData>(&bytes)?;
            let cp: Checkpoint = data.into();
            let result = handler.process(&Arc::new(cp)).await?;

            let mut batch = Vec::new();
            handler.batch(&mut batch, result.into_iter());
            handler.commit(&batch, &mut conn).await?;
        }
    }

    // Check results by comparing database tables with snapshots
    for table in tables_to_check {
        let rows = read_table(table, &database_url, get_order_statement(table)).await?;
        assert_json_snapshot!(format!("{test_name}__{table}"), rows);
    }
    Ok(())
}

/// Run an auctions handler data test with a single checkpoint directory
async fn data_test_auctions(
    test_name: &str,
    handler: AuctionsHandlerPipeline,
    tables_to_check: impl IntoIterator<Item = &'static str>,
) -> Result<(), anyhow::Error> {
    data_test_auctions_multi(test_name, handler, tables_to_check, &[test_name]).await
}

/// Run an auctions handler data test with multiple checkpoint directories
async fn data_test_auctions_multi(
    test_name: &str,
    handler: AuctionsHandlerPipeline,
    tables_to_check: impl IntoIterator<Item = &'static str>,
    checkpoint_dirs: &[&str],
) -> Result<(), anyhow::Error> {
    // Start PostgreSQL container
    let container = Postgres::default().start().await?;
    let port = container.get_host_port_ipv4(5432).await?;

    let database_url = format!("postgres://postgres:postgres@localhost:{}/postgres", port);

    // Set up database connection and run migrations
    let url = Url::parse(&database_url)?;
    let db = Arc::new(Db::for_write(url, DbArgs::default()).await?);
    db.run_migrations(Some(&MIGRATIONS)).await?;
    let mut conn = db.connect().await?;

    // Process all checkpoint directories in order
    for checkpoint_dir in checkpoint_dirs {
        let test_path = Path::new("tests/checkpoints").join(checkpoint_dir);
        let checkpoints = get_checkpoints_in_folder(&test_path)?;

        for checkpoint_path in checkpoints {
            let bytes = fs::read(&checkpoint_path)?;
            let data = Blob::from_bytes::<CheckpointData>(&bytes)?;
            let cp: Checkpoint = data.into();
            let result = handler.process(&Arc::new(cp)).await?;

            let mut batch = Vec::new();
            handler.batch(&mut batch, result.into_iter());
            handler.commit(&batch, &mut conn).await?;
        }
    }

    // Check results by comparing database tables with snapshots
    for table in tables_to_check {
        let rows = read_table(table, &database_url, get_order_statement(table)).await?;
        assert_json_snapshot!(format!("{test_name}__{table}"), rows);
    }
    Ok(())
}

fn get_order_statement(table: &str) -> Option<&'static str> {
    match table {
        "listings" => Some("ORDER BY listing_id ASC"),
        "auctions" => Some("ORDER BY auction_id ASC"),
        "bids" => Some("ORDER BY id ASC"),
        "set_seal_config" => Some("ORDER BY id ASC"),
        "set_service_fee" => Some("ORDER BY id ASC"),
        _ => None,
    }
}

/// Read the entire table from database as json value.
/// note: bytea values will be hashed to reduce output size.
async fn read_table(
    table_name: &str,
    db_url: &str,
    order_statement: Option<&str>,
) -> Result<Vec<Value>, anyhow::Error> {
    let pool = PgPool::connect(db_url).await?;

    // Get column info to identify enum columns
    let columns_query = format!(
        "SELECT column_name, data_type, udt_name FROM information_schema.columns WHERE table_name = '{table_name}'"
    );
    let column_info: Vec<(String, String, String)> = sqlx::query_as(&columns_query)
        .fetch_all(&pool)
        .await?;

    // Build SELECT with enum and timestamp columns cast to text
    let select_columns: Vec<String> = column_info
        .iter()
        .map(|(col_name, data_type, _)| {
            if data_type == "USER-DEFINED"
                || data_type == "timestamp with time zone"
                || data_type == "timestamp without time zone"
            {
                format!("{col_name}::text as {col_name}")
            } else {
                col_name.clone()
            }
        })
        .collect();

    let query = format!(
        "SELECT {} FROM {table_name} {}",
        select_columns.join(", "),
        order_statement.unwrap_or("")
    );

    let rows = sqlx::query(&query).fetch_all(&pool).await?;

    // To json
    Ok(rows
        .iter()
        .map(|row| {
            let mut obj = serde_json::Map::new();

            for column in row.columns() {
                let column_name = column.name();

                let value = if let Ok(v) = row.try_get::<String, _>(column_name) {
                    Value::String(v)
                } else if let Ok(v) = row.try_get::<i32, _>(column_name) {
                    Value::String(v.to_string())
                } else if let Ok(v) = row.try_get::<i64, _>(column_name) {
                    Value::String(v.to_string())
                } else if let Ok(v) = row.try_get::<i16, _>(column_name) {
                    Value::String(v.to_string())
                } else if let Ok(v) = row.try_get::<bool, _>(column_name) {
                    Value::Bool(v)
                } else if let Ok(v) = row.try_get::<Value, _>(column_name) {
                    v
                } else if let Ok(v) = row.try_get::<Vec<u8>, _>(column_name) {
                    // hash bytea contents
                    let mut hash_function = Sha256::default();
                    hash_function.update(v);
                    let digest2 = hash_function.finalize();
                    Value::String(digest2.to_string())
                } else if let Ok(v) = row.try_get::<Vec<Option<String>>, _>(column_name) {
                    // Handle TEXT[] arrays
                    Value::Array(v.into_iter().map(|s| s.map(Value::String).unwrap_or(Value::Null)).collect())
                } else if let Ok(v) = row.try_get::<Vec<Option<Vec<u8>>>, _>(column_name) {
                    // Handle BYTEA[] arrays - hash each element
                    Value::Array(v.into_iter().map(|bytes| {
                        bytes.map(|b| {
                            let mut hash_function = Sha256::default();
                            hash_function.update(b);
                            Value::String(hash_function.finalize().to_string())
                        }).unwrap_or(Value::Null)
                    }).collect())
                } else if let Ok(v) = row.try_get::<NaiveDateTime, _>(column_name) {
                    Value::String(v.to_string())
                } else if let Ok(true) = row.try_get_raw(column_name).map(|v| v.is_null()) {
                    Value::Null
                } else {
                    panic!(
                        "Cannot parse DB value to json, type: {:?}, column: {column_name}",
                        row.try_get_raw(column_name)
                            .map(|v| v.type_info().to_string())
                    )
                };
                obj.insert(column_name.to_string(), value);
            }

            Value::Object(obj)
        })
        .collect())
}

fn get_checkpoints_in_folder(folder: &Path) -> Result<Vec<String>, anyhow::Error> {
    let mut files = Vec::new();

    // Read the directory
    for entry in fs::read_dir(folder)? {
        let entry = entry?;
        let path = entry.path();

        // Check if it's a file and ends with ".chk"
        if path.is_file() && path.extension().and_then(|s| s.to_str()) == Some("chk") {
            files.push(path.display().to_string());
        }
    }

    // Sort to ensure consistent ordering
    files.sort();
    Ok(files)
}
