// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract DutchAuction {
    uint256 private constant DURATION = 7 days;

    IERC721 public immutable nft;
    uint256 public immutable tokenId;

    address public immutable seller;
    uint256 public immutable startingPrice;
    uint256 public immutable startAt;
    uint256 public immutable endAt;
    uint256 public immutable discountRate;

    constructor(uint256 _startingPrice, uint256 _discountRate, address _nft, uint256 _tokenId) {
        seller = payable(msg.sender);
        startingPrice = _startingPrice;
        discountRate = _discountRate;
        startAt = block.timestamp;
        endAt = block.timestamp + DURATION;

        require(_startingPrice >= _discountRate * DURATION, "starting price < discount");
        nft = IERC721(_nft);
        tokenId = _tokenId;
    }

    function getPrice() public view returns (uint256) {
        uint256 timeElapsed = block.timestamp - startAt;
        uint256 discount = discountRate * timeElapsed;
        return startingPrice - discount;
    }

    function buy() external payable {
        require(block.timestamp < endAt, "aunction expired");

        uint256 price = getPrice();
        require(msg.value >= price, "ETH < price");

        nft.transferFrom(seller, msg.sender, tokenId);
        uint256 refund = msg.value - price;

        if (refund > 0) {
            payable(msg.sender).transfer(refund);
        }
    }
}
