#!/bin/bash
# Written and maintained by Robert Kretschmar

# This script will enroll the bootstrapped admin user from 001-deploy-new-tls-ca-server.sh
# (Bootstrapping takes the place of a register command, and only happens for the first 
# (and usually only) administrator of the TLS server.) This script also assumes a few 
# things:
#
#	The directory infrastructure is already in place. For example, a peer organization
# of ID 1 would have the directory structure of organization/peerOrganizations/org1.fabsec.com
#
#	Furthermore, the fabric-ca-client binary is located in the ca-client directory 
# under org1.fabsec.com (or whichever organization you're working with).

# First move to the appropriate directory.
if [[ "$1" == "orderer" ]]; then
	echo "cd ../organizations/ordererOrganizations/org$2.fabsec.com/ca-client";
	cd ../organizations/ordererOrganizations/org$2.fabsec.com/ca-client
elif [[ "$1" == "peer" ]]; then
	echo "cd ../organizations/peerOrganizations/org$2.fabsec.com/ca-client";
	cd ../organizations/peerOrganizations/org$2.fabsec.com/ca-client
else
	echo "Unsure if Orderer or Peer organization! Exiting...";
	echo "Pro-tip: proper use of this script comes in the form of:";
	echo -e "\t$0 <orderer|peer> <ID#>";
	exit;
fi

# Next, we copy the TLS root cert from tls-ca-server/ca-cert.pem to the 
# ca-client/tls-root-cert directory, also changing its name to tls-ca-cert.pem for clarity
# since there will be different cryptographic material for multiple CAs (both TLS and 
# Fabric).
echo "cp ../tls-ca-server/ca-cert.pem tls-root-cert/tls-ca-cert.pem"
cp ../tls-ca-server/ca-cert.pem tls-root-cert/tls-ca-cert.pem

# Also, the way the client binary is set-up we need to export the directory where that 
# binary is located to the environmental variable $FABRIC_CA_CLIENT_HOME. Since we're 
# already there, this is simple.
echo "export FABRIC_CA_CLIENT_HOME=$PWD"
export FABRIC_CA_CLIENT_HOME=$PWD

# Finally, execute! For the arguments:
# -d Prints debugging information. May want to remove this for production.
# -u https://<username>:<password>@<host>:<port> is the general form of this URL. This is 
# the URL of the TLS server that got deployed in the previous script. The username and 
# password are the ones used to bootstrap the server. The host and port are from gathered 
# from the YAML config file also created/modified in the previous step.
# --tls.certfiles points to the location of the signed certificate of the TLS server
# --enrollment-profile <tls|ca> is an optional parameter of which profile, in this case 
# TLS, that we want to use if we hadn't removed the CA signing profile in the YAML. (Not 
# present, because we did.)
# --csr.hosts <hosts> is another optional argument where <hosts> is a comma-separated list 
# of hostnames for which the certificate should be valid. This is optional because it can 
# pull these from the YAML config file. However, an important thing to note here is the 
# use of wildcards. For example, *.example.com, will recognizes any host within the 
# example.com domain.
# --mspdir points to the directory of the msp where the command will store the TLS CA 
# admin certificates that are generated by this enroll command.
#
# FURTHER NOTE ON MSP: The --mspdir flag operates differently for a register command vs an
# enroll command. For a register command, it points to the location of the cryptographic 
# material to use. For an enroll command, it points to where to store the generated 
# certificates.

# NOTE: We will need the username and password that we siphoned off into tls-creds.txt
# EDIT: We've now put the port in there as well to make it psuedo-dynamic
echo "IFS=':' read -ra creds <<< \$(cat ../tls-ca-server/tls-creds.txt)";
IFS=':' read -ra creds <<< $(cat ../tls-ca-server/tls-creds.txt); # This just splits the username and password into an array.

echo "./fabric-ca-client enroll -d -u https://${creds[0]}:${creds[1]}@localhost:${creds[2]} --tls.certfiles tls-root-cert/tls-ca-cert.pem --mspdir tls-ca/${creds[0]}/msp --csr.hosts \"127.0.0.1, hypertest, localhost, *.org0.fabsec.com, *.org1.fabsec.com, *.org2.fabsec.com\""
./fabric-ca-client enroll -d -u https://${creds[0]}:${creds[1]}@localhost:${creds[2]} --tls.certfiles tls-root-cert/tls-ca-cert.pem --mspdir tls-ca/${creds[0]}/msp --csr.hosts "127.0.0.1, hypertest, localhost, *.org0.fabsec.com, *.org1.fabsec.com, *.org2.fabsec.com" 

# Lastly, let's rename that ugly secret key we get to something more manageable.
echo "mv tls-ca/${creds[0]}/msp/keystore/*_sk tls-ca/${creds[0]}/msp/keystore/key.pem"
mv tls-ca/${creds[0]}/msp/keystore/*_sk tls-ca/${creds[0]}/msp/keystore/key.pem
