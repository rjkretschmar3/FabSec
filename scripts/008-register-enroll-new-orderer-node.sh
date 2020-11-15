#!/bin/bash
# Written and maintained by Robert Kretschmar

# This script is the sibling script to 007-register-enroll-new-peer-node where we instead register
# and enroll a new orderer node. It will follow the same logic, as there is not much difference
# between the two actions other than (1) where the Local MSP will end up being generated, and (2)
# the "id.type" in the register command. As you could imagine, the latter is changed from "peer" to
# "orderer". So, for a more in-depth explanation to what these commands are doing, I refer you to
# that script's comments.

# Since the act of setting up an orderer is intrinsically happening within an Orderer Organization,
# the script will not need that information via commandline arguments. However, it will need to know
# specifically which Orderer Org we want to operate within, and which Orderer Node we want to operate
# on.

# So, let's make sure we have the correct number of arguments before moving on. If we do not,
# return a nice message to the user on how to use this script.
if (( $# != 2 )); then
        echo "Incorrect amount of arguments!!";
        echo "Pro-tip: proper use of this script comes in the form of:";
        echo -e "\t$0 <Org ID#> <Orderer ID#>";
        exit;
fi

# Since we are using the organization's CA Client to fulfill these requests we should move
# to the Fabric CA Client directory of the appropriate Orderer Org, and then export the client home as 
# usual.
echo "cd ../organizations/ordererOrganizations/org$1.fabsec.com/ca-client";
cd ../organizations/ordererOrganizations/org$1.fabsec.com/ca-client

echo "export FABRIC_CA_CLIENT_HOME=$PWD";
export FABRIC_CA_CLIENT_HOME=$PWD

# Let's start with registering and enrolling the orderer with the TLS Server. For this, we will
# need to grab the TLS Admin creds at least for the username which is the directory where
# the admin's certificate lives.

echo "IFS=':' read -ra TLScreds <<< \$(cat ../tls-ca-server/tls-creds.txt)";
IFS=':' read -ra TLScreds <<< $(cat ../tls-ca-server/tls-creds.txt);

# Now, let's register the orderer with the TLS server using the TLS admin cert (which lives in
# the TLS admin's MSP)
echo "./fabric-ca-client register -d --id.name orderer$2-org$1 --id.secret orderer$2-org$1-pw "\
		"--id.type orderer -u https://hypertest:7054 --tls.certfiles tls-root-cert/tls-ca-cert.pem " \
		"--mspdir tls-ca/${TLScreds[0]}/msp";
./fabric-ca-client register -d --id.name orderer$2-org$1 --id.secret orderer$2-org$1-pw --id.type orderer \
	-u https://hypertest:7054 --tls.certfiles tls-root-cert/tls-ca-cert.pem --mspdir \
	tls-ca/${TLScreds[0]}/msp;

# Since both servers are up-and-running, we can do the same registering with the Fab CA
# server. The only difference is now we grab the Fab CA Admin's credentials as well as use
# *their* MSP (and, of course, use the correct port which depends on the Org and the CA).
echo "IFS=':' read -ra FABcreds <<< \$(cat ../fab-ca-server/fab-creds.txt)";
IFS=':' read -ra FABcreds <<< $(cat ../fab-ca-server/fab-creds.txt);

echo "./fabric-ca-client register -d --id.name orderer$2-org$1 --id.secret orderer$2-org$1-pw " \
	"--id.type orderer -u https://hypertest:7055 --tls.certfiles tls-root-cert/tls-ca-cert.pem --mspdir " \
	"fab-ca/\${FABcreds[0]}/msp";
./fabric-ca-client register -d --id.name orderer$2-org$1 --id.secret orderer$2-org$1-pw --id.type orderer \
	-u https://hypertest:7055 --tls.certfiles tls-root-cert/tls-ca-cert.pem --mspdir \
	fab-ca/${FABcreds[0]}/msp;

# Even though, we tend not to use the credentials much after registering and enrolling, let's still get them
# into a file just in case. NOTE: However, again, this is a development procedure. Delete them for a production
# environment.
echo "orderer$2-org$1:orderer$2-org$1-pw" > ../orderers/orderer$2.org$1.fabsec.com/orderer-creds.txt;

# Next we enroll! This will set up the TLS crypto and identity of the orderer. This command will take
# the form of previous enroll commands with the exception of the --mspdir argument which will now
# point to where we want the MSP information of the current orderer we are operating on to live. For
# example, if it was the Orderer 0 of Organization 0, the path (relative from our PWD of ca-client)
# would be: ../orderers/orderer0.org0.fabsec.com/tls-msp for the TLS server and 
# ../orderers/orderer0.org0.fabsec.com/msp for the Fab server.
echo "./fabric-ca-client enroll -d -u https://orderer$2-org$1:orderer$2-org$1-pw@hypertest:7054 "\
	"--tls.certfiles tls-root-cert/tls-ca-cert.pem --mspdir ../orderers/orderer$2.org$1.fabsec.com/msp";
./fabric-ca-client enroll -d -u https://orderer$2-org$1:orderer$2-org$1-pw@hypertest:7054 \
	--tls.certfiles tls-root-cert/tls-ca-cert.pem --mspdir ../orderers/orderer$2.org$1.fabsec.com/tls-msp;

# And, since the private key of the orderer is not pretty, let us make it so.
echo "mv ../orderers/orderer$2.org$1.fabsec.com/tls-msp/keystore/*_sk " \
	"../orderers/orderer$2.org$1.fabsec.com/tls-msp/keystore/key.pem"
mv ../orderers/orderer$2.org$1.fabsec.com/tls-msp/keystore/*_sk \
	../orderer/orderer$2.org$1.fabsec.com/tls-msp/keystore/key.pem

echo "./fabric-ca-client enroll -d -u https://orderer$2-org$1:orderer$2-org$1-pw@hypertest:7055 " \
	"--tls.certfiles tls-root-cert/tls-ca-cert.pem --mspdir ../orderers/orderer$2.org$1.fabsec.com/msp"
./fabric-ca-client enroll -d -u https://orderer$2-org$1:orderer$2-org$1-pw@hypertest:7055 \
	--tls.certfiles tls-root-cert/tls-ca-cert.pem --mspdir ../orderers/orderer$2.org$1.fabsec.com/msp

# Again, work our naming magic on the private key.
echo "mv ../orderers/orderer$2.org$1.fabsec.com/msp/keystore/*_sk " \
	"../orderers/orderer$2.org$1.fabsec.com/msp/keystore/key.pem"
mv ../orderers/orderer$2.org$1.fabsec.com/msp/keystore/*_sk \
	../orderers/orderer$2.org$1.fabsec.com/msp/keystore/key.pem

