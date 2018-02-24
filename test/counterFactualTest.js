'use strict'

const utils = require('./helpers/utils')
// const fs = require('fs')
// const solc = require('solc')

const BondManager = artifacts.require("./BondManager.sol")
const Registry = artifacts.require("./ChannelRegistry.sol")
const SPC = artifacts.require("./InterpretSpecialChannel.sol")

let bm
let reg
let spc
let sigV = []
let sigR = []
let sigS = []

let event_args

contract('counterfactual payment channel', function(accounts) {
  it("Payment Channel", async function() {
    reg = await Registry.new()
    // counterfactual code should be pulled from compiled code not from deployed, quick hack for now
    spc = await SPC.new(reg.address)

    var ctfcode = spc.constructor.bytecode

    console.log('SPC bytecode: ' + ctfcode)
    console.log('Begin signing and register ctf address...')

    // Hashing and signature
    var hmsg = web3.sha3(ctfcode, {encoding: 'hex'})
    console.log('hashed msg: ' + hmsg)

    var sig1 = await web3.eth.sign(accounts[0], hmsg)
    var r = sig1.substr(0,66)
    var s = "0x" + sig1.substr(66,64)
    //var v = parseInt(sig1.substr(130, 2)) + 27
    var v = "0x" + sig1.substr(130,2)

    console.log('party 1 signature of CTF bytecode: '+sig1)

    var sig2 = await web3.eth.sign(accounts[1], hmsg)
    var r2 = sig2.substr(0,66)
    var s2 = "0x" + sig2.substr(66,64)
    //var v2 = parseInt(sig2.substr(130, 2)) + 27
    var v2 = "0x" + sig2.substr(130,2)

    var sig3 = await web3.eth.sign(accounts[2], hmsg)
    var r3 = sig2.substr(0,66)
    var s3 = "0x" + sig3.substr(66,64)
    //var v3 = parseInt(sig3.substr(130, 2)) + 27
    var v3 = "0x" + sig3.substr(130,2)

    sigV = []
    sigR = []
    sigS = []

    sigV.push(v)
    sigV.push(v2)
    sigV.push(v3)
    sigR.push(r)
    sigR.push(r2)
    sigR.push(r3)
    sigS.push(s)
    sigS.push(s2)
    sigS.push(s3)

    console.log('party 2 signature of CTF bytecode: '+sig2)
    console.log('party 3 signature of CTF bytecode: '+sig3)

    // construct an identifier for the counterfactual address
    //var CTFaddress = '0x' + sig1.substr(2, 2) + sig2.substr(2,2)
    var sigs = sig1+sig2.substr(2, sig2.length)+sig3.substr(2, sig3.length)
    var CTFaddress = web3.sha3(sigs, {encoding: 'hex'})
    console.log('counterfactual address: ' + CTFaddress)

    //bm = await BondManager.new(0, CTFaddress, reg.address)

    await reg.deployCTF(ctfcode, sigs)

    let deployAddress = await reg.resolveAddress(CTFaddress)

    console.log('counterfactual contract deployed and mapped by registry: ' + deployAddress)
    let ctfaddy = await reg.ctfaddy()
    console.log('contract hashed ctf addres: ' + ctfaddy)

    // let newBm = BondManager.at(deployAddress)
    // let testBm = await newBm.test()
    // console.log('Test should be 420: ' + testBm)


  })

})

function generateState(sentinel, seq, addyA, addyB, balA, balB) {
    var sentinel = padBytes32(web3.toHex(sentinel))
    var sequence = padBytes32(web3.toHex(seq))
    var addressA = padBytes32(addyA)
    var addressB = padBytes32(addyB)
    var balanceA = padBytes32(web3.toHex(web3.toWei(balA, 'ether')))
    var balanceB = padBytes32(web3.toHex(web3.toWei(balB, 'ether')))

    var m = sentinel +
        sequence.substr(2, sequence.length) +
        addressA.substr(2, addressA.length) +
        addressB.substr(2, addressB.length) +
        balanceA.substr(2, balanceA.length) + 
        balanceB.substr(2, balanceB.length)

    return m
}

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

