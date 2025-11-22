use chrono::NaiveDateTime;
use fastcrypto::hash::{HashFunction, Sha256};
use insta::assert_json_snapshot;
use move_core_types::language_storage::StructTag;
use serde_json::Value;
use sqlx::{Column, PgPool, Row, ValueRef};
use std::fs;
use std::path::Path;
use std::str::FromStr;
use std::sync::Arc;
use sui_indexer_alt_framework::pipeline::concurrent::Handler;
use sui_indexer_alt_framework::pipeline::Processor;
use sui_indexer_alt_framework::store::Store;
use sui_pg_db::temp::TempDb;
use sui_pg_db::Connection;
use sui_pg_db::Db;
use sui_pg_db::DbArgs;
use sui_storage::blob::Blob;
use sui_types::base_types::SuiAddress;
use sui_types::full_checkpoint_content::CheckpointData;
use suins_indexer::handlers::domain_handler::DomainHandler;
use suins_indexer::MIGRATIONS;

const TEST_REGISTRY_TABLE_ID: &str =
    "0xb120c0d55432630fce61f7854795a3463deb6e3b443cc4ae72e1282073ff56e4";
const TEST_NAME_RECORD_TYPE: &str = "0x2::dynamic_field::Field<0x22fa05f21b1ad71442491220bb9338f7b7095fe35000ef88d5400d28523bdd93::domain::Domain,0x22fa05f21b1ad71442491220bb9338f7b7095fe35000ef88d5400d28523bdd93::name_record::NameRecord>";
const TEST_SUBDOMAIN_REGISTRATION_TYPE: &str = "0x22fa05f21b1ad71442491220bb9338f7b7095fe35000ef88d5400d28523bdd93::subdomain_registration::SubDomainRegistration";

/// For our test policy, we have a few checkpoints that contain some data additions, deletions, replacements
///
/// Checkpoint 22279187: Adds 3 different names (1 SLD, 1 leaf, 1 node). Deletes none.
/// Checkpoint 22279365: Removes 1 leaf name. Adds 1 leaf name.
/// Checkpoint 22279496: Replaces the name added on `22279365` (new.test.sui) by removing it and then adding it as a node name.
/// Checkpoint 22279944: Adds `remove.test.sui`.
/// Checkpoint 22280030: Adds `remove.test.sui` as a replacement (the previous one expired!).
///                      [This was only simulated using a dummy contract and cannot happen in realistic scenarios.]
///
///
#[tokio::test]
async fn process_22279187_checkpoint() -> Result<(), anyhow::Error> {
    let handler = get_test_handler();
    data_test("process_22279187_checkpoint", handler, ["domains"]).await?;
    Ok(())
}

#[tokio::test]
async fn process_22279365_checkpoint() -> Result<(), anyhow::Error> {
    let handler = get_test_handler();
    data_test("process_22279365_checkpoint", handler, ["domains"]).await?;
    Ok(())
}

#[tokio::test]
async fn process_22279496_checkpoint() -> Result<(), anyhow::Error> {
    let handler = get_test_handler();
    data_test("process_22279496_checkpoint", handler, ["domains"]).await?;
    Ok(())
}

#[tokio::test]
async fn process_22279944_checkpoint() -> Result<(), anyhow::Error> {
    let handler = get_test_handler();
    data_test("process_22279944_checkpoint", handler, ["domains"]).await?;
    Ok(())
}

#[tokio::test]
async fn process_22280030_checkpoint() -> Result<(), anyhow::Error> {
    let handler = get_test_handler();
    data_test("process_22280030_checkpoint", handler, ["domains"]).await?;
    Ok(())
}

fn get_test_handler() -> DomainHandler {
    let registry = SuiAddress::from_str(TEST_REGISTRY_TABLE_ID).unwrap();
    let subdomain = StructTag::from_str(TEST_SUBDOMAIN_REGISTRATION_TYPE).unwrap();
    let name_record = StructTag::from_str(TEST_NAME_RECORD_TYPE).unwrap();
    DomainHandler::new(registry, subdomain, name_record)
}

async fn data_test<H, I>(
    test_name: &str,
    handler: H,
    tables_to_check: I,
) -> Result<(), anyhow::Error>
where
    I: IntoIterator<Item = &'static str>,
    H: Handler + Processor,
    for<'a> H::Store: Store<Connection<'a> = Connection<'a>>,
{
    // Set up the temporary database
    let temp_db = TempDb::new()?;
    let url = temp_db.database().url();
    let db = Arc::new(Db::for_write(url.clone(), DbArgs::default()).await?);
    db.run_migrations(Some(&MIGRATIONS)).await?;
    let mut conn = db.connect().await?;

    // Test setup based on provided test_name
    let test_path = Path::new("tests/checkpoints").join(test_name);
    let checkpoints = get_checkpoints_in_folder(&test_path)?;

    // Run pipeline for each checkpoint
    for checkpoint in checkpoints {
        run_pipeline(&handler, &checkpoint, &mut conn).await?;
    }

    // Check results by comparing database tables with snapshots
    for table in tables_to_check {
        let rows = read_table(&table, &url.to_string(), Some("ORDER BY name ASC")).await?;
        assert_json_snapshot!(format!("{test_name}__{table}"), rows);
    }
    Ok(())
}

async fn run_pipeline<'c, T: Handler + Processor, P: AsRef<Path>>(
    handler: &T,
    path: P,
    conn: &mut Connection<'c>,
) -> Result<(), anyhow::Error>
where
    T::Store: Store<Connection<'c> = Connection<'c>>,
{
    let bytes = fs::read(path)?;
    let cp = Blob::from_bytes::<CheckpointData>(&bytes)?;
    let result = handler.process(&Arc::new(cp))?;
    T::commit(&result, conn).await?;
    Ok(())
}

/// Read the entire table from database as json value.
/// note: bytea values will be hashed to reduce output size.
async fn read_table(
    table_name: &str,
    db_url: &str,
    order_statement: Option<&str>,
) -> Result<Vec<Value>, anyhow::Error> {
    let pool = PgPool::connect(db_url).await?;
    let rows = sqlx::query(&format!(
        "SELECT * FROM {table_name} {}",
        order_statement.unwrap_or("")
    ))
    .fetch_all(&pool)
    .await?;

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

    Ok(files)
}
