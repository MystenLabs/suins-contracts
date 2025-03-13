#!/usr/bin/env bash

set -o nounset      # Treat unset variables as an error when substituting
set -o errexit      # Exit immediately if any command returns a non-zero status
set -o pipefail     # Prevent errors in a pipeline from being masked
# set -o xtrace       # Print each command to the terminal before execution

SCRIPT_DIR="$( dirname "$(readlink -f "${BASH_SOURCE[0]}")" )"

### paths ###

PACKAGES_DIR="$SCRIPT_DIR/../../"
TOKEN_DIR="$PACKAGES_DIR/token"
VOTING_DIR="$PACKAGES_DIR/voting"

### functions ###

function publish() {
    local dir="$1"

    echo "Publishing $dir"
    cd "$dir"
    local json=$(sui client publish --json)
    local package_id=$(get_package_id "$json")
    echo "Package ID: $package_id"
}

function get_package_id() {
    local json="$1"

    echo "$json" | jq '.objectChanges[] | select(.type == "published") | .packageId'
}

### main ###

# prevent from running on mainnet
if [ "$(sui client active-env)" == "mainnet" ]; then
    echo "The active environment is mainnet. Aborting."
    exit 1
fi

publish "$TOKEN_DIR"
publish "$VOTING_DIR"
