#!/bin/bash
# Written and maintained by Robert Kretschmar

# This script will designate the anchor peers for an organization. As a little editorial note, I'm not
# entirely sure why this has to be an explicit step, as we designate these peers in the configtx.yaml
# file. But without these commands, they do not register in the channel. The steps involve pulling the
# channel configuration block from the blockchain, adding the proper stanzas through the configtxlator
# with some 'jq' magic, and updating the channel through the peers.

# Since we need to do this for each peer, I'll let a meta-script take care of calling this script, and
# make this general here taking in commandline arguments for exactly which peer we are talking about as 
# well as which organization that peer is under.
if (( $# != 2 )); then
	echo "Incorrect amount of arguments!!";
	echo "Pro-tip: proper use of this script comes in the form of:";
	echo -e "\t$0 <Org ID#> <Peer ID#>";
	exit;
fi

# Now, traverse to the proper directory...
echo "cd ../organizations/peerOrganizations/org$1.fabsec.com/peers/peer$2.org$1.fabsec.com";
cd ../organizations/peerOrganizations/org$1.fabsec.com/peers/peer$2.org$1.fabsec.com;

# This is a switch to change the Anchor Peer's port number depending on which organization we are 
# currently setting this up for. 6051 for Org1 and 6053 for Org 2 (since they just have one Anchor
# Peer each).
if (( $1 == 1 )); then
        ANCHORPORT=6051;
elif (( $1 == 2 )); then
        ANCHORPORT=6053
else
        echo "There are currently only two Peer Organizations.";
        exit;
fi

# I talked about this in greater detail in 012, but to find the core.yaml config file, I'll set the
# FABRIC_CFG_PATH to the PWD. 
echo "export FABRIC_CFG_PATH=$PWD";
export FABRIC_CFG_PATH=$PWD;

# First thing we need to do is grab the channel configuration block. Instead of messing with the original
# genesis block, as well as to make this more general, we'll grab the most recent one.
echo "./peer channel fetch config channel-artifacts/config_block.pb -o orderer0.org0.fabsec.com:6050 "\
	"-c fabsec-channel --tls --cafile AllOrgsMSPs/org0/msp/tlscacerts/org0-tls-ca-cert.pem";
./peer channel fetch config ./channel-artifacts/config-block.pb -o orderer0.org0.fabsec.com:6050 -c \
	fabsec-channel --tls --cafile AllOrgsMSPs/org0/msp/tlscacerts/org0-tls-ca-cert.pem

# Let's move to the channel-artifact directory to do our work.
echo "cd ./channel-artifacts"
cd ./channel-artifacts/

# Now, we have to decode the block from its native "protobuf" format into JSON that we can more easily edit,
# as well as strip away the information that we don't need from the new block JSON file, and then create a
# copy to edit. (This original block JSON file will be used later.)
echo "../configtx/configtxlator proto_decode --input config-block.pb --type common.Block "\
	"--output config-block.json";
../configtx/configtxlator proto_decode --input config-block.pb --type common.Block --output config-block.json
echo "jq '.data.data[0].payload.data.config' config-block.json > config.json"
jq '.data.data[0].payload.data.config' config-block.json > config.json
echo "cp config.json new-config.json"
cp config.json new-config.json

# Now, we use jq to add the new anchor peers data. NOTE: I have to jump through some hoops with an 'if' statement
# here, because I somehow have a variable inside a quote inside a jq tag, and it's just too much for jq to handle.
echo "jq '.channel_group.groups.Application.groups.\"org$1.fabsec.com\".values += {\"AnchorPeers\":{\"mod_policy"\
	"\": \"Admins\", \"value\":{\"anchor_peers\": [{\"host\": \"peer0.org$1.fabsec.com\", \"port\": "\
	"$ANCHORPORT}]}, \"version\": \"0\"}}' new-config.json > modified-config.json";
if (( $1 == 1 )); then
	jq --argjson ap $ANCHORPORT --arg host peer0.org$1.fabsec.com \
		'.channel_group.groups.Application.groups."org1.fabsec.com".values+= {"AnchorPeers":{"mod_policy": "Admins", "value":{"anchor_peers": [{"host": $host, "port": $ap}]}, "version": "0"}}' new-config.json > modified-config.json
elif (($1 == 2 )); then
	jq --argjson ap $ANCHORPORT --arg host peer0.org$1.fabsec.com \
		'.channel_group.groups.Application.groups."org2.fabsec.com".values+= {"AnchorPeers":{"mod_policy": "Admins", "value":{"anchor_peers": [{"host": $host, "port": $ap}]}, "version": "0"}}' new-config.json > modified-config.json
fi

# Now we can take the original JSON config and the modified JSON config, re-profobuf them, and then compute the
# update protobuf version.
echo "../configtx/configtxlator proto_encode --input config.json --type common.Config --output config.pb"
../configtx/configtxlator proto_encode --input config.json --type common.Config --output config.pb
echo "../configtx/configtxlator proto_encode --input modified-config.json --type common.Config --output modified-config.pb"
../configtx/configtxlator proto_encode --input modified-config.json --type common.Config --output modified-config.pb
echo "../configtx/configtxlator compute_update --channel_id fabsec-channel --original config.pb --updated modified-config.pb "\
	"--output config-update.pb"
../configtx/configtxlator compute_update --channel_id fabsec-channel --original config.pb --updated modified-config.pb --output config-update.pb

# Penultimately, we need to decode the new protobuffed updated config, wrap it in what they call an "envelope", and then re-encode it.
echo "../configtx/configtxlator proto_decode --input config-update.pb --type common.ConfigUpdate --output config-update.json";
../configtx/configtxlator proto_decode --input config-update.pb --type common.ConfigUpdate --output config-update.json
echo "echo '{\"payload\":{\"header\":{\"channel_header\":{\"channel_id\": \"fabsec-channel\", \"type\": 2}},\"data\":{\"config_update\""\
	":'$(cat config-update.json)'}}}' | jq . > config-update-in-envelope.json";
echo '{"payload":{"header":{"channel_header":{"channel_id": "fabsec-channel", "type": 2}},"data":{"config_update":'$(cat config-update.json)'}}}' | \
	jq . > config-update-in-envelope.json
echo "../configtx/configtxlator proto_encode --input config-update-in-envelope.json --type common.Envelope --output config-update-in-envelope.pb";
../configtx/configtxlator proto_encode --input config-update-in-envelope.json --type common.Envelope --output config-update-in-envelope.pb

# And then finally, back out of the configtx directory, become the admin through exporting the MSP, and use the peer command to update the channel
echo "cd ..";
cd ..
echo "export CORE_PEER_MSPCONFIGPATH=$PWD/../../msp";
export CORE_PEER_MSPCONFIGPATH=$PWD/../../msp
echo "./peer channel update -f channel-artifacts/config-update-in-envelope.pb -c fabsec-channel -o orderer0.org0.fabsec.com:6050 --tls "\
	"--cafile AllOrgsMSPs/org0/msp/tlscacerts/org0-tls-ca-cert.pem";
./peer channel update -f channel-artifacts/config-update-in-envelope.pb -c fabsec-channel -o orderer0.org0.fabsec.com:6050 --tls \
	--cafile AllOrgsMSPs/org0/msp/tlscacerts/org0-tls-ca-cert.pem
