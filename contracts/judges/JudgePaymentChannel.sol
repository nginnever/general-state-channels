pragma solidity ^0.4.18;

import "./JudgeInterface.sol";

contract JudgePaymentChannel is JudgeInterface {
    // State
    // [0-31] isClose flag
    // [32-63] address sender
    // [64-95] address receiver
    // [96-127] bond 
    // [128-159] balance of receiver

    uint public b;
    uint public ba;
    address public a1;

    function run(bytes _data) public {

      uint256 _b1;
      uint256 _bond;
      address _a;
      address _b;

      assembly {
          _a := mload(add(_data, 64))
          _b := mload(add(_data, 96))
          _bond := mload(add(_data, 128))
          _b1 := mload(add(_data, 160))
      }

      b = _bond;
      ba = _b1;
      a1 = _b;
      require(_b1<=_bond && _b1>=0);
    }
}