#!/bin/bash
# Written and maintained by Robert Kretschmar

# This is one of the meta-scripts which uses the other scripts in this project to batch a job, in
# this case that would be establishing the Peer Organization 1.

# NOTE: For non-Linux users the & after some of the scripts means that I background the command
# after it's executed. This is because starting up jobs like the servers are run-until-canceled
# processes which means execution of this meta-script stops. Backgrounding those jobs  keeps the 
# flow of the script going. However, to avoid future commands from executing until prior commands 
# are finished, I'll introduce small waits after a backgrounded script. 

echo "Creating Peer Organization 1..."
echo "Deploying the TLS Server..."
./001-deploy-new-tls-ca-server.sh peer 1 meta &
sleep 2
./002-enroll-tls-admin-with-tls-server.sh peer 1
./003-register-enroll-fab-ca-admin-with-tls-server.sh peer 1
echo "Deploying Fabric Identity Server..."
./004-deploy-new-fab-ca-server.sh peer 1 meta &
sleep 2
./005-enroll-fab-admin-with-fab-server.sh peer 1
./006-register-enroll-org-admin-with-fab-server.sh peer 1
echo "Peer Organization 1 Created!"
