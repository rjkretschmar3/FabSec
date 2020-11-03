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
# be collected into an MSP (Membership Service Provider) also known as a "local MSP" since 
# its the MSP for a node. The MSP holds the identifying information of the node.

# This time we don't need to know whether or not the organization is a Orderer Org or Peer 
# Org since it's intrinsically for a peer node meaning it is definitely for a Peer Organization.

# However, we do still need to know two things: The Organizational ID Number and the Peer ID Number. These will be the first and second positional arguments, respectively.

# Let's make sure we have the correct number of arguments before moving on. If we do not,
# return a nice message to the user on how to use this script.
if (( $# != 2 )); then
	echo "Incorrect amount of arguments!!";
	echo "Pro-tip: proper use of this script comes in the form of:";
	echo -e "\t$0 <Org ID#> <Peer ID#>";
	exit;
fi

# Since we are using the Fabric CA Client to fulfill these requests we should move to the Fab CA Client directory of the appropriate Peer Org, and then export the client home as usual.
echo "cd ../organizations/peerOrganizations/org$1.fabsec.com/ca-client";
cd ../organizations/peerOrganizations/org$1.fabsec.com/ca-client

echo "export FABRIC_CA_CLIENT_HOME=$PWD";
export FABRIC_CA_CLIENT_HOME=$PWD

# Let's start with registering and enrolling the peer with the TLS Server. For this, we will
# need to grab the TLS Admin creds at least for the username which is the directory where
# the admin's certificate is at.

echo "IFS=':' read -ra TLScreds <<< \$(cat ../tls-ca-server/tls-creds.txt)";
IFS=':' read -ra TLScreds <<< $(cat ../tls-ca-server/tls-creds.txt);

# Now, let's register the peer with the TLS server using the TLS admin cert (which lives in
# the TLS admin's MSP)
echo "./fabric-ca-client register -d --id.name peer$2-org$1 --id.secret peer$2-org$1-pw --id.type peer -u https://hypertest:7054 --tls.certfiles tls-root-cert/tls-ca-cert.pem --mspdir tls-ca/${TLScreds[0]}/msp";
./fabric-ca-client register -d --id.name peer$2-org$1 --id.secret peer$2-org$1-pw --id.type peer -u https://hypertest:7054 --tls.certfiles tls-root-cert/tls-ca-cert.pem --mspdir tls-ca/${TLScreds[0]}/msp;

# Since both servers are up-and-running, we can do the same registering with the Fab CA
# server. The only difference is now we grab the Fab CA Admin's credentials as well as use
# *their* MSP (and, of course, use port 7055 instead of 7054).
echo "IFS=':' read -ra FABcreds <<< \$(cat ../fab-ca-server/fab-creds.txt)";
IFS=':' read -ra FABcreds <<< $(cat ../fab-ca-server/fab-creds.txt);

echo "./fabric-ca-client register -d --id.name peer$2-org$1 --id.secret peer$2-org$1-pw --id.type peer -u https://hypertest:7055 --tls.certfiles tls-root-cert/tls-ca-cert.pem --mspdir fab-ca/\${FABcreds[0]}/msp";
./fabric-ca-client register -d --id.name peer$2-org$1 --id.secret peer$2-org$1-pw --id.type peer -u https://hypertest:7055 --tls.certfiles tls-root-cert/tls-ca-cert.pem --mspdir fab-ca/${FABcreds[0]}/msp;

# Even though, we tend not to use the credentials much after registering, let's still get them
# into a file just in case. NOTE: However, again, this is a development procedure. Delete them for a production environment.
echo "peer$2-org$1:peer$2-org$1-pw" > ../peers/peer$2.org$1.fabsec.com/peer-creds.txt;

# Next we enroll! This will set up the identity of the peer. This command will take the form
# of previous enroll commands with the exception of the --mspdir argument which will now
# point to where we want the MSP of the current peer we are operating on. For example, if it 
# was the peer 1 of Organization 2, the path (relative from our PWD of ca-client) would be:
# ../peers/peer1.org2.fabsec.com/msp
echo "./fabric-ca-client enroll -d -u https://peer$2-org$1:peer$2-org$1-pw@hypertest:7054 --tls.certfiles tls-root-cert/tls-ca-cert.pem --mspdir ../peers/peer$2.org$1.fabsec.com/msp";
./fabric-ca-client enroll -d -u https://peer$2-org$1:peer$2-org$1-pw@hypertest:7054 --tls.certfiles tls-root-cert/tls-ca-cert.pem --mspdir ../peers/peer$2.org$1.fabsec.com/msp

# And, since the private key of the peer is not pretty, let us make it so.
echo "mv ../peers/peer$2.org$1.fabsec.com/msp/keystore/*_sk ../peers/peer$2.org$1.fabsec.com/msp/keystore/tls-key.pem"
mv ../peers/peer$2.org$1.fabsec.com/msp/keystore/*_sk ../peers/peer$2.org$1.fabsec.com/msp/keystore/tls-key.pem

echo "./fabric-ca-client enroll -d -u https://peer$2-org$1:peer$2-org$1-pw@hypertest:7055 --tls.certfiles tls-root-cert/tls-ca-cert.pem --mspdir ../peers/peer$2.org$1.fabsec.com/msp"
./fabric-ca-client enroll -d -u https://peer$2-org$1:peer$2-org$1-pw@hypertest:7055 --tls.certfiles tls-root-cert/tls-ca-cert.pem --mspdir ../peers/peer$2.org$1.fabsec.com/msp

# And, since the private key of the peer is not pretty, let us make it so.
echo "mv ../peers/peer$2.org$1.fabsec.com/msp/keystore/*_sk ../peers/peer$2.org$1.fabsec.com/msp/keystore/fab-key.pem"
mv ../peers/peer$2.org$1.fabsec.com/msp/keystore/*_sk ../peers/peer$2.org$1.fabsec.com/msp/keystore/fab-key.pem
