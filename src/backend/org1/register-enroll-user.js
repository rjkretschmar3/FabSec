/*
 * File: register-enroll-user.js
 * Programmer: Robert Kretschmar
 * Project: CPSC 597
 * Description: This file will register and enroll the Org1 App User which will be the indentity
 * that we will need to interact with the Chaincode functions.
*/

'use strict';

// Require the needed libraries.
const { Wallets } = require('fabric-network');
const FabricCAServices = require('fabric-ca-client');
const yaml = require('js-yaml');
const fs = require('fs');
const path = require('path');

// All of these will need to be wrapped up in async functions as they themselves use
// async functions for various parts of the system.
async function registerEnrollUser() {
	try {
		// First, we load in the necessary Connection Profile. For ease, this will be
                // the same for both Peer Orgs, however each would have their own version. More
                // on the connection profile in the commnetos of the profile itself
		const connProfPath = path.resolve(__dirname, 'gateway', 'fabsec-connection-profile.yaml');
		const connProf = yaml.safeLoad(fs.readFileSync(connProfPath, 'utf8'));

		// Next, we want to connect to the Fabric CA of the Organization that we are
                // currently acting under. Remember that the Fabric CA is responible for the
                // identities on the network, and so to get Client identities we will need to
                // talk to it. This is done through the FabricCAServices object.
		const caInfo = connProf.certificateAuthorities['org1-fab-ca'];
		const caURL = caInfo.url;
		const caTLSCert = fs.readFileSync(caInfo.tlsCACerts.path); 
		const ca = new FabricCAServices(caURL, {
			trustedRoots: caTLSCert,
			verify: true
		}, caInfo.caName);

 		// Then, we need to generate a new Filesystem Wallet into which we'll store
                // the user indentity in. This is all done through the Wallets class.
		const walletPath = path.resolve(__dirname, 'wallet');
		const wallet = await Wallets.newFileSystemWallet(walletPath);
		console.log(`Setting new wallet path to ${walletPath}`);

 		// Of course, let's put a check in here to make sure the user doesn't already
                // exist.
		const userIdentity = await wallet.get('org1-app-user');
		if (userIdentity) {
			console.log('An identiy for the user "org1-app-user" already exists ' +
				'in the wallet');
			return;
		}
		
		// Here, since we're using the App Admin to register and enroll the new user
		// identtity, we need to make sure that the admin exists.
		const adminIdentity = await wallet.get('org1-app-admin');
		if (!adminIdentity) {
			console.log('An identity for the admin user "org1-app-admin" does not ' +
				'yet exist in wallet...');
			console.log('Run the enrollAdmin.js application before retrying!');
			return;
		}

		// As mentioned before, we need to act as admin, so let's grab the necessary
		// admin information.
		console.log('Using org1-app-admin identity for authentication...');
		const provider = wallet.getProviderRegistry().getProvider(adminIdentity.type);
		const adminUser = await provider.getUserContext(adminIdentity, 'org1-app-admin');

		// Now we are free to register the user, enroll the user, and import that new 
		// identity into the wallet.
		console.log('Registering org1-app-user...');
		const secret = await ca.register({
			enrollmentID: 'org1-app-user',
			role: 'client'
		}, adminUser);
		console.log('Enrolling org1-app-user...');
		const enrollment = await ca.enroll({
			enrollmentID: 'org1-app-user',
			enrollmentSecret: secret
		});
		console.log('Building x509 Identity...');
		const x509Identity = {
			credentials: {
				certificate: enrollment.certificate,
				privateKey: enrollment.key.toBytes()
			},
			mspId: 'PeerOrg1MSP',
			type: 'X.509'
		};
		await wallet.put('org1-app-user', x509Identity);
		console.log('Successfully registered and enrolled admin user "org1-app-user" ' +
			'and imported it to wallet');

	// Again, catch any falling errors.
	} catch (error) {
		console.error(`Error: Failed to register user "org1-app-user": ${error}`);
		process.exit(1);
	}
}

registerEnrollUser();

