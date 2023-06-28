// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./TokenStructs.sol";

// TODO : Add NatSpec + Token to tokenId ?

error AlreadyVoted(address voter, ListingStatus status, uint256 listingPhase);
error InvalidPaymentToken(address paymentToken);
error TokenPaymentFailed(address paymentToken, uint256 amount);
error TokenNotFound(uint256 tokenId);
error InvalidPaymentAmount();
error InvalidUpdatingUser(address sender, address submitter);
error NotSortingListing(Token token, ListingStatus status);
error NotUpdatingListing(Token token, ListingStatus status);
error NotValidationListing(Token token, ListingStatus status);
error TokenInCooldown(Token token);
error InvalidScoreValue();
error InsufficientProtocolBalance(uint256 protocolBalance, uint256 amountToWithdraw);
error NothingToClaim(address claimer);
error ETHTransferFailed(address recipient);
error ERC20WithdrawFailed(address contractAddress, address recipient, uint256 amount);
error InvalidUserRank(uint256 userRank, uint256 minimumRankNeeded);
error RankPromotionImpossible(uint256 userRank, uint256 maxCurrentRank);
error NoPromotionYet(uint256 toRank);
error RankDemotionImpossible(uint256 userRank, uint256 minCurrentRank);
error NoDemotionYet(uint256 fromRank);
error InvalidPercentage(uint256 percentage);
error InvalidStatusUpdate(Token token, ListingStatus currentStatus, ListingStatus targetStatus);