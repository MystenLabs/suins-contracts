#!/bin/bash

export RUST_BACKTRACE=1
export RUST_LOG=debug

# for initdb
export PATH="/usr/lib/postgresql/$(ls /usr/lib/postgresql | head -n 1)/bin:$PATH"

# If RESET_WATERMARKS is set, clear existing watermarks to allow --first-checkpoint to work
if [ "$RESET_WATERMARKS" = "true" ] && [ -n "$DB_URL" ]; then
    echo "Resetting watermarks table..."
    psql "$DB_URL" -c "DELETE FROM watermarks;" 2>/dev/null || echo "Warning: Could not reset watermarks (table may not exist yet)"
fi

# Build command with optional arguments
CMD="/opt/mysten/bin/suins-indexer --database-url $DB_URL"

if [ -n "$FIRST_CHECKPOINT" ]; then
    CMD="$CMD --first-checkpoint $FIRST_CHECKPOINT"
fi

if [ -n "$LAST_CHECKPOINT" ]; then
    CMD="$CMD --last-checkpoint $LAST_CHECKPOINT"
fi

exec $CMD
