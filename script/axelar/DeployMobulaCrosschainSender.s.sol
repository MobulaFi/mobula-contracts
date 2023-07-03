// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./Base.s.sol";

import "src/MobulaCrosschainSender.sol";

contract DeployMobulaCrosschainSenderArbitrum is Base {
    function setUp() public {}

    function run() external {
        vm.startBroadcast(deployerArbitrumPK);

        MobulaCrosschainSender sender = new MobulaCrosschainSender(axelarArbitrumGateway, axelarArbitrumGas);

        // TODO : Whitelist stablecoins on Arbitrum

        string memory destinationChain = "Polygon";
        sender.setDestination(destinationChain, toAsciiString(receiverContract));

        vm.stopBroadcast();
    }
}

contract DeployMobulaCrosschainSenderBNB is Base {
    function setUp() public {}

    function run() external {
        vm.startBroadcast(deployerBNBPK);

        MobulaCrosschainSender sender = new MobulaCrosschainSender(axelarBNBGateway, axelarBNBGas);

        // B-USDC
        sender.whitelistStable(BUSDC, true);

        string memory destinationChain = "Polygon";
        sender.setDestination(destinationChain, toAsciiString(receiverContract));

        vm.stopBroadcast();
    }
}

// Not relevant, as the main contract is already on Polygon
contract DeployMobulaCrosschainSenderPolygon is Base {
    function setUp() public {}

    function run() external {
        vm.startBroadcast(deployerPolygonPK);

        MobulaCrosschainSender sender = new MobulaCrosschainSender(axelarPolygonGateway, axelarPolygonGas);

        string memory destinationChain = "Polygon";
        sender.setDestination(destinationChain, toAsciiString(receiverContract));

        vm.stopBroadcast();
    }
}