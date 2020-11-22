#!/bin/bash
# Written and maintained by Robert Kretschmar

# This is one of the meta-scripts which uses the other scripts in this project to batch a job, in
# this case that would be establishing the Orderer Organization.

# NOTE: For non-Linux users the & after some of the scripts means that I background the command
# after it's executed. This is because starting up jobs like the servers are run-until-canceled
# processes which means execution of this meta-script stops. Backgrounding those jobs  keeps the 
# flow of the script going. However, to avoid future commands from executing until prior commands 
# are finished, I'll introduce small waits after a backgrounded script. 

echo "Creating Orderer Organization..."
echo "Deploying the TLS Server..."
./001-deploy-new-tls-ca-server.sh orderer 0 meta &
sleep 2
./002-enroll-tls-admin-with-tls-server.sh orderer 0
./003-register-enroll-fab-ca-admin-with-tls-server.sh orderer 0
echo "Deploying Fabric Identity Server..."
./004-deploy-new-fab-ca-server.sh orderer 0 meta &
sleep 2
./005-enroll-fab-admin-with-fab-server.sh orderer 0
./006-register-enroll-org-admin-with-fab-server.sh orderer 0
echo "Orderer Organization Created!"
