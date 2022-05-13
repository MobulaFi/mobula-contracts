//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface Protocol {
    function rank(address member) external view returns (uint256 memberRank);
}

contract Vault {
    mapping(address => uint256) public lastClaim;
    mapping(address => uint256) public totalClaim;

    Protocol protocol;

    constructor(address _protocolAddress) {
        protocol = Protocol(_protocolAddress);
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
