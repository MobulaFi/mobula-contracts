// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@axelar/contracts/executable/AxelarExecutable.sol";
import "@axelar/contracts/interfaces/IAxelarGasService.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./AxelarStructs.sol";

/*
    CONCERNS :
    - Should we implement the 'revert' logic here ?
    - What happen to gas left ? -> refunded minutes after
    - What happen on a reverted tx on destination chain ?
    - Use callContractWithTokenExpress() ? -> partnership with axelar probably needed
    - Need to WL axlTokens

*/

contract AxelarSender is AxelarExecutable, Ownable {
    IAxelarGasService public immutable gasService;

    string public destinationChain;
    string public destinationAddress;

    constructor(address gateway_, address gasReceiver_) AxelarExecutable(gateway_) {
        gasService = IAxelarGasService(gasReceiver_);
    }

    function setDestination(string memory _destinationChain, string memory _destinationAddress) external onlyOwner {
        destinationChain = _destinationChain;
        destinationAddress = _destinationAddress;
    }

    function updateTokenAxelar(uint256 tokenId, string memory ipfsHash) external payable {
        require(msg.value > 0, 'Gas payment is required');

        bytes memory payload = abi.encode(MobulaPayload(MobulaMethod.UpdateToken, msg.sender, ipfsHash, tokenId));

        _sendCrosschain(payload, "", 0);
    }
    
    function submitTokenAxelar(string memory ipfsHash, string memory symbol, uint256 paymentAmount) external payable
    {
        require(msg.value > 0, 'Gas payment is required');

        bytes memory payload = abi.encode(MobulaPayload(MobulaMethod.SubmitToken, msg.sender, ipfsHash, 0));

        _sendCrosschain(payload, symbol, paymentAmount);
    }

    function topUpTokenAxelar(uint256 tokenId, string memory symbol, uint256 paymentAmount) external payable {
        require(msg.value > 0, 'Gas payment is required');

        bytes memory payload = abi.encode(MobulaPayload(MobulaMethod.TopUpToken, msg.sender, "", tokenId));

        _sendCrosschain(payload, symbol, paymentAmount);
    }

    function revertAxelar(string memory message) external payable {
        require(msg.value > 0, 'Gas payment is required');

        bytes memory payload = abi.encode(MobulaPayload(MobulaMethod.TestRevert, msg.sender, message, 0));

        _sendCrosschain(payload, "", 0);
    }

    function revertPaymentAxelar(string memory message, string memory symbol, uint256 paymentAmount) external payable {
        require(msg.value > 0, 'Gas payment is required');

        bytes memory payload = abi.encode(MobulaPayload(MobulaMethod.TestRevert, msg.sender, message, 0));

        _sendCrosschain(payload, symbol, paymentAmount);
    }

    function _sendCrosschain(bytes memory payload, string memory symbol, uint256 amount) internal {
        // TODO : Check callContractWithTokenExpress()
        if (amount != 0) {
            address tokenAddress = gateway.tokenAddresses(symbol);
            IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);
            IERC20(tokenAddress).approve(address(gateway), amount);

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
        } else {
            gasService.payNativeGasForContractCall{ value: msg.value }(
                address(this),
                destinationChain,
                destinationAddress,
                payload,
                msg.sender
            );
            gateway.callContract(destinationChain, destinationAddress, payload);
        }
    }
}