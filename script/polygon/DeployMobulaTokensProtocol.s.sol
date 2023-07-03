// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./Base.s.sol";

import "src/MobulaTokensProtocol.sol";

contract DeployMobulaTokensProtocol is Base {
    function setUp() public {}

    function run() external {
        vm.startBroadcast(deployerPolygonPK);

        MobulaTokensProtocol tokensProtocol = new MobulaTokensProtocol(axelarPolygonGateway, deployerPolygon, MOBL);

        // Add USDC as a whitelisted stablecoins to pay for listings
        tokensProtocol.whitelistStable(USDC, true);

        // TODO : WL each AxelarSender contracts
        // string memory sourceChain = "binance";
        // string memory sourceAddress; // TODO : Add AxelarSender address
        // tokensProtocol.whitelistAxelarContract(sourceChain, sourceAddress, true);

        // TODO : Only call this if API is deployed and API address in env file
        // tokensProtocol.updateProtocolAPIAddress(protocolAPI);

        tokensProtocol.updateSubmitFloorPrice(100); // 100$

        // Votes
        tokensProtocol.updateSortingMaxVotes(10); // Max 10 votes
        tokensProtocol.updateValidationMaxVotes(10);
        tokensProtocol.updateTokensPerVote(10);

        tokensProtocol.updateVoteCooldown(3600); // 1H cooldown
        tokensProtocol.updateWhitelistedCooldown(3600); // 1H cooldown

        // %
        tokensProtocol.updateSortingMinAcceptancesPct(50); // 50%
        tokensProtocol.updateSortingMinModificationsPct(50); // 50%

        tokensProtocol.updateValidationMinAcceptancesPct(50); // 50%
        tokensProtocol.updateValidationMinModificationsPct(50); // 50%

        // Members
        tokensProtocol.updateMembersToPromoteToRankI(10);
        tokensProtocol.updateMembersToPromoteToRankII(10);
        tokensProtocol.updateMembersToDemoteFromRankI(10);
        tokensProtocol.updateMembersToDemoteFromRankII(10);
        
        tokensProtocol.updateVotesNeededToRankIPromotion(5);
        tokensProtocol.updateVotesNeededToRankIIPromotion(5);
        tokensProtocol.updateVotesNeededToRankIDemotion(5);
        tokensProtocol.updateVotesNeededToRankIIDemotion(5);

        vm.stopBroadcast();
    }
}