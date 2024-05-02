pragma solidity ^0.8.10;

import {Test, console} from "forge-std/Test.sol";
import {CrowdFund} from "../src/CrowdFund.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {Test20} from "../src/Test20.sol";

contract CrowdFundTest is Test {
    CrowdFund public crowdFund;
    Test20 public erc20Token;

    uint INITIAL_ID = 1;
    uint INTIAL_GOAL = 1000;
    uint INITIAL_PLEDGE = 500;

    function setUp() public {
        crowdFund = new CrowdFund();
        erc20Token = new Test20();
        crowdFund.launch(address(erc20Token), INTIAL_GOAL, uint32(block.timestamp + 1 hours), uint32(block.timestamp + 1 days));

        (address creator , , , , , ,) = crowdFund.campaigns(INITIAL_ID);
        assertEq(creator, address(this));
    }

    function testCancel() public {
        crowdFund.cancel(INITIAL_ID);
        (address creator , , , , , ,) = crowdFund.campaigns(INITIAL_ID);
        assertEq(creator, address(0));
    }

    function testPledge() public {
        vm.warp(block.timestamp + 2 hours);
        vm.startPrank(address(321));
        erc20Token.mint(INITIAL_PLEDGE);

        erc20Token.approve(address(crowdFund), INITIAL_PLEDGE);
        crowdFund.pledge(INITIAL_ID, INITIAL_PLEDGE);
        uint pledgeAmount = crowdFund.pledgedAmount(INITIAL_ID, address(321));

        assertEq(pledgeAmount, INITIAL_PLEDGE);
    }

    function testUnpledge() public {
        vm.warp(block.timestamp + 2 hours);
        vm.startPrank(address(321));
        erc20Token.mint(INITIAL_PLEDGE);

        erc20Token.approve(address(crowdFund), INITIAL_PLEDGE);
        crowdFund.pledge(INITIAL_ID, INITIAL_PLEDGE);

        crowdFund.unpledge(INITIAL_ID, INITIAL_PLEDGE);
        uint tokenBalance = erc20Token.balanceOf(address(321));
        uint pledgeAmount = crowdFund.pledgedAmount(INITIAL_ID, address(321));

        assertEq(pledgeAmount, 0);
        assertEq(tokenBalance, 500);
    }

    function testClaim() public {
        vm.warp(block.timestamp + 2 hours);
        erc20Token.mint(INTIAL_GOAL);

        erc20Token.approve(address(crowdFund), INTIAL_GOAL);
        crowdFund.pledge(INITIAL_ID, INTIAL_GOAL);

        uint pledgeAmount = crowdFund.pledgedAmount(INITIAL_ID, address(this));
        assertEq(pledgeAmount, INTIAL_GOAL);

        vm.warp(block.timestamp + 2 days);
        crowdFund.claim(INITIAL_ID);

        (, , , , , , bool claimed) = crowdFund.campaigns(INITIAL_ID);
        uint tokenBalance = erc20Token.balanceOf(address(this));

        assertEq(tokenBalance, INTIAL_GOAL);
        assertEq(claimed, true);
    }

    function testRefund() public {
        vm.warp(block.timestamp + 2 hours);
        vm.startPrank(address(321));
        erc20Token.mint(INITIAL_PLEDGE);

        erc20Token.approve(address(crowdFund), INITIAL_PLEDGE);
        crowdFund.pledge(INITIAL_ID, INITIAL_PLEDGE);

        crowdFund.refund(INITIAL_ID);
        uint tokenBalance = erc20Token.balanceOf(address(321));
        uint pledgeAmount = crowdFund.pledgedAmount(INITIAL_ID, address(321));

        assertEq(pledgeAmount, 0);
        assertEq(tokenBalance, 500);
    }

}
