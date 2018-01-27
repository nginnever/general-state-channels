'use strict'

const utils = require('./helpers/utils')

const ChannelManager = artifacts.require("./ChannelManager.sol")
const Judge = artifacts.require("./JudgePaymentChannel.sol")
const Interpreter = artifacts.require("./InterpretPaymentChannel.sol")

let cm
let jg
let int

let event_args

contract('Single direction payment channel', function(accounts) {
  it("Payment Channel", async function() {
    cm = await ChannelManager.new()
    jg = await Judge.new()
    int = await Interpreter.new()


    // State encoding
    // We simply replace the sequence number with the receiver balance
    // ----------- valid state -------------- //
    var sentinel = padBytes32(web3.toHex(0))
    var balance = padBytes32(web3.toHex(1))

    var msg = sentinel + balance.substr(2, balance.length)

    console.log('State input: ' + msg)


    // Hashing and signature
    hmsg = web3.sha3(msg, {encoding: 'hex'})
    console.log('hashed msg: ' + hmsg)

    var sig = await web3.eth.sign(accounts[0], hmsg)

    let res = await cm.openChannel(accounts[1], 1337, 1337, int.address, jg.address, msg, sig1, {from: accounts[0], value: web3.toWei(2, 'ether')})
    let numChan = await cm.numChannels()

    event_args = res.logs[0].args

    let channelId = event_args.channelId
    console.log('Channels created: ' + numChan.toNumber() + ' channelId: ' + channelId)

    await cm.joinChannel(channelId, {from: accounts[1], value: web3.toWei(2, 'ether')})

    let open = await cm.getChannel(channelId)
    console.log('Channel joined, open: ' + open[8][0])

//     await cm.exerciseJudge(channelId, 'run(bytes)', sig1, msg)

//     var sig2 = await web3.eth.sign(accounts[1], hmsg)
//     // var r2 = sig2.substr(0, 66)
//     // var s2 = "0x" + sig2.substr(66, 64)
//     // var v2 = 27

//     await cm.closeChannel(channelId, msg, sig1, sig2)

//     open = await cm.getChannel(channelId)

//     console.log('Channel closed by two party signature on close sentinel')

//     console.log('Signing address: ' + accounts[0])

//     let load = await jg.temp()
//     console.log('assembly data stored: ' + load)

//     let _seq = await jg.s()
//     console.log('recovered sequence num: ' + _seq)

//     console.log('Judge resolution: ' + open[8][2])

//     // build an invalid state, signed by one of the parties. Excersize the judge so that it
//     // may fail and set the violator and state of violation. Then use the interpreter proxy call
//     // to resolve the action of sending the violators bond to the challenger.

//     console.log('\n')
//     console.log('Starting game...')
//     // Initial State

//     sentinel = padBytes32(web3.toHex(0))
//     sequence = padBytes32(web3.toHex(1))

//     h = padBytes32(web3.toHex('h'))

//     msg = sentinel + 
//               sequence.substr(2, sequence.length) + 
//               h.substr(2, h.length)

//     hmsg = web3.sha3(msg, {encoding: 'hex'})
//     console.log('hashed msg: ' + hmsg)

//     sig1 = await web3.eth.sign(accounts[0], hmsg)
//     //console.log('State signature: ' + sig1)

//     console.log('\nState_0: ' + msg)
//     // Open new Channel

//     res = await cm.openChannel(accounts[1], 1337, 1337, int.address, jg.address, msg, sig1, {from: accounts[0], value: web3.toWei(2, 'ether')})
//     numChan = await cm.numChannels()

//     event_args = res.logs[0].args

//     channelId = event_args.channelId
//     console.log('Channels created: ' + numChan.toNumber() + ' channelId: ' + channelId)

//     console.log('{Simulated network send of channelId and state}')
//     console.log('{Player 2 validating initial state, signing, and joining channel}\n')

//     await cm.joinChannel(channelId, {from: accounts[1], value: web3.toWei(2, 'ether')})

//     open = await cm.getChannel(channelId)
//     console.log('Channel joined, open: ' + open[8][0])



//     // State 2

//     console.log('Starting game...\n')
//     console.log('Player 2 assembling state_1 _he_')
//     // Initial State

//     sentinel = padBytes32(web3.toHex(0))
//     sequence = padBytes32(web3.toHex(2))

//     msg = sentinel + 
//               sequence.substr(2, sequence.length) + 
//               h.substr(2, h.length) +
//               e.substr(2, e.length)

//     console.log('State_1: ' + msg)

//     hmsg = web3.sha3(msg, {encoding: 'hex'})
//     console.log('hashed msg: ' + hmsg)

//     sig2 = await web3.eth.sign(accounts[1], hmsg)
//     //console.log('State signature: ' + sig2)

//     console.log('{Simulated network send of player 2 State_1}')
//     console.log('{Player 1 validating State_1, and signing}\n')

//     sig1 = await web3.eth.sign(accounts[0], hmsg)


//     //console.log('State signature: ' + sig1)
//     // State 3

//     console.log('Player 1 assembling state_2 _hel_')
//     console.log('Player also signals to checkpoint this state transitition')
//     // Initial State

//     sentinel = padBytes32(web3.toHex(0))
//     sequence = padBytes32(web3.toHex(3))

//     msg = sentinel + 
//               sequence.substr(2, sequence.length) + 
//               h.substr(2, h.length) +
//               e.substr(2, e.length) +
//               l.substr(2, l.length)

//     console.log('State_2: ' + msg)

//     hmsg = web3.sha3(msg, {encoding: 'hex'})
//     console.log('hashed msg: ' + hmsg)

//     sig1 = await web3.eth.sign(accounts[0], hmsg)
//     //console.log('State signature: ' + sig2)

//     console.log('{Simulated network send of player 1 State_2}')
//     console.log('{Player 2 validating State_2, and signing with agreement to checkpoint}\n')

//     sig2 = await web3.eth.sign(accounts[1], hmsg)

//     await cm.checkpointState(channelId, msg, sig1, sig2, sequence)
//     console.log('State checkpointed\n')


//     // State 4

//     console.log('Player 2 incorrectly assembling state_3 _help_')
//     // Initial State

//     sentinel = padBytes32(web3.toHex(0))
//     sequence = padBytes32(web3.toHex(4))

//     var p = padBytes32(web3.toHex('p'))

//     msg = sentinel + 
//               sequence.substr(2, sequence.length) + 
//               h.substr(2, h.length) +
//               e.substr(2, e.length) +
//               l.substr(2, l.length) +
//               p.substr(2, p.length)

//     console.log('State_3: ' + msg)

//     hmsg = web3.sha3(msg, {encoding: 'hex'})
//     console.log('hashed msg: ' + hmsg)

//     sig2 = await web3.eth.sign(accounts[1], hmsg)
//     //console.log('State signature: ' + sig2)

//     console.log('{Simulated network send of player 2 State_3}')
//     console.log('{Player 2 validating State_2, and catches an error localy}')
//     console.log('Closing channel with judge')

//     await cm.exerciseJudge(channelId, 'run(bytes)', sig2, msg)
//     open = await cm.getChannel(channelId)
//     console.log('Judge resolution: ' + open[8][2])

//     await cm.closeWithChallenge(channelId)
//     open = await cm.getChannel(channelId)
//     console.log('Channel status: ' + open[8][0])

//     // hello world game question: State grows in this game so if the word 
//     // was longer than "hello world" the judge would not be able to verify state
//     // general state channels still needs a clever judge like truebit or clever
//     // handling of the state representation. 
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