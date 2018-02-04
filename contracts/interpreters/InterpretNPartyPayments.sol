pragma solidity ^0.4.18;

import "./InterpreterInterface.sol";

contract InterpretPlasma is InterpreterInterface {
    // State
    // [0-31] isClose flag
    // [32-63] sequence number
    // [] address length
    // [] addressA
    // [] addressB 
    // ...
    // [] balance of party A
    // [] balance of party B
    // ...

    uint256 public b1;
    uint256 public b2;
    uint256[] bals;

    mapping(address => uint256) balances;

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

    function isSequenceHigher(bytes _data1, bytes _data2) public returns (bool) {
        uint isHigher1;
        uint isHigher2;

        assembly {
            isHigher1 := mload(add(_data1, 64))
            isHigher2 := mload(add(_data2, 64))
        }

        // allow the sequence number to be equal to that of the settled state stored.
        // this will allow a counterparty signature

        require(isHigher1 > isHigher2);
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

    function isAddressInState(address _queryAddress, bytes _data) public returns (bool) {
        return true;   
    }

    function challenge(address _violator, bytes _state) public {
        // we do not close with a challenge for bi-directional. We assume
        // that the client will close with a settlement period on last good state
        // instead
        require(1==2);
    }

    function quickClose(bytes _state) public returns (bool) {
        decodeState(_state);

        // b1 = _b1;
        // b2 = _b2;

        // require(_b1 + _b2 == this.balance);
        // _b.send(_b2);
        // _a.send(_b1);
        return true;
    }

    function decodeState(bytes state) internal {
        uint addressLength;
        uint _temp;

        assembly {
            addressLength := mload(add(state, 96))
            // _a := mload(add(state, 96))
            // _b := mload(add(state, 128))
            // _b1 := mload(add(state, 160))
            // _b2 := mload(add(state, 192))
        }

        // Need to build a withdrawal structure that does not loop, this limits
        // the number of balances the plasma chain may hold
        // move towards a merkle proof of inclusion in a signed plasma block
        // judge will excersize rules on a fraud proof, state will be to large
        // to validate on chain
        for (uint i=96+addressLength; i<96+addressLength+addressLength; i+=32) {
            assembly {
                _temp := mload(add(state, i))
            }
            bals.push(_temp);
        }

    }

}