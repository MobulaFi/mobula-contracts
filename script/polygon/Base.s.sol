// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Script.sol";
import "forge-std/console.sol";

contract Base is Script {
    address internal axelarPolygonGateway;
    address internal coco;
    address internal deployerBNB;
    address internal deployerArbitrum;
    address internal deployerPolygon;
    address internal senderContract;
    address internal receiverContract;
    uint256 internal cocoPK;
    uint256 internal deployerPolygonPK;

    address internal protocolAPI; // TODO : Add API address on env file
    address internal tokensProtocolAddress; // TODO : Add MobulaTokensProtocol address on env file

    address internal MOBL;
    address internal USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;

    constructor() {
        cocoPK = vm.envUint("PRIVATE_KEY_COCO");
        deployerPolygonPK = vm.envUint("DEPLOYER_PK_POLYGON");
        coco = vm.addr(cocoPK);
        deployerPolygon = vm.addr(deployerPolygonPK);
        axelarPolygonGateway = vm.envAddress("POLYGON_AXELAR_GATEWAY");
        senderContract = vm.envAddress("SENDER_ADDRESS");
        // Polygon (main contract) smart contract address
        receiverContract = vm.envAddress("TOKENS_PROTOCOL_ADDRESS");
        MOBL = vm.envAddress("POLYGON_MOBL_ADDRESS");
        protocolAPI = vm.envAddress("PROTOCOL_API_ADDRESS");
        tokensProtocolAddress = vm.envAddress("TOKENS_PROTOCOL_ADDRESS=");
    }

    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);            
        }
        return string(s);
    }
    
    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
}