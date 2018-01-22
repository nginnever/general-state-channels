pragma solidity ^0.4.18;

import "./JudgeInterface.sol";
import "./InterpreterInterface.sol";

contract ChannelManager {
    address public tester;
    bytes32 public hash;
    bytes32[] public da;
    uint public dlength;

    struct Channel
    {
        address partyA;
        address partyB;
        uint256 bond;
        uint256 bonded;
        JudgeInterface judge;
        InterpreterInterface interpreter;

        uint settlementPeriod;
        bool open;
        bool settling;
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
            false, 
            false, 
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
        channels[_id].open = true;
        channels[_id].bonded += msg.value;

        channels[_id].interpreter.send(msg.value);
    }

    // This updates the state stored in the channel struct
    // check that a valid state is signed by both parties
    // change this to an optional update function to checkpoint state
    function checkpoint(
        bytes32 _id, 
        bytes32 _data, 
        uint8 v, 
        bytes32 r, 
        bytes32 s, 
        uint8 v2, 
        bytes32 r2, 
        bytes32 s2) 
        public 
    {
    // 

    }

    // Fast close: Both parties agreed to close
    // check that a valid state is signed by both parties
    // change this to an optional update function to checkpoint state
    function closeChannel(
        bytes32 _id, 
        bytes32 _data, 
        uint8 v, 
        bytes32 r, 
        bytes32 s, 
        uint8 v2, 
        bytes32 r2, 
        bytes32 s2) 
        public 
    {
    // 

    }

    function exerciseJudge(bytes32 _id, string _method, uint8 v, bytes32 r, bytes32 s, bytes _data) public returns(bool success){
        //da.push(_data[0]);
        uint dataLength = _data.length;
        dlength = dataLength;

        uint256 _bonded = channels[_id].bonded;
        channels[_id].bonded = 0;

        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 h = keccak256(_data);
        hash = h;
        bytes32 prefixedHash = keccak256(prefix, h);
        address challenged = ecrecover(prefixedHash, v, r, s);
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

        require(channels[_id].judge.call(bytes4(bytes32(sha3(_method))), bytes32(32), bytes32(dataLength), _data));

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
        bool open,
        bool settling,
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
            ch.open,
            ch.settling,
            ch.state,
            ch.sequenceNum
        );
    }
}