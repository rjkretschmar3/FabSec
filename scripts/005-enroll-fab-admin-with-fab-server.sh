#!/bin/bash
# Written and maintained by Robert Kretschmar

# This script will enroll the Fab CA admin with the Fab CA server. Remember that an enroll 
# command tells the server to generate and return the signed certificate and private key for 
# the actor you're enrolling. This key-pair for the admin identity will allow that admin to 
# enroll other identities.
#
# The directory tree assumed to be in place for this script is ca-client/fab-ca/ to store 
# the certificates that are issued by the enroll command against the Fab CA and 
# ca-client/tls-root-cert/ for the secure communications.

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
 
# Then, let's set the environmental variable they like us to set.
echo "export FABRIC_CA_CLIENT_HOME=$PWD";
export FABRIC_CA_CLIENT_HOME=$PWD

# Next, grab the Fab CA admin credentials out of the file we put them in in the last script.
echo "IFS=':' read -ra creds <<< \$(cat ../fab-ca-server/fab-creds.txt)"
IFS=':' read -ra creds <<< $(cat ../fab-ca-server/fab-creds.txt)

# Now we can issue the enroll command.
# NOTE: One of the commandline arguments (not used here... yet) is that of --csr.hosts which 
# is followed by a comma-separated list of hostnames for which the certificate is valid. 
# Since I am currently doing development all on the same host "hypertest" is fine. However, 
# when I expand this to multiple virtual hosts (to simulate a real network), I'll have to 
# figure out the hostname management.
echo "./fabric-ca-client enroll -d -u https://${creds[0]}:${creds[1]}@hypertest:${creds[2]} --tls.certfiles tls-root-cert/tls-ca-cert.pem --mspdir fab-ca/${creds[0]}/msp"
./fabric-ca-client enroll -d -u https://${creds[0]}:${creds[1]}@hypertest:${creds[2]} --tls.certfiles tls-root-cert/tls-ca-cert.pem --mspdir fab-ca/${creds[0]}/msp

# Lastly, let's rename that ugly secret key we get to something more manageable.
echo "mv fab-ca/${creds[0]}/msp/keystore/*_sk fab-ca/${creds[0]}/msp/keystore/key.pem"
mv fab-ca/${creds[0]}/msp/keystore/*_sk fab-ca/${creds[0]}/msp/keystore/key.pem
