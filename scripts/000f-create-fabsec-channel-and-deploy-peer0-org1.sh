#!/bin/bash
# Written and maintained by Robert Kretschmar

# Another metascript; this time it will register and enroll peer 0 at organization 1, generate the
# fabsec application channel creation transaction, generate the fabsec channel block from that transaction,
# deploy peer0, and join it to the channel. You can read further into what each of those things mean in their
# individual scripts.

# One unique thing is because I have to deploy the peer before I join it, but the peer is one of those run-
# until-canceled processes, I will temporarily background the process, join it, and bring it back to the
# foreground. This is becasue, much like the orderer, the output of the peer is actually helpful for debugging,
# testing chaincode, and just generally knowing what's going on. : )

echo "Registering and enrolling peer 0 at organization 1...";
./010-register-enroll-new-peer-node.sh 1 0
echo "Generating the fabsec application channel Creation Transaction...";
./011-generate-new-fabsec-channel-creation-transaction.sh
echo "Generating the fabsec channel Genesis Block...";
./012-generate-new-fabsec-channel-block.sh
echo "Deploying and backgrounding peer 0 node...";
./013-deploy-new-peer-node.sh 1 0 &
PEER_PID=$!
sleep 2 # wait a bit for it to fully deploy.
echo "Joining peer to fabsec-channel..."
./014-join-peer-node-to-fabsec-channel.sh 1 0
kill -CONT PEER_PID # bring the peer back!
