#!/bin/bash

# This script will now register and enroll the administrator for the Organizational CA Server. The Org CA, also known as the Fab CA, is the server in charge of creating the identities that will be used in the actual Fabric network. That is, it names the participants of the network and is used for the permissioning of the system. First, however, it'll need its own administrator and, as with every node/participant on the network, will need to be registered and enrolled on with the TLS server for secure communications.
#
# As with the other scripts, the commandline arguments will be positional:
#	1) Whether it is an ~orderer~ or ~peer~ organization.
#	2) The ID number of the organization.
# 
# The default Org CA admin is going to have the credentials of org<ID#>-fab-admin:org<ID#>-fab-admin-pw similar to that of the TLS admin. (In a true production environment, I would modify the script to accept user input for these values as defaults are a security hazard in and of themselves.)

# As usual, move to the ca-client directory of the appropriate org.
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


# Don't forget to set the environmental variable $FABRIC_CA_CLIENT_HOME. As with the last script, since we're already there, this is simple.
echo "export FABRIC_CA_CLIENT_HOME=$PWD"
export FABRIC_CA_CLIENT_HOME=$PWD

# Next, register the Fab CA admin identity. For few notes here:
#	1) Registering an identity on the TLS (or any CA) server is done by the admin of that server (in this case, the TLS server admin), and let's the server know that there will be an enroll request coming in at some point in the future.
#	2) That enroll request, as we'll see later, comes from the actual user whose credentials they belong to. In this case, the Fab CA admin. (This is a separation of concerns/power thing.)
#	3) localhost is where the TLS server lives. If you host the server on a different physical machine (or logical network partition), put it there. Same with the port.
#	4) The --mspdir flag here (that is, for the register command) points to the MSP directory of the TLS admin, so that the TLS server knows this command was employed by the true admin (in lieu of username/password).

# Dynamically grab the TLS admin username to access their MSP.
echo "IFS=':' read -ra TLScreds <<< \$(cat ../tls-ca-server/tls-creds.txt);" 
IFS=':' read -ra TLScreds <<< $(cat ../tls-ca-server/tls-creds.txt); 

echo "./fabric-ca-client register -d --id.name org$2-fab-admin --id.secret org$2-fab-admin-pw -u https://localhost:7054 --tls.certfiles tls-root-cert/tls-ca-cert.pem --mspdir tls-ca/${TLScreds[0]}/msp";
./fabric-ca-client register -d --id.name org$2-fab-admin --id.secret org$2-fab-admin-pw -u https://localhost:7054 --tls.certfiles tls-root-cert/tls-ca-cert.pem --mspdir tls-ca/${TLScreds[0]}/msp

# Also siphon off the Fab CA credentials into their own file under the fab-ca-server directory for later use if need be. (Although, big ol' WARNING, probably not a good idea to leave these around on a true production server.)
echo "org$2-fab-admin:org$2-fab-admin-pw" > fab-creds.txt;

# Now, we enroll the Fab CA admin. Again, it's going to look similar to the enroll command in the previous script with the username and password being the ones we've just registered, and the --mspdir NOW pointing to where we store the key and public cert of the Fab CA admin for later use.
echo "./fabric-ca-client enroll -d -u https://org$2-fab-admin:org$2-fab-admin-pw@localhost:7054 --tls.certfiles tls-root-cert/tls-ca-cert.pem --mspdir tls-ca/org$2-fab-admin/msp"
./fabric-ca-client enroll -d -u https://org$2-fab-admin:org$2-fab-admin-pw@localhost:7054 --tls.certfiles tls-root-cert/tls-ca-cert.pem --mspdir tls-ca/org$2-fab-admin/msp

#TODO: Once the key is generated, it's an ugly alphanumeric string. Renaming it to something like key.pem would be good since it will be needed to finally deploy the other CA (that is the Fab CA (remember this script only registers and enrolls the Fab CA admin, it doesn't set up the actual Fab CA Server. That's coming next script.)


