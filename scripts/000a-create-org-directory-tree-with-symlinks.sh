#!/bin/bash
#Written and maintained by Robert Kretschmar

# This is one of the structural scripts as denoted my having the prefix of 000 and a letter. This
# script in particular sets up the organizational directory structure. It will set up both the Orderer
# and Peers organizations. It will also make the appropriate symlinks to the CA Server, CA Client, Peer
# and Orderer binaries.

# As of now, the numbering is static reflecting the topography of one Orderer Org with one Orderer, and
# two Peers Orgs, one with one Peer and the other with two Peers. An idea for later would be to make the
# script more dynamic by letting the script operator choose how many of each gets set up with commandline
# arguments.

# Finally, this script assumes that it will be ran from the fabsec/scripts/ directory and will start the 
# directory tree at fabsec/organizations/ (Further assumes organizations/ directory tree doesn't already 
# exist.)

echo "This script will set up the organizational directory tree as well as symlink the appropriate " \
       "binaries from the fabsec/bin/ directory.";

# Start with the top of the tree.
echo "Moving to root directory, and creating organizations/ directory.";
cd ..
mkdir organizations/

# Set up Orderer Organization.
echo "Making Orderer Organization: ordererOrganizations/org0.fabsec.com/"
cd organizations/
mkdir ordererOrganizations/
cd ordererOrganizations/
mkdir org0.fabsec.com/
cd org0.fabsec.com/

# Set up orderers/
echo "Setting up orderers/ directory with orderer0.org0.fabsec.com..."
mkdir orderers/
cd orderers/
mkdir orderer0.org0.fabsec.com/
cd orderer0.org0.fabsec.com/
ln -s ../../../../../bin/orderer
mkdir ./blockstore/;
mkdir ./system-genesis-block/;

# Eventually, we'll need to collect the Peer Orgs MSPs into a local directory to feed into the configtxgen
# binary via the configtx.yaml file.
mkdir ./PeerOrgsMSPs/
cd ./PeerOrgsMSPs/
mkdir ./org1/
mkdir ./org2/
cd ..

# Set up the configtx directory with its own symlinked binary and YAML file
echo "Setting up orderer0's configtx directory..."
mkdir ./configtx/
cd ./configtx/
ln -s ../../../../../../bin/configtxgen
cp ../../../../../../test-configs/org0/orderer0/configtx.yaml
cd ../

# The orderer has a special set of directories needed for the Raft Consensus Protocol
echo "Setting up Raft Consensus Protocol directories...";
mkdir ./etcdraft/
cd ./etcdraft/
mkdir ./wal/
mkdir ./snapshot/
cd ../../../

# Set up ca-client/
echo "Setting up ca-client/ directory..."
mkdir ca-client/
cd ca-client/
mkdir fab-ca/
mkdir tls-ca/
mkdir tls-root-cert/
ln -s ../../../../bin/fabric-ca-client
cd ../

# Set up fab-ca-server/
echo "Setting up fab-ca-server/ directory..."
mkdir fab-ca-server/
cd fab-ca-server/
mkdir tls/
ln -s ../../../../bin/fabric-ca-server
cd ../

# Set up tls-ca-server/
echo "Setting up tls-ca-server/ directory..."
mkdir tls-ca-server/
cd tls-ca-server/
ln -s ../../../../bin/fabric-ca-server
cd ../

# Return to organizations
cd ../../

# Set up first Peer Organization.
echo "Making Peer Organization: peerOrganizations/org1.fabsec.com/"
mkdir peerOrganizations/
cd peerOrganizations/
mkdir org1.fabsec.com/
cd org1.fabsec.com/

# Set up peers/
echo "Setting up peers/ directory with peer0.org1.fabsec.com..."
mkdir peers/
cd peers/
mkdir peer0.org1.fabsec.com/
cd peer0.org1.fabsec.com/
ln -s ../../../../../bin/peer
mkdir ./blockstore/
mkdir ./channel-artifacts/

# Set up the configtx directory with its own symlinked binary and YAML file
echo "Setting up peer0's configtx directory..."
mkdir ./configtx/
cd ./configtx/
ln -s ../../../../../../bin/configtxgen
cp ../../../../../../test-configs/org0/orderer0/configtx.yaml
cd ../../

# Set up ca-client/
echo "Setting up ca-client/ directory..."
mkdir ca-client/
cd ca-client/
mkdir fab-ca/
mkdir tls-ca/
mkdir tls-root-cert/
ln -s ../../../../bin/fabric-ca-client
cd ../

# Set up fab-ca-server/
echo "Setting up fab-ca-server/ directory..."
mkdir fab-ca-server/
cd fab-ca-server/
mkdir tls/
ln -s ../../../../bin/fabric-ca-server
cd ../

# Set up tls-ca-server/
echo "Setting up tls-ca-server/ directory..."
mkdir tls-ca-server/
cd tls-ca-server/
ln -s ../../../../bin/fabric-ca-server
cd ../

# Return to peerOrganizations/
cd ../

# Set up second Peer Organization.
echo "Making Peer Organization: peerOrganizations/org2.fabsec.com/"
mkdir org2.fabsec.com/
cd org2.fabsec.com/

# Set up peers/
echo "Setting up peers/ directory with peer0.org2.fabsec.com/ and peer1.org2.fabsec.com/..."
mkdir peers/
cd peers/
mkdir peer0.org2.fabsec.com/
cd peer0.org2.fabsec.com/
ln -s ../../../../../bin/peer
mkdir ./blockstore/
mkdir ./channel-artifacts/
cd ../
mkdir peer1.org2.fabsec.com/
cd peer1.org2.fabsec.com/
ln -s ../../../../../bin/peer
mkdir ./blockstore/
mkdir ./channel-artifacts/
cd ../../

# Set up ca-client/
echo "Setting up ca-client/ directory..."
mkdir ca-client/
cd ca-client/
mkdir fab-ca/
mkdir tls-ca/
mkdir tls-root-cert/
ln -s ../../../../bin/fabric-ca-client
cd ../

# Set up fab-ca-server/
echo "Setting up fab-ca-server/ directory..."
mkdir fab-ca-server/
cd fab-ca-server/
mkdir tls/
ln -s ../../../../bin/fabric-ca-server
cd ../

# Set up tls-ca-server/
echo "Setting up tls-ca-server/ directory..."
mkdir tls-ca-server/
cd tls-ca-server/
ln -s ../../../../bin/fabric-ca-server
cd ../

# ...and we're done!
echo "Finished!"


