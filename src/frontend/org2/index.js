/*
 * File: index.js
 * Programmer: Robert Kretschmar
 * Project: CPSC 597 Distributed Log Aggregator
 * Description: This is my frontend to the project. It will be a simple Express home page that
 * will automatically bring up the logs from the blockchain. This is just to show the chaincode
 * functionaly to grab the logs. Of course, in a production setting, it would have a lot more
 * bells and whistles.
*/

'use strict';

// Require the necessary libraries.
const express = require('express');
const { Gateway, Wallets } = require('fabric-network');
const fs = require('fs');
const path = require('path');
const yaml = require('js-yaml');

// Since we're going to use async functions, we need to wrap them in an async function as well.
async function initEnvironAndRunFrontendServer() {

	// First, we need to grab a copy of the org2-app-user's credentials. The creation of these 
	// credentials is done via the backend. It is assumed that the backend modules have already 
	// been run, and thus these credentials already exist (since without a backend the frontend 
	// is pretty useless anyway, haha). So, check that that the credentials don't currently exist 
	// in the frontend's wallet, copy then over if not, and fail out of this whole module if the 
	// credentials don't exist in the backend.
	const credPath = path.resolve(__dirname, '..', '..', 'backend', 'org2', 'wallet', 'org2-app-user.id');
	fs.copyFile(credPath, './wallet/org2-app-user.id', (err) => {
		if (err) {
			console.log('An identity for the user "org2-app-user" does not seem to exist in the ' +
				'backend wallet...');
			console.log('Run the registerUser.js in the org2\'s backend directory before retrying.');
			console.log(`Offical error: ${err}`);
			process.exit(1);
		} else {
				console.log(`${credPath} copied to frontend wallet!`);
		}
	});

	// Also, let's load in the Connection Profile for the Gateway later. (More on the Connection
	// Profile in the paper. Suffice it to say, that it is a YAML layout of our network topography
	// for the Gateway to use.)
	const connProfPath = path.resolve(__dirname, 'gateway', 'fabsec-connection-profile.yaml');
	console.log(`Loading Connection Profile from ${connProfPath}`);
	const connProf = yaml.safeLoad(fs.readFileSync(connProfPath, 'utf8'));
	
	// Then, we need to generate a Filesystem Wallet object from which we'll grab the user identity.
	const walletPath = path.resolve(__dirname, 'wallet');
	const wallet = await Wallets.newFileSystemWallet(walletPath);
	const identity = await wallet.get('org2-app-user');
	
	// Now we connect to the Gateway. The Gateway class is explained further in the backend code's
	// comments.
	console.log('Connection through Gateway as "org2-app-user" with Discovery...');
	const gateway = new Gateway();
	await gateway.connect(connProf, {
			wallet: wallet,
			identity: 'org2-app-user',
			discovery: {
				enabled: true,
				asLocalhost: false
			}
	});
		
	// Now, we're going to pick out the channel (aka network) we're going to use, as well as the
	// contract which in the case of this project is 'logaggr'.
	console.log('Getting the network "fabsec-channel"...');
	const network = await gateway.getNetwork('fabsec-channel');
	console.log('Getting the contract "logaggr"...');
	const contract = network.getContract('logaggr');
	
	// Finally, with the overhead out of the way. start up an instance of the Express Web Server
	var fabsecDemoApp = express();

	// When the user connects to the website, we'll grab the logs from the blockchain (through the
	// chaincode), and display them.
	fabsecDemoApp.get('/', async (req, res) => {
		console.log('Grabbing the log entries from the blockchain!');
		const logs = await contract.evaluateTransaction('queryAllMessages');
		
		console.log('Done! Forwarding them to the calling browser!');
		res.send(JSON.parse(logs.toString()));
	});

	// Fire up the server!
	var fabsecDemoServer = fabsecDemoApp.listen(8082, "127.0.0.1", () => {
		var host = fabsecDemoServer.address().address;
		var port = fabsecDemoServer.address().port;

		console.log(`FabSec Demo Server - Org2 listening on http://${host}:${port}`);
	});
}

initEnvironAndRunFrontendServer();
