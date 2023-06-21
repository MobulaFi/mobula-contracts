// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";

import "./interfaces/IAPI.sol";
import "./interfaces/IERC20Extended.sol";

import "./lib/ProtocolErrors.sol";
import "./lib/TokenStruct.sol";


contract TokensProtocolProxy is Initializable, Ownable2Step {

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
     * @dev mobulaToken MOBL token address
     */
    address mobulaToken;

    /* Events */
    event FundsWithdrawn(address indexed recipient, uint256 amount);

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

    /* Hierarchy Management */

    // TODO : Add promote/demote

    /* Emergency Methods */

    // TODO : Add token emergency methods

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

}