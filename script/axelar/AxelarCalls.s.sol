// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./Base.s.sol";

import "src/axelar/AxelarSender.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AxelarSubmitToken is Base {
    function setUp() public {}

    function run() external {
        vm.startBroadcast(deployerBNBPK);

        address axlUSDC = 0x4268B8F0B87b6Eae5d897996E6b845ddbD99Adf3;
        uint256 amountGas = 1e16;

        string memory destinationChain = "Polygon";
        string memory symbol = "axlUSDC";
        uint256 amount = 12345;
        
        IERC20(axlUSDC).approve(senderContract, amount);

        AxelarSender(senderContract).setDestination(destinationChain, toAsciiString(receiverContract));

        AxelarSender(senderContract).submitTokenAxelar{value: amountGas}("testIpfsHash", symbol, amount);

        vm.stopBroadcast();
    }
}

contract AxelarUpdateToken is Base {
    function setUp() public {}

    function run() external {
        vm.startBroadcast(deployerBNBPK);

        string memory destinationChain = "Polygon";
        uint256 amountGas = 1e16;

        AxelarSender(senderContract).setDestination(destinationChain, toAsciiString(receiverContract));

        AxelarSender(senderContract).updateTokenAxelar{value: amountGas}(1234, "testIpfsHash");

        vm.stopBroadcast();
    }
}

contract AxelarTopUpToken is Base {
    function setUp() public {}

    function run() external {
        vm.startBroadcast(deployerBNBPK);

        address axlUSDC = 0x4268B8F0B87b6Eae5d897996E6b845ddbD99Adf3;
        uint256 amountGas = 1e16;

        string memory destinationChain = "Polygon";
        string memory symbol = "axlUSDC";
        uint256 amount = 12345;
        
        IERC20(axlUSDC).approve(senderContract, amount);

        AxelarSender(senderContract).setDestination(destinationChain, toAsciiString(receiverContract));

        AxelarSender(senderContract).topUpTokenAxelar{value: amountGas}(1234, symbol, amount);

        vm.stopBroadcast();
    }
}

contract AxelarRevert is Base {
    function setUp() public {}

    function run() external {
        vm.startBroadcast(deployerBNBPK);

        string memory destinationChain = "Polygon";
        uint256 amountGas = 1e16;

        AxelarSender(senderContract).setDestination(destinationChain, toAsciiString(receiverContract));

        AxelarSender(senderContract).revertAxelar{value: amountGas}("testRevertMessage");

        vm.stopBroadcast();
    }
}

contract AxelarRevertToken is Base {
    function setUp() public {}

    function run() external {
        vm.startBroadcast(deployerBNBPK);

        address axlUSDC = 0x4268B8F0B87b6Eae5d897996E6b845ddbD99Adf3;
        uint256 amountGas = 1e16;

        string memory destinationChain = "Polygon";
        string memory symbol = "axlUSDC";
        uint256 amount = 12345;
        
        IERC20(axlUSDC).approve(senderContract, amount);

        AxelarSender(senderContract).setDestination(destinationChain, toAsciiString(receiverContract));

        AxelarSender(senderContract).revertPaymentAxelar{value: amountGas}("testRevertMessage", symbol, amount);

        vm.stopBroadcast();
    }
}