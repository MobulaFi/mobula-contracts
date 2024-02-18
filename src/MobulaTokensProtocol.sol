// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@axelar/contracts/executable/AxelarExecutable.sol";

import "./interfaces/IAPI.sol";
import "./interfaces/IERC20Extended.sol";

import "./lib/ProtocolErrors.sol";
import "./lib/TokenStructs.sol";
import "./lib/AxelarStructs.sol";

contract MobulaTokensProtocol is AxelarExecutable, Ownable2Step {

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
     * @dev whitelistedSubmitter Does this user needs to pay for a Token submission
     * @dev whitelistedLastSubmit Timestamp last submission
     * @dev whitelistedCooldown Minimum time required between two Token submission for whitelisted users
     */
    mapping(address => bool) public whitelistedSubmitter;
    mapping(address => uint256) public whitelistedLastSubmit;
    uint256 public whitelistedCooldown;

    /**
     * @dev submitFloorPrice Minimim price to pay for a listing
     */
    uint256 public submitFloorPrice;

    /**
     * @dev whitelistedAxelarContract Does an address on a blockchain is whitelisted
     */
    mapping(string => mapping(string => bool)) public whitelistedAxelarContract;

    /**
     * @dev tokenListings All Token Listings
     */
    TokenListing[] public tokenListings;

    /**
    * @dev nextTokenId used to track token ID state.
     */
    uint256 public nextTokenId;

    /**
     * @dev sortingMaxVotes Maximum votes count for Sorting
     * @dev sortingMinAcceptancesPct Minimum % of Acceptances for Sorting
     * @dev sortingMinModificationsPct Minimum % of ModificationsNeeded for Sorting
     * @dev validationMaxVotes Maximum votes count for Validation
     * @dev validationMinAcceptancesPct Minimum % of Acceptances for Validation
     * @dev validationMinModificationsPct Minimum % of ModificationsNeeded for Validation
     * @dev tokensPerVote Amount of tokens rewarded per vote (* coeff)
     */
    uint256 public sortingMaxVotes;
    uint256 public sortingMinAcceptancesPct;
    uint256 public sortingMinModificationsPct;
    uint256 public validationMaxVotes;
    uint256 public validationMinAcceptancesPct;
    uint256 public validationMinModificationsPct;
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
     * @dev editCoeffMultiplier Coefficient multiplier for Token update (edit)
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
    uint256 public editCoeffMultiplier;

    /**
     * @dev rank User rank
     * @dev promoteVotes Amount of votes for User promotion
     * @dev demoteVotes Amount of votes for User demotion
     * @dev goodSortingVotes Amount of User's 'good' first votes
     * @dev badSortingVotes Amount of User's 'bad' first votes
     * @dev goodValidationVotes Amount of User's 'good' final votes
     * @dev badValidationVotes Amount of User's 'bad' final votes
     * @dev owedRewards Amount of User's owed rewards
     * @dev paidRewards Amount of User's paid rewards
     */
    mapping(address => uint256) public rank;
    mapping(address => uint256) public promoteVotes;
    mapping(address => uint256) public demoteVotes;
    mapping(address => uint256) public goodSortingVotes;
    mapping(address => uint256) public badSortingVotes;
    mapping(address => uint256) public goodValidationVotes;
    mapping(address => uint256) public badValidationVotes;
    mapping(address => uint256) public owedRewards;
    mapping(address => uint256) public paidRewards;

    /**
     * @dev poolListings IDs of listing in Pool state
     * @dev updatingListings IDs of listing in Updating state
     * @dev sortingListings IDs of listing in Sorting state
     * @dev validationListings IDs of listing in Validation state
     * @dev validatedListings IDs of listing in Validated state
     * @dev rejectedListings IDs of listing in Rejected state
     * @dev killedListings IDs of listing in Killed state
     */
    uint256[] poolListings;
    uint256[] updatingListings;
    uint256[] sortingListings;
    uint256[] validationListings;
    uint256[] validatedListings;
    uint256[] rejectedListings;
    uint256[] killedListings;

    /**
     * @dev sortingVotesPhase Token's Sorting Users vote phase
     * @dev validationVotesPhase Token's Validation Users vote phase
     */
    mapping(uint256 => mapping(address => uint256)) public sortingVotesPhase;
    mapping(uint256 => mapping(address => uint256)) public validationVotesPhase;

    /**
     * @dev sortingAcceptances Token's Sorting Accept voters
     * @dev sortingRejections Token's Sorting Reject voters
     * @dev sortingModifications Token's Sorting ModificationsNeeded voters
     * @dev validationAcceptances Token's Validation Accept voters
     * @dev validationRejections Token's Validation Reject voters
     * @dev validationModifications Token's Validation ModificationsNeeded voters
     */
    mapping(uint256 => address[]) public sortingAcceptances;
    mapping(uint256 => address[]) public sortingRejections;
    mapping(uint256 => address[]) public sortingModifications;
    mapping(uint256 => address[]) public validationAcceptances;
    mapping(uint256 => address[]) public validationRejections;
    mapping(uint256 => address[]) public validationModifications;
    
    /**
     * @dev PAYMENT_COEFF Payment coefficient
     */
    uint256 private constant PAYMENT_COEFF = 1000;

    /**
     * @dev mobulaToken MOBL token address
     */
    address private mobulaToken;

    /**
     * @dev protocolAPI API address
     */
    address public protocolAPI;

    /* Events */
    event TokenListingSubmitted(address submitter, TokenListing tokenListing);
    event TokenDetailsUpdated(Token token);
    event TokenListingFunded(address indexed funder, TokenListing tokenListing, uint256 amount);
    event RewardsClaimed(address indexed claimer, uint256 amount);
    event FundsWithdrawn(address indexed recipient, uint256 amount);
    event ERC20FundsWithdrawn(address indexed recipient, address indexed contractAddress, uint256 amount);
    event UserPromoted(address indexed promoted, uint256 newRank);
    event UserDemoted(address indexed demoted, uint256 newRank);
    event ListingStatusUpdated(Token token, ListingStatus previousStatus, ListingStatus newStatus);
    event SortingVote(Token token, address voter, ListingVote vote, uint256 utilityScore, uint256 socialScore, uint256 trustScore);
    event ValidationVote(Token token, address voter, ListingVote vote, uint256 utilityScore, uint256 socialScore, uint256 trustScore);
    event TokenValidated(Token token);

    constructor(address gateway_, address _owner, address _mobulaToken) AxelarExecutable(gateway_) {
        _transferOwnership(_owner);
        mobulaToken = _mobulaToken;
    }

    /* Getters */

    /**
     * @dev Retrieve all Token listings
     */
    function getTokenListings() external view returns (TokenListing[] memory) {
        return tokenListings;
    }

    /**
     * @dev Retrieve all Token listings in Sorting status
     */
    function getSortingTokenListings() external view returns (TokenListing[] memory) {
        return getTokenListingsWithStatus(ListingStatus.Sorting);
    }

    /**
     * @dev Retrieve all Token listings in Validation status
     */
    function getValidationTokenListings() external view returns (TokenListing[] memory) {
        return getTokenListingsWithStatus(ListingStatus.Validation);
    }

    /**
     * @dev Retrieve all Token listings in a specific status
     * @param status Status of listings to retrieve
     */
    function getTokenListingsWithStatus(ListingStatus status) public view returns (TokenListing[] memory) {
        if (status == ListingStatus.Init) {
            return new TokenListing[](0);
        }

        uint256[] memory voteIds = _getStorageArrayForStatus(status);

        TokenListing[] memory listings = new TokenListing[](voteIds.length);
        for (uint256 i; i < listings.length; i++) {
            listings[i] = tokenListings[voteIds[i]];
        }

        return listings;
    }
    
    /* Users methods */

    /**
     * @dev Allows the submitter of a Token to update Token details
     * @param voteId ID of the Vote to update
     * @param ipfsHash New IPFS hash of the Token
     */
    function updateToken(uint256 voteId, string memory ipfsHash) external {
        _updateToken(voteId, ipfsHash, msg.sender);
    }

    /**
     * @dev Allows a user to submit a Token for validation
     * @param ipfsHash IPFS hash of the Token
     * @param paymentTokenAddress Address of ERC20 stablecoins used to pay for listing
     * @param paymentAmount Amount to be paid (without decimals)
     * @param tokenId ID of the Token to update (if update, 0 otherwise)
     */
    function submitToken(string memory ipfsHash, address paymentTokenAddress, uint256 paymentAmount, uint256 tokenId) external {
        _submitToken(ipfsHash, paymentTokenAddress, paymentAmount, msg.sender, tokenId);
    }

    /**
     * @dev Allows a user to top up listing payment
     * @param voteId ID of the Vote to top up
     * @param paymentTokenAddress Address of ERC20 stablecoins used to pay for listing
     * @param paymentAmount Amount to be paid (without decimals)
     */
    function topUpToken(uint256 voteId, address paymentTokenAddress, uint256 paymentAmount) external {
        _topUpToken(voteId, paymentTokenAddress, paymentAmount, msg.sender);
    }

    /**
     * @dev Claim User rewards
     * @param user User to claim rewards for
     */
    function claimRewards(address user) external {
        uint256 amountToPay = owedRewards[user] * tokensPerVote;
        if (amountToPay == 0) revert NothingToClaim(user);

        paidRewards[user] += amountToPay;
        delete owedRewards[user];

        uint256 moblAmount = amountToPay / PAYMENT_COEFF;

        IERC20(mobulaToken).transfer(user, moblAmount);

        emit RewardsClaimed(user, moblAmount);
    }

    /* Votes */

    /**
     * @dev Allows a ranked user to vote for Token Sorting
     * @param voteId ID of the Vote to vote for
     * @param vote User's vote
     * @param utilityScore Utility score
     * @param socialScore Social score
     * @param trustScore Trust score
     */
    function voteSorting(uint256 voteId, ListingVote vote, uint256 utilityScore, uint256 socialScore, uint256 trustScore)
        external
        onlyRanked
    {
        if (voteId >= tokenListings.length) revert VoteNotFound(voteId);

        TokenListing storage listing = tokenListings[voteId];

        if (listing.status != ListingStatus.Sorting) revert NotSortingListing(listing.token, listing.status);

        if (listing.token.lastUpdate > block.timestamp - voteCooldown) revert TokenInCooldown(listing.token);

        if (sortingVotesPhase[voteId][msg.sender] >= listing.phase) revert AlreadyVoted(msg.sender, listing.status, listing.phase);

        sortingVotesPhase[voteId][msg.sender] = listing.phase;

        if (vote == ListingVote.ModificationsNeeded) {
            sortingModifications[voteId].push(msg.sender);
        } else if (vote == ListingVote.Reject) {
            sortingRejections[voteId].push(msg.sender);
        } else {
            if (utilityScore > 5 || socialScore > 5 || trustScore > 5) revert InvalidScoreValue();

            sortingAcceptances[voteId].push(msg.sender);

            listing.accruedUtilityScore += utilityScore;
            listing.accruedSocialScore += socialScore;
            listing.accruedTrustScore += trustScore;
        }

        emit SortingVote(listing.token, msg.sender, vote, utilityScore, socialScore, trustScore);

        if (sortingModifications[voteId].length * 100 >= sortingMaxVotes * sortingMinModificationsPct) {
            _updateListingStatus(voteId, ListingStatus.Updating);
        } else if (sortingAcceptances[voteId].length + sortingRejections[voteId].length + sortingModifications[voteId].length >= sortingMaxVotes) {
            if (sortingAcceptances[voteId].length * 100 >= sortingMaxVotes * sortingMinAcceptancesPct) {
                _updateListingStatus(voteId, ListingStatus.Validation);
            } else {
                _updateListingStatus(voteId, ListingStatus.Rejected);
            }
        }
    }

    /**
     * @dev Allows a rank II User to vote for Token Validation
     * @param voteId ID of the Token to vote for
     * @param vote User's vote
     * @param utilityScore Utility score
     * @param socialScore Social score
     * @param trustScore Trust score
     */
    function voteValidation(uint256 voteId, ListingVote vote, uint256 utilityScore, uint256 socialScore, uint256 trustScore)
        external
        onlyRankII
    {
        if (voteId >= tokenListings.length) revert VoteNotFound(voteId);

        TokenListing storage listing = tokenListings[voteId];

        if (listing.status != ListingStatus.Validation) revert NotValidationListing(listing.token, listing.status);

        if (validationVotesPhase[voteId][msg.sender] >= listing.phase) revert AlreadyVoted(msg.sender, listing.status, listing.phase);

        validationVotesPhase[voteId][msg.sender] = listing.phase;

        if (vote == ListingVote.ModificationsNeeded) {
            validationModifications[voteId].push(msg.sender);
        } else if (vote == ListingVote.Reject) {
            validationRejections[voteId].push(msg.sender);
        } else {
            if (utilityScore > 5 || socialScore > 5 || trustScore > 5) revert InvalidScoreValue();

            validationAcceptances[voteId].push(msg.sender);

            listing.accruedUtilityScore += utilityScore;
            listing.accruedSocialScore += socialScore;
            listing.accruedTrustScore += trustScore;
        }

        emit ValidationVote(listing.token, msg.sender, vote, utilityScore, socialScore, trustScore);

        if (validationModifications[voteId].length * 100 >= validationMaxVotes * validationMinModificationsPct) {
            _updateListingStatus(voteId, ListingStatus.Updating);
        } else if (validationAcceptances[voteId].length + validationRejections[voteId].length + validationModifications[voteId].length >= validationMaxVotes) {
            if (validationAcceptances[voteId].length * 100 >= validationMaxVotes * validationMinAcceptancesPct) {
                _rewardVoters(voteId, ListingStatus.Validated);

                _saveToken(voteId);

                _updateListingStatus(voteId, ListingStatus.Validated);
            } else {
                _rewardVoters(voteId, ListingStatus.Rejected);

                _updateListingStatus(voteId, ListingStatus.Rejected);
            }
        }
    }

    /* Hierarchy Management */

    /**
     * @dev Allows a Rank II user to vote for a promotion for a Rank I user or below
     * @param promoted Address of the user
     */
    function promote(address promoted) external onlyRankII {
        uint256 rankPromoted = rank[promoted];
        if (rankPromoted > 1) revert RankPromotionImpossible(rankPromoted, 1);

        if (rankPromoted == 0) {
            if (membersToPromoteToRankI == 0) revert NoPromotionYet(1);
            ++promoteVotes[promoted];

            if (promoteVotes[promoted] == votesNeededToRankIPromotion) {
                --membersToPromoteToRankI;
                _promote(promoted);
            }
        } else {
            if (membersToPromoteToRankII == 0) revert NoPromotionYet(2);
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
        if (rankDemoted == 0) revert RankDemotionImpossible(rankDemoted, 1);

        if (rankDemoted == 1) {
            if (membersToDemoteFromRankI == 0) revert NoDemotionYet(1);
            ++demoteVotes[demoted];

            if (demoteVotes[demoted] == votesNeededToRankIDemotion) {
                --membersToDemoteFromRankI;
                _demote(demoted);
            }
        } else {
            if (membersToDemoteFromRankII == 0) revert NoDemotionYet(2);
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
        if (rankPromoted > 1) revert RankPromotionImpossible(rankPromoted, 1);
        _promote(promoted);
    }

    /**
     * @dev Allows the owner to demote a user
     * @param demoted Address of the user
     */
    function emergencyDemote(address demoted) external onlyOwner {
        uint256 rankDemoted = rank[demoted];
        if (rankDemoted == 0) revert RankDemotionImpossible(rankDemoted, 1);
        _demote(demoted);
    }

    /**
     * @dev Allows the owner to remove a Token from the validation process
     * @param voteId ID of the Token
     */
    function emergencyKillRequest(uint256 voteId) external onlyOwner {
        _updateListingStatus(voteId, ListingStatus.Killed);
    }

    /**
     * @dev Allows the owner to change a Token listing status
     * @param voteId ID of the Token
     * @param status New status of the listing
     */
     function emergencyUpdateListingStatus(uint256 voteId, ListingStatus status) external onlyOwner {
        _updateListingStatus(voteId, status);
    }

    /* Protocol Management */

    function whitelistStable(address _stableAddress, bool whitelisted) external onlyOwner {
        whitelistedStable[_stableAddress] = whitelisted;
    }

    function whitelistSubmitter(address _submitter, bool whitelisted) external onlyOwner {
        whitelistedSubmitter[_submitter] = whitelisted;
    }

    function whitelistAxelarContract(string memory _sourceChain, string memory _sourceAddress, bool whitelisted) external onlyOwner {
        whitelistedAxelarContract[_sourceChain][_sourceAddress] = whitelisted;
    }

    function updateProtocolAPIAddress(address _protocolAPI) external onlyOwner {
        protocolAPI = _protocolAPI;
    }

    function updateSubmitFloorPrice(uint256 _submitFloorPrice) external onlyOwner {
        submitFloorPrice = _submitFloorPrice;
    }

    function updateSortingMaxVotes(uint256 _sortingMaxVotes) external onlyOwner {
        sortingMaxVotes = _sortingMaxVotes;
    }

    function updateValidationMaxVotes(uint256 _validationMaxVotes)
        external
        onlyOwner
    {
        validationMaxVotes = _validationMaxVotes;
    }

    function updateEditCoeffMultiplier(uint256 _editCoeffMultiplier)
        external
        onlyOwner
    {
        editCoeffMultiplier = _editCoeffMultiplier;
    }

    function updateSortingMinAcceptancesPct(uint256 _sortingMinAcceptancesPct) external onlyOwner {
        if (_sortingMinAcceptancesPct > 100) revert InvalidPercentage(_sortingMinAcceptancesPct);
        sortingMinAcceptancesPct = _sortingMinAcceptancesPct;
    }

    function updateSortingMinModificationsPct(uint256 _sortingMinModificationsPct) external onlyOwner {
        if (_sortingMinModificationsPct > 100) revert InvalidPercentage(_sortingMinModificationsPct);
        sortingMinModificationsPct = _sortingMinModificationsPct;
    }

    function updateValidationMinAcceptancesPct(uint256 _validationMinAcceptancesPct) external onlyOwner {
        if (_validationMinAcceptancesPct > 100) revert InvalidPercentage(_validationMinAcceptancesPct);
        validationMinAcceptancesPct = _validationMinAcceptancesPct;
    }

    function updateValidationMinModificationsPct(uint256 _validationMinModificationsPct) external onlyOwner {
        if (_validationMinModificationsPct > 100) revert InvalidPercentage(_validationMinModificationsPct);
        validationMinModificationsPct = _validationMinModificationsPct;
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

    function updateWhitelistedCooldown(uint256 _whitelistedCooldown) external onlyOwner {
        whitelistedCooldown = _whitelistedCooldown;
    }

    /* Funds Management */

    /**
     * @dev Withdraw ETH amount to recipient
     * @param recipient The recipient
     * @param amount Amount to withdraw
     */
    function withdrawFunds(address recipient, uint256 amount) external onlyOwner {
        uint256 protocolBalance = address(this).balance;
        if (amount > protocolBalance) revert InsufficientProtocolBalance(protocolBalance, amount);

        (bool success,) = recipient.call{value: amount}("");

        if (!success) revert ETHTransferFailed(recipient);

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

        if (!success) revert ERC20WithdrawFailed(contractAddress, recipient, amount);

        emit ERC20FundsWithdrawn(recipient, contractAddress, amount);
    }

    /* Axelar callback */

    /**
     * @dev Execute a cross chain call from Axelar
     * @param sourceChain Source blockchain
     * @param sourceAddress Source smart contract address
     * @param payload Payload
     */
    function _execute(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) internal override {
        if (!whitelistedAxelarContract[sourceChain][sourceAddress]) revert InvalidAxelarContract(sourceChain, sourceAddress);

        MobulaPayload memory mPayload = abi.decode(payload, (MobulaPayload));
        
        if (mPayload.method == MobulaMethod.SubmitToken) {
            _submitToken(mPayload.ipfsHash, mPayload.paymentTokenAddress, mPayload.paymentAmount, mPayload.sender, mPayload.tokenId);
        } else if (mPayload.method == MobulaMethod.UpdateToken) {
            _updateToken(mPayload.voteId, mPayload.ipfsHash, mPayload.sender);
        } else if (mPayload.method == MobulaMethod.TopUpToken) {
            _topUpToken(mPayload.voteId, mPayload.paymentTokenAddress, mPayload.paymentAmount, mPayload.sender);
        } else {
            revert UnknownMethod(mPayload);
        }
    }

    /* Internal Methods */

    /**
     * @dev Allows the submitter of a Token to update Token details
     * @param voteId ID of the Token to update
     * @param ipfsHash New IPFS hash of the Token
     * @param sourceMsgSender Sender of the tx
     */
    function _updateToken(uint256 voteId, string memory ipfsHash, address sourceMsgSender) internal {
        if (voteId >= tokenListings.length) revert VoteNotFound(voteId);

        TokenListing storage listing = tokenListings[voteId];

        if (listing.status != ListingStatus.Updating) revert NotUpdatingListing(listing.token, listing.status);

        if (listing.submitter != sourceMsgSender) revert InvalidUpdatingUser(sourceMsgSender, listing.submitter);

        listing.token.ipfsHash = ipfsHash;
        listing.token.lastUpdate = block.timestamp;

        emit TokenDetailsUpdated(listing.token);
        
        // We put the Vote back to Sorting (impossible to be in Pool status)
        _updateListingStatus(voteId, ListingStatus.Sorting);
    }
    
    /**
     * @dev Allows a user to submit a Token for validation
     * @param ipfsHash IPFS hash of the Token
     * @param paymentTokenAddress Address of ERC20 stablecoins used to pay for listing
     * @param paymentAmount Amount to be paid (without decimals)
     * @param sourceMsgSender Sender of the tx
     * @param tokenId ID of the Token to update (if update, 0 otherwise)
     */
    function _submitToken(string memory ipfsHash, address paymentTokenAddress, uint256 paymentAmount, address sourceMsgSender, uint256 tokenId)
        internal
    {
        uint256 coeff;
        ListingStatus status = ListingStatus.Pool;

        if (whitelistedSubmitter[sourceMsgSender]) {
            if (whitelistedLastSubmit[sourceMsgSender] > block.timestamp - whitelistedCooldown) revert SubmitterInCooldown(sourceMsgSender);
            whitelistedLastSubmit[sourceMsgSender] = block.timestamp;

            coeff = PAYMENT_COEFF;
        } else if (paymentAmount != 0) {
            // If method was called from another chain
            if (msg.sender != sourceMsgSender) {
                coeff = _getCoeff(paymentAmount);
            } else {
                coeff = _payment(paymentTokenAddress, paymentAmount);
            }
        }

        if (tokenId != 0 && tokenId >= nextTokenId) {
            revert TokenNotFound(tokenId);
        }

        if (tokenId != 0) {
            coeff += PAYMENT_COEFF * editCoeffMultiplier;
        }

        if (coeff >= PAYMENT_COEFF) {
            status = ListingStatus.Sorting;
        }

        Token memory token;
        TokenListing memory listing;

        token.ipfsHash = ipfsHash;
        token.lastUpdate = block.timestamp;
        token.id = tokenId != 0 ? tokenId : nextTokenId;

        listing.token = token;
        listing.coeff = coeff;
        listing.submitter = sourceMsgSender;
        listing.phase = 1;

        tokenListings.push(listing);

        // We are working with a new token, so must update.
        if (tokenId == 0) nextTokenId += 1;

        emit TokenListingSubmitted(sourceMsgSender, listing);
        
        _updateListingStatus(tokenListings.length - 1, status);
    }

    /**
     * @dev Allows a user to top up listing payment
     * @param voteId ID of the Vote to top up
     * @param paymentTokenAddress Address of ERC20 stablecoins used to pay for listing
     * @param paymentAmount Amount to be paid (without decimals)
     * @param sourceMsgSender Sender of the tx
     */
    function _topUpToken(uint256 voteId, address paymentTokenAddress, uint256 paymentAmount, address sourceMsgSender) internal {
        if (voteId >= tokenListings.length) revert VoteNotFound(voteId);
        if (paymentAmount == 0) revert InvalidPaymentAmount();

        // If method was called from another chain
        if (msg.sender != sourceMsgSender) {
            tokenListings[voteId].coeff += _getCoeff(paymentAmount);
        } else {
            tokenListings[voteId].coeff += _payment(paymentTokenAddress, paymentAmount);
        }

        emit TokenListingFunded(sourceMsgSender, tokenListings[voteId], paymentAmount);

        if (tokenListings[voteId].status == ListingStatus.Pool && tokenListings[voteId].coeff >= PAYMENT_COEFF) {
            _updateListingStatus(voteId, ListingStatus.Sorting);
        }
    }

    /**
     * @dev Update the status of a listing, by moving the listing/token index from one status array to another one
     * @param voteId ID of the Token to vote for
     * @param status New listing status
     */
    function _updateListingStatus(uint256 voteId, ListingStatus status) internal {
        TokenListing storage listing = tokenListings[voteId];

        if (status == ListingStatus.Init) revert InvalidStatusUpdate(listing.token, listing.status, status);

        if (listing.status != ListingStatus.Init) {
            // Can only be updated to Pool status, if current status is Init
            if (status == ListingStatus.Pool) revert InvalidStatusUpdate(listing.token, listing.status, status);

            // Remove listing from current status array
            uint256[] storage fromArray = _getStorageArrayForStatus(listing.status);
            uint256 indexMovedListing = fromArray[fromArray.length - 1];
            fromArray[listing.statusIndex] = indexMovedListing;
            tokenListings[indexMovedListing].statusIndex = listing.statusIndex;
            fromArray.pop();
        }

        // Add listing to new status array
        uint256[] storage toArray = _getStorageArrayForStatus(status);
        listing.statusIndex = toArray.length;
        toArray.push(voteId);

        ListingStatus previousStatus = listing.status;
        listing.status = status;

        // For these status, we need to reset all votes and scores of the listing
        if (status == ListingStatus.Updating || status == ListingStatus.Rejected || status == ListingStatus.Validated || status == ListingStatus.Killed) {
            // Increment listing phase, so voters will be able to vote again on this listing
            if (status == ListingStatus.Updating) {
                ++listing.phase;
            }

            delete listing.accruedUtilityScore;
            delete listing.accruedSocialScore;
            delete listing.accruedTrustScore;

            delete sortingAcceptances[voteId];
            delete sortingRejections[voteId];
            delete sortingModifications[voteId];
            delete validationAcceptances[voteId];
            delete validationRejections[voteId];
            delete validationModifications[voteId];
        }

        emit ListingStatusUpdated(listing.token, previousStatus, status);
    }

    /**
     * @dev Retrieve status' corresponding storage array
     * @param status Status
     */
    function _getStorageArrayForStatus(ListingStatus status) internal view returns (uint256[] storage) {
        uint256[] storage array = poolListings;
        if (status == ListingStatus.Updating) {
            array = updatingListings;
        } else if (status == ListingStatus.Sorting) {
            array = sortingListings;
        } else if (status == ListingStatus.Validation) {
            array = validationListings;
        } else if (status == ListingStatus.Validated) {
            array = validatedListings;
        } else if (status == ListingStatus.Rejected) {
            array = rejectedListings;
        } else if (status == ListingStatus.Killed) {
            array = killedListings;
        }
        return array;
    }

    /**
     * @dev Save Token in Protocol API
     * @param voteId ID of the Vote to save
     */
    function _saveToken(uint256 voteId) internal {
        TokenListing storage listing = tokenListings[voteId];

        uint256 scoresCount = sortingAcceptances[voteId].length + validationAcceptances[voteId].length;

        // TODO : Handle float value (x10 then round() / 10 ?)
        listing.token.utilityScore = listing.accruedUtilityScore / scoresCount;
        listing.token.socialScore = listing.accruedSocialScore / scoresCount;
        listing.token.trustScore = listing.accruedTrustScore / scoresCount;
        
        IAPI(protocolAPI).addAssetData(listing.token);

        emit TokenValidated(listing.token);
    }

    /**
     * @dev Reward voters of a Token listing process
     * @param voteId ID of the Token
     * @param finalStatus Final status of the listing
     */
    function _rewardVoters(uint256 voteId, ListingStatus finalStatus) internal {
        uint256 coeff = tokenListings[voteId].coeff;

        for (uint256 i; i < sortingAcceptances[voteId].length; i++) {
            if (finalStatus == ListingStatus.Validated) {
                ++goodSortingVotes[sortingAcceptances[voteId][i]];
                owedRewards[sortingAcceptances[voteId][i]] += coeff;
            } else {
                ++badSortingVotes[sortingAcceptances[voteId][i]];
            }
        }
        
        for (uint256 i; i < sortingRejections[voteId].length; i++) {
            if (finalStatus == ListingStatus.Rejected) {
                ++goodSortingVotes[sortingRejections[voteId][i]];
                owedRewards[sortingRejections[voteId][i]] += coeff;
            } else {
                ++badSortingVotes[sortingRejections[voteId][i]];
            }
        }

        for (uint256 i; i < validationAcceptances[voteId].length; i++) {
            if (finalStatus == ListingStatus.Validated) {
                ++goodValidationVotes[validationAcceptances[voteId][i]];
                owedRewards[validationAcceptances[voteId][i]] += coeff * 2;
            } else {
                ++badValidationVotes[validationAcceptances[voteId][i]];
            }
        }

        for (uint256 i; i < validationRejections[voteId].length; i++) {
            if (finalStatus == ListingStatus.Rejected) {
                ++goodValidationVotes[validationRejections[voteId][i]];
                owedRewards[validationRejections[voteId][i]] += coeff * 2;
            } else {
                ++badValidationVotes[validationRejections[voteId][i]];
            }
        }
    }

    /**
     * @dev Make the payment from user
     * @param paymentTokenAddress Address of ERC20 stablecoins used to pay for listing
     * @param paymentAmount Amount to be paid (without decimals)
     * @return coeff Coeff to add to the listing
     */
    function _payment(address paymentTokenAddress, uint256 paymentAmount) internal returns (uint256 coeff) {
        if (!whitelistedStable[paymentTokenAddress]) revert InvalidPaymentToken(paymentTokenAddress);

        IERC20Extended paymentToken = IERC20Extended(paymentTokenAddress);
        uint256 amount = paymentAmount * 10**paymentToken.decimals();
        bool success = paymentToken.transferFrom(msg.sender, address(this), amount);

        if (!success) revert TokenPaymentFailed(paymentTokenAddress, amount);

        coeff = _getCoeff(paymentAmount);
    }

    /**
     * @dev Get the coeff for a payment amount
     * @param paymentAmount Amount paid (without decimals)
     * @return coeff Coeff to add to the listing
     */
    function _getCoeff(uint256 paymentAmount) internal view returns (uint256 coeff) {
        coeff = (paymentAmount * PAYMENT_COEFF) / submitFloorPrice;
    }

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