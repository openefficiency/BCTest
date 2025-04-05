#!/bin/bash

# generateChannelArtifacts.sh - Script to generate channel artifacts for the Whistleblower Application

# Exit on first error
set -e

# Print command being executed
set -x

# Variables
CHANNEL_NAME="whistleblowerchannel"
PROFILE_ORDERER="TwoOrgsOrdererGenesis"
PROFILE_CHANNEL="TwoOrgsChannel"
SYSTEM_CHANNEL="system-channel"

# Check if configtxgen exists
which configtxgen
if [ "$?" -ne 0 ]; then
  echo "Error: configtxgen tool not found. Ensure Hyperledger Fabric binaries are in your PATH"
  echo "You can download the binaries from https://hyperledger-fabric.readthedocs.io/en/latest/install.html"
  exit 1
fi

# Create channel artifacts directory
mkdir -p channel-artifacts

# Generate genesis block for orderer
echo "========= Generating Orderer Genesis Block ========="
configtxgen -profile ${PROFILE_ORDERER} -channelID ${SYSTEM_CHANNEL} -outputBlock ./channel-artifacts/genesis.block
if [ "$?" -ne 0 ]; then
  echo "Error: Failed to generate orderer genesis block"
  exit 1
fi
echo "========= Orderer Genesis Block generated successfully ========="

# Generate channel creation transaction
echo "========= Generating Channel Creation Transaction ========="
configtxgen -profile ${PROFILE_CHANNEL} -outputCreateChannelTx ./channel-artifacts/${CHANNEL_NAME}.tx -channelID ${CHANNEL_NAME}
if [ "$?" -ne 0 ]; then
  echo "Error: Failed to generate channel configuration transaction"
  exit 1
fi
echo "========= Channel Creation Transaction generated successfully ========="

# Generate anchor peer update transactions
echo "========= Generating Anchor Peer Update Transactions ========="

# For DoE (Department of Education)
configtxgen -profile ${PROFILE_CHANNEL} -outputAnchorPeersUpdate ./channel-artifacts/DoEMSPanchors.tx -channelID ${CHANNEL_NAME} -asOrg DoEMSP
if [ "$?" -ne 0 ]; then
  echo "Error: Failed to generate anchor peer update for DoEMSP"
  exit 1
fi
echo "========= Anchor Peer Update Transaction for DoE generated successfully ========="

# For DoGE (Department of Government Efficiency)
configtxgen -profile ${PROFILE_CHANNEL} -outputAnchorPeersUpdate ./channel-artifacts/DoGEMSPanchors.tx -channelID ${CHANNEL_NAME} -asOrg DoGEMSP
if [ "$?" -ne 0 ]; then
  echo "Error: Failed to generate anchor peer update for DoGEMSP"
  exit 1
fi
echo "========= Anchor Peer Update Transaction for DoGE generated successfully ========="

# Display results
echo "========= Channel Artifacts Generation Completed ========="
echo "Genesis block: ./channel-artifacts/genesis.block"
echo "Channel creation transaction: ./channel-artifacts/${CHANNEL_NAME}.tx"
echo "DoE anchor peer update transaction: ./channel-artifacts/DoEMSPanchors.tx"
echo "DoGE anchor peer update transaction: ./channel-artifacts/DoGEMSPanchors.tx"
echo "========================================================"

# Make the script executable
chmod +x generateChannelArtifacts.sh

# Instructions for next steps
echo ""
echo "Next steps:"
echo "1. Place the generated artifacts in the correct directories"
echo "2. Start the network with './network.sh up'"
echo "3. Create the channel with './network.sh createChannel'"
echo "4. Deploy the chaincode with './network.sh deployCC'"
