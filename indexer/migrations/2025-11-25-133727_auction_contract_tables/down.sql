-- ============================================================================
-- ADMIN/CONFIG TABLES
-- ============================================================================

DROP TABLE IF EXISTS set_service_fee;
DROP TABLE IF EXISTS set_seal_config;

-- ============================================================================
-- LISTING TABLES
-- ============================================================================

DROP INDEX IF EXISTS idx_listings_status;
DROP INDEX IF EXISTS idx_listings_owner;
DROP INDEX IF EXISTS idx_listings_domain_name;

DROP TABLE IF EXISTS listings;

-- ============================================================================
-- AUCTION TABLES
-- ============================================================================

DROP INDEX IF EXISTS idx_bids_bidder;
DROP INDEX IF EXISTS idx_bids_domain_name;

DROP INDEX IF EXISTS idx_auctions_status;
DROP INDEX IF EXISTS idx_auctions_owner;
DROP INDEX IF EXISTS idx_auctions_domain_name;

DROP TABLE IF EXISTS bids;
DROP TABLE IF EXISTS auctions;

-- ============================================================================
-- OFFERS TABLE
-- ============================================================================

DROP INDEX IF EXISTS idx_offers_status;
DROP INDEX IF EXISTS idx_offers_buyer;
DROP INDEX IF EXISTS idx_offers_domain_name;

DROP TABLE IF EXISTS offers;

-- ============================================================================
-- OFFER EVENT TABLES
-- ============================================================================

DROP TABLE IF EXISTS accept_counter_offer;
DROP TABLE IF EXISTS make_counter_offer;
DROP TABLE IF EXISTS offer_declined;
DROP TABLE IF EXISTS offer_accepted;
DROP TABLE IF EXISTS offer_cancelled;
DROP TABLE IF EXISTS offer_placed;

-- ============================================================================
-- ENUMS
-- ============================================================================

DROP TYPE IF EXISTS ListingStatus;
DROP TYPE IF EXISTS AuctionStatus;
DROP TYPE IF EXISTS OfferStatus;
