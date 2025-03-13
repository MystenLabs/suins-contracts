#!/usr/bin/env bash

set -o nounset      # Treat unset variables as an error when substituting
set -o errexit      # Exit immediately if any command returns a non-zero status
set -o pipefail     # Prevent errors in a pipeline from being masked
# set -o xtrace       # Print each command to the terminal before execution

SCRIPT_DIR="$( dirname "$(readlink -f "${BASH_SOURCE[0]}")" )"

### paths ###

PACKAGES_DIR="$SCRIPT_DIR/../../"
VOTING_DIR="$PACKAGES_DIR/voting"

### functions ###

function upgrade() {
    local dir="$1"

    echo "Upgrading $dir"
    cd "$dir"
    sui client upgrade --upgrade-capability "$UPGRADE_CAP" --json
}

### main ###

# prevent from running on mainnet
if [ "$(sui client active-env)" == "mainnet" ]; then
    echo "The active environment is mainnet. Aborting."
    exit 1
fi

# read upgrade cap from CLI args
if [ $# -lt 1 ]; then
    echo "Usage: $0 <upgrade-capability-id>"
    echo "Example: $0 0x123"
    exit 1
fi

UPGRADE_CAP="$1"

upgrade "$VOTING_DIR"
