// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import "src/MobulaTokensProtocol.sol";

contract Base is Test {
    address internal axelarPolygonGateway;
    address internal deployerPolygon;
    uint256 internal deployerPolygonPK;

    address internal MOBL;

    MobulaTokensProtocol tokensProtocol;

    constructor() {
        deployerPolygonPK = vm.envUint("DEPLOYER_PK_POLYGON");
        deployerPolygon = vm.addr(deployerPolygonPK);
        axelarPolygonGateway = vm.envAddress("POLYGON_AXELAR_GATEWAY");
        MOBL = vm.envAddress("POLYGON_MOBL_ADDRESS");

        tokensProtocol = new MobulaTokensProtocol(axelarPolygonGateway, deployerPolygon, MOBL);
    }
}