// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

/*
    @title Lottery Contract
    @author Chris Gonel
    @notice CSBC2010 - Module 8
*/

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

contract Lottery is VRFConsumerBaseV2, Ownable {
    VRFCoordinatorV2Interface COORDINATOR;
    LinkTokenInterface LINKTOKEN;

    address vrfCoordinator = 0x6168499c0cFfCaCD319c818142124B7A15E857ab;
    address link = 0x01BE23585060835E02B77ef475b0Cc51aA1e0709;
    bytes32 keyHash = 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;
    uint32 callbackGasLimit = 100000; 
    uint16 requestConfirmations = 3;
    uint16 numWords =  1;
    uint64 s_subscriptionId;
    bool lotteryEnded;

    uint64 endTime;
    address winner;
    address[] participants;
    mapping(address => bool) registeredParticipants;


    uint256 s_randomWord; 
    uint256 s_requestId;
    uint256 fee;

    /// @param  _endTime timestamp at which lottery ends
    /// @param _fee cost to enter in the lottery in wei
    /// @param _s_subscriptionId the id of the VRF subscription
    constructor(uint64 _endTime, uint256 _fee, uint64 _s_subscriptionId) VRFConsumerBaseV2(vrfCoordinator){
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        LINKTOKEN = LinkTokenInterface(link);
        endTime = uint64(block.timestamp + _endTime);
        fee = _fee;
        s_subscriptionId = _s_subscriptionId;
    } 

    /// @notice get fee of lottery entry
    /// @return uint256 fee
    function getFee() view external returns(uint256) {
        return fee;
    }

    /// @notice get end time of lottery
    /// @return uint64 end time of the lottery
    function getEndTime() view external returns(uint64) {
        return endTime;
    }

    /// @notice returns the address of the participant
    /// @param _index index of the participant
    /// @return participant address of participant
    function getParticipant(uint256 _index) view external returns(address participant){
        return participants[_index];
    }

    /// @notice returns if participant already registered
    /// @param _participant address of the participant
    /// @return enteredLottery bool if participant is registered
    function getRegisteredParticipants(address _participant) view external returns(bool enteredLottery){
        return registeredParticipants[_participant];
    }

    /// @notice to enter the draw, must provide the exact cost of the ticket
    /// @notice can only enter the lottery once
    /// @return success returns if entered the lottery successfully
    function enterLottery() external payable returns(bool success){
        require(msg.value == fee, "Please provide the correct fee to be able to enter the lottery");
        require(!lotteryEnded, "The lottery has ended");
        require(!registeredParticipants[msg.sender], "Already entered the lottery");

        // add msg.sender to participants if lottery is active
        if (block.timestamp < endTime) {
            participants.push(msg.sender);
            registeredParticipants[msg.sender] = true;
            return true;
        } else {
            // end lottery
            lotteryEnded = true;
            // send back money 
            payable(msg.sender).transfer(msg.value);
            // call VRF
            requestRandomWords();
            return false;
        }
    }

    /// @notice sets the winner
    /// @param _winnerNumber the index of the winning participant
    function setWinner(uint256 _winnerNumber) private {        
        winner = participants[_winnerNumber];
        emit LotteryEnded(winner);
    }

    /// @notice logs the winner when lottery has ended
    /// @param winner the winner of the lottery
    event LotteryEnded(address indexed winner);

    /// @notice withdraw the lottery pool, only callable by the winner or the owner
    function withdrawal() external {
        require(lotteryEnded, "The lottery is still active");
        require(msg.sender == winner || msg.sender == owner(), "Can only be called by the winner and owner of the lottery");

        selfdestruct(payable(winner));
    }
 
    /// @dev calls Chainlink VRF 
    function requestRandomWords() internal {
        s_requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
    }

    /// @dev receives randomWord from VRF and derives the winning number
    /// @param randomWords the received random value from Chainlink VRF
    function fulfillRandomWords(uint256 /* requestId */, uint256[] memory randomWords) internal override {
        s_randomWord = randomWords[0];
        uint256 winnerNumber = randomWords[0] % participants.length;
        setWinner(winnerNumber);
    }

}