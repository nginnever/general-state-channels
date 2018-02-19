# general-state-channels 

This POC is a combination of insights derived from Eth, L4, and Spankchain research. This system is a set of Ethereum contracts that attempts to abstract away the logic of authority contracts for many use cases by managing bonds and agreed upon state between participants. It allows state channels to be open with up to N participants where N is bounded by the gas costs to reconstruct signatures (~50 participants).

Table of Contents:

- Definitions
- Background Information
- System Overview
- Channel API
- Interpreter Guide
- TODO
- Contributing

Definitions:

Channel Manager: The contract responsible for opening and closing channels. It instantiates the interpreter contracts. (Ideally only when a challenge is presented)

Interpreters: These are the contracts that hold the logic responsible for assembling state bytes into meaningful representations. ie constructing the balances in a payment channel or determining the winner of a game. They provide judgement on valid state transitions and hold the bonds of the channel to be acted upon by interpreted state. The bonds will be held by the channel manager in the future as interpreters will be counterfactually instantiated.

The current version of this implementation requires that the agreed upon interpreter contracts be deployed when the channel is opened. As L4 research suggests this may be replaced by putting the byte code of the interpreter contracts in the agreed upon state. This work is left TODO.

Background Information:

TODO Outline Layer 2 solutions, L4 research, Spankchain research

