# CPSC 597 Graduate Project
## On the Applications of Consortium Blockchain Technology as a Dedicated Security Network Deployment

These are the internals (scripts, chaincode, and binaries) of my CPSC 597 Graduate 
Project. They are written/modified, administered, and maintained by Robert Kretschmar. 
The latest official Read the Docs for Hyperledger Fabric were used (release-2.2 at the 
time of writing) in guiding the building of this project, so much thanks to those 
giants on whose shoulders I stand. 
[Hyperledger Fabric's Read the Docs](https://hyperledger-fabric.readthedocs.io/en/release-2.2/)

FabSec (short for Fabric Security) is a exploration in the potential of using Hyperledger 
Fabric's Distributed Ledger Technology as a dedicated security network. Hyperledger is an 
ecosystem of different tools, libraries, and frameworks for creating different types of 
Blockchains: from private and permissioned ones to public and permissionless ones. 
Fabric is one of those Blockchain frameworks. It allows multiple actors to share a blockchain 
between them for any use case that they could think to apply it to. This project attempts to explore 
the use of this technology in the security space, namely having a dedicated security network between 
actors. These actors can be two (or more) organizations looking to join forces and pool security 
resources or, and this is how the idea start, to have a security for Wide-Area Network (WANs) and/or 
Metropolitan-Area Networks (MANs). An extended hope is that this could one day be applied to 
non-permissioned and/or public blockchains in future work. 

*A note about terminology: You'll see a few terms being thrown around such as Consortium Blockchain 
and Distributed Ledger Technology. For the purposes of this project, these are almost interchangeable, 
however in different spheres they will have different and distinct definitions, so please be aware 
of that and always do your due diligence. (For another example, you'll see later when we talk about 
chaincode vs smart contracts; interchangeable in the context of this (and a few other projects), but 
do technically mean two different things.)*

The choice to start with using Fabric for this idea was the ability full control of the blockchain in 
question while the structure was being planned out and developing of the scripts and chaincode. A public 
blockchain solution such as Ethereum sounded like a hassle out-of-the-gate. That being said, and as 
mentioned above, it is a hope that once the plans are solidified translating to a public blockchain sphere 
won't be too difficult. For the security network applications, I believe this could have great value in the 
realms of Public Key Infrastructure (PKI), Two-Factor Authentication (2FA), Distributed Denial off Service (DDoS) 
prevention, Domain Name System Security (DNSSec), and beyond! The Proof-of-Concept of this research project 
will be a single blockchain, or Channel in Hyperledger parlance, to be used as a distributed log aggregator.

### Design Decisions
	
* Currently, there will be three Organizations involved. Two Peers and and an Orderer. The Peer Organizations 
will be the participants that will use the security system. In the context of a Log Aggregator network, they 
will be the ones logging to the blockchain and retrieving data back from it. The Orderer Organization acts as 
the Consensus nodes. It will do the assembling of transactions into blocks, validates those transactions/blocks, 
and finally disseminates the blocks to the peers. Since this is a distributed network, the Orderer is usually a 
third-party outside of those that are peers to a particular Channel. 
* There will be a dedicated TLS CA for each Organization (the Orderer and both Peers).
* There will not be any Intermediate CAs. (Although, definitely worth looking into for scalability.)
* Many static credentials were used when registering and enrolling. This may, and honestly should, be changed to 
dynamic via arguments to the script if time permits.

#### The CA Servers
Here is one of the parts that can get confusing: there are technically TWO different CA Servers per Organization. One 
is the TLS CA Server which secures the communications of the different nodes within a single intranet or, in other words, 
the internal network of a single organization. These are relatively straight-forward in their purpose.

The other server is that of the Fabric CA Server which handles all of the identities for an Organization *in reference to* 
the Fabric internet, that is, the combined network of all participating Organizations. (The "cloud" in the figure below.)

What makes this a bit confusing is that it is the same binary (fabric-ca-server) for both and only what you set in the individual 
configuration files is what that server ends of becoming. So, there's a lot of overlap between the two in the following information. 
However, I will mostly be talking about the Fabric CA Server from here on as that is the more important component of the network 
as a whole. (If I need to make it explicit that I am talking about the TLS server, I will do so at the time of writing.)

From an outsider's perspective (i.e. without looking in the individual config files), however, you can tell the difference between the
two servers by which directory they're located. `<some-org>`/fab-ca-server/ for the Fab CA Server, and `<some-org>`/tls-ca-server/ for
the TLS CA Server. 

For illustrative purposes, the Fab CA Server I am talking about here is the Org CA Server (again, their nomenclature, Fab CA Server in 
mine) in the following diagram:

![CA Server Diagram](/images/fabric-network-diagram.png)

### Notes about fabric-ca-server-config.yaml
Removed this section for now as all of this information, and more, is in the comments of the different scripts. The comments of those 
scripts are meant to not only tell a reader *what* a certain command does but also *how* it fits in to the system as a whole. This includes
editing the default YAML configuration files.

	
MORE TO COME
