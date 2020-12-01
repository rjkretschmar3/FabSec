#!/bin/bash
# Written and maintained by Robert Kretschmar

# This small meta-script will just use the much larger 015 script to individually set each of the 
# Anchor Peers of the different Organizations for the fabsec-channel.

echo "Setting Org1's Anchor Peer...";
./015-designate-anchor-peers.sh 1 0
echo "Setting Org2'a Anchor Peer...";
./015-designate-anchor-peers.sh 2 0
echo "Done!"
