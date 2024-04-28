// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract DutchAuction {
    event AuctionCreated(address indexed nftAddress, uint256 indexed tokenId, uint256 indexed endAt);
    event TokenPurchased(address indexed nftAddress, uint256 indexed tokenId, uint256 indexed price);

    struct Auction {
        address seller;
        uint256 startingPrice;
        uint256 startAt;
        uint256 endAt;
        uint256 discountRate;
    }

    mapping(address => mapping(uint256 => Auction)) public auctions;

    function getPrice(address nftAddress, uint256 tokenId) public view returns (uint256) {
        Auction memory auction = auctions[nftAddress][tokenId];
        uint256 timeElapsed = block.timestamp - auction.startAt;
        uint256 discount = auction.discountRate * timeElapsed;
        return auction.startingPrice - discount;
    }

    function createAuction(address nftAddress, uint256 tokenId, Auction memory auction) external {
        require(auctions[nftAddress][tokenId].seller == address(0), "auction created");
        require(msg.sender == auction.seller, "seller must call the function");
        require(auction.endAt > auction.startAt, "invalid start time");
        require(auction.endAt > block.timestamp, "invalid end time");

        auctions[nftAddress][tokenId] = auction;
        emit AuctionCreated(nftAddress, tokenId, auction.endAt);
    }

    function buy(address nftAddress, uint256 tokenId) external payable {
        Auction memory auction = auctions[nftAddress][tokenId];

        require(block.timestamp < auction.endAt, "aunction expired");

        uint256 price = getPrice(nftAddress, tokenId);
        require(msg.value >= price, "ETH < price");

        IERC721 nft = IERC721(nftAddress);
        nft.transferFrom(auction.seller, msg.sender, tokenId);
        uint256 refund = msg.value - price;

        if (refund > 0) {
            payable(msg.sender).transfer(refund);
        }

        delete auctions[nftAddress][tokenId];

        emit TokenPurchased(nftAddress, tokenId, price);
    }
}
