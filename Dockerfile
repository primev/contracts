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

RUN chmod +x entrypoint.sh

ENTRYPOINT ["/app/entrypoint.sh"]

