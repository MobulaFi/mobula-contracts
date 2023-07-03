// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./Base.s.sol";

import "src/API.sol";

contract DeployProtocolAPI is Base {
    function setUp() public {}

    function run() external {
        vm.startBroadcast(deployerPolygonPK);

        new API(tokensProtocolAddress, deployerPolygon);

        vm.stopBroadcast();
    }
}