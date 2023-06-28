// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@axelar/contracts/executable/AxelarExecutable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AxelarReceiver is AxelarExecutable {

    constructor(address gateway_) AxelarExecutable(gateway_) {}

    function _executeWithToken(
        string calldata,
        string calldata,
        bytes calldata payload,
        string calldata tokenSymbol,
        uint256 amount
    ) internal override {
        address[] memory recipients = abi.decode(payload, (address[]));
        address tokenAddress = gateway.tokenAddresses(tokenSymbol);

        uint256 sentAmount = amount / recipients.length;
        for (uint256 i = 0; i < recipients.length; i++) {
            IERC20(tokenAddress).transfer(recipients[i], sentAmount);
        }
    }
}