#!/bin/bash

# This script will initialize and deploy an Organization's Fabric CA Server. There is a 
# bit of linguistic confusion here as the official documentation calls this the Organization 
# CA Server, but I fear this overloads the word "Organization"... not that Fabric CA Server 
# is any better, but it is a bit less overloaded.
#
# That being said, the purpose of this Fab CA Server, as opposed to the TLS CA Server, is to 
# manage identities that will be used heavily on the whole of the network. It fills the 
# "permissioned" quality of the network. I'll explain more as we hit different responsibilities
# of this server. For now, let's initialize and deploy it.
#
# As with the other scripts, we have the commandline arguments being ~orderer~ or ~peer~ and 
# the ID number of the org in question.
#
# Also, like the TLS Deployment script (001), this script assumes the directory structure for
# the Fab Server of organizations/{orderer|peer}Organizations/org{ID#}.fabsec.com, and 
# specifically the fab-ca-server directory under that tree.

# First, as always, let's move to the correct working directory.
if [[ "$1" == "orderer" ]]; then
        echo "cd ../organizations/ordererOrganizations/org$2.fabsec.com/fab-ca-server";
        cd ../organizations/ordererOrganizations/org$2.fabsec.com/fab-ca-server;
elif [[ "$1" == "peer" ]]; then
        echo "cd ../organizations/peerOrganizations/org$2.fabsec.com/fab-ca-server";
        cd ../organizations/peerOrganizations/org$2.fabsec.com/fab-ca-server;
else
        echo "Unsure if Orderer or Peer organization!";
        echo "Pro-tip: proper use of this script comes in the form of: ";
        echo -e "\t$0 <orderer|peer> <ID#> [meta]";
        exit;
fi

# Next, remind the operator that this is a destructive script...
# EDIT: Skip this part if run by a meta script.
if [[ "$3" != "meta" ]]; then
	read -p "This script is for initializing a new Fab CA server. If you have an existing Fab CA server, \
	this will destroy the old key material, not to mention the YAML file, requiring all participants \
	to re-register and re-enroll. If you have an initialized server already, use the non-destructive \
	start-fab-server.sh script instead. Are you sure you want to continue? [y/N] " prompt

	if [[ $prompt != "y" && $prompt != "Y" ]]; then
		echo "A wise choice, exiting...";
		exit;
	fi
fi

# First remove the old config file and the old key material
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
echo "rm -R ./msp/";
rm -R ./msp/

# Then, grab the credentials from the fab-creds.txt file. 
echo "IFS=':' read -ra creds <<< \$(cat fab-creds.txt)";
IFS=':' read -ra creds <<< $(cat fab-creds.txt);

# Next, we want to copy over the organization CA TLS certificate and key pair that was 
# generated in script 003. The cert.pem is the admin's X.509 certificate which is how 
# they identifies themselves to the TLS server (in lieu of credentials) and lives in 
# ca-client/tls-ca/<fab-admin>/msp/signedcerts/ directory. The key.pem, or what we ended up 
# renaming to key.pem, is the signing key for the admin and lives in a similar location to 
# above but msp/keystore/ directory. These will be conveniently place in a directory called tls/

echo "cp ../ca-client/tls-ca/${creds[0]}/msp/signcerts/cert.pem tls/";
cp ../ca-client/tls-ca/${creds[0]}/msp/signcerts/cert.pem tls/
echo "cp ../ca-client/tls-ca/${creds[0]}/msp/keystore/key.pem tls/";
cp ../ca-client/tls-ca/${creds[0]}/msp/keystore/key.pem tls/

# Now, just like with the 001 script and the TLS CA Server, we're going to initialize the Fab 
# CA Server and bootstrap its admin.

echo "./fabric-ca-server init -b ${creds[0]}:${creds[1]}"
./fabric-ca-server init -b ${creds[0]}:${creds[1]}

# ================================ NOT USED IN TESTING ============================================
# That was easy. But, this next part isn't. At least until I research that 'yq' program to 
# help automate this. The previous step generated the default fabric-ca-server-config.yaml
# file that we'll need to edit in vim. Again, I'll echo out some helpful details to the 
# operator before they enter vim to guide them on what to change. (It's a bit more than just
# what the TLS server had to.)

# echo "This script will now open the YAML configuration file.";
# echo "Some fields to be changed: "
# echo -e "\tport - The port to operate on. Needs to be changed to 7055 for the Fab CA Server."
# echo -e "\ttls.enabled - Change to true."
# echo -e "\ttls.certfile - Relative path and filename for the TLS CA signedcert. This is the " \
#	"cert.pem we just copied into the local tls directory."
# echo -e "\ttls.keystore - Relative path and filename fort the TLS CA private key. This is " \
#	"the key.pem we just copied into the local tls directory."
# echo -e "\tca.name - Change to org$2-fab-ca."
# echo -e "\tcsr.hosts - Check that the hostnames are in order."
# echo -e "\toperations.listenAddress - Since we have the TLS CA on this same host we need to change " \
#	"this to 9444."
# echo -e "\tsigning.profiles - Delete the ~tls~ profile."
# read -p "Press [Enter] to enter vim..."

# echo "vim fabric-ca-server-config.yaml"
# vim fabric-ca-server-config.yaml
# echo "Done!"

# echo "If you have a pre-configured YAML file, please copy it over to $PWD before continuing.";
# read -p "Press [Enter] to continue script...";
# The above portion was to make this script more dynamic, however for the project static is fine.
# Worth keeping for future use, however.
# For now, we'll copy over the pre-configured YAML file from the test-configs directory.
cp ../../../../test-configs/org$2/fab-config/fabric-ca-server-config.yaml ./

#The following section will start the server.

# In case the CSR block of the YAML file has been changed in the vim step above, delete the
# TLS CA cert ca-cert.pem and the entire tls-ca-server/msp directory. These will be
# regenerated with the newly populated config information when the servers starts up next
# time.

echo "rm ./ca-cert.pem";
rm ./ca-cert.pem
echo "rm -R ./msp/";
rm -R ./msp/

# Finally start the Fabric CA Server (aka Organizational CA Server, aka the Enrollment CA Server, aka the eCert Server)
echo "./fabric-ca-server start"
./fabric-ca-server start 2>&1 fab-server-logs.txt
