/*
 * File log-message.js
 * Programmer: Robert Kretschmar
 * Project: CPSC 597 -- Distributed Log Aggregator
 * Description: This is a my LogMessage Class. It is a data structure to help facilitate
 * the storing of a Log Message.
*/

 'use strict';

class LogMessage {
	// The constructor takes the inital values to set the LogMessage Object to.
	constructor(id, u, d, m) {
		this.id = id;
		this.user = u;
		this.date = d;
		this.message = m;
	}

	// The JSON Representation is just nice version of the object to have when
	// displaying.
	getJSONRep() {
		return { 
			id: this.id, 
			user: this.user, 
			date: this.date, 
			message: this.message 
		};
	}
}

module.exports = LogMessage;
