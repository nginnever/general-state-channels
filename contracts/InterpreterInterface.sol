pragma solidity ^0.4.18;

contract InterpreterInterface {
    bool public interpreter = true;
    /// @dev simply a boolean to indicate this is the contract we expect to be
    function isInterpreter() public view returns (bool){
      return interpreter;
    }

    function interpret(bytes _data) public returns (bool);

    function () payable {
      
    }

}