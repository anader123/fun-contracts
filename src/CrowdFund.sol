// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CrowdFund {
    event Launch(
        uint256 id, address indexed creator, address indexed token, uint256 goal, uint32 startAt, uint32 endAt
    );
    event Cancel(uint256 id);
    event Pledge(uint256 id, address indexed caller, uint256 amount);
    event Unpledge(uint256 id, address indexed caller, uint256 amount);
    event Claim(uint256 id);
    event Refund(uint256 id, address indexed caller, uint256 amount);

    struct Campaign {
        address creator;
        address token;
        uint256 goal;
        uint256 pledged;
        uint32 startAt;
        uint32 endAt;
        bool claimed;
    }

    uint256 public count;

    mapping(uint256 => Campaign) public campaigns;
    mapping(uint256 => mapping(address => uint256)) public pledgedAmount;

    function launch(address token, uint256 goal, uint32 startAt, uint32 endAt) external {
        require(startAt >= block.timestamp, "start at < now");
        require(endAt >= startAt, "end at < start at");
        require(endAt <= block.timestamp + 90 days, "end at > max duration");

        count += 1;
        campaigns[count] = Campaign({
            creator: msg.sender,
            token: token,
            goal: goal,
            pledged: 0,
            startAt: startAt,
            endAt: endAt,
            claimed: false
        });

        emit Launch(count, msg.sender, token, goal, startAt, endAt);
    }

    function cancel(uint256 id) external {
        Campaign memory campaign = campaigns[id];
        require(msg.sender == campaign.creator, "not creator");
        require(block.timestamp < campaign.startAt, "started");

        delete campaigns[id];
        emit Cancel(id);
    }

    function pledge(uint256 id, uint256 amount) external {
        Campaign storage campaign = campaigns[id];
        require(block.timestamp >= campaign.startAt, "not started");
        require(block.timestamp <= campaign.endAt, "ended");

        campaign.pledged += amount;
        pledgedAmount[id][msg.sender] += amount;

        IERC20 token = IERC20(campaign.token);
        token.transferFrom(msg.sender, address(this), amount);

        emit Pledge(id, msg.sender, amount);
    }

    function unpledge(uint256 id, uint256 amount) external {
        Campaign storage campaign = campaigns[id];
        require(block.timestamp <= campaign.endAt, "ended");
        require(campaign.pledged >= amount, "invalid amount");

        campaign.pledged -= amount;
        pledgedAmount[id][msg.sender] -= amount;

        IERC20 token = IERC20(campaign.token);
        token.transfer(msg.sender, amount);

        emit Unpledge(id, msg.sender, amount);
    }

    function claim(uint256 id) external {
        Campaign storage campaign = campaigns[id];
        require(msg.sender == campaign.creator, "not created");
        require(campaign.endAt < block.timestamp, "not ended");
        require(campaign.pledged >= campaign.goal, "pledged < goal");
        require(!campaign.claimed, "claimed");

        campaign.claimed = true;
        IERC20 token = IERC20(campaign.token);
        token.transfer(msg.sender, campaign.pledged);

        emit Claim(id);
    }

    function refund(uint256 id) external {
        Campaign storage campaign = campaigns[id];
        require(campaign.endAt > block.timestamp, "not ended");
        require(campaign.pledged < campaign.goal, "pledged > goal");

        uint256 bal = pledgedAmount[id][msg.sender];
        pledgedAmount[id][msg.sender] = 0;

        IERC20 token = IERC20(campaign.token);
        token.transfer(msg.sender, bal);

        emit Refund(id, msg.sender, bal);
    }
}
