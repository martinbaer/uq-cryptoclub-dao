/* 
    SPDX-License-Identifier: Unlicensed 

*/

pragma solidity ^0.8.17;

contract cryptoDAO {
    // structs
    struct ClubEvent {
        uint256 id;
        string title;
        string description;
        address creator;
        address[] members;
        bool stillOpen;
    }

    struct AddMemberVote {
        address newMember;
        string name;
        uint256 votes;
        mapping(address => uint256) votesCastByMembers;
    }

    struct ClubChange {
        uint256 id;
        string description;
        uint256 votes;
        bool accepted;
    }

    struct ClubPayment {
        uint256 id;
        address recipient;
        uint256 amount;
        string description;
        uint256 votes;
        bool accepted;
    }

    struct Election {
        uint256 electionId;
        uint256 votesToStart;
        uint256 startTime;
        uint256 endTime;
        bool votingEnabled;
        mapping(address => uint256) presidentVotes;
    }
    // end structs

    // JOINING THE CLUB

    mapping(address => AddMemberVote) public approvalVotes;
    event joinRequest(address member, string);
    event newMemberAccepted(string name);

    // MEMBERS AND VOTING
    address[] members;
    mapping(address => string) memberAddressToName;
    mapping(address => uint256) public userVotes;
    uint256 public totalVotes = 0;

    // CHANGES
    mapping(uint256 => ClubChange) clubChanges; // id => clubChange
    mapping(uint256 => mapping(address => uint256)) votesCastByMembersForChange; // change id => (voter => votes cast by voter)
    uint256 changesCount = 0;
    event changeAccepted(uint256 id);

    // EVENTS
    ClubEvent[] events;

    // ELECTIONS
    address president;
    Election election;
    uint256 electionId = 0;

    // MONEY
    ClubPayment[] public clubPayments; //
    mapping(uint256 => mapping(address => uint256)) votesCastByMembersForPayment; // payment id => (voter => votes cast by voter)
    uint256 public paymentsCount = 0;
    event paymentAccepted(uint256 id);

    modifier memberOnly() {
        require(userVotes[msg.sender] > 0, "you are not in the club");
        _;
    }

    constructor() {
        members.push(msg.sender);
        president = msg.sender;
        memberAddressToName[msg.sender] = "satoshi";
        userVotes[msg.sender] = 1;
        totalVotes = 1;
    }

    function viewMemberName(address user) public view returns (string memory) {
        return memberAddressToName[user];
    }

    function viewMemberAddresses() public view returns (address[] memory) {
        return members;
    }

    function viewMemberNames() public view returns (string[] memory) {
        string[] memory names = new string[](members.length);
        for (uint i = 0; i < members.length; i++) {
            names[i] = memberAddressToName[members[i]];
        }
        return names;
    }

    // ===================================    JOINING CLUB    =================================== //

    function requestToJoin(string memory name) external payable {
        require(msg.value >= 10 ** 15 wei); // user must pay >10^15 wei == 0.001eth to request to join club, to prevent spam (works as entrance fee)
        approvalVotes[msg.sender].newMember = msg.sender;
        approvalVotes[msg.sender].name = name;
        approvalVotes[msg.sender].votes = 0;
        emit joinRequest(msg.sender, name);
    }

    function voteToAddMember(address newMember) external memberOnly {
        // if the current member has not yet cast a vote to induct the new member
        require(
            approvalVotes[newMember].votesCastByMembers[msg.sender] == 0,
            "you have already voted to add this user"
        );
        // cast the votes
        approvalVotes[newMember].votes += userVotes[msg.sender];
        approvalVotes[newMember].votesCastByMembers[msg.sender] = userVotes[
            msg.sender
        ];

        if (
            approvalVotes[newMember].votes > totalVotes / 2 &&
            userVotes[newMember] == 0
        ) {
            members.push(newMember);
            memberAddressToName[newMember] = approvalVotes[newMember].name;
            userVotes[newMember] = 1;
            totalVotes++;
            emit newMemberAccepted(memberAddressToName[newMember]);
        }
    }

    // ===================================    CLUB EVENTS    =================================== //

    // create a new event for the club which contains the creator, attendees, and whether it's still open.
    function createEvent(
        string memory title,
        string memory description
    ) external memberOnly returns (ClubEvent memory) {
        ClubEvent memory newEvent;
        newEvent.title = title;
        newEvent.description = description;
        newEvent.creator = msg.sender;
        newEvent.stillOpen = true;
        events.push(newEvent);
        return newEvent;
    }

    function joinEvent(uint256 id) external memberOnly {
        require(userVotes[msg.sender] > 0, "you are not in the club");
        require(events[id].stillOpen, "event closed");
        require(events[id].stillOpen, "event closed");
        events[id].members.push(msg.sender);
        if (userVotes[events[id].creator] < 10) {
            userVotes[events[id].creator]++; // increases event creators voting weight
            totalVotes++;
        }
    }

    function closeEvent(uint256 id) external memberOnly {
        require(msg.sender == events[id].creator);
        events[id].stillOpen = false;
    }

    function viewAllEvents() external view returns (ClubEvent[] memory) {
        return events;
    }

    function viewOpenEvents() external view returns (ClubEvent[] memory) {
        ClubEvent[] memory openEvents = new ClubEvent[](events.length);
        uint count = 0;
        for (uint i = 0; i < events.length; i++) {
            if (events[i].stillOpen) {
                openEvents[count] = events[i];
                count++;
            }
        }
        return openEvents;
    }

    function viewEventInfo(
        uint256 id
    ) external view returns (ClubEvent memory) {
        return events[id];
    }

    function viewEventTitle(uint256 id) external view returns (string memory) {
        return events[id].title;
    }

    function viewEventDescription(
        uint256 id
    ) external view returns (string memory) {
        return events[id].description;
    }

    function viewEventAttendees(
        uint256 id
    ) external view returns (address[] memory) {
        return events[id].members;
    }

    // ===================================    CLUB CHANGES    =================================== //

    function proposeChange(string memory description) external memberOnly {
        uint256 id = changesCount;

        ClubChange memory newChange = ClubChange(
            id,
            description,
            userVotes[msg.sender],
            false
        );

        votesCastByMembersForChange[id][msg.sender] = userVotes[msg.sender];

        clubChanges[id] = newChange;

        changesCount++;
    }

    function voteOnChange(uint256 id) external memberOnly {
        require(clubChanges[id].votes > 0, "change id does not exist!");
        require(
            votesCastByMembersForChange[id][msg.sender] == 0,
            "you have already voted!"
        );
        require(!clubChanges[id].accepted, "change has already been accepted!");
        clubChanges[id].votes += userVotes[msg.sender];
        votesCastByMembersForChange[id][msg.sender] = userVotes[msg.sender];
        if (clubChanges[id].votes > totalVotes / 2) {
            clubChanges[id].accepted = true;
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
    //     bool accepted;
    // }

    function proposeSpendClubETH(
        address recipient,
        uint256 amount,
        string memory description
    ) external memberOnly {
        uint256 id = paymentsCount;

        ClubPayment memory newPayment = ClubPayment(
            id,
            recipient,
            amount,
            description,
            userVotes[msg.sender],
            false
        );

        votesCastByMembersForPayment[id][msg.sender] = userVotes[msg.sender];

        clubPayments[id] = newPayment;

        paymentsCount++;
    }

    function voteSpendClubETH(uint256 paymentId) external memberOnly {
        require(
            clubPayments[paymentId].votes > 0,
            "payment id does not exist!"
        );
        require(
            votesCastByMembersForPayment[paymentId][msg.sender] == 0,
            "you have already voted!"
        );
        require(
            !clubPayments[paymentId].accepted,
            "payment has already been accepted!"
        );
        clubPayments[paymentId].votes += userVotes[msg.sender];
        votesCastByMembersForPayment[paymentId][msg.sender] = userVotes[
            msg.sender
        ];
        if (clubPayments[paymentId].votes > totalVotes / 2) {
            clubPayments[paymentId].accepted = true;
            (bool success, ) = clubPayments[paymentId].recipient.call{
                value: clubPayments[paymentId].amount
            }("a payment from the UQ crypto club DAO");
            require(success);
            emit paymentAccepted(paymentId);
        }
    }

    function viewSpendETHProposalDescription(
        uint256 proposalId
    ) public view returns (string memory) {
        return clubPayments[proposalId].description;
    }

    function viewSpendETHProposalVotes(
        uint256 proposalId
    ) public view returns (uint256) {
        return clubPayments[proposalId].votes;
    }

    function viewSpendETHProposals()
        public
        view
        returns (ClubPayment[] memory)
    {
        return clubPayments;
    }

    // function voteStartElection(bool start) external memberOnly {
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

    // function voteForPresident(address candidate) external memberOnly {

    // }

    // ===================================    VIEW CLUB INFO    =================================== //

    // not needed bc fields are public

    // // view the members of the club
    // function viewMembers() public view returns (address[] memory) {
    //     return members;
    // }

    // // view how many votes a member has
    // function viewMemberVotes(address member) public view returns (uint256) {
    //     return userVotes[member];
    // }
}
