pragma solidity ^0.4.18;

import "./JudgeInterface.sol";

contract JudgeHelloWorld is JudgeInterface {

    bytes32 public newState;
    bytes1 public temp;
    bytes1 public t;

    bytes1 h = 0x68;
    bytes1 e = 0x65;
    bytes1 l = 0x6c;
    bytes1 l2 = 0x6c;
    bytes1 o = 0xf0;

    bytes constant word_table = "\x68\x65\x6c\x6c\xf0";

    // We encode the data with the first 0 bytes represented the seperation between
    // state generated and the letter added to the word to get this new state (trivial)
    // The next 0 byte seperates the challengers local view of the state
    // This will apply the state update that has been signed by the accused
    // to the challengers local state. If the outcome is not part of the word, then 
    // the challenge was successful.

    function run(bytes32 _data) public returns (bool) {
      // get the signed new state and transition action
      newState = _data;

      // apply the action to the supplied challenger state

      // check that the outcome of state transition on challenger state
      // with accused state update is equal to the signed state by the violator
      bytes1 _temp;
      t = _data[1];

      //bytes1[] word;

      // for (uint i=0; i<_data.length; i++){

      //   word.push(_data[i]);
      // }

      //require(1 == 2);
      return false;
    }

}