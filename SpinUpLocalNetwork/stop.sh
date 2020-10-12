#!/bin/bash

# tutorial: https://interledger.org/spin-up-local-network.html

#================================
# VI. Stop services
#================================

docker stop redis ethereum-testnet alice-node bob-node charlie-node alice-eth bob-eth bob-xrp charlie-xrp
docker rm redis ethereum-testnet alice-node bob-node charlie-node alice-eth bob-eth bob-xrp charlie-xrp
docker network rm local-ilp