#!/bin/bash

# Exit on first error
set -e

# Print command being executed
set -x

# Generate cryptographic material using cryptogen
function generateCrypto() {
  which cryptogen
  if [ "$?" -ne 0 ]; then
    echo "cryptogen tool not found. Ensure Hyperledger Fabric binaries are in your PATH"
    exit 1
  fi
  
  echo "##### Generating crypto material using cryptogen #####"
  
  if [ -d "crypto-config" ]; then
    rm -rf crypto-config
  fi
  
  cryptogen generate --config=./crypto-config.yaml
  if [ "$?" -ne 0 ]; then
    echo "Failed to generate crypto material..."
    exit 1
  fi
  
  echo "##### Crypto material generation completed successfully #####"
}

# Generate the orderer genesis block
function generateGenesisBlock() {
  which configtxgen
  if [ "$?" -ne 0 ]; then
    echo "configtxgen tool not found. Ensure Hyperledger Fabric binaries are in your PATH"
    exit 1
  fi
  
  echo "##### Generating Orderer Genesis block #####"
  
  # Create the genesis block directory if it doesn't exist
  mkdir -p channel-artifacts
  
  configtxgen -profile TwoOrgsOrdererGenesis -channelID system-channel -outputBlock ./channel-artifacts/genesis.block
  if [ "$?" -ne 0 ]; then
    echo "Failed to generate orderer genesis block..."
    exit 1
  fi
  
  echo "##### Orderer genesis block generation completed successfully #####"
}

# Generate channel configuration transaction
function generateChannelConfig() {
  which configtxgen
  if [ "$?" -ne 0 ]; then
    echo "configtxgen tool not found. Ensure Hyperledger Fabric binaries are in your PATH"
    exit 1
  fi
  
  echo "##### Generating channel configuration transaction #####"
  
  configtxgen -profile TwoOrgsChannel -outputCreateChannelTx ./channel-artifacts/channel.tx -channelID mychannel
  if [ "$?" -ne 0 ]; then
    echo "Failed to generate channel configuration transaction..."
    exit 1
  fi
  
  echo "##### Channel configuration transaction generation completed successfully #####"
}

# Generate anchor peer transactions for each organization
function generateAnchorPeers() {
  which configtxgen
  if [ "$?" -ne 0 ]; then
    echo "configtxgen tool not found. Ensure Hyperledger Fabric binaries are in your PATH"
    exit 1
  fi
  
  echo "##### Generating anchor peer update transactions #####"
  
  configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org1MSPanchors.tx -channelID mychannel -asOrg Org1MSP
  if [ "$?" -ne 0 ]; then
    echo "Failed to generate anchor peer update for Org1MSP..."
    exit 1
  fi
  
  configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org2MSPanchors.tx -channelID mychannel -asOrg Org2MSP
  if [ "$?" -ne 0 ]; then
    echo "Failed to generate anchor peer update for Org2MSP..."
    exit 1
  fi
  
  echo "##### Anchor peer update transactions generation completed successfully #####"
}

# Main execution
echo "==== Starting crypto material generation ===="
generateCrypto
echo "==== Starting genesis block generation ===="
generateGenesisBlock
echo "==== Starting channel configuration transaction generation ===="
generateChannelConfig
echo "==== Starting anchor peer transactions generation ===="
generateAnchorPeers
echo "==== All artifacts generated successfully ===="
