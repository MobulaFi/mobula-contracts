// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./Base.s.sol";

import "src/axelar/AxelarSender.sol";

contract DeployAxelarSender is Base {
    function setUp() public {}

    function run() external {
        vm.startBroadcast(deployerBNBPK);

        new AxelarSender(axelarBNBGateway, axelarBNBGas);

        vm.stopBroadcast();
    }

    // function run() external {
    //     vm.startBroadcast(deployerArbitrumPK);

    //     new AxelarSender(axelarArbitrumGateway, axelarArbitrumGas);

    //     vm.stopBroadcast();
    // }
}