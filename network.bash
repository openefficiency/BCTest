#!/bin/bash

# network-setup.sh - Script to set up the Hyperledger Fabric network for the Whistleblower Application

# Stop and remove any existing containers and volumes
function cleanUp() {
    echo "Cleaning up existing containers and volumes..."
    docker-compose -f docker-compose.yaml down --volumes --remove-orphans
    docker container prune -f
    docker volume prune -f
    rm -rf organizations/peerOrganizations
    rm -rf organizations/ordererOrganizations
    rm -rf channel-artifacts
}

# Create directories for artifacts
function createDirectories() {
    echo "Creating directories for artifacts..."
    mkdir -p organizations/peerOrganizations
    mkdir -p organizations/ordererOrganizations
    mkdir -p channel-artifacts
}

# Generate crypto material
function generateCrypto() {
    echo "Generating crypto material..."
    cryptogen generate --config=./crypto-config.yaml --output="organizations"
}

# Generate genesis block
function generateGenesisBlock() {
    echo "Generating genesis block..."
    configtxgen -profile TwoOrgsOrdererGenesis -channelID system-channel -outputBlock ./channel-artifacts/genesis.block
}

# Create channel transaction
function createChannelTx() {
    echo "Creating channel transaction..."
    configtxgen -profile TwoOrgsChannel -outputCreateChannelTx ./channel-artifacts/whistleblowerchannel.tx -channelID whistleblowerchannel
}

# Create anchor peer transactions
function createAnchorPeerTx() {
    echo "Creating anchor peer transactions..."
    configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/DoEMSPanchors.tx -channelID whistleblowerchannel -asOrg DoEMSP
    configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/DoGEMSPanchors.tx -channelID whistleblowerchannel -asOrg DoGEMSP
}

# Start the network
function startNetwork() {
    echo "Starting the Hyperledger Fabric network..."
    docker-compose -f docker-compose.yaml up -d
}

# Create and join the channel
function createAndJoinChannel() {
    echo "Creating and joining the channel..."
    docker exec cli peer channel create -o orderer.example.com:7050 -c whistleblowerchannel -f /etc/hyperledger/configtx/whistleblowerchannel.tx --tls --cafile /etc/hyperledger/orderer/tls/ca.crt
    
    # Peer0 of DoE joins the channel
    docker exec -e CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@doe.example.com/msp \
                -e CORE_PEER_ADDRESS=peer0.doe.example.com:7051 \
                -e CORE_PEER_LOCALMSPID="DoEMSP" \
                -e CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/peer/tls/ca.crt \
                cli peer channel join -b whistleblowerchannel.block
    
    # Peer0 of DoGE joins the channel
    docker exec -e CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@doge.example.com/msp \
                -e CORE_PEER_ADDRESS=peer0.doge.example.com:9051 \
                -e CORE_PEER_LOCALMSPID="DoGEMSP" \
                -e CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/peer/tls/ca.crt \
                cli peer channel join -b whistleblowerchannel.block
}

# Update anchor peers
function updateAnchorPeers() {
    echo "Updating anchor peers..."
    # Update anchor peers for DoE
    docker exec -e CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@doe.example.com/msp \
                -e CORE_PEER_ADDRESS=peer0.doe.example.com:7051 \
                -e CORE_PEER_LOCALMSPID="DoEMSP" \
                -e CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/peer/tls/ca.crt \
                cli peer channel update -o orderer.example.com:7050 -c whistleblowerchannel -f /etc/hyperledger/configtx/DoEMSPanchors.tx --tls --cafile /etc/hyperledger/orderer/tls/ca.crt
    
    # Update anchor peers for DoGE
    docker exec -e CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@doge.example.com/msp \
                -e CORE_PEER_ADDRESS=peer0.doge.example.com:9051 \
                -e CORE_PEER_LOCALMSPID="DoGEMSP" \
                -e CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/peer/tls/ca.crt \
                cli peer channel update -o orderer.example.com:7050 -c whistleblowerchannel -f /etc/hyperledger/configtx/DoGEMSPanchors.tx --tls --cafile /etc/hyperledger/orderer/tls/ca.crt
}

# Install and instantiate chaincode
function deployChaincode() {
    echo "Packaging chaincode..."
    pushd ../chaincode/whistleblower
    GO111MODULE=on go mod vendor
    popd
    
    echo "Installing chaincode on DoE peer..."
    docker exec -e CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@doe.example.com/msp \
                -e CORE_PEER_ADDRESS=peer0.doe.example.com:7051 \
                -e CORE_PEER_LOCALMSPID="DoEMSP" \
                -e CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/peer/tls/ca.crt \
                cli peer lifecycle chaincode package whistleblower.tar.gz --path /opt/gopath/src/github.com/chaincode/whistleblower --lang java --label whistleblower_1.0
    
    docker exec -e CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@doe.example.com/msp \
                -e CORE_PEER_ADDRESS=peer0.doe.example.com:7051 \
                -e CORE_PEER_LOCALMSPID="DoEMSP" \
                -e CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/peer/tls/ca.crt \
                cli peer lifecycle chaincode install whistleblower.tar.gz
    
    echo "Installing chaincode on DoGE peer..."
    docker exec -e CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@doge.example.com/msp \
                -e CORE_PEER_ADDRESS=peer0.doge.example.com:9051 \
                -e CORE_PEER_LOCALMSPID="DoGEMSP" \
                -e CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/peer/tls/ca.crt \
                cli peer lifecycle chaincode install whistleblower.tar.gz
    
    echo "Getting package ID..."
    CC_PACKAGE_ID=$(docker exec -e CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@doe.example.com/msp \
                -e CORE_PEER_ADDRESS=peer0.doe.example.com:7051 \
                -e CORE_PEER_LOCALMSPID="DoEMSP" \
                -e CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/peer/tls/ca.crt \
                cli peer lifecycle chaincode queryinstalled | grep whistleblower_1.0 | awk '{print $3}' | sed 's/,//')
    
    echo "Approving chaincode by DoE..."
    docker exec -e CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@doe.example.com/msp \
                -e CORE_PEER_ADDRESS=peer0.doe.example.com:7051 \
                -e CORE_PEER_LOCALMSPID="DoEMSP" \
                -e CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/peer/tls/ca.crt \
                cli peer lifecycle chaincode approveformyorg -o orderer.example.com:7050 --tls --cafile /etc/hyperledger/orderer/tls/ca.crt --channelID whistleblowerchannel --name whistleblower --version 1.0 --package-id $CC_PACKAGE_ID --sequence 1
    
    echo "Approving chaincode by DoGE..."
    docker exec -e CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@doge.example.com/msp \
                -e CORE_PEER_ADDRESS=peer0.doge.example.com:9051 \
                -e CORE_PEER_LOCALMSPID="DoGEMSP" \
                -e CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/peer/tls/ca.crt \
                cli peer lifecycle chaincode approveformyorg -o orderer.example.com:7050 --tls --cafile /etc/hyperledger/orderer/tls/ca.crt --channelID whistleblowerchannel --name whistleblower --version 1.0 --package-id $CC_PACKAGE_ID --sequence 1
    
    echo "Committing chaincode definition..."
    docker exec -e CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@doe.example.com/msp \
                -e CORE_PEER_ADDRESS=peer0.doe.example.com:7051 \
                -e CORE_PEER_LOCALMSPID="DoEMSP" \
                -e CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/peer/tls/ca.crt \
                cli peer lifecycle chaincode commit -o orderer.example.com:7050 --tls --cafile /etc/hyperledger/orderer/tls/ca.crt --channelID whistleblowerchannel --name whistleblower --version 1.0 --sequence 1 --peerAddresses peer0.doe.example.com:7051 --tlsRootCertFiles /etc/hyperledger/peer/tls/ca.crt --peerAddresses peer0.doge.example.com:9051 --tlsRootCertFiles /etc/hyperledger/peer/doge/tls/ca.crt
    
    echo "Initializing chaincode..."
    docker exec -e CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@doe.example.com/msp \
                -e CORE_PEER_ADDRESS=peer0.doe.example.com:7051 \
                -e CORE_PEER_LOCALMSPID="DoEMSP" \
                -e CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/peer/tls/ca.crt \
                cli peer chaincode invoke -o orderer.example.com:7050 --tls --cafile /etc/hyperledger/orderer/tls/ca.crt --channelID whistleblowerchannel --name whistleblower --peerAddresses peer0.doe.example.com:7051 --tlsRootCertFiles /etc/hyperledger/peer/tls/ca.crt --peerAddresses peer0.doge.example.com:9051 --tlsRootCertFiles /etc/hyperledger/peer/doge/tls/ca.crt -c '{"function":"initLedger","Args":[]}'
}

# Generate connection profiles
function generateConnectionProfiles() {
    echo "Generating connection profiles..."
    mkdir -p connection-profiles
    
    # Generate DoE connection profile
    cat > connection-profiles/doe-connection.json << EOF
{
    "name": "whistleblower-network-doe",
    "version": "1.0.0",
    "client": {
        "organization": "DoE",
        "connection": {
            "timeout": {
                "peer": {
                    "endorser": "300"
                },
                "orderer": "300"
            }
        }
    },
    "organizations": {
        "DoE": {
            "mspid": "DoEMSP",
            "peers": [
                "peer0.doe.example.com"
            ],
            "certificateAuthorities": [
                "ca.doe.example.com"
            ]
        }
    },
    "peers": {
        "peer0.doe.example.com": {
            "url": "grpcs://localhost:7051",
            "tlsCACerts": {
                "path": "organizations/peerOrganizations/doe.example.com/peers/peer0.doe.example.com/tls/ca.crt"
            },
            "grpcOptions": {
                "ssl-target-name-override": "peer0.doe.example.com",
                "hostnameOverride": "peer0.doe.example.com"
            }
        }
    },
    "certificateAuthorities": {
        "ca.doe.example.com": {
            "url": "https://localhost:7054",
            "caName": "ca-doe",
            "tlsCACerts": {
                "path": "organizations/peerOrganizations/doe.example.com/ca/ca.doe.example.com-cert.pem"
            },
            "httpOptions": {
                "verify": false
            }
        }
    }
}
EOF

    # Generate DoGE connection profile
    cat > connection-profiles/doge-connection.json << EOF
{
    "name": "whistleblower-network-doge",
    "version": "1.0.0",
    "client": {
        "organization": "DoGE",
        "connection": {
            "timeout": {
                "peer": {
                    "endorser": "300"
                },
                "orderer": "300"
            }
        }
    },
    "organizations": {
        "DoGE": {
            "mspid": "DoGEMSP",
            "peers": [
                "peer0.doge.example.com"
            ],
            "certificateAuthorities": [
                "ca.doge.example.com"
            ]
        }
    },
    "peers": {
        "peer0.doge.example.com": {
            "url": "grpcs://localhost:9051",
            "tlsCACerts": {
                "path": "organizations/peerOrganizations/doge.example.com/peers/peer0.doge.example.com/tls/ca.crt"
            },
            "grpcOptions": {
                "ssl-target-name-override": "peer0.doge.example.com",
                "hostnameOverride": "peer0.doge.example.com"
            }
        }
    },
    "certificateAuthorities": {
        "ca.doge.example.com": {
            "url": "https://localhost:8054",
            "caName": "ca-doge",
            "tlsCACerts": {
                "path": "organizations/peerOrganizations/doge.example.com/ca/ca.doge.example.com-cert.pem"
            },
            "httpOptions": {
                "verify": false
            }
        }
    }
}
EOF
}

# Generate wallets
function generateWallets() {
    echo "Generating wallets..."
    mkdir -p wallets/doe
    mkdir -p wallets/doge
    
    # Will require the Fabric SDK operations to actually enroll users and create wallets
    # This is typically done through a separate enrollment script
}

# Main execution
cleanUp
createDirectories
generateCrypto
generateGenesisBlock
createChannelTx
createAnchorPeerTx
startNetwork
sleep 10
createAndJoinChannel
updateAnchorPeers
deployChaincode
generateConnectionProfiles
generateWallets

echo "Network setup complete!"
