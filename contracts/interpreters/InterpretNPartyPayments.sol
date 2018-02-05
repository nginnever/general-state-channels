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
    bool allJoin = false;

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
        
        _decodeState(_data);
        //require(_queryAddress == _a || _queryAddress == _b);
        return true;
    }

    function hasAllSigs(address[] _recovered, bytes _data) public returns (bool) {
        // uint256 _b1;
        // uint256 _b2;
        // address _a;
        // address _b;

        // (_b1, _b2, _a, _b) = decodeState(_data);

        // a = _a;
        // b = _b;

        // //hack indexes for bug here with the 0 element of the array being populated with 000.. (maybe size of arr)
        // for(uint i=1; i<3; i++) {
        //     if(_recovered[i] == _a) {
        //         require(_recovered[i+1] == _b);
        //     } else {
        //         require(_recovered[i-1] == _a);
        //     }
        //     //require(_recovered[i] == _a || _recovered[i] == _b);
        //     a = _recovered[i];
        // }

        return true;
    }

    function allJoined() public returns (bool) {
        return allJoin;
    }

    function challenge(address _violator, bytes _state) public {
        // we do not close with a challenge for bi-directional. We assume
        // that the client will close with a settlement period on last good state
        // instead
        require(1==2);
    }

    function quickClose(bytes _state) public returns (bool) {

        // uint256 _b1;
        // uint256 _b2;
        // address _a;
        // address _b;

        // (_b1, _b2, _a, _b) = decodeState(_state);

        // b1 = _b1;
        // b2 = _b2;

        // require(_b1 + _b2 == this.balance);
        // _b.send(_b2);
        // _a.send(_b1);
        return true;
    }


    function run(bytes _data) public {
        uint sequence;
        uint _bond;

        assembly {
            sequence := mload(add(_data, 64))
        }

        _decodeState(_data);

    }

    function _decodeState(bytes state) pure internal {
        uint numParty;
        assembly {
            numParty := mload(add(state, 96))
        }

        for(uint i=0; i<numParty; i++){
            uint pos = 0;
            uint posA = 0;
            uint temp;
            address tempA;

            pos = 128+(32*i);
            posA = 128+(32*numParty)+(32*i);

            assembly {
                temp := mload(add(state, pos))
                tempA :=mload(add(state, posA))
            }
        }
    }

}