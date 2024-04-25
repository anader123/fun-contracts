// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";


contract HighestPriceAuction {
    event Start();
    event Bid(address index sender, uint256 amount);
    event Withdraw(address indexed bidder, uint256 amount);
    event End(address highestBidder, uint256 amount);

    IERC721 public immutable nft;
    uint256 public immutable tokenId;

    address payable public immutable seller;
    uint32 public endAt;
    bool public started;
    uint256 public highestBidder;
    uint256 public highestBid;
    mapping(address => uint256) public bids;

    constructor(
        address _nft,
        uint256 _tokenId,
        uint256 _startingBid
    ) {
        nft = IERC721(_nft);
        tokenId = _tokenId;
        seller = payable(msg.sender);
        highestBid = _startingBid;
    }

    function start() external {
        require(msg.sender == seller, "not seller");
        require(!started, "started");

        started = true;
        endAt = uint32(block.timestamp + 7 days);
        nft.transferFrom(seller, address(this), tokenId);

        emit Start();
    }

    function bid() external payable {
        require(started, "not started");
        require(block.timestamp < endAt, "ended");
        require(msg.value > highestBid, "value < highest bid");

        highestBid = msg.value;
        highestBidder = msg.sender;
    }

    function withdraw() external {
        uint256 bal = bids[msg.sender];
        bids[msg.sender] = 0;
        payable(msg.sender).transafer(bal);

        emit Withdaw(msg.sender, bal);
    }

    function end() external {
        require(started, "not started");
        require(!ended, "ended");
        require(block.timestamp >= endAt, "not ended");
        
        ended = true;

        if(highestBidder != address(0)){
            nft.transferFrom(address(this), highestBidder, tokenId);
            seller.transfer(highestBid);
        } else {            
            nft.transferFrom(address(this), seller, tokenId);
        }
        
        emit End(highestBidder, highestBid);
    }
}