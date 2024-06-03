// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BettingPlatform {
    struct Bet {
        address better;
        uint256 amount;
        bool outcome;
    }

    struct Event {
        string description;
        uint256 endTime;
        bool outcome;
        bool resolved;
        uint256 totalYes;
        uint256 totalNo;
        Bet[] bets;
    }

    uint256 public eventCount;
    mapping(uint256 => Event) public events;

    event EventCreated(uint256 eventId, string description, uint256 endTime);
    event BetPlaced(uint256 eventId, address better, uint256 amount, bool outcome);
    event EventResolved(uint256 eventId, bool outcome);

    function createEvent(string memory description, uint256 duration) external {
        eventCount++;
        events[eventCount] = Event(description, block.timestamp + duration, false, false, 0, 0, new Bet[](0));
        emit EventCreated(eventCount, description, block.timestamp + duration);
    }

    function placeBet(uint256 eventId, bool outcome) external payable {
        Event storage event = events[eventId];
        require(block.timestamp < event.endTime, "Betting period over");
        require(!event.resolved, "Event already resolved");

        event.bets.push(Bet(msg.sender, msg.value, outcome));
        if (outcome) {
            event.totalYes += msg.value;
        } else {
            event.totalNo += msg.value;
        }

        emit BetPlaced(eventId, msg.sender, msg.value, outcome);
    }

    function resolveEvent(uint256 eventId, bool outcome) external {
        Event storage event = events[eventId];
        require(block.timestamp >= event.endTime, "Event not ended yet");
        require(!event.resolved, "Event already resolved");

        event.resolved = true;
        event.outcome = outcome;
        uint256 totalPot = event.totalYes + event.totalNo;
        uint256 winnerTotal = outcome ? event.totalYes : event.totalNo;

        for (uint256 i = 0; i < event.bets.length; i++) {
            if (event.bets[i].outcome == outcome) {
                uint256 payout = (totalPot * event.bets[i].amount) / winnerTotal;
                payable(event.bets[i].better).transfer(payout);
            }
        }

        emit EventResolved(eventId, outcome);
    }

    function getEvent(uint256 eventId) external view returns (string memory description, uint256 endTime, bool outcome, bool resolved, uint256 totalYes, uint256 totalNo) {
        Event storage event = events[event
