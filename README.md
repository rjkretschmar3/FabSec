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
* There are two options for, what's called, the State Database: CouchDB and LevelDB. The State Database is the database 
maintained by each Peer which tracks the current values for all of the assets listed on the ledger. LevelDB is the
default, and embedded, choice for this decision which will be used by this project.
* The ports to the different services are going to be hardcoded since, honestly, I got tired of re-typing
them in each time. However, a future (post-project) idea would be nice to have them dynamically chosen. They
are as follows:
	- Org0, TLS CA -- main: 7054, operations:
	- Org0, Fab CA -- main: 7055, operations:
	- Org0, orderer0 -- ListenPort: 7050, Operations: 8443
	- Org1, TLS CA -- main: 7056, operations:
	- Org1, Fab CA -- main: 7057, operations:
	- Org1, peer0 -- listenAddress: 7051, chaincodeListenAddress: 7052
	- Org2, TLS CA -- main: 7058, operations:
	- Org2, Fab CA -- main: 7059, operations:

### The CA Servers
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
two servers by which directory they're located: `org<org-id>/fab-ca-server/` for the Fab CA Server, and `org<org-id>/tls-ca-server/` for
the TLS CA Server. 

For illustrative purposes, the Fab CA Server I am talking about here is the Org CA Server (again, their nomenclature, Fab CA Server in 
mine) in the following diagram:

![CA Server Diagram](/images/fabric-network-diagram.png)

To see how this diagram looks in directory tree form, please see `fabsec-org-tree.txt`.

#### Notes about fabric-ca-server-config.yaml
Suffice it to say, this it the main configuration file for the CA Servers. Each server (TLS and Fab) have their own individual versions
of this file. In fact, depending on the *signing profile* this YAML file contains determines how the server binary (remember it's the same
binary for both) acts. I've removed ta lot of his section for now as all of this information, and more, is in the comments of the different 
scripts. The comments of those scripts are meant to not only tell a reader *what* a certain command does but also *how* it fits in to the 
system as a whole. This includes information on the editing these default YAML configuration files.

### Peers
A Peer Node is the node that contains, or hosts, the ledgers and the chaincode. In this project, an individual peer node (the binary and 
relevant files such as the configuration core.yaml) will live in `org<org-id>.fabsec.com/peers/peer<peer-id>.org<org-id>.fabsec.com`. This
topic is explained in more detail below.  

#### Notes about core.yaml
The core.yaml configuration file is the main configuration file for a peer node. As with the configuration files for the CA servers,
if I don't need to explicitly need to change a value from a default, I won't. Unlike the config files for the CA servers, it is not
auto-generated each time you bring up a peer, but rather downloaded from the official GitHub repo. That is to say, you need to hand
edit these files each time you want to persist a new value. I'll also talk about some values that won't explicitly be changed from
their default, but are important to keep in mind or need further explanation. 

Guidance provided by [Checklist for a Production Peer](https://hyperledger-fabric.readthedocs.io/en/release-2.1/deploypeer/peerchecklist.html)

<details>
	<summary>The following configuration changes from the defaults will take place:</summary>

- peer.id
	- This is the ID by which the peer will be referenced. This will follow the naming convention 
used for the individual peers (as mentioned above). For example, peer 0 of organization 1 would be 
`peer0.org1.fabsec.com`.

- peer.networkId
	- This is the ID by which the network will be referenced. It allows logical separation of networks 
and generally it would be named after it's planned usage. For the purposes of this project, this will 
be `grad-project`.

- peer.listenAddress
	- This is the address the peer will listen on. By default, this and the other "address" configuration
values below will listen to all IP addresses as identified by 0.0.0.0 which is INADDR\_ANY in TCP 
parlance. I'll be leaving the address portion of these alone, however in some production scenarios, one
would probably want to tighten that up. The port starting, again by default, at 7051 will need to be
changed for each subsequent peer to come up.

- peer.chaincodeListenAddress
	- This is the address the peer will listen on for inbound chaincode connections. The default of
0.0.0.0 is fine for the address, however the default port of 7052 will have to be changed for each
subsequent peer to come up after the first. NOTE: This and the next config option will have to be
uncommented to take effect.

- peer.chaincodeAddress
	- This is the address that the chaincode itself will use to connect to the peer. It will get 
the peer ID as an address and the `peer.chaincodeListenAddress` port as its port.

- peer.address
	- This is the address other peers can use to connect to this peer. It will get the peer ID as
an address and the `peer.listenAddress` port as its port.

- peer.addressAutoDetect
	- I'm not changing this from its default, which is false, for now. But to remind myself of its
existence when/if I containerize later with Docker.

- peer.mspConfigPath
	- This is the path where the peer will find it's local MSP configuration. As of now, I'm leaving it as the
default of `msp` since each individual peer will have its own local `peer` binary with its own local MSP.

- peer.localMspId
	- This is the value of the MSP ID of the organization the peer belongs to. This is a security measure to
check if a peer's organization is a channel member. If not, then the peer won't be allow to join the channel
for obvious reasons. (This is MSP ID is defined in configtx.yaml.)

- peer.fileSystemPath
	- This variable points the peer to where the ledger and installed chaincode lives. The default is 
`/var/hyperledger/production`, but since I set up this project to be contained within a special file structure, 
I will be changing it to `./datastore`. The single dot means the directory `datastore` will be in the peer's
own directory. Further, this means each peer will have its own individual datastore (to simulate a real network
where each peer would be running on its own machine).

- peer.gossip.\*
	- Endpoints: These are the parameters controlling the endpoints of the Gossip protocol. This project,
at least starting out, will not be using Gossip. It is unclear whether or not this still need to be filled out,
so I will fill them out as well as talk about them here.
		- bootstrap: This is the list of other peers addresses in the peer's organization to discover.
		- endpoint: This is the address that *other peers in this peer's organization* will use to to
connect to this peer.
		- externalEndpoint: This is the address that *other peers outside of this peer's organization*
will use to connect to this peer. For both this and `endpoint` above, I will just fill it out with the peer's
`peer.address` value. So, for example, peer 0 running in organization 1 will get the value of `peer0.prg1.facsec.com:7051`.

	- Block Dissemination: There are two ways for peers to get blocks: via the orderers
or via other peers. For this project, the peers will be using the former method (that is, 
getting their blocks from the orderers). As of v2.2, it is recommended to not use Gossip and have 
peers get their blocks from the orderers to reduce network congestion. So, I'll leave these parameters 
as the defaults. However, for completeness, they are...
		- useLeaderElection: Default set to false. This would be set to true if I wanted
peers to get blocks from other peers, i.e. use the Gossip Protocol. However, since I'm not doing that this
this will remain false. This also means that *at least one* peer must be set to an orgLeader.
		- orgLeader: This defaults to true. This will remain true for all peers essentially
meaning that all peers will be leaders and no peers will be no leaders. 
		- state.enabled: This defaults to false meaning that the Gossip protocol won't be activated.

	- Implicit Data: This is an interesting concept that won't be used in this project, but mentioning it
to remind myself it exists. However, since I won't be using it, that's as far as I'll go into here.

- peer.tls.\*
	- enabled: This is by default false, however we will certainly be using TLS communications, so all peers
will have this value flipped to true.
	- cert.file: This file is the certificate (cert.pem) file that is generated when one enrolls the peer with 
the TLS Server. It is the peer's TLS identity and lives in `tls-msp/signcerts/cert.pem`.
	- key.file: This file is the private key (key.pem) file generated when one enrolls the peer with the
TLS Server. This lives in `tls-msp/keystore/key.pem`.
	- rootcert.file: This file is the TLS root certificate It lives at `tls-msp/cacerts/<host>-<port>.pem`.
</details>

### Orderers
An Orderer Node is the node that collects the different transactions and *orderers* them into the blocks that will 
eventually go on the ledger (blockchain). In a public blockchain, like that of Bitcoin or Ethereum, every node has the
chance to be an "orderer" (although the call them miners).

#### Notes about orderer.yaml
The orderer.yaml configuration file is the main configuration file for an orderer node. As you might
notice, many of these values will be similar with those of the `core.yaml` configuation file for the
peers under different names.

<details>
	<summary>The following configuration changes from the defaults will take place:</summary>

- General.LocalMSPID
	- This is the ID by which the orderer will be referenced. One of the main places this name
is reference is in the `configtx.yaml` file which generates the Genesis Block that is used for
Channel configuration. If this name is different between the two files, the Channel will not accept
this Orderer as valid.

- General.LocalMSPDir
	- This is the relative path to the Local MSP of the Orderer Node. Since this config file, the orderer
binary, and the MSP are all in the same directory, this will simply reflect to check the local directory.

- General.TLS.\*
	- These need the same values (key, cert, and TLS root cert) that the peers have (just for the Orderer
Org), so refer to there for more information.

- General.ListenAddress and General.ListenPort
	- These values govern the endpoint to other ordering nodes in the same organization. They won't be 
changed from their defaults, at least in the case of the project network which only has one ordering node.

- General.BootstrapFile
	- The is the name/location of the block used to bootstrap the ordering node. In the case of a newly 
formed Ordering Service, that is going to be the Genesis Block which will live at 
`./system-genesis-block/genesis.block` of the orderer's PWD.

- FileLedger.Location
	- So, while the Orderers don't have a, what's called, State Database (essentially an indexed view into
the transaction log), they still need to keep a copy of the blockchain for the system configuation blocks.
(Such as that of the Genesis Block.) This is where that will be stored.



</details>

#### Notes about the Genesis Block and the `configtxgen` tool in relation to Orderers
Unlike peer nodes which need nothing more than an identity and a properly filled out `core.yaml` configuration file to be 
spun up, an orderer node which will be the beginning of a new network, that is it won't be joining an existing orderer 
cluster, needs something called a *Genesis Block*. These Genesis Blocks contain special information about the Channel
in which the orderer node will be operating on. (More about Channels below.)

### Channels
Channels are the main way the nodes associate themselves with not only each other, but with the ledgers and chaincode as well.

#### Notes on the Genesis Block and the `configtxgen` tool in relation to Channels.
So, as mentioned above but intentionally glossed over, every Channel needs a Genesis Block.

### Chaincode
Chaincode, as mentioned before, is the Hyperledger equivalent to Smart Contracts. These are Turing-complete programs that hold the business
logic for a given use case. In that spirit, they are used to encapsulate the *shared processes* of the Fabric network.

### Ledgers
Ledgers are the immutable records of all the transactions generated by the Chaincode. They encapsulate all the *shared information* in a
Fabric network.
	
~~ MORE TO COME ~~
