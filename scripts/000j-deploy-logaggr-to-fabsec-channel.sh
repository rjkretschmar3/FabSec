#!/bin/bash
# Written and maintained by Robert Kretschmar

# This is the last meta-script (I think... hopefully) which will deploy the chaincode. My chaincode
# for this project is called LogAggr for Log Aggregator. As with most of these meta-scripts, the main
# magic is in the base script. (As well as the comments on how it works.) This is mostly here for
# meta-script flow for the presentation.

echo "./016-deploy-chaincode-to-fabsec-channel.sh logaggr 1";
./016-deploy-chaincode-to-fabsec-channel.sh logaggr 1
