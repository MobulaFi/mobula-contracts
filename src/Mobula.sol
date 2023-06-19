// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

contract Mobula is ERC20, Ownable, ERC20Permit, ERC20Votes {
    bool private _paused;
    mapping(address => bool) public whitelisted;
    mapping(address => bool) public blacklisted;

    event Paused(address account);
    event Unpaused(address account);

    constructor() ERC20("Mobula", "MOBL") ERC20Permit("Mobula") {
        _mint(msg.sender, 20000000 * 10**decimals());
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    function pause() public onlyOwner {
        _paused = true;
        emit Paused(_msgSender());
    }

    function unpause() public onlyOwner {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    function changeWhitelist(address account) public onlyOwner {
        whitelisted[account] = !whitelisted[account];
    }

    function changeBlacklist(address account) public onlyOwner {
        blacklisted[account] = !blacklisted[account];
    }

    modifier whenNotPaused() {
        require(
            !blacklisted[_msgSender()] &&
                (!paused() || whitelisted[_msgSender()]),
            "Pausable: paused"
        );
        _;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }

    // The following functions are overrides required by Solidity.

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Votes) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._burn(account, amount);
    }
}
