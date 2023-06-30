// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@axelar/contracts/executable/AxelarExecutable.sol";
import "@axelar/contracts/interfaces/IAxelarGasService.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./AxelarStructs.sol";

import "../lib/ProtocolErrors.sol";
import "../interfaces/IERC20Extended.sol";

/*
    TODOs :
    - How to link payment and token/user ?

*/

contract AxelarSender is AxelarExecutable, Ownable {
    IAxelarGasService public immutable gasService;

    /**
     * @dev whitelistedStable Does an ERC20 stablecoin is whitelisted as listing payment
     */
    mapping(address => bool) public whitelistedStable;

    string public destinationChain;
    string public destinationAddress;

    constructor(address gateway_, address gasReceiver_) AxelarExecutable(gateway_) {
        gasService = IAxelarGasService(gasReceiver_);
    }

    function whitelistStable(address _stableAddress, bool whitelisted) external onlyOwner {
        whitelistedStable[_stableAddress] = whitelisted;
    }

    function setDestination(string memory _destinationChain, string memory _destinationAddress) external onlyOwner {
        destinationChain = _destinationChain;
        destinationAddress = _destinationAddress;
    }

    function updateTokenAxelar(uint256 tokenId, string memory ipfsHash) external payable {
        require(msg.value > 0, 'Gas payment is required');

        bytes memory payload = abi.encode(MobulaPayload(MobulaMethod.UpdateToken, msg.sender, address(0), ipfsHash, tokenId, 0));

        _sendCrosschain(payload);
    }
    
    function submitTokenAxelar(string memory ipfsHash, address paymentTokenAddress, uint256 paymentAmount) external payable
    {
        require(msg.value > 0, 'Gas payment is required');

        if (paymentAmount != 0) {
            _payment(paymentTokenAddress, paymentAmount);
        }

        bytes memory payload = abi.encode(MobulaPayload(MobulaMethod.SubmitToken, msg.sender, paymentTokenAddress, ipfsHash, 0, paymentAmount));

        _sendCrosschain(payload);
    }

    function topUpTokenAxelar(uint256 tokenId, address paymentTokenAddress, uint256 paymentAmount) external payable {
        require(msg.value > 0, 'Gas payment is required');

        if (paymentAmount != 0) {
            _payment(paymentTokenAddress, paymentAmount);
        }

        bytes memory payload = abi.encode(MobulaPayload(MobulaMethod.TopUpToken, msg.sender, paymentTokenAddress, "", tokenId, paymentAmount));

        _sendCrosschain(payload);
    }

    function revertAxelar(string memory message) external payable {
        require(msg.value > 0, 'Gas payment is required');

        bytes memory payload = abi.encode(MobulaPayload(MobulaMethod.TestRevert, msg.sender, address(0), message, 0, 0));

        _sendCrosschain(payload);
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
    }

    /* Internal Methods */

    function _sendCrosschain(bytes memory payload) internal {
        gasService.payNativeGasForContractCall{ value: msg.value }(
            address(this),
            destinationChain,
            destinationAddress,
            payload,
            msg.sender
        );
        gateway.callContract(destinationChain, destinationAddress, payload);
    }

    /**
     * @dev Make the payment from user
     * @param paymentTokenAddress Address of ERC20 stablecoins used to pay for listing
     * @param paymentAmount Amount to be paid (without decimals)
     */
     function _payment(address paymentTokenAddress, uint256 paymentAmount) internal {
        if (!whitelistedStable[paymentTokenAddress]) revert InvalidPaymentToken(paymentTokenAddress);

        IERC20Extended paymentToken = IERC20Extended(paymentTokenAddress);
        uint256 amount = paymentAmount * 10**paymentToken.decimals();
        bool success = paymentToken.transferFrom(msg.sender, address(this), amount);

        if (!success) revert TokenPaymentFailed(paymentTokenAddress, amount);
    }
}