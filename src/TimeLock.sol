// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";

contract TimeLock is Ownable {
    event Queue(bytes32 indexed txId, address indexed target, uint256 value, bytes data, uint256 timestamp);
    event Execute(bytes32 indexed txId, address indexed target, uint256 value, bytes data, uint256 timestamp);
    event Cancel(bytes32 indexed txId);

    uint256 MIN_DELAY = 7 days;
    uint256 MAX_DELAY = 14 days;

    mapping(bytes32 => bool) public queued;

    constructor() Ownable(msg.sender) {}

    receive() external payable {}

    function getTxId(address target, uint256 value, bytes calldata data, uint256 timestamp)
        public
        pure
        returns (bytes32 txId)
    {
        return keccak256(abi.encode(target, value, data, timestamp));
    }

    function queue(address target, uint256 value, bytes calldata data, uint256 timestamp) external onlyOwner {
        bytes32 txId = getTxId(target, value, data, timestamp);
        require(!queued[txId], "transaction already queued");

        require(
            timestamp > block.timestamp + MIN_DELAY && timestamp < block.timestamp + MAX_DELAY,
            "outside valid time range"
        );

        queued[txId] = true;

        emit Queue(txId, target, value, data, timestamp);
    }

    function execute(address target, uint256 value, bytes calldata data, uint256 timestamp)
        external
        payable
        onlyOwner
        returns (bytes memory)
    {
        bytes32 txId = getTxId(target, value, data, timestamp);

        require(queued[txId], "not queued");
        require(block.timestamp > timestamp, "time not passed");
        require(block.timestamp < timestamp + MAX_DELAY, "expired");

        queued[txId] = false;

        (bool success, bytes memory res) = target.call{value: value}(data);

        require(success, "tx failed");

        emit Execute(txId, target, value, data, timestamp);
        return res;
    }

    function cancel(bytes32 txId) external onlyOwner {
        require(queued[txId], "tx not queued");

        queued[txId] = false;
        emit Cancel(txId);
    }
}
