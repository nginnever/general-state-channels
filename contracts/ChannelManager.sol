pragma solidity ^0.4.18;

import "./JudgeInterface.sol";

contract ChannelManager {
    address public tester;
    bytes32 public hash;
    bytes32 public da;

    struct Channel
    {
        address partyA;
        address partyB;
        uint256 bond;
        uint256 bonded;
        JudgeInterface judge;

        uint settlementPeriod;
        bool open;
        bool settling;
    }

    mapping(bytes32 => Channel) channels;

    uint256 public numChannels = 0;

    event ChannelCreated(bytes32 channelId, address indexed partyA, address indexed partyB);

    function openChannel(address _partyB, uint _duration, uint _settlementPeriod, address _judge) public payable {
        JudgeInterface candidateContract = JudgeInterface(_judge);

        // NOTE: verify that a contract is what we expect - https://github.com/Lunyr/crowdsale-contracts/blob/cfadd15986c30521d8ba7d5b6f57b4fefcc7ac38/contracts/LunyrToken.sol#L117
        require(candidateContract.isJudge());
        require(_partyB != 0x0);


        Channel memory _channel = Channel(
            msg.sender, _partyB, msg.value, msg.value, candidateContract, _settlementPeriod, false, false);

        numChannels++;
        var _id = keccak256(now + numChannels);
        channels[_id] = _channel;


        ChannelCreated(_id, msg.sender, _partyB);
    }

    function joinChannel(bytes32 _id) public payable{
        require(channels[_id].partyB == msg.sender);
        require(msg.value == channels[_id].bond);
        channels[_id].open == true;
        channels[_id].bonded += msg.value;
    }

    // check that a valid state is signed by both parties
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

    function exerciseJudge(bytes32 _id, string _method, uint8 v, bytes32 r, bytes32 s, bytes32 _data) public {
        da = _data;
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
        // require(!channels[_id].judge.call(bytes4(bytes32(sha3(_method))), _data));
        require(!channels[_id].judge.run(_data));

        //channels[_id].judge.call(bytes4(bytes32(sha3(_method))), _data)

        // punish the violator and close the channel
        // msg.sender.send(_bonded / 2);
        // _bonded -= _bonded/2;

        // // return bond to non-violator
        // if(challenged == channels[_id].partyA) {
        //     channels[_id].partyB.send(_bonded);
        // } else {
        //     channels[_id].partyA.send(_bonded);
        // }

        delete channels[_id];
    }
}