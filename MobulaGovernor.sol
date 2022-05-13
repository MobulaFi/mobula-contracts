// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract MobulaGovernor {
    enum VotingOptions {
        Yes,
        No
    }
    enum Status {
        Accepted,
        Rejected,
        Pending
    }
    struct Proposal {
        uint256 id;
        address author;
        string name;
        uint256 createdAt;
        uint256 votesForYes;
        uint256 votesForNo;
        Status status;
    }

    mapping(uint256 => Proposal) public proposals;
    mapping(address => mapping(uint256 => bool)) public votes;
    mapping(address => uint256) public shares;
    mapping(address => uint256) public lastVote;

    uint256 public totalShares;
    uint256 constant CREATE_PROPOSAL_MIN_SHARE = 100000 * 10**18;
    uint256 constant VOTING_PERIOD = 3 days;
    uint256 public nextProposalId;

    IERC20 public token;

    constructor(address _mobulaTokenAddress) {
        token = IERC20(_mobulaTokenAddress);
    }

    function deposit(uint256 _amount) external {
        shares[msg.sender] += _amount;
        totalShares += _amount;
        token.transferFrom(msg.sender, address(this), _amount);
    }

    function withdraw(uint256 _amount) external {
        require(
            shares[msg.sender] >= _amount,
            "You cannot withdraw more than what you deposited."
        );
        require(
            lastVote[msg.sender] + VOTING_PERIOD <= block.timestamp,
            "You need to wait 3 days after your last vote to withdraw."
        );

        shares[msg.sender] -= _amount;
        totalShares -= _amount;
        token.transfer(msg.sender, _amount);
    }

    function createProposal(string memory name) external {
        // validate the user has enough shares to create a proposal
        require(
            shares[msg.sender] >= CREATE_PROPOSAL_MIN_SHARE,
            "You do not have enough $MOBL to create a proposal."
        );

        proposals[nextProposalId] = Proposal(
            nextProposalId,
            msg.sender,
            name,
            block.timestamp,
            0,
            0,
            Status.Pending
        );
        nextProposalId++;
    }

    function vote(uint256 _proposalId, VotingOptions _vote) external {
        Proposal storage proposal = proposals[_proposalId];
        require(
            votes[msg.sender][_proposalId] == false,
            "You cannot vote twice."
        );
        require(
            block.timestamp <= proposal.createdAt + VOTING_PERIOD,
            "The voting period is over."
        );
        lastVote[msg.sender] = block.timestamp;
        votes[msg.sender][_proposalId] = true;
        if (_vote == VotingOptions.Yes) {
            proposal.votesForYes += shares[msg.sender];
            if ((proposal.votesForYes * 100) / totalShares > 50) {
                proposal.status = Status.Accepted;
            }
        } else {
            proposal.votesForNo += shares[msg.sender];
            if ((proposal.votesForNo * 100) / totalShares > 50) {
                proposal.status = Status.Rejected;
            }
        }
    }

    function getLiveProposals(uint256 top)
        external
        view
        returns (Proposal[] memory)
    {
        Proposal[] memory liveProposals = new Proposal[](top);
        uint256 _nextProposalId = nextProposalId - 1;
        Proposal memory proposal = proposals[_nextProposalId];

        while (
            block.timestamp <= proposal.createdAt + VOTING_PERIOD &&
            _nextProposalId >= 0 &&
            nextProposalId - _nextProposalId < top + 1
        ) {
            proposal = proposals[_nextProposalId];
            liveProposals[nextProposalId - _nextProposalId - 1] = proposal;
            if (_nextProposalId > 0) {
                _nextProposalId--;
            } else {
                break;
            }
        }
        return liveProposals;
    }
}
