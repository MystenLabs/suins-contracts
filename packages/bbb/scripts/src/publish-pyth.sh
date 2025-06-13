#!/usr/bin/env bash

#### DEV ONLY SCRIPT ####

# === settings ===

set -o nounset      # Treat unset variables as an error when substituting
set -o errexit      # Exit immediately if any command returns a non-zero status
set -o pipefail     # Prevent errors in a pipeline from being masked
# set -o xtrace       # Print each command to the terminal before execution

# === paths ===

SCRIPT_DIR="$( dirname "$(readlink -f "${BASH_SOURCE[0]}")" )"
PATH_PROJECT="$( cd "$SCRIPT_DIR/../../../.." && pwd )"
PATH_PACKAGES="$PATH_PROJECT/packages"
PATH_BBB="$PATH_PACKAGES/bbb"
PATH_TMP="$PATH_PACKAGES/tmp"

# === main ===

# check network

network=$(sui client active-env)
if [ "$network" != "localnet" ]; then
    read -p "You are about to publish to $network. Are you sure? (y/n): " confirm
    if [ "$confirm" != "y" ]; then
        echo "Aborted by user."
        exit 1
    fi
fi

# copy files

rm -rf "$PATH_TMP"
mkdir -p "$PATH_TMP/sources"
cp "$PATH_BBB/Move.toml" "$PATH_TMP/"
cp "$PATH_BBB/sources/oracle_pyth.move" "$PATH_TMP/sources/"

# modify Move.toml

sed -i.bak1 '/^AftermathAmm = /d' "$PATH_TMP/Move.toml"
sed -i.bak2 '/^AfSuiTreasury = /d' "$PATH_TMP/Move.toml"
sed -i.bak3 '/^InsuranceFund = /d' "$PATH_TMP/Move.toml"
sed -i.bak4 '/^ProtocolFeeVault = /d' "$PATH_TMP/Move.toml"
rm "$PATH_TMP"/Move.toml.bak*

# publish
sui client publish "$PATH_TMP" --json --dry-run

# cleanup
rm -rf "$PATH_TMP"
