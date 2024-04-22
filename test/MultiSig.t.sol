pragma solidity ^0.8.10;

import {Test, console} from "forge-std/Test.sol";
import {MultiSig} from "../src/MultiSig.sol";

contract MultiSigTest is Test {
    MultiSig public multiSig;

    function setUp() public {
        address[] memory owners = new address[](3);
        owners[0] = address(1);
        owners[1] = address(2);
        owners[2] = address(3);
        multiSig = new MultiSig(owners, 2);
    }

    function test_RequiredApprovals() public view {
        assertEq(multiSig.requiredApprovals(), 2);
    }
}
