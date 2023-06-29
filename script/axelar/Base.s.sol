// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Script.sol";
import "forge-std/console.sol";

contract Base is Script {
    address internal axelarBNBGateway;
    address internal axelarBNBGas;
    address internal axelarArbitrumGateway;
    address internal axelarArbitrumGas;
    address internal axelarPolygonGateway;
    address internal axelarPolygonGas;
    address internal coco;
    address internal dada;
    address internal deployerBNB;
    address internal deployerArbitrum;
    address internal deployerPolygon;
    uint256 internal cocoPK;
    uint256 internal dadaPK;
    uint256 internal deployerBNBPK;
    uint256 internal deployerArbitrumPK;
    uint256 internal deployerPolygonPK;

    constructor() {
        cocoPK = vm.envUint("PRIVATE_KEY_COCO");
        dadaPK = vm.envUint("PRIVATE_KEY_DADA");
        deployerBNBPK = vm.envUint("DEPLOYER_PK_BNB");
        deployerArbitrumPK = vm.envUint("DEPLOYER_PK_ARBITRUM");
        deployerPolygonPK = vm.envUint("DEPLOYER_PK_POLYGON");
        coco = vm.addr(cocoPK);
        dada = vm.addr(dadaPK);
        deployerBNB = vm.addr(deployerBNBPK);
        deployerArbitrum = vm.addr(deployerArbitrumPK);
        deployerPolygon = vm.addr(deployerPolygonPK);
        axelarBNBGateway = vm.envAddress("BNB_AXELAR_GATEWAY");
        axelarArbitrumGateway = vm.envAddress("ARBITRUM_AXELAR_GATEWAY");
        axelarPolygonGateway = vm.envAddress("POLYGON_AXELAR_GATEWAY");
        axelarBNBGas = vm.envAddress("BNB_AXELAR_GAS");
        axelarArbitrumGas = vm.envAddress("ARBITRUM_AXELAR_GAS");
        axelarPolygonGas = vm.envAddress("POLYGON_AXELAR_GAS");
    }
}