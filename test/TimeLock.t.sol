// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Test, console} from "forge-std/Test.sol";
import {Test721} from "../src/Test721.sol";
import {TimeLock} from "../src/TimeLock.sol";


contract TimeLockTest is Test {
    Test721 public nftContract;
    TimeLock public timeLock;

    uint256 public START_TIME;
    bytes MINT_DATA;

    function setUp() public {
        vm.startPrank(address(123));
        timeLock = new TimeLock();

        nftContract = new Test721();
        MINT_DATA = abi.encodeCall(Test721.mint, ());

        START_TIME = block.timestamp + 8 days;

        timeLock.queue(address(nftContract), 0, MINT_DATA, START_TIME);

        vm.stopPrank();
    }

    function testFailAlreadyQueued() public {
        vm.startPrank(address(123));
        timeLock.queue(address(nftContract), 0, MINT_DATA, START_TIME);
        vm.stopPrank();
    }

    function testFailNotOwnerQueue() public {
        vm.startPrank(address(321));
        timeLock.queue(address(nftContract), 0, MINT_DATA, START_TIME);
        vm.stopPrank();
    }

    function testExecute() public {
        vm.startPrank(address(123));

        vm.warp(block.timestamp + 9 days);
        timeLock.execute(address(nftContract), 0, MINT_DATA, START_TIME);

        address nftOwner = nftContract.ownerOf(1);
        assertEq(address(timeLock), nftOwner);
    }

    function testFailNotOwnerExecute() public {
        vm.startPrank(address(321));
        timeLock.execute(address(nftContract), 0, MINT_DATA, START_TIME);
        vm.stopPrank();
    }

    function testCancel() public {
        vm.startPrank(address(123));
        bytes32 txId = timeLock.getTxId(address(nftContract), 0, MINT_DATA, START_TIME);
        timeLock.cancel(txId);
        vm.stopPrank();
    }

    function testFailCancelNoExecute() public {
        vm.startPrank(address(123));
        
        bytes32 txId = timeLock.getTxId(address(nftContract), 0, MINT_DATA, START_TIME);
        timeLock.cancel(txId);
        timeLock.execute(address(nftContract), 0, MINT_DATA, START_TIME);

        vm.stopPrank();
    }

    function testFailNotOwnerCancel() public {
        vm.startPrank(address(321));
        bytes32 txId = timeLock.getTxId(address(nftContract), 0, MINT_DATA, START_TIME);
        timeLock.cancel(txId);
        vm.stopPrank();
    }

}