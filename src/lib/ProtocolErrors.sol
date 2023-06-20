// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

error InsufficientProtocolBalance(uint256 protocolBalance, uint256 amountToWithdraw);
error ETHTransferFailed(address recipient);
error ERC20WithdrawFailed(address contractAddress, address recipient, uint256 amount);