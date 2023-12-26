#!/bin/sh

forge script scripts/DeployScripts.s.sol:DeployScript --rpc-url "$RPC_URL" --private-key "$PRIVATE_KEY" --broadcast --chain-id "$CHAIN_ID" -vvvv --use 0.8.23

