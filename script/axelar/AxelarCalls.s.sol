// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./Base.s.sol";

import "src/axelar/AxelarSender.sol";

import "src/interfaces/IERC20Extended.sol";

contract AxelarSubmitToken is Base {
    function setUp() public {}

    function run() external {
        vm.startBroadcast(deployerBNBPK);

        uint256 amountGas = 1e16;

        IERC20Extended paymentToken = IERC20Extended(BUSDC);
        uint256 paymentAmount = 1;
        uint256 amount = paymentAmount * 10**paymentToken.decimals();
        
        paymentToken.approve(senderContract, amount);

        AxelarSender(senderContract).submitTokenAxelar{value: amountGas}("testIpfsHash", BUSDC, paymentAmount);

        vm.stopBroadcast();
    }
}

contract AxelarUpdateToken is Base {
    function setUp() public {}

    function run() external {
        vm.startBroadcast(deployerBNBPK);

        uint256 amountGas = 1e16;

        AxelarSender(senderContract).updateTokenAxelar{value: amountGas}(1234, "testIpfsHash");

        vm.stopBroadcast();
    }
}

contract AxelarTopUpToken is Base {
    function setUp() public {}

    function run() external {
        vm.startBroadcast(deployerBNBPK);

        uint256 amountGas = 1e16;

        IERC20Extended paymentToken = IERC20Extended(BUSDC);
        uint256 paymentAmount = 1;
        uint256 amount = paymentAmount * 10**paymentToken.decimals();
        
        paymentToken.approve(senderContract, amount);

        AxelarSender(senderContract).topUpTokenAxelar{value: amountGas}(1234, BUSDC, paymentAmount);

        vm.stopBroadcast();
    }
}

contract AxelarRevert is Base {
    function setUp() public {}

    function run() external {
        vm.startBroadcast(deployerBNBPK);

        uint256 amountGas = 1e16;

        AxelarSender(senderContract).revertAxelar{value: amountGas}("testRevertMessage");

        vm.stopBroadcast();
    }
}