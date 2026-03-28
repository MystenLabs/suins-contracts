CREATE TABLE IF NOT EXISTS auctions_activity (
    id SERIAL PRIMARY KEY,
    type VARCHAR(20) NOT NULL,
    domain_name VARCHAR NOT NULL,
    price VARCHAR NOT NULL,
    from_address VARCHAR NOT NULL,
    to_address VARCHAR,
    timestamp TIMESTAMPTZ NOT NULL,
    status VARCHAR NOT NULL,
    tx_digest VARCHAR NOT NULL,
    source_table VARCHAR(20) NOT NULL,
    source_id VARCHAR NOT NULL,
    UNIQUE(source_table, source_id, type)
);

CREATE INDEX IF NOT EXISTS idx_activity_domain_name ON auctions_activity(domain_name);
CREATE INDEX IF NOT EXISTS idx_activity_timestamp ON auctions_activity(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_activity_type ON auctions_activity(type);
CREATE INDEX IF NOT EXISTS idx_activity_from_address ON auctions_activity(from_address);
CREATE INDEX IF NOT EXISTS idx_activity_to_address ON auctions_activity(to_address);

CREATE OR REPLACE FUNCTION handle_offers_activity()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO auctions_activity (
            type, domain_name, price, from_address, to_address, 
            timestamp, status, tx_digest, source_table, source_id
        ) 
        VALUES (
            'offer', NEW.domain_name, NEW.value, NEW.buyer, NULL, 
            NEW.created_at, NEW.status::text, NEW.last_tx_digest, 'offers', NEW.id::text
        )
        ON CONFLICT (source_table, source_id, type) DO NOTHING;
    END IF;

    IF (TG_OP = 'UPDATE') THEN
        IF (OLD.status != NEW.status AND NEW.status::text IN ('accepted', 'accepted-countered')) THEN
            INSERT INTO auctions_activity (
                type, domain_name, price, from_address, to_address, 
                timestamp, status, tx_digest, source_table, source_id
            ) 
            VALUES (
                'sale', NEW.domain_name, NEW.value, NEW.owner, NEW.buyer, 
                NEW.updated_at, NEW.status::text, NEW.last_tx_digest, 'offers', NEW.id::text
            )
            ON CONFLICT (source_table, source_id, type) DO NOTHING;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION handle_bids_activity()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO auctions_activity (
            type, domain_name, price, from_address, to_address, 
            timestamp, status, tx_digest, source_table, source_id
        ) 
        VALUES (
            'bid', NEW.domain_name, NEW.amount, NEW.bidder, NULL, 
            NEW.created_at, 'placed', NEW.tx_digest, 'bids', NEW.id::text
        )
        ON CONFLICT (source_table, source_id, type) DO NOTHING;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION handle_listings_activity()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO auctions_activity (
            type, domain_name, price, from_address, to_address, 
            timestamp, status, tx_digest, source_table, source_id
        ) 
        VALUES (
            'listing', NEW.domain_name, NEW.price, NEW.owner, NULL, 
            NEW.created_at, NEW.status::text, NEW.last_tx_digest, 'listings', NEW.listing_id
        )
        ON CONFLICT (source_table, source_id, type) DO NOTHING;
    END IF;

    IF (TG_OP = 'UPDATE') THEN
        IF (OLD.status != NEW.status AND NEW.status::text = 'bought') THEN
            INSERT INTO auctions_activity (
                type, domain_name, price, from_address, to_address, 
                timestamp, status, tx_digest, source_table, source_id
            ) 
            VALUES (
                'sale', NEW.domain_name, NEW.price, NEW.owner, NEW.buyer, 
                NEW.updated_at, NEW.status::text, NEW.last_tx_digest, 'listings', NEW.listing_id
            )
            ON CONFLICT (source_table, source_id, type) DO NOTHING;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION handle_auctions_activity()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'UPDATE') THEN
        IF (OLD.status != NEW.status AND NEW.status::text = 'finalized' 
            AND NEW.winner IS NOT NULL 
            AND NEW.winner != '0x0000000000000000000000000000000000000000000000000000000000000000') THEN
            INSERT INTO auctions_activity (
                type, domain_name, price, from_address, to_address, 
                timestamp, status, tx_digest, source_table, source_id
            ) 
            VALUES (
                'sale', NEW.domain_name, COALESCE(NEW.amount, NEW.min_bid), NEW.owner, NEW.winner, 
                NEW.updated_at, NEW.status::text, NEW.last_tx_digest, 'auctions', NEW.auction_id
            )
            ON CONFLICT (source_table, source_id, type) DO NOTHING;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_sync_offers_activity ON offers;
CREATE TRIGGER trg_sync_offers_activity
AFTER INSERT OR UPDATE ON offers
FOR EACH ROW EXECUTE FUNCTION handle_offers_activity();

DROP TRIGGER IF EXISTS trg_sync_bids_activity ON bids;
CREATE TRIGGER trg_sync_bids_activity
AFTER INSERT ON bids
FOR EACH ROW EXECUTE FUNCTION handle_bids_activity();

DROP TRIGGER IF EXISTS trg_sync_listings_activity ON listings;
CREATE TRIGGER trg_sync_listings_activity
AFTER INSERT OR UPDATE ON listings
FOR EACH ROW EXECUTE FUNCTION handle_listings_activity();

DROP TRIGGER IF EXISTS trg_sync_auctions_activity ON auctions;
CREATE TRIGGER trg_sync_auctions_activity
AFTER UPDATE ON auctions
FOR EACH ROW EXECUTE FUNCTION handle_auctions_activity();
