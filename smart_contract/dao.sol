/* 
    SPDX-License-Identifier: Unlicensed 

*/ 

pragma solidity ^0.8.17; 

contract cryptoDAO {

// structs

    /* represents something the community can vote on */
    struct Status {
        bool initialized;
        uint256 votes;
        bool approved;
    }

    /* represents a club member
       Includes member address, member name, voting power, 
       votes to induct member into club, and if they're an approved member */
    struct ClubMember {
        uint256 id;
        address addressOfMember;
        string name;
        uint256 votes;
        Status status;
    }
    // record of who has voted to approve a member already 
    mapping (address => mapping (address => uint256)) membershipVotesForFrom;

    /* Represents a club event, like a picnic or bbq */
    struct ClubEvent {
        uint256 id;
        string title;
        string description;
        ClubMember creator;
        ClubMember[] members;
        bool stillOpen;
    }
    // does the event's `members` contin given user
    mapping (uint256 => mapping (address => bool)) doesEventContainMember;

    /* Represents a proposed change for the club. 
       Change will be approved on-chain and carried out off-chain. */
    struct ClubChange {
        uint256 id;
        string description;
        Status status;
    }
    mapping (uint256 => mapping (address => uint256)) changeVotesForFrom;

    /* Represents a payment proposal, which will be from this contract address to the proposed recipient for the stated amount.
       Can be proposed by any club member, and requires 51% approval to happen. */
    struct ClubPayment {
        uint256 id;
        address recipient;
        uint256 amount;
        string description;
        Status status;
    }
    mapping (uint256 => mapping (address => uint256)) paymentVotesForFrom;

    /* Represents an election for the club, which:
     - is started by a majority vote
     - once the election is started, voting for the president is enabled 
     - ends after a set period from the start
     - anyone can be nominated as a candidate 
     - keeps track of all votes candidates receive
    */
    struct Election {
        uint256 electionId;
        uint256 startTime;
        uint256 endTime;
        Status status;
        bool votingEnabled;
        ClubMember[] candidates;
        address winner;
    }
    // votes to start election for given election from given user
    mapping (uint256 => mapping (address => uint256)) electionVotesForFrom;
    // president votes for given election for given candidate
    mapping (uint256 => mapping (address => uint256)) presidentVotesForFor;
    // president vote for given election from given voter
    mapping (uint256 => mapping (address => address)) presidentVoteForFrom;

// end structs

    Status emptyStatus = Status(false, 0 , false);
    ClubMember emptyMember = ClubMember(0, address(0), "", 0, emptyStatus);

    // MEMBERS AND VOTING

    ClubMember[] members;
    mapping (address => uint256) addressToMemberID;
    uint256 public totalVotes = 0;
    uint256 numMembers;
    event joinRequest(address member, string name);
    event newMemberAccepted(string name);
    uint256 nextDecay;

    // CHANGES 
    ClubChange[] clubChanges; 
    uint256 changesCount = 0;
    event changeAccepted(uint256 id);

    // EVENTS
    ClubEvent[] events;
    uint eventId = 0;

    // ELECTIONS
    address president;
    Election[] elections;
    Election election;
    uint256 electionId = 0;

    // MONEY
    ClubPayment[] clubPayments;  
    uint256 public paymentsCount = 0;
    event paymentAccepted(uint256 id);



    modifier approvedOnly {
        require(addressToClubMember(msg.sender).status.approved, "you are not an approved member");
        _;
    }

    constructor () {
        Status memory membership;
        membership.initialized = true;
        membership.votes = 1;
        membership.approved = true;

        ClubMember memory creator = ClubMember(0, msg.sender, "satoshi", 1, membership);
        members.push(creator);
        addressToMemberID[msg.sender] = 0;

        president = msg.sender;
        election.status.initialized = true;
        totalVotes = 1;
        numMembers = 1;
        // DEMO
        nextDecay = block.timestamp + 600;
    }





    // ===================================    MEMBERS    =================================== //

    function requestToJoin(string memory name) payable external {
        require(msg.value >= 10**15 wei); // user must pay >10^15 wei == 0.001eth to request to join club, to prevent spam (works as entrance fee
        require(!addressToClubMember(msg.sender).status.initialized, "you are already a (possibly unapproved) member");

        Status memory membership;
        membership.initialized = true;
        membership.votes = 0;
        membership.approved = false;

        ClubMember memory newMember = ClubMember(numMembers, msg.sender, name, 0, membership);
        members.push(newMember);

        // members[numMembers].id = numMembers;
        // members[numMembers].addressOfMember = msg.sender;
        // members[numMembers].name = "name";
        // members[numMembers].votes = 0;
        // members[numMembers].status.initialized = true;
        // members[numMembers].status.votes = 0;
        // members[numMembers].status.approved = false;
        addressToMemberID[msg.sender] = newMember.id;

        numMembers++;
        emit joinRequest(msg.sender, name);
    }

    function addressToClubMember(address memberAddress) public view returns (ClubMember memory) {
        // if this is not a registered member
        if(addressToMemberID[memberAddress] == 0 && memberAddress != members[0].addressOfMember) {
            return emptyMember;
        }
        return members[addressToMemberID[memberAddress]];
    }

    function voteToAddMember(address newMemberAddress) external approvedOnly {

        uint256 id = addressToClubMember(newMemberAddress).id;
        // if the current member has not yet cast a vote to induct the new member
        require(membershipVotesForFrom[newMemberAddress][msg.sender] == 0, "you have already voted to add this user");
        // cast the votes
        members[id].status.votes += userVotes(msg.sender);
        membershipVotesForFrom[newMemberAddress][msg.sender] = userVotes(msg.sender);

        if (members[id].status.votes > totalVotes/2 && !members[id].status.approved) {
            members[id].status.approved = true;
            members[id].votes = 1;
            // addressToClubMember[msg.sender] = newMember;
            totalVotes++;
            emit newMemberAccepted(members[id].name);
        }
        
    }

    function viewAllMembers() public view returns (ClubMember[] memory) {
        return members;
    }

    function viewMemberInfo(address user) public view returns (ClubMember memory) {
        return addressToClubMember(user);
    }

    function userVotes(address userAddress) public view returns (uint256) {
        return addressToClubMember(userAddress).votes;
    }





    // ===================================    CLUB EVENTS    =================================== //

    // create a new event for the club which contains the creator, attendees, and whether it's still open.
    function createEvent(string memory title, string memory description) external approvedOnly {
        ClubEvent storage newEvent = events.push();
        newEvent.id = eventId;
        newEvent.title = title;
        newEvent.description = description;
        newEvent.creator = addressToClubMember(msg.sender);
        newEvent.stillOpen = true;
        newEvent.members.push(addressToClubMember(msg.sender));
        doesEventContainMember[eventId][msg.sender] = true;

        eventId++;
    }

    function joinEvent(uint256 id) external approvedOnly {
        require(events[id].stillOpen, "event closed");
        require(!doesEventContainMember[id][msg.sender], "you have already joined");
        events[id].members.push(addressToClubMember(msg.sender));
        doesEventContainMember[id][msg.sender] = true;
        if (events[id].creator.votes < 10) {
            members[events[id].creator.id].votes++;
            totalVotes++;
        }
    }

    function closeEvent(uint256 id) external approvedOnly {
        require(msg.sender == events[id].creator.addressOfMember, "you are not the event creator");
        events[id].stillOpen = false;
    }

    function viewAllEvents() external view returns (ClubEvent[] memory) {
        return events;
    }

    function viewEventInfo(uint256 id) external view returns (ClubEvent memory) {
        return events[id];
    }

    function viewEventTitle(uint256 id) external view returns (string memory) {
        return events[id].title;
    }

    function viewEventDescription(uint256 id) external view returns (string memory) {
        return events[id].description;
    }

    function viewEventAttendees(uint256 id) external view returns (ClubMember[] memory) {
        return events[id].members;
    }





    // ===================================    CLUB CHANGES    =================================== //


    function proposeChange(string memory description) external approvedOnly {
        uint256 id = changesCount;

        Status memory status;
        status.initialized = true;
        status.votes = userVotes(msg.sender);
        changeVotesForFrom[id][msg.sender] = userVotes(msg.sender);
        ClubChange memory newChange = ClubChange(id, description, status);

        clubChanges.push(newChange);
        changesCount++;
    }


    function voteOnChange(uint256 id) external approvedOnly {
        require(clubChanges[id].status.initialized, "change id does not exist!");
        require(!clubChanges[id].status.approved, "change has already been approved!");
        require(changeVotesForFrom[id][msg.sender] == 0, "you have already voted!");

        clubChanges[id].status.votes += userVotes(msg.sender);
        changeVotesForFrom[id][msg.sender] = userVotes(msg.sender);
        if (clubChanges[id].status.votes > totalVotes/2) {
            clubChanges[id].status.approved = true;
            emit changeAccepted(id);
        }
    }

    function viewAllChanges() public view returns (ClubChange[] memory) {
        return clubChanges;
    }




    // ===================================    CLUB PAYMENTS    =================================== //


    function proposePayment(address recipient, uint256 amountWei, string memory description) external approvedOnly {
        uint256 id = paymentsCount;

        Status memory status;
        status.initialized = true;
        status.votes = userVotes(msg.sender);
        paymentVotesForFrom[id][msg.sender] = userVotes(msg.sender);
        status.approved = false;
        ClubPayment memory newPayment = ClubPayment(id, recipient, amountWei, description, status);
        
        clubPayments.push(newPayment);
        paymentsCount++;
    }

    function votePayment(uint256 paymentId) external approvedOnly {
        require(clubPayments[paymentId].status.initialized, "payment id does not exist!");
        require(!clubPayments[paymentId].status.approved, "payment has already been approved!");
        require(paymentVotesForFrom[paymentId][msg.sender] == 0, "you have already voted!");
        clubPayments[paymentId].status.votes += userVotes(msg.sender);
        paymentVotesForFrom[paymentId][msg.sender] = userVotes(msg.sender);
        if (clubPayments[paymentId].status.votes > totalVotes/2) {
            clubPayments[paymentId].status.approved = true;
            (bool success, ) = clubPayments[paymentId].recipient.call{value: clubPayments[paymentId].amount}("a payment from the UQ crypto club DAO");
            require(success, "failed to send ETH to recipient, check if sufficient balance");
            emit paymentAccepted(paymentId);
        }
    }

    function viewAllClubPayments() public view returns (ClubPayment[] memory) {
        return clubPayments;
    }

    function viewClubPayment(uint256 id) public view returns (ClubPayment memory) {
        return clubPayments[id];
    }

    function viewPaymentDescription(uint256 proposalId) public view returns (string memory) {
        return clubPayments[proposalId].description;
    }

    function viewPaymentVotes(uint256 proposalId) public view returns (uint256) {
        return clubPayments[proposalId].status.votes;
    }





    // ===================================    CLUB ELECTIONS    =================================== //


    function voteStartElection() external approvedOnly {
        // if user has not yet voted
        require(electionVotesForFrom[electionId][msg.sender] == 0, "you have already voted to start this election");
        election.status.votes += userVotes(msg.sender);
        electionVotesForFrom[electionId][msg.sender] = userVotes(msg.sender);
        if (election.status.votes > totalVotes/2) {
            election.votingEnabled = true;
            election.startTime = block.timestamp;
            // DEMO
            election.endTime = block.timestamp + 60;
        }
    }

    function voteForPresident(address candidate) external approvedOnly {
        require(election.votingEnabled && block.timestamp < election.endTime, "election is not active");
        require(addressToClubMember(candidate).status.approved, "cannot vote for a non-approved member");
        require(presidentVoteForFrom[electionId][msg.sender] == address(0), "you have already voted!");

        if (presidentVotesForFor[electionId][candidate] == 0) {
            election.candidates.push(addressToClubMember(candidate));
        }
        presidentVotesForFor[electionId][candidate] += userVotes(msg.sender);
        presidentVoteForFrom[electionId][msg.sender] = candidate;
    
    }

    function finalizeElection() external approvedOnly {
        require(election.votingEnabled, "election has not started yet");
        require(block.timestamp > election.endTime, "election has not finished yet");
        uint mostVotes = 0;
        address winnerAddress;
        for (uint i = 0; i < election.candidates.length; i++) {
            uint votesForCandidate = presidentVotesForFor[electionId][election.candidates[i].addressOfMember];
            if (votesForCandidate > mostVotes) {
                winnerAddress = election.candidates[i].addressOfMember;
                mostVotes = votesForCandidate;
            }
        }
        president = mostVotes > 0 ? winnerAddress : president;
        election.winner = president;
        elections[electionId] = election;


        electionId++;
        election = elections[electionId];
        election.electionId = electionId;
        election.status.initialized = true;
    }

    function viewPresident() public view returns (ClubMember memory) {
        return addressToClubMember(president);
    }

    function viewAllElections() public view returns (Election[] memory) {
        return elections;
    }

    function viewAllCandidates() public view returns (ClubMember[] memory) {
        return election.candidates;
    }

    function isElectionVotingOpen() public view returns (bool) {
        return election.votingEnabled;
    }




    // ===================================    VOTING DECAY    =================================== //


    function triggerYearlyDecay() external approvedOnly {
        require(checkIfReadyToDecay(), "next decay has not come yet");
        // dont let satoshi fall below one vote, for security reasons
        members[0].votes = members[0].votes == 1 ? 1 : members[0].votes - 1;
        for (uint i = 1; i < members.length; i++) {
            if (members[i].votes > 0) {
                members[i].votes = members[i].votes - 1;
                totalVotes--;
            }
        }
        // DEMO
        nextDecay = nextDecay + 600;
    }

    function checkIfReadyToDecay() public view returns (bool) {
        return block.timestamp > nextDecay;
    }


    // struct Election {
    //     uint256 electionId;
    //     uint256 votesToStart
    //     uint256 startTime;
    //     uint256 endTime;
    //     bool votingEnabled;
    //     mapping (address => uint256) presidentVotes;
    // }



}
