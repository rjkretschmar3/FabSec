#!/bin/bash
# Written and maintained by Robert Kretschmar

# This script will create a the channel artifacts for creating a new System Channel. A System Channel
# is different than the second Channel we will create called the Application Channel. There can be more
# than one Application Channel (something that I'll go into in the Application Channel script), but there
# will only be one System Channel. The System Channel is the first one that needs to be built (i.e. create
# a Genesis Block) since the Orderer will need that block to bootstrap itself. As that block will contain
# all of the configuration data for the Channel. This script will use the use the configtxgen binary to 
# accomplish this task. While the command to invoke the configtxgen binary to build the Genesis Block seems
# simple, it consumes its own configuration file called the configtx.yaml into which a lot of the main decision
# making and work goes. (I talk more about the configtx.yaml file in the README.md.)

# First thing to do is to traverse over to the Orderer Organization where we will be creating our 
# Genesis Block. Unlike the previous scripts, this script doesn't need to know whether it need to go to 
# an Orderer or Peer Organization because the action of creating a new Genesis Block and, in turn, 
# a Channel happens only for an Orderer. However, in the future, I may add the ability for the operator 
# to choose which Orderer Org they will be going to. As it stands now, however, this project only has 
# one Orderer Org making the choice trivial.

# The configtxgen binary uses the environmental variable of FABRIC_CFG_PATH to find its OWN configuration 
# file (talked about in the README.md) named configtx.yaml, so we'll set that to the correct directory 
# after the traversal.
echo "cd ../organizations/ordererOrganiations/org0.fabsec.com/";
echo "export FABRIC_CFG_PATH=${PWD}/configtx"

# Almost ready for the command, just need to grab the MSPs from the Peer Orgs 1 and 2 locally into Orderer
# Org 0 so that the Genesis Block will have the identities for reference.
echo "cp -R ../../peerOrganizations/org1.fabsec.com/msp ./PeerOrgsMSPs/org1/."

echo "cp -R ../../peerOrganizations/org2.fabsec.com/msp ./PeerOrgsMSPs/org2/."

# Now, let's generate the Genesis Block
echo "./configtx/configtxgen -profile FabSecOrdererGenesis -channelID system-channel -outputBlock ../system-genesis-block/genesis.block";
./configtx/configtxgen -profile FabSecOrdererGenesis -channelID system-channel -outputBlock ../system-genesis-block/genesis.block;
