// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract UQCryptoClubDAO {
    struct Member {
        string name;
        uint256 voteWeight;
        uint256 lastActive;
        bool approved;
    }

    struct Decision {
        string description;
        mapping(address => uint256) votes;
        address[] voters;
        uint256 endTime;
        bool active;
    }

    struct Event {
        string name;
        string description;
        uint256 time;
        address[] attendees;
        address creator;
        bool active;
    }

    mapping(address => Member) public members;
    address[] public memberAddresses;

    Decision[] public decisions;
    Event[] public events;

    // Membership functions
    function joinDAO(string memory name) public {
        require(!members[msg.sender].approved, "Already a member.");
        members[msg.sender] = Member(name, 0, block.timestamp, false);
        memberAddresses.push(msg.sender);
    }

    function approveMember(address member) public {
        require(members[msg.sender].approved, "Only members can approve.");
        require(!members[member].approved, "Member already approved.");
        members[member].approved = true;
    }

    function checkActivity() public {
        for (uint256 i = 0; i < memberAddresses.length; i++) {
            if (
                block.timestamp - members[memberAddresses[i]].lastActive >=
                90 days
            ) {
                delete members[memberAddresses[i]];
            }
        }
    }

    // Decision functions
    function createDecision(
        string memory description,
        uint256 duration
    ) public {
        require(
            members[msg.sender].approved,
            "Only members can create decisions."
        );
        decisions.push();
        decisions[decisions.length - 1].description = description;
        decisions[decisions.length - 1].endTime = block.timestamp + duration;
        decisions[decisions.length - 1].active = true;
    }

    function vote(uint256 decisionId, uint256 option) public {
        require(members[msg.sender].approved, "Only members can vote.");
        require(decisions[decisionId].active, "Decision is no longer active.");
        require(
            decisions[decisionId].endTime > block.timestamp,
            "Voting time has elapsed."
        );
        decisions[decisionId].votes[msg.sender] = option;
        decisions[decisionId].voters.push(msg.sender);
    }

    // Event functions
    function createEvent(
        string memory name,
        string memory description,
        uint256 time
    ) public {
        require(
            members[msg.sender].approved,
            "Only members can create events."
        );
        events.push(
            Event(name, description, time, new address[](0), msg.sender, true)
        );
    }

    function attendEvent(uint256 eventId) public {
        require(
            members[msg.sender].approved,
            "Only members can attend events."
        );
        require(events[eventId].active, "Event is no longer active.");
        events[eventId].attendees.push(msg.sender);
    }

    function deleteEvent(uint256 eventId) public {
        require(
            events[eventId].creator == msg.sender,
            "Only the event creator can delete the event."
        );
        events[eventId].active = false;
    }

    function removeAttendee(uint256 eventId, address attendee) public {
        require(
            events[eventId].creator == msg.sender,
            "Only the event creator can remove attendees."
        );
        require(events[eventId].active, "Event is no longer active.");

        // Get the list of attendees
        address[] storage attendees = events[eventId].attendees;

        for (uint i = 0; i < attendees.length; i++) {
            if (attendees[i] == attendee) {
                // Swap the attendee to remove with the last attendee
                attendees[i] = attendees[attendees.length - 1];

                // Delete the last attendee
                attendees.pop();

                break;
            }
        }
    }
}
