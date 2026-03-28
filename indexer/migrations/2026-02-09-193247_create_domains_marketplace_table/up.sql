CREATE TABLE IF NOT EXISTS domains_marketplace (
    domain_name VARCHAR PRIMARY KEY,
    status VARCHAR NOT NULL DEFAULT 'unlisted',
    min_price NUMERIC,
    owner VARCHAR,
    auction_id VARCHAR,
    auction_min_bid NUMERIC,
    auction_end_time TIMESTAMPTZ,
    auction_highest_bid NUMERIC,
    listing_id VARCHAR,
    listing_price NUMERIC,
    listing_expires_at TIMESTAMPTZ,
    best_offer_value NUMERIC,
    active_offer_count INTEGER DEFAULT 0,
    last_marketplace_update TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_dm_status_min_price ON domains_marketplace(status, min_price);
CREATE INDEX IF NOT EXISTS idx_dm_active_offer_count ON domains_marketplace(active_offer_count);

CREATE INDEX IF NOT EXISTS idx_dm_auction_end_time ON domains_marketplace(auction_end_time) WHERE auction_end_time IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_dm_listing_expires_at ON domains_marketplace(listing_expires_at) WHERE listing_expires_at IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_dm_last_update ON domains_marketplace(last_marketplace_update);

CREATE OR REPLACE FUNCTION refresh_domain_marketplace(p_domain_name VARCHAR)
RETURNS VOID AS $$
DECLARE
    v_auction_status VARCHAR;
    v_auction_id VARCHAR;
    v_auction_owner VARCHAR;
    v_auction_min_bid NUMERIC;
    v_auction_end_time TIMESTAMPTZ;
    v_auction_highest_bid NUMERIC;
    v_listing_status VARCHAR;
    v_listing_id VARCHAR;
    v_listing_owner VARCHAR;
    v_listing_price NUMERIC;
    v_listing_expires_at TIMESTAMPTZ;
    v_best_offer NUMERIC;
    v_offer_count INTEGER;
    v_offer_owner VARCHAR;
    v_auction_created_at TIMESTAMPTZ;
    v_listing_created_at TIMESTAMPTZ;
    v_offer_created_at TIMESTAMPTZ;
    v_final_status VARCHAR := 'unlisted';
    v_min_price NUMERIC := NULL;
    v_owner VARCHAR := NULL;
BEGIN
    SELECT 
        status, auction_id, owner, min_bid::numeric, to_timestamp(end_time), created_at
    INTO 
        v_auction_status, v_auction_id, v_auction_owner, v_auction_min_bid, v_auction_end_time, v_auction_created_at
    FROM auctions 
    WHERE domain_name = p_domain_name 
      AND status = 'created' 
      AND end_time > (extract(epoch from now()))::bigint
    ORDER BY created_at DESC 
    LIMIT 1;

    IF v_auction_id IS NOT NULL THEN
        SELECT MAX(amount::numeric) INTO v_auction_highest_bid 
        FROM bids 
        WHERE auction_id = v_auction_id;
    END IF;

    SELECT 
        status, listing_id, owner, price::numeric, to_timestamp(expires_at), created_at
    INTO 
        v_listing_status, v_listing_id, v_listing_owner, v_listing_price, v_listing_expires_at, v_listing_created_at
    FROM listings 
    WHERE domain_name = p_domain_name 
      AND status = 'created' 
      AND (expires_at IS NULL OR expires_at > (extract(epoch from now()))::bigint)
    ORDER BY created_at DESC 
    LIMIT 1;

    SELECT 
        MAX(value::numeric), COUNT(*), MAX(created_at), MAX(owner)
    INTO 
        v_best_offer, v_offer_count, v_offer_created_at, v_offer_owner
    FROM offers 
    WHERE domain_name = p_domain_name 
      AND status IN ('placed', 'countered');

    IF v_auction_status = 'created' THEN
        v_final_status := 'auction';
        v_min_price := GREATEST(v_auction_min_bid, COALESCE(v_auction_highest_bid, 0));
    ELSIF v_listing_status = 'created' THEN
        v_final_status := 'listed';
        v_min_price := v_listing_price;
    ELSE
        v_final_status := 'unlisted';
        v_min_price := v_best_offer; 
    END IF;

    IF v_final_status = 'unlisted' AND COALESCE(v_offer_count, 0) = 0 THEN
        DELETE FROM domains_marketplace WHERE domain_name = p_domain_name;
    ELSE
        INSERT INTO domains_marketplace (
            domain_name, status, min_price, owner,
            auction_id, auction_min_bid, auction_end_time, auction_highest_bid,
            listing_id, listing_price, listing_expires_at,
            best_offer_value, active_offer_count,
            last_marketplace_update
        ) VALUES (
            p_domain_name, v_final_status, v_min_price, 
            COALESCE(v_auction_owner, v_listing_owner, v_offer_owner),
            v_auction_id, v_auction_min_bid, v_auction_end_time, v_auction_highest_bid,
            v_listing_id, v_listing_price, v_listing_expires_at,
            v_best_offer, COALESCE(v_offer_count, 0),
            COALESCE(GREATEST(v_auction_created_at, v_listing_created_at, v_offer_created_at), NOW())
        )
        ON CONFLICT (domain_name) DO UPDATE SET
            status = EXCLUDED.status,
            min_price = EXCLUDED.min_price,
            owner = EXCLUDED.owner,
            auction_id = EXCLUDED.auction_id,
            auction_min_bid = EXCLUDED.auction_min_bid,
            auction_end_time = EXCLUDED.auction_end_time,
            auction_highest_bid = EXCLUDED.auction_highest_bid,
            listing_id = EXCLUDED.listing_id,
            listing_price = EXCLUDED.listing_price,
            listing_expires_at = EXCLUDED.listing_expires_at,
            best_offer_value = EXCLUDED.best_offer_value,
            active_offer_count = EXCLUDED.active_offer_count,
            last_marketplace_update = COALESCE(GREATEST(v_auction_created_at, v_listing_created_at, v_offer_created_at), NOW());
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION trigger_refresh_marketplace()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'DELETE') THEN
        PERFORM refresh_domain_marketplace(OLD.domain_name);
    ELSE
        PERFORM refresh_domain_marketplace(NEW.domain_name);
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION trigger_refresh_marketplace_bids()
RETURNS TRIGGER AS $$
DECLARE
    v_domain_name VARCHAR;
BEGIN
    IF (TG_OP = 'INSERT') THEN
         SELECT domain_name INTO v_domain_name FROM auctions WHERE auction_id = NEW.auction_id;
         IF v_domain_name IS NOT NULL THEN
            PERFORM refresh_domain_marketplace(v_domain_name);
         END IF;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_dm_auctions ON auctions;
CREATE TRIGGER trg_dm_auctions
AFTER INSERT OR UPDATE ON auctions
FOR EACH ROW EXECUTE FUNCTION trigger_refresh_marketplace();

DROP TRIGGER IF EXISTS trg_dm_listings ON listings;
CREATE TRIGGER trg_dm_listings
AFTER INSERT OR UPDATE ON listings
FOR EACH ROW EXECUTE FUNCTION trigger_refresh_marketplace();

DROP TRIGGER IF EXISTS trg_dm_offers ON offers;
CREATE TRIGGER trg_dm_offers
AFTER INSERT OR UPDATE OR DELETE ON offers
FOR EACH ROW EXECUTE FUNCTION trigger_refresh_marketplace();

DROP TRIGGER IF EXISTS trg_dm_bids ON bids;
CREATE TRIGGER trg_dm_bids
AFTER INSERT ON bids
FOR EACH ROW EXECUTE FUNCTION trigger_refresh_marketplace_bids();
