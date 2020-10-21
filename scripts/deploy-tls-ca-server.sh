#!/bin/bash

# This script will initalize and deploy an Organization's TLS CA Server. It assumes a few things:
#	Commandline Arguments are positional and are as follows:
#		1) Whether it is an ~orderer~ or ~peer~ organization.
#		2) The ID number of the organization. (In the real world, this would be an actual name.)
#
#	The directory infastructure is already in place. For example, a peer organization of ID 1 would have the directory structure of organizations/peerOrganizations/org1.fabsec.com 
#
#	Furthermore, that the fabric-ca-server binary is located in the tls-ca-server directory under org1.fabsec.com (or whichever organization you're working with).

# ADDED TO NOT MAKE THIS MISTAKE AGAIN:
read -p "This script is for initializing a new TLS server. If you have an existing TLS server, this will destory the old key material , not to mention the YAML file, requiring all participates to re-register and re-enroll. If you have an initialized server already, use the non-destructive start-tls-server.sh script instead. Are you sure you want to continue? [y/N] " prompt

if [[ $prompt != "y" && $prompt != "Y" ]]; then
	echo "A wise choice, exiting...";
	exit;
fi

# First move to the appropiate directory: organizations/ordererOrganizations for an Orderer and organizations/peerOragnizations for a Peer.
if [[ "$1" == "orderer" ]]; then
	echo "cd ../organizations/ordererOrganizations/org$2.fabsec.com/tls-ca-server";
	cd ../organizations/ordererOrganizations/org$2.fabsec.com/tls-ca-server
elif [[ "$1" == "peer" ]]; then
	echo "cd ../organizations/peerOrganizations/org$2.fabsec.com/tls-ca-server";
	cd ../organizations/peerOrganizations/org$2.fabsec.com/tls-ca-server
else
	echo "Unsure if Orderer or Peer organization!";
	exit;
fi

# Next, this will initalize the server. Initalization does a few things: 
#	1) It will register a bootstrap identity, which will be in the form of <ADMIN_USER>:<ADMIN_PW>. In the case of the above example the bootstrap indentity will be org1-tls-admin:org1-tls-adminpw.
#	2) It'll set the default CA Home directory environmental variable FABRIC_CA_HOME to the present working directory. (Thus, the need to travrese there in the previous steps.)
#	3) Generates the default YAML conifguration file. (Talked about later.)
#	4) Generates the TLS CA root signed certificate file ca-cert.pem
#	5) Generates the CA server private key and stores it in the FABRIC_CA_HOME directory under /msp/keystore

# Remove the old config file and the old key material
echo "rm ./fabric-ca-server-config.yaml"
rm ./fabric-ca-server-config.yaml
echo "rm ca-cert.pem"; 
rm ca-cert.pem
echo "rm -R msp";
rm -R msp

echo "./fabric-ca-server init -b org$2-tls-admin:org$2-tls-adminpw";
echo "org$2-tls-admin:org$2-tls-adminpw" > tls-creds.txt
./fabric-ca-server init -b org$2-tls-admin:org$2-tls-adminpw

# Here is where it gets murky. As mentioned this initialization process generates a default YAML file for server configuration. I have yet to find an elegant way to automatically change some of the default values to the working ones. For now, it opens up vim for manual editing. (However, I can generate and present the values for the operator to write down before changing them.)

echo "This script will now open the YAML configuration file.";
echo "Some fields to be changed: ";
echo -e "\tport - The port to operate on";
echo -e "\ttls.enabled - Change to true";
echo -e "\tca.name - Change to org$2-tls-ca";
echo -e "\tcsr.hosts - Check that the hostnames are in order";
echo -e "\tsigning.profiles.ca - Delete the ~ca~ profile";
read -p "Press [Enter] to enter vim...";

echo "vim fabric-ca-server-config.yaml";
vim fabric-ca-server-config.yaml
echo "Done!";

# The following section will start the server.

# In case the CSR block of the YAML file has been changed in the vim step above, delete the TLS CA cert ca-cert.pem and the entire tls-ca-server/msp directory. These will be regenerated with the correct information when the servers starts up.

echo "rm ca-cert.pem";
rm ca-cert.pem
echo "rm -R msp";
rm -R msp

# Finally start the TLS Server
echo "./fabric-ca-server start"
./fabric-ca-server start

