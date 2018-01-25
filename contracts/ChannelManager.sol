pragma solidity ^0.4.18;

import "./JudgeInterface.sol";
import "./InterpreterInterface.sol";
import "./lib/ECRecovery.sol";

contract ChannelManager {
    address public tester;
    address public tester2;
    bytes32 public hash;
    bytes32[] public da;
    uint public dlength;
    bool public judgeRes;

    struct Channel
    {
        address partyA;
        address partyB;
        uint256 bond;
        uint256 bonded;
        JudgeInterface judge;
        InterpreterInterface interpreter;
        uint settlementPeriod;
        uint8[3] booleans; //  [0,1] = [false, true] : ['isChannelOpen', 'isInSettlingPeriod', 'judgeResolution']
        address[2] disputeAddresses;
        bytes state;
        uint sequenceNum;
    }

    mapping(bytes32 => Channel) channels;

    uint256 public numChannels = 0;

    event ChannelCreated(bytes32 channelId, address indexed partyA, address indexed partyB);

    function openChannel(
        address _partyB, 
        uint _duration, 
        uint _settlementPeriod, 
        address _interpreter, 
        address _judge, 
        bytes _initState) 
        public 
        payable 
    {
        // Open channel should run an initial state against the judge to make sure it is okay.

        JudgeInterface candidateJudgeContract = JudgeInterface(_judge);
        InterpreterInterface candidateInterpreterContract = InterpreterInterface(_interpreter);

        // NOTE: verify that a contract is what we expect - https://github.com/Lunyr/crowdsale-contracts/blob/cfadd15986c30521d8ba7d5b6f57b4fefcc7ac38/contracts/LunyrToken.sol#L117
        require(candidateJudgeContract.isJudge());
        require(candidateInterpreterContract.isInterpreter());

        // send bond to the interpreter contract. This contract will read agreed upon state 
        // and settle any outcomes of state. ie paying a wager on a game or settling a payment channel

        candidateInterpreterContract.send(msg.value);

        require(_partyB != 0x0);


        Channel memory _channel = Channel(
            msg.sender, 
            _partyB, 
            msg.value, 
            msg.value, 
            candidateJudgeContract, 
            candidateInterpreterContract, 
            _settlementPeriod, 
            [0,0,1],
            [address(0x0),address(0x0)],
            _initState, 
            0
        );

        numChannels++;
        var _id = keccak256(now + numChannels);
        channels[_id] = _channel;


        ChannelCreated(_id, msg.sender, _partyB);
    }

    function joinChannel(bytes32 _id) public payable{
        require(channels[_id].partyB == msg.sender);
        require(msg.value == channels[_id].bond);
        channels[_id].booleans[0] = 1;
        channels[_id].bonded += msg.value;

        channels[_id].interpreter.send(msg.value);
    }

    // This updates the state stored in the channel struct
    // check that a valid state is signed by both parties
    // change this to an optional update function to checkpoint state
    function checkpoint(
        bytes32 _id, 
        bytes _data, 
        bytes sig1,
        bytes sig2) 
        public 
    {
        // check this state is signed by both parties
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 h = keccak256(_data);
        hash = h;

        bytes32 prefixedHash = keccak256(prefix, h);

        address challenged = ECRecovery.recover(prefixedHash, sig1);
        address challenged2 = ECRecovery.recover(prefixedHash, sig2);

        require(challenged == channels[_id].partyA && challenged2 == channels[_id].partyB);

        uint seq;

        assembly {
            seq := mload(add(_data, 64))
        }

        require(!channels[_id].interpreter.isClose(_data));
        require(channels[_id].sequenceNum < seq);

        // run the judge to be sure this is a valid state transition? does this matter if it was agreed upon?
        channels[_id].state = _data;
        channels[_id].sequenceNum = seq;
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
        // check this state is signed by both parties
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 h = keccak256(_data);
        hash = h;

        bytes32 prefixedHash = keccak256(prefix, h);

        address challenged = ECRecovery.recover(prefixedHash, sig1);
        address challenged2 = ECRecovery.recover(prefixedHash, sig2);

        require(challenged == channels[_id].partyA && challenged2 == channels[_id].partyB);
        //  If the first 32 bytes of the state represent true 0x00...01 then both parties have
        // signed a close channel agreement on this representation of the state.

        // check for this sentinel value

        require(channels[_id].interpreter.isClose(_data));

        // run the judge to be sure this is a valid state transition? does this matter if it was agreed upon?
        channels[_id].state = _data;
        channels[_id].booleans[0] = 0;
    }

    function closeWithChallenge(bytes32 _id) public {
        require(channels[_id].disputeAddresses[0] != 0x0);
        require(channels[_id].booleans[2] == 0);
        channels[_id].interpreter.challenge(channels[_id].disputeAddresses[0], channels[_id].state);
        channels[_id].booleans[0] = 0;
    }

    function exerciseJudge(bytes32 _id, string _method, bytes sig, bytes _data) public returns(bool success){
        //da.push(_data[0]);
        uint dataLength = _data.length;
        dlength = dataLength;

        uint256 _bonded = channels[_id].bonded;
        channels[_id].bonded = 0;

        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 h = keccak256(_data);
        hash = h;
        bytes32 prefixedHash = keccak256(prefix, h);
        address challenged = ECRecovery.recover(prefixedHash, sig);
        tester = challenged;

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

        if (channels[_id].judge.call(bytes4(bytes32(sha3(_method))), bytes32(32), bytes32(dataLength), _data)) {
            judgeRes = true;
            channels[_id].booleans[2] = 1;

        } else {
            judgeRes = false;
            channels[_id].booleans[2] = 0;
            channels[_id].state = _data;
            channels[_id].disputeAddresses[0] = challenged;
            channels[_id].disputeAddresses[1] = msg.sender;
        }

        // punish the violator and close the channel
        // msg.sender.send(_bonded / 2);
        // _bonded -= _bonded/2;

        // // return bond to non-violator
        // if(challenged == channels[_id].partyA) {
        //     channels[_id].partyB.send(_bonded);
        // } else {
        //     channels[_id].partyA.send(_bonded);
        // }

        // delete channels[_id];
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
        uint settlementPeriod,
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
            ch.settlementPeriod,
            ch.booleans,
            ch.disputeAddresses,
            ch.state,
            ch.sequenceNum
        );
    }
}