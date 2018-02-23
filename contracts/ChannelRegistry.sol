pragma solidity ^0.4.18;

contract ChannelRegistry {
    mapping(bytes32 => address) registry;
    bytes32 public ctfaddy;

    event ContractDeployed(address deployedAddress);

    function resolveAddress(bytes32 _CTFaddress) public view returns(address) {
        return registry[_CTFaddress];
    }

    function deployCTF(bytes _CTFbytes, bytes _sigs) public {
        address deployedAddress;
        assembly {
            deployedAddress := create(0, add(_CTFbytes, 0x20), mload(_CTFbytes))
            // invalidJumLabel no longer compiles in solc v0.4.12 and higher
            //jumpi(invalidJumpLabel, iszero(extcodesize(deployedAddress)))
        }
        // todo: check that CTFaddress is derived correctly from 
        // all signatures of provided parties.
        // check that all signatures are present
        //bytes sigs = _concat(_v, _r, _s);


        bytes32 _CTFaddress = keccak256(_sigs);

        // for(uint i=2; i<_s.length; i++) {
        //     _CTFaddress = keccak256(_CTFaddress, _r[i], _s[i], _v[i]);
        // }

        ctfaddy = _CTFaddress;

        registry[_CTFaddress] = deployedAddress;
        ContractDeployed(deployedAddress);
    }
}