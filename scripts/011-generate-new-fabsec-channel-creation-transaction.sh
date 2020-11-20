#!/bin/bash
# Written and maintained by Robert Kretschmar

# This script will create the channel artifact for creating a new Application Channel. For the purposes
# of this project, I will call this channel FabSec. However, in production it should have a name that
# reflects its use.

# Unlike the System Channel Genesis Block that was built over in the Orderer Organization, this is the
# start of connecting up the Peers, so it will take place in the Peer Organization 1. Only one Peer Org
# needs to create the channel (and subsequently "create" the channel through the `peer` binary). The
# other Peers will then "join" through their binaries. (Something I'll talk about more in the peer join
# scripts.)

# First thing to do is to traverse over to the Peer Organization where we will be creating our Channel
# Creation Transaction. Here I will hardcore that this creation action will take place in Peer Org 1. 
# Also, we'll need to set the FABRIC_CFG_PATH so that `configtxgen` can find its configuration file.
echo "cd ../organizations/peerOrganizations/org1.fabsec.com/peers/peer0.org1.fabsec.com";
cd ../organizations/peerOrganizations/org1.fabsec.com/peers/peer0.org1.fabsec.com
echo "export FABRIC_CFG_PATH=${PWD}/configtx";
export FABRIC_CFG_PATH=${PWD}/configtx

# Also, we need the PeerOrgsMSPs for Channel Creation as well, so let's copy that over.
cp -R ../../../../ordererOrganizations/org0.fabsec.com/orderers/orderer0.org0.fabsec.com/AllOrgsMSPs/ \
	./

# Now, let's create the Channel Creation Transaction!
echo "./configtx/configtxgen -profile FabSecChannel -channelID fabsec-channel -outputCreateChannelTx " \
	"./channel-artifacts/fabsec-channel.tx";
./configtx/configtxgen -profile FabSecChannel -channelID fabsec-channel -outputCreateChannelTx ./channel-artifacts/fabsec-channel.tx
