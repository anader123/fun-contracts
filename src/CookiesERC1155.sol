// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @notice Token URI called for NonexistentToken
error URIQueryForNonexistentToken();

error TokenSaleNotOpen();

error NotEnoughValue();

error TokenIsLocked();

contract CookiesERC1155 is ERC1155, Ownable {
    event TokenDetailsUpdated(
        uint256 indexed tokenId, uint256 indexed startTime, uint256 indexed endTime, string uri, uint256 price
    );
    event TokenLocked(uint256 tokenId);

    struct Token {
        string uri;
        uint256 price;
        uint256 startTime;
        uint256 endTime;
        bool locked;
    }

    mapping(uint256 => Token) private tokenDetails;

    constructor() ERC1155("") Ownable(msg.sender) {}

    function mint(uint256 tokenId, uint256 quantity, address recipient) external payable {
        if (msg.value < tokenDetails[tokenId].price * quantity) {
            revert NotEnoughValue();
        }

        if (tokenDetails[tokenId].startTime < block.timestamp || tokenDetails[tokenId].endTime > block.timestamp) {
            revert TokenSaleNotOpen();
        }

        if (tokenDetails[tokenId].locked) {
            revert TokenIsLocked();
        }

        _mint(recipient, tokenId, quantity, "");
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        string memory tokenURI = tokenDetails[tokenId].uri;
        if (bytes(tokenURI).length == 0) {
            revert URIQueryForNonexistentToken();
        }
        return (tokenURI);
    }

    function setTokenDetails(uint256 tokenId, Token memory token) external onlyOwner {
        tokenDetails[tokenId] = token;
        if (token.locked) {
            emit TokenLocked(tokenId);
        } else {
            emit TokenDetailsUpdated(tokenId, token.startTime, token.endTime, token.uri, token.price);
        }
    }
}
