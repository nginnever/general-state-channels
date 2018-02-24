
pragma solidity ^0.4.18;

import "../ChannelRegistry.sol";
import "./InterpreterInterface.sol";
import "./InterpretNPartyPayments.sol";
import "./InterpretBidirectional.sol";
import "./InterpretPaymentChannel.sol";
import "./InterpretBattleChannel.sol";

// this contract will essentially be the current channelManager contract
// requirements:
//   - start settle state: calls intreperter instantiated contract to check sigs, store state and sequence num, start challenge period
//   - challenge settle state: calls interpreter to check sigs and higher sequence num
contract InterpretSpecialChannel is InterpreterInterface {
    // state
    struct Game {
        uint isClose;
        uint isInSettlementState;
        uint numParties;
        uint sequence;
        uint intType;
        address[] participants;
        bytes32 CTFaddress;
        uint settlementPeriodLength;
        uint settlementPeriodEnd;
        bytes state;
    }

    mapping(uint => Game) games;
    mapping(address => uint256) balances;
    uint public numParties = 0;
    uint256 public bonded = 0;
    uint public numGames = 0;
    bytes public state;
    uint isOpen = 1;
    uint isInSettlementState = 0;
    ChannelRegistry public registry;

    function InterpretSpecialChannel(address _registry) {
        require(_registry != 0x0);
        registry = ChannelRegistry(_registry);
    }

    // entry point for settlement of byzantine sub-channel
    function startSettleStateGame(uint _gameIndex, bytes _state, uint8[] _v, bytes32[] _r, bytes32[] _s) public {
        _decodeState(_state, _gameIndex);

        require(games[_gameIndex].isClose == 0);
        require(games[_gameIndex].isInSettlementState == 0);
        require(_v.length == _r.length && _r.length == _s.length);
        // figure out decode ctf address and store
        InterpreterInterface deployedInterpreter = InterpreterInterface(registry.resolveAddress(games[_gameIndex].CTFaddress));

        uint dataLength = _state.length;

        address[] memory tempSigs = new address[](_v.length);

        for(uint i=0; i<_v.length; i++) {
            address participant = _getSig(_state, _v[i], _r[i], _s[i]);
            tempSigs[i] = participant;
        }

        // currently settling sub-channels requires signatures from all parties
        // in the SPC even if they aren't participating in the channel
        require(_hasAllSigs(tempSigs));

        // consult the now deployed special channel logic to see if sequence is higher
        // this also may not be necessary, just check sequence on challenges. what if 
        // the initial state needs to be settled?

        require(deployedInterpreter.isSequenceHigher(_state, state));

        // consider running some logic on the state from the interpreter to validate 
        // the new state obeys transition rules

        // figure out storage
        games[_gameIndex].isInSettlementState = 1;
        games[_gameIndex].settlementPeriodEnd = now + games[_gameIndex].settlementPeriodLength;
    }

    // No need for a consensus close on the SPC since it is only instantiated in 
    // byzantine cases and just requires updating the state
    // client side (update spc bond balances, updates number of channels open, remove
    // closed channel state from total SPC state)

    // could be a case where this gets instantiated because a game went byzantine but you 
    // want to continue fast closing sub-channels against this contract. Though you
    // could just settle the sub-channels off chain until another dispute

    // function closeChannel(bytes _state, uint8[] sigV, bytes32[] sigR, bytes32[] sigS) public {
    //     require(isClose(_state));
    //     require(sigV.length == sigR.length && sigR.length == sigS.length);

    //     uint totalBalance = 0;
    //     totalBalance = _decodeState(_state);
    //     require(totalBalance == bonded);

    //     address[] memory tempSigs = new address[](sigV.length);

    //     for(uint i=0; i<sigV.length; i++) {
    //         address participant = _getSig(_state, sigV[i], sigR[i], sigS[i]);
    //         tempSigs[i] = participant;
    //     }

    //     require(hasAllSigs(tempSigs));
    //     //_payout(tempSigs);
    // }

    function challengeSettleStateGame(uint _gameIndex, bytes _data, uint8[] _v, bytes32[] _r, bytes32[] _s) public {
        // require the channel to be in a settling state
        // figure out how to decode and store this in SPC
        //require(booleans[1] == 1);
        //require(settlementPeriodEnd <= now);
        uint dataLength = _data.length;

        address[] memory tempSigs = new address[](_v.length);

        for(uint i=0; i<_v.length; i++) {
            address participant = _getSig(_data, _v[i], _r[i], _s[i]);
            tempSigs[i] = participant;
        }

        // make sure all parties have signed
        // figure out how to decode and store this in SPC
        //require(_hasAllSigs(tempSigs));

        // consult the now deployed special channel logic to see if sequence is higher
        // figure out how decode the CTFaddress from the state
        //InterpreterInterface deployedInterpreter = InterpreterInterface(registry.resolveAddress(interpreter));
        //require(deployedInterpreter.isSequenceHigher(_data, state));

        // consider running some logic on the state from the interpreter to validate 
        // the new state obeys transition rules. The only invalid transition is trying to 
        // create more tokens than the bond holds, since each contract is currently deployed
        // for each channel, closing on a bad state like that would just fail at the channels
        // expense.

        // figure out how to store this per chan
        //settlementPeriodEnd = now + settlementPeriodLength;
        //state = _data;
    }

    function closeWithTimeoutGame(uint _gameIndex, bytes _state, uint8[] sigV, bytes32[] sigR, bytes32[] sigS) public {
        // figure out how to decode and store this in SPC
        //require(settlementPeriodEnd <= now);
        //require(booleans[1] == 1);
        //require(booleans[0] == 1);
        require(sigV.length == sigR.length && sigR.length == sigS.length);

        // figure out how to decode the SPC balance with this state close
        //uint totalBalance = 0;
        //totalBalance = _decodeState(_state);
        //require(totalBalance == bonded);

        address[] memory tempSigs = new address[](sigV.length);

        for(uint i=0; i<sigV.length; i++) {
            address participant = _getSig(_state, sigV[i], sigR[i], sigS[i]);
            tempSigs[i] = participant;
        }

        // figure out how to decode the party address in the chan in question
        //require(_hasAllSigs(tempSigs));
        // update the spc state for balance
        //_payout(tempSigs);
        //booleans[0] = 0;
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

    function isClose(bytes _data) returns(bool) {
        uint isClosed;

        assembly {
            isClosed := mload(add(_data, 32))
        }

        require(isClosed == 1);
        return true;
    }

    function _hasAllSigs(address[] _recovered) internal view returns (bool) {
        require(_recovered.length == numParties);

        for(uint i=0; i<_recovered.length; i++) {
            // this means that final state balances can't be 0, fix this!
            require(balances[_recovered[i]] != 0);
        }

        return true;
    }

    function _decodeState(bytes _state, uint _gameIndex) internal {
        // SPC State
        // [
        //    32 isClose
        //    64 sequence
        //    96 numParties
        //    128 numInstalledChannels
        //    160 address 1
        //    address 2
        //    ...
        //    balance 1
        //    256 balance 2
        //    ...
        //    channel 1 state length
        //    channel 1 interpreter type
        //    channel 1 CTF address
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
        uint _gameLength;
        uint _numParties;
        uint _sequence;
        uint _isClose;
        uint _settlement;
        uint _intType;
        bytes32 _CTFaddress;
        bytes state;

        uint pos = 128;

        assembly {
            _numParties := mload(add(_state, 96))
            _numGames := mload(add(_state, 128))
            //_gameLength := mload(add(_state, 160))
        }

        numParties = _numParties;

        for(uint i=0; i<_numParties; i++){
            uint _pos = 0;
            uint _posA = 0;
            address tempA;
            uint temp;

            _posA = 160+(32*i);
            _pos = 160+(32*_numParties)+(32*i);

            assembly {
                tempA:= mload(add(_state, _posA))
                temp :=mload(add(_state, _pos))
            }

            //total+=temp;
            balances[tempA] = temp;
        }

        // game index 0 means this is an initial state where there have
        // been no games loaded, so this state can't be assembled
        if (_gameIndex != 0) {
            numGames = _numGames;
            // push pointer past the addresses and balances
            pos+=32*(2*_numParties);

            assembly {
                _gameLength := mload(add(_state, pos))
            }

            pos+=_gameLength+32+32+32;

            for(i=1; i<_gameIndex; i++) {
                assembly {
                    _gameLength := mload(add(_state, pos))
                }
                pos+=_gameLength+32+32+32;
            }

            pos-= 32+32;

            assembly {
                _gameLength := mload(add(_state, pos))
            }

            uint _posState = pos+64+_gameLength;

            assembly {
                _intType := mload(add(_state, add(pos, 32)))
                _CTFaddress := mload(add(_state, add(pos, 64)))
                _isClose := mload(add(_state, add(pos,96)))
                _sequence := mload(add(_state, add(pos,128)))
                _settlement := mload(add(_state, add(pos, 160)))
                _state := mload(add(_state, add(pos, _posState)))
            }

            games[_gameIndex].intType = _intType;
            games[_gameIndex].settlementPeriodLength = _settlement;
            games[_gameIndex].CTFaddress = _CTFaddress;
            games[_gameIndex].numParties = _numParties;
            games[_gameIndex].isClose = _isClose;
            games[_gameIndex].sequence = _sequence;
            games[_gameIndex].state = _state;
        }

    }

    function _getSig(bytes _d, uint8 _v, bytes32 _r, bytes32 _s) internal pure returns(address) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 h = keccak256(_d);

        bytes32 prefixedHash = keccak256(prefix, h);

        address a = ecrecover(prefixedHash, _v, _r, _s);

        //address a = ECRecovery.recover(prefixedHash, _s);

        return(a);
    }


    function isAddressInState(address _queryAddress) public returns (bool){

    }

    function quickClose(bytes _state) public returns (bool) {

    }

    function initState(bytes _state, uint8[] _v, bytes32[] _r, bytes32[] _s) public returns (bool) {
        _decodeState(_state, 0);

        require(isOpen == 1);
        require(isInSettlementState == 0);

        address[] memory tempSigs = new address[](_v.length);

        for(uint i=0; i<_v.length; i++) {
            address participant = _getSig(_state, _v[i], _r[i], _s[i]);
            tempSigs[i] = participant;
        }

        require(_hasAllSigs(tempSigs));
        state = _state;
    }

    function run(bytes _state) public {

    }
  

}