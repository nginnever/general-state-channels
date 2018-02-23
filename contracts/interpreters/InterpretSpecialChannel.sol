
pragma solidity ^0.4.18;

import "../ChannelRegistry.sol";
import "./InterpreterInterface.sol";
import "./InterpretNPartyPayments.sol";
import "./InterpretBidirectional.sol";
import "./InterpretPaymentChannel.sol";
import "./InterpretBattleChannel.sol";

// this contract will essentially be the current channelManager contract
// requirements:
//   - quick close channel: minimal state update, only update final bond balances 
//   - start settle state: calls bidirectional instantiated contract to check sigs, store state and sequence num, start challenge period
//   - challenge settle state: calls bidirectional to check sigs and higher sequence num
contract InterpretSpecialChannel is InterpreterInterface {
    // state
    mapping(address => uint256) balances;
    uint numParties;
    uint256 bonded = 0;
    bytes public state;

    function startSettleStateGame(uint _gameIndex, bytes _state, uint8[] _v, bytes32[] _r, bytes32[] _s) public {
        _decodeState(_state);

    }

    // No need for a consensus close on the SPC since it is only instantiated in 
    // byzantine cases and just requires updating the state
    // client side (update spc bond balances, updates number of channels open, remove
    // closed channel state from total SPC state)

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

    function hasAllSigs(address[] _recovered) returns (bool) {
        require(_recovered.length == numParties);

        for(uint i=0; i<_recovered.length; i++) {
            // this means that final state balances can't be 0, fix this!
            require(balances[_recovered[i]] != 0);
        }

        return true;
    }

    function _decodeState(bytes _state) internal returns(uint256 totalBalance){
        uint numParty;
        uint256 total;
        assembly {
            numParty := mload(add(_state, 96))
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
                tempA:= mload(add(_state, posA))
                temp :=mload(add(_state, pos))
            }

            total+=temp;
            balances[tempA] = temp;
        }
        return total;
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

    function quickClose(bytes _data) public returns (bool) {

    }

    function initState(bytes _date) public returns (bool) {

    }

    function run(bytes _data) public {

    }
  

}