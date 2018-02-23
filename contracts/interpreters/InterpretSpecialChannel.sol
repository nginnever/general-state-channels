
pragma solidity ^0.4.18;

import "../ChannelRegistry.sol";
import "./InterpreterInterface.sol";
import "./InterpretBidirectional.sol";
import "./InterpretPaymentChannel.sol";

// this contract will essentially be the current channelManager contract
// requirements:
//   - quick close channel: minimal state update, only update final bond balances 
//   - start settle state: calls bidirectional instantiated contract to check sigs, store state and sequence num, start challenge period
//   - challenge settle state: calls bidirectional to check sigs and higher sequence num
contract SpecialPaymentChannel is InterpreterInterface {
  // state
  uint256 public partyAbal;
  uint256 public partyBbal;

  

}