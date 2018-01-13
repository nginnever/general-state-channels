pragma solidity ^0.4.18;

contract JudgeInterface {
    bool public judge = true;
    /// @dev simply a boolean to indicate this is the contract we expect to be
    function isJudge() public view returns (bool){
      return judge;
    }

}