// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

enum MobulaMethod {
    SubmitToken,
    UpdateToken,
    TopUpToken
}

struct MobulaPayload {
    MobulaMethod method;
    address sender;
    string ipfsHash;
    uint256 tokenId;
}