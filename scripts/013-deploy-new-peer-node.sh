#!/bin/bash
# Written and maintained by Robert Kretschmar

# This script will deploy a peer node. Since most of the information needed by the peer is already
# set in the core.yaml config file, this will be pretty straight forward. By starting a peer, it is
# not joined to any channel. That'll come next. It is merely a server to be commanded via either
# the peer binary on the commandline (through subcommands like join or any of the lifecycle 
# sub-commands) or to be interacted with through an application (such as updating or querying the
# ledger.)

# Since this is another general script, we'll take in commandline arguments for exacting which peer
# we are talking about as well as which organization that peer is under.
if (( $# != 2 )); then
	echo "Incorrect amount of arguments!!";
	echo "Pro-tip: proper use of this script comes in the form of:";
	echo -e "\t$0 <Org ID#> <Peer ID#>";
	exit;
fi

# Now, traverse to the proper directory...
echo "cd ../organizations/peerOrganizations/org$1.fabsec.com/peers/peer$2.org$1.fabsec.com";
cd ../organizations/peerOrganizations/org$1.fabsec.com/peers/peer$2.org$1.fabsec.com;

# Set debug logging level. (Comment out when not needed.)
# export FABRIC_LOGGING_SPEC=debug

# I talked about this in greater detail in 012, but to find the core.yaml config file, I'll set the
# FABRIC_CFG_PATH to the PWD. 
echo "export FABRIC_CFG_PATH=$PWD";
export FABRIC_CFG_PATH=$PWD;

# Let's fire up the node!!
echo "./peer node start";
./peer node start;
