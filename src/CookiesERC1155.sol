pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @notice Token URI called for NonexistentToken
error URIQueryForNonexistentToken();

error TokenSaleNotOpen();

error NotEnoughValue();

error TokenLocked();

contract CookiesERC1155 is ERC1155, Ownable {

    struct Token {
        string uri;
        uint256 price;
        uint256 startTime;
        uint256 endTime;
        bool locked;
    }

    mapping(uint256 => Token) private tokenDetails;

    function mint(uint256 tokenId, uint256 quantity, address recipient) external payable {
        if(msg.value < tokenDetails[tokenId].price * quantity) {
            revert NotEnoughValue();
        }

        if(tokenDetails[tokenId].startTime < block.timestamp || tokenDetails[tokenId].endTime > block.timestamp) {
            revert TokenSaleNotOpen();
        }

        if(tokenDetails[tokenId].locked) {
            revert TokenLocked();
        }

        _mint(recipient, tokenId, quantity, "");
    } 

    function uri(uint256 tokenId) override public view returns (string memory) { 
        string memory tokenURI = tokenDetails[tokenId].uri;
        if(bytes(tokenURI).length == 0) {
            revert URIQueryForNonexistentToken();
        }
        return(tokenURI);
    }

    function setTokenDetails(uint256 tokenId, TokenDetails memory tokenDetails) external onlyOwner { 
        tokenDetails[tokenId] = tokenDetails;
    }
}