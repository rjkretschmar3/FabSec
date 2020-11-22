#!/bin/bash
# Written and maintained by Robert Kretschmar

# Another metascript; this time it will register and enroll peer 0 at organization 2, fetch the fabsec-channel
# Genesis Block, and the join the fabsec-channel.

# Again, I'll play musical processes with the peer to get it join after its deployed, and then bring it back
# for its delicious, delicious output.
echo "Registering and enrolling peer 0 at organization 2...";
./010-register-enroll-new-peer-node.sh 2 0
echo "Deploying and backgrounding peer 0 node...";
./013-deploy-new-peer-node.sh 2 0 &
PEER_PID=$!
sleep 2 # wait a bit for it to fully deploy.
echo "Fetching the fabsec-channel Genesis Block and joining fabsec-channel...";
./014-join-peer-node-to-fabsec-channel.sh 2 0
wait $PEER_PID # bring the peer back!
