'use strict'

const utils = require('./helpers/utils')

const ChannelManager = artifacts.require("./ChannelManager.sol")
const Judge = artifacts.require("./JudgeHelloWorld.sol")

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

    var msg = padBytes32(web3.toHex('hello'))
    let msgArr = [msg]
    msgArr.push('0xdeadbeef')
    console.log(msgArr)
    console.log(padBytes32(msg))
    var hmsg = web3.sha3(msg, {encoding: 'hex'})
    console.log('hashed msg: ' + hmsg)

    var sig = await web3.eth.sign(accounts[0], hmsg)
    var r = sig.substr(0,66)
    var s = "0x" + sig.substr(66,64)
    var v = 28

    let ttt = await jg.tester()
    console.log(ttt)

    await cm.exerciseJudge(channelId, 'run(bytes)', v, r, s, msg)
    let newState = await jg.newState()
    let testRecover = await cm.tester()
    let _hash = await cm.hash()
    console.log('Hash : ' + _hash)
    console.log('Recovered Address: ' + testRecover)
    console.log(accounts[0])
    console.log('Sliced new invalid state data: ' + newState)

    // let d = await cm.da(0)
    // console.log('data stored: ' + d)

    let load = await jg.temp()
    console.log('assembly data stored: ' + load)

    ttt = await jg.tester()
    console.log(ttt)
  })

})


function padBytes32(data){
  let l = 66-data.length
  for(var i=0; i<l; i++) {
    data+=0
  }
  return data
}