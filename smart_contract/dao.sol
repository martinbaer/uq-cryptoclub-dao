/* 
    SPDX-License-Identifier: Unlicensed 

*/ 

pragma solidity ^0.8.17; 

contract cryptoDAO {

// structs

    /* represents a poll */
    struct Status {
        bool initialized;
        uint256 votes;
        bool approved;
    }

    /* represents a club member
       Includes member address, member name, voting power, 
       votes to induct member into club, and record of who has voted for them already */
    struct ClubMember {
        address addressOfMember;
        string name;
        uint256 votes;
        Status status;
    }
    mapping (address => mapping (address => uint256)) membershipVotesForFrom;

    /* Represents a club event, like a picnic or bbq */
    struct ClubEvent {
        uint256 id;
        string title;
        string description;
        address creator;
        address[] members;
        bool stillOpen;
    }

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
        address[] candidates;
        mapping (address => uint256) votesReceivedByCandidate;
        mapping (address => address) userVotedForCandidate;
    }
    mapping (uint256 => mapping (address => uint256)) electionVotesForFrom;

// end structs

    // MEMBERS AND VOTING

    ClubMember[] members;
    mapping (address => ClubMember) addressToClubMember;
    uint256 public totalVotes = 0;
    event joinRequest(address member, string name);
    event newMemberAccepted(string name);

    // CHANGES 
    mapping (uint256 => ClubChange) clubChanges; // id => clubChange
    uint256 changesCount = 0;
    event changeAccepted(uint256 id);

    // EVENTS
    ClubEvent[] events;

    // ELECTIONS
    address president;
    Election election;
    uint256 electionId = 0;

    // MONEY
    ClubPayment[] clubPayments; // 
    uint256 public paymentsCount = 0;
    event paymentAccepted(uint256 id);


    modifier approvedOnly {
        require(addressToClubMember[msg.sender].status.approved, "you are not an approved member");
        _;
    }

    constructor () {
        Status memory membership;
        membership.initialized = true;
        membership.votes = 1;
        membership.approved = true;

        ClubMember memory creator = ClubMember(msg.sender, "satoshi", 1, membership);
        members.push(creator);

        president = msg.sender;
        totalVotes = 1;
    }


    // function viewAllMemberNames() public view returns (string[] memory) {
    //     string[] memory names = new string[](members.length);
    //     for (uint i = 0; i < members.length; i++) {
    //         names[i] = memberAddressToName[members[i]];
    //     }
    //     return names;
    // }

    // ===================================    MEMBERS    =================================== //

    function requestToJoin(string memory name) payable external {
        require(msg.value >= 10**15 wei); // user must pay >10^15 wei == 0.001eth to request to join club, to prevent spam (works as entrance fee

        Status memory membership;
        membership.initialized = true;
        membership.votes = 0;
        membership.approved = false;

        ClubMember memory newMember = ClubMember(msg.sender, name, 0, membership);
        members.push(newMember);

        emit joinRequest(msg.sender, name);
    }

    function voteToAddMember(address newMemberAddress) external approvedOnly {

        ClubMember memory newMember = addressToClubMember[newMemberAddress];
        // if the current member has not yet cast a vote to induct the new member
        require(membershipVotesForFrom[newMemberAddress][msg.sender] == 0, "you have already voted to add this user");
        // cast the votes
        newMember.status.votes += userVotes(msg.sender);
        membershipVotesForFrom[newMemberAddress][msg.sender] = userVotes(msg.sender);

        if (newMember.status.votes > totalVotes/2 && !newMember.status.approved) {
            newMember.status.approved = true;
            newMember.votes = 1;
            members.push(newMember);
            totalVotes++;
            emit newMemberAccepted(newMember.name);
        }
        
    }

    function viewAllMembers() public view returns (ClubMember[] memory) {
        return members;
    }

    function viewMemberInfo(address user) public view returns (ClubMember memory) {
        return addressToClubMember[user];
    }

    function userVotes(address userAddress) public view returns (uint256) {
        return addressToClubMember[userAddress].votes;
    }


    // ===================================    CLUB EVENTS    =================================== //

    // create a new event for the club which contains the creator, attendees, and whether it's still open.
    function createEvent(string memory title, string memory description) external approvedOnly returns (ClubEvent memory) {
        ClubEvent memory newEvent;
        newEvent.title = title;
        newEvent.description = description;
        newEvent.creator = msg.sender;
        newEvent.stillOpen = true;
        events.push(newEvent);
        return newEvent;
    }

    function joinEvent(uint256 id) external approvedOnly {
        require(events[id].stillOpen, "event closed");
        events[id].members.push(msg.sender);
        if (addressToClubMember[events[id].creator].votes < 10) {
            addressToClubMember[events[id].creator].votes++; // increases event creators voting weight
            totalVotes++;
        }
    }

    function closeEvent(uint256 id) external approvedOnly {
        require(msg.sender == events[id].creator);
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

    function viewEventAttendees(uint256 id) external view returns (address[] memory) {
        return events[id].members;
    }


    // function viewOpenEvents() external view returns (ClubEvent[] memory) {
    //     ClubEvent[] memory openEvents = new ClubEvent[](events.length);
    //     uint count = 0;
    //     for (uint i = 0; i < events.length; i++) {
    //         if (events[i].stillOpen) {
    //             openEvents[count] = events[i];
    //             count++;
    //         }
    //     }
    //     return openEvents;
    // }
    // ===================================    CLUB CHANGES    =================================== //


    function proposeChange(string memory description) external approvedOnly {
        uint256 id = changesCount;

        Status memory status;
        status.initialized = true;
        status.votes = userVotes(msg.sender);
        changeVotesForFrom[id][msg.sender] = userVotes(msg.sender);
        ClubChange memory newChange = ClubChange(id, description, status);

        clubChanges[id] = newChange;
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

    // PAYMENTS //

    // struct ClubPayment {
    //     uint256 id;
    //     address recipient;
    //     uint256 amount;
    //     string paymentDescription;
    //     uint256 votes;
    //     bool approved;
    // }

    function proposeSpendClubETH(address recipient, uint256 amount, string memory description) external approvedOnly {
        uint256 id = paymentsCount;

        Status memory status;
        status.initialized = true;
        status.votes = userVotes(msg.sender);
        paymentVotesForFrom[id][msg.sender] = userVotes(msg.sender);
        status.approved = userVotes(msg.sender) > totalVotes/2;
        ClubPayment memory newPayment = ClubPayment(id, recipient, amount, description, status);
        
        clubPayments[id] = newPayment;
        paymentsCount++;
    }

    function voteSpendClubETH(uint256 paymentId) external approvedOnly {
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

    function viewAllSpendETHProposals() public view returns (ClubPayment[] memory) {
        return clubPayments;
    }

    function viewSpendETHProposal(uint256 id) public view returns (ClubPayment memory) {
        return clubPayments[id];
    }

    function viewSpendETHProposalDescription(uint256 proposalId) public view returns (string memory) {
        return clubPayments[proposalId].description;
    }

    function viewSpendETHProposalVotes(uint256 proposalId) public view returns (uint256) {
        return clubPayments[proposalId].status.votes;
    }

    // function voteStartElection(bool start) external approvedOnly {
    //     if ()
    //     election.
    // }

    // struct Election {
    //     uint256 electionId;
    //     uint256 votesToStart
    //     uint256 startTime;
    //     uint256 endTime;
    //     bool votingEnabled;
    //     mapping (address => uint256) presidentVotes;
    // }

    // function voteForPresident(address candidate) external approvedOnly {

    // }


}
