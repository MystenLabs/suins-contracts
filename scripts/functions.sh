#!/bin/bash
download_sui() {
    git clone --single-branch --branch "devnet" https://github.com/MystenLabs/sui.git
    cd sui || exit 1
    LATEST_TAG=$(git tag -l 'devnet*' --sort=-version:refname | grep -m1 "")
    echo "Sui version: $LATEST_TAG"
    curl -L https://github.com/MystenLabs/sui/releases/download/"$LATEST_TAG"/sui > sui
    chmod +x sui
    export PATH="/sui:$PATH" 
    cd /
}

copy_wallet_creds() {
    mkdir -p /root/.sui/sui_config
    echo "active_address: \"$ACTIVE_ADDRESS\"" >> /sui_config/client.yaml
    echo "[\"$PRIVATE_KEY\"]" > /sui_config/sui.keystore
    cp /sui_config/* /root/.sui/sui_config
    ACTIVE_ADDR=$(sui client active-address)
    echo "Active address: $ACTIVE_ADDR"
    echo "Setup client successfully"
}

find_contract_addresses_from_docs_repo() {
    git clone --single-branch --branch "main" https://github.com/SuiNSdapp/docs.git
    PACKAGE_RE="^- Package address: \[0x([0-9a-fA-F]+)\]\(https://explorer.devnet.sui.io/objects/0x([0-9a-fA-F]+)\)$"
    CONFIGURATION_RE="^- Configuration object: \[0x([0-9a-fA-F]+)\]\(https://explorer.devnet.sui.io/objects/0x([0-9a-fA-F]+)\)$"

    while read -r line
    do
    if [[ $line =~ $CONFIGURATION_RE ]]; then
        CONFIGURATION_ADDR="0x${BASH_REMATCH[1]}"

        if [ -z "$PACKAGE_ADDR" ]; then
          continue
        else
          break
        fi
    fi
    if [[ $line =~ $PACKAGE_RE ]]; then
        PACKAGE_ADDR="0x${BASH_REMATCH[1]}"

        if [ -z "$CONFIGURATION_ADDR" ]; then
          continue
        else
          break
        fi
    fi
    done < docs/README.md

    find_admin_cap_address
}

find_contract_addresses_from_env() {
    PACKAGE_ADDR=$1
    CONFIGURATION_ADDR=$2
    find_admin_cap_address
}

find_admin_cap_address() {
    NFTs=$(
      curl --location --request POST 'https://fullnode.devnet.sui.io:443' \
      --header 'Content-Type: application/json' \
      --data-raw '{ "jsonrpc": "2.0",
                    "method": "sui_getObjectsOwnedByAddress",
                    "params": [
                        "'"$ACTIVE_ADDR"'"
                    ],
                    "id": 1 }' | json_pp
    )
    ADMIN_CAP=$(
      echo "$NFTs" | jq -r \
        '.result[] | select(.type=="'"$PACKAGE_ADDR"'::base_registry::AdminCap") | .objectId'
    )
    echo "PACKAGE ADDRESS: $PACKAGE_ADDR"
    echo "CONFIGURATION OBJECT: $CONFIGURATION_ADDR"
    echo "ADMIN_CAP OBJECT: $ADMIN_CAP"
}

download_csv_file() {
    wget --no-check-certificate -q "$1" -O input.csv
    CSV=$(tail -n +2 input.csv)
}

publish_discount_codes() {
    RATE_RE='^([0-9]{1,2}|100)$'
    OWNER_RE='^(0x|0X)'
    CODE_BATCH=''
    
    while IFS="," read -r code rate owner
    do
    if ! [[ $rate =~ $RATE_RE ]]; then
        echo " $rate error: Not a number" >&2; exit 1
    fi
    if ! [[ $owner =~ $OWNER_RE ]]; then
        echo "$owner error: Not a address" >&2; exit 1
    fi
    CODE_BATCH+="$code,"
    CODE_BATCH+="$rate,"
    CODE_BATCH+="$owner;"
    done < <(echo "$CSV")

    sui client call --package "$PACKAGE_ADDR" --module configuration \
        --function new_discount_code_batch \
        --args "$ADMIN_CAP" "$CONFIGURATION_ADDR" "$CODE_BATCH" --gas-budget 10000
}
