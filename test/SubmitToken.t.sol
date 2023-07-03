// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./Base.t.sol";

contract SubmitToken is Base {

    function setUp() public {}

    function testTokenIsSubmitted(string memory testHash) public {
        TokenListing[] memory tokenListings = tokensProtocol.getTokenListings();

        uint256 newTokenId = tokenListings.length;

        tokensProtocol.submitToken(testHash, address(0), 0);

        TokenListing[] memory newTokenListings = tokensProtocol.getTokenListings();

        TokenListing memory listing = newTokenListings[newTokenId];

        assertEq(newTokenListings.length, tokenListings.length + 1, "Token was added to listings");
        assertEq(listing.token.ipfsHash, testHash, "Token IPFS hash is correct");
    }
}
