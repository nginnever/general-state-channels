'use strict'

const utils = require('./helpers/utils')

const ChannelManager = artifacts.require("./ChannelManager.sol")
const Judge = artifacts.require("./JudgeAlways420.sol")

let cm
let jg

let event_args

contract('ChannelManager', function(accounts) {
  it("ChannelManager deployed", async function() {
    cm = await ChannelManager.new()
    jg = await Judge.new()

    let res = await cm.openChannel(accounts[1], 1337, 1337, jg.address)
    let numChan = await cm.numChannels()
    console.log('Channels open: ' + numChan.toNumber())
    event_args = res.logs[0].args

    let channelId = event_args.channelId

    await cm.exerciseJudge(channelId, 'testVar(uint256)', 420)
    let data = await jg.data()
    console.log('Contract data after proxy call: ' + data.toNumber())
  })

})
