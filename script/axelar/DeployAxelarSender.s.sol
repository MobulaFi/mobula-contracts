// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./Base.s.sol";

import "src/axelar/AxelarSender.sol";

contract DeployAxelarSenderArbitrum is Base {
    function setUp() public {}

    function run() external {
        vm.startBroadcast(deployerArbitrumPK);

        AxelarSender sender = new AxelarSender(axelarArbitrumGateway, axelarArbitrumGas);

        string memory destinationChain = "Polygon";
        sender.setDestination(destinationChain, toAsciiString(receiverContract));

        vm.stopBroadcast();
    }
}

contract DeployAxelarSenderBNB is Base {
    function setUp() public {}

    function run() external {
        vm.startBroadcast(deployerBNBPK);

        AxelarSender sender = new AxelarSender(axelarBNBGateway, axelarBNBGas);

        // B-USDC
        sender.whitelistStable(BUSDC, true);

        string memory destinationChain = "Polygon";
        sender.setDestination(destinationChain, toAsciiString(receiverContract));

        vm.stopBroadcast();
    }
}

contract DeployAxelarSenderPolygon is Base {
    function setUp() public {}

    function run() external {
        vm.startBroadcast(deployerPolygonPK);

        AxelarSender sender = new AxelarSender(axelarPolygonGateway, axelarPolygonGas);

        string memory destinationChain = "Polygon";
        sender.setDestination(destinationChain, toAsciiString(receiverContract));

        vm.stopBroadcast();
    }
}