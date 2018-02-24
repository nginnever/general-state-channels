pragma solidity ^0.4.18;

import "./InterpreterInterface.sol";

contract InterpretPaymentChannel is InterpreterInterface {
    // State
    // [0-31] isClose flag
    // [32-63] address sender
    // [64-95] address receiver
    // [96-127] bond 
    // [128-159] balance of receiver

    // function interpret(bytes _data) public returns (bool) {

    //   return true;
    // }

    // This always returns true since the receiver should only
    // sign and close the highest balance they have
    function isClose(bytes _data) public returns(bool) {
        return true;
    }

    function isSequenceHigher(bytes _data1, bytes _data2) public pure returns (bool) {
        uint isHigher1;
        uint isHigher2;

        assembly {
            isHigher1 := mload(add(_data1, 64))
            isHigher2 := mload(add(_data2, 64))
        }

        require(isHigher1 > isHigher2);
        return true;
    }

    function isAddressInState(address _queryAddress) public returns (bool) {
        return true;
    }

    function challenge(address _violator, bytes _state) public {
        // punish the violator
    }

    // just look for receiver sig
    function quickClose(bytes _data) public returns (bool) {
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

        require(_b1<=_bond && _b1>=0);

        require(_bond == this.balance);
        _b.transfer(_b1);
        _a.transfer(_bond-_b1);
        return true;
    }

    // function decodeState(bytes state) pure internal {
    //     assembly {

    //     }
    // }

    function startSettleStateGame(uint _gameIndex, bytes _state, uint8[2] _v, bytes32[2] _r, bytes32[2] _s) public {

    }


    // function hasAllSigs(address[] recoveredAddresses) returns (bool);


    function initState(bytes _state, uint8[2] _v, bytes32[2] _r, bytes32[2] _s) public returns (bool) {

    }

    function run(bytes _data) public {

    }


    // function hasAllSigs(address[] recoveredAddresses) returns (bool);




}