// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IAPI {
    struct Token {
        string ipfsHash;
        address[] contractAddresses;
        uint256 id;
        address[] totalSupply;
        address[] excludedFromCirculation;
        uint256 lastUpdate;
        uint256 utilityScore;
        uint256 socialScore;
        uint256 trustScore;
    }

    function addAssetData(Token memory token) external;

    function addStaticData(address token, string memory hashString) external;

    function staticData(address token)
        external
        view
        returns (string memory hashString);
}