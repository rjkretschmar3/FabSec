#!/bin/bash
# Written and maintained by Robert Kretschmar

# This script will create the channel artifacts for creating a new System Channel. A System Channel
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

# So, let's make sure we have the correct number of arguments before moving on. If we do not,
# return a nice message to the user on how to use this script.
if (( $# != 2  & $# != 3)); then
	echo "Incorrect amount of arguments!!";
	echo "Pro-tip: proper use of this script comes in the form of:";
	echo -e "\t$0 <Org ID#> <Orderer ID#> [meta]";
	exit;
fi

# Make sure that the user understands what need to happen before they run this script.
# EDIT: Skip this part for a meta-script
if [[ "$3" != "meta" ]]; then
	read -p "This script needs both Peer Organizations to have been created (up to script 006) \
	so that their respective MSPs can be collected. Otherwise the Genesis Block can't be \
	created! Are you sure the Peer MSPs exist? [y/N] " prompt

	if [[ $prompt != "y" && $prompt != "Y" ]]; then
		echo "Go make them! : )";
		exit;
	fi
fi

# The configtxgen binary uses the environmental variable of FABRIC_CFG_PATH to find its OWN configuration 
# file (talked about in the README.md) named configtx.yaml, so we'll set that to the correct directory 
# after the traversal.
echo "cd ../organizations/ordererOrganizations/org$1.fabsec.com/orderers/orderer$2.org$1.fabsec.com";
cd ../organizations/ordererOrganizations/org$1.fabsec.com/orderers/orderer$2.org$1.fabsec.com;
echo "export FABRIC_CFG_PATH=${PWD}/configtx"
export FABRIC_CFG_PATH=${PWD}/configtx

# Almost ready for the command, just need to grab the MSPs from the Peer Orgs 1 and 2 locally into Orderer
# Org 0 so that the Genesis Block will have the identities for reference.
# EDIT: Also need the Orderer Org MSP
echo "cp -R ../../../../peerOrganizations/org1.fabsec.com/msp ./AllOrgsMSPs/org1/."
cp -R ../../../../peerOrganizations/org1.fabsec.com/msp ./AllOrgsMSPs/org1/.

echo "cp -R ../../../../peerOrganizations/org2.fabsec.com/msp ./AllOrgsMSPs/org2/."
cp -R ../../../../peerOrganizations/org2.fabsec.com/msp ./AllOrgsMSPs/org2/.

echo "cp -R ../../msp ./AllOrgsMSPs/org0/.";
cp -R ../../msp ./AllOrgsMSPs/org0/.

# Now, let's generate the Genesis Block
echo "./configtx/configtxgen -profile FabSecOrdererGenesis -channelID system-channel -outputBlock ../system-genesis-block/genesis.block";
./configtx/configtxgen -profile FabSecOrdererGenesis -channelID system-channel -outputBlock system-genesis-block/genesis.block;
