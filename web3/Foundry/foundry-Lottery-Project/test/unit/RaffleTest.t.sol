// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Vm} from "../../lib/forge-std/src/Vm.sol";
import {VRFCoordinatorV2_5Mock} from "../../lib/chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {CodeConstants} from "../../script/HelperConfig.s.sol";
contract RaffleTest is CodeConstants, Test {
    Raffle public raffle;
    HelperConfig public helperConfig;

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint256 subscriptionId;
    uint32 callbackGasLimit;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_PLAYER_BALANCE = 10 ether;

    event RaffleEntered(address indexed newPlayer); // A new Event -> New player has entered the game
    event WinnerPicked(address indexed winner); // For events, we use 'indexed' keyword only

    // NOTE -> IN ALL OUR TESTS,WE DO THE CHANGES TO A DUMMY CONTRACT raffle, AND COMPARE IT WITH ORIGNAL CONTRACT RAFFLE
    function setUp() public {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.deployContract();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig(); // We are calling the getConfig function to get the network configuration
        // Now, we have all the variables data inside the config variable
        entranceFee = config.entranceFee;
        interval = config.interval;
        vrfCoordinator = config.vrfCoordinator;
        gasLane = config.gasLane;
        subscriptionId = config.subscriptionId;
        callbackGasLimit = config.callbackGasLimit;

        vm.deal(PLAYER, STARTING_PLAYER_BALANCE);
    }

    function testRaffleInitializesInOpenState() public view {
        // Check that the raffle is in the open state
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN); // In tests, we compare between the Raffle we created and the Raffle of the contract
        // Another way -> assert(uint256(raffle.getRaffleState) == 0);
    }

    /* Enter Raffle */
    function testRaffleRevertWhenYouDontPayEnough() public {
        // Arrange
        vm.prank(PLAYER);
        // Act,Asset
        vm.expectRevert(Raffle.Raffle__SendMoreEthToEnterRaffle.selector); // means that we are pranking the a user enters inside Raffle with 0 balance,
        // and we are expecting the given revert error: Raffle__SendMoreEthToEnterRaffle, if this is not the error,test fails.
        raffle.enterRaffle();
    }

    function testRaffleRecordsWhenTheyEnter() public {
        // Arrange
        vm.prank(PLAYER);
        // Act
        raffle.enterRaffle{value: entranceFee}(); // Remember to do vm.deal() in the constructor to give funds to PLAYER
        // Asset
        address playerRecorded = raffle.getPlayer(0);
        // We are putting 0 in getPlayer since there is only 1 player in the raffle.
        assert(playerRecorded == PLAYER);
    }

    function testEnteringRaffleEmitsEvent() public {
        // Arrange
        vm.prank(PLAYER);
        // Act
        vm.expectEmit(true, false, false, false, address(raffle)); // only 1 true bcoz RaffleEntered event has a single parameter.
        // Moreover, we need to copy paste all the events in this code in order to test them.
        emit RaffleEntered(PLAYER);
        // Asset
        raffle.enterRaffle{value: entranceFee}();
    }

    function testDontAllowPlayersToEnterWhileRaffleIsPickingWinner() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1); // vm.warp helps to wait for some period of time
        // We are waiting for this interval so that now,the whole raffle-state can come to a state of selecting a winner
        vm.roll(block.number + 1); // why use ..?
        raffle.performUpkeep(""); // this line sets the Raffle state as CALCULATING -> s_raffleState = RaffleState.CALCULATING
        // In the above line, we are failing the test due to 'InvalidConsumer'.So we need to add a consumer
        // So we add consumer in Interactions.sol
        // Act / Assert
        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }

    /* Notes:
        checkUpKeep is a function that checks if all the conditions are met to pick a winner (enough time has passed, 
        raffle is open, there are players, and the contract has ETH).
        performUpkeep is the function that is actually called to start the process of picking a winner (it changes 
        the state and requests randomness).
     */

    function testCheckUpKeepReturnsFalseItItHasNoBalance() public {
        // Arrange
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        // Act
        // Here, before calling checkUpKeep, we do not send ETH to it,so the contract does not have ETH.
        (bool upKeepNeeded, ) = raffle.checkUpKeep("");
        // Now, w/o any ETH in contract, the users can't get prize of lottery win..So upKeepNeeded must return false.
        // Assert
        assert(!upKeepNeeded);
    }

    function testCheckUpKeepReturnsFalseIfRaffleIsntOpen() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        // INITIALLY RAFFLE IS ALWAYS OPENED
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        // WINNER IS BEEN PICKED UP CURRENTLY...
        raffle.performUpkeep("");
        // Since winner is been picked up currently, the raffle must be CLOSED ...
        (bool upKeepNeeded, ) = raffle.checkUpKeep("");
        assert(!upKeepNeeded);
    }

    function testCheckUpKeepReturnsFalseIfEnoughTimeHasPassed() public {
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        (bool upKeepNeeded, ) = raffle.checkUpKeep("");
        assert(!upKeepNeeded);
    }

    function testCheckUpKeepReturnsTrueWhenParametersAreGood() public {
        // Here, we are trying to bring the whole condition to a state where the phase of Choosing winner has started.
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        // okay..so the time has paased and now, time to pick winner has come.So we use checkUpkeep
        (bool upKeepNeeded, ) = raffle.checkUpKeep("");
        assert(upKeepNeeded);
    }

    /* PERFORM UPKEEP TESTS */
    function testPerformUpKeepCanOnlyRunIfCheckUpKeepIsTrue() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();

        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        /*
        We ensured that all these pointers occured: 
        1) Enough time has passed -> done using .warp
        2) The raffle is open -> It comes to .calculating state only when we performUpkeep
        3) There is at least one player -> prank function
        4) The contract has ETH  -> value: entranceFee()
        So now, if performUpkeep fails, means test fails.
        */
        // Act,Assert
        raffle.performUpkeep(""); // Here,
    }

    function testPerformUpKeepRevertIfCheckUpKeepIsFalse() public {
        // Arrange
        uint256 currentBalance = 0; // Balance of the contract
        uint256 numPlayers = 0;
        Raffle.RaffleState rState = raffle.getRaffleState();

        vm.prank(PLAYER);
        // Raffle state is open, and we did not advanced the time.
        raffle.enterRaffle{value: entranceFee}();
        currentBalance += entranceFee; // The fees given by the Player goes to Balance of contract
        numPlayers += 1;
        // Act
        vm.expectRevert( // Since we did not advanced the time, we expect the revert.
            abi.encodeWithSelector(
                Raffle.Raffle__UpkeepNotNeeded.selector,
                currentBalance,
                numPlayers,
                rState
            )
        ); // We are saying to foundry-> "I expect the next call to revert with this specific error and arguments."
        // Assert
        raffle.performUpkeep("");
    }

    modifier raffleEntered() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _; // Modifier runs before our test runs.
    }

    function testPerformUpKeepUpdatesRaffleStateAndEmitsRequestId()
        public
        raffleEntered
    {
        // Arrange

        // Act
        vm.recordLogs(); // It says like, whatever logs are emitted by below line, keep its track.
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs(); // This line stores all the recoreded logs into entries array
        bytes32 requestId = entries[1].topics[1];

        // Assert
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        assert(uint256(requestId) > 0); // If the request id exists, then u are good to go !
        assert(uint256(raffleState) == 1); // When we call performUpkeep, raffle state is updated to CALCULAING-> 1.
    }

    /* 
        FULFILL RANDOM WORDS TESTS -> 
    */
    // Fullfill random words can only be called after performUpkeep is called

    modifier skipFork() {
        if(block.chainid != LOCAL_CHAIN_ID)
        {
            return ;
        }
        _;
    }

    function testFulFillRandomWordsCanOnlyBeCalledAfterPerformUpKeep(uint256 randomRequestId)public raffleEntered skipFork
    {
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector); // We are expecting the revert error: InvalidRequest, if this is not the error,test fails.
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords( // Here we are calling the fulfillRandomWords function of VRFCoordinatorV2_5Mock contract before performUpkeep is called.
            randomRequestId, // requestId
            address(raffle) // consumer
        );
        // Now we need to test for all requestIds, so we will write fuzz test for it.So we will remove 0 and add a variable instead
    }
    // function testFulFillRandomWordsPicksWinnerResetsAndSendMoney() public raffleEntered skipFork {
    //     // Arrange
    //     // Call fullfillRandomWords after performUpkeep
    //     // Reset the whole array of players
    //     // Send the winner the money
    //     uint256 additionalEntrants = 3; // Total 4 , bcoz we used the modifier raffleEntered above.
    //     uint256 startingIndex = 1;
    //     address expectedWinner = address(1);

    //     for(uint256 i=startingIndex;i<startingIndex + additionalEntrants;i++) {
    //         address newPlayer = address(uint160(i)); // Converting the indexes to address
    //         hoax(newPlayer, 1 ether); // Gives the player some ether
    //         raffle.enterRaffle{value: entranceFee}();
    //     }
    //     uint256 startingTimeStamp = raffle.getLastTimeStamp();
    //     uint256 winnerStartingBalance = expectedWinner.balance;

    //     // Act
    //     vm.recordLogs();
    //     raffle.performUpkeep("");// Kicks offf the chainlink vrf.
    //     Vm.Log[] memory entries = vm.getRecordedLogs();
    //     bytes32 requestId = entries[1].topics[1];
    //     VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(uint256(requestId),address(raffle));


    //     // Assert
    //     address recentWinner = raffle.getRecentWinner();
    //     Raffle.RaffleState raffleState = raffle.getRaffleState();
    //     uint256 winnerBalance = recentWinner.balance;
    //     uint256 endingTimeStamp = raffle.getLastTimeStamp();
    //     uint256 prize = entranceFee * (additionalEntrants+1);
    //     assert(recentWinner == expectedWinner);
    //     assert(uint256(raffleState) == 0); // Raffle state must now become OPEN after the winner has been chosen
    //     assert(winnerBalance == winnerStartingBalance + prize);
    //     assert(endingTimeStamp > startingTimeStamp);
    // }

}
