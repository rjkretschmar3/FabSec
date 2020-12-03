/*
 * File: index.js
 * Programmer: Robert Kretschmar
 * Project: CPSC 597 -- Distributed Log Aggregator
 * Description: This is the Chaincode to send and receive logfile entries to and from the
 * Blockchain. 
*/

'use strict';

// Require the nescessary libraries/modules
const { Contract } = require('fabric-contract-api');
const LogMessage = require('./log-message');

// A global ID to keep the Keys unique since we'll be pooling log messages from different
// sources.
var ID = 1;

// This is the main workhorse of the smart contract. It will get and set messages from/to
// the blockchain.
class LogAggr extends Contract {
	// In practice, we probably won't need an init function, but I put it in here if the
	// class takes a turn where we will need to do some initialization before we can use
	// the other functions.
	async initLedger(ctx) {
		console.info('initLedger called!');
		
		// Populate the LogMessage Data Structure, and print a console message.
		var initLM = new LogMessage(ID, 'fabsec-init', new Date(), 'System Initialized');
		console.info('Crafting initial record: {' + initLM.id + ', ' +
			initLM.user + ', ' + initLM.date.toDateString(), initLM.message + '}');
		// Update the ID
		ID++;

		// The ctx variable is the Transaction's current Context. It has a lot of functionality
		// but we will use the "stub" part to access the PutState() function. This function is
		// how we access the blockchain to write data to it.
		console.info('Committing record to the blockchain');
		await ctx.stub.putState(initLM.id.toString(), 
				Buffer.from(JSON.stringify(initLM.getJSONRep())));
		console.info('Done!');

		console.info('Ending initLedger...');
		return 'initLedger compeleted!';
	}

	// This function is the same as the init function, but it allows the user to put their own
	// messages on the blockchain. In the case of this project, this will be the log messages
	// as read from the logfile and delivered by the watch-and-commit-logs.js module.
	async addMessage(ctx, user, date, message) {
		console.info('addMessage called!');
		
		// Craft a new LogMessage object.
		var newMesg = new LogMessage(ID, user, date, message);
		console.info('Crafting new record: {' + newMesg.id + ', ' +
			newMesg.user + ', ' + newMesg.date + newMesg.message + '}');
		// Update the global ID
		ID++;

		// And use the stub within the TX Context to put the message on the blockchain.
		console.info('Committing record to the blockchain..');
		await ctx.stub.putState(newMesg.id.toString(), 
				Buffer.from(JSON.stringify(newMesg.getJSONRep())));
		console.info('Done!');

		console.info('Ending addMessage..');
		return 'Added message: ' + newMesg.id + ', ' +
			newMesg.user + ', ' + newMesg.message;
	}

	// This function will be used to grab the entries from the Blockchain. In this project,
	// we'll grab all of them, and let the frontend deal with how to deliver them to the
	// End User. However, a future idea would be to allow different types of searches within
	// the chaincode itself to reduce the work needed to be done. Especially if the user is
	// only looking for the most recent log entries.
	async queryAllMessages(ctx) {
		console.info('queryAllMessages called!');
		
		// For the getStateByRange function within the stub API, one get the beginning of
		// the State List with an empty Key, and same with the end of the State List.
		const startKey = '';
		const endKey = '';
		const allResults = [];
		
		// Go ahead and grab the entries. This is a simple loop to run through the Range
		// Iterator and grab each of the records to store in a return list.
		console.info('Gathering all messages...');
		for await (const {key, value} of ctx.stub.getStateByRange(startKey, endKey)) {
			const strValue = Buffer.from(value).toString();
			let record;
			try {
				record = JSON.parse(strValue);
			} catch (err) {
					console.log(err);
					record = strValue;
			}
			allResults.push({ Key: key, Record: record });
		}

		// Once we're done, let's go ahead and send the data back!
		console.info(allResults);
		console.info('Ending queryAllMessage..');
		return JSON.stringify(allResults);
	}
}


module.exports = LogAggr;
