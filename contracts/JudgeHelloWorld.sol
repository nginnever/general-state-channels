pragma solidity ^0.4.18;

import "./JudgeInterface.sol";

contract JudgeHelloWorld is JudgeInterface {

    bytes32 public newState;
    bytes32 public temp;
    uint public s;

    bytes32 h = 0x68;
    bytes32 e = 0x65;
    bytes32 l = 0x6c;
    bytes32 o = 0x6f;

    bytes constant word_table = "\x68\x65\x6c\x6c\xf0";

    // We encode the data with the first 0 bytes represented the seperation between
    // state generated and the letter added to the word to get this new state (trivial)
    // The next 0 byte seperates the challengers local view of the state
    // This will apply the state update that has been signed by the accused
    // to the challengers local state. If the outcome is not part of the word, then 
    // the challenge was successful.

    function run(bytes _data) public {
      // get the signed new state and transition action

      // apply the action to the supplied challenger state

      // check that the outcome of state transition on challenger state
      // with accused state update is equal to the signed state by the violator

      // [0:8] sequence number (in this case building the word could check for longest valid state for seq check)
      uint sequence;

      assembly {
          sequence := mload(add(_data, 32))
      }

      s = sequence;

      bytes32 _h;
      bytes32 _e;
      bytes32 _l;
      bytes32 _l2;
      bytes32 _o;

      (_h, _e, _l, _l2, _o) = decodeState(_data);

      temp = _l;

      require(_h == h || _h == 0x0);
      require(_e == e || _e == 0x0);
      require(_l == l || _l == 0x0);
      require(_l2 == l || _l2 == 0x0);
      require(_o == o || _o == 0x0);
    }

    function decodeState(bytes state) pure internal returns (bytes32 _h, bytes32 _e, bytes32 _l, bytes32 _l2, bytes32 _o) {
        assembly {
            _h := mload(add(state, 96))
            _e := mload(add(state, 128))
            _l := mload(add(state, 160))
            _l2 := mload(add(state, 192))
            _o := mload(add(state, 224))
        }
    }

}