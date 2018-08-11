#!/bin/bash

echo
echo " ____    _____      _      ____    _____ "
echo "/ ___|  |_   _|    / \    |  _ \  |_   _|"
echo "\___ \    | |     / _ \   | |_) |   | |  "
echo " ___) |   | |    / ___ \  |  _ <    | |  "
echo "|____/    |_|   /_/   \_\ |_| \_\   |_|  "
echo
echo "Build your first network (BYFN) end-to-end test"
echo
CHANNEL_NAME="$1"
DELAY="$2"
LANGUAGE="$3"
TIMEOUT="$4"
: ${CHANNEL_NAME:="mychannel"}
: ${DELAY:="3"}
: ${LANGUAGE:="golang"}
: ${TIMEOUT:="10"}
LANGUAGE=`echo "$LANGUAGE" | tr [:upper:] [:lower:]`
COUNTER=1
MAX_RETRY=5
ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/blockchain.com/orderers/orderer.blockchain.com/msp/tlscacerts/tlsca.blockchain.com-cert.pem

CC_SRC_PATH="github.com/chaincode/chaincode_example02/go/"
if [ "$LANGUAGE" = "node" ]; then
	CC_SRC_PATH="/opt/gopath/src/github.com/chaincode/chaincode_example02/node/"
fi

echo "Channel name : "$CHANNEL_NAME

# import utils
. scripts/utils.sh

createChannel() {
	setGlobals 0 1

	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
                set -x
		peer channel create -o orderer.blockchain.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/channel.tx >&log.txt
		res=$?
                set +x
	else
				set -x
		peer channel create -o orderer.blockchain.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/channel.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA >&log.txt
		res=$?
				set +x
	fi
	cat log.txt
	verifyResult $res "Channel creation failed"
	echo "===================== Channel \"$CHANNEL_NAME\" is created successfully ===================== "
	echo
}

joinChannel () {
	for org in 1 2; do
	    for peer in 0 1; do
		joinChannelWithRetry $peer $org
		echo "===================== peer${peer}.org${org} joined on the channel \"$CHANNEL_NAME\" ===================== "
		sleep $DELAY
		echo
	    done
	done
}

## Create channel
echo "Creating channel..."
createChannel

## Join all the peers to the channel
echo "Having all peers join the channel..."
joinChannel

## Set the anchor peers for each org in the channel
echo "Updating anchor peers for importer..."
updateAnchorPeers 0 1
echo "Updating anchor peers for exporter..."
updateAnchorPeers 0 2
echo "Updating anchor peers for importerbank..."
updateAnchorPeers 0 3
echo "Updating anchor peers for exporterbank..."
updateAnchorPeers 0 4
echo "Updating anchor peers for custom..."
updateAnchorPeers 0 5

## Install chaincode on peer0.importer, peer0.exporter , peer0.importerbank ,peer0.exporterbank and peer0.custom
echo "Installing chaincode on peer0.importer..."
#installChaincode 0 1
echo "Install chaincode on peer0.exporter..."
#installChaincode 0 2
echo "Installing chaincode on peer0.importerbank..."
#installChaincode 0 3
echo "Install chaincode on peer0.exporterbank..."
#installChaincode 0 4
echo "Installing chaincode on peer0.custom..."
#installChaincode 0 5


# Instantiate chaincode on peer0.exporter
echo "Instantiating chaincode on peer0.exporter..."
#instantiateChaincode 0 2

# Query chaincode on peer0.importer
echo "Querying chaincode on peer0.importer..."
#chaincodeQuery 0 1 100

# Invoke chaincode on peer0.importer
echo "Sending invoke transaction on peer0.importer..."
#chaincodeInvoke 0 1

## Install chaincode on peer1.exporter
echo "Installing chaincode on peer1.exporter..."
#installChaincode 1 2

# Query on chaincode on peer1.exporter, check if the result is 90
echo "Querying chaincode on peer1.exporter..."
#chaincodeQuery 1 2 90

echo
echo "========= All GOOD, BYFN execution completed =========== "
echo

echo
echo " _____   _   _   ____   "
echo "| ____| | \ | | |  _ \  "
echo "|  _|   |  \| | | | | | "
echo "| |___  | |\  | | |_| | "
echo "|_____| |_| \_| |____/  "
echo

exit 0