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

/*
    TODOs :
    - [EDIT] Being able to edit a not validated listing
        - Is it possible to update a validated listing ?
    - [NO MIN] Being able to submit a listing without sending the minimum amount
    - [METADATAS] Being able to add way more datas to a listing (ERC721 support and other needs)
        - Probably handled on IPFS
    - [MC] Being able to pay on another EVM chain
    - [WL] Being able to whitelist a token -> no need to pay anything to be validated
        - Paid by the protocol

*/

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
    // TODO : Find a way to differentiate tokens (other than contract addresses)
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
        // TODO : WL and NO MIN
        require(
            paymentAmount >= submitFloorPrice,
            "You must pay the required amount."
        );

        IERC20Extended paymentToken = IERC20Extended(paymentTokenAddress);

        // TODO : WL and NO MIN
        require(
            paymentToken.allowance(msg.sender, address(this)) >=
                paymentAmount * 10**paymentToken.decimals(),
            "You must approve the required amount."
        );
        // TODO : WL and NO MIN
        // Retrieve submitter payment for this token
        require(
            paymentToken.transferFrom(
                msg.sender,
                address(this),
                paymentAmount * 10**paymentToken.decimals()
            ),
            "Payment failed."
        );

        // TODO : Can cost a lot in gas + now possible to add same contract address for several tokens
        // -> Not so much in the end if there are not too many pending tokens -> but no check with API's token
        // Check that token's contract addresses aren't already linked with another 'pending' token (to remove)
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

        // TODO : Can cost a lot in gas + now possible to add same contract address for several tokens
        // -> Not so much in the end if there are not too many validated tokens -> but no check with API's token
        // Check that token's contract addresses aren't already linked with another 'validated' token (to remove)
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
            (paymentAmount * 1000) / submitFloorPrice // If paymentAmount == submitFloorPrice -> coeff == 1000
        );
        // Add token as pending
        submittedTokens.push(submittedToken);
        indexOfFirstSortTokens[submittedToken.id] = firstSortTokens.length;
        firstSortTokens.push(submittedToken);
        emit DataSubmitted(submittedToken);
    }

    // TODO : EDIT
    // Method used by Rank I+ users to validate (or not) a token + give scores
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
        // QUESTION : What is this feature ?
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

        // Add voter's scores for this token
        tokenUtilityScore[tokenId].push(utilityScore);
        tokenSocialScore[tokenId].push(socialScore);
        tokenTrustScore[tokenId].push(trustScore);
        // Save that this user voted
        firstSortVotes[msg.sender][tokenId] = true;
        // Add user in Validations or Rejections for this token
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

        // TODO : store indexOfFirstSortTokens in memory
        // If token is in finalValidationTokens -> removed from firstSortTokens -> unreachable
        // If token received enough votes (validations and rejections combined)
        if (
            tokenFirstValidations[tokenId].length +
                tokenFirstRejections[tokenId].length >=
            firstSortMaxVotes
        ) {
            // Relation between firstSortMaxVotes and firstSortValidationsNeeded ? -> thresold for the token to be validated/rejected
            // If there are enough validations -> token first validation
            if (
                tokenFirstValidations[tokenId].length >=
                firstSortValidationsNeeded
            ) {
                // Add token in finalValidationTokens
                indexOfFinalValidationTokens[tokenId] = finalValidationTokens
                    .length;
                finalValidationTokens.push(
                    firstSortTokens[indexOfFirstSortTokens[tokenId]]
                );
                emit FirstSortValidated(
                    firstSortTokens[indexOfFirstSortTokens[tokenId]],
                    tokenFirstValidations[tokenId].length
                );
            // If there are not enough validations (thus enough rejections)
            } else {
                emit FirstSortRejected(
                    firstSortTokens[indexOfFirstSortTokens[tokenId]],
                    tokenFirstValidations[tokenId].length
                );
            }

            // TODO : Probably simplify the readability of the pop
            // Replace token in firstSortTokens by the last token of firstSortTokens
            firstSortTokens[indexOfFirstSortTokens[tokenId]] = firstSortTokens[
                firstSortTokens.length - 1
            ];
            // Remove the last token from firstSortTokens (duplicate)
            indexOfFirstSortTokens[
                firstSortTokens[firstSortTokens.length - 1].id
            ] = indexOfFirstSortTokens[tokenId];
            firstSortTokens.pop();
            // -> After it receives enough votes, remove the token from firstSortTokens
            // What happens to indexOfFirstSortTokens[tokenId] ?
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
        // Is the token validated by rank I users ? (in finalValidationTokens)
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
        // Save that this user voted
        finalDecisionVotes[msg.sender][tokenId] = true;

        // QUESTION : Rank II can submit score twice ? (already possible in firstSortVote) -> can vote for and against ?
        tokenUtilityScore[tokenId].push(utilityScore);
        tokenSocialScore[tokenId].push(socialScore);
        tokenTrustScore[tokenId].push(trustScore);
        // Add user in FinalValidations or FinalRejections for this token
        if (validate) {
            tokenFinalValidations[tokenId].push(msg.sender);
        } else {
            tokenFinalRejections[tokenId].push(msg.sender);
        }

        // TODO : Save in memory indexOfFinalValidationTokens[tokenId] ?

        emit FinalValidationVote(
            finalValidationTokens[indexOfFinalValidationTokens[tokenId]],
            msg.sender,
            validate,
            utilityScore,
            socialScore,
            trustScore
        );

        // TODO : refacto needed -> explode in several methods
        // If token received enough 'final' votes (validations and rejections combined)
        if (
            tokenFinalValidations[tokenId].length +
                tokenFinalRejections[tokenId].length >=
            finalDecisionMaxVotes
        ) {
            // Relation between finalDecisionMaxVotes and finalDecisionValidationsNeeded ? -> thresold for the token to be final validated/rejected
            // If there are enough final validations -> token 'final' validation
            if (
                tokenFinalValidations[tokenId].length >=
                finalDecisionValidationsNeeded
            ) {
                for (
                    uint256 i = 0;
                    i < tokenFirstValidations[tokenId].length;
                    i++
                ) {
                    // tokenFirstValidations[tokenId][i] = voter address whom validated this token
                    // Remove current voter's (i) validation vote for this token from firstSortVotes
                    delete firstSortVotes[tokenFirstValidations[tokenId][i]][
                        tokenId
                    ];
                    // Increment voter's goodFirstVotes count
                    goodFirstVotes[tokenFirstValidations[tokenId][i]]++;
                    // Increment voter's rewards with token's coeff
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
                    // tokenFirstRejections[tokenId][i] = voter address whom rejected this token
                    // Remove current voter's (i) rejection vote for this token from firstSortVotes
                    delete firstSortVotes[tokenFirstRejections[tokenId][i]][
                        tokenId
                    ];
                    // Increment voter's badFirstVotes count
                    badFirstVotes[tokenFirstRejections[tokenId][i]]++;
                }

                // Reward good final voters
                for (
                    uint256 i = 0;
                    i < tokenFinalValidations[tokenId].length;
                    i++
                ) {
                    // tokenFinalValidations[tokenId][i] = voter address whom 'final' validated this token
                    // Remove current voter's (i) final validation vote for this token from finalDecisionVotes
                    delete finalDecisionVotes[
                        tokenFinalValidations[tokenId][i]
                    ][tokenId];
                    // Increment voter's goodFinalVotes count
                    goodFinalVotes[tokenFinalValidations[tokenId][i]]++;
                    // Increment voter's rewards with token's coeff * 2
                    // BUG : tokenFinalValidations[tokenId][i] instead of tokenFirstValidations[tokenId][i] ?
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
                    // tokenFinalRejections[tokenId][i] = voter address whom 'final' rejected this token
                    // Remove current voter's (i) final rejection vote for this token from finalDecisionVotes
                    delete finalDecisionVotes[tokenFinalRejections[tokenId][i]][
                        tokenId
                    ];
                    // Increment voter's badFinalVotes count
                    badFinalVotes[tokenFinalRejections[tokenId][i]]++;
                }

                // Calculate token utility score average
                uint256 tokenUtilityScoreAverage;

                for (
                    uint256 i = 0;
                    i < tokenUtilityScore[tokenId].length;
                    i++
                ) {
                    tokenUtilityScoreAverage += tokenUtilityScore[tokenId][i];
                }

                tokenUtilityScoreAverage /= tokenUtilityScore[tokenId].length;

                // Calculate token social score average
                uint256 tokenSocialScoreAverage;

                for (uint256 i = 0; i < tokenSocialScore[tokenId].length; i++) {
                    tokenSocialScoreAverage += tokenSocialScore[tokenId][i];
                }

                tokenSocialScoreAverage /= tokenSocialScore[tokenId].length;

                // Calculate token trust score average
                uint256 tokenTrustScoreAverage;

                for (uint256 i = 0; i < tokenTrustScore[tokenId].length; i++) {
                    tokenTrustScoreAverage += tokenTrustScore[tokenId][i];
                }

                tokenTrustScoreAverage /= tokenTrustScore[tokenId].length;
                // Save token's scores
                finalValidationTokens[indexOfFinalValidationTokens[tokenId]]
                    .utilityScore = tokenUtilityScoreAverage;
                finalValidationTokens[indexOfFinalValidationTokens[tokenId]]
                    .socialScore = tokenSocialScoreAverage;
                finalValidationTokens[indexOfFinalValidationTokens[tokenId]]
                    .trustScore = tokenTrustScoreAverage;
                // Craft API Token
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
                // Save token in API
                ProtocolAPI.addAssetData(token);

                emit FinalDecisionValidated(
                    finalValidationTokens[
                        indexOfFinalValidationTokens[tokenId]
                    ],
                    tokenFinalValidations[tokenId].length
                );
            // If there are not enough final validations (thus enough final rejections)
            } else {
                // Punish wrong first voters
                for (
                    uint256 i = 0;
                    i < tokenFirstValidations[tokenId].length;
                    i++
                ) {
                    // tokenFirstValidations[tokenId][i] = voter address whom validated this token
                    // Remove current voter's (i) validation vote for this token from firstSortVotes
                    delete firstSortVotes[tokenFirstValidations[tokenId][i]][
                        tokenId
                    ];
                    // Increment voter's badFirstVotes count
                    badFirstVotes[tokenFirstValidations[tokenId][i]]++;
                }

                // Reward good first voters
                for (
                    uint256 i = 0;
                    i < tokenFirstRejections[tokenId].length;
                    i++
                ) {
                    // tokenFirstRejections[tokenId][i] = voter address whom rejected this token
                    // Remove current voter's (i) rejection vote for this token from firstSortVotes
                    delete firstSortVotes[tokenFirstRejections[tokenId][i]][
                        tokenId
                    ];
                    // Increment voter's goodFirstVotes count
                    goodFirstVotes[tokenFirstRejections[tokenId][i]]++;
                    // Increment voter's rewards with token's coeff
                    // BUG : tokenFirstRejections[tokenId][i] instead of tokenFirstValidations[tokenId][i] ?
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
                    // tokenFinalValidations[tokenId][i] = voter address whom validated this token
                    // Remove current voter's (i) validation vote for this token from finalDecisionVotes
                    delete finalDecisionVotes[
                        tokenFinalValidations[tokenId][i]
                    ][tokenId];
                    // Increment voter's badFinalVotes count
                    badFinalVotes[tokenFinalValidations[tokenId][i]]++;
                }

                // Reward good final voters
                for (
                    uint256 i = 0;
                    i < tokenFinalRejections[tokenId].length;
                    i++
                ) {
                    // tokenFinalRejections[tokenId][i] = voter address whom rejected this token
                    // Remove current voter's (i) rejection vote for this token from finalDecisionVotes
                    delete finalDecisionVotes[tokenFinalRejections[tokenId][i]][
                        tokenId
                    ];
                    // Increment voter's goodFinalVotes count
                    goodFinalVotes[tokenFinalRejections[tokenId][i]]++;
                    // Increment voter's rewards with token's coeff*2
                    // BUG : tokenFinalRejections[tokenId][i] instead of tokenFirstValidations[tokenId][i] ?
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
            // TODO : Probably simplify the readability of the pop
            // Replace token in finalValidationTokens by the last token of finalValidationTokens
            finalValidationTokens[
                indexOfFinalValidationTokens[tokenId]
            ] = finalValidationTokens[finalValidationTokens.length - 1];
            // Remove the last token from finalValidationTokens (duplicate)
            indexOfFinalValidationTokens[
                finalValidationTokens[finalValidationTokens.length - 1].id
            ] = indexOfFinalValidationTokens[tokenId];
            finalValidationTokens.pop();
            // -> After it receives enough votes, remove the token from finalValidationTokens
            // What happens to indexOfFinalValidationTokens[tokenId] ?

            // Remove token's scores
            delete tokenUtilityScore[tokenId];
            delete tokenSocialScore[tokenId];
            delete tokenTrustScore[tokenId];
        }
    }

    // Claim personal owed rewards
    // TODO : Being able to claim for anybody ?
    function claimRewards() external {
        uint256 amountToPay = (owedRewards[msg.sender] -
            paidRewards[msg.sender]) * tokensPerVote;
        require(amountToPay > 0, "Nothing to claim.");
        paidRewards[msg.sender] = owedRewards[msg.sender];
        // QUESTION : Why don't we reset owedRewards (but keep stacking paidRewards)
        MOBL.transfer(msg.sender, amountToPay / 1000);
        // QUESTION : MOBL not divisible ?
    }

    // Hierarchy management
    // TODO : Add events -> really hard to track ranked users otherwise
    // TODO : Update promoteVotes, membersToDemoteFromRankI, membersToDemoteFromRankII
    // Increment user's rank
    function emergencyPromote(address promoted) external onlyOwner {
        require(rank[promoted] <= 1, "Impossible");
        rank[promoted]++;
    }
    // Decrement user's rank
    function emergencyDemote(address demoted) external onlyOwner {
        require(rank[demoted] >= 1, "Impossible");
        rank[demoted]--;
    }

    // Remove a token from validation process
    function emergencyKillRequest(uint256 tokenId) external onlyOwner {

        for (uint256 i = 0; i < firstSortTokens.length; i++) {
            if (firstSortTokens[i].id == tokenId) {
                // Remove token from firstSortTokens (refacto this)
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
                // Remove token from firstSortTokens (refacto this)
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

    // Method allowing a rank II user to vote for a promote for a rank I user or below
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

    // Method allowing a rank II user to vote for a demote for a rank II or I user
    function demote(address demoted) external {
        require(rank[msg.sender] >= 2, "You must be Rank II demote.");
        require(rank[demoted] >= 1, "Impossible");

        // BUG : Condition impossible
        if (rank[demoted] == 0) {
            require(membersToDemoteFromRankI > 0, "No demotion yet.");
            demoteVotes[demoted]++;

            if (demoteVotes[demoted] == votesNeededToRankIDemotion) {
                membersToDemoteFromRankI--;
                delete demoteVotes[demoted];
                rank[demoted]++;
            }
        } else {
            // BUG : As previous condition is impossible -> this lead to bugs when demoting rank I
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
    // Withdraw ETH amount to owner
    // TODO : Use msg.sender.call to withdraw funds + allow withdraw to another recipient + checks (amount + not fail)
    function withdrawFunds(uint256 amount) external onlyOwner {
        payable(msg.sender).transfer(amount);
    }

    // Withdraw ERC20 (contractAddress) amount to owner
    // TODO : Allow withdraw to another recipient + checks
    function withdrawERC20Funds(uint256 amount, address contractAddress)
        external
        onlyOwner
    {
        IERC20Extended paymentToken = IERC20Extended(contractAddress);
        paymentToken.transfer(msg.sender, amount);
    }
}
