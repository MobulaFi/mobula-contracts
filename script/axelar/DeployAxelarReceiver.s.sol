// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./Base.s.sol";

import "src/axelar/AxelarReceiver.sol";

// Not relevant anymore, as the main contract is now the receiver

contract DeployAxelarReceiverBNB is Base {
    function setUp() public {}
    
    function run() external {
        vm.startBroadcast(deployerBNBPK);

        new AxelarReceiver(axelarBNBGateway);

        vm.stopBroadcast();
    }
}

contract DeployAxelarReceiverPolygon is Base {
    function setUp() public {}

    function run() external {
        vm.startBroadcast(deployerPolygonPK);

        new AxelarReceiver(axelarPolygonGateway);

        vm.stopBroadcast();
    }
}