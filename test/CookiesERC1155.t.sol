pragma solidity ^0.8.10;

import {Test, console} from "forge-std/Test.sol";
import {CookiesERC1155} from "../src/CookiesERC1155.sol";

contract Test1155 is Test {
    CookiesERC1155 public cookiesERC1155;

    function setUp() public {
        cookiesERC1155 = new CookiesERC1155();

        CookiesERC1155.Token memory token = CookiesERC1155.Token({
            uri: "ipfs://exampleuri",
            price: 1 ether,
            startTime: (block.timestamp + 1 hours),
            endTime: (block.timestamp + 1 days),
            locked: false
        });

        cookiesERC1155.setTokenDetails(1, token);
    }

    function testCreateToken() public {
        CookiesERC1155.Token memory token = CookiesERC1155.Token({
            uri: "ipfs://exampleuri",
            price: 1 ether,
            startTime: (block.timestamp + 1 hours),
            endTime: (block.timestamp + 1 days),
            locked: false
        });

        cookiesERC1155.setTokenDetails(1, token);

        (string memory uri,,,,) = cookiesERC1155.tokenDetails(1);
        assertEq(uri, "ipfs://exampleuri");
    }

    function testMintToken() public {
        vm.warp(block.timestamp + 2 hours);
        vm.startPrank(address(123));
        vm.deal(address(123), 1 ether);

        cookiesERC1155.mint{value: 1 ether}(1, 1, address(123));

        uint256 tokenBal = cookiesERC1155.balanceOf(address(123), 1);
        assertEq(tokenBal, 1);
    }

    function testFailMintTokenNotCreated() public {
        vm.warp(block.timestamp + 2 hours);
        vm.startPrank(address(123));
        vm.deal(address(123), 1 ether);

        cookiesERC1155.mint{value: 1 ether}(2, 1, address(123));
    }

    function testFailMintNotOpen() public {
        vm.startPrank(address(123));
        vm.deal(address(123), 1 ether);

        cookiesERC1155.mint{value: 1 ether}(1, 1, address(123));
    }

    function testFailNonOwnerCreateToken() public {
        vm.startPrank(address(123));

        CookiesERC1155.Token memory token = CookiesERC1155.Token({
            uri: "ipfs://exampleuri2",
            price: 1000,
            startTime: block.timestamp + 1 hours,
            endTime: block.timestamp + 1 days,
            locked: false
        });

        cookiesERC1155.setTokenDetails(2, token);
    }
}
