#!/bin/bash

# deployChaincode.sh
# Script to deploy chaincode to a Hyperledger Fabric network

set -e

# Default values
CHANNEL_NAME="mychannel"
CC_NAME="mycc"
CC_SRC_PATH=""
CC_VERSION="1.0"
CC_SEQUENCE="1"
CC_INIT_FCN="InitLedger"
DELAY="3"
MAX_RETRY="5"
VERBOSE="false"

# Print the usage message
function printHelp() {
  echo "Usage: "
  echo "  deployChaincode.sh [options]"
  echo "    -c <channel name> - Name of channel (default \"mychannel\")"
  echo "    -n <name> - Name of the chaincode (default \"mycc\")"
  echo "    -p <path> - Path to chaincode source code"
  echo "    -v <version> - Chaincode version (default \"1.0\")"
  echo "    -s <sequence> - Chaincode definition sequence (default 1)"
  echo "    -i <init function> - Function to call on init (default \"InitLedger\")"
  echo "    -d <delay> - Delay between commands in seconds (default 3)"
  echo "    -r <max retry> - Maximum retry attempts (default 5)"
  echo "    -l - Enable verbose logging"
  echo "    -h - Print this help message"
  echo
  echo "Example: "
  echo "  deployChaincode.sh -c mychannel -n mycc -p ./chaincode/asset-transfer -v 1.0 -s 1"
}

# Parse command line arguments
while getopts "h?c:n:p:v:s:i:d:r:l" opt; do
  case "$opt" in
  h | \?)
    printHelp
    exit 0
    ;;
  c)
    CHANNEL_NAME=$OPTARG
    ;;
  n)
    CC_NAME=$OPTARG
    ;;
  p)
    CC_SRC_PATH=$OPTARG
    ;;
  v)
    CC_VERSION=$OPTARG
    ;;
  s)
    CC_SEQUENCE=$OPTARG
    ;;
  i)
    CC_INIT_FCN=$OPTARG
    ;;
  d)
    DELAY=$OPTARG
    ;;
  r)
    MAX_RETRY=$OPTARG
    ;;
  l)
    VERBOSE=true
    ;;
  esac
done

# Check if the chaincode path is specified
if [ -z "$CC_SRC_PATH" ]; then
  echo "Error: No chaincode path specified. Use -p flag"
  printHelp
  exit 1
fi

# Source the environment variables
. ./setEnv.sh

# Print configuration
if [ "$VERBOSE" = "true" ]; then
  echo
  echo "========= Chaincode deployment configuration ========="
  echo "Channel name: ${CHANNEL_NAME}"
  echo "Chaincode name: ${CC_NAME}"
  echo "Chaincode path: ${CC_SRC_PATH}"
  echo "Chaincode version: ${CC_VERSION}"
  echo "Chaincode sequence: ${CC_SEQUENCE}"
  echo "Chaincode init function: ${CC_INIT_FCN}"
  echo "==================================================="
  echo
fi

# Package the chaincode
packageChaincode() {
  echo "Packaging chaincode..."
  set -x
  peer lifecycle chaincode package ${CC_NAME}.tar.gz --path ${CC_SRC_PATH} --lang golang --label ${CC_NAME}_${CC_VERSION} >&log.txt
  res=$?
  set +x
  cat log.txt
  if [ $res -ne 0 ]; then
    echo "Error packaging chaincode"
    exit 1
  fi
  echo "Chaincode package created successfully"
}

# Install chaincode on peers
installChaincode() {
  ORG=$1
  echo "Installing chaincode on peer0.org${ORG}..."
  
  # Set environment variables for the peer
  setGlobals $ORG
  
  set -x
  peer lifecycle chaincode install ${CC_NAME}.tar.gz >&log.txt
  res=$?
  set +x
  cat log.txt
  if [ $res -ne 0 ]; then
    echo "Error installing chaincode on peer0.org${ORG}"
    exit 1
  fi
  echo "Chaincode installed successfully on peer0.org${ORG}"
}

# Query if chaincode is installed
queryInstalled() {
  ORG=$1
  echo "Querying installed chaincode on peer0.org${ORG}..."
  
  # Set environment variables for the peer
  setGlobals $ORG
  
  set -x
  peer lifecycle chaincode queryinstalled >&log.txt
  res=$?
  set +x
  cat log.txt
  
  if [ $res -ne 0 ]; then
    echo "Error querying installed chaincode on peer0.org${ORG}"
    exit 1
  fi
  
  # Get the package ID
  PACKAGE_ID=$(sed -n "/${CC_NAME}_${CC_VERSION}/{s/^Package ID: //; s/, Label:.*$//; p;}" log.txt)
  echo "Chaincode package ID: ${PACKAGE_ID}"
  
  if [ -z "$PACKAGE_ID" ]; then
    echo "Error: No package ID found for ${CC_NAME}_${CC_VERSION}"
    exit 1
  fi
}

# Approve chaincode definition for an organization
approveForMyOrg() {
  ORG=$1
  echo "Approving chaincode definition for org${ORG}..."
  
  # Set environment variables for the peer
  setGlobals $ORG
  
  set -x
  peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name ${CC_NAME} --version ${CC_VERSION} --package-id ${PACKAGE_ID} --sequence ${CC_SEQUENCE} >&log.txt
  res=$?
  set +x
  cat log.txt
  
  if [ $res -ne 0 ]; then
    echo "Error approving chaincode definition for org${ORG}"
    exit 1
  fi
  echo "Chaincode definition approved for org${ORG}"
}

# Check commit readiness for chaincode
checkCommitReadiness() {
  ORG=$1
  echo "Checking commit readiness for org${ORG}..."
  
  # Set environment variables for the peer
  setGlobals $ORG
  
  set -x
  peer lifecycle chaincode checkcommitreadiness --channelID $CHANNEL_NAME --name ${CC_NAME} --version ${CC_VERSION} --sequence ${CC_SEQUENCE} --output json >&log.txt
  res=$?
  set +x
  cat log.txt
  
  if [ $res -ne 0 ]; then
    echo "Error checking commit readiness for org${ORG}"
    exit 1
  fi
}

# Commit chaincode definition
commitChaincodeDefinition() {
  echo "Committing chaincode definition to channel..."
  
  # Set environment variables for org1
  setGlobals 1
  
  PEER_CONN_PARMS="--peerAddresses localhost:7051 --tlsRootCertFiles ${PEER0_ORG1_CA}"
  
  # Add org2 peer connection parameters if this is a multi-org deployment
  if [ -f "${PEER0_ORG2_CA}" ]; then
    PEER_CONN_PARMS="${PEER_CONN_PARMS} --peerAddresses localhost:9051 --tlsRootCertFiles ${PEER0_ORG2_CA}"
  fi
  
  set -x
  peer lifecycle chaincode commit -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name ${CC_NAME} --version ${CC_VERSION} --sequence ${CC_SEQUENCE} ${PEER_CONN_PARMS} >&log.txt
  res=$?
  set +x
  cat log.txt
  
  if [ $res -ne 0 ]; then
    echo "Error committing chaincode definition"
    exit 1
  fi
  echo "Chaincode definition committed successfully"
}

# Query committed chaincode
queryCommitted() {
  ORG=$1
  echo "Querying committed chaincode on peer0.org${ORG}..."
  
  # Set environment variables for the peer
  setGlobals $ORG
  
  set -x
  peer lifecycle chaincode querycommitted --channelID $CHANNEL_NAME --name ${CC_NAME} >&log.txt
  res=$?
  set +x
  cat log.txt
  
  if [ $res -ne 0 ]; then
    echo "Error querying committed chaincode"
    exit 1
  fi
}

# Initialize chaincode by invoking init function
chaincodeInvokeInit() {
  echo "Invoking chaincode init function ${CC_INIT_FCN}..."
  
  # Set environment variables for org1
  setGlobals 1
  
  PEER_CONN_PARMS="--peerAddresses localhost:7051 --tlsRootCertFiles ${PEER0_ORG1_CA}"
  
  # Add org2 peer connection parameters if this is a multi-org deployment
  if [ -f "${PEER0_ORG2_CA}" ]; then
    PEER_CONN_PARMS="${PEER_CONN_PARMS} --peerAddresses localhost:9051 --tlsRootCertFiles ${PEER0_ORG2_CA}"
  fi
  
  # If init function is provided, invoke it
  if [ -n "${CC_INIT_FCN}" ]; then
    set -x
    peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile $ORDERER_CA -C $CHANNEL_NAME -n ${CC_NAME} ${PEER_CONN_PARMS} --isInit -c '{"function":"'${CC_INIT_FCN}'","Args":[]}' >&log.txt
    res=$?
    set +x
    cat log.txt
    
    if [ $res -ne 0 ]; then
      echo "Error invoking chaincode init function"
      exit 1
    fi
    echo "Chaincode initialized successfully"
  else
    echo "No init function provided, skipping initialization"
  fi
}

# The main function to deploy the chaincode
main() {
  echo "==== Starting chaincode deployment ===="
  
  # Package the chaincode
  packageChaincode
  
  # Install chaincode on org1 peer
  installChaincode 1
  
  # Query installed chaincode on org1 peer to get package ID
  queryInstalled 1
  
  # Install chaincode on org2 peer if it exists
  if [ -f "${PEER0_ORG2_CA}" ]; then
    installChaincode 2
    queryInstalled 2
  fi
  
  # Approve chaincode definition for org1
  approveForMyOrg 1
  
  # Check commit readiness for org1
  checkCommitReadiness 1
  
  # Approve chaincode definition for org2 if it exists
  if [ -f "${PEER0_ORG2_CA}" ]; then
    approveForMyOrg 2
    checkCommitReadiness 2
  fi
  
  # Commit the chaincode definition
  commitChaincodeDefinition
  
  # Query the committed chaincode
  queryCommitted 1
  
  # Initialize the chaincode
  chaincodeInvokeInit
  
  echo "==== Chaincode deployment completed ===="
}

# Execute the main function
main
