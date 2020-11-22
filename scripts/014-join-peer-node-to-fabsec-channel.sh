#!/bin/bash
# Written and maintained by Robert Kretschmar

# This is the script to join a peer to the fabsec-channel. Again, since most of the information needed
# is already in the core.yaml, for the peer, and now in the fabsec-channel.block, for the channel, this
# will be a rather simple script. Nice to have for the meta-scripts and general script flow, though.

# Since this is another general script, we'll take in commandline arguments for exacting which peer
# we are talking about as well as which organization that peer is under.
if (( $# != 2 )); then
	echo "Incorrect amount of arguments!!";
	echo "Pro-tip: proper use of this script comes in the form of:";
	echo -e "\t$0 <Org ID#> <Peer ID#>";
	exit;
fi

# Now, transverse to the proper directory...
echo "cd ../organizations/peerOrganizations/org$1.fabsec.com/peers/peer$2.org$1.fabsec.com";
cd ../organizations/peerOrganizations/org$1.fabsec.com/peers/peer$2.org$1.fabsec.com;

# I talked about this in greater detail in 012, but to find the core.yaml config file, I'll set the
# FABRIC_CFG_PATH to the PWD. And since the peer command to join need to be run as an admin, we'll
# set CORE_PEER_MSPCONFIGPATH to the admin's MSP ../../msp.
echo "export FABRIC_CFG_PATH=$PWD";
export FABRIC_CFG_PATH=$PWD;
echo "export CORE_PEER_MSPCONFIGPATH=$PWD/../../msp";
export CORE_PEER_MSPCONFIGPATH=$PWD/../../msp;

# One major thing is if we're not the peer that generated the fabsec-channel block (which is only
# peer0.org1), we will have to fetch for block from the orderer to join.
# The test checks to see if we're not in organization 1 (which means we're not the generator).
if (( $1 != 1 )); then
	# This 0 in the fetch subcommand is just saying we want the genesis block (block 0).
	echo "./peer channel fetch 0 ./channel-artifacts/fabsec-channel.block -o orderer0.org0.fabsec.com:6050 "\
		"-c fabsec-channel --tls --cafile ./orderer-tls-root-cert/tls-ca-cert.pem";
	./peer channel fetch 0 ./channel-artifacts/fabsec-channel.block -o orderer0.org0.fabsec.com:6050 \
		-c fabsec-channel --tls --cafile ./orderer-tls-root-cert/tls-ca-cert.pem
fi

# Aaaand we're ready to join!
echo "./peer channel join -b ./channel-artifacts/fabsec-channel.block"
./peer channel join -b ./channel-artifacts/fabsec-channel.block;
