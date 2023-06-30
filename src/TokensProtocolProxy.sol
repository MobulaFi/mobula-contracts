// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";

import "./interfaces/IAPI.sol";
import "./interfaces/IERC20Extended.sol";

import "./lib/ProtocolErrors.sol";
import "./lib/TokenStructs.sol";

/*
    SUGGESTIONS :
    - Add a cooldown for whitelisted submitters
        -> MOBL could be farmed by malicious whitelisted submitters
    - Init ProtocolAPI at launch
    - Pausable ?
    - Owner should be able to force status change (for example, if listing already paid elsewhere)

    QUESTIONS :
    - When update token.lastUpdate ?
    - Can somebody pay with MATIC ? Why does the user can chose assetId ?

*/

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
     * @dev whitelistedSubmitter Does this user needs to pay for a Token submission
     */
    mapping(address => bool) public whitelistedSubmitter;

    /**
     * @dev submitFloorPrice Minimim price to pay for a listing
     */
    uint256 public submitFloorPrice;

    /**
     * @dev tokenListings All Token Listings
     */
    TokenListing[] public tokenListings;

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
    event RewardsClaimed(address indexed claimer, uint256 amount);
    event FundsWithdrawn(address indexed recipient, uint256 amount);
    event UserPromoted(address indexed promoted, uint256 newRank);
    event UserDemoted(address indexed demoted, uint256 newRank);
    event ListingStatusUpdated(Token token, ListingStatus previousStatus, ListingStatus newStatus);
    event SortingVote(Token token, address voter, ListingVote vote, uint256 utilityScore, uint256 socialScore, uint256 trustScore);
    event ValidationVote(Token token, address voter, ListingVote vote, uint256 utilityScore, uint256 socialScore, uint256 trustScore);
    event TokenValidated(Token token);

    function initialize(address _owner, address _mobulaToken)
        public
        initializer
    {
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

        uint256[] memory tokenIds = _getStorageArrayForStatus(status);

        TokenListing[] memory listings = new TokenListing[](tokenIds.length);
        for (uint256 i; i < listings.length; i++) {
            listings[i] = tokenListings[tokenIds[i]];
        }

        return listings;
    }
    
    /* Users methods */

    /**
     * @dev Allows the submitter of a Token to update Token details
     * @param tokenId ID of the Token to update
     * @param ipfsHash New IPFS hash of the Token
     */
    function updateToken(uint256 tokenId, string memory ipfsHash) external {
        if (tokenId >= tokenListings.length) {
            revert TokenNotFound(tokenId);
        }

        TokenListing storage listing = tokenListings[tokenId];

        if (listing.status != ListingStatus.Updating) {
            revert NotUpdatingListing(listing.token, listing.status);
        }

        if (listing.submitter != msg.sender) {
            revert InvalidUpdatingUser(msg.sender, listing.submitter);
        }

        listing.token.ipfsHash = ipfsHash;
        listing.token.lastUpdate = block.timestamp;

        emit TokenDetailsUpdated(listing.token);
        
        // We put the Token back to Sorting (impossible to be in Pool status)
        _updateListingStatus(tokenId, ListingStatus.Sorting);
    }

    /**
     * @dev Allows a user to submit a Token for validation
     * @param ipfsHash IPFS hash of the Token
     * @param paymentTokenAddress Address of ERC20 stablecoins used to pay for listing
     * @param paymentAmount Amount to be paid (without decimals)
     */
    function submitToken(string memory ipfsHash, address paymentTokenAddress, uint256 paymentAmount)
        external
    {
        uint256 coeff;
        ListingStatus status = ListingStatus.Pool;

        if (whitelistedSubmitter[msg.sender]) {
            coeff = PAYMENT_COEFF;
        } else if (paymentAmount != 0) {
            coeff = _payment(paymentTokenAddress, paymentAmount);
        }

        if (coeff >= PAYMENT_COEFF) {
            status = ListingStatus.Sorting;
        }

        Token memory token;
        token.ipfsHash = ipfsHash;
        token.lastUpdate = block.timestamp;
        
        TokenListing memory listing;
        listing.token = token;
        listing.coeff = coeff;
        listing.submitter = msg.sender;
        listing.phase = 1;

        tokenListings.push(listing);
        token.id = tokenListings.length - 1;

        _updateListingStatus(token.id, status);

        emit TokenListingSubmitted(msg.sender, listing);
    }

    /**
     * @dev Allows a user to top up listing payment
     * @param tokenId ID of the Token to top up
     * @param paymentTokenAddress Address of ERC20 stablecoins used to pay for listing
     * @param paymentAmount Amount to be paid (without decimals)
     */
    function topUpToken(uint256 tokenId, address paymentTokenAddress, uint256 paymentAmount) external {
        if (tokenId >= tokenListings.length) {
            revert TokenNotFound(tokenId);
        }
        if (paymentAmount == 0) {
            revert InvalidPaymentAmount();
        }

        tokenListings[tokenId].coeff += _payment(paymentTokenAddress, paymentAmount);

        // TODO : Event ?

        if (tokenListings[tokenId].status == ListingStatus.Pool && tokenListings[tokenId].coeff >= PAYMENT_COEFF) {
            _updateListingStatus(tokenId, ListingStatus.Sorting);
        }
    }

    /**
     * @dev Claim User rewards
     * @param user User to claim rewards for
     */
    function claimRewards(address user) external {
        uint256 amountToPay = owedRewards[user] * tokensPerVote;
        if (amountToPay == 0) {
            revert NothingToClaim(user);
        }

        paidRewards[user] += amountToPay;
        delete owedRewards[user];

        uint256 moblAmount = amountToPay / PAYMENT_COEFF;

        IERC20(mobulaToken).transfer(user, moblAmount);

        emit RewardsClaimed(user, moblAmount);
    }

    /* Axelar callbacks */

    // TODO : add Axelar submitHandler

    /* Votes */

    /**
     * @dev Allows a ranked user to vote for Token Sorting
     * @param tokenId ID of the Token to vote for
     * @param vote User's vote
     * @param utilityScore Utility score
     * @param socialScore Social score
     * @param trustScore Trust score
     */
    function voteSorting(uint256 tokenId, ListingVote vote, uint256 utilityScore, uint256 socialScore, uint256 trustScore)
        external
        onlyRanked
    {
        if (tokenId >= tokenListings.length) {
            revert TokenNotFound(tokenId);
        }
        TokenListing storage listing = tokenListings[tokenId];

        if (listing.status != ListingStatus.Sorting) {
            revert NotSortingListing(listing.token, listing.status);
        }

        if (listing.token.lastUpdate > block.timestamp - voteCooldown) {
            revert TokenInCooldown(listing.token);
        }

        if (sortingVotesPhase[tokenId][msg.sender] >= listing.phase) {
            revert AlreadyVoted(msg.sender, listing.status, listing.phase);
        }

        sortingVotesPhase[tokenId][msg.sender] = listing.phase;

        if (vote == ListingVote.ModificationsNeeded) {
            sortingModifications[tokenId].push(msg.sender);
        } else if (vote == ListingVote.Reject) {
            sortingRejections[tokenId].push(msg.sender);
        } else {
            if (utilityScore > 5 || socialScore > 5 || trustScore > 5) {
                revert InvalidScoreValue();
            }

            sortingAcceptances[tokenId].push(msg.sender);

            listing.accruedUtilityScore += utilityScore;
            listing.accruedSocialScore += socialScore;
            listing.accruedTrustScore += trustScore;
        }

        emit SortingVote(listing.token, msg.sender, vote, utilityScore, socialScore, trustScore);

        if (sortingModifications[tokenId].length * 100 >= sortingMaxVotes * sortingMinModificationsPct) {
            _updateListingStatus(tokenId, ListingStatus.Updating);
        } else if (sortingAcceptances[tokenId].length + sortingRejections[tokenId].length + sortingModifications[tokenId].length >= sortingMaxVotes) {
            if (sortingAcceptances[tokenId].length * 100 >= sortingMaxVotes * sortingMinAcceptancesPct) {
                _updateListingStatus(tokenId, ListingStatus.Validation);
            } else {
                _updateListingStatus(tokenId, ListingStatus.Rejected);
            }
        }
    }

    /**
     * @dev Allows a rank II User to vote for Token Validation
     * @param tokenId ID of the Token to vote for
     * @param vote User's vote
     * @param utilityScore Utility score
     * @param socialScore Social score
     * @param trustScore Trust score
     */
    function voteValidation(uint256 tokenId, ListingVote vote, uint256 utilityScore, uint256 socialScore, uint256 trustScore)
        external
        onlyRankII
    {
        if (tokenId >= tokenListings.length) {
            revert TokenNotFound(tokenId);
        }
        TokenListing storage listing = tokenListings[tokenId];

        if (listing.status != ListingStatus.Validation) {
            revert NotValidationListing(listing.token, listing.status);
        }

        if (validationVotesPhase[tokenId][msg.sender] >= listing.phase) {
            revert AlreadyVoted(msg.sender, listing.status, listing.phase);
        }

        validationVotesPhase[tokenId][msg.sender] = listing.phase;

        if (vote == ListingVote.ModificationsNeeded) {
            validationModifications[tokenId].push(msg.sender);
        } else if (vote == ListingVote.Reject) {
            validationRejections[tokenId].push(msg.sender);
        } else {
            if (utilityScore > 5 || socialScore > 5 || trustScore > 5) {
                revert InvalidScoreValue();
            }

            validationAcceptances[tokenId].push(msg.sender);

            listing.accruedUtilityScore += utilityScore;
            listing.accruedSocialScore += socialScore;
            listing.accruedTrustScore += trustScore;
        }

        emit ValidationVote(listing.token, msg.sender, vote, utilityScore, socialScore, trustScore);

        if (validationModifications[tokenId].length * 100 >= validationMaxVotes * validationMinModificationsPct) {
            _updateListingStatus(tokenId, ListingStatus.Updating);
        } else if (validationAcceptances[tokenId].length + validationRejections[tokenId].length + validationModifications[tokenId].length >= validationMaxVotes) {
            if (validationAcceptances[tokenId].length * 100 >= validationMaxVotes * validationMinAcceptancesPct) {
                _rewardVoters(tokenId, ListingStatus.Validated);

                _saveToken(tokenId);

                _updateListingStatus(tokenId, ListingStatus.Validated);
            } else {
                _rewardVoters(tokenId, ListingStatus.Rejected);

                _updateListingStatus(tokenId, ListingStatus.Rejected);
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
        _demote(demoted);
    }

    /**
     * @dev Allows the owner to remove a Token from the validation process
     * @param tokenId ID of the Token
     */
    function emergencyKillRequest(uint256 tokenId) external onlyOwner {
        _updateListingStatus(tokenId, ListingStatus.Killed);
    }

    /* Protocol Management */
    // TODO : Add NatSpec
    function toggleWhitelistedStable(address _stableAddress) external onlyOwner {
        whitelistedStable[_stableAddress] = !whitelistedStable[_stableAddress];
    }

    function toggleWhitelistedSubmitter(address _submitter) external onlyOwner {
        whitelistedSubmitter[_submitter] = !whitelistedSubmitter[_submitter];
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

    function updateSortingMinAcceptancesPct(uint256 _sortingMinAcceptancesPct) external onlyOwner {
        if (_sortingMinAcceptancesPct > 100) {
            revert InvalidPercentage(_sortingMinAcceptancesPct);
        }
        sortingMinAcceptancesPct = _sortingMinAcceptancesPct;
    }

    function updateSortingMinModificationsPct(uint256 _sortingMinModificationsPct) external onlyOwner {
        if (_sortingMinModificationsPct > 100) {
            revert InvalidPercentage(_sortingMinModificationsPct);
        }
        sortingMinModificationsPct = _sortingMinModificationsPct;
    }

    function updateValidationMinAcceptancesPct(uint256 _validationMinAcceptancesPct) external onlyOwner {
        if (_validationMinAcceptancesPct > 100) {
            revert InvalidPercentage(_validationMinAcceptancesPct);
        }
        validationMinAcceptancesPct = _validationMinAcceptancesPct;
    }

    function updateValidationMinModificationsPct(uint256 _validationMinModificationsPct) external onlyOwner {
        if (_validationMinModificationsPct > 100) {
            revert InvalidPercentage(_validationMinModificationsPct);
        }
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
        // TODO : Event ?
    }

    /* Internal Methods */

    /**
     * @dev Update the status of a listing, by moving the listing/token index from one status array to another one
     * @param tokenId ID of the Token to vote for
     * @param status New listing status
     */
    function _updateListingStatus(uint256 tokenId, ListingStatus status) internal {
        TokenListing storage listing = tokenListings[tokenId];

        if (status == ListingStatus.Init) {
            revert InvalidStatusUpdate(listing.token, listing.status, status);
        }

        if (listing.status != ListingStatus.Init) {
            // Can only be updated to Pool status, if current status is Init
            if (status == ListingStatus.Pool) {
                revert InvalidStatusUpdate(listing.token, listing.status, status);
            }
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
        toArray.push(tokenId);

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

            delete sortingAcceptances[tokenId];
            delete sortingRejections[tokenId];
            delete sortingModifications[tokenId];
            delete validationAcceptances[tokenId];
            delete validationRejections[tokenId];
            delete validationModifications[tokenId];
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
     * @param tokenId ID of the Token to save
     */
    function _saveToken(uint256 tokenId) internal {
        TokenListing storage listing = tokenListings[tokenId];

        uint256 scoresCount = sortingAcceptances[tokenId].length + validationAcceptances[tokenId].length;

        // TODO : Handle float value (x10 then round() / 10 ?)
        listing.token.utilityScore = listing.accruedUtilityScore / scoresCount;
        listing.token.socialScore = listing.accruedSocialScore / scoresCount;
        listing.token.trustScore = listing.accruedTrustScore / scoresCount;
        
        IAPI(protocolAPI).addAssetData(listing.token);

        emit TokenValidated(listing.token);
    }

    /**
     * @dev Reward voters of a Token listing process
     * @param tokenId ID of the Token
     * @param finalStatus Final status of the listing
     */
    function _rewardVoters(uint256 tokenId, ListingStatus finalStatus) internal {
        uint256 coeff = tokenListings[tokenId].coeff;

        for (uint256 i; i < sortingAcceptances[tokenId].length; i++) {
            if (finalStatus == ListingStatus.Validated) {
                ++goodSortingVotes[sortingAcceptances[tokenId][i]];
                owedRewards[sortingAcceptances[tokenId][i]] += coeff;
            } else {
                ++badSortingVotes[sortingAcceptances[tokenId][i]];
            }
        }
        
        for (uint256 i; i < sortingRejections[tokenId].length; i++) {
            if (finalStatus == ListingStatus.Rejected) {
                ++goodSortingVotes[sortingRejections[tokenId][i]];
                owedRewards[sortingRejections[tokenId][i]] += coeff;
            } else {
                ++badSortingVotes[sortingRejections[tokenId][i]];
            }
        }

        for (uint256 i; i < validationAcceptances[tokenId].length; i++) {
            if (finalStatus == ListingStatus.Validated) {
                ++goodValidationVotes[validationAcceptances[tokenId][i]];
                owedRewards[validationAcceptances[tokenId][i]] += coeff * 2;
            } else {
                ++badValidationVotes[validationAcceptances[tokenId][i]];
            }
        }

        for (uint256 i; i < validationRejections[tokenId].length; i++) {
            if (finalStatus == ListingStatus.Rejected) {
                ++goodValidationVotes[validationRejections[tokenId][i]];
                owedRewards[validationRejections[tokenId][i]] += coeff * 2;
            } else {
                ++badValidationVotes[validationRejections[tokenId][i]];
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
        if (!whitelistedStable[paymentTokenAddress]) {
            revert InvalidPaymentToken(paymentTokenAddress);
        }

        IERC20Extended paymentToken = IERC20Extended(paymentTokenAddress);
        uint256 amount = paymentAmount * 10**paymentToken.decimals();
        bool success = paymentToken.transferFrom(msg.sender, address(this), amount);

        if (!success) {
            revert TokenPaymentFailed(paymentTokenAddress, amount);
        }

        // TODO : How is it handled if stablecoins have different decimals count
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