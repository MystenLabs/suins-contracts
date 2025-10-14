DROP INDEX IF EXISTS idx_offers_domain_name;
DROP INDEX IF EXISTS idx_offers_buyer;
DROP INDEX IF EXISTS idx_offers_status;

DROP TABLE IF EXISTS offers;
DROP TYPE IF EXISTS OfferStatus;
