// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract HighestPriceAuction {
    event Created(uint256 indexed auctionId, address nftAddress, uint256 tokenId);
    event Start(uint256 indexed auctionId);
    event Bid(uint256 indexed auctionId, address sender, uint256 amount);
    event End(uint256 indexed auctionId, address highestBidder, uint256 amount);

    uint256 private _auctionId;

    struct Auction {
        address seller;
        address nftAddress;
        uint256 tokenId;
        uint32 endAt;
        bool started;
        bool ended;
        address highestBidder;
        uint256 highestBid;
    }

    mapping(uint256 => Auction) public auctions;

    function createAuction(address nftAddress, uint256 tokenId, uint32 endAt) public {
        uint256 currentAuctionId = _auctionId;
        auctions[currentAuctionId] = Auction({
            seller: msg.sender,
            nftAddress: nftAddress,
            tokenId: tokenId,
            endAt: endAt,
            started: false,
            ended: false,
            highestBidder: address(0),
            highestBid: 0
        });

        _auctionId++;
        emit Created(currentAuctionId, nftAddress, tokenId);
    }

    function start(uint256 auctionId, uint256 duration) external {
        Auction storage auction = auctions[auctionId];

        require(msg.sender == auction.seller, "not seller");
        require(!auction.started, "started");

        auction.started = true;
        auction.endAt = uint32(block.timestamp + duration);

        IERC721 nft = IERC721(auction.nftAddress);
        nft.transferFrom(auction.seller, address(this), auction.tokenId);

        emit Start(auctionId);
    }

    function bid(uint256 auctionId) external payable {
        Auction storage auction = auctions[auctionId];

        require(auction.started, "not started");
        require(block.timestamp < auction.endAt, "ended");
        require(msg.value > auction.highestBid, "value < highest bid");

        payable(auction.highestBidder).transfer(auction.highestBid);

        auction.highestBidder = msg.sender;
        auction.highestBid = msg.value;

        emit Bid(auctionId, msg.sender, msg.value);
    }

    function end(uint256 auctionId) external {
        Auction storage auction = auctions[auctionId];
        
        require(auction.started, "not started");
        require(!auction.ended, "ended");
        require(block.timestamp >= auction.endAt, "not ended");

        auction.ended = true;
        IERC721 nft = IERC721(auction.nftAddress);

        if (auction.highestBidder != address(0)) {
            nft.transferFrom(address(this), auction.highestBidder, auction.tokenId);
            payable(auction.seller).transfer(auction.highestBid);
        } else {
            nft.transferFrom(address(this), auction.seller, auction.tokenId);
        }

        emit End(auctionId, auction.highestBidder, auction.highestBid);
    }
}
