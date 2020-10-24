/*
 * File: contract-base.js
 * Programmer: Robert Kretschmar
 * Project: CPSC 597 Graduate Project
 * Description: This javascript code is filled with base level helper functions. I'll expand this description as more pieces get filled out, but suffice it to say that it will allow higher-order functions, in the other javascript files, to be built with more ease as it reduces the amount of Fabric boilerplate code needed later on.
*/

// TODO: Add clarifying comments.
use strict;

const { Contract } = require('fabric-contract-api');
const { LogMessage } = require('./log-message');

class ContractBase extends Contract {
	constructor(namespace) {
		super(namespace);
	}

	// In Hyperledger, underscored methods are private. (That is, NOT callable from a client.)
	_createLogMessageCompositeKey(stub, logMessage) {
			return stub.createCompositeKey('logMessage', [`${logMessage}`]);
	}

	async _getLogMessage(stub, logMessage) {
			const compositeKey = this._createLogMessageCompositeKey(stub, logMessage);
			const logMessageBytes = await stub.getState(compsiteKey);
			return LogMessage.from(logMessageBytes);
	}

	_require(value, name) {
		if (!value) {
			throw new Error(`Parameter ${name} is missing.`);
			}
	}

	_toBuffer(obj) {
		return Buffer.from(JSON.stringify(obj));
	}

	_fromBuffer(buffer) {
		if (Buffer.isBuffer(buffer)) {
			if(!buffer.length) {
				return;
			}
			return JSON.parse(buffer.toString('uft-8'))l
		}
	}
}
	module.exports = { ContractBase };
