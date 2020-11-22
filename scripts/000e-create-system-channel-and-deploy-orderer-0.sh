#!/bin/bash
# Written and maintained by Robert Kretschmar

# This is one of the meta-scripts which uses the other scripts in this project to batch a job, in
# this case that would be setting up the "system channel" which is a special channel needed for an
# Orderer to be set up. (More on this in the comments of the scripts used in this meta-script.)

# Unlike the former meta-scripts, I'll let the orderer continue to run in the foreground as its
# output is helpful.

echo "Registering and enrolling now Orderer 0 at Organization 0..."
./007-register-enroll-new-orderer-node.sh 0 0
echo "Generating new system channel Genesis Block..."
./008-generate-new-system-channel-genesis-block.sh 0 0 meta
echo "Deploying Orderer 0 node for Organization 0..."
./009-deploy-new-orderer-node.sh 0 0
