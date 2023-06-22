// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;


/**
* @dev Enum to define a listing vote
* @custom:Accept Accept the Token
* @custom:Reject Reject the Token
* @custom:ModificationsNeeded Token needs modifications
*/
enum ListingVote {
    // TODO : Add an init state ?
    Accept,
    Reject,
    ModificationsNeeded
}

/**
* @dev Enum to define Listing status
* @custom:Init Initial Listing status
* @custom:Pool Token has been submitted
* @custom:Updating Submitter needs to update Token details
* @custom:Sorting RankI users can vote to sort this Token
* @custom:Validation RankII users can vote to validate this Token
* @custom:Validated Token has been validated and listed
* @custom:Rejected Token has been rejected
*/
enum ListingStatus {
    Init,
    Pool,
    Updating,
    Sorting,
    Validation,
    Validated,
    Rejected
}

/**
 * @custom:ipfsHash IPFS Hash of metadatas
 * @custom:id Attributed ID for the Token
 * @custom:lastUpdate Timestamp of Token's last update
 * @custom:utilityScore Token's utility score
 * @custom:socialScore Token's social score
 * @custom:trustScore Token's trust score
 */
// TODO : Use uint8 score type ?
struct Token {
    string ipfsHash;
    uint256 id;
    uint256 lastUpdate;
    uint256 utilityScore;
    uint256 socialScore;
    uint256 trustScore;
}

/**
 * @custom:token Token
 * @custom:coeff Listing coeff
 * @custom:status Listing status
 * @custom:submitter User who submitted the Token for listing
 * @custom:statusIndex Index of listing in corresponding statusArray
 * @custom:accruedUtilityScore Sum of voters utility score
 * @custom:accruedSocialScore Sum of voters social score
 * @custom:accruedTrustScore Sum of voters trust score
 * @custom:phase Phase count
 */
// TODO : Reorg for gas effiency 
struct TokenListing {
    Token token;
    uint256 coeff;
    ListingStatus status;
    address submitter;
    uint256 statusIndex;

    uint256 accruedUtilityScore;
    uint256 accruedSocialScore;
    uint256 accruedTrustScore;

    uint256 phase;
}