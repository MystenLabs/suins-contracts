DROP TRIGGER IF EXISTS trg_sync_offers_activity ON offers;
DROP TRIGGER IF EXISTS trg_sync_bids_activity ON bids;
DROP TRIGGER IF EXISTS trg_sync_listings_activity ON listings;
DROP TRIGGER IF EXISTS trg_sync_auctions_activity ON auctions;

DROP FUNCTION IF EXISTS handle_offers_activity();
DROP FUNCTION IF EXISTS handle_bids_activity();
DROP FUNCTION IF EXISTS handle_listings_activity();
DROP FUNCTION IF EXISTS handle_auctions_activity();

DROP TABLE IF EXISTS auctions_activity;
