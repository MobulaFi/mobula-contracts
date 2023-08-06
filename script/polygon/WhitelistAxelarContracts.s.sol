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
        string memory sourceAddress = "0xBD0ac880252Ef89dEf4Bfdb01208df59C54B1817"; // TODO : Add AxelarSender address
        // MobulaTokensProtocol(tokensProtocolAddress).whitelistAxelarContract(sourceChain, sourceAddress, true);
        // MobulaTokensProtocol(tokensProtocolAddress).updateSubmitFloorPrice(30);
        // MobulaTokensProtocol(tokensProtocolAddress).whitelistStable(0xc2132D05D31c914a87C6611C10748AEb04B58e8F, true);

        MobulaTokensProtocol(tokensProtocolAddress).emergencyPromote(0x09bE1d0fC708F60160f813d4ABa17fc6e1Bd9d8E);

        vm.stopBroadcast();
    }
}