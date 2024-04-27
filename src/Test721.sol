pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract Test721 is ERC721 {
    constructor() ERC721("Test", "TST") {}

    function mint() public {
        _mint(msg.sender, 1);
    }
}