// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract API {
    address public protocol;
    address public owner;

    mapping(address => string) public staticData;
    mapping(address => uint256) public tokenAssetId;
    Token[] public assets;
    mapping(uint256 => Token) public assetById;

    struct Token {
        string ipfsHash;
        address[] contractAddresses;
        uint256 id;
        address[] totalSupply;
        address[] excludedFromCirculation;
        uint256 lastUpdate;
        uint256 utilityScore;
        uint256 socialScore;
        uint256 trustScore;
        uint256 marketScore;
    }

    event NewListing(address indexed token, string ipfsHash);

    event NewAssetListing(Token token);

    constructor(address _protocol, address _owner) {
        protocol = _protocol;
        owner = _owner;
    }

    function getAllAssets() external view returns (Token[] memory) {
        return assets;
    }

    function addStaticData(
        address token,
        string memory ipfsHash,
        uint256 assetId
    ) external {
        require(
            protocol == msg.sender || owner == msg.sender,
            "Only the DAO or the Protocol can add data."
        );
        staticData[token] = ipfsHash;
        tokenAssetId[token] = assetId;
        emit NewListing(token, ipfsHash);
    }

    function addAssetData(Token memory token) external {
        require(
            protocol == msg.sender || owner == msg.sender,
            "Only the DAO or the Protocol can add data."
        );
        assets.push(token);
        assetById[token.id] = token;

        for (uint256 i = 0; i < token.contractAddresses.length; i++) {
            staticData[token.contractAddresses[i]] = token.ipfsHash;
        }

        emit NewAssetListing(token);
    }

    function removeStaticData(address token) external {
        require(owner == msg.sender);
        delete staticData[token];
    }

    function setProtocolAddress(address _protocol) external {
        require(
            owner == msg.sender,
            "Only the DAO can modify the Protocol address."
        );
        protocol = _protocol;
    }
}
