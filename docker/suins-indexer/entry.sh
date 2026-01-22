#!/bin/bash

export RUST_BACKTRACE=1
export RUST_LOG=debug

# for initdb
export PATH="/usr/lib/postgresql/$(ls /usr/lib/postgresql | head -n 1)/bin:$PATH"

# Build command with optional arguments
CMD="/opt/mysten/bin/suins-indexer --database-url $DB_URL"

if [ -n "$FIRST_CHECKPOINT" ]; then
    CMD="$CMD --first-checkpoint $FIRST_CHECKPOINT"
fi

if [ -n "$LAST_CHECKPOINT" ]; then
    CMD="$CMD --last-checkpoint $LAST_CHECKPOINT"
fi

exec $CMD
