# CPSC 597 Graduate Project
## On the Applications of Consortium Blockchain Technology as a Dedicated Security Network Deployment
### By Robert Kretschmar
### California State University, Fullerton, Department of Computer Science

=================================================

NOTE: Many of the conceptual details about the Hyperledger Fabric system that were in this README 
file were reproduced in my formal report. So, to keep from too much redundancy, and to keep this 
README manageable for casual observers of my project, I'll just have the functional details of my project 
in here.

=================================================

These are the internals (scripts, chaincode, and binaries) of my CPSC 597 Graduate Project. They were
written/modified, administered, and maintained by Robert Kretschmar. The latest official Read the Docs 
for Hyperledger Fabric (release-2.2 at the time of writing) were used for guiding the building of this 
project, so much thanks to those giants on whose shoulders I stand. 
[Hyperledger Fabric's Read the Docs](https://hyperledger-fabric.readthedocs.io/en/release-2.2/)

Blockchain technology has been a disruptive force in this world. Originally, that disruption was felt 
in the financial sector with Bitcoin. This relegation to the financial sector existed because the 
Bitcoin scripting language Script was intentionally non-Turing complete; perfect for its Use Case as a 
cryptocurrency, but otherwise significantly under-powered for general applications. However, it wasn't 
long until the next level came in the form of Ethereum which introduced a Turing-complete scripting 
language along side its cryptocurrency offering. This opened up the world to the possibility of decentralized 
applications (dApps). While those platforms were necessarily public and open, others still thought about other 
Use Cases that would benefit from the use of this type of distributed technology -- ledgers in the form of 
cryptographically connected blocks, decentralized node consensus, scripting to build applications on these 
platforms, etc. -- in a private and permissioned space. One of those offerings was a system, itself defined 
and built by a consortium of organizations (from Intel to IBM), maintained by The Linux Foundation called 
The Hyperledger Project.

FabSec (short for Fabric Security) is an exploration in the potential of using Hyperledger Fabric's 
Distributed Ledger Technology as a dedicated security network. Hyperledger is an ecosystem of different 
tools, libraries and frameworks for creating different types of Blockchains: from private and permissioned 
to public and permissionless. Fabric is one of those Blockchain frameworks. It allows multiple actors to 
share a blockchain between themselves for any Use Case which to they could think to apply it.

This project attempts to explore use of this technology in the security space, namely having a dedicated 
security network between actors. These actors can be two (or more) organizations looking to join forces 
and pool security resources. In fact, how this idea got started was thinking about having a dedicated 
security network as an overlay to something like a Wide-Area Network (WAN) specifically that of a 
Metropolitan-Area Network (MAN). (Or really any network system which is large enough the scaling security 
could present a problem.) You could have multiple organizations within a city each helping to strengthen 
the security mission of their networks without having that security centralized as a city is often its own 
ecosystem of businesses, departments, and other stakeholders. An extended hope is that this could one day 
be applied to non-permissioned and/or public blockchains in future work. 

*A note about terminology: You'll see a few terms being used here such as Consortium Blockchain and 
Distributed Ledger. For the purposes of this project, as well as many others these are interchangeable. This 
interchangeability holds because a Blockchain system at its base is nothing more than a Distributed Ledger of 
transactions. Another example of this seen later is Chaincode vs Smart Contracts.*

The choice to start with using Fabric for this idea was the ability to have full control of the blockchain 
in question while the structure was being planned out and the scripts and chaincode were being developed. A 
public blockchain such as Ethereum sounded like too many unknown variables right out-of-the-gate. That being 
said, and as mentioned above, it is a hope that once the plans are solidified translating this work to a 
public blockchain won't be too difficult. However, something thought about after this choice was made was 
doubling down on the idea of using a permissioned blockchain such as Fabric for a real implementation, such 
as for a MAN. The beauty of the idea is that its easily translatable to many different platforms. For security 
network applications, I believe this could have great value in the realms of Public Key Infrastructure (PKI), 
Two-Factor Authentication (2FA), Distributed Denial of Service (DDoS) prevention, Domain Name System Security 
(DNSSec), and beyond! The Proof-of-Concept of his research project will be a single blockchain network -- or 
Channel in Hyperledger parlance -- to be used as a distributed log aggregator. As anyone in blue team security 
can tell you, the logs are everything!

#### Design Decisions
<details>
	<summary>The following are the different Design Decisions I had to make throughout this project.</summary>	

* Currently, there will be three Organizations involved. Two Peers and and an Orderer. The Peer Organizations 
will be the participants that will use the security system. In the context of a Log Aggregator network, they 
will be the ones logging to the blockchain and retrieving data back from it. The Orderer Organization acts as 
the Consensus nodes. It will do the assembling of transactions into blocks, validates those blocks, and finally 
disseminates the blocks to the peers. Since this is a distributed network, the Orderer is usually a third-party 
outside of those that are peers to a particular Channel. 
* There will be a dedicated TLS CA for each Organization (the Orderer and both Peers).
* There will not be any Intermediate CAs. (Although, definitely worth looking into for scalability.)
* Many static credentials were used when registering and enrolling. This may, and honestly should, be changed to 
dynamic via arguments to the script for a real world scenario.
* There are two options for, what's called, the State Database: CouchDB and LevelDB. The State Database is the database 
maintained by each Peer which tracks the current values for all of the assets listed on the ledger. LevelDB is the
default, and embedded, choice for this decision which will be used by this project.
* The ports to the different services are going to be hard-coded since, honestly, I got tired of re-typing
them in each time. However, a future (post-project) idea would be nice to have them dynamically chosen. They
are as follows:
	- Org0, TLS CA -- main: 7054, operations: 9443
	- Org0, Fab CA -- main: 7055, operations: 9444
	- Org0, orderer0 -- main: 6050, operations: 8443
	- Org1, TLS CA -- main: 7056, operations: 9445
	- Org1, Fab CA -- main: 7057, operations: 9446
	- Org1, peer0 -- main: 6051, chaincode: 6052, operations: 8446
	- Org2, TLS CA -- main: 7058, operations: 9447
	- Org2, Fab CA -- main: 7059, operations: 9448
	- Org2, peer0 -- main: 6053, chaincode: 6054, operations: 8447
	- Org2, peer1 -- main: 6055, chaincode: 6056, operations: 8448

</details>

#### Network Topography
![CA Server Diagram](/images/fabric-network-diagram.png)

Above is the general network diagram of my system. As you can see there are three Organizations that
are all separate from one another. The two Peer Organizations will host the Chaincode and the Ledgers
on their Peer nodes. These Peer Nodes are the "entry points" into the network for Clients (the 
End-Users). The Orderer Organization will host the Orderer Node which is where the *ordering* of the
Blocks that go into the Blockchain will take place. All Organization will have their own dedicated TLS
CA Server for secure communications, and their own Fabric CA Server for the necessary Identities on the
network (to maintain the *permissioned* nature of it). For more information on these conceptual ideas such
as Orderers, Peers, Identities, Ledgers, etc., I invite you to read the `fabsec-report-kretschmar.pdf`
document. To see how this diagram looks in directory tree form, as well as other structural information of
each of the Organizations, please see `fabsec-org-tree.txt`.


#### Scripts
The best place to start looking at my project is through the scripts. These scripts are how the network gets
bootstrapped and realized. Notice that there is no `organizations` directory in the listing above although it
is mentioned in the `fabsec-org-tree.txt` file. This is because that directory as well as all of its children
will be instantiated through the first script. As you move through the scripts, more and more of the network will
come together until, finally, you have a full realized network ready for use. The reason for this is I found
changes were more easily made through the scripts, and subsequently creating and destroy the network, than through
made a more "concrete" model.

There are two types of scripts: those that are identified by a number, and those identified by a letter. The ones
identified by a number are the base scripts. They are the ones that deliver the actual commands to the systems, and
take in commandline arguments to make them more applicable. The scripts identified by a letter are what I'm
calling "meta-scripts" which use the base scripts to set up the system to the specification of the project. In
interest of flow, I'll just talk about the meta-scripts here, but you can find out more about all the scripts in
the paper and in the comments of the scripts themselves.

<details>
	<summary>The meta-scripts are as follows:</summary>

* 000a-create-org-directory-tree-with-symlinks.sh
	
	This script is what creates the all of the Organizations as they will be used in the network. It creates each
organization's directory structure, and pre-fills it with various binaries and configuration files, where needed. It
is also the only meta-script to not use any base scripts.

* 000b-create-orderer-organization.sh
	
	So, in Fabric, the act of "defining an organization" takes place by registering and enrolling an Organizational
Administrator. This is done through the Fabric (Identity) Certificate Authority. (More on Fabric Identity Certificates in
the paper.) To talk to the Fabric CA Server, we need to first set up the TLS CA Server. So, that's the flow of this script:
Set up -- and bootstrap the admin of -- the TLS CA Server, set up -- and bootstrap the admin of -- the Fabric CA Server,
and then register and enroll the Organizational Admin themselves.

* 000c-create-peer-organization-1.sh
	
	This follows the same steps as script 000b, but for Peer Org 1.

* 000d-create-peer-organization-2.sh
	
	This follows the same steps as script 000b, but for Peer Org 2.

* 000e-create-system-channel-and-deploy-orderer-0.sh
	
	This script will set up the network and deploy orderer on that network. To start, since Hyperledger Fabric is a
permissioned blockchain, every node on the network needs to have an identity issued by the Fabric CA belonging to their
organization. This script starts by doing just that for the orderer node known as orderer0. It then creates the Genesis
Block for the System Channel. A Channel, in Fabric terms, is essentially an individual network within the over-arching
network. Since Fabric has the ability to be *multi-tenant*, it allows for many of these Channels (or networks) to be set 
up. There are two types of Channels: the System Channel, and the Application Channel. I'll go more into the Application
Channel in the next script description. 

	This Channel is the System Channel, otherwise called the "Ordering System Channel". It is used to create the way 
to facilitate communication of the Ordering Service (which is just a fancy term for the group of Orderers on the 
network). In the case of this project, it will only have one Orderer, or an "Ordering Service of one" so to speak.  The 
System Channel configuration is stored in a Block on the Blockchain for that Channel. (It is usually one Blockchain per
Channel for this reason.) In fact, the initial Channel Configuration is always the first (0th) block on the chain, and 
this is what we refer to as the Genesis Block. The process of creating one is outside the scope of this README, but it 
involves a channel configuration YAML file and one of the binaries called `configtxgen`. So, this script will use the base 
script that generates that. It then deploys the Orderer orderer0 which is usually the first node to be defined which will
consume that block to bootstrap itself.

* 000f-create-fabsec-channel-and-deploy-peer0-org1.sh
	
	This script will register and enroll the identity for the Peer peer0 in Organization 1. It then creates the "Channel
Creation Transaction" for my main Application Channel "fabsec-channel". The Channel Creation Transaction is need for the Ordering
Service to register and recognize the newly created channel for itself. This is then used for the next base script to generate the
Genesis Block that defines the configuration of the Application Channel fabsec-channel. As an aside, ideally, if we think about 
expanding this whole "security network" idea to more than just the Log Aggregator, say also use it for Access-Control Lists, then 
that would be in its own Channel. Each Channel has its own Peers, Orderers, Chaincodes, and Ledger (among other artifacts). Again,
more on Channels in the paper, but I felt it was important enough to spotlight it here. So, next this script deploys peer0 and then 
joins it to the newly instantiated fabsec-channel.

* 000g-deploy-peer0-org2-and-join-fabsec-channel.sh
	
	This script will register and enroll peer0 of Organization 2, deploy it, and join it to the fabsec-channel. Since the System
Channel was created and instantiated in script 000e and the Application Channel (fabsec-channel) was created and instantiated in the
last script (000f), this script doesn't need to do any of that, and simply just joins the existing channel. This is illustrative of
how easy it is to add nodes once all of heavy lifting has been done.

* 000h-deploy-peer1-org2-and-join-fabsec-channel.sh
	
	This script will register and enroll peer 1 of Organization 2, deploy it, and join it to the fabsec-channel. Again, nothing
fancy has to be done here.

* 000i-designate-anchor-peers-for-fabsec.sh
	
	This meta-script is deceptively simple for its concepts. A lot of the magic is in the base scripts. It involves the concepts
of Channel Configuration Updating (which is *not* a trivial process), the Gossip Protocol, and  to add nodes once all of heavy lifting 
has been done.

* 000h-deploy-peer1-org2-and-join-fabsec-channel.sh
	
	This script will register and enroll peer 1 of Organization 2, deploy it, and join it to the fabsec-channel. Again, nothing
fancy has to be done here.

* 000i-designate-anchor-peers-for-fabsec.sh
	
	This meta-script is deceptively simple for its concepts. A lot of the magic is in the base scripts. It involves the concepts
of Channel Configuration Updating (which is *not* a trivial process using `jq` and the `configtxlator` binary) and the Gossip 
Protocol. Suffice it to say, that this script sets up the Peers used for inter-organizational peer-to-peer communication.

* 000j-deploy-logaggr-chaincode
	
	This last meta-script is relatively short since it's really just here for general meta-script flow and completeness, but it
uses the base script 016 to deploy the chaincode to the channel. The process of "deploying" involves installing the chaincode to each
of the peers, having them approve it for their organization, and committing that chaincode to the channel. After this meta-script is
done, the FabSec network will have been officially set up. The next part of the project comes in the form of javascript modules.

</details>
