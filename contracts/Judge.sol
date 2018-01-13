pragma solidity ^0.4.18;

import "./JudgeInterface.sol";

contract Judge is JudgeInterface {

    function testVar(bytes _data) public view returns (bool){
      return true;
    }

}