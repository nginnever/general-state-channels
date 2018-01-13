'use strict'

const utils = require('./helpers/utils')

const ChannelManager = artifacts.require("./ChannelManager.sol")
const Judge = artifacts.require("./Judge.sol")

let cm
let jg

contract('ChannelManager', function(accounts) {
  it("ChannelManager deployed", async function() {
    cm = await ChannelManager.new()
    jg = await Judge.new()

    await cm.openChannel(jg.address)
    let numChan = await cm.numChannels()
    console.log('Channels open: ' + numChan.toNumber())

    await cm.exerciseJudge(1, 'testVar(bytes)', 0, 'test')
  })

})
