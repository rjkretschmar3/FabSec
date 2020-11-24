#!/bin/bash
# Written and maintained by Robert Kretschmar

# Here is where we come a little fuller circle with this project. This script will deploy the log aggregator 
# chaincode that will run on the peers. Chaincode deployment for Fabric is a whole beast -- as much as the
# developers tried to make it easy for the end user whether that be Operator or Developer. One of the big
# headaches was sifting through current and deprecated versions. From Hyperledger Fabric 1.4 to 2.2, there was
# a major change in how chaincode is deployed to a Channel. I won't go in to the old way, but suffice it to
# say there isn't a lot of information on the new way.

# That being said, with 2.2, there is the idea of the Chaincode Lifecycle. This allows all Organizations that
# belong to a certain channel to approve of the chaincode before it can be run. I'll go more in depth with this
# in the README/Final Paper, but the overarching "steps" of a Lifecycle-style Chaincode Deployment are:
#	1) Packaging the Chaincode
#	2) Installing the Chaincode on the Peers
#	3) Approving the Chaincode "Definition" for Each Organization
#	4) Committing the Chaincode Definition to the Channel
# I'll definitely go into these steps in my supporting material, but I'll also give little descriptions as
# each on comes up in this script.

# First, let's traverse to the correct directory: Peer0 of Organization 1. While I could do this on any
# peer of any Organization, this is the most logical to start at.
echo "cd ../organizations/peerOrganizations/org1.fabsec.com/peers/peer0.org1.fabsec.com";

# Now, all of these commands need to be executed by the Administrator of the Organization, so let's set the
# correct environmental variable to the Admin's MSP.
echo "export CORE_PEER_MSPCONFIGPATH=$PWD/../../msp";
export CORE_PEER_MSPCONFIGPATH=$PWD/../../msp

# Next, we package the code. This will produce a .tar.gz file with the code and some Fabric metadata.
# Here the parameters are:
#	--path: the path to the chaincode
#	--lang: the language the chaincode is in. (This project will use Node.js)
#	--label: a human readable description of the package.
echo "./peer lifecycle chaincode package testcc.tar.gz --path ../../../../../chaincode/ --lang node --label testcc";
./peer lifecycle chaincode package testcc.tar.gz --path ../../../../../chaincode/ --lang node --label testcc;

# Then we will install the chaincode on the peer. Note: This will be done on each peer of each organization,
# however, I'll switch to the other peers a bit later to complete this step For now, let's install it on Peer 0
# of Organization 1. Also, this is when any build errors will be revealed.
echo "./peer lifecycle chaincode install testcc.tar.gz";
./peer lifecycle chaincode install testcc.tar.gz;

# This next part is a bit of an aside, but it's needed to grab the Package ID which is the label followed by a
# hash of the package. It is needed for further steps. The queryinstalled command will return the Package ID, but
# it has a bunch of other details with it which we don't need. So, work a little sed/awk magic to grab the exact
# portion that we DO need, and save it to a variable.
PKID = $(./peer lifecycle chaincode queryinstalled | sed -n '2p' | awk '{print $3}' | sed 's/,//');
echo "Caught PKID $PKID";

# Next we use the verbosely named command `approveformyorg` to approve the chaincode for the organization. This
# happens for each organization. These parameters you set here are called the "Chaincode Definition", and they must 
# be the same across all the organizations.
# These parameters are:
#	-o: the orderer to connect to
#	-tls: since this network is using tls, we need to state so
#	-cafile: the Root CA Certificate for the orderer
#	-channelID: the ID of the channel we want the chaincode to be run on
#	--name: the name of the chaincode (used when invoking the chaincode later)
#	--version: the version of the chaincode (important for upgrading your chaincode later)
#	-- package-id: the PKID we assigned to a variable earlier (Note: this is optional if a peer isn't going to
#		run the chaincode, and rather just needs to approve it for the channel)
#	--sequence: the number of times the chaincode has been defined (also used when upgrading)
echo "./peer lifecycle chaincode approveformyorg -o orderer0.org0.fabsec.com:6050 --tls --cafile "\
	"orderer-tls-root-cert/tls-ca-cert.pem  --channelID fabsec-channel --name testcc --version v0 --package-id "\
	"$PKID --sequence 1"
./peer lifecycle chaincode approveformyorg -o orderer0.org0.fabsec.com:6050 --tls --cafile \
	orderer-tls-root-cert/tls-ca-cert.pem  --channelID fabsec-channel --name testcc --version v0 --package-id \
	$PKID --sequence 1

# Okay, now we have to go to the other organizations and install the chaincode on each endorsing peer as well as approve
# the chaincode for that organization (only needed on one peer unlike installing).

# Let's move on over to Organization 2's Peer 0, and act as THEIR admin...
echo "pushd ../../../org2.fabsec.com/peers/peer0.org2.fabsec.com/";
pushd ../../../org2.fabsec.com/peers/peer0.org2.fabsec.com/;

echo "export CORE_PEER_MSPCONFIGPATH=$PWD/../../msp"
export CORE_PEER_MSPCONFIGPATH=$PWD/../../msp

# We need to bring the chaincode package over as well. Typically in a real production scenario, this would be done 
# out-of-band.
echo "cp ../../../org1.fabsec.com/peers/peer0.org1.fabsec.com/testcc.tar.gz .";
cp ../../../org1.fabsec.com/peers/peer0.org1.fabsec.com/testcc.tar.gz .

# Then we install it on the peer..
echo "./peer lifecycle chaincode install testcc.tar.gz"
./peer lifecycle chaincode install testcc.tar.gz

# And then approve it for Org 2..
echo "./peer lifecycle chaincode approveformyorg -o orderer0.org0.fabsec.com:6050 --tls --cafile "\
	"orderer-tls-root-cert/tls-ca-cert.pem  --channelID fabsec-channel --name testcc --version "\
	"v0 --package-id $PKID --sequence 1";
./peer lifecycle chaincode approveformyorg -o orderer0.org0.fabsec.com:6050 --tls --cafile \
	orderer-tls-root-cert/tls-ca-cert.pem  --channelID fabsec-channel --name testcc --version v0 \
	--package-id $PKID --sequence 1

# Then go over to Peer 1, and just install it there real quick, and then popd back to Peer 0 or Org 1
echo "cd ../peer1.org2.fabsec.com/";
cd ../peer1.org2.fabsec.com/;
echo "cp ../../../org1.fabsec.com/peers/peer0.org1.fabsec.com/testcc.tar.gz .";
cp ../../../org1.fabsec.com/peers/peer0.org1.fabsec.com/testcc.tar.gz .;
echo "./peer lifecycle chaincode install testcc.tar.gz";
./peer lifecycle chaincode install testcc.tar.gz;
echo "popd";
popd;

# A side command that I won't use in this script, but will put here in commented form for completeness,
# is the `checkcommitreadiness` command. This command provides a nice check to see which organizations have
# approved the chaincode.

# ./peer lifecycle chaincode checkcommitreadiness -o orderer0.org0.fabsec.com:6050 --tls --cafile 
# orderer-tls-root-cert/tls-ca-cert.pem  --channelID fabsec-channel --name testcc --version v0 --sequence 1

# Now, that we're back at Peer 0 of Organization 1, we revert back to their Admin credentials, and
# then commit the chaincode -- well, technically the "chaincode definition" as mentioned above -- to
# the channel. Once the chaincode has been committed, the chaincode will launch on all peers and will
# then be ready to use!
# The parameters here are the same as the previous commands with the added ones of:
#	--peerAddresses: The addresses of the endorsing peers that will commit the chaincode. This needs to 
#		be a MAJORITY, so two is fine here. Notice that we include a peer for each Org.
#	-- tlsRootCertFiles: Since we're using TLS, much like with the Orderer, we need to specify the Root
#		CA Certs from each organization that we're trying to connect to.
echo "export CORE_PEER_MSPCONFIGPATH=$PWD/../../msp";
export CORE_PEER_MSPCONFIGPATH=$PWD/../../msp

echo "./peer lifecycle chaincode commit -o orderer0.org0.fabsec.com:6050 --tls --cafile "\
	"orderer-tls-root-cert/tls-ca-cert.pem  --channelID fabsec-channel --name testcc --version v0 --sequence "\
	"1 --peerAddresses peer0.org1.fabsec.com:6051 --tlsRootCertFiles AllOrgsMSPs/org1/msp/tlscacerts/org1-tls-ca-cert.pem "\
	"--peerAddresses peer0.org2.fabsec.com:6053 --tlsRootCertFiles AllOrgsMSPs/org2/msp/tlscacerts/org2-tls-ca-cert.pem"
./peer lifecycle chaincode commit -o orderer0.org0.fabsec.com:6050 --tls --cafile orderer-tls-root-cert/tls-ca-cert.pem  --channelID \
	fabsec-channel --name testcc --version v0 --sequence 1 --peerAddresses peer0.org1.fabsec.com:6051 --tlsRootCertFiles \
	AllOrgsMSPs/org1/msp/tlscacerts/org1-tls-ca-cert.pem --peerAddresses peer0.org2.fabsec.com:6053 --tlsRootCertFiles \
	AllOrgsMSPs/org2/msp/tlscacerts/org2-tls-ca-cert.pem
