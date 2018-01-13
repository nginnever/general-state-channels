pragma solidity ^0.4.18;

import "./JudgeInterface.sol";

contract ChannelManager {

    struct Participant
    {
        uint256 balance;
        uint256 channelId;
    }

    struct Channel
    {
        address a;
        address b;
        uint256 bond;
        JudgeInterface judge;

        uint settlementPeriod;
    }

    mapping(address => Participant) participants;
    mapping(uint256 => Channel) channels;

    uint256 public numChannels;

    function openChannel(address _judge) public payable {
        JudgeInterface candidateContract = JudgeInterface(_judge);

        // NOTE: verify that a contract is what we expect - https://github.com/Lunyr/crowdsale-contracts/blob/cfadd15986c30521d8ba7d5b6f57b4fefcc7ac38/contracts/LunyrToken.sol#L117
        require(candidateContract.isJudge());

        Channel memory _channel = Channel(msg.sender, 0x0, msg.value, candidateContract, 0);
        numChannels++;
        channels[numChannels] = _channel;


        // Set the new contract address
    }

    function closeChannel() public {

    }

    function exerciseJudge(uint256 _id, string _method, uint256 _value, bytes _data) public {
        require(channels[_id].judge.call(bytes4(bytes32(sha3(_method))), msg.sender, _value, this, _data));
    }

    function challengeClose() public {

    }
}