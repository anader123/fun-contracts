pragma solidity ^0.8.10;

import {Test, console} from "forge-std/Test.sol";
import {Test721} from "../src/Test721.sol";
import {DutchAuction} from "../src/DutchAuction.sol";

contract DutchAuctionTest is Test {
    Test721 public nftContract;
    DutchAuction public dutchAuction;

    function setUp() public {
        vm.startPrank(address(123));
        dutchAuction = new DutchAuction();

        nftContract = new Test721();
        nftContract.mint();
        nftContract.approve(address(dutchAuction), 1);

        DutchAuction.Auction memory auction =
            DutchAuction.Auction(address(123), 1 ether, block.timestamp, block.timestamp + 1 days, 100);
        dutchAuction.createAuction(address(nftContract), 1, auction);

        vm.stopPrank();
    }

    function testBuyToken() public {
        vm.startPrank(address(321));
        deal(address(321), 1 ether);

        address sellerAddress = nftContract.ownerOf(1);
        assertEq(sellerAddress, address(123));

        dutchAuction.buy{value: 1 ether}(address(nftContract), 1);

        address buyerAddress = nftContract.ownerOf(1);
        assertEq(buyerAddress, address(321));

        vm.stopPrank();
    }
}
