pragma solidity ^0.4.18;

import "./InterpreterInterface.sol";

contract InterpretHelloWorld is InterpreterInterface {


    function interpret(bytes _data) public returns (bool) {

      return true;
    }

    function isClose(bytes _data) public returns(bool) {
        uint isClose;

        assembly {
            isClose := mload(add(_data, 32))
        }

        require(isClose == 1);
        return true;
    }

    function challenge(address _violator, bytes _state) public {
        // punish the violator
    }

    function decodeState(bytes state) pure internal returns (bytes32 _h, bytes32 _e, bytes32 _l, bytes32 _l2, bytes32 _o) {
        assembly {
            _h := mload(add(state, 64))
            _e := mload(add(state, 96))
            _l := mload(add(state, 128))
            _l2 := mload(add(state, 160))
            _o := mload(add(state, 192))
        }
    }

}