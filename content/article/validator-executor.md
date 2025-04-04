# Validator-Executor Architecture and the Role of Besu as an Execution Client

The recent evolution of Ethereum’s infrastructure has introduced a clear separation between the consensus layer (validators) and the execution layer (execution clients). This architecture, often called the “validator-executor” model, allows for better specialization and scalability. In this article, we explore what this separation means, how validators and executors work together, and how Besu fits into this picture as a robust execution client.

## Understanding the Separation

### Validators and Their Role
Validators are responsible for the consensus process: proposing, validating, and finalizing blocks. In Ethereum’s Proof-of-Stake (PoS) system, a validator must stake 32 ETH to participate in block proposal and attestation. However, validators do not directly process or execute transactions. Instead, they rely on execution clients to provide them with the blockchain’s current state and a pool of pending transactions (the mempool).

### Execution Clients and the Mempool
Execution clients, like Besu, run the Ethereum Virtual Machine (EVM) and manage the state of the blockchain. They maintain a local mempool—a temporary storage area for pending transactions waiting to be included in a block. Each node’s mempool may vary slightly due to propagation delays or filtering, but once a validator proposes a block based on the mempool data from its connected execution client, the block becomes part of the canonical chain if it meets consensus rules.

An important point is that validators typically work with one primary execution client at block creation. This means the block proposal is built from that client's local view. If a particular transaction is absent in that mempool, the validator cannot force its inclusion, even though other nodes might have it pending. Such differences are reconciled by the consensus rules and eventual block propagation.

## How Besu Fits as an Execution Client

### Besu’s Capabilities
Hyperledger Besu is a full-featured Ethereum execution client that can run on both public networks (such as Ethereum Mainnet and various testnets) and private, permissioned networks. As an execution client, Besu:

- **Processes Transactions:** It validates and executes transactions using the EVM.
- **Maintains the State:** Besu holds a complete copy of the blockchain’s state, ensuring that every transaction's effects are recorded and verifiable.
- **Manages the Mempool:** Like other execution clients, Besu maintains a local mempool that stores pending transactions. This is crucial for validators, as the mempool is the source from which block proposals are built.

### Validator-Executor Interaction
When a validator prepares to propose a block, it queries its connected execution client—Besu, in this case—to obtain the latest state and a set of pending transactions from the mempool. The execution client then assembles the block according to consensus rules. Despite potential variations between mempools on different nodes, the validator’s reliance on a single execution client ensures that its block is internally consistent.

If a validator wants a specific transaction to be included, that transaction must already exist in Besu’s mempool. Otherwise, even if other nodes have that transaction, the validator cannot force its inclusion in the block it builds. This process highlights the importance of a well-maintained, synchronized mempool across the network.

## Conclusion

The validator-executor separation improves the efficiency and modularity of Ethereum’s infrastructure. Validators focus solely on consensus, while execution clients like Besu handle the heavy lifting of transaction execution and state management. For anyone running an Ethereum node or operating in a staking setup, understanding this interaction is key. Besu stands out as a versatile and reliable execution client, offering robust features for both public and private network deployments while seamlessly integrating into the validator-executor model.
