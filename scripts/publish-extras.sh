#!/bin/bash

# check dependencies are available.
for i in jq curl sui; do
  if ! command -V ${i} 2>/dev/null; then
    echo "${i} is not installed"
    exit 1
  fi
done

NETWORK=http://localhost:9000
BACKEND_API=http://localhost:3000

if [ $# -ne 0 ]; then
  if [ $1 = "testnet" ]; then
    NETWORK="https://mysten-rpc.testnet.sui.io:443"
    FAUCET="https://faucet.testnet.sui.io/gas"
    BACKEND_API="https://api-testnet.sui.io"
  fi
  if [ $1 = "devnet" ]; then
    NETWORK="https://rpc.devnet.sui.io:443"
    FAUCET="https://faucet.devnet.sui.io/gas"
    BACKEND_API="https://api-devnet.sui.io"
  fi
fi

echo "- Admin Address is: ${ADMIN_ADDRESS}"

utils_publish_res=$(sui client publish --skip-fetch-latest-git-deps --gas-budget 2000000000 --json ../packages/utils --skip-dependency-verification)
registration_publish_res=$(sui client publish --skip-fetch-latest-git-deps --gas-budget 2000000000 --json ../packages/registration --skip-dependency-verification)
subdomains_publish_res=$(sui client publish --skip-fetch-latest-git-deps --gas-budget 2000000000 --json ../packages/subdomains --skip-dependency-verification)

utilsObjs=$(echo "$utils_publish_res" | jq -r '.objectChanges[] | select(.type == "published")')
registrationObjs=$(echo "$registration_publish_res" | jq -r '.objectChanges[] | select(.type == "published")')
subdomainsObjs=$(echo "$subdomains_publish_res" | jq -r '.objectChanges[] | select(.type == "published")')

UTILS_PACKAGE_ID=$(echo "$utilsObjs" | jq -r '.packageId')
REGISTRATION_PACKAGE_ID=$(echo "$registrationObjs" | jq -r '.packageId')
SUBDOMAINS_PACKAGE_ID=$(echo "$subdomainsObjs" | jq -r '.packageId')


suffix=""
if [ $# -eq 0 ]; then
  suffix=".localnet"
fi

cat >> .env.local<<-API_ENV
UTILS_PACKAGE_ADDRESS=$UTILS_PACKAGE_ID
REGISTRATION_PACKAGE_ADDRESS=$REGISTRATION_PACKAGE_ID
SUBDOMAINS_PACKAGE_ADDRESS=$SUBDOMAINS_PACKAGE_ID
API_ENV

echo "Side contracts Deployment finished!"
