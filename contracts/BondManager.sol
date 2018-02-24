// This contract acts as a multisig between channel participants. 
// Requirements
//   - store bond value in ether and tokens
//   - store counterfactual address of SPC
//   - point that address to the registry contract
//   - check sigantures on state of SPC
//   - check that byte code derives CTF address
//   - Be able to reconstruct final balances on SPC from state of SPC
//   - Some non-zero balance for all participants

pragma solidity ^0.4.18;

import "./ChannelRegistry.sol";
import "./interpreters/InterpreterInterface.sol";

contract BondManager {
    // TODO: Allow token balances
    mapping(address => uint256) balances;

    ChannelRegistry public registry;

    uint sequenceNum = 0;
    uint public numParties = 0;
    uint public numJoined = 0;
    uint256 bond = 0; //in state
    uint256 bonded = 0;
    bytes32 interpreter;
    uint256 settlementPeriodLength;
    uint256 settlementPeriodEnd = 0;
    uint8[] booleans = [0,0,0]; // ['isChannelOpen', 'settlingPeriodStarted', 'judgeResolution']
    bytes state;

    event ChannelCreated(bytes32 channelId, address indexed initiator);
    event ChannelJoined(bytes32 channelId, address indexed joiningParty);

    function BondManager(uint _settlementPeriod, bytes32 _interpreter, address _registry) {
        require(_settlementPeriod >= 0);
        require(_interpreter != 0x0);
        require(_registry != 0x0);
        interpreter = _interpreter;
        settlementPeriodLength = _settlementPeriod;
        registry = ChannelRegistry(_registry);
    }

    function openChannel(
        bytes _state,
        uint8 _v,
        bytes32 _r,
        bytes32 _s) 
        public 
        payable
    {
        // check the account opening a channel signed the initial state
        address s = _getSig(_state, _v, _r, _s);
        // consider if this is required
        require(s == msg.sender || s == tx.origin);
        bond = _decodeState(_state);
        require(balances[s] == msg.value);

        bonded += msg.value;
    }

    function joinChannel(uint8 _v, bytes32 _r, bytes32 _s) public payable{
        // require the channel is not open yet
        require(booleans[0] == 0);

        // check that the state is signed by the sender and sender is in the state
        address _joiningParty = _getSig(state, _v, _r, _s);

        require(balances[_joiningParty] == msg.value);

        bonded += msg.value;
        numJoined++;
        if(numJoined == numParties) {
            require(bond == bonded);
            booleans[0] = 1;
        }
    }

    function closeChannel(bytes _state, uint8[] sigV, bytes32[] sigR, bytes32[] sigS) public {
        require(_isClose(_state));
        require(sigV.length == sigR.length && sigR.length == sigS.length);

        uint totalBalance = 0;
        totalBalance = _decodeState(_state);
        require(totalBalance == bonded);

        address[] memory tempSigs = new address[](sigV.length);

        for(uint i=0; i<sigV.length; i++) {
            address participant = _getSig(_state, sigV[i], sigR[i], sigS[i]);
            tempSigs[i] = participant;
        }

        require(_hasAllSigs(tempSigs));
        _payout(tempSigs);
    }

    function startSettleState(uint _gameIndex, uint8[] _v, bytes32[] _r, bytes32[] _s, bytes _data) public {
        require(booleans[1] == 0);
        require(_v.length == _r.length && _r.length == _s.length);
        InterpreterInterface deployedInterpreter = InterpreterInterface(registry.resolveAddress(interpreter));

        if(_gameIndex == 0) {
            uint dataLength = _data.length;

            address[] memory tempSigs = new address[](_v.length);

            for(uint i=0; i<_v.length; i++) {
                address participant = _getSig(_data, _v[i], _r[i], _s[i]);
                tempSigs[i] = participant;
            }

            require(_hasAllSigs(tempSigs));
            // consult the now deployed special channel logic to see if sequence is higher
            // this also may not be necessary, just check sequence on challenges. what if 
            // the initial state needs to be settled?
            require(deployedInterpreter.isSequenceHigher(_data, state));

            // consider running some logic on the state from the interpreter to validate 
            // the new state obeys transition rules

            booleans[1] = 1;
            settlementPeriodEnd = now + settlementPeriodLength;
            state = _data;
        } else {
            deployedInterpreter.startSettleStateGame(_gameIndex, _data, _v, _r, _s);
        }
    }

    function challengeSettleState(bytes _data, uint8[] _v, bytes32[] _r, bytes32[] _s) public {
        // require the channel to be in a settling state
        require(booleans[1] == 1);
        require(settlementPeriodEnd <= now);
        uint dataLength = _data.length;

        address[] memory tempSigs = new address[](_v.length);

        for(uint i=0; i<_v.length; i++) {
            address participant = _getSig(_data, _v[i], _r[i], _s[i]);
            tempSigs[i] = participant;
        }

        // make sure all parties have signed
        require(_hasAllSigs(tempSigs));

        // consult the now deployed special channel logic to see if sequence is higher 
        InterpreterInterface deployedInterpreter = InterpreterInterface(registry.resolveAddress(interpreter));
        require(deployedInterpreter.isSequenceHigher(_data, state));

        // consider running some logic on the state from the interpreter to validate 
        // the new state obeys transition rules. The only invalid transition is trying to 
        // create more tokens than the bond holds, since each contract is currently deployed
        // for each channel, closing on a bad state like that would just fail at the channels
        // expense.

        settlementPeriodEnd = now + settlementPeriodLength;
        state = _data;
    }

    function closeWithTimeout(bytes _state, uint8[] sigV, bytes32[] sigR, bytes32[] sigS) public {
        require(settlementPeriodEnd <= now);
        require(booleans[1] == 1);
        require(booleans[0] == 1);
        require(sigV.length == sigR.length && sigR.length == sigS.length);

        uint totalBalance = 0;
        totalBalance = _decodeState(_state);
        require(totalBalance == bonded);

        address[] memory tempSigs = new address[](sigV.length);

        for(uint i=0; i<sigV.length; i++) {
            address participant = _getSig(_state, sigV[i], sigR[i], sigS[i]);
            tempSigs[i] = participant;
        }

        require(_hasAllSigs(tempSigs));
        _payout(tempSigs);
        booleans[0] = 0;
    }

    function _payout(address[] _parties) internal {
        for(uint i=0; i<numParties; i++) {
            _parties[i].transfer(balances[_parties[i]]);
        }
    }

    function _hasAllSigs(address[] _recovered) internal view returns (bool) {
        require(_recovered.length == numParties);

        for(uint i=0; i<_recovered.length; i++) {
            // this means that final state balances can't be 0, fix this!
            require(balances[_recovered[i]] != 0);
        }

        return true;
    }

    function _isClose(bytes _data) internal pure returns(bool) {
        uint isClosed;

        assembly {
            isClosed := mload(add(_data, 32))
        }

        require(isClosed == 1);
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

            posA = 160+(32*i);
            pos = 160+(32*numParty)+(32*i);

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

}