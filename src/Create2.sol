// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Test721} from "./Test721.sol";

contract Create2Factory {
    event Deployed(address addr, uint256 salt);

    function getBytecode() public pure returns (bytes memory) {
        bytes memory bytecode = type(Test721).creationCode;
        return abi.encodePacked(bytecode);
    }

    function getAddress(bytes memory bytecode, uint256 salt) public view returns (address) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                salt,
                keccak256(bytecode)
            )
        );
        return address(uint160(uint256(hash)));
    }

    function deploy(bytes memory bytecode, uint256 salt) public payable {
        address addr;

        assembly {
            addr := create2(
                callvalue(),
                add(bytecode, 0x20),
                mload(bytecode),
                salt
            )

            if iszero(extcodesize(addr)) {
                revert(0,0)
            }
        }
        emit Deployed(addr, salt);
    }
}