#!/bin/bash
# Written and maintained by Robert Kretschmar

# This script is where we start to change gears. Now that both the CA servers (TLS and 
# Fab) are up, we can register and enroll the Organizational Administrator (Org Admin).
# Doing this will essentially set up our Organization entity in the Fabric network.

# As usual, move to the appropriate directory.
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

# Next, since we're going to use the Fabric CA client to do these actions, set the
# environmental variable that it expects.
echo "export FABRIC_CA_CLIENT_HOME=$PWD"
export FABRIC_CA_CLIENT_HOME=$PWD

# Also, let's pull out the Fab Admin CA username from the fab-creds.txt file to
# dynamically get the username which doubles as the name of the directory where the
# MSP resides for authenticating the register command.

echo "IFS=':' read -ra creds <<< \$(cat ../fab-ca-server/fab-creds.txt)"
IFS=':' read -ra creds <<< $(cat ../fab-ca-server/fab-creds.txt)

# Now, let's register the Org admin. A few notes to keep in mind...
#	1) Org Admins, unlike the Fab Admin or TLS Admin, don't need to be registered and
#		enrolled with the TLS server, just the Fab Server. (However, the subsequent
#		nodes (Peers and Orderer) will have to be registered/enrolled with both.
# 	2) As mentioned above, since this is a register command, we need the Fab CA Admin's
#		MSP pointed to by the --mspdir flag.
#	3) Along with the standard arguments that we send in, since this is a "user" identity,
#		we have a new argument of --id.type which will be of type 'admin'.

echo "./fabric-ca-client register -d --id.name org$2-org-admin --id.secret org$2-org-admin-pw --id.type admin -u https://hypertest:${creds[2]} --tls.certfiles tls-root-cert/tls-ca-cert.pem  --mspdir fab-ca/${creds[0]}/msp " 
./fabric-ca-client register -d --id.name org$2-org-admin --id.secret org$2-org-admin-pw --id.type admin -u https://hypertest:${creds[2]} --tls.certfiles tls-root-cert/tls-ca-cert.pem  --mspdir fab-ca/${creds[0]}/msp

# As usual, let's get the credentials into a text file for future use if need be.
echo "org$2-org-admin:org$2-org-admin-pw" > ../org-creds.txt;

# Now, we enroll the Org admin. Typically, the Fab CA Admin (who is presumably setting
# this up) will give the username/password to the Org Admin (or whoever is being enrolled).
# Again, this is just PKI best practices as the enrollment will generate, among other things,
# a secret key, and that should ONLY be exposed to the user whose it is.
#
# Also recall that since this is the Org Admin we are now enrolling, the returned MSP will
# effectively be the whole Organization's MSP. From there, we can start registering and enrolling
# the node identities.

echo "./fabric-ca-client enroll -d -u https://org$2-org-admin:org$2-org-admin-pw@hypertest:${creds[2]} " \
	"--tls.certfile tls-root-cert/tls-ca-cert.pem --mspdir ../msp"
./fabric-ca-client enroll -d -u https://org$2-org-admin:org$2-org-admin-pw@hypertest:${creds[2]} \
	--tls.certfiles tls-root-cert/tls-ca-cert.pem --mspdir ../msp

# EDIT: Now that we have the MSP directory for the Organization, we should also copy the NodeOUs
# config.yaml file into that MSP. The contents of which will change based on with org we are
# interacting with. They live in the meta-directory "test-configs/" NodeOUs are talked about more
# in depth in the README.
cp ../../../../test-configs/org$2/nodeOUs/config.yaml ../msp/.

# And, as always, rename the secret key from whatever ugly alphanumeric string they have it as
# to key.pem. Since these keys are placed in their own directories, namely keystore, under the
# MSP, we don't have to worry about the same filename stomping on other filenames. HOWEVER, if
# one where to take it out of that keystore, say for backup, they might want to name the actual
# key to something more meaningful.
echo "mv ../msp/keystore/*_sk ../msp/keystore/key.pem"
mv ../msp/keystore/*_sk ../msp/keystore/key.pem
