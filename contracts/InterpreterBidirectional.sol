pragma solidity ^0.4.18;

import "./InterpreterInterface.sol";

contract InterpretBidirectional is InterpreterInterface {
    // State
    // [0-31] isClose flag
    // [32-63] sequence number
    // [64-95] balance of party A
    // [96-127] balance of party B

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

    function decodeState(bytes state) pure internal {
        assembly {

        }
    }

}