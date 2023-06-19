// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./interfaces/IProtocol.sol";

contract Vault {
    mapping(address => uint256) public lastClaim;
    mapping(address => uint256) public totalClaim;

    IProtocol protocol;

    constructor(address _protocolAddress) {
        protocol = IProtocol(_protocolAddress);
    }

    receive() external payable {}

    function claim() external {
        require(
            lastClaim[msg.sender] + 7 * 24 * 60 * 60 < block.timestamp,
            "You can't claim twice a week."
        );
        require(
            protocol.rank(msg.sender) > 0,
            "You must be part of the DAO to claim MATIC;"
        );

        lastClaim[msg.sender] = block.timestamp;
        payable(msg.sender).transfer(1 ether);
    }
}
