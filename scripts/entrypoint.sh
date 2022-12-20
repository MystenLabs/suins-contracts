#!/bin/bash

set -eo pipefail
source functions.sh

if [ -z "$1" ]; then
  echo "The DOWNLOAD URL is not set"
  exit 1
fi

download_sui
copy_wallet_creds

if [ -z "$2" ] || [ -z "$3" ]; then
  find_contract_addresses_from_docs_repo
else
  find_contract_addresses_from_env "$2" "$3"
fi

download_csv_file "$1"
publish_discount_codes
