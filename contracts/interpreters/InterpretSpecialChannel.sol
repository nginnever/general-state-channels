
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
    address public partyA;
    address public partyB;
    uint256 public balanceA;
    uint256 public balanceB;
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
    function startSettleStateGame(uint _gameIndex, bytes _state, uint8[2] _v, bytes32[2] _r, bytes32[2] _s) public {
        _decodeState(_state, _gameIndex);

        require(games[_gameIndex].isClose == 0);
        require(games[_gameIndex].isInSettlementState == 0);

        // figure out decode ctf address and store
        InterpreterInterface deployedInterpreter = InterpreterInterface(registry.resolveAddress(games[_gameIndex].CTFaddress));

        address _partyA = _getSig(_state, _v[0], _r[0], _s[0]);
        address _partyB = _getSig(_state, _v[1], _r[1], _s[1]);

        require(_hasAllSigs(_partyA, _partyB));

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

    function challengeSettleStateGame(uint _gameIndex, bytes _state, uint8[2] _v, bytes32[2] _r, bytes32[2] _s) public {
        // require the channel to be in a settling state
        // figure out how to decode and store this in SPC
        //require(booleans[1] == 1);
        //require(settlementPeriodEnd <= now);
        address _partyA = _getSig(_state, _v[0], _r[0], _s[0]);
        address _partyB = _getSig(_state, _v[1], _r[1], _s[1]);

        require(_hasAllSigs(_partyA, _partyB));
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

    function closeWithTimeoutGame(uint _gameIndex, bytes _state, uint8[2] _v, bytes32[2] _r, bytes32[2] _s) public {
        // figure out how to decode and store this in SPC
        //require(settlementPeriodEnd <= now);
        //require(booleans[1] == 1);
        //require(booleans[0] == 1);

        // figure out how to decode the SPC balance with this state close
        //uint totalBalance = 0;
        //totalBalance = _decodeState(_state);
        //require(totalBalance == bonded);

        address _partyA = _getSig(_state, _v[0], _r[0], _s[0]);
        address _partyB = _getSig(_state, _v[1], _r[1], _s[1]);

        require(_hasAllSigs(_partyA, _partyB));
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

    function _hasAllSigs(address _a, address _b) internal view returns (bool) {
        require(_a == partyA && _b == partyB);

        return true;
    }

    function _decodeState(bytes _state, uint _gameIndex) internal {
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
        address _addressA;
        address _addressB;
        uint256 _balanceA;
        uint256 _balanceB;
        uint _gameLength;
        uint _sequence;
        uint _isClose;
        uint _settlement;
        uint _intType;
        bytes32 _CTFaddress;
        bytes memory _gameState;

        assembly {
            _numGames := mload(add(_state, 96))
            _addressA := mload(add(_state, 128))
            _addressB := mload(add(_state, 160))
            _balanceA := mload(add(_state, 192))
            _balanceB := mload(add(_state, 224))
        }



        // game index 0 means this is an initial state where there have
        // been no games loaded, so this state can't be assembled
        if (_gameIndex != 0) {
            numGames = _numGames;
            // push pointer past the addresses and balances
            uint pos = 256;

            assembly {
                _gameLength := mload(add(_state, pos))
            }

            pos+=_gameLength+32+32+32;

            for(uint i=1; i<_gameIndex; i++) {
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
                _gameState := mload(add(_state, add(pos, _posState)))
            }

            games[_gameIndex].intType = _intType;
            games[_gameIndex].settlementPeriodLength = _settlement;
            games[_gameIndex].CTFaddress = _CTFaddress;
            games[_gameIndex].isClose = _isClose;
            games[_gameIndex].sequence = _sequence;
            games[_gameIndex].state = _gameState;
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

    function initState(bytes _state, uint8[2] _v, bytes32[2] _r, bytes32[2] _s) public returns (bool) {
        _decodeState(_state, 0);

        require(isOpen == 1);
        require(isInSettlementState == 0);

        address _partyA = _getSig(_state, _v[0], _r[0], _s[0]);
        address _partyB = _getSig(_state, _v[1], _r[1], _s[1]);

        require(_hasAllSigs(_partyA, _partyB));
        
        state = _state;
    }

    function run(bytes _state) public {

    }
  

}