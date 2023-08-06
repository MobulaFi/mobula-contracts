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

        // MobulaCrosschainSender sender = new MobulaCrosschainSender(axelarBNBGateway, axelarBNBGas);

       

        // B-USDC
        // sender.whitelistStable(BUSDC, true);

        string memory destinationChain = "Polygon";
         MobulaCrosschainSender(0xBD0ac880252Ef89dEf4Bfdb01208df59C54B1817).whitelistStable(0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d, true);

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