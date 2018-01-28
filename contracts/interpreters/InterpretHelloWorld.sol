pragma solidity ^0.4.18;

import "./InterpreterInterface.sol";

contract InterpretHelloWorld is InterpreterInterface {
    // State
    // [0-31] isClose flag
    // [32-63] sequence number
    // [64-95] bond
    // [96-127] "h"
    // [128,159] "e"
    // [160,191] "l"
    // ...

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

    function isSequenceHigher(bytes _data, uint _seq) public returns (bool) {
        uint isHigher;

        assembly {
            isHigher := mload(add(_data, 64))
        }

        // allow the sequence number to be equal to that of the settled state stored.
        // this will allow a counterparty signature

        require(isHigher >= _seq);
        return true;
    }

    function isSequenceEqual(bytes _data, uint _seq) public returns (bool) {
        uint isEqual;

        assembly {
            isEqual := mload(add(_data, 64))
        }

        // allow the sequence number to be equal to that of the settled state stored.
        // this will allow a counterparty signature

        require(isEqual == _seq);
        return true;
    }

    function challenge(address _violator, bytes _state) public {
        // punish the violator
    }

    function timeout(bytes _state) public {
        // punish the violator
    }

    function quickClose(bytes _state) public returns (bool) {
        return true;
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