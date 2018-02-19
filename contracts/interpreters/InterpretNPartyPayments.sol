pragma solidity ^0.4.18;

import "./InterpreterInterface.sol";

contract InterpretNPartyPayments is InterpreterInterface {
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
    uint256 public b3;
    address public a;
    address public b;
    address public c;

    bool allJoin = false;
    uint256 public numJoined = 0;
    uint256 public numParties = 0;

    struct Participant {
        uint256 balance;
        address owner;
        bool inState;
        bool joined;
    }

    mapping(address => Participant) participants;

    // mapping(address => uint256) balances;
    // mapping(address => address) public joinedParties;
    // mapping(address => bool) inState;
    address[] partyArr;


    // function interpret(bytes _data) public returns (bool) {
    //     return true;
    // }

    function initState(bytes _data) public returns (bool) {
        _decodeState(_data);
        return true;
    }

    function isClose(bytes _data) public returns(bool) {
        uint isClosed;

        assembly {
            isClosed := mload(add(_data, 32))
        }

        require(isClosed == 1);
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
        //require(inState[_queryAddress] != false);
        //require(joinedParties[_queryAddress] == 0x0);
        require(participants[_queryAddress].owner != 0x0);
        require(participants[_queryAddress].inState == true);

        if(participants[_queryAddress].joined == false) {
            participants[_queryAddress].joined == true;
            numJoined++;
        }

        //joinedParties[_queryAddress] = _queryAddress;
        //participants[_queryAddress].owner = _queryAddress;
        //partyArr.push(_queryAddress);
        //numJoined++;

        return true;
    }

    function hasAllSigs(address[] _recovered) public returns (bool) {
        require(_recovered.length == numParties);

        for(uint i=0; i<_recovered.length; i++) {
            //require(joinedParties[_recovered[i]] == _recovered[i]);
            require(participants[_recovered[i]].inState == true);
        }

        return true;
    }

    function allJoined() public returns (bool) {
        if(numJoined == numParties){
            allJoin = true;
        }

        return allJoin;
    }

    function challenge(address _violator, bytes _state) public {
        // todo
        // require(1==2);
    }

    function quickClose(bytes _state) public returns (bool) {

        _decodeState(_state);

        for(uint i=0; i<numParties; i++) {
            // total balances and bond check
            partyArr[i].transfer(participants[partyArr[i]].balance);
        }

        // check to be sure reverting here reverts the transfers
        // balance total loop

        return true;
    }


    function run(bytes _data) public {
        uint sequence;

        assembly {
            sequence := mload(add(_data, 64))
        }

        _decodeState(_data);

    }

    function _decodeState(bytes state) internal {
        uint numParty;
        assembly {
            numParty := mload(add(state, 96))
        }

        numParties = numParty;

        for(uint i=0; i<numParty; i++){
            uint pos = 0;
            uint posA = 0;
            address tempA;
            uint temp;

            posA = 128+(32*i);
            pos = 128+(32*numParty)+(32*i);

            assembly {
                tempA:= mload(add(state, posA))
                temp :=mload(add(state, pos))
            }

            if(participants[tempA].owner == 0x0) {
                partyArr.push(tempA);
            }

            participants[tempA].balance = temp;
            participants[tempA].owner = tempA;
            participants[tempA].inState = true;

            //balances[tempA] = temp;
            //inState[tempA] = true;

            // ---- for testing only
            if(i==0) {
                a = tempA;
                b1 = temp;
            }
            if(i==1) {
                b = tempA;
                b2 = temp;
            }
            if(i==2) {
                c = tempA;
                b3 = temp;
            }
            // ----
        }
    }

}