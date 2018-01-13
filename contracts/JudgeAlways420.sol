pragma solidity ^0.4.18;

import "./JudgeInterface.sol";

contract JudgeAlways420 is JudgeInterface {

    uint256 public data;

    function testVar(uint256 _data) public returns (bool){
      data = _data;
      return _data == 420;
    }

}