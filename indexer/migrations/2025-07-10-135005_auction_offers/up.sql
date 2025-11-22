CREATE TYPE OfferStatus AS ENUM (
    'placed',
    'cancelled',
    'accepted',
    'declined',
    'countered',
    'accepted-countered'
);

CREATE TABLE IF NOT EXISTS offers (
    id SERIAL PRIMARY KEY,
    domain_name VARCHAR NOT NULL,
    buyer VARCHAR NOT NULL,
    initial_value VARCHAR NOT NULL,
    value VARCHAR NOT NULL,
    owner VARCHAR,
    status OfferStatus NOT NULL DEFAULT 'placed',
    updated_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    last_tx_digest VARCHAR NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_offers_domain_name ON offers(domain_name);
CREATE INDEX IF NOT EXISTS idx_offers_buyer ON offers(buyer);
CREATE INDEX IF NOT EXISTS idx_offers_status ON offers(status);
