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

    uint256 public balanceA = 0;
    uint256 public balanceB = 0;
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

    function closeWithTimeoutGame(bytes _state, uint _gameIndex, uint8[2] _v, bytes32[2] _r, bytes32[2] _s) public {

    }
    // function hasAllSigs(address[] recoveredAddresses) returns (bool);


    function initState(bytes _state, uint _gameIndex, uint8[2] _v, bytes32[2] _r, bytes32[2] _s) public returns (bool) {
        _decodeState(_state, _gameIndex);
    }

    function _decodeState(bytes _state, uint _gameIndex) {
        // SPC State
        // [
        //    32 isClose
        //    64 sequence
        //    96 numInstalledChannels
        //    128 address 1
        //    160 address 2
        //    192 balance 1
        //    224 balance 2
        //    256 channel 1 state length
        //    288 channel 1 interpreter type
        //    320 channel 1 CTF address
        //    [
        //        isClose
        //        sequence
        //        settlement period length
        //        channel specific state
        //        ...
        //    ]
        //    channel 2 state length
        //    channel 2 interpreter type
        //    channel 2 CTF address
        //    [
        //        isClose
        //        sequence
        //        settlement period length
        //        channel specific state
        //        ...
        //    ]
        //    ...
        // ]

        uint _numGames;

        uint256 _balanceA;
        uint256 _balanceB;

        // game index 0 means this is an initial state where there have
        // been no games loaded, so this state can't be assembled
        if (_gameIndex != 0) {
            // push pointer past the addresses and balances
            uint pos = 256;
            uint _gameLength;

            assembly {
                _gameLength := mload(add(_state, pos))
            }

            _gameLength = _gameLength*32;

            if(_gameIndex > 1) {
                pos+=_gameLength+32+32+32;
            }

            for(uint i=1; i<_gameIndex; i++) {
                assembly {
                    _gameLength := mload(add(_state, pos))
                }
                pos+=_gameLength+32+32+32;
            }

            if(_gameIndex > 1) {
                pos-= 32+32;
            }

            // assembly {
            //     _gameLength := mload(add(_state, pos))
            // }

            // uint _posState = pos+64+_gameLength;

            assembly {
                //_intType := mload(add(_state, add(pos, 32)))
                //_CTFaddress := mload(add(_state, add(pos, 64)))
                //_sequence := mload(add(_state, add(pos,128)))
                //_settlement := mload(add(_state, add(pos, 160)))
                //_gameState := mload(add(_state, add(pos, _posState)))
                _balanceA := mload(add(_state, add(pos, 256)))
                _balanceB := mload(add(_state, add(pos, 288)))
            }

            //games[_gameIndex].intType = _intType;
            //games[_gameIndex].settlementPeriodLength = _settlement;
            //games[_gameIndex].CTFaddress = _CTFaddress;
            //games[_gameIndex].sequence = _sequence;
            //games[_gameIndex].state = _gameState;
            //ctfaddress = _CTFaddress;
            //gamelength = _gameLength;
            balanceA = _balanceA;
            balanceB = _balanceB;
        }
    }

    function run(bytes _data) public {

    }


    // function hasAllSigs(address[] recoveredAddresses) returns (bool);




}