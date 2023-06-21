// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

error InsufficientProtocolBalance(uint256 protocolBalance, uint256 amountToWithdraw);
error ETHTransferFailed(address recipient);
error ERC20WithdrawFailed(address contractAddress, address recipient, uint256 amount);
error InvalidUserRank(uint256 userRank, uint256 minimumRankNeeded);
error RankPromotionImpossible(uint256 userRank, uint256 maxCurrentRank);
error NoPromotionYet(uint256 toRank);
error RankDemotionImpossible(uint256 userRank, uint256 minCurrentRank);
error NoDemotionYet(uint256 fromRank);