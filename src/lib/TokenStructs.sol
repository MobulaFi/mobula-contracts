// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;


/**
* @dev Enum to define Token status
* @custom:Pool Initial Token status 
* @custom:FirstSort RankI users can vote for this Token
* @custom:FinalValidation RankII users can vote to validate this Token
* @custom:Validated Token has been validated and listed
*/
enum TokenStatus {
    Pool,
    FirstSort,
    FinalValidation,
    Validated
}

/**
 * @custom:ipfsHash IPFS Hash of metadatas
 * @custom:id Attributed ID for the Token
 * @custom:lastUpdate Timestamp of Token's last update
 * @custom:utilityScore Token's utility score
 * @custom:socialScore Token's social score
 * @custom:trustScore Token's trust score
 */
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
 * @custom:coeff Token coeff
 * @custom:status Token status
 */
struct TokenListing {
    Token token;
    uint256 coeff;
    TokenStatus status;
} 