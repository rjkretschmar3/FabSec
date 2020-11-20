#!/bin/bash
# Written and maintained by Robert Kretschmar

# This script will take the channel creation transaction from the last script and submit it to the 
# ordering service. This will finalize the channel so that the peers can then join. (More about 
# joining a channel in the next script.)

# Let's jump on over to the Peer's directory!
echo "cd ../organizations/peerOrganizations/org1.fabsec.com/peers/peer0.org1.fabsec.com";
cd ../organizations/peerOrganizations/org1.fabsec.com/peers/peer0.org1.fabsec.com

# First, we have to set some environmental variables, specifically:
# 1) Set the FABRIC_CFG_PATH to the $PWD which is where the core.yaml file lives.
# 2) Since, by default, only admin identities of organizations that belong to the system channel's
# consortium can create a new channel, we need to set the CORE_PEER_MSPCONFIGPATH to that of org 1's
# admin which lives ../../msp. Now, two things to note here: i) That default may be changed at a later
# date depending on the security risks, and ii) in a environment where this peer would be on a different
# physical machine, I might do this all from the Org 1 Admin machine OR create an admin specifically
# for peer0. For now, just using the relative path works fine. (Even for production depending on the
# final layout of that specific environment.)
echo "export FABRIC_CFG_PATH=$PWD";
export FABRIC_CFG_PATH=$PWD
echo "export CORE_PEER_MSPCONFIGPATH=$PWD/../../msp/";
export CORE_PEER_MSPCONFIGPATH=$PWD/../../msp/

# Another thing is to talk to the Orderer, this peer will need the Orderer's TLS Root Cert. In a 
# real-world scenario, this would probably happen out-of-band, but for this project, I'll just copy
# it over from the Orderer Org.
echo "cp -R ../../../../ordererOrganizations/org0.fabsec.com/ca-client/tls-root-cert/ ./orderer-tls-root-cert/";
cp -R ../../../../ordererOrganizations/org0.fabsec.com/ca-client/tls-root-cert/ ./orderer-tls-root-cert/

# Now, let's send it!
echo "./peer channel create -o orderer0.org0.fabsec.com:6050 -c fabsec-channel -f ./channel-artifacts/fabsec-channel.tx  --outputBlock ./channel-artifacts/fabsec-channel.block --tls --cafile orderer-tls-root-cert/tls-ca-cert.pem"
./peer channel create -o orderer0.org0.fabsec.com:6050 -c fabsec-channel -f ./channel-artifacts/fabsec-channel.tx  --outputBlock ./channel-artifacts/fabsec-channel.block --tls --cafile orderer-tls-root-cert/tls-ca-cert.pem
