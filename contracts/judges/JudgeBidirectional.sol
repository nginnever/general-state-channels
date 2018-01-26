pragma solidity ^0.4.18;

import "./JudgeInterface.sol";

contract JudgeBidirectional is JudgeInterface {
    // State
    // [0-31] isClose flag
    // [32-63] sequence number
    // [64-95] balance of party A
    // [96-127] balance of party B
    // [] bond

    function run(bytes _data) public {
      // get the signed new state and transition action

      // apply the action to the supplied challenger state

      // check that the outcome of state transition on challenger state
      // with accused state update is equal to the signed state by the violator

      // [0:8] sequence number (in this case building the word could check for longest valid state for seq check)
      uint sequence;

      assembly {
          sequence := mload(add(_data, 64))
      }

      uint256 _b1;
      uint256 _b2;
      uint256 _bond;

      (_b1, _b2, _bond) = decodeState(_data);

      //require(_bond == this.balance);
      require(_b1 + _b2 <= _bond);
    }

    function decodeState(bytes state) pure internal returns (uint256 _b1, uint256 _b2, uint256 _bond) {
        assembly {
            _b1 := mload(add(state, 96))
            _b2 := mload(add(state, 128))
            _bond := mload(add(state, 160))
        }
    }

}