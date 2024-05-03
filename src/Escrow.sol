// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Escrow {
    event SaleCreated(address indexed seller, address houseToken, uint256 houseTokenId, uint256 price, uint256 saleId);
    event SaleUpdated(address indexed seller, address houseToken, uint256 houseTokenId, uint256 price, uint256 saleId);
    event SaleFilled(
        address indexed seller, address buyer, address houseToken, uint256 houseTokenId, uint256 price, uint256 saleId
    );
    event SaleCanceled(uint indexed saleId);

    uint256 public counterId;

    struct Property {
        string descriptionURI;
        address seller;
        address purchaseToken;
        address houseToken;
        uint256 houseTokenId;
        uint256 price;
        bool filled;
    }

    mapping(uint256 => Property) public sales;

    function createSale(Property memory property) external {
        require(msg.sender == property.seller, "invalid seller");

        sales[counterId] = property;
        counterId++;

        emit SaleCreated(property.seller, property.houseToken, property.houseTokenId, property.price, counterId - 1);
    }

    function updateSale(uint256 saleId, Property memory property) external {
        Property memory currentProperty = sales[saleId];
        require(msg.sender == currentProperty.seller, "not the seller");
        require(msg.sender == property.seller, "invalid seller set");

        emit SaleUpdated(property.seller, property.houseToken, property.houseTokenId, property.price, saleId);
    }

    function fillSale(uint256 saleId) external {
        Property storage property = sales[saleId];

        IERC20 purchaseToken = IERC20(property.purchaseToken);
        purchaseToken.transferFrom(msg.sender, property.seller, property.price);

        IERC721 houseToken = IERC721(property.houseToken);
        houseToken.transferFrom(property.seller, msg.sender, property.houseTokenId);

        property.filled = true;

        emit SaleFilled(property.seller, msg.sender, property.houseToken, property.houseTokenId, property.price, saleId);
    }

    function cancelSale(uint256 saleId) external {
        Property storage property = sales[saleId];
        require(msg.sender == property.seller, "invalid seller");

        delete sales[saleId];

        emit SaleCanceled(saleId);
    }
}
