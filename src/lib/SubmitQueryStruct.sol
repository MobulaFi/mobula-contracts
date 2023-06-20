// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @dev SubmitQuery struct to define Token informations
 * @custom:ipfsHash IPFS Hash of metadatas
 * @custom:contractAddresses Array of smart contract addresses related to the Token
 * @custom:id Attributed ID for the Token
 * @custom:totalSupply Addresses that allows to retrive Token's total supply
 * @custom:excludedFromCirculation Addresses that allows to retrive Token's amount excluded from circulation
 * @custom:lastUpdate Timestamp of Token's last update
 * @custom:utilityScore Token's utility score
 * @custom:socialScore Token's social score
 * @custom:trustScore Token's trust score
 * @custom:coeff Token's coeff -> directly related to amount paid
 */
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
    IDEAS :
    - Use same Struct in TokensProtocol and API ?
        - Remove coeff from the struct
        -> coeff is stored in the struct but not use in API, scores aren't stored in the struct but use in API -> inconsistent
    - Add state ? init / pending / validated / need modifications

*/