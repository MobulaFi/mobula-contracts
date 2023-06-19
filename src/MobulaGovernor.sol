// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/IVotingEscrow.sol";

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
        string contentIpfsHash;
        uint256 createdAt;
        uint256 votesForYes;
        uint256 votesForNo;
        Status status;
    }

    event Vote(address indexed voter, uint indexed proposalId, VotingOptions vote, uint votingPower);
    event CreatedProposal(address indexed creator, uint indexed proposalId);

    mapping(uint256 => Proposal) public proposals;
    mapping(address => mapping(uint256 => bool)) public votes;
    mapping(address => uint256) public lastVote;

    uint256 constant CREATE_PROPOSAL_MIN_SHARE = 100000;
    uint256 constant VOTING_PERIOD = 3 * 24 * 3600;


    uint256 public nextProposalId = 0;
    uint256 public acceptedProposals = 0;
    uint256 public refusedProposals = 0;
    uint256 public numberVotes = 0;

    IVotingEscrow  public votingEscrow;

    IERC20 public token;

    address votingEscrowAddress;

    constructor(address _mobulaTokenAddress, address _votingEscrowAddress) {
        token = IERC20(_mobulaTokenAddress);
        votingEscrow = IVotingEscrow(_votingEscrowAddress);
        votingEscrowAddress = _votingEscrowAddress;
    }

    function checkClosing() public {

        Proposal[] memory _proposals = getLiveProposals(nextProposalId);
        uint256 totalShares = getTotalShares();

        for(uint i = 0; i <_proposals.length; i++){
            Proposal memory _proposal = _proposals[i];

            if(_proposal.createdAt + VOTING_PERIOD < block.timestamp &&
            (_proposal.votesForYes + _proposal.votesForNo >= totalShares * 5/100))
            {

                proposals[_proposal.id].status = _proposal.votesForYes > _proposal.votesForNo ? Status.Accepted : Status.Rejected;

            }

        }
        
    }

    function getCurrentBalance(address _address) internal view returns(uint256) {
        return votingEscrow.balanceOf(_address);

    }


    function getTotalShares() public view returns(uint256) {
        return votingEscrow.totalSupply();

    }


    function getStackedBalanceMOBL() external view returns(uint256) {
        return token.balanceOf(address(votingEscrowAddress));

    }

    function getNumberPropsals() external view returns(uint256[3] memory) {
        return [acceptedProposals,refusedProposals, nextProposalId];
    }

    function getVotesProposal(uint256 _proposalId) view external returns(uint256[2] memory) {
        return [proposals[_proposalId].votesForYes,proposals[_proposalId].votesForNo ];
    }




    function getVotesInformation() view public returns(uint256[6] memory) {
        uint256 stackedVeMOBL = votingEscrow.totalSupply();
        uint256 stackedMOBL = token.balanceOf(address(votingEscrowAddress));
        return [numberVotes, nextProposalId, acceptedProposals,refusedProposals,stackedVeMOBL,stackedMOBL];
    }

    function getBalances(address _address) view public returns(uint256[2] memory) {
        uint256 stackedVeMOBL = votingEscrow.balanceOf(_address);
        uint256 stackedMOBL = token.balanceOf(_address);
        return [stackedMOBL, stackedVeMOBL];
    }


    function getProposal(uint256 index) view external returns(Proposal memory) {

        return proposals[index];
    }

    function createProposal(string memory contentIpfsHash) external returns(uint256){
        // validate the user has enough shares to create a proposal
        uint256 shares=getCurrentBalance(msg.sender);
        require(
            shares >= CREATE_PROPOSAL_MIN_SHARE,
            "You do not have enough $MOBL to create a proposal."
        );
        uint256 id = nextProposalId;

        proposals[id] = Proposal(
            id,
            msg.sender,
            contentIpfsHash,
            block.timestamp,
            0,
            0,
            Status.Pending
        );
        emit CreatedProposal(msg.sender, id);
        nextProposalId++;
        return id;
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

        require(getCurrentBalance(msg.sender) > 0, "You do not have any voting power.");


        lastVote[msg.sender] = block.timestamp;
        votes[msg.sender][_proposalId] = true;
        uint256 totalShares = getTotalShares();
        Status previousStatus = proposal.status;
        if (_vote == VotingOptions.Yes) {
            proposal.votesForYes += getCurrentBalance(msg.sender);
            if (((proposal.votesForYes) / totalShares) * 100 >= 50) {
                if(previousStatus == Status.Rejected) {
                    refusedProposals -= 1;
                }
                if(previousStatus != Status.Accepted) {
                    acceptedProposals  += 1;
                }

                proposal.status = Status.Accepted;
            }
        } else {
            proposal.votesForNo += getCurrentBalance(msg.sender);
            if (((proposal.votesForNo) / totalShares ) * 100 >= 50) {
                if(previousStatus == Status.Accepted) {
                    acceptedProposals -= 1;
                }
                if(previousStatus != Status.Rejected) {
                    refusedProposals  += 1;
                }
                proposal.status = Status.Rejected;
            }
        }
        emit Vote(msg.sender, _proposalId, _vote, votingEscrow.balanceOf(msg.sender));
        numberVotes += 1;

        checkClosing();

    }

    function getLiveProposals(uint256 top)
    public
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