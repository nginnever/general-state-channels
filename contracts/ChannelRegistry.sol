// This contract acts as a multisig between channel participants. 
// Requirements
//   - store bond value in ether and tokens
//   - store counterfactual address of SPC
//   - point that address to the registry contract
//   - check sigantures on state of SPC
//   - check that byte code derives CTF address
//   - Be able to reconstruct final balances on SPC from state of SPC

pragma solidity ^0.4.18;

contract ChannelRegistry {
    mapping(bytes32 => address) registry;

    event ContractDeployed(address deployedAddress);

    function resolveAddress(bytes32 _CTFaddress) public view returns(address) {
        return registry[_CTFaddress];
    }

    function deployCTF(bytes _CTFbytes, bytes32 _CTFaddress) public {
        address deployedAddress;
        assembly {
            deployedAddress := create(0, add(_CTFbytes, 0x20), mload(_CTFbytes))
            // invalidJumLabel no longer compiles in solc v0.4.12 and higher
            //jumpi(invalidJumpLabel, iszero(extcodesize(deployedAddress)))
        }
        // todo: check that CTFaddress is derived correctly from 
        // all signatures of provided parties.
        
        registry[_CTFaddress] = deployedAddress;
        ContractDeployed(deployedAddress);
    }
}