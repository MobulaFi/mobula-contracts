// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";

import "./interfaces/IAPI.sol";
import "./interfaces/IERC20Extended.sol";

import "./lib/ProtocolErrors.sol";
import "./lib/SubmitQueryStruct.sol";


contract TokensProtocolProxy is Initializable, Ownable2Step {

    /* Protocol variables */
    

    /* Events */
    event FundsWithdrawn(address indexed recipient, uint256 amount);


    /* Getters */

    // TODO : Add mapping and arrays getters
    
    /* Users methods */

    // TODO : Add submitToken + add Axelar submitHandler + add updateToken
    
    // TODO : Add claimRewards

    /* Votes */

    // TODO : Add votes methods + create modifiers (onlyRanked, onlyRankII...)

    /* Protocol Management */

    // TODO : Add protocol variable setters

    /* Hierarchy Management */

    // TODO : Add promote/demote

    /* Emergency Methods */

    // TODO : Add token emergency methods

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
    }

}