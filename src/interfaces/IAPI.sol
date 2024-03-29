// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../lib/TokenStructs.sol";

interface IAPI {
    function addAssetData(Token memory token) external;

    function addStaticData(address token, string memory hashString) external;

    function staticData(address token)
        external
        view
        returns (string memory hashString);
}