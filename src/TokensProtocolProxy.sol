// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";

import "./interfaces/IAPI.sol";
import "./interfaces/IERC20Extended.sol";

import "./lib/ProtocolErrors.sol";
import "./lib/TokenStruct.sol";


contract TokensProtocolProxy is Initializable, Ownable2Step {

    /* Modifiers */
    /**
     * @dev Modifier to limit function calls to Rank I or higher
     */
    modifier onlyRanked() {
        if (rank[msg.sender] == 0) {
            revert InvalidUserRank(rank[msg.sender], 1);
        }
        _;
    }

    /**
     * @dev Modifier to limit function calls to Rank II
     */
    modifier onlyRankII() {
        if (rank[msg.sender] < 2) {
            revert InvalidUserRank(rank[msg.sender], 2);
        }
        _;
    }

    /* Protocol variables */
    /**
     * @dev whitelistedStable Does an ERC20 stablecoin is whitelisted as listing payment
     */
    mapping(address => bool) public whitelistedStable;

    /**
     * @dev protocolAPI API address
     */
    address public protocolAPI;

    /**
     * @dev submitFloorPrice Minimim price to pay for a listing
     */
    uint256 public submitFloorPrice;

    /**
     * @dev firstSortMaxVotes Maximum votes count for first validation
     * @dev firstSortValidationsNeeded Validations count needed for first validation
     * @dev finalDecisionMaxVotes Maximum votes count for final validation
     * @dev finalDecisionValidationsNeeded Validations count needed for final validation
     * @dev tokensPerVote Amount of tokens rewarded per vote (* coeff)
     */
    uint256 public firstSortMaxVotes;
    uint256 public firstSortValidationsNeeded;
    uint256 public finalDecisionMaxVotes;
    uint256 public finalDecisionValidationsNeeded;
    uint256 public tokensPerVote;

    /**
     * @dev membersToPromoteToRankI Amount of Rank I promotions available
     * @dev membersToPromoteToRankII Amount of Rank II promotions available
     * @dev votesNeededToRankIPromotion Amount of votes needed for a Rank I promotion
     * @dev votesNeededToRankIIPromotion Amount of votes needed for a Rank II promotion
     * @dev membersToDemoteFromRankI Amount of Rank I demotion available
     * @dev membersToDemoteFromRankII Amount of Rank II demotion available
     * @dev votesNeededToRankIDemotion Amount of votes needed for a Rank I demotion
     * @dev votesNeededToRankIIDemotion Amount of votes needed for a Rank II demotion
     * @dev voteCooldown Minimum time required between a Token update and a first validation vote
     */
    uint256 public membersToPromoteToRankI;
    uint256 public membersToPromoteToRankII;
    uint256 public votesNeededToRankIPromotion;
    uint256 public votesNeededToRankIIPromotion;
    uint256 public membersToDemoteFromRankI;
    uint256 public membersToDemoteFromRankII;
    uint256 public votesNeededToRankIDemotion;
    uint256 public votesNeededToRankIIDemotion;
    uint256 public voteCooldown;

    /**
     * @dev rank User rank
     * @dev promoteVotes Amount of votes for User promotion
     * @dev demoteVotes Amount of votes for User demotion
     * @dev goodFirstVotes Amount of User's 'good' first votes
     * @dev badFirstVotes Amount of User's 'bad' first votes
     * @dev goodFinalVotes Amount of User's 'good' final votes
     * @dev badFinalVotes Amount of User's 'bad' final votes
     * @dev owedRewards Amount of User's owed rewards
     * @dev paidRewards Amount of User's paid rewards
     */
    mapping(address => uint256) public rank;
    mapping(address => uint256) public promoteVotes;
    mapping(address => uint256) public demoteVotes;
    mapping(address => uint256) public goodFirstVotes;
    mapping(address => uint256) public badFirstVotes;
    mapping(address => uint256) public goodFinalVotes;
    mapping(address => uint256) public badFinalVotes;
    mapping(address => uint256) public owedRewards;
    mapping(address => uint256) public paidRewards;

    /**
     * @dev mobulaToken MOBL token address
     */
    address mobulaToken;

    /* Events */
    event FundsWithdrawn(address indexed recipient, uint256 amount);
    event UserPromoted(address indexed promoted, uint256 newRank);
    event UserDemoted(address indexed demoted, uint256 newRank);

    function initialize(address _owner, address _mobulaToken)
        public
        initializer
    {
        _transferOwnership(_owner);
        mobulaToken = _mobulaToken;
    }

    /* Getters */

    // TODO : Add mapping and arrays getters
    
    /* Users methods */

    // TODO : Add submitToken + add Axelar submitHandler + add updateToken
    
    // TODO : Add claimRewards

    /* Votes */

    // TODO : Add votes methods + create modifiers (onlyRanked, onlyRankII...)

    /* Hierarchy Management */

    /**
     * @dev Allows a Rank II user to vote for a promotion for a Rank I user or below
     * @param promoted Address of the user
     */
    function promote(address promoted) external onlyRankII {
        uint256 rankPromoted = rank[promoted];
        if (rankPromoted > 1) {
            revert RankPromotionImpossible(rankPromoted, 1);
        }

        if (rankPromoted == 0) {
            if (membersToPromoteToRankI == 0) {
                revert NoPromotionYet(1);
            }
            ++promoteVotes[promoted];

            if (promoteVotes[promoted] == votesNeededToRankIPromotion) {
                --membersToPromoteToRankI;
                _promote(promoted);
            }
        } else {
            if (membersToPromoteToRankII == 0) {
                revert NoPromotionYet(2);
            }
            ++promoteVotes[promoted];

            if (promoteVotes[promoted] == votesNeededToRankIIPromotion) {
                --membersToPromoteToRankII;
                _promote(promoted);
            }
        }
    }

    /**
     * @dev Allows a Rank II user to vote for a demotion for a Rank II user or below
     * @param demoted Address of the user
     */
    function demote(address demoted) external onlyRankII {
        uint256 rankDemoted = rank[demoted];
        if (rankDemoted == 0) {
            revert RankDemotionImpossible(rankDemoted, 1);
        }

        if (rankDemoted == 1) {
            if (membersToDemoteFromRankI == 0) {
                revert NoDemotionYet(1);
            }
            ++demoteVotes[demoted];

            if (demoteVotes[demoted] == votesNeededToRankIDemotion) {
                --membersToDemoteFromRankI;
                _demote(demoted);
            }
        } else {
            if (membersToDemoteFromRankII == 0) {
                revert NoDemotionYet(2);
            }
            ++demoteVotes[demoted];

            if (demoteVotes[demoted] == votesNeededToRankIIDemotion) {
                --membersToDemoteFromRankII;
                _demote(demoted);
            }
        }
    }

    /* Emergency Methods */

    /**
     * @dev Allows the owner to promote a user
     * @param promoted Address of the user
     */
    function emergencyPromote(address promoted) external onlyOwner {
        uint256 rankPromoted = rank[promoted];
        if (rankPromoted > 1) {
            revert RankPromotionImpossible(rankPromoted, 1);
        }
        // TODO : Update membersToPromoteToRankI or membersToPromoteToRankII ?
        _promote(promoted);
    }

    /**
     * @dev Allows the owner to demote a user
     * @param demoted Address of the user
     */
    function emergencyDemote(address demoted) external onlyOwner {
        uint256 rankDemoted = rank[demoted];
        if (rankDemoted == 0) {
            revert RankDemotionImpossible(rankDemoted, 1);
        }
        // TODO : Update membersToDemoteFromRankI or membersToDemoteFromRankII ?
        _demote(demoted);
    }

    /**
     * @dev Allows the owner to remove a Token from the validation process
     * @param tokenId ID of the Token
     */
    function emergencyKillRequest(uint256 tokenId) external onlyOwner {
        // TODO : Implement

        // for (uint256 i = 0; i < firstSortTokens.length; i++) {
        //     if (firstSortTokens[i].id == tokenId) {
        //         // Remove token from firstSortTokens (refacto this)
        //         firstSortTokens[i] = firstSortTokens[
        //             firstSortTokens.length - 1
        //         ];
        //         indexOfFirstSortTokens[
        //             firstSortTokens[firstSortTokens.length - 1].id
        //         ] = i;
        //         firstSortTokens.pop();
        //         break;
        //     }
        // }

        // for (uint256 i = 0; i < finalValidationTokens.length; i++) {
        //     if (finalValidationTokens[i].id == tokenId) {
        //         // Remove token from firstSortTokens (refacto this)
        //         finalValidationTokens[i] = finalValidationTokens[
        //             finalValidationTokens.length - 1
        //         ];
        //         indexOfFinalValidationTokens[
        //             finalValidationTokens[finalValidationTokens.length - 1].id
        //         ] = i;
        //         finalValidationTokens.pop();
        //         break;
        //     }
        // }
    }

    /* Protocol Management */

    function toggleWhitelistedStable(address _stableAddress) external onlyOwner {
        whitelistedStable[_stableAddress] = !whitelistedStable[_stableAddress];
    }

    function updateProtocolAPIAddress(address _protocolAPI) external onlyOwner {
        protocolAPI = _protocolAPI;
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

    /* Funds Management */

    /**
     * @dev Withdraw ETH amount to recipient
     * @param recipient The recipient
     * @param amount Amount to withdraw
     */
    function withdrawFunds(address recipient, uint256 amount) external onlyOwner {
        uint256 protocolBalance = address(this).balance;
        if (amount > protocolBalance) {
            revert InsufficientProtocolBalance(protocolBalance, amount);
        }
        (bool success,) = recipient.call{value: amount}("");
        if (!success) {
            revert ETHTransferFailed(recipient);
        }
        emit FundsWithdrawn(recipient, amount);
    }

    /**
     * @dev Withdraw ERC20 amount to recipient
     * @param recipient The recipient
     * @param amount Amount to withdraw
     * @param contractAddress ERC20 address
     */
    function withdrawERC20Funds(address recipient, uint256 amount, address contractAddress) external onlyOwner {
        bool success = IERC20Extended(contractAddress).transfer(recipient, amount);
        if (!success) {
            revert ERC20WithdrawFailed(contractAddress, recipient, amount);
        }
    }

    /* Internal Methods */

    /**
     * @dev Increase user rank
     * @param promoted Address of the user
     */
    function _promote(address promoted) internal {
        delete promoteVotes[promoted];

        emit UserPromoted(promoted, ++rank[promoted]);
    }

    /**
     * @dev Decrease user rank
     * @param demoted Address of the user
     */
    function _demote(address demoted) internal {
        delete demoteVotes[demoted];

        emit UserDemoted(demoted, --rank[demoted]);
    }
}