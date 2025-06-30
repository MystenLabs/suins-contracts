use anyhow::Context;
use clap::Parser;
use move_core_types::language_storage::StructTag;
use prometheus::Registry;
use std::net::SocketAddr;
use sui_indexer_alt_framework::ingestion::ClientArgs;
use sui_indexer_alt_framework::{Indexer, IndexerArgs};
use sui_indexer_alt_metrics::db::DbConnectionStatsCollector;
use sui_indexer_alt_metrics::{MetricsArgs, MetricsService};
use sui_pg_db::{Db, DbArgs};
use sui_types::base_types::SuiAddress;
use suins_indexer::handlers::domain_handler::DomainHandler;
use suins_indexer::MAINNET_REMOTE_STORE_URL;
use suins_indexer::MIGRATIONS;
use tokio_util::sync::CancellationToken;
use url::Url;

#[derive(Parser)]
#[clap(rename_all = "kebab-case", author, version)]
struct Args {
    #[command(flatten)]
    db_args: DbArgs,
    #[command(flatten)]
    indexer_args: IndexerArgs,
    #[clap(env, long, default_value = "0.0.0.0:9184")]
    metrics_address: SocketAddr,
    #[clap(
        env,
        long,
        default_value = "postgres://postgres:postgrespw@localhost:5432/suins"
    )]
    database_url: Url,
    /// Checkpoint remote store URL, defaulted to Sui mainnet remote store.
    #[clap(env, long, default_value = MAINNET_REMOTE_STORE_URL)]
    remote_store_url: Url,

    /// Optional registry table id override, defaulted to Sui mainnet name service registry table id.
    #[clap(env, long)]
    registry_id: Option<SuiAddress>,

    /// Optional subdomain wrapper type override, defaulted to Sui mainnet subdomain wrapper type.
    #[clap(env, long)]
    subdomain_wrapper_type: Option<StructTag>,

    /// Optional name record type override, defaulted to Sui mainnet name name record type.
    #[clap(env, long)]
    name_record_type: Option<StructTag>,
}

#[tokio::main]
async fn main() -> Result<(), anyhow::Error> {
    let _guard = telemetry_subscribers::TelemetryConfig::new()
        .with_env()
        .init();

    let Args {
        db_args,
        indexer_args,
        metrics_address,
        remote_store_url,
        database_url,
        registry_id,
        subdomain_wrapper_type,
        name_record_type,
    } = Args::parse();

    let cancel = CancellationToken::new();
    let registry = Registry::new_custom(Some("suins".into()), None)
        .context("Failed to create Prometheus registry.")?;
    let metrics = MetricsService::new(
        MetricsArgs { metrics_address },
        registry.clone(),
        cancel.child_token(),
    );

    // Prepare the store for the indexer
    let store = Db::for_write(database_url, db_args)
        .await
        .context("Failed to connect to database")?;

    store
        .run_migrations(Some(&MIGRATIONS))
        .await
        .context("Failed to run pending migrations")?;

    registry.register(Box::new(DbConnectionStatsCollector::new(
        Some("suins_indexer_db"),
        store.clone(),
    )))?;

    let mut indexer = Indexer::new(
        store,
        indexer_args,
        ClientArgs {
            remote_store_url: Some(remote_store_url),
            local_ingestion_path: None,
            rpc_api_url: None,
            rpc_username: None,
            rpc_password: None,
        },
        Default::default(),
        metrics.registry(),
        cancel.clone(),
    )
    .await?;

    let handler = if let (Some(registry_id), Some(subdomain_wrapper_type), Some(name_record_type)) =
        (registry_id, subdomain_wrapper_type, name_record_type)
    {
        DomainHandler::new(registry_id, subdomain_wrapper_type, name_record_type)
    } else {
        DomainHandler::default()
    };

    indexer
        .concurrent_pipeline(handler, Default::default())
        .await?;

    let h_indexer = indexer.run().await?;
    let h_metrics = metrics.run().await?;

    let _ = h_indexer.await;
    cancel.cancel();
    let _ = h_metrics.await;

    Ok(())
}
