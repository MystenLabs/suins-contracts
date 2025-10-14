DROP INDEX IF EXISTS idx_auctions_domain_name;
DROP INDEX IF EXISTS idx_auctions_owner;
DROP INDEX IF EXISTS idx_auctions_status;

DROP INDEX IF EXISTS idx_bids_domain_name;
DROP INDEX IF EXISTS idx_bids_bidder;

DROP TABLE IF EXISTS bids;
DROP TABLE IF EXISTS auctions;
DROP TYPE IF EXISTS AuctionStatus;
