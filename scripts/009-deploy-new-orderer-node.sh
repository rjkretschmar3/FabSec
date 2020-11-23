#!/bin/bash
# Written and maintained by Robert Kretschmar

# This script will deploy an orderer node. Since all of the information that the orderer will
# need has been created into other scripts, and all of the configuration values are set in this
# project's pre-configuated files. This is a very simple script. I mostly have it for script 
# sequencing.

# So, let's make sure we have the correct number of arguments before moving on. If we do not,
# return a nice message to the user on how to use this script.
if (( $# != 2 )); then
        echo "Incorrect amount of arguments!!";
        echo "Pro-tip: proper use of this script comes in the form of:";
        echo -e "\t$0 <Org ID#> <Orderer ID#>";
        exit;
fi

# Set logging to debug. (Comment out when not needed.)
export FABRIC_LOGGING_SPEC=debug

# Then traverse over to the correct directory and set the configuration path envar.
echo "cd ../organizations/ordererOrganizations/org$1.fabsec.com/orderers/orderer$2.org$1.fabsec.com";
cd ../organizations/ordererOrganizations/org$1.fabsec.com/orderers/orderer$2.org$1.fabsec.com;
export FABRIC_CFG_PATH=$PWD
echo $FABRIC_CFG_PATH

# Then execute the orderer!
./orderer
