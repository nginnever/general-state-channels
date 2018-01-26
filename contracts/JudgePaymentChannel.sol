pragma solidity ^0.4.18;

import "./JudgeInterface.sol";

contract JudgePaymentChannel is JudgeInterface {
    // State
    // [0-31] isClose flag
    // [32-63] balance of receiver
    // [64-95] bond

    function run(bytes _data) public {
      // get the signed new state and transition action

      // apply the action to the supplied challenger state

      // check that the outcome of state transition on challenger state
      // with accused state update is equal to the signed state by the violator

      uint256 _b1;
      uint256 _bond;

      assembly {
          _b1 := mload(add(_data, 64))
          _bond := mload(add(_data, 96))
      }

      require(_b1<=_bond && _b1>=0);
    }

    // function decodeState(bytes state) pure internal returns (uint256 _b1, uint256 _b2) {
    //     assembly {
    //         _b1 := mload(add(state, 96))
    //         _b2 := mload(add(state, 128))
    //     }
    // }

}