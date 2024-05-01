pragma solidity ^0.8.10;

import {Test, console} from "forge-std/Test.sol";
import {Create2Factory} from "../src/Create2.sol";
import {Test721} from "../src/Test721.sol";


contract TestCreate2 is Test {
    Create2Factory public create2Factory;
    Test721 public nftContract;

    bytes public bytecode;
    uint256 public salt;
    address public expectedAddress = 0x69B548094317B2FCd930B61b0C04a3C1484FC619;

    function setUp() public {
        create2Factory = new Create2Factory();

        bytecode = create2Factory.getBytecode();
    }

    function testGetAddress() public view {
        address calcedAddress = create2Factory.getAddress(bytecode, salt);
        assertEq(calcedAddress, expectedAddress);
    }

    function testDeploy() public {
        create2Factory.deploy(bytecode, salt);
        nftContract = Test721(expectedAddress);

        nftContract.mint();
        address owner = nftContract.ownerOf(1);
        assertEq(owner, address(this));
    }
}