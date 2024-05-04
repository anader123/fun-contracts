pragma solidity ^0.8.10;

import {Test, console} from "forge-std/Test.sol";
import {Escrow} from "../src/Escrow.sol";
import {Test20} from "../src/Test20.sol";
import {Test721} from "../src/Test721.sol";

contract TestScrow is Test {
    Escrow public escrow;
    Test20 public erc20Token;
    Test721 public erc721Token;

    uint256 INITIAL_PRICE = 1000;

    function setUp() public {
        escrow = new Escrow();
        erc20Token = new Test20();
        erc721Token = new Test721();

        erc721Token.mint();
        erc721Token.approve(address(escrow), 1);

        Escrow.Property memory property = Escrow.Property({
            descriptionURI: "ipfs://exampleuri",
            seller: address(this),
            purchaseToken: address(erc20Token),
            houseToken: address(erc721Token),
            houseTokenId: 1,
            price: INITIAL_PRICE,
            filled: false
        });

        escrow.createSale(property);
    }

    function testSaleCreated() public view {
        (, address seller,,,,,) = escrow.sales(0);
        assertEq(seller, address(this));
    }

    function testSaleUpdated() public {
        Escrow.Property memory updatedProperty = Escrow.Property({
            descriptionURI: "ipfs://updatedUri",
            seller: address(this),
            purchaseToken: address(erc20Token),
            houseToken: address(erc721Token),
            houseTokenId: 1,
            price: INITIAL_PRICE,
            filled: false
        });

        escrow.updateSale(0, updatedProperty);

        (string memory descriptionURI,,,,,,) = escrow.sales(0);
        assertEq(descriptionURI, "ipfs://updatedUri");
    }

    function testFillSale() public {
        vm.startPrank(address(123));

        erc20Token.mint(INITIAL_PRICE);
        erc20Token.approve(address(escrow), INITIAL_PRICE);

        escrow.fillSale(0);

        uint256 tokenBalance = erc20Token.balanceOf(address(this));
        assertEq(tokenBalance, INITIAL_PRICE);

        address nftOwner = erc721Token.ownerOf(1);
        assertEq(nftOwner, address(123));

        vm.stopPrank();
    }

    function testCancelSale() public {
        escrow.cancelSale(0);
        (, address seller,,,,,) = escrow.sales(0);

        assertEq(seller, address(0));
    }
}
