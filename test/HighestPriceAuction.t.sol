pragma solidity ^0.8.10;

import {Test, console} from "forge-std/Test.sol";
import {Test721} from "../src/Test721.sol";
import {HighestPriceAuction} from "../src/HighestPriceAuction.sol";

contract HighestPriceAuctionTest is Test {
    Test721 public nftContract;
    HighestPriceAuction public highestPriceAuction;

    function setUp() public {
        vm.startPrank(address(123));
        highestPriceAuction = new HighestPriceAuction();
        nftContract = new Test721();
        nftContract.mint();
        nftContract.approve(address(highestPriceAuction), 1);

        highestPriceAuction.createAuction(address(nftContract), 1, uint32(block.timestamp + 1 days));
        highestPriceAuction.start(0);

        vm.stopPrank();
    }

    function testCreateAuction() public {
        vm.startPrank(address(777));
        nftContract.mint();

        highestPriceAuction.createAuction(address(nftContract), 2, uint32(block.timestamp + 1 days));
        (address seller,,,,,,,) = highestPriceAuction.auctions(1);

        assertEq(seller, address(777));
        vm.stopPrank();
    }

    function testStart() public view {
        address nftOwner = nftContract.ownerOf(1);
        assertEq(nftOwner, address(highestPriceAuction));
    }

    function testBid() public {
        (,,,,,, address highestBidder1,) = highestPriceAuction.auctions(0);
        assertEq(highestBidder1, address(0));

        hoax(address(321), 1 ether);
        highestPriceAuction.bid{value: 1 ether}(0);
        (,,,,,, address highestBidder2,) = highestPriceAuction.auctions(0);

        assertEq(highestBidder2, address(321));
    }

    function testEndWithBid() public {
        hoax(address(321), 1 ether);
        highestPriceAuction.bid{value: 1 ether}(0);

        uint256 beforeSale = address(123).balance;

        vm.warp(block.timestamp + 2 days);
        highestPriceAuction.end(0);
        address newOwner = nftContract.ownerOf(1);
        assertEq(newOwner, address(321));

        uint256 afterSale = address(123).balance;
        assertEq(beforeSale + 1 ether, afterSale);
    }

    function testEndWithOutBid() public {
        vm.warp(block.timestamp + 2 days);
        highestPriceAuction.end(0);

        address newOwner = nftContract.ownerOf(1);
        assertEq(newOwner, address(123));
    }
}
