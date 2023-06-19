// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IProtocol {
    function rank(address member) external view returns (uint256 memberRank);
}