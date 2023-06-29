// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@axelar/contracts/executable/AxelarExecutable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./AxelarStructs.sol";

contract AxelarReceiver is AxelarExecutable {

    constructor(address gateway_) AxelarExecutable(gateway_) {}

    event UpdateTokenRequested(uint256 tokenId, string ipfsHash, address sourceSender);
    event SubmitTokenRequested(string ipfsHash, address paymentTokenAddress, uint256 paymentAmount, address sourceSender);
    event TopUpTokenRequested(uint256 tokenId, address paymentTokenAddress, uint256 paymentAmount, address sourceSender);

    function _executeWithToken(
        string calldata,
        string calldata,
        bytes calldata payload,
        string calldata tokenSymbol,
        uint256 amount
    ) internal override {
        address tokenAddress = gateway.tokenAddresses(tokenSymbol);

        MobulaPayload memory mPayload = abi.decode(payload, (MobulaPayload));

        if (mPayload.method == MobulaMethod.SubmitToken) {
            _submitTokenAxelar(mPayload.ipfsHash, tokenAddress, amount, mPayload.sender);
        } else if (mPayload.method == MobulaMethod.UpdateToken) {
            _updateTokenAxelar(mPayload.tokenId, mPayload.ipfsHash, mPayload.sender);
        } else if (mPayload.method == MobulaMethod.TopUpToken) {
            _topUpTokenAxelar(mPayload.tokenId, tokenAddress, amount, mPayload.sender);
        }
    }

    function _execute(
        string calldata,
        string calldata,
        bytes calldata payload
    ) internal override {
        MobulaPayload memory mPayload = abi.decode(payload, (MobulaPayload));
        
        if (mPayload.method == MobulaMethod.SubmitToken) {
            _submitTokenAxelar(mPayload.ipfsHash, address(0), 0, mPayload.sender);
        } else if (mPayload.method == MobulaMethod.UpdateToken) {
            _updateTokenAxelar(mPayload.tokenId, mPayload.ipfsHash, mPayload.sender);
        }
    }

    function _updateTokenAxelar(uint256 tokenId, string memory ipfsHash, address sourceMsgSender) internal {
        emit UpdateTokenRequested(tokenId, ipfsHash, sourceMsgSender);
    }
    
    function _submitTokenAxelar(string memory ipfsHash, address paymentTokenAddress, uint256 paymentAmount, address sourceMsgSender)
        internal
    {
        emit SubmitTokenRequested(ipfsHash, paymentTokenAddress, paymentAmount, sourceMsgSender);
    }

    function _topUpTokenAxelar(uint256 tokenId, address paymentTokenAddress, uint256 paymentAmount, address sourceMsgSender) internal {
        emit TopUpTokenRequested(tokenId, paymentTokenAddress, paymentAmount, sourceMsgSender);
    }
}