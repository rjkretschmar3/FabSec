/*
 * File: watch-and-commit-logs.js
 * Programmer: Robert Kretschmar
 * Project CPSC 597
 * Description: This is the main workhorse of the backend series of JS files. It will
 * monitor the logfile for its particular Organization and then commit any now entries
 * to the Blockchain.
*/

'use strict';

// Require the needed libraries
const fs = require('fs');
const readline = require('readline');
const path = require('path');
const yaml = require ('js-yaml');
const { Gateway, Wallets } = require('fabric-network');

// The logfile to monitor
const logfile = '/var/log/syslog'; //'./logfile';

// This is a bit of pre-processing. It will skip the currently existing lines in the
// logfile. This will not only stop the repeating old entries on a reboot of this process,
// but also get the monitoring section up-to-speed to where the new entries will be coming
// in (i.e. the end of the logfile).
var file = fs.readFileSync(logfile).toString();
var lines = file.split('\n');
var currentCount = lines.length-1;
console.log(`Skipping ${currentCount} existing lines of logfile ${logfile}...`);

async function watchAndCommitLogs() {
	try {
		// First, we load in the necessary Connection Profile. For ease, this will be
                // the same for both Peer Orgs, however each would have their own version. More
                // on the connection profile in the comments of the profile itself.
		const connProfPath = path.resolve(__dirname, 'gateway', 'fabsec-connection-profile.yaml');
		console.log(`Loading Connection Profile from ${connProfPath}`);
		const connProf = yaml.safeLoad(fs.readFileSync(connProfPath, 'utf8'));

		// Then, we need to generate a Filesystem Wallet object which we'll grab the user
                // identity from.
		const walletPath = path.resolve(__dirname, 'wallet');
		const wallet = await Wallets.newFileSystemWallet(walletPath);
		console.log(`Current wallet path is ${walletPath}`);

		// Check to see if the App User identity exists, otherwise we can't move forward.
		const identity = await wallet.get('org1-app-user');
		if (!identity) {
			console.log('An identity for the user "org1-app-user" does not exist in the wallet');
			console.log('Run the registerUser.js application before retrying.');
			return;
		}

		// Now, let's get a Gateway object primed to access our network through! A Gateway
		// allows us to abstract away the details of how we connect to the network using
		// the Connection Profile and a process called Discovery where our Organization's
		// Anchor Peer will update us on the network topography. This has the added benefit of
		// letting other peers and orderers come and go dynamically. More on this in the formal
		// report.
		console.log('Connecting through Gateway as "org1-app-user" with Discovery...');
		const gateway = new Gateway();
		await gateway.connect(connProf, {
			wallet: wallet, 
			identity: 'org1-app-user', 
			discovery: { 
				enabled: true,
				asLocalhost: false
			}
		});
		
		// Now, we can get the network (channel) to which our contract is deployed.
		console.log('Getting the network "fabsec-channel"...');
		const network = await gateway.getNetwork('fabsec-channel');
	
		// Then, we pick out which contract we'd like to use. For the purposes of this
		// project, there is only one. However, this is great for adding more functionality
		// in the future.
		console.log('Getting the contract "logaggr"...');
		const contract = network.getContract('logaggr');

		// watch for changes to the logfile, and commit new entries to the blockchain.
		// Finally, we will monitor the logifle for changes and then commit them to the 
		// Blockchain through our Abstraction (Gateway->Network->Contract) into it.
		console.log('Done! Client connected to FabSec Network...');
		console.log('Moving to log watch and committing changes to the blockchain...');
		fs.watchFile(logfile, { interval: 5000 }, async (curr, prev) => {
			// We want to make sure that we're not commiting old data. So, this assumes the
			// logfile never gets cleaned out. Of course, in a real world deployment, I'd
			// make this more robust.
			if (curr.size != prev.size) {	
				var file = fs.readFileSync(logfile).toString();
				var lines = file.split('\n');

				console.log('New entries found! Committing to blockchain...');
				for (; currentCount < lines.length-1; currentCount++) {
					console.log("Entry: " + lines[currentCount]);
					await contract.submitTransaction('addMessage', 'org1-app-user',
						new Date().toDateString(), lines[currentCount]);
					}
				console.log('Done!');
			}
		});
		// This is just a formality. This would never get hit as our loop above is infinite. Again,
		// in a production environment, we'd most likey stick this and other "clean-up" code into
		// a functions that will catch the SIGINT needed to break the loop.
		await gateway.disconnect();

	// General error handling for debugging.
	} catch (error) {
		console.error(`Failed to submit transaction: ${error}`);
		process.exit(1)
	}
}

watchAndCommitLogs();

