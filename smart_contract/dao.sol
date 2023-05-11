/* 
    SPDX-License-Identifier: Unlicensed 

*/ 

pragma solidity ^0.8.17; 

contract cryptoDAO {


    // STRUCTS FOR STORING INFO ABOUT DAO EVENTS ETC.

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
        bool initialized;
    }

    struct ClubChange {
        uint256 id;
        string changeDescription;
        uint256 votes;
        mapping (address => uint256) votesCastByMembers;
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
    mapping (uint256 => ClubChange) clubChanges;
    uint256 changesCount = 0;

    // EVENTS
    ClubEvent[] public events;
    mapping (uint256 => ClubEvent) clubEvents;
    uint256 eventsCount = 0;

    // OTHER

    uint256 public totalVotes = 0;

    address president;

}