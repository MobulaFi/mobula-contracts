// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable2Step.sol";

import "./lib/TokenStructs.sol";

contract API is Ownable2Step {
    address public protocol;

    error NotProtocolOrOwner(address account);

    mapping(address => string) public staticData;
    mapping(address => uint256) public tokenAssetId;
    Token[] public assets;
    mapping(uint256 => Token) public assetById;

    event NewListing(address indexed token, string ipfsHash);

    event NewAssetListing(Token token);

    modifier onlyProtocolAndOwner() {
        if (protocol != msg.sender && owner() != msg.sender) {
            revert NotProtocolOrOwner(msg.sender);
        }
        _;
    }

    constructor(address _protocol, address _owner) {
        protocol = _protocol;
        _transferOwnership(_owner);
    }

    function getAllAssets() external view returns (Token[] memory) {
        return assets;
    }

    function addStaticData(
        address token,
        string memory ipfsHash,
        uint256 assetId
    ) external onlyProtocolAndOwner {
        staticData[token] = ipfsHash;
        tokenAssetId[token] = assetId;
        emit NewListing(token, ipfsHash);
    }

    function addAssetData(Token memory token) external onlyProtocolAndOwner {
        assets.push(token);
        assetById[token.id] = token;

        // TODO : Refacto
        // for (uint256 i = 0; i < token.contractAddresses.length; i++) {
        //     staticData[token.contractAddresses[i]] = token.ipfsHash;
        // }

        emit NewAssetListing(token);
    }

    function removeStaticData(address token) external onlyOwner {
        delete staticData[token];
    }

    function setProtocolAddress(address _protocol) external onlyOwner {
        protocol = _protocol;
    }
}
