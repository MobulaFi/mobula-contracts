// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @dev Token struct to define Token informations
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

/*
    IDEAS :
    - Use same Struct in TokensProtocol and API ?
        - Remove coeff from the struct
        -> coeff is stored in the struct but not use in API, scores aren't stored in the struct but use in API -> inconsistent
    - Add state ? init / pending / validated / need modifications

*/