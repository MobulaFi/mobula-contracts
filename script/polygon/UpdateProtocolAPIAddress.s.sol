// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./Base.s.sol";

import "src/MobulaTokensProtocol.sol";
import "src/API.sol";

contract UpdateProtocolAPIAddress is Base {
    function setUp() public {}

    function run() external {
        vm.startBroadcast(deployerPolygonPK);

        MobulaTokensProtocol(tokensProtocolAddress).updateProtocolAPIAddress(protocolAPI);

        API(protocolAPI).setProtocolAddress(tokensProtocolAddress);

        vm.stopBroadcast();
    }
}