#!/bin/bash

export RUST_BACKTRACE=1
export RUST_LOG=debug

# for initdb
export PATH="/usr/lib/postgresql/$(ls /usr/lib/postgresql | head -n 1)/bin:$PATH"

/opt/mysten/bin/suins-indexer --database-url "$DB_URL"
