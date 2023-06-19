// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Vault {
    address internal owner;

    modifier onlyOwner() {
        require(isOwner(msg.sender), "Call not allowed.");
        _;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function getRewardsEarned(address staker) public view returns (uint256) {
        return
            stakersRewards[staker] +
            (balance[staker] *
                rewardsPerSAFUPerBlock *
                (block.number - lastUpdate[staker])) /
            1e9;
    }

    function getLastUpdate(address staker) public view returns (uint256) {
        return lastUpdate[staker];
    }

    function getStakerBalance(address staker) public view returns (uint256) {
        return balance[staker];
    }

    IERC20 SAFU = IERC20(0x890cc7d14948478c98A6CD7F511E1f7f7f99F397); //Main Net

    uint256 public maximumLocked = 2000 * 1e9;
    uint256 public totalLocked;
    uint256 public rewardsPerSAFUPerBlock;

    mapping(address => uint256) stakersRewards;
    mapping(address => uint256) lastUpdate;
    mapping(address => uint256) balance;

    address[] stakers;
    mapping(address => uint256) stakerIndexes;

    constructor() {
        owner = msg.sender;
    }

    function stake(uint256 amount) public {
        require(
            amount > 0 && totalLocked + amount <= maximumLocked,
            "The maximum amount of SAFUs has been staked in this pool."
        );
        SAFU.transferFrom(msg.sender, address(this), amount);

        totalLocked += amount;

        uint256 _lastUpdate = lastUpdate[msg.sender];
        lastUpdate[msg.sender] = block.number;

        if (balance[msg.sender] > 0) {
            stakersRewards[msg.sender] +=
                (balance[msg.sender] *
                    rewardsPerSAFUPerBlock *
                    (block.number - _lastUpdate)) /
                1e9;
        } else {
            addStaker(msg.sender);
        }

        balance[msg.sender] += amount;
    }

    function withdraw(uint256 amount) public {
        require(
            amount > 0 && amount <= balance[msg.sender],
            "You cannot withdraw more than what you have!"
        );
        uint256 _lastUpdate = lastUpdate[msg.sender];
        lastUpdate[msg.sender] = block.number;
        stakersRewards[msg.sender] +=
            (balance[msg.sender] *
                rewardsPerSAFUPerBlock *
                (block.number - _lastUpdate)) /
            1e9;
        balance[msg.sender] -= amount;

        if (balance[msg.sender] == 0) {
            removeStaker(msg.sender);
        }

        SAFU.transfer(msg.sender, amount);

        totalLocked -= amount;
    }

    function claim() public {
        uint256 _lastUpdate = lastUpdate[msg.sender];
        lastUpdate[msg.sender] = block.number;
        stakersRewards[msg.sender] +=
            (balance[msg.sender] *
                rewardsPerSAFUPerBlock *
                (block.number - _lastUpdate)) /
            1e9;
        require(stakersRewards[msg.sender] > 0, "No rewards to claim!");
        uint256 rewards = stakersRewards[msg.sender];
        stakersRewards[msg.sender] = 0;
        SAFU.transfer(msg.sender, rewards);
    }

    function modifyRewards(uint256 amount) public onlyOwner {
        for (uint256 i = 0; i < stakers.length; i++) {
            uint256 _lastUpdate = lastUpdate[stakers[i]];
            lastUpdate[stakers[i]] = block.number;
            stakersRewards[stakers[i]] +=
                (balance[stakers[i]] *
                    rewardsPerSAFUPerBlock *
                    (block.number - _lastUpdate)) /
                1e9;
        }

        rewardsPerSAFUPerBlock = amount;
    }

    function addStaker(address staker) internal {
        stakerIndexes[staker] = stakers.length;
        stakers.push(staker);
    }

    function removeStaker(address staker) internal {
        stakers[stakerIndexes[staker]] = stakers[stakers.length - 1];
        stakerIndexes[stakers[stakers.length - 1]] = stakerIndexes[staker];
        stakers.pop();
    }
}
