-- This file should undo anything in `up.sql`

-- Drop all tables in reverse order
DROP TABLE IF EXISTS offer_cancelled;
DROP TABLE IF EXISTS offer_placed;
DROP TABLE IF EXISTS events_cursor;
