'use strict'

const utils = require('./helpers/utils')

const ChannelManager = artifacts.require("./ChannelManager.sol")
const Judge = artifacts.require("./JudgeHelloWorld.sol")
const Interpreter = artifacts.require("./InterpretHelloWorld.sol")

let cm
let jg
let int

let event_args

contract('ChannelManager', function(accounts) {
  it("ChannelManager deployed", async function() {
    cm = await ChannelManager.new()
    jg = await Judge.new()
    int = await Interpreter.new()

    let res = await cm.openChannel(accounts[1], 1337, 1337, int.address, jg.address, '0x0', {from: accounts[0], value: web3.toWei(2, 'ether')})
    let numChan = await cm.numChannels()

    event_args = res.logs[0].args

    let channelId = event_args.channelId
    console.log('Channels created: ' + numChan.toNumber() + ' channelId: ' + channelId)

    await cm.joinChannel(channelId, {from: accounts[1], value: web3.toWei(2, 'ether')})

    let open = await cm.getChannel(channelId)
    console.log('Channel joined, open: ' + open[7])

    // State encoding

    // Rounds will be played that builf the word "hello"
    // The first person will sign state containing "h"
    // followed by the second account recieving and checking the letter
    // If the letter is not in "hello" then they may present the invalid state
    // If valid the second will sign "h". At this point state is agreed and may be checkpointed
    // Account 2 will then concat "e" transforming state to "he" and send this to account1
    // repeat until "hello" is signed by both parties and close the state
    // there is no wager so the interpreter should just return the bond

    // we build the first 32 byte word with a sentinel value indicating the party is 
    // interested in closing this channel
    var sentinel = padBytes32(web3.toHex(1))
    var sequence = padBytes32(web3.toHex(1))

    var h = padBytes32(web3.toHex('h'))
    var e = padBytes32(web3.toHex('e'))
    var l = padBytes32(web3.toHex('l'))
    var o = padBytes32(web3.toHex('o'))

    console.log('Sequence number: ' + sequence)

    var msg = sentinel + 
              sequence.substr(2, sequence.length) + 
              h.substr(2, h.length) + 
              e.substr(2, e.length) + 
              l.substr(2, l.length) + 
              l.substr(2, l.length) +
              o.substr(2, o.length)

    console.log('State input: ' + msg)

    // let msgArr = [msg]
    // msgArr.push(padBytes32(web3.toHex('deadbeef')))
    // console.log(msgArr)

    // Hashing and signature
    var hmsg = web3.sha3(msg, {encoding: 'hex'})
    console.log('hashed msg: ' + hmsg)

    var sig = await web3.eth.sign(accounts[0], hmsg)
    var r = sig.substr(0,66)
    var s = "0x" + sig.substr(66,64)
    var v = 27

    await cm.exerciseJudge(channelId, 'run(bytes)', v, r, s, msg)

    sig = await web3.eth.sign(accounts[1], hmsg)
    var r2 = sig.substr(0, 66)
    var s2 = "0x" + sig.substr(66, 64)
    var v2 = 27

    await cm.closeChannel(channelId, msg, v, r, s, v2, r2, s2)

    console.log('Channel closed by two party signature on close sentinel')

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