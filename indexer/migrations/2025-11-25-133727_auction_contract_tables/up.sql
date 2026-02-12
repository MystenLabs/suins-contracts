-- ============================================================================
-- ENUMS
-- ============================================================================

-- Offer status enum
CREATE TYPE OfferStatus AS ENUM (
    'placed',
    'cancelled',
    'accepted',
    'declined',
    'countered',
    'accepted-countered'
);

-- Auction status enum
CREATE TYPE AuctionStatus AS ENUM (
    'created',
    'cancelled',
    'finalized'
);

-- Listing status enum
CREATE TYPE ListingStatus AS ENUM (
    'created',
    'bought',
    'cancelled'
);

-- ============================================================================
-- OFFERS TABLE (Current State)
-- ============================================================================

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
    last_tx_digest VARCHAR NOT NULL,
    token VARCHAR NOT NULL,
    expires_at BIGINT
);

-- Indexes for offers table
CREATE INDEX IF NOT EXISTS idx_offers_domain_name ON offers(domain_name);
CREATE INDEX IF NOT EXISTS idx_offers_buyer ON offers(buyer);
CREATE INDEX IF NOT EXISTS idx_offers_status ON offers(status);

-- ============================================================================
-- AUCTION TABLES
-- ============================================================================

-- Auctions table
CREATE TABLE IF NOT EXISTS auctions (
    auction_id VARCHAR NOT NULL PRIMARY KEY,
    domain_name VARCHAR NOT NULL,
    owner VARCHAR NOT NULL,
    start_time BIGINT NOT NULL,
    end_time BIGINT NOT NULL,
    min_bid VARCHAR NOT NULL,
    winner VARCHAR,
    amount VARCHAR,
    status AuctionStatus NOT NULL DEFAULT 'created',
    updated_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    last_tx_digest VARCHAR NOT NULL,
    token VARCHAR NOT NULL,
    reserve_price_encrypted BYTEA,
    reserve_price BIGINT
);

-- Indexes for auctions table
CREATE INDEX IF NOT EXISTS idx_auctions_domain_name ON auctions(domain_name);
CREATE INDEX IF NOT EXISTS idx_auctions_owner ON auctions(owner);
CREATE INDEX IF NOT EXISTS idx_auctions_status ON auctions(status);

-- Bids table
CREATE TABLE IF NOT EXISTS bids (
    id SERIAL PRIMARY KEY,
    auction_id VARCHAR NOT NULL REFERENCES auctions(auction_id),
    domain_name VARCHAR NOT NULL,
    bidder VARCHAR NOT NULL,
    amount VARCHAR NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    tx_digest VARCHAR NOT NULL,
    token VARCHAR NOT NULL
);

-- Indexes for bids table
CREATE INDEX IF NOT EXISTS idx_bids_domain_name ON bids(domain_name);
CREATE INDEX IF NOT EXISTS idx_bids_bidder ON bids(bidder);

-- ============================================================================
-- LISTING TABLES (Fixed Price)
-- ============================================================================

CREATE TABLE IF NOT EXISTS listings (
    listing_id VARCHAR PRIMARY KEY,
    domain_name VARCHAR NOT NULL,
    owner VARCHAR NOT NULL,
    price VARCHAR NOT NULL,
    buyer VARCHAR,
    status ListingStatus NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    last_tx_digest VARCHAR NOT NULL,
    token VARCHAR NOT NULL,
    expires_at BIGINT
);

-- Indexes for listings table
CREATE INDEX IF NOT EXISTS idx_listings_domain_name ON listings(domain_name);
CREATE INDEX IF NOT EXISTS idx_listings_owner ON listings(owner);
CREATE INDEX IF NOT EXISTS idx_listings_status ON listings(status);

-- ============================================================================
-- ADMIN/CONFIG TABLES
-- ============================================================================

-- Seal configuration events
CREATE TABLE IF NOT EXISTS set_seal_config (
    id SERIAL PRIMARY KEY,
    key_servers TEXT[] NOT NULL,
    public_keys BYTEA[] NOT NULL,
    threshold SMALLINT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    tx_digest VARCHAR NOT NULL
);

-- Service fee configuration events
CREATE TABLE IF NOT EXISTS set_service_fee (
    id SERIAL PRIMARY KEY,
    service_fee VARCHAR NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    tx_digest VARCHAR NOT NULL
);
