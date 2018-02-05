pragma solidity ^0.4.18;

import "./InterpreterInterface.sol";

contract InterpretBidirectional is InterpreterInterface {
    // State
    // [0-31] isClose flag
    // [32-63] sequence number
    // [64-95] addressA
    // [96-127] addressB 
    // [128-159] balance of party A
    // [160-191] balance of party B

    uint256 public b1;
    uint256 public b2;
    uint256 public bond;
    address public a;
    address public b;
    bool public allJoin = false;

    function interpret(bytes _data) public returns (bool) {

      return true;
    }

    function initState(bytes _data) public returns (bool) {
        uint256 _b1;
        uint256 _b2;
        address _a;
        address _b;

        (_b1, _b2, _a, _b) = decodeState(_data);
        a = _a;
        b = _b;
        b1 = _b1;
        b2 = _b2;
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

    function isAddressInState(address _queryAddress) public returns (bool) {
        require(_queryAddress == a || _queryAddress == b);
        if(a != 0x0 && b != 0x0) {
            allJoin = true;
        }
        return true;
    }

    function hasAllSigs(address[] _recovered, bytes _data) public returns (bool) {
        //uint256 _b1;
        //uint256 _b2;
        //address _a;
        //address _b;

        //(_b1, _b2, _a, _b) = decodeState(_data);

        //a = _a;
        //b = _b;

        for(uint i=0; i<_recovered.length; i++) {
            if(_recovered[i] == a) {
                require(_recovered[i+1] == b);
            } else {
                require(_recovered[i-1] == a);
            }
            //require(_recovered[i] == _a || _recovered[i] == _b);
        }

        return true;
    }

    function challenge(address _violator, bytes _state) public {
        // we do not close with a challenge for bi-directional. We assume
        // that the client will close with a settlement period on last good state
        // instead
        require(1==2);
    }

    function quickClose(bytes _state) public returns (bool) {

        uint256 _b1;
        uint256 _b2;
        address _a;
        address _b;

        (_b1, _b2, _a, _b) = decodeState(_state);

        b1 = _b1;
        b2 = _b2;

        require(_b1 + _b2 == this.balance);
        _b.send(_b2);
        _a.send(_b1);
        return true;
    }


    function run(bytes _data) public {
        uint sequence;
        uint _bond;

        assembly {
            sequence := mload(add(_data, 64))
        }

        uint256 _b1;
        uint256 _b2;
        address _a;
        address _b;

        (_b1, _b2, _a, _b) = decodeState(_data);

        b1 = _b1;
        b2 = _b2;
        bond = _b1 + _b2;
        _bond = _b1 + _b2;

        require(_bond == this.balance);
    }

    function allJoined() public returns (bool) {
        return allJoin;
    }

    function decodeState(bytes state) pure internal returns (uint256 _b1, uint256 _b2, address _a, address _b) {
        assembly {
            _a := mload(add(state, 96))
            _b := mload(add(state, 128))
            _b1 := mload(add(state, 160))
            _b2 := mload(add(state, 192))
        }
    }

}