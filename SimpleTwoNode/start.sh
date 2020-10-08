#!/bin/bash

###########################
# 2 Launch Redis
###########################

mkdir -p logs

# RUN redis-server --port 6379
redis-server --port 6379 &> logs/redis-a-node.log &
redis-server --port 6380 &> logs/redis-b-node.log &
  # CMD tail -f logs/redis-a-node.log

#   # Remove all data from Redis # Doing this causes connection errors...
# for port in `seq 6379 6380`; do
#     redis-cli -p $port flushall
# done

###########################
# 3. Launch The 2 Nodes
###########################

# Turn on debug logging for all of the interledger.rs components
export RUST_LOG=interledger=debug

# Start both nodes.
# Note that the configuration options can be passed as environment variables
# or saved to a YAML, JSON or TOML file and passed to the node as a positional argument.
# You can also pass it from STDIN.

./ilp-node \
  --ilp_address example.node_a \
  --secret_seed 8852500887504328225458511465394229327394647958135038836332350604 \
  --admin_auth_token admin-a \
  --redis_url redis://127.0.0.1:6379/ \
  --http_bind_address 127.0.0.1:7770 \
  --settlement_api_bind_address 127.0.0.1:7771 \
  &> logs/node_a.log &

./ilp-node \
  --ilp_address example.node_b \
  --secret_seed 1604966725982139900555208458637022875563691455429373719368053354 \
  --admin_auth_token admin-b \
  --redis_url redis://127.0.0.1:6380/ \
  --http_bind_address 127.0.0.1:8770 \
  --settlement_api_bind_address 127.0.0.1:8771 \
  &> logs/node_b.log &

###########################
# 4. Configure the Nodes
###########################
# For authenticating to nodes, we can set credentials as an environment variable or a CLI argument
export ILP_CLI_API_AUTH=admin-a

# Create accounts
printf "Creating Alice's account on Node A...\n"
./ilp-cli accounts create alice \
  --asset-code ABC \
  --asset-scale 9 \
  --ilp-over-http-incoming-token alice-password \
  &>logs/account-node_a-alice.log

printf "Creating Node B's account on Node A...\n"
./ilp-cli accounts create node_b \
  --asset-code ABC \
  --asset-scale 9 \
  --ilp-address example.node_b \
  --ilp-over-http-outgoing-token node_a-password \
  --ilp-over-http-url 'http://localhost:8770/accounts/node_a/ilp' \
  &>logs/account-node_a-node_b.log


# Insert accounts on Node B
# One account represents Bob and the other represents Node A's account with Node B

printf "Creating Bob's account on Node B...\n"
./ilp-cli --node http://localhost:8770 accounts create bob \
  --auth admin-b \
  --asset-code ABC \
  --asset-scale 9 \
  &>logs/account-node_b-bob.log

printf "Creating Node A's account on Node B...\n"
ilp-cli --node http://localhost:8770 accounts create node_a \
    --auth admin-b \
    --asset-code ABC \
    --asset-scale 9 \
    --ilp-over-http-incoming-token node_a-password \
    &>logs/account-node_b-node_a.log



# 5 Sending a Payment
# Sending payment of 500 from Alice (on Node A) to Bob (on Node B)
./ilp-cli pay alice \
    --auth alice-password \
    --amount 500 \
    --to http://localhost:8770/accounts/bob/spsp

while true; do sleep 99000; done