/*
 * File log-message.js
 * Programmer: Robert Kretschmar
 * Project: CPSC 597 Graduate Project
 * Description: This is the LogMessage class code. A log message is a convinent way to store
 * not only the message itself, but some metadata for it too.
 */

use strict;

class LogMessage {
	constructor() {
		this.host = "";
		this.user = "";
		this.date = "";
		this.level = "";
		this.message = "";
	}

	// helper functions for writing to and reading from Fabric's world state
	static from(bufferOrJson) {
	
		if (Buffer.isBuffer(bufferOrJson)) {
			// if there is no data, return a default object;
			if (!bufferOrJson) {
				return;
			}

			bufferOrJson = JSON.parse(bufferOrJson.toString('utf8');
		}

		return Object.assign(new LogMessage(), bufferOrJson);
	}

	toBuffer() {
		return Buffer.from(JSON.stringify(this));
	}
}

module.exports = { LogMessage };
