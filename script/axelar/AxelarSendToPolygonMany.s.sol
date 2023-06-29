// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./Base.s.sol";

import "src/axelar/AxelarSender.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AxelarSendToMany is Base {
    function setUp() public {}

    function run() external {
        vm.startBroadcast(deployerArbitrumPK);

        address axelarSender = 0x87698686340931A6c01294B042c6a8D9f1696196;
        address arbToken = 0x912CE59144191C1204E64559FE8253a0e49E6548;
        uint256 amountGas = 1e16;

        string memory destinationChain = "Polygon";
        string memory destinationAddress = "0x11D70b2aee11364f55d923da35ca984F152bD84c";
        address[] memory destinationAddresses = new address[](2);
        destinationAddresses[0] = dada;
        destinationAddresses[1] = coco;
        string memory symbol = "ARB"; // ARB
        uint256 amount = 12345;
        
        IERC20(arbToken).approve(axelarSender, amount);

        // AxelarSender(axelarSender).sendToMany{value: amountGas}(destinationChain, destinationAddress, destinationAddresses, symbol, amount);

        vm.stopBroadcast();
    }
}