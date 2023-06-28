// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@axelar/contracts/executable/AxelarExecutable.sol";
import "@axelar/contracts/interfaces/IAxelarGasService.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AxelarSender is AxelarExecutable {
    IAxelarGasService public immutable gasService;

    constructor(address gateway_, address gasReceiver_) AxelarExecutable(gateway_) {
        gasService = IAxelarGasService(gasReceiver_);
    }

    function sendToMany(
        string memory destinationChain,
        string memory destinationAddress,
        address[] calldata destinationAddresses,
        string memory symbol,
        uint256 amount
    ) external payable {
        require(msg.value > 0, 'Gas payment is required');

        address tokenAddress = gateway.tokenAddresses(symbol);
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);
        IERC20(tokenAddress).approve(address(gateway), amount);
        bytes memory payload = abi.encode(destinationAddresses);
        gasService.payNativeGasForContractCallWithToken{ value: msg.value }(
            address(this),
            destinationChain,
            destinationAddress,
            payload,
            symbol,
            amount,
            msg.sender
        );
        gateway.callContractWithToken(destinationChain, destinationAddress, payload, symbol, amount);
    }
}