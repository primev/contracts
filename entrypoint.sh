#!/bin/sh

# Default to core deploy type if not specified
DEPLOY_TYPE=${DEPLOY_TYPE:-core}

if [ "$DEPLOY_TYPE" = "core" ]; then
    echo "Deploying core contracts"
    forge script scripts/DeployScripts.s.sol:DeployScript --rpc-url "$RPC_URL" --private-key "$PRIVATE_KEY" --broadcast --chain-id "$CHAIN_ID" -vvvv --use 0.8.23

elif [ "$DEPLOY_TYPE" = "whitelist" ]; then
    if [ -z "$HYP_ERC20_ADDR" ]; then
        echo "HYP_ERC20_ADDR not specified"
        exit 1
    fi
    echo "Deploying whitelist contract"
    HYP_ERC20_ADDR="$HYP_ERC20_ADDR" forge script scripts/DeployScripts.s.sol:DeployWhitelist --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast --chain-id $CHAIN_ID -vvvv --use 0.8.23
fi
