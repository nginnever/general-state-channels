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
    function isClose() public returns(bool) {
        return true;
    }

    function isSequenceHigher(bytes _data, uint _seq) public pure returns (bool) {
        uint isHigher;

        assembly {
            isHigher := mload(add(_data, 160))
        }

        // allow the sequence number to be equal to that of the settled state stored.
        // this will allow a counterparty signature

        require(isHigher >= _seq);
        return true;
    }

    function isAddressInState() public returns (bool) {
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

}