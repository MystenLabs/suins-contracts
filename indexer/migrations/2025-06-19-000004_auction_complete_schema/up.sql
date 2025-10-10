CREATE TABLE IF NOT EXISTS offer_placed (
    id SERIAL PRIMARY KEY,
    domain_name VARCHAR NOT NULL,
    address VARCHAR NOT NULL,
    value VARCHAR NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    tx_digest VARCHAR NOT NULL
);

CREATE TABLE IF NOT EXISTS offer_cancelled (
    id SERIAL PRIMARY KEY,
    domain_name VARCHAR NOT NULL,
    address VARCHAR NOT NULL,
    value VARCHAR NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    tx_digest VARCHAR NOT NULL
);

CREATE TABLE IF NOT EXISTS offer_accepted (
    id SERIAL PRIMARY KEY,
    domain_name VARCHAR NOT NULL,
    address VARCHAR NOT NULL,
    owner VARCHAR NOT NULL,
    value VARCHAR NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    tx_digest VARCHAR NOT NULL
);

CREATE TABLE IF NOT EXISTS offer_declined (
    id SERIAL PRIMARY KEY,
    domain_name VARCHAR NOT NULL,
    address VARCHAR NOT NULL,
    owner VARCHAR NOT NULL,
    value VARCHAR NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    tx_digest VARCHAR NOT NULL
);

CREATE TABLE IF NOT EXISTS make_counter_offer (
    id SERIAL PRIMARY KEY,
    domain_name VARCHAR NOT NULL,
    address VARCHAR NOT NULL,
    owner VARCHAR NOT NULL,
    value VARCHAR NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    tx_digest VARCHAR NOT NULL
);

CREATE TABLE IF NOT EXISTS accept_counter_offer (
    id SERIAL PRIMARY KEY,
    domain_name VARCHAR NOT NULL,
    address VARCHAR NOT NULL,
    value VARCHAR NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    tx_digest VARCHAR NOT NULL
);
