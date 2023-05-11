/* 
    SPDX-License-Identifier: Unlicensed 

*/ 

pragma solidity ^0.8.17; 

contract cryptoDAO {

    struct ClubEvent {
        uint256 id;
        string name;
        address organizer;
        address[] members;
        bool stillOpen;
    }

    struct AddMemberVote {
        address newMember;
        uint256 votes;
        mapping (address => uint256) votesCastByMembers;
    }

    struct ClubChange {
        uint256 id;
        string changeDescription;
        uint256 votes;
        bool accepted;
    }

    // JOINING THE CLUB 

    mapping (address => AddMemberVote) public approvalVotes;
    event joinRequest(address member, string);

    // MEMBERS AND VOTING
    address[] public members;
    mapping(address => string) public memberNames;
    mapping(address => uint256) public userVotes;

    // CHANGES 
    mapping (uint256 => ClubChange) clubChanges; // id => clubChange
    mapping (uint256 => mapping (address => uint256)) votesCastByMembersForChange; // change id => (voter => votes cast by voter)
    uint256 changesCount = 0;
    event changeAccepted(uint256 id);

    // EVENTS
    ClubEvent[] public events;
    mapping (uint256 => ClubEvent) clubEvents;
    uint256 eventsCount = 0;

    // OTHER

    uint256 public totalVotes = 0;

    address president;


    constructor () {
        members.push(msg.sender);
        president = msg.sender;
        userVotes[msg.sender] = 1;
        totalVotes = 1;
    }

    // ===================================    JOINING CLUB    =================================== //

    function requestToJoin(string memory name) external payable {
        require(msg.value == 1); // user must pay to request to join club, to prevent spam (works as entrance fee)
        approvalVotes[msg.sender].newMember = msg.sender;
        approvalVotes[msg.sender].votes = 0;
        emit joinRequest(msg.sender, name);
    }

    function voteToAddMember(address newMember) external {

        // if the current member has not yet cast a vote to induct the new member
        if (approvalVotes[newMember].votesCastByMembers[msg.sender] == 0) {
            // cast the votes
            approvalVotes[newMember].votes += userVotes[msg.sender];
            approvalVotes[newMember].votesCastByMembers[msg.sender] = userVotes[msg.sender];
        }
    }

    function joinClub() external {
        require(approvalVotes[msg.sender].votes > totalVotes/2 && userVotes[msg.sender] == 0);
        members.push(msg.sender);
        userVotes[msg.sender] = 1;
        totalVotes++;
    }

    // ===================================    CLUB EVENTS    =================================== //

    // create a new event for the club which contains the organizer, attendees, and whether it's still open.
    function createEvent(string memory name) external returns (ClubEvent memory) {
        ClubEvent memory newEvent;
        newEvent.name = name;
        newEvent.organizer = msg.sender;
        newEvent.stillOpen = true;
        events.push(newEvent);
        clubEvents[eventsCount] = newEvent;
        eventsCount++;
        return newEvent;
    }

    function joinEvent(uint256 id) external {
        clubEvents[id].members.push(msg.sender);
    }

    function viewEventAttendees(uint256 id) external view returns (address[] memory) {
        return clubEvents[id].members;
    }

    // ===================================    CLUB CHANGES    =================================== //


    function proposeChange(string memory description) external {
        require(userVotes[msg.sender] > 0);
        uint256 id = changesCount;

        ClubChange memory newChange = ClubChange(id, description, userVotes[msg.sender], false);
        
        votesCastByMembersForChange[id][msg.sender] = userVotes[msg.sender];

        clubChanges[id] = newChange;
        
        changesCount++;
    }


    function voteOnChange(uint256 id) external {
        require(votesCastByMembersForChange[id][msg.sender] == 0, "you have already voted!");
        require(!clubChanges[id].accepted, "change has already been accepted!");
        clubChanges[id].votes += userVotes[msg.sender];
        votesCastByMembersForChange[id][msg.sender] = userVotes[msg.sender];
        if (clubChanges[id].votes > totalVotes/2) {
            clubChanges[id].accepted = true;
            emit changeAccepted(id);
        }
    }







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
