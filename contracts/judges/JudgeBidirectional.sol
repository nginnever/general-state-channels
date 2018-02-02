pragma solidity ^0.4.18;

import "./JudgeInterface.sol";

contract JudgeBidirectional is JudgeInterface {
    // State
    // [0-31] isClose flag
    // [32-63] sequence number
    // [64-95] addressA
    // [96-127] addressB 
    // [128-159] balance of party A
    // [160-191] balance of party B

    uint public b1;
    uint public b2;
    address public a1;

    // sequence and close checks in the judge

    function run(bytes _data) public {
      uint sequence;

      assembly {
          sequence := mload(add(_data, 32))
      }

      uint256 _b1;
      uint256 _b2;

      (_b1, _b2) = decodeState(_data);

      b1 = _b1;
      b2 = _b2;

      //require(_bond == this.balance);
      //require(_b1 + _b2 <= _bond);
    }

    function decodeState(bytes state) pure internal returns (uint256 _b1, uint256 _b2) {
        assembly {
            _b1 := mload(add(state, 160))
            _b2 := mload(add(state, 192))
        }
    }

}