// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @notice Token URI called for NonexistentToken
error URIQueryForNonexistentToken();

/// @notice Sale is not open for a given tokens
error TokenSaleNotOpen();

/// @notice Not enough value included in the transaction
error NotEnoughValue();

/// @notice Token has been locked and can't be minted again
error TokenIsLocked();

/// @notice Batch Minting args don't match up
error InvalidBatchMintingArgs();

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

    function isMintable(uint256 tokenId, uint256 quantity) internal view returns (bool) {
        if (msg.value < tokenDetails[tokenId].price * quantity) {
            revert NotEnoughValue();
        }

        if (tokenDetails[tokenId].startTime < block.timestamp || tokenDetails[tokenId].endTime > block.timestamp) {
            revert TokenSaleNotOpen();
        }

        if (tokenDetails[tokenId].locked) {
            revert TokenIsLocked();
        }

        return true;
    }

    function mint(uint256 tokenId, uint256 quantity, address recipient) external payable {
        if (isMintable(tokenId, quantity)) {
            _mint(recipient, tokenId, quantity, "");
        }
    }

    function batchMint(address recipient, uint256[] calldata ids, uint256[] calldata quantities) external payable {
        if (ids.length != quantities.length) {
            revert InvalidBatchMintingArgs();
        }

        for (uint256 i = 0; i < ids.length; i++) {
            isMintable(ids[i], quantities[i]);
        }

        _mintBatch(recipient, ids, quantities, "");
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
