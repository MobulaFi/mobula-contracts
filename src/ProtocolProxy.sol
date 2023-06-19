// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";

import "./interfaces/IAPI.sol";
import "./interfaces/IERC20Extended.sol";

struct SubmitQuery {
    string ipfsHash;
    address[] contractAddresses;
    uint256 id;
    address[] totalSupply;
    address[] excludedFromCirculation;
    uint256 lastUpdate;
    uint256 utilityScore;
    uint256 socialScore;
    uint256 trustScore;
    uint256 coeff;
}

contract ProtocolProxy is Initializable, Ownable2Step {
    uint256 public submitFloorPrice;

    uint256 public firstSortMaxVotes;
    uint256 public firstSortValidationsNeeded;
    uint256 public finalDecisionValidationsNeeded;
    uint256 public finalDecisionMaxVotes;
    uint256 public tokensPerVote;

    uint256 public membersToPromoteToRankI;
    uint256 public membersToPromoteToRankII;
    uint256 public votesNeededToRankIPromotion;
    uint256 public votesNeededToRankIIPromotion;
    uint256 public membersToDemoteFromRankI;
    uint256 public membersToDemoteFromRankII;
    uint256 public votesNeededToRankIDemotion;
    uint256 public votesNeededToRankIIDemotion;
    uint256 public voteCooldown;

    mapping(address => bool) public whitelistedStable;

    mapping(address => mapping(uint256 => bool)) public firstSortVotes;
    mapping(address => mapping(uint256 => bool)) public finalDecisionVotes;
    mapping(uint256 => address[]) public tokenFirstValidations;
    mapping(uint256 => address[]) public tokenFirstRejections;
    mapping(uint256 => address[]) public tokenFinalValidations;
    mapping(uint256 => address[]) public tokenFinalRejections;

    mapping(uint256 => uint256[]) public tokenUtilityScore;
    mapping(uint256 => uint256[]) public tokenSocialScore;
    mapping(uint256 => uint256[]) public tokenTrustScore;

    mapping(address => uint256) public rank;
    mapping(address => uint256) public promoteVotes;
    mapping(address => uint256) public demoteVotes;
    mapping(address => uint256) public goodFirstVotes;
    mapping(address => uint256) public badFirstVotes;
    mapping(address => uint256) public badFinalVotes;
    mapping(address => uint256) public goodFinalVotes;
    mapping(address => uint256) public owedRewards;
    mapping(address => uint256) public paidRewards;

    SubmitQuery[] public submittedTokens;

    SubmitQuery[] public firstSortTokens;
    mapping(uint256 => uint256) public indexOfFirstSortTokens;
    SubmitQuery[] public finalValidationTokens;
    mapping(uint256 => uint256) public indexOfFinalValidationTokens;

    IERC20 MOBL;
    IAPI ProtocolAPI;

    event DataSubmitted(SubmitQuery token);
    event FirstSortVote(
        SubmitQuery token,
        address voter,
        bool validated,
        uint256 utilityScore,
        uint256 socialScore,
        uint256 trustScore
    );
    event FinalValidationVote(
        SubmitQuery token,
        address voter,
        bool validated,
        uint256 utilityScore,
        uint256 socialScore,
        uint256 trustScore
    );
    event FirstSortValidated(SubmitQuery token, uint256 validations);
    event FirstSortRejected(SubmitQuery token, uint256 validations);
    event FinalDecisionValidated(SubmitQuery token, uint256 validations);
    event FinalDecisionRejected(SubmitQuery token, uint256 validations);

    function initialize(address _owner, address _mobulaTokenAddress)
        public
        initializer
    {
        _transferOwnership(_owner);
        MOBL = IERC20(_mobulaTokenAddress);
    }

    // Getters for public arrays

    function getSubmittedTokens() external view returns (SubmitQuery[] memory) {
        return submittedTokens;
    }

    function getFirstSortTokens() external view returns (SubmitQuery[] memory) {
        return firstSortTokens;
    }

    function getFinalValidationTokens()
        external
        view
        returns (SubmitQuery[] memory)
    {
        return finalValidationTokens;
    }

    //Protocol variables updaters

    function changeWhitelistedStable(address _stableAddress) external onlyOwner {
        whitelistedStable[_stableAddress] = !whitelistedStable[_stableAddress];
    }

    function updateProtocolAPIAddress(address _protocolAPIAddress) external onlyOwner {
        ProtocolAPI = IAPI(_protocolAPIAddress);
    }

    function updateSubmitFloorPrice(uint256 _submitFloorPrice) external onlyOwner {
        submitFloorPrice = _submitFloorPrice;
    }

    function updateFirstSortMaxVotes(uint256 _firstSortMaxVotes) external onlyOwner {
        firstSortMaxVotes = _firstSortMaxVotes;
    }

    function updateFinalDecisionMaxVotes(uint256 _finalDecisionMaxVotes)
        external
        onlyOwner
    {
        finalDecisionMaxVotes = _finalDecisionMaxVotes;
    }

    function updateFirstSortValidationsNeeded(
        uint256 _firstSortValidationsNeeded
    ) external onlyOwner {
        firstSortValidationsNeeded = _firstSortValidationsNeeded;
    }

    function updateFinalDecisionValidationsNeeded(
        uint256 _finalDecisionValidationsNeeded
    ) external onlyOwner {
        finalDecisionValidationsNeeded = _finalDecisionValidationsNeeded;
    }

    function updateTokensPerVote(uint256 _tokensPerVote) external onlyOwner {
        tokensPerVote = _tokensPerVote;
    }

    function updateMembersToPromoteToRankI(uint256 _membersToPromoteToRankI)
        external
        onlyOwner
    {
        membersToPromoteToRankI = _membersToPromoteToRankI;
    }

    function updateMembersToPromoteToRankII(uint256 _membersToPromoteToRankII)
        external
        onlyOwner
    {
        membersToPromoteToRankII = _membersToPromoteToRankII;
    }

    function updateMembersToDemoteFromRankI(uint256 _membersToDemoteToRankI)
        external
        onlyOwner
    {
        membersToDemoteFromRankI = _membersToDemoteToRankI;
    }

    function updateMembersToDemoteFromRankII(uint256 _membersToDemoteToRankII)
        external
        onlyOwner
    {
        membersToDemoteFromRankII = _membersToDemoteToRankII;
    }

    function updateVotesNeededToRankIPromotion(
        uint256 _votesNeededToRankIPromotion
    ) external onlyOwner {
        votesNeededToRankIPromotion = _votesNeededToRankIPromotion;
    }

    function updateVotesNeededToRankIIPromotion(
        uint256 _votesNeededToRankIIPromotion
    ) external onlyOwner {
        votesNeededToRankIIPromotion = _votesNeededToRankIIPromotion;
    }

    function updateVotesNeededToRankIDemotion(
        uint256 _votesNeededToRankIDemotion
    ) external onlyOwner {
        votesNeededToRankIDemotion = _votesNeededToRankIDemotion;
    }

    function updateVotesNeededToRankIIDemotion(
        uint256 _votesNeededToRankIIDemotion
    ) external onlyOwner {
        votesNeededToRankIIDemotion = _votesNeededToRankIIDemotion;
    }

    function updateVoteCooldown(uint256 _voteCooldown) external onlyOwner {
        voteCooldown = _voteCooldown;
    }

    //Protocol data processing

    function submitIPFS(
        address[] memory contractAddresses,
        address[] memory totalSupplyAddresses,
        address[] memory excludedCirculationAddresses,
        string memory ipfsHash,
        address paymentTokenAddress,
        uint256 paymentAmount,
        uint256 assetId
    ) external payable {
        require(
            whitelistedStable[paymentTokenAddress],
            "You must pay with valid stable."
        );
        require(
            contractAddresses.length > 0,
            "You must submit at least one contract."
        );
        require(
            paymentAmount >= submitFloorPrice,
            "You must pay the required amount."
        );

        IERC20Extended paymentToken = IERC20Extended(paymentTokenAddress);

        require(
            paymentToken.allowance(msg.sender, address(this)) >=
                paymentAmount * 10**paymentToken.decimals(),
            "You must approve the required amount."
        );
        require(
            paymentToken.transferFrom(
                msg.sender,
                address(this),
                paymentAmount * 10**paymentToken.decimals()
            ),
            "Payment failed."
        );

        for (uint256 i = 0; i < firstSortTokens.length; i++) {
            for (
                uint256 j = 0;
                j < firstSortTokens[i].contractAddresses.length;
                j++
            ) {
                for (uint256 k = 0; k < contractAddresses.length; k++) {
                    require(
                        firstSortTokens[i].contractAddresses[j] !=
                            contractAddresses[k],
                        "One of the smart-contracts is already in the listing process."
                    );
                }
            }
        }

        for (uint256 i = 0; i < finalValidationTokens.length; i++) {
            for (
                uint256 j = 0;
                j < finalValidationTokens[i].contractAddresses.length;
                j++
            ) {
                for (uint256 k = 0; k < contractAddresses.length; k++) {
                    require(
                        finalValidationTokens[i].contractAddresses[j] !=
                            contractAddresses[k],
                        "One of the smart-contracts is already in the listing process."
                    );
                }
            }
        }

        uint256 finalId;

        if (assetId == 0) {
            finalId = submittedTokens.length;
        } else {
            finalId = assetId;
        }

        SubmitQuery memory submittedToken = SubmitQuery(
            ipfsHash,
            contractAddresses,
            finalId,
            totalSupplyAddresses,
            excludedCirculationAddresses,
            block.timestamp,
            0,
            0,
            0,
            (paymentAmount * 1000) / submitFloorPrice
        );

        submittedTokens.push(submittedToken);
        indexOfFirstSortTokens[submittedToken.id] = firstSortTokens.length;
        firstSortTokens.push(submittedToken);
        emit DataSubmitted(submittedToken);
    }

    function firstSortVote(
        uint256 tokenId,
        bool validate,
        uint256 utilityScore,
        uint256 socialScore,
        uint256 trustScore
    ) external {
        require(rank[msg.sender] >= 1, "You must be Rank I or higher to vote.");
        require(
            firstSortTokens[indexOfFirstSortTokens[tokenId]]
                .contractAddresses
                .length > 0,
            "Token not submitted."
        );
        require(
            !firstSortVotes[msg.sender][tokenId],
            "You cannot vote twice for the same token."
        );
        require(
            block.timestamp >
                firstSortTokens[indexOfFirstSortTokens[tokenId]].lastUpdate +
                    voteCooldown,
            "You must wait before the end of the cooldown to vote."
        );
        require(
            utilityScore <= 5 && socialScore <= 5 && trustScore <= 5,
            "Scores must be between 0 and 5."
        );

        tokenUtilityScore[tokenId].push(utilityScore);
        tokenSocialScore[tokenId].push(socialScore);
        tokenTrustScore[tokenId].push(trustScore);

        firstSortVotes[msg.sender][tokenId] = true;

        if (validate) {
            tokenFirstValidations[tokenId].push(msg.sender);
        } else {
            tokenFirstRejections[tokenId].push(msg.sender);
        }

        emit FirstSortVote(
            firstSortTokens[indexOfFirstSortTokens[tokenId]],
            msg.sender,
            validate,
            utilityScore,
            socialScore,
            trustScore
        );

        if (
            tokenFirstValidations[tokenId].length +
                tokenFirstRejections[tokenId].length >=
            firstSortMaxVotes
        ) {
            if (
                tokenFirstValidations[tokenId].length >=
                firstSortValidationsNeeded
            ) {
                indexOfFinalValidationTokens[tokenId] = finalValidationTokens
                    .length;
                finalValidationTokens.push(
                    firstSortTokens[indexOfFirstSortTokens[tokenId]]
                );
                emit FirstSortValidated(
                    firstSortTokens[indexOfFirstSortTokens[tokenId]],
                    tokenFirstValidations[tokenId].length
                );
            } else {
                emit FirstSortRejected(
                    firstSortTokens[indexOfFirstSortTokens[tokenId]],
                    tokenFirstValidations[tokenId].length
                );
            }

            firstSortTokens[indexOfFirstSortTokens[tokenId]] = firstSortTokens[
                firstSortTokens.length - 1
            ];
            indexOfFirstSortTokens[
                firstSortTokens[firstSortTokens.length - 1].id
            ] = indexOfFirstSortTokens[tokenId];
            firstSortTokens.pop();
        }
    }

    function finalDecisionVote(
        uint256 tokenId,
        bool validate,
        uint256 utilityScore,
        uint256 socialScore,
        uint256 trustScore
    ) external {
        require(rank[msg.sender] >= 2, "You must be Rank II to vote.");
        require(
            finalValidationTokens[indexOfFinalValidationTokens[tokenId]]
                .contractAddresses
                .length > 0,
            "Token not submitted."
        );
        require(
            !finalDecisionVotes[msg.sender][tokenId],
            "You cannot vote twice for the same token."
        );

        finalDecisionVotes[msg.sender][tokenId] = true;

        tokenUtilityScore[tokenId].push(utilityScore);
        tokenSocialScore[tokenId].push(socialScore);
        tokenTrustScore[tokenId].push(trustScore);

        if (validate) {
            tokenFinalValidations[tokenId].push(msg.sender);
        } else {
            tokenFinalRejections[tokenId].push(msg.sender);
        }

        emit FinalValidationVote(
            finalValidationTokens[indexOfFinalValidationTokens[tokenId]],
            msg.sender,
            validate,
            utilityScore,
            socialScore,
            trustScore
        );

        if (
            tokenFinalValidations[tokenId].length +
                tokenFinalRejections[tokenId].length >=
            finalDecisionMaxVotes
        ) {
            if (
                tokenFinalValidations[tokenId].length >=
                finalDecisionValidationsNeeded
            ) {
                for (
                    uint256 i = 0;
                    i < tokenFirstValidations[tokenId].length;
                    i++
                ) {
                    delete firstSortVotes[tokenFirstValidations[tokenId][i]][
                        tokenId
                    ];
                    goodFirstVotes[tokenFirstValidations[tokenId][i]]++;
                    owedRewards[
                        tokenFirstValidations[tokenId][i]
                    ] += finalValidationTokens[
                        indexOfFinalValidationTokens[tokenId]
                    ].coeff;
                }

                for (
                    uint256 i = 0;
                    i < tokenFirstRejections[tokenId].length;
                    i++
                ) {
                    delete firstSortVotes[tokenFirstRejections[tokenId][i]][
                        tokenId
                    ];
                    badFirstVotes[tokenFirstRejections[tokenId][i]]++;
                }

                // Reward good final voters
                for (
                    uint256 i = 0;
                    i < tokenFinalValidations[tokenId].length;
                    i++
                ) {
                    delete finalDecisionVotes[
                        tokenFinalValidations[tokenId][i]
                    ][tokenId];
                    goodFinalVotes[tokenFinalValidations[tokenId][i]]++;
                    owedRewards[tokenFirstValidations[tokenId][i]] +=
                        finalValidationTokens[
                            indexOfFinalValidationTokens[tokenId]
                        ].coeff *
                        2;
                }

                // Punish wrong final voters
                for (
                    uint256 i = 0;
                    i < tokenFinalRejections[tokenId].length;
                    i++
                ) {
                    delete finalDecisionVotes[tokenFinalRejections[tokenId][i]][
                        tokenId
                    ];
                    badFinalVotes[tokenFinalRejections[tokenId][i]]++;
                }

                uint256 tokenUtilityScoreAverage;

                for (
                    uint256 i = 0;
                    i < tokenUtilityScore[tokenId].length;
                    i++
                ) {
                    tokenUtilityScoreAverage += tokenUtilityScore[tokenId][i];
                }

                tokenUtilityScoreAverage /= tokenUtilityScore[tokenId].length;

                uint256 tokenSocialScoreAverage;

                for (uint256 i = 0; i < tokenSocialScore[tokenId].length; i++) {
                    tokenSocialScoreAverage += tokenSocialScore[tokenId][i];
                }

                tokenSocialScoreAverage /= tokenSocialScore[tokenId].length;

                uint256 tokenTrustScoreAverage;

                for (uint256 i = 0; i < tokenTrustScore[tokenId].length; i++) {
                    tokenTrustScoreAverage += tokenTrustScore[tokenId][i];
                }

                tokenTrustScoreAverage /= tokenTrustScore[tokenId].length;

                finalValidationTokens[indexOfFinalValidationTokens[tokenId]]
                    .utilityScore = tokenUtilityScoreAverage;
                finalValidationTokens[indexOfFinalValidationTokens[tokenId]]
                    .socialScore = tokenSocialScoreAverage;
                finalValidationTokens[indexOfFinalValidationTokens[tokenId]]
                    .trustScore = tokenTrustScoreAverage;

                IAPI.Token memory token = IAPI.Token(
                    finalValidationTokens[indexOfFinalValidationTokens[tokenId]]
                        .ipfsHash,
                    finalValidationTokens[indexOfFinalValidationTokens[tokenId]]
                        .contractAddresses,
                    finalValidationTokens[indexOfFinalValidationTokens[tokenId]]
                        .id,
                    finalValidationTokens[indexOfFinalValidationTokens[tokenId]]
                        .totalSupply,
                    finalValidationTokens[indexOfFinalValidationTokens[tokenId]]
                        .excludedFromCirculation,
                    finalValidationTokens[indexOfFinalValidationTokens[tokenId]]
                        .lastUpdate,
                    finalValidationTokens[indexOfFinalValidationTokens[tokenId]]
                        .utilityScore,
                    finalValidationTokens[indexOfFinalValidationTokens[tokenId]]
                        .socialScore,
                    finalValidationTokens[indexOfFinalValidationTokens[tokenId]]
                        .trustScore
                );

                ProtocolAPI.addAssetData(token);

                emit FinalDecisionValidated(
                    finalValidationTokens[
                        indexOfFinalValidationTokens[tokenId]
                    ],
                    tokenFinalValidations[tokenId].length
                );
            } else {
                // Punish wrong first voters
                for (
                    uint256 i = 0;
                    i < tokenFirstValidations[tokenId].length;
                    i++
                ) {
                    delete firstSortVotes[tokenFirstValidations[tokenId][i]][
                        tokenId
                    ];
                    badFirstVotes[tokenFirstValidations[tokenId][i]]++;
                }

                // Reward good first voters
                for (
                    uint256 i = 0;
                    i < tokenFirstRejections[tokenId].length;
                    i++
                ) {
                    delete firstSortVotes[tokenFirstRejections[tokenId][i]][
                        tokenId
                    ];
                    goodFirstVotes[tokenFirstRejections[tokenId][i]]++;
                    owedRewards[
                        tokenFirstValidations[tokenId][i]
                    ] += finalValidationTokens[
                        indexOfFinalValidationTokens[tokenId]
                    ].coeff;
                }

                // Punish wrong final voters
                for (
                    uint256 i = 0;
                    i < tokenFinalValidations[tokenId].length;
                    i++
                ) {
                    delete finalDecisionVotes[
                        tokenFinalValidations[tokenId][i]
                    ][tokenId];
                    badFinalVotes[tokenFinalValidations[tokenId][i]]++;
                }

                // Reward good final voters
                for (
                    uint256 i = 0;
                    i < tokenFinalRejections[tokenId].length;
                    i++
                ) {
                    delete finalDecisionVotes[tokenFinalRejections[tokenId][i]][
                        tokenId
                    ];
                    goodFinalVotes[tokenFinalRejections[tokenId][i]]++;
                    owedRewards[tokenFirstValidations[tokenId][i]] +=
                        finalValidationTokens[
                            indexOfFinalValidationTokens[tokenId]
                        ].coeff *
                        2;
                }

                emit FinalDecisionRejected(
                    finalValidationTokens[
                        indexOfFinalValidationTokens[tokenId]
                    ],
                    tokenFinalValidations[tokenId].length
                );
            }

            finalValidationTokens[
                indexOfFinalValidationTokens[tokenId]
            ] = finalValidationTokens[finalValidationTokens.length - 1];
            indexOfFinalValidationTokens[
                finalValidationTokens[finalValidationTokens.length - 1].id
            ] = indexOfFinalValidationTokens[tokenId];
            finalValidationTokens.pop();

            delete tokenUtilityScore[tokenId];
            delete tokenSocialScore[tokenId];
            delete tokenTrustScore[tokenId];
        }
    }

    function claimRewards() external {
        uint256 amountToPay = (owedRewards[msg.sender] -
            paidRewards[msg.sender]) * tokensPerVote;
        require(amountToPay > 0, "Nothing to claim.");
        paidRewards[msg.sender] = owedRewards[msg.sender];
        MOBL.transfer(msg.sender, amountToPay / 1000);
    }

    // Hierarchy management

    function emergencyPromote(address promoted) external onlyOwner {
        require(rank[promoted] <= 1, "Impossible");
        rank[promoted]++;
    }

    function emergencyDemote(address demoted) external onlyOwner {
        require(rank[demoted] >= 1, "Impossible");
        rank[demoted]--;
    }

    function emergencyKillRequest(uint256 tokenId) external onlyOwner {

        for (uint256 i = 0; i < firstSortTokens.length; i++) {
            if (firstSortTokens[i].id == tokenId) {
                firstSortTokens[i] = firstSortTokens[
                    firstSortTokens.length - 1
                ];
                indexOfFirstSortTokens[
                    firstSortTokens[firstSortTokens.length - 1].id
                ] = i;
                firstSortTokens.pop();
                break;
            }
        }

        for (uint256 i = 0; i < finalValidationTokens.length; i++) {
            if (finalValidationTokens[i].id == tokenId) {
                finalValidationTokens[i] = finalValidationTokens[
                    finalValidationTokens.length - 1
                ];
                indexOfFinalValidationTokens[
                    finalValidationTokens[finalValidationTokens.length - 1].id
                ] = i;
                finalValidationTokens.pop();
                break;
            }
        }
    }

    function promote(address promoted) external {
        require(rank[msg.sender] >= 2, "You must be Rank II to promote.");
        require(rank[promoted] <= 1, "Impossible");

        if (rank[promoted] == 0) {
            require(membersToPromoteToRankI > 0, "No promotions yet.");
            promoteVotes[promoted]++;

            if (promoteVotes[promoted] == votesNeededToRankIPromotion) {
                membersToPromoteToRankI--;
                delete promoteVotes[promoted];
                rank[promoted]++;
            }
        } else {
            require(membersToPromoteToRankII > 0, "No promotions yet.");
            promoteVotes[promoted]++;

            if (promoteVotes[promoted] == votesNeededToRankIIPromotion) {
                membersToPromoteToRankII--;
                delete promoteVotes[promoted];
                rank[promoted]++;
            }
        }
    }

    function demote(address demoted) external {
        require(rank[msg.sender] >= 2, "You must be Rank II demote.");
        require(rank[demoted] >= 1, "Impossible");

        if (rank[demoted] == 0) {
            require(membersToDemoteFromRankI > 0, "No demotion yet.");
            demoteVotes[demoted]++;

            if (demoteVotes[demoted] == votesNeededToRankIDemotion) {
                membersToDemoteFromRankI--;
                delete demoteVotes[demoted];
                rank[demoted]++;
            }
        } else {
            require(membersToDemoteFromRankII > 0, "No demotion yet.");
            demoteVotes[demoted]++;

            if (demoteVotes[demoted] == votesNeededToRankIIDemotion) {
                membersToDemoteFromRankII--;
                delete demoteVotes[demoted];
                rank[demoted]--;
            }
        }
    }

    // Funds management

    function withdrawFunds(uint256 amount) external onlyOwner {
        payable(msg.sender).transfer(amount);
    }

    function withdrawERC20Funds(uint256 amount, address contractAddress)
        external
        onlyOwner
    {
        IERC20Extended paymentToken = IERC20Extended(contractAddress);
        paymentToken.transfer(msg.sender, amount);
    }
}
