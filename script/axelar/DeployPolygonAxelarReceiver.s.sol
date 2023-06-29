// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./Base.s.sol";

import "src/axelar/AxelarReceiver.sol";

contract DeployAxelarReceiver is Base {
    function setUp() public {}

    function run() external {
        vm.startBroadcast(deployerPolygonPK);

        new AxelarReceiver(axelarPolygonGateway);

        vm.stopBroadcast();
    }
}