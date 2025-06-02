use diesel_migrations::{embed_migrations, EmbeddedMigrations};

pub mod handlers;

mod models;
mod schema;

pub const MIGRATIONS: EmbeddedMigrations = embed_migrations!("migrations");

pub const MAINNET_REMOTE_STORE_URL: &str = "https://checkpoints.mainnet.sui.io";
