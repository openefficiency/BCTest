#!/bin/bash

# Exit on first error
set -e

# Print command being executed
set -x

CHANNEL_NAME="mychannel"
DELAY=3
MAX_RETRY=5
COUNTER=1
ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

# Join peer to the channel
joinChannel() {
  ORG=$1
  PEER=$2
  
  setGlobals $ORG $PEER
  
  peer channel join -b ${CHANNEL_NAME}.block
  if [ $? -ne 0 ]; then
    echo "Failed to join peer${PEER}.org${ORG} to channel ${CHANNEL_NAME}"
    exit 1
  fi
  echo "===================== peer${PEER}.org${ORG} joined channel ${CHANNEL_NAME} ====================="
  sleep $DELAY
}

# Set global variables for organization and peer
setGlobals() {
  ORG=$1
  PEER=$2
  
  if [ $ORG -eq 1 ]; then
    CORE_PEER_LOCALMSPID="Org1MSP"
    CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer${PEER}.org1.example.com/tls/ca.crt
    CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
    CORE_PEER_ADDRESS=peer${PEER}.org1.example.com:7051
  elif [ $ORG -eq 2 ]; then
    CORE_PEER_LOCALMSPID="Org2MSP"
    CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/peers/peer${PEER}.org2.example.com/tls/ca.crt
    CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
    CORE_PEER_ADDRESS=peer${PEER}.org2.example.com:9051
  else
    echo "Unknown organization: ${ORG}"
    exit 1
  fi
  
  export CORE_PEER_LOCALMSPID
  export CORE_PEER_TLS_ROOTCERT_FILE
  export CORE_PEER_MSPCONFIGPATH
  export CORE_PEER_ADDRESS
}

# Create the channel
createChannel() {
  setGlobals 1 0
  
  # Check if channel already exists
  peer channel list | grep "^${CHANNEL_NAME}$" > /dev/null
  if [ $? -eq 0 ]; then
    echo "Channel ${CHANNEL_NAME} already exists, skipping creation"
    return
  fi
  
  echo "===================== Creating channel ${CHANNEL_NAME} ====================="
  peer channel create -o orderer.example.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/channel.tx --tls --cafile $ORDERER_CA
  if [ $? -ne 0 ]; then
    echo "Failed to create channel ${CHANNEL_NAME}"
    exit 1
  fi
  echo "===================== Channel ${CHANNEL_NAME} created successfully ====================="
  sleep $DELAY
}

# Update anchor peers for an organization
updateAnchorPeers() {
  ORG=$1
  setGlobals $ORG 0
  
  echo "===================== Updating anchor peers for org${ORG} ====================="
  peer channel update -o orderer.example.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/Org${ORG}MSPanchors.tx --tls --cafile $ORDERER_CA
  if [ $? -ne 0 ]; then
    echo "Failed to update anchor peers for org${ORG}"
    exit 1
  fi
  echo "===================== Anchor peers updated for org${ORG} ====================="
  sleep $DELAY
}

# Fetch channel configuration if needed
fetchChannelConfig() {
  setGlobals 1 0
  
  # Check if channel block already exists
  if [ -f "${CHANNEL_NAME}.block" ]; then
    echo "Channel block ${CHANNEL_NAME}.block already exists, skipping fetch"
    return
  fi
  
  echo "===================== Fetching channel config for channel ${CHANNEL_NAME} ====================="
  peer channel fetch 0 ${CHANNEL_NAME}.block -o orderer.example.com:7050 -c $CHANNEL_NAME --tls --cafile $ORDERER_CA
  if [ $? -ne 0 ]; then
    echo "Failed to fetch channel configuration block"
    exit 1
  fi
  echo "===================== Channel config fetched successfully ====================="
  sleep $DELAY
}

# Main execution
echo "Creating channel '${CHANNEL_NAME}'"
createChannel

echo "Fetching channel config for all peers to join"
fetchChannelConfig

echo "Having all peers join the channel..."
joinChannel 1 0
joinChannel 1 1
joinChannel 2 0
joinChannel 2 1

echo "Updating anchor peers for each org..."
updateAnchorPeers 1
updateAnchorPeers 2

echo "===================== All peers have joined channel '${CHANNEL_NAME}' ====================="
echo "Channel creation and configuration complete"
