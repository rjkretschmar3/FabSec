/*
 * File: enroll-admin.js
 * Programmer: Robert Kretschmar
 * Project: CPSC 597
 * Description: This file will enroll the Admin user which is needed to register and enroll
 * our web users (clients, in Fabric Node OUs parlance). 
*/

'use strict';

// Require the needed libraries.
const FabricCAServices = require('fabric-ca-client');
const { Wallets } = require('fabric-network');
const yaml = require('js-yaml');
const fs = require('fs');
const path = require('path');

// All of these will need to be wrapped up in async functions as they themselves use
// async functions for various parts of the system.
async function enrollAdmin() {
	try {
		// First, we load in the necessary Connection Profile. For ease, this will be
		// the same for both Peer Orgs, however each would have their own version. More
		// on the connection profile in the commnetos of the profile itself
		const connProfPath = path.resolve(__dirname, 'gateway', 'fabsec-connection-profile.yaml');
		console.log(`Loading Connection Profile from ${connProfPath}`);
		const connProf = yaml.safeLoad(fs.readFileSync(connProfPath, 'utf8'));

		// Next, we want to connect to the Fabric CA of the Organization that we are
		// currently acting under. Remember that the Fabric CA is responible for the
		// identities on the network, and so to get Client identities we will need to
		// talk to it. This is done through the FabricCAServices object.
		const caInfo = connProf.certificateAuthorities['org2-fab-ca'];
		const caTLSCert = fs.readFileSync(caInfo.tlsCACerts.path);
		const ca = new FabricCAServices(caInfo.url, {
			trustedRoots: caTLSCert, 
			verify: true
			},
			caInfo.caName);

		// Then, we need to generate a new Filesystem Wallet into which we'll store
		// the admin identity. This is all done through the Wallets class.
		const walletPath = path.resolve(__dirname, 'wallet');
		const wallet = await Wallets.newFileSystemWallet(walletPath);
		console.log(`Setting new wallet path to ${walletPath}`);
	
		// Of course, let's put a check in here to make sure the admin doesn't already
		// exist. 
		const identity = await wallet.get('org2-app-admin');
		if (identity) {
			console.log('An identity for the admin user "org2-app-admin" ' + 
				'already exists in the wallet');
			return;
		}

		// If we've made it here, the admin doesn't exist so let's enroll. A point to
		// note here is an "enrollment" operation just means that we're pulling the 
		// existing credentials over. We're not creating a new admin, per se, as that is
		// a "register" action. The credentials that we're pulling over are the Fab Admin's
		// (as evidenced by the ID/Secret combination). In this context, we're calling them
		// the App Admin, but it's the same identity.
		const enrollment = await ca.enroll({ 
			enrollmentID: 'org2-fab-admin', 
			enrollmentSecret: 'org2-fab-admin-pw'
		});

		// Once we have the enrollment return values we can craft our identity and store it
		// in the Wallet for later use.
		const x509Identity = {
			credentials: {
				certificate: enrollment.certificate,
				privateKey: enrollment.key.toBytes()
			},
			mspId: 'PeerOrg2MSP',
			type: 'X.509'
		};
		await wallet.put('org2-app-admin', x509Identity);
		console.log('Successfully enrolled admin user "org2-app-admin" and imported their' +
			' identity into the wallet');

	// Catch any falling errors. For now, we can leave this pretty general to just guide debugging.
	} catch (error) {
		console.error(`Error: Failed to enroll admin user "org2-app-admin" => ${error}`);
		process.exit(1);
	}
}

enrollAdmin();
