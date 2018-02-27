# general-state-channels

# WIP!

This POC is a combination of insights derived from Eth, L4, and Spankchain research. This system is a set of Ethereum contracts that attempts to abstract away the logic of authority contracts for many use cases by managing bonds and agreed upon state between participants. 

## Table of Contents:

- Supported Systems
  - Single Direction Paywall Channel
  - Bi-directional Payment Channel
  - Crypto Kitties Battle Channel
- Background Information
- Channel API
  - openChannel
  - joinChannel
  - checkpointState
  - closeChannel
  - startSettleState
  - challengeSettleState
  - closeWithChallenge
  - getChannel
- Interpreter Interface
- Roadmap
- Contributing

## Background Information:

TODO Outline Layer 2 solutions, L4 research, Spankchain research

### Definitions:

Channel Manager: The contract responsible for opening and closing channels. It instantiates the interpreter contracts. (Ideally only when a challenge is presented)

Interpreters: These are the contracts that hold the logic responsible for assembling state bytes into meaningful representations. ie constructing the balances in a payment channel or determining the winner of a game. They provide judgement on valid state transitions and hold the bonds of the channel to be acted upon by interpreted state. The bonds will be held by the channel manager in the future as interpreters will be counterfactually instantiated.

### Overview:

This POC is comprised of a channel manager contract that contains a mapping of channel structs. Channel structs hold a reference to the interpreter contract that is needed to handle final state. This will be replaced in the future so that multiple state games may be played on the same channel bond. Closing the channel will only require reconstructing some final agreed upon state on the bond and not the intermediary final states of any other game that was not challenged and closed without channel consensus. This is like nesting many channels into one bonded channel.

The interpreters for each single channel are constructed and placed in a library where reviewed interpreters for each type of state may be reused by different channels. In the future this library should build a reference for accepted byte code for interpreters that may be counterfacutally deployed when necessary. Alternatively interpreters may be deployed once and reused or called upon with variable state input if they do not store any state.

To open a channel the client must assemble the initial state with the participants they plan to interact with. They sign this state and pass it to the `openChannel()` function. This function will create a channel object and initialize the interpreter with the initial channel state. To join the channel, the participants in the initial state must sign the state and provide this signature to the `joinChannel()` function in the manager. Once all parties in the state have joined the channel it is flagged open and any settlements or closing may begin.

Closing a channel may happen in two ways, fast with consensus or slow with byzantine faults with and a settlement period. To fast close, the state must be signed with an initial sentinel value in its sequence of bytes that represents the participants will to close to the channel. If all parties have signed a state transition with this flag then the state may be acted upon immediately by the manager and interpreter contract to settle any balances, wagers, or state outcome. If this flag is not present and the participants can't agree on the final state, the settlement game starts and accepts the highest sequence signed state.


## Channel API:

The channel manager currently exposes the following to clients for opening, joining, and closing channels.

### openChannel

```channelManager.openChannel(bond, settlementPeriod, interpreter, initialState, signature, {from: participantAddress, value: bond})```

Called by the initiator of a channel.

Parameters:

- uint256 bond: The amount required to join the channel (TODO how to make this variable for N party that may start with 0 bal)
- uint256 settlementPeriod: The time required to allow parties to challenge closing state. Also how often participants must check the ethereum chain
- address interpreter: The address of the logic for interpreting the channels state
- bytes initialState: bytes array of the initial state as defined by each intepreter application
signature inputes
- uint8 v
- bytes32 r
- bytes32 s

Example

TODO: Think about this function more. Can a channel be considered open by simply accepting the bonds from all participants in the state? Can this be done in the manager without interpreting the initial state or storing the participants in the channel struct?

### joinChannel

```channelManager.joinChannel(channelID, initState, signature, {from: participantAddress, value: bond})```

Called by parties in the initial state to join the channel

Parameters:

- bytes32 channelID: The channel id that references the channel in the manager contract
- bytes state: the initial state 
signature inputs
- uint8 v
- bytes32 r
- bytes32 s

### checkpointState

```channelManager.checkpointState(channelID, state, signatures[])```

Called by anyone that holds all signatures to a state

Parameters:

- bytes32 channelID: The channel id that references the channel in the manager contract
- bytes state: the checkpoint state 
signature inputs array
- uint8[] v
- bytes32[] r
- bytes32[] s

### closeChannel

```channelManager.closeChannel(channelID, state, signatures[])```

quick close called by anyone with state that has a flag to close and all participant signatures

Parameters:
- bytes32 channelID: The channel id that references the channel in the manager contract
- bytes state: the checkpoint state 
signature inputs array
- uint8[] v
- bytes32[] r
- bytes32[] s

### startSettleState

```channelManager(channelID, state, signatures)```

called by anyone with valid signatures on state that does not have close flag

Parameters:
- bytes32 channelID: The channel id that references the channel in the manager contract
- bytes state: the checkpoint state 
signature inputs array
- uint8[] v
- bytes32[] r
- bytes32[] s

### challengeSettleState

```channelManager.challengeSettleState(channelID, state, signatures)```

called by anyone within the settlement period that has a higher sequence numbered state signed by all parties

Parameters:
- bytes32 channelID: The channel id that references the channel in the manager contract
- bytes state: the checkpoint state 
signature inputs array
- uint8[] v
- bytes32[] r
- bytes32[] s

### closeWithTimeout

```channelManager.closeWithTimeout(channelID)```

called by anyone after the settlement period has ended

Parameters:
- bytes32 channelID: The channel id that references the channel in the manager contract

## Interpreter Interface

All interpreter contracts must implement the following interface. Interpreters are predefined contracts that return boolean results that the channel manager needs to open, settle, and close. TODO create a guideline on how developers may structure custom interpreter contracts for their applications that will work with the channel manager.

### isClose

```function isClose(bytes _data) public returns (bool);```

### isSequenceHiger

```function isSequenceHigher(bytes _data1, bytes _data2) public returns (bool);```

### isAddressInState

```function isAddressInState(address _queryAddress) public returns (bool);```

### hasAllSigs

```function hasAllSigs(address[] recoveredAddresses) public returns (bool);```

### quickClose

```function quickClose(bytes _data) public returns (bool);```

### allJoined

```function allJoined() public returns (bool);```

### inState

```function initState(bytes _date) public returns (bool);```

### run

```function run(bytes _data) public;```

## Future Work / Roadmap

TODO

## Contribution

TODO

