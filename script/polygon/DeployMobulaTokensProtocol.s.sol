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

        // // Votes
        tokensProtocol.updateSortingMaxVotes(6); // Max 10 votes
        tokensProtocol.updateValidationMaxVotes(4);
        tokensProtocol.updateTokensPerVote(5);

        tokensProtocol.updateVoteCooldown(60 * 30);
        tokensProtocol.updateWhitelistedCooldown(60); 

        // // %
        tokensProtocol.updateSortingMinAcceptancesPct(50); // 50%
        tokensProtocol.updateSortingMinModificationsPct(30); // 50%

        tokensProtocol.updateValidationMinAcceptancesPct(50); // 50%
        tokensProtocol.updateValidationMinModificationsPct(30); // 50%

        tokensProtocol.updateEditCoeffMultiplier(1); // Enough for free edits

        // Members


        vm.stopBroadcast();
    }
}