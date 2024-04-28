pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract Test721 is ERC721 {
    uint256 private _nextTokenId = 1;
    constructor() ERC721("Test", "TST") {}

    function mint() public {
        uint256 tokenId = _nextTokenId++;
        _mint(msg.sender, tokenId);
    }
}