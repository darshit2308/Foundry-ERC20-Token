// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * @title A sample Raffle smart contract
 * @author Darshit Khandelwal
 * @notice This contract is a simple lottery system where users can enter a raffle by sending Ether.
 * @dev The contract uses a random number generator to select a winner from the participants.Implements Chainlink VRFv2.5
 */
// import {IVRFCoordinatorV2Plus} from "chainlink/contracts/src/v0.8/vrf/dev/interfaces/IVRFCoordinatorV2Plus.sol";
import {VRFV2PlusClient} from "chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
// import {VRFCoordinatorV2_5} from "chainlink/contracts/src/v0.8/vrf/dev/VRFCoordinatorV2_5.sol";
import {VRFConsumerBaseV2Plus} from "chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
// import {AutomationCompatibleInterface} from "chainlink/contracts/src/v0.8/automation/interfaces/AutomationCompatibleInterface.sol";

import {console2} from "forge-std/Script.sol";

contract Raffle is VRFConsumerBaseV2Plus {
    /* Errors */
    error Raffle__SendMoreEthToEnterRaffle(); // You must mention the name of contract in the Error name also
    error Raffle__TransferFailed();
    error Raffle__RaffleNotOpen();
    error Raffle__UpkeepNotNeeded(
        uint256 balance,
        uint256 playersLength,
        uint256 RaffleState
    );

    /* Type declarations */
    enum RaffleState {
        // An enum is used when we need to create different types of states, like shown below
        OPEN, // Means the raffle is open to anyone to join
        CALCULATING // Means choosing of winner is in the process,and no one else can enter during this period.
    }

    /* Variables */
    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval; // This is the time interval in which we are gonna organise the lottery(the duration is in seconds.)
    uint256 private s_lastTimeStamp;
    address private s_recentWinner;

    address payable[] s_players; // A payable group(Means the players can be paid) of players addresses stored in an array

    // chainlink VRF related variables
    VRFConsumerBaseV2Plus private immutable i_vrfCoordinator;
    bytes32 private immutable i_keyhash;
    uint256 private immutable i_subscriptionId;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private immutable i_callbackGasLimit;
    uint32 private constant NUM_WORDS = 1;
    RaffleState private s_raffleState;

    /* Events */
    event RaffleEntered(address indexed newPlayer); // A new Event -> New player has entered the game
    event WinnerPicked(address indexed winner); // For events, we use 'indexed' keyword only
    event RequestedRaffleWinner(uint256 indexed requestId);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint256 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        // immutables
        i_entranceFee = entranceFee;
        i_interval = interval;
        i_vrfCoordinator = VRFConsumerBaseV2Plus(vrfCoordinator); // vrfCoordinator is the address of the Chainlink VRF Coordinator contract
        i_keyhash = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;

        // storages
        s_lastTimeStamp = block.timestamp; // Storing the timestamp each time the contract is launched
        s_raffleState = RaffleState.OPEN;
    }

    function enterRaffle() external payable {
        // Enter the game and buy a lottery ticket
        // In order to only allow users after paying a certain amount, they are the following methods:
        // 1) -> (Not Gas efficient)
        // require(msg.value >= i_entranceFee , "Not Enough ETH Provide !!!");
        // 2) ->(Latest , but not Gas efficient)
        // require(msg.value >= i_entranceFee , Raffle__SendMoreEthToEnterRaffle());

        // 3) -> (Latest)
        if (msg.value < i_entranceFee)
            revert Raffle__SendMoreEthToEnterRaffle();
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotOpen();
        }
        s_players.push(payable(msg.sender)); // We need to write payble to make the player payble

        // The reason that when and why we emit an event , but PAtrick said to do
        emit RaffleEntered(msg.sender);
    }

    /*
    Notes: there are 2 main functions to ensure that we do not need to call the lottery again and again manually.We call firstly checkUpKeep, which 
    ensures that if all the conditions are correct or not to again start lottery.If Upkeep is correct, then we call performUpkeep which is the main
    functionality.
    */
    /**
     * @dev This is the function that the Chainlink nodes will call to see
     * if the lottery is ready to have a winner picked
     * The following should be true in order for upKeepNeeded to be true:
     * 1. The time interval has passed between raffle runs
     * 2. The lottery is open
     * 3. The contract has ETH
     * 4. Implicitly, your subscription has LINK
     * @param - ignored
     * @return upkeepNeeded - true if its time to restart the lottery.
     * @return - ignored
     */
    // The below function will keep on running continiously, and when it is true, we comee to know that it is time to decide a new winner
    function checkUpKeep(
        bytes memory /* checkData */
    ) public view returns (bool upkeepNeeded, bytes memory) {
        /* Here we could have set this function as override(used when we can update this function 
    anywhere else after importing it */
        // Here, in above function, we replaced calldata by memory ,  don't know whyyyy
        bool timeHasPassed = ((block.timestamp - s_lastTimeStamp) >=
            i_interval); // 1
        bool isOpen = s_raffleState == RaffleState.OPEN; // 2
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;
        upkeepNeeded = timeHasPassed && isOpen && hasBalance && hasPlayers;

        return (upkeepNeeded, "");
    }

    // 1. Get a number
    // 2. Use a random number to pick a player
    // 3. Be automatically called -> We need to make it automatic, since we are busy !

    function performUpkeep(bytes calldata) external { // Here we also pick the winner...
        // pickWinner namechanged to -> performUpkeep
        //  Check
        (bool upKeepNeeded, ) = checkUpKeep(""); // We are calling the checkUpKeep function to check if all the conditions are met or not.
        if (!upKeepNeeded) {
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }
        if (block.timestamp - s_lastTimeStamp < i_interval) revert();

        s_raffleState = RaffleState.CALCULATING; // Put the enum in calculating state so that no more any user can enter the raffle.

        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient
            .RandomWordsRequest({
                keyHash: i_keyhash,// Refers to the specific key used by the Chainlink oracle to generate randomness.It tells how much maximu gas we can spend
                subId: i_subscriptionId,// Your Chainlink subscription ID which must be funded with LINK,allows us to pay for randomness request.
                requestConfirmations: REQUEST_CONFIRMATIONS,// how many block confirmations to wait before responding.
                callbackGasLimit: i_callbackGasLimit,// The gas limit for the fulfillRandomWords() callback.
                numWords: NUM_WORDS,// How many random numbers you want returned.
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            });

        uint256 requestId = s_vrfCoordinator.requestRandomWords(request); // we pass the request with all the paremeters shown above.
        /* IMP NOTE: When we call requestRandomWords,then Chainlink VRF automatically calls fulfillRandomWords function with random number
        as parameters */


        /*
        s_vrfCoordinator is the address of the Chainlink VRF Coordinator contract
        It does 3 main things:

        Sends randomness requests to Chainlink via s_vrfCoordinator.requestRandomWords(...).

        Verifies that random numbers come only from the real Chainlink VRF Coordinator.

        Lets the owner update the coordinator address in case Chainlink upgrades it.
        Without s_vrfCoordinator, your contract wouldn't know who to ask for randomness or how to verify it came from the right source.
        */


       emit RequestedRaffleWinner(requestId);
    }

    // CEI : Checks , Effects , Interaction Pattern
    function fulfillRandomWords(
        // Inside this function, the winner is decided and s_players is formated.
        uint256  requestId ,
        uint256[] calldata randomWords
    ) internal override {
        // Checks -> They must be done at the start of functions, since it has less Time complexity -> Gas Efficient.
        // Conditionals
        //

        // Effects
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0); // s_players array has been formated and now, new players will join raffle.
        s_lastTimeStamp = block.timestamp;
        emit WinnerPicked(s_recentWinner);

        // Interactions (External Contract Interactions)
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if (!success) revert Raffle__TransferFailed();
    }

    /* If we need to import and use VRFConsumerBaseV2Plus, then we need to use this function.The chainlink node will run this command to return the requestId.
    The fulfillRandomWords function is a callback that Chainlink VRF calls when your contract receives random numbers.
    It is where you handle the randomness and implement your lottery logic */


    /* Some Getter functions */

    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }
    function getPlayer(uint256 indexOfPlayer) external view returns (address) {
        return s_players[indexOfPlayer];
    }
    function getLastTimeStamp() external view returns (uint256) {
        return s_lastTimeStamp;
    }
    function getRecentWinner() external view returns(address) {
        return s_recentWinner;
    }
}
/* Notes: 
1) We start another lottery as soon as a winner has been selected
2) We select a winner after every 'interval' period of time


*/