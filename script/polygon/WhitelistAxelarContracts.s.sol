// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./Base.s.sol";

import "src/MobulaTokensProtocol.sol";

contract WhitelistAxelarContracts is Base {
    function setUp() public {}

    function run() external {
        vm.startBroadcast(deployerPolygonPK);

        // TODO : WL each AxelarSender contracts
        string memory sourceChain = "binance";
        string memory sourceAddress; // TODO : Add AxelarSender address
        MobulaTokensProtocol(tokensProtocolAddress).whitelistAxelarContract(sourceChain, sourceAddress, true);

        vm.stopBroadcast();
    }
}