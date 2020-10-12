#!/bin/bash

# ETH to XRP 3 Node example
# This tutorial demonstrates how to:

# 1. Spin up a local test network with three Interledger.rs nodes
# 2. Send a cross-currency payment between them
# 3. Settle the payment using a local Ethereum testnet and the XRP Ledger testnet

# tutorial: https://interledger.org/spin-up-local-network.html
# Diagram: https://github.com/interledger-rs/interledger-rs/tree/master/examples/eth-xrp-three-nodes
## This is probably the diagram for this example... though it's not entirely clear if this tutorial is the same

#================================
# I. Set up
#================================

# 1. Download Docker Images
# docker pull interledgerrs/ilp-node
# docker pull interledgerrs/ilp-cli
# docker pull interledgerrs/ilp-settlement-ethereum
# docker pull trufflesuite/ganache-cli
# docker pull interledgerjs/settlement-xrp
# docker pull redis

# 2. create docker network
docker network create local-ilp

# 3. Start a Redis database instance that will be shared across all the services:
docker run -d \
  --name redis \
  --network local-ilp \
  redis

#4. Then, launch a local Ethereum testnet with 10 prefunded accounts to use as a settlement ledger between Alice and Bob:
docker run -d \
--name ethereum-testnet \
--network local-ilp \
trufflesuite/ganache-cli \
-m "abstract vacuum mammal awkward pudding scene penalty purchase dinner depart evoke puzzle" \
-i 1


#================================
# II. Start the nodes
#================================

# 1. Start Alice's node
# First, start Alice's Ethereum settlement engine, which will be used to settle with Bob:
## The provided private key corresponds to a prefunded Ethereum account in the Ganache testnet.
printf "%s\n" "Alice: Starting Ethereum Settlement Engine..."
docker run -d \
  --name alice-eth \
  --network local-ilp \
  -e "RUST_LOG=interledger=trace" \
  interledgerrs/ilp-settlement-ethereum \
  --private_key 380eb0f3d505f087e438eca80bc4df9a7faa24f868e69fc0440261a0fc0567dc \
  --confirmations 0 \
  --poll_frequency 1000 \
  --ethereum_url http://ethereum-testnet:8545 \
  --connector_url http://alice-node:7771 \
  --redis_url redis://redis:6379/0 \
  --asset_scale 9 \
  --settlement_api_bind_address 0.0.0.0:3000
sleep 2

# 2. Next, start Alice's Interledger node:
printf "%s\n" "Alice: Starting Interledger node..."
docker run -d \
  --name alice-node \
  --network local-ilp \
  -e "RUST_LOG=interledger=trace" \
  interledgerrs/ilp-node \
  --ilp_address example.alice \
  --secret_seed 8852500887504328225458511465394229327394647958135038836332350604 \
  --admin_auth_token hi_alice \
  --redis_url redis://redis:6379/1 \
  --http_bind_address 0.0.0.0:7770 \
  --settlement_api_bind_address 0.0.0.0:7771 \
  --exchange_rate.provider CoinCap
sleep 2

# 3. Start Bob's node
# First, start Bob's Ethereum settlement engine, which will be used to credit incoming Ethereum payments from Alice:
printf "%s\n" "Bob: Starting Ethereum Settlement Engine..."
docker run -d \
  --name bob-eth \
  --network local-ilp \
  -e "RUST_LOG=interledger=trace" \
  interledgerrs/ilp-settlement-ethereum \
  --private_key cc96601bc52293b53c4736a12af9130abf347669b3813f9ec4cafdf6991b087e \
  --confirmations 0 \
  --poll_frequency 1000 \
  --ethereum_url http://ethereum-testnet:8545 \
  --connector_url http://bob-node:7771 \
  --redis_url redis://redis:6379/2 \
  --asset_scale 9 \
  --settlement_api_bind_address 0.0.0.0:3000
sleep 2

# 4. Now, start Bob's XRP settlement engine, which will be used to settle with Charlie:
printf "%s\n" "Bob: Starting XRP Settlment Engine..."
docker run -d \
  --name bob-xrp \
  --network local-ilp \
  -e "DEBUG=settlement*" \
  -e "CONNECTOR_URL=http://bob-node:7771" \
  -e "REDIS_URI=redis://redis:6379/3" \
  -e "ENGINE_PORT=3001" \
  interledgerjs/settlement-xrp
sleep 2
  # The XRP settlement engine will automatically generate a prefunded testnet account and credentials from the official faucet .

# 5. Lastly, start Bob's Interledger node:
printf "%s\n" "Bob: Starting Interledger node..."
docker run -d \
  --name bob-node \
  --network local-ilp \
  -e "RUST_LOG=interledger=trace" \
  interledgerrs/ilp-node \
  --ilp_address example.bob \
  --secret_seed 1604966725982139900555208458637022875563691455429373719368053354 \
  --admin_auth_token hi_bob \
  --redis_url redis://redis:6379/4 \
  --http_bind_address 0.0.0.0:7770 \
  --settlement_api_bind_address 0.0.0.0:7771 \
  --exchange_rate.provider CoinCap
sleep 2
  # Bob will pull exchange rates from the CoinCap API  for foreign exchange between ETH and XRP.

# 6. Start Charlie's node
# Start Charlie's XRP settlement engine to credit incoming settlements from Bob:
printf "%s\n" "Charlie: Starting XRP Settlement engine..."
docker run -d \
  --name charlie-xrp \
  --network local-ilp \
  -e "DEBUG=settlement*" \
  -e "CONNECTOR_URL=http://charlie-node:7771" \
  -e "REDIS_URI=redis://redis:6379/5" \
  -e "ENGINE_PORT=3000" \
  interledgerjs/settlement-xrp
sleep 2
# 7. And lastly, start Charlie's Interledger node:
printf "%s\n" "Charlie: Starting Interledger node..."
docker run -d \
  --name charlie-node \
  --network local-ilp \
  -e "RUST_LOG=interledger=trace" \
  interledgerrs/ilp-node \
  --secret_seed 1232362131122139900555208458637022875563691455429373719368053354 \
  --admin_auth_token hi_charlie \
  --redis_url redis://redis:6379/6 \
  --http_bind_address 0.0.0.0:7770 \
  --settlement_api_bind_address 0.0.0.0:7771 \
  --exchange_rate.provider CoinCap
sleep 2


#================================
# III. Configure Accounts
#================================

# 0. Configure Aliases
# alias docker run --rm --network local-ilp interledgerrs/ilp-cli --node http://alice-node:7770="docker run --rm --network local-ilp interledgerrs/ilp-cli --node http://alice-node:7770"
# alias docker run --rm --network local-ilp interledgerrs/ilp-cli --node http://bob-node:7770="docker run --rm --network local-ilp interledgerrs/ilp-cli --node http://bob-node:7770"
# alias docker run --rm --network local-ilp interledgerrs/ilp-cli --node http://charlie-node:7770="docker run --rm --network local-ilp interledgerrs/ilp-cli --node http://charlie-node:7770"

# 1. Configure Alice's accounts
# Create Alice's account:
printf "%s\n" "Alice: Creating Account on Alice's Node..."
docker run --rm --network local-ilp interledgerrs/ilp-cli --node http://alice-node:7770 accounts create alice \
  --auth hi_alice \
  --ilp-address example.alice \
  --asset-code ETH \
  --asset-scale 9 \
  --ilp-over-http-incoming-token alice_password
sleep 2

# 2. Create the Alice ⇋ Bob account on Alice's node (ETH, peer relation):
printf "%s\n" "Alice: Creating Alice⇋Bob account on Alice's node (ETH, peer relation)"
docker run --rm --network local-ilp interledgerrs/ilp-cli --node http://alice-node:7770 accounts create bob \
  --auth hi_alice \
  --ilp-address example.bob \
  --asset-code ETH \
  --asset-scale 9 \
  --settlement-engine-url http://alice-eth:3000 \
  --ilp-over-http-incoming-token bob_password \
  --ilp-over-http-outgoing-token alice_password \
  --ilp-over-http-url http://bob-node:7770/accounts/alice/ilp \
  --settle-threshold 100000 \
  --settle-to 0 \
  --routing-relation Peer
sleep 2
# After more than 0.0001 ETH is fulfilled from Alice to Bob (settle-threshold), Alice will settle the entire liability with Bob (settle-to).

# 3. Configure Bob's accounts
# Create the Alice ⇋ Bob account on Bob's node (ETH, peer relation):
printf "%s\n" "Bob: Creating Alice⇋Bob account on Bob's node (ETH, peer relation)"
docker run --rm --network local-ilp interledgerrs/ilp-cli --node http://bob-node:7770 accounts create alice \
  --auth hi_bob \
  --ilp-address example.alice \
  --asset-code ETH \
  --asset-scale 9 \
  --max-packet-amount 100000 \
  --settlement-engine-url http://bob-eth:3000 \
  --ilp-over-http-incoming-token alice_password \
  --ilp-over-http-outgoing-token bob_password \
  --ilp-over-http-url http://alice-node:7770/accounts/bob/ilp \
  --min-balance -150000 \
  --routing-relation Peer
sleep 2
  # Bob enforces that Alice will not owe him greater than 0.00015 ETH (min-balance). After that, she must settle to send additional ILP packets.

# 4. Create the Bob ⇋ Charlie account on Bob's node (XRP, child relation):
printf "%s\n" "Bob: Creating Bob⇋Charlie account on Bob's node (XRP, child relation)"
docker run --rm --network local-ilp interledgerrs/ilp-cli --node http://bob-node:7770 accounts create charlie \
  --auth hi_bob \
  --asset-code XRP \
  --asset-scale 6 \
  --settlement-engine-url http://bob-xrp:3001 \
  --ilp-over-http-incoming-token charlie_password \
  --ilp-over-http-outgoing-token bob_other_password \
  --ilp-over-http-url http://charlie-node:7770/accounts/bob/ilp \
  --settle-threshold 10000 \
  --settle-to -1000000 \
  --routing-relation Child
sleep 2
  # After 0.01 XRP is fulfilled from Bob to Charlie (settle-threshold), Bob will settle the full liability plus prepay Charlie 1 XRP (settle-to).


# 5. Configure Charlie's accounts
# Create the Bob ⇋ Charlie account on Charlie's node (XRP, parent relation):
printf "%s\n" "Charlie: Creating the Bob ⇋ Charlie account on Charlie's node (XRP, parent relation)"
docker run --rm --network local-ilp interledgerrs/ilp-cli --node http://charlie-node:7770 accounts create bob \
  --auth hi_charlie \
  --ilp-address example.bob \
  --asset-code XRP \
  --asset-scale 6 \
  --settlement-engine-url http://charlie-xrp:3000 \
  --ilp-over-http-incoming-token bob_other_password \
  --ilp-over-http-outgoing-token charlie_password \
  --ilp-over-http-url http://bob-node:7770/accounts/charlie/ilp \
  --min-balance -50000 \
  --routing-relation Parent
sleep 2
  # Charlie enforces that Bob will not owe him greater than 0.05 XRP (min-balance). After that, he must settle to send additional ILP packets.

# 6. Lastly, create Charlie's account:
printf "%s\n" "Charlie: Creating Charlie's account on Charlie's node..."
docker run --rm --network local-ilp interledgerrs/ilp-cli --node http://charlie-node:7770 accounts create charlie \
  --auth hi_charlie \
  --asset-code XRP \
  --asset-scale 6 \
  --ilp-over-http-incoming-token charlie_password

sleep 6 # This sleep is crucial

#================================
# IV. Send a payment
#================================

# 1. Send Payment
# Now, send a payment from Alice to Charlie, via Bob. Specifically, send a payment from the alice account on Alice's node,
# to the $charlie-node:7770/accounts/charlie/spsp payment pointer, which corresponds to the charlie account on Charlie's node.
printf "%s\n" "Alice: Sending payment from Alice to Charlie, via Bob..."
docker run --rm --network local-ilp interledgerrs/ilp-cli --node http://alice-node:7770 pay alice \
  --auth alice_password \
  --amount 200000 \
  --to http://charlie-node:7770/accounts/charlie/spsp
sleep 2
  # If the payment is successful, you should see output like this (the delivered amount will differ since the exchange rate will change):


#================================
# V. Check balances
#================================

printf "\n========= ALICE'S NODE ========="
printf "\nAlice's balance: "
docker run --rm --network local-ilp interledgerrs/ilp-cli --node http://alice-node:7770 accounts balance alice --auth hi_alice
printf "Bob's balance: "
docker run --rm --network local-ilp interledgerrs/ilp-cli --node http://alice-node:7770 accounts balance bob --auth hi_alice

printf "\n========= BOB'S NODE ========="
printf "\nAlice's balance: "
docker run --rm --network local-ilp interledgerrs/ilp-cli --node http://bob-node:7770 accounts balance alice --auth hi_bob
printf "Charlie's balance: "
docker run --rm --network local-ilp interledgerrs/ilp-cli --node http://bob-node:7770 accounts balance charlie --auth hi_bob

printf "\n========= CHARLIE'S NODE ========="
printf "\nBob's balance: "
docker run --rm --network local-ilp interledgerrs/ilp-cli --node http://charlie-node:7770 accounts balance bob --auth hi_charlie
printf "Charlie's balance: "
docker run --rm --network local-ilp interledgerrs/ilp-cli --node http://charlie-node:7770 accounts balance charlie --auth hi_charlie
sleep 2
#================================
# VI. Stop services
#================================

docker stop redis ethereum-testnet alice-node bob-node charlie-node alice-eth bob-eth bob-xrp charlie-xrp
docker rm redis ethereum-testnet alice-node bob-node charlie-node alice-eth bob-eth bob-xrp charlie-xrp
docker network rm local-ilp