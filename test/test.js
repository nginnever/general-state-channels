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

    
    var sequence = padBytes32(web3.toHex(2))

    var hello = padBytes32(web3.toHex('hello'))
    var word2 = padBytes32(web3.toHex('world'))
    var word3 = padBytes32(web3.toHex('weee'))
    console.log('Sequence number: ' + sequence)

    var msg = sequence + word2.substr(2, word2.length) + hello.substr(2, hello.length) + word3.substr(2, word3.length)
    console.log('State input: ' + msg)

    // let msgArr = [msg]
    // msgArr.push(padBytes32(web3.toHex('deadbeef')))
    // console.log(msgArr)

    var hmsg = web3.sha3(msg, {encoding: 'hex'})
    console.log('hashed msg: ' + hmsg)

    var sig = await web3.eth.sign(accounts[0], hmsg)
    var r = sig.substr(0,66)
    var s = "0x" + sig.substr(66,64)
    var v = 28

    await cm.exerciseJudge(channelId, 'run(bytes)', v, r, s, msg)

    let testRecover = await cm.tester()
    let _hash = await cm.hash()

    console.log('Hash : ' + _hash)
    console.log('Recovered Address: ' + testRecover)
    console.log('Signing address: ' + accounts[0])

    let load = await jg.temp()
    console.log('assembly data stored: ' + load)

    let dl = await cm.dlength()
    console.log('state length: ' + dl)

    let _seq = await jg.s()
    console.log('recovered sequence num: ' + _seq)
  })

})


function padBytes32(data){
  let l = 66-data.length
  let x = data.substr(2, data.length)

  for(var i=0; i<l; i++) {
    x = 0 + x
  }
  return '0x' + x
}

function rightPadBytes32(data){
  let l = 66-data.length

  for(var i=0; i<l; i++) {
    data+=0
  }
  return data
}