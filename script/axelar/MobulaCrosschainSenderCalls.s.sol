// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./Base.s.sol";

import "src/MobulaCrosschainSender.sol";

import "src/interfaces/IERC20Extended.sol";

contract MobulaCrosschainSenderSubmitToken is Base {
    function setUp() public {}

    function run() external {
        vm.startBroadcast(deployerBNBPK);

        uint256 amountGas = 1e16;

        IERC20Extended paymentToken = IERC20Extended(BUSDC);
        uint256 paymentAmount = 1;
        uint256 amount = paymentAmount * 10**paymentToken.decimals();
        
        paymentToken.approve(senderContract, amount);

        MobulaCrosschainSender(senderContract).submitTokenAxelar{value: amountGas}("testIpfsHash", BUSDC, paymentAmount, 0);

        vm.stopBroadcast();
    }
}

contract MobulaCrosschainSenderUpdateToken is Base {
    function setUp() public {}

    function run() external {
        vm.startBroadcast(deployerBNBPK);

        uint256 amountGas = 1e16;

        MobulaCrosschainSender(senderContract).updateTokenAxelar{value: amountGas}(1234, "testIpfsHash");

        vm.stopBroadcast();
    }
}

contract MobulaCrosschainSenderTopUpToken is Base {
    function setUp() public {}

    function run() external {
        vm.startBroadcast(deployerBNBPK);

        uint256 amountGas = 1e16;

        IERC20Extended paymentToken = IERC20Extended(BUSDC);
        uint256 paymentAmount = 1;
        uint256 amount = paymentAmount * 10**paymentToken.decimals();
        
        paymentToken.approve(senderContract, amount);

        MobulaCrosschainSender(senderContract).topUpTokenAxelar{value: amountGas}(1234, BUSDC, paymentAmount);

        vm.stopBroadcast();
    }
}