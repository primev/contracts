# Use the latest foundry image
FROM ghcr.io/foundry-rs/foundry

# Set working directory
WORKDIR /app

# Copy our source code into the container
COPY . .

# Build the source code
RUN forge build

# Set environment variables for RPC URL and private key
# These should be passed during the Docker build process
ARG RPC_URL
ARG PRIVATE_KEY
ARG CHAIN_ID

# Run the deploy script using forge
# Note: This line will execute during image build, 
# which may not be ideal for deployment scripts. Consider using CMD or ENTRYPOINT for runtime execution.
RUN forge script scripts/DeployScripts.s.sol:DeployScript --rpc-url "$RPC_URL" --private-key "$PRIVATE_KEY" --broadcast --chain-id "$CHAIN_ID" -vvvv
