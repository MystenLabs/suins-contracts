CREATE TABLE IF NOT EXISTS set_seal_config (
    id SERIAL PRIMARY KEY,
    key_servers TEXT[] NOT NULL,
    public_keys BYTEA[] NOT NULL,
    threshold SMALLINT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    tx_digest VARCHAR NOT NULL
);
