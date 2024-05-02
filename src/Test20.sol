pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Test20 is ERC20 {
    constructor() ERC20("Test", "TST") {}

    function mint(uint amount) public {
        _mint(msg.sender, amount);
    }
}
