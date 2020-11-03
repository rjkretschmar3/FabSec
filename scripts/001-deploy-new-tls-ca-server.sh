#!/bin/bash
# Written and maintained by Robert Kretschmar

# This script will initialize and deploy an Organization's TLS CA Server. It assumes a few
# things:
#	Commandline Arguments are positional and are as follows:
#		1) Whether it is an ~orderer~ or ~peer~ organization.
#		2) The ID number of the organization. (In the real world, this would be 
#		an actual name.)
#
# 	The directory infrastructure is already in place. For example, a peer organization
# of ID 1 would have the directory structure of 
# organizations/peerOrganizations/org1.fabsec.com, and specifically the directory 
# tls-ca-server under that tree. 
#
#	Furthermore, that the fabric-ca-server binary is located in the tls-ca-server 
# directory under org1.fabsec.com (or whichever organization you're working with).

# ADDED TO NOT MAKE THIS MISTAKE AGAIN:
read -p "This script is for initializing a new TLS server. If you have an existing TLS server, this will destroy the old key material , not to mention the YAML file, requiring all participates to re-register and re-enroll. If you have an initialized server already, use the non-destructive start-tls-server.sh script instead. Are you sure you want to continue? [y/N] " prompt

if [[ $prompt != "y" && $prompt != "Y" ]]; then
	echo "A wise choice, exiting...";
	exit;
fi

# First move to the appropriate directory: organizations/ordererOrganizations for an 
# Orderer and organizations/peerOrganizations for a Peer.
if [[ "$1" == "orderer" ]]; then
	echo "cd ../organizations/ordererOrganizations/org$2.fabsec.com/tls-ca-server";
	cd ../organizations/ordererOrganizations/org$2.fabsec.com/tls-ca-server
elif [[ "$1" == "peer" ]]; then
	echo "cd ../organizations/peerOrganizations/org$2.fabsec.com/tls-ca-server";
	cd ../organizations/peerOrganizations/org$2.fabsec.com/tls-ca-server
else
	echo "Unsure if Orderer or Peer organization!";
	echo "Pro-tip: proper use of this script comes in the form of: ";
	echo -e "\t$0 <orderer|peer> <ID#>";
	exit;
fi

# Next, this will initialize the server. Initialization does a few things: 
#	1) It will register a bootstrap identity, which will be in the form of 
# <ADMIN_USER>:<ADMIN_PW>. In the case of the above example the bootstrap identity will be
# org1-tls-admin:org1-tls-adminpw.
#	2) It'll set the default CA Home directory environmental variable FABRIC_CA_HOME 
# to the present working directory. (Thus, the need to traverse there in the previous 
# steps.)
#	3) Generates the default YAML configuration file. (Talked about later.)
#	4) Generates the TLS CA root signed certificate file ca-cert.pem
#	5) Generates the TLS CA server private key and stores it in the FABRIC_CA_HOME 
# directory under /msp/keystore

# Remove the old config file and the old key material
echo "rm ./fabric-ca-server-config.yaml"
rm ./fabric-ca-server-config.yaml
echo "rm ./fabric-ca-server.db"
rm ./fabric-ca-server.db
echo "rm ./IssuerPublicKey"
rm ./IssuerPublicKey
echo "rm ./IssuerRevocationPublicKey"
rm ./IssuerRevocationPublicKey
echo "rm ./ca-cert.pem"; 
rm ./ca-cert.pem
echo "rm ./tls-cert.pem"
rm ./tls-cert.pem
echo "rm ./tls-cred.txt"
rm ./tls-cred.txt
echo "rm -R ./msp/";
rm -R ./msp/

echo "./fabric-ca-server init -b org$2-tls-admin:org$2-tls-admin-pw";
echo "org$2-tls-admin:org$2-tls-admin-pw" > tls-creds.txt
./fabric-ca-server init -b org$2-tls-admin:org$2-tls-admin-pw

# Here is where it gets murky. As mentioned this initialization process generates a default
# YAML file for server configuration. I have yet to find an elegant way to automatically 
# change some of the default values to the working ones. For now, it opens up vim for 
# manual editing. (However, I can generate and present the values for the operator to write
# down before changing them.) TODO: Research the program 'yq' for this task.

echo "This script will now open the YAML configuration file.";
echo "Some fields to be changed: ";
echo -e "\tport - The port to operate on";
echo -e "\ttls.enabled - Change to true";
echo -e "\tca.name - Change to org$2-tls-ca";
echo -e "\tcsr.hosts - Check that the hostnames are in order";
echo -e "\tsigning.profiles - Delete the ~ca~ profile";
read -p "Press [Enter] to enter vim...";

echo "vim fabric-ca-server-config.yaml";
vim fabric-ca-server-config.yaml
echo "Done!";

echo "If you have a pre-configured YAML file, please copy it over to $PWD before continuing.";
read -p "Press [Enter] to continue script...";

# The following section will start the server.

# In case the CSR block of the YAML file has been changed in the vim step above, delete the
# TLS CA cert ca-cert.pem and the entire tls-ca-server/msp directory. These will be 
# regenerated with the newly populated config information when the servers starts up next
# time.

echo "rm ./ca-cert.pem";
rm ./ca-cert.pem
echo "rm -R ./msp/";
rm -R ./msp/

# Finally start the TLS Server
echo "./fabric-ca-server start"
./fabric-ca-server start

