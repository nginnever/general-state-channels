# general-state-channels 

This POC is a combination of insights derived from Eth, L4, and Spankchain research. This system is a set of Ethereum contracts that attempts to abstract away the logic of authority contracts for many use cases by managing bonds and agreed upon state between participants. It allows state channels to be open with up to N participants where N is bounded by the gas costs to reconstruct signatures (~50 participants).

Table of Contents:

- Definitions
- Background Information
- System Overview
- Channel API
- Interpreter API
- TODO
- Contributing

Definitions:

Channel Manager: The contract responsible for opening and closing channels. It instantiates the interpreter contracts. (Ideally only when a challenge is presented)

Interpreters: These are the contracts that hold the logic responsible for assembling state bytes into meaningful representations. ie constructing the balances in a payment channel or determining the winner of a game. They provide judgement on valid state transitions and hold the bonds of the channel to be acted upon by interpreted state. The bonds will be held by the channel manager in the future as interpreters will be counterfactually instantiated.

The current version of this implementation requires that the agreed upon interpreter contracts be deployed when the channel is opened. As L4 research suggests this may be replaced by putting the byte code of the interpreter contracts in the agreed upon state. This work is left TODO.

Background Information:

TODO Outline Layer 2 solutions, L4 research, Spankchain research

System Overview:

This POC is comprised of a channel manager contract that contains a mapping of channel structs. Channel structs hold a reference to the interpreter contract that is needed to handle final state. This will be replace in the future so that multiple state games may be played on the same channel bond. Closing the channel will only requiring reconstructing some final agreed upon state on the bond and not the intermediary final states of any other game that was not challenged and closed without channel consensus. This is like nesting many channels into one bonded channel.

The interpreters for each single channel are constructed and placed in a library where reviewed interpreters for each type of state may be reused by different channels. In the future this library should build a reference for accepted byte code for interpreters that may be counterfacutally deployed when necessary. Alternatively interpreters may be deployed once and reused or called upon with variable state input if they do not store any state.

To open a channel the client must assemble the initial state with the participants they plan to interact with. They sign this state and pass it to the createChannel() function. This function will create a channel object and initialize the interpreter with the initial channel state. To join the channel, the participants in the initial state must sign the state and provide this to the joinChannel() function in the manager. Once all parties in the state have joined the channel is flagged open and any settlements or closing may begin.

Interpreters are predefined contracts that must follow a certain api and return boolean results that the channel manager needs to open, settle, and close. There is a guideline below on how developers may structure custom interpreter contracts for their applications that will work with the channel manager.

Closing a channel may happen in two ways, fast with consensus or with byzantine faults with a delayed settlement period. To fast close, the state must be signed with initial sentinel value in its sequence of bytes that represents the participants will to close to the channel. If all parties have signed a state transition with this flag then the state may be acted upon immediately by the manager and interpreter contract to settle any balances, wagers, or state outcome. If this flag is not present and the participants can't agree on the final state, the settlement game starts and accepts the highest sequence signed state.


Channel API:
