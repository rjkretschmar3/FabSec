# CPSC 597 Graduate Project - On the Applications of Consortium Blockchain Technology as a Dedicated Security Network Deployment

These are the internals (script, source code, and binaries) of my CPSC 597 Graduate Project. This is written, administered, and maintained by Robert Kretschmar. FabSec (short for Fabric Security) is a exploration in the potential of using Hyperledger Fabric's Distributed Ledger Technology as a dedicated security network. The hope is that this could one day be applied to non-permissioned and/or public blockchains in future work.

The choice to start with using Fabric for this idea was the ability to start up multiple private blockchains for the different security tasks. The Proof-of-Concept will be a single blockchain, or Channel in Hyperledger parlance, to be used as a distributed log aggregator with hot-swapable node and no single point of failure.

### Design Decisions
	#### TLS Certificate Authority
		* There will be a dedicated TLS CA for each Organization (the Orderer and both Peers).
		* There will not be any Intermediate CAs. (Although, definitely worth looking into for scalability.)

### The CA Servers
	Here is one of the parts that can get confusing: there are technically TWO different CA Servers per Organization. One is the TLS CA Server which secures the communications of the different nodes on a single intranet or, in other words, the internal network of a single organization. These are relatively straight-forward in their purpose. 
	The other server is that of the Fabric CA Server which handles all of the identities for an Organization *in reference to* the Fabric internet, that is, the combined network of all participating Organizations.
	What makes this a bit confusing is that it is the same binary for both and only what you set in the individual configuration files is what that server ends of becoming. So, there's a lot of overlap between the two in the following information. However, I will mostly be talking about the Fabric CA Server from here on as that is the more important component of the network as a whole. (If I need to make it explicit that I am talking about the TLS server, I will do so at the time of writing.) 

	For illustrative purposes, the Fabric CA Server I am talking about here is the Fabric-CA Root Server of the following diagram:

	![CA Server Diagram](/images/fabric-ca.png)
	*Image borrowed from https://hyperledger-fabric-ca.readthedocs.io/en/latest/users-guide.html#initializing-the-server*

### Notes about fabric-ca-server-config.yaml
	The following configuration fields from the given _fabric-ca-server-config.yaml_ configuration file have been changed from their defaults:
		* _ca_
			Here I just customize the _name_ of the server. For example the TLS-CA Server for Organization 1 will be something like tls-ca-org1 while Organization 1's Fabric CA would be named fab-ca-org1. _keyfile_, _certfile_, and _chainfile_ will be left blank.
	
		* _tls_
			This is one of the few times a TLS CA and a Fabric CA will diverge. For a TLS CA, all I need to do is change the _enabled_ flag to true. However, for a Fabric CA (which needs to use the key material from the Organization's TLS CA to do its communications), I also need to add the _certfile_ and _keyfile_ values that were generated when I initialized the TLS CA Server. (A consequence of this, of course, is when one sets up an Organization in the network, they will need to first fire up the TLS CA Server BEFORE the Fabric CA Server.) Specifically:
			* the _certfile_ (the TLS's signed certificate file) is found in the signedcerts directory of the TLS Server. (Typically named something like cert.pem.)
			* the _keyfile_ (the TLS's private key) is found in the keystore directory, and is named something like d1d030ba430db15f6ba714a99918e51948e45f846832e02za48934d9d9e3_sk.

		* _port_
			This is simply the port to be run on. Each Server should be running on its own port.
		* _affiliations_
			Affiliations is being mentioned here if I choose to eventually incorporate it into a more scaled up version. For now left default which is blank.

		* _csr_
			CSR (Certificate Signing Request) is where one would populate the root CA certificate with custom information. It needs to be filled out before running the server for the first time. Most are optional, however checking that _hosts_ has the proper hostnames is a good idea.

		* _signing_
			Here the defaults are fine for a production server with special attention paid to the _expiry_ field. Also, one should remove the _profile_ for the type of CA server that this one isn't going to be. _ca_ is the profile for a Fabric CA Server, and _tls_ is the profile for a -- surprise, surprise -- TLS CA Server.


MORE TO COME
