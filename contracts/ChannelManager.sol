pragma solidity ^0.4.18;

import "./judges/JudgeInterface.sol";
import "./interpreters/InterpreterInterface.sol";
import "./lib/ECRecovery.sol";

contract ChannelManager {
    bool public judgeRes;

    struct Channel
    {
        address partyA;
        address partyB;
        uint256 bond;
        uint256 bonded;
        JudgeInterface judge;
        InterpreterInterface interpreter;
        uint256 settlementPeriodLength;
        uint256 settlementPeriodEnd;
        uint8[3] booleans; // ['isChannelOpen', 'settlingPeriodStarted', 'judgeResolution']
        address[2] disputeAddresses;
        bytes state;
        uint sequenceNum;
    }

    mapping(bytes32 => Channel) channels;

    uint256 public numChannels = 0;

    event ChannelCreated(bytes32 channelId, address indexed partyA, address indexed partyB);

    function openChannel(
        address _partyB, 
        uint _bond, 
        uint _settlementPeriod, 
        address _interpreter, 
        address _judge, 
        bytes _data,
        bytes _sig) 
        public 
        payable 
    {

        JudgeInterface candidateJudgeContract = JudgeInterface(_judge);
        InterpreterInterface candidateInterpreterContract = InterpreterInterface(_interpreter);

        // NOTE: verify that a contract is what we expect - https://github.com/Lunyr/crowdsale-contracts/blob/cfadd15986c30521d8ba7d5b6f57b4fefcc7ac38/contracts/LunyrToken.sol#L117
        require(candidateJudgeContract.isJudge());
        require(candidateInterpreterContract.isInterpreter());

        // check the account opening a channel signed the initial state
        address s = _getSig(_data, _sig);
        require(s == msg.sender);

        // send bond to the interpreter contract. This contract will read agreed upon state 
        // and settle any outcomes of state. ie paying a wager on a game or settling a payment channel

        candidateInterpreterContract.send(msg.value);

        // not running judge against initial state since the client counterparty can check the state
        // before agreeing to join the channel

        require(_partyB != 0x0);


        Channel memory _channel = Channel(
            msg.sender,
            _partyB,
            _bond,
            msg.value,
            candidateJudgeContract,
            candidateInterpreterContract,
            _settlementPeriod,
            0,
            [0,0,1],
            [address(0x0),address(0x0)],
            _data,
            0
        );

        numChannels++;
        var _id = keccak256(now + numChannels);
        channels[_id] = _channel;


        ChannelCreated(_id, msg.sender, _partyB);
    }

    function joinChannel(bytes32 _id, bytes _data, bytes sig1, bytes sig2) public payable{
        require(channels[_id].partyB == msg.sender);
        require(channels[_id].booleans[0] == 0);
        require(msg.value == channels[_id].bond);

        address party1 = _getSig(_data, sig1);
        address party2 = _getSig(_data, sig2);

        require(party1 == channels[_id].partyA && party2 == channels[_id].partyB);

        channels[_id].booleans[0] = 1;
        channels[_id].bonded += msg.value;

        channels[_id].interpreter.send(msg.value);
    }

    // This updates the state stored in the channel struct
    // check that a valid state is signed by both parties
    // change this to an optional update function to checkpoint state
    function checkpointState(
        bytes32 _id, 
        bytes _data, 
        bytes sig1,
        bytes sig2,
        uint _seq) 
        public 
    {

        address party1 = _getSig(_data, sig1);
        address party2 = _getSig(_data, sig2);

        require(party1 == channels[_id].partyA && party2 == channels[_id].partyB);

        require(channels[_id].interpreter.isSequenceEqual(_data, _seq));
        require(channels[_id].sequenceNum < _seq);

        // run the judge to be sure this is a valid state transition? does this matter if it was agreed upon?
        channels[_id].state = _data;
        channels[_id].sequenceNum = _seq;
    }

    // Fast close: Both parties agreed to close
    // check that a valid state is signed by both parties
    // change this to an optional update function to checkpoint state
    function closeChannel(
        bytes32 _id, 
        bytes _data, 
        bytes sig1,
        bytes sig2) 
        public 
    {

        address challenged = _getSig(_data, sig1);
        address challenged2 = _getSig(_data, sig2);

        require(challenged == channels[_id].partyA && challenged2 == channels[_id].partyB);
        //  If the first 32 bytes of the state represent true 0x00...01 then both parties have
        // signed a close channel agreement on this representation of the state.

        // check for this sentinel value

        require(channels[_id].interpreter.isClose(_data));
        require(channels[_id].interpreter.quickClose(_data));

        // run the judge to be sure this is a valid state transition? does this matter if it was agreed upon?
        channels[_id].state = _data;
        channels[_id].booleans[0] = 0;
    }

    // Closing with the following does not need to contain a flag in state for an agreed close

    // requires judge exercised
    function closeWithChallenge(bytes32 _id) public {
        require(channels[_id].disputeAddresses[0] != 0x0);
        require(channels[_id].booleans[2] == 0);
        // have the interpreter act on the verfied incorrect state 
        channels[_id].interpreter.challenge(channels[_id].disputeAddresses[0], channels[_id].state);
        channels[_id].booleans[0] = 0;
    }

    function closeWithTimeout(bytes32 _id) public {
        require(channels[_id].settlementPeriodEnd >= now);

        // handle timeout logic
        channels[_id].interpreter.quickClose(channels[_id].state);
        channels[_id].booleans[0] = 0;
    }

    function challengeSettleState(bytes32 _id, bytes _data, bytes sig1, bytes sig2, string _method, uint256 _seqNum) public {
        // require the channel to be in a settling state
        require(channels[_id].booleans[1] == 1);
        require(channels[_id].settlementPeriodEnd <= now);
        uint dataLength = _data.length;

        require(channels[_id].settlementPeriodEnd < now);

        address partyA = _getSig(_data, sig1);
        address partyB = _getSig(_data, sig2);

        require(partyA == channels[_id].partyA && partyB == channels[_id].partyB);

        if (channels[_id].judge.call(bytes4(bytes32(sha3(_method))), bytes32(32), bytes32(dataLength), _data)) {
            judgeRes = true;
            channels[_id].booleans[2] = 1;

        } else {
            judgeRes = false;
            channels[_id].booleans[2] = 0;
            channels[_id].state = _data;
            // channels[_id].disputeAddresses[0] = initiator;
            // channels[_id].disputeAddresses[1] = msg.sender;
        }

        require(channels[_id].booleans[2] == 1);

        // we also alow the sequence to be equal to allow continued game
        require(channels[_id].interpreter.isSequenceHigher(_data, channels[_id].sequenceNum));
        require(channels[_id].interpreter.isSequenceEqual(_data, _seqNum));

        channels[_id].settlementPeriodEnd = now + channels[_id].settlementPeriodLength;
        channels[_id].state = _data;
        channels[_id].sequenceNum = _seqNum;

    }

    function startSettleState(bytes32 _id, string _method, bytes sig1, bytes sig2, bytes _data, uint256 _seqNum) public {
        require(channels[_id].booleans[1] == 0);

        uint dataLength = _data.length;

        //require(!channels[_id].interpreter.isClose(_data));
        address partyA = _getSig(_data, sig1);
        address partyB = _getSig(_data, sig2);

        require(partyA == channels[_id].partyA && partyB == channels[_id].partyB);

        // In order to start settling we run the judge to be sure this is a valid state transition

        if (channels[_id].judge.call(bytes4(bytes32(sha3(_method))), bytes32(32), bytes32(dataLength), _data)) {
            judgeRes = true;
            channels[_id].booleans[2] = 1;

        } else {
            judgeRes = false;
            channels[_id].booleans[2] = 0;
            channels[_id].state = _data;
            // channels[_id].disputeAddresses[0] = initiator;
            // channels[_id].disputeAddresses[1] = msg.sender;
        }

        require(channels[_id].booleans[2] == 1);
        require(channels[_id].interpreter.isSequenceHigher(_data, channels[_id].sequenceNum));
        require(channels[_id].interpreter.isSequenceEqual(_data, _seqNum));

        channels[_id].booleans[1] = 1;
        channels[_id].sequenceNum = _seqNum;
        channels[_id].settlementPeriodEnd = now + channels[_id].settlementPeriodLength;
    }

    function exerciseJudge(bytes32 _id, string _method, bytes sig, bytes _data) public returns(bool success){
        uint dataLength = _data.length;

        // uint256 _bonded = channels[_id].bonded;
        // channels[_id].bonded = 0;

        address challenged = _getSig(_data, sig);

        require(challenged == channels[_id].partyA || challenged == channels[_id].partyB);
        // assert that the state update failed the judge run

        // address addr = address(channels[_id].judge);
        // bytes4 sig = bytes4(bytes32(sha3(_method)));
        // assembly {
        //     let x := mload(0x40)
        //     mstore(x, sig)
        //     mstore(add(x,0x04), _data)

        //     let success := call(5000, addr, 0, x, 0x44, x, 0x20)
        //     let c := mload(x)
        //     mstore(0x40, add(x,0x44))
        // }

        if (!channels[_id].judge.call(bytes4(bytes32(sha3(_method))), bytes32(32), bytes32(dataLength), _data)) {
            judgeRes = false;
            channels[_id].booleans[2] = 0;
            channels[_id].state = _data;
            channels[_id].disputeAddresses[0] = challenged;
            channels[_id].disputeAddresses[1] = msg.sender;

        }
    }

    function getChannel(bytes32 _id)
        external
        view
        returns
    (
        address partyA,
        address partyB,
        uint256 bond,
        uint256 bonded,
        address judge,
        address interpreter,
        uint256 settlementPeriodLength,
        uint256 settlementPeriodEnd,
        uint8[3] booleans,
        address[2] disputeAddresses,
        bytes state,
        uint sequenceNum
    ) {

        Channel storage ch = channels[_id];

        return (
            ch.partyA,
            ch.partyB,
            ch.bond,
            ch.bonded,
            ch.judge,
            ch.interpreter,
            ch.settlementPeriodLength,
            ch.settlementPeriodEnd,
            ch.booleans,
            ch.disputeAddresses,
            ch.state,
            ch.sequenceNum
        );
    }

    function _getSig(bytes _d, bytes _s) internal returns(address) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 h = keccak256(_d);

        bytes32 prefixedHash = keccak256(prefix, h);

        address a = ECRecovery.recover(prefixedHash, _s);

        return(a);
    }
}