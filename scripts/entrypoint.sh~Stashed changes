#!/bin/bash

set -eo pipefail
source functions.sh
jq
if [ -z "$1" ]; then
  echo "The DOWNLOAD URL is not set"
  exit 1
fi

download_sui
copy_wallet_creds
get_contract_addresses
download_csv_file "$1"
publish_discount_codes
