#!/bin/bash
# Written and maintained by Robert Kretschmar

# This script is another massive change in gears from the previous scripts. Now, we get to
# set up the peers of the network.. I won't go into a lot of detail as to what a Peer is in
# relation to the Fabric network as most of that information is in the README.md of this
# project. Suffice it to say, however, they are one of the two type of Nodes on the Fabric
# network, the other being Orderers, and they host the Chaincode and the Ledgers and allow
# users a way to interact with the Blockchain.

# When I say "sets up the peers", I mean this script interacts with the CA servers,
# specifically the Fab CA server, to collect the cryptographic material that defines this
# peer's identity. (Also the TLS server for the secure communication.) This identity will 
# be collected into an `msp` directory (MSP standing for Membership Service Provider) also 
# known as a "local MSP" since its the MSP for a node. (This is opposed to a Channel or Org
# MSP which is talked about in the Orderer scripts and section of the README.md) The MSP holds 
# the identifying information of the node. There will also be a special `tls-msp` to hold the
# TLS information of the node.

# This time we don't need to know whether or not the organization is a Orderer Org or Peer 
# Org since it's for a peer node meaning it is intrinsically for a Peer Organization.

# However, we do still need to know two things: The Organizational ID Number and the Peer ID 
# Number. These will be the first and second positional arguments, respectively.

# Let's make sure we have the correct number of arguments before moving on. If we do not,
# return a nice message to the user on how to use this script.
if (( $# != 2 )); then
	echo "Incorrect amount of arguments!!";
	echo "Pro-tip: proper use of this script comes in the form of:";
	echo -e "\t$0 <Org ID#> <Peer ID#>";
	exit;
fi

# EDIT: In an attempt to streamline this script, I'm adding a section where the port numbers of the TLS and
# Fab CA are chosen depending on which of the Peer Orgs the operator of this script is trying to operate
# within. This port are now part of my Design Decisions (talked about in the README) and are assign when
# setting up those servers. In the future, I will hope to make this more dynamic to allow from more than
# just the two "pre-programmed" Peer Orgs.
if (( $1 == 1 )); then
	TLSport=7056;
	FABport=7057;
elif (( $1 == 2 )); then
	TLSport=7058
	FABport=7059
else
	echo "There are current only two Peer Organizations.";
	exit;
fi


# Since we are using the organization's CA Client to fulfill these requests we should move 
# to the Fabric CA Client directory of the appropriate Peer Org, and then export the client home as usual.
echo "cd ../organizations/peerOrganizations/org$1.fabsec.com/ca-client";
cd ../organizations/peerOrganizations/org$1.fabsec.com/ca-client

echo "export FABRIC_CA_CLIENT_HOME=$PWD";
export FABRIC_CA_CLIENT_HOME=$PWD

# Let's start with registering and enrolling the peer with the TLS Server. For this, we will
# need to grab the TLS Admin creds at least for the username which is the directory where
# the admin's certificate lives.

echo "IFS=':' read -ra TLScreds <<< \$(cat ../tls-ca-server/tls-creds.txt)";
IFS=':' read -ra TLScreds <<< $(cat ../tls-ca-server/tls-creds.txt);

# Now, let's register the peer with the TLS server using the TLS admin cert (which lives in
# the TLS admin's MSP)
echo "./fabric-ca-client register -d --id.name peer$2-org$1 --id.secret peer$2-org$1-pw --id.type peer "\
	"-u https://hypertest:$TLSport --tls.certfiles tls-root-cert/tls-ca-cert.pem --mspdir tls-ca/${TLScreds[0]}/msp --csr.hosts \"127.0.0.1, hypertest, localhost, *.org0.fabsec.com, *.org1.fabsec.com, *.org2.fabsec.com\"";
./fabric-ca-client register -d --id.name peer$2-org$1 --id.secret peer$2-org$1-pw --id.type peer \
	-u https://hypertest:$TLSport --tls.certfiles tls-root-cert/tls-ca-cert.pem --mspdir tls-ca/${TLScreds[0]}/msp --csr.hosts "127.0.0.1, hypertest, localhost, *.org0.fabsec.com, *.org1.fabsec.com, *.org2.fabsec.com";

# Since both servers are up-and-running, we can do the same registering with the Fab CA
# server. The only difference is now we grab the Fab CA Admin's credentials as well as use
# *their* MSP (and, of course, use port 7055 instead of 7054).
echo "IFS=':' read -ra FABcreds <<< \$(cat ../fab-ca-server/fab-creds.txt)";
IFS=':' read -ra FABcreds <<< $(cat ../fab-ca-server/fab-creds.txt);

echo "./fabric-ca-client register -d --id.name peer$2-org$1 --id.secret peer$2-org$1-pw --id.type peer "\
	"-u https://hypertest:$FABport --tls.certfiles tls-root-cert/tls-ca-cert.pem --mspdir fab-ca/\${FABcreds[0]}/msp --csr.hosts \"127.0.0.1, hypertest, localhost, *.org0.fabsec.com, *.org1.fabsec.com, *.org2.fabsec.com\"";
./fabric-ca-client register -d --id.name peer$2-org$1 --id.secret peer$2-org$1-pw --id.type peer \
	-u https://hypertest:$FABport --tls.certfiles tls-root-cert/tls-ca-cert.pem --mspdir fab-ca/${FABcreds[0]}/msp --csr.hosts "127.0.0.1, hypertest, localhost, *.org0.fabsec.com, *.org1.fabsec.com, *.org2.fabsec.com";

# Even though, we tend not to use the credentials much after registering, let's still get them
# into a file just in case. NOTE: However, again, this is a development procedure. Delete them for a production 
# environment.
echo "peer$2-org$1:peer$2-org$1-pw" > ../peers/peer$2.org$1.fabsec.com/peer-creds.txt;

# Next we enroll! This will set up the TLS crypto and identity of the peer. This command will take 
# the form of previous enroll commands with the exception of the --mspdir argument which will now
# point to where we want the MSP information of the current peer we are operating on to live. For 
# example, if it was the Peer 1 of Organization 2, the path (relative from our PWD of ca-client) 
# would be: ../peers/peer1.org2.fabsec.com/tls-msp for the TLS server and ../peers/peer1.org2.fabsec.com/msp
# for the Fab server.
echo "./fabric-ca-client enroll -d -u https://peer$2-org$1:peer$2-org$1-pw@hypertest:$TLSport "\
	"--tls.certfiles tls-root-cert/tls-ca-cert.pem --mspdir ../peers/peer$2.org$1.fabsec.com/msp --csr.hosts \"127.0.0.1, hypertest, localhost, *.org0.fabsec.com, *.org1.fabsec.com, *.org2.fabsec.com\"";
./fabric-ca-client enroll -d -u https://peer$2-org$1:peer$2-org$1-pw@hypertest:$TLSport \
	--tls.certfiles tls-root-cert/tls-ca-cert.pem --mspdir ../peers/peer$2.org$1.fabsec.com/tls-msp --csr.hosts "127.0.0.1, hypertest, localhost, *.org0.fabsec.com, *.org1.fabsec.com, *.org2.fabsec.com"

# And, since the private key of the peer is not pretty, let us make it so.
echo "mv ../peers/peer$2.org$1.fabsec.com/tls-msp/keystore/*_sk ../peers/peer$2.org$1.fabsec.com/tls-msp/keystore/key.pem"
mv ../peers/peer$2.org$1.fabsec.com/tls-msp/keystore/*_sk ../peers/peer$2.org$1.fabsec.com/tls-msp/keystore/key.pem

echo "./fabric-ca-client enroll -d -u https://peer$2-org$1:peer$2-org$1-pw@hypertest:$FABport "\
	"--tls.certfiles tls-root-cert/tls-ca-cert.pem --mspdir ../peers/peer$2.org$1.fabsec.com/msp --csr.hosts \"127.0.0.1, hypertest, localhost, *.org0.fabsec.com, *.org1.fabsec.com, *.org2.fabsec.com\""
./fabric-ca-client enroll -d -u https://peer$2-org$1:peer$2-org$1-pw@hypertest:$FABport \
	--tls.certfiles tls-root-cert/tls-ca-cert.pem --mspdir ../peers/peer$2.org$1.fabsec.com/msp --csr.hosts "127.0.0.1, hypertest, localhost, *.org0.fabsec.com, *.org1.fabsec.com, *.org2.fabsec.com"

# Now, we'll copy over the NodeOUs config.yaml file from the test-configs directory.
cp ../../../../test-configs/org$1/nodeOUs/config.yaml ../peers/peer$2.org$1.fabsec.com/msp/.

# While we're at it, let's bring over the peer's config file as well: core.yaml
cp ../../../../test-configs/org$1/peer$2/core-config/core.yaml ../peers/peer$2.org$1.fabsec.com/.

# Another thing is in order to talk to the Orderer, this peer will need the Orderer's TLS Root Cert. In a
# real-world scenario, this would probably happen out-of-band, but for this project, I'll just copy
# it over from the Orderer Org.
echo "cp ../../../ordererOrganizations/org0.fabsec.com/ca-client/tls-root-cert/tls-ca-cert.pem "\
	"../peers/peer$2.org$1.fabsec.com/orderer-tls-root-cert/.";
cp ../../../ordererOrganizations/org0.fabsec.com/ca-client/tls-root-cert/tls-ca-cert.pem \
	../peers/peer$2.org$1.fabsec.com/orderer-tls-root-cert/.

# Eventually, we'll need some crypto data from the other Organizations, so I'll go ahead and copy over our
# running AllOrgsMSPs pool into the node. However, again, in production this would want to be done in a less
# careless manner. i.e. to NOT copy over secret keys and probably to this in a secure out-of-band way.
echo "cp -R ../../../ordererOrganizations/org0.fabsec.com/orderers/orderer0.org0.fabsec.com/AllOrgsMSPs/ "\
	"../peers/peer$2.org$1.fabsec.com/"
cp -R ../../../ordererOrganizations/org0.fabsec.com/orderers/orderer0.org0.fabsec.com/AllOrgsMSPs/ \
	../peers/peer$2.org$1.fabsec.com/

# Again, work our naming magic on the private key.
echo "mv ../peers/peer$2.org$1.fabsec.com/msp/keystore/*_sk ../peers/peer$2.org$1.fabsec.com/msp/keystore/key.pem"
mv ../peers/peer$2.org$1.fabsec.com/msp/keystore/*_sk ../peers/peer$2.org$1.fabsec.com/msp/keystore/key.pem
