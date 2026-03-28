DROP TRIGGER IF EXISTS trg_dm_auctions ON auctions;
DROP TRIGGER IF EXISTS trg_dm_listings ON listings;
DROP TRIGGER IF EXISTS trg_dm_offers ON offers;
DROP TRIGGER IF EXISTS trg_dm_bids ON bids;

DROP FUNCTION IF EXISTS trigger_refresh_marketplace();
DROP FUNCTION IF EXISTS trigger_refresh_marketplace_bids();

DROP FUNCTION IF EXISTS refresh_domain_marketplace(VARCHAR);

DROP TABLE IF EXISTS domains_marketplace;
