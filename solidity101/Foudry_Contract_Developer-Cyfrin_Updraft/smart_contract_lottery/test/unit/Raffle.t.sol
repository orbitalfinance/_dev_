//SPDX-LICENSE-IDENTIFIER: MIT
pragma solidity ^0.8.34;

import {Test} from "../../lib/forge-std/src/Test.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../..//src/Raffle.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Vm} from "../../lib/forge-std/src/Vm.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {CodeConstants} from "../../script/HelperConfig.s.sol";

contract RaffleTest is Test, CodeConstants {
    Raffle public newRaffle;
    HelperConfig public newHelperConfig;

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint32 callbackGasLimit;
    uint256 subscriptionId;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_BALANCE = 10 ether;

    /** Events */
    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (newRaffle, newHelperConfig) = deployer.deployRaffle();

        HelperConfig.NetworkConfig memory config = newHelperConfig.getConfig();
        entranceFee = config.entranceFee;
        interval = config.interval;
        vrfCoordinator = config.vrfCoordinator;
        gasLane = config.gasLane;
        callbackGasLimit = config.callbackGasLimit;
        subscriptionId = config.subscriptionId;

        vm.deal(PLAYER, STARTING_BALANCE);
    }

    // Lottery should start as OPEN

    function testRaffleInitializesInOpenState() public view {
        assert(newRaffle.getRaffleState() == Raffle.RaffleState.OPEN);
        // assertEq(uint256(newRaffle.getRaffleState()) == 0);
    }

    /*//////////////////////////////////////////////////////////////
                              ENTER RAFFLE
    //////////////////////////////////////////////////////////////*/

    function testRaffleRevertWhenDontPayEnough() public {
        vm.prank(PLAYER);
        vm.expectRevert(Raffle.Raffle_NotEnoughEthToEnterRaffle.selector);
        newRaffle.enterRaffle();
    }

    function testRaffleRecordsPlayersWhenTheyEnter() public {
        vm.prank(PLAYER);
        newRaffle.enterRaffle{value: entranceFee}();

        address playerRecorded = newRaffle.getPlayers()[0];
        assert(playerRecorded == PLAYER);
    }

    function testEnteringRaffleEmitsEvent() public {
        // Arrange
        vm.prank(PLAYER);
        // Act
        vm.expectEmit(true, false, false, false, address(newRaffle));
        emit RaffleEntered(PLAYER);
        // Assert
        newRaffle.enterRaffle{value: entranceFee}();
    }

    function testDontAllowPlayersToEnterWhileRaffleIsCalculating() public {
        // Arrange
        vm.prank(PLAYER);
        newRaffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        newRaffle.performUpkeep("");

        // Act & Assert
        vm.expectRevert(Raffle.Raffle_RaffleNotOpen.selector);
        vm.prank(PLAYER);
        newRaffle.enterRaffle{value: entranceFee}();
    }

    /*//////////////////////////////////////////////////////////////
                              CHECK UPKEEP
    //////////////////////////////////////////////////////////////*/

    function testCheckUpkeepReturnsFalseIfItHasNoBalance() public {
        //Arrange
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        // Act
        (bool upkeepNedeed, ) = newRaffle.checkUpkeep("");
        assert(!upkeepNedeed);
    }

    function testCheckUpkeepReturnsFalseIfRaffleIsntOpen() public {
        // Arrange
        vm.prank(PLAYER);
        newRaffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        newRaffle.performUpkeep("");

        // Act
        (bool upkeepNeeded, ) = newRaffle.checkUpkeep("");

        // Assert
        assert(!upkeepNeeded);
    }

    /*//////////////////////////////////////////////////////////////
                             PERFORM UPKEEP
    //////////////////////////////////////////////////////////////*/

    function testPerformUpkeepCanOnlyRunIfCheckUpkeepIsTrue() public {
        // Arrange
        vm.prank(PLAYER);
        newRaffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        // Act / Assert
        newRaffle.performUpkeep("");
    }

    function testPerformUpkeepRevertsIfCheckUpkeepIsFalse() public {
        // Arrange
        uint256 currentBalance = 0;
        uint256 numPlayers = 0;
        Raffle.RaffleState rState = newRaffle.getRaffleState();

        vm.prank(PLAYER);
        newRaffle.enterRaffle{value: entranceFee}();
        currentBalance = currentBalance + entranceFee;
        numPlayers = 1;

        // Act / Assert
        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle_UpkeepNotNeeded.selector,
                currentBalance,
                numPlayers,
                rState
            )
        );
        newRaffle.performUpkeep("");
    }

    modifier raffleEntered() {
        vm.prank(PLAYER);
        newRaffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
    }

    // What if we need to get data from emitted events in our tests?
    function testPerformUpkeepUpdatesRaffleStateAndEmitsRequestId()
        public
        raffleEntered
    {
        // Act
        vm.recordLogs();
        newRaffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        // Assert
        Raffle.RaffleState raffleState = newRaffle.getRaffleState();
        assert(uint256(requestId) > 0);
        assert(uint256(raffleState) == 1);
    }

    /*//////////////////////////////////////////////////////////////
                          FULLFILLRANDOMWORDS
    //////////////////////////////////////////////////////////////*/

    modifier skipFork() {
        if (block.chainid != LOCAL_CHAIN_ID) {
            return;
        }
        _;
    }

    function testFulfillRandomWordsCanOnlyBeCalledAfterPerformUpkeep(
        uint256 randomRequestId
    ) public raffleEntered skipFork {
        // Arrange / Act / Assert
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(
            randomRequestId,
            address(newRaffle)
        );
    }

    function testFulfillrandomWordsPicksAWinnerResetsAndSendsMoney()
        public
        raffleEntered
        skipFork
    {
        // Arrange
        uint256 additionalEntrants = 3; // 4 total
        uint256 startingIndex = 1;
        address expectedWinner = address(1);

        for (
            uint256 i = startingIndex;
            i < startingIndex + additionalEntrants;
            i++
        ) {
            // casting to uint160 is safe because i is a small loop index
            // forge-lint: disable-next-line(unsafe-typecast)

            address newPlayer = address(uint160(i));
            hoax(newPlayer, 1 ether);
            newRaffle.enterRaffle{value: entranceFee}();
        }

        uint256 startingTimeStamp = newRaffle.getLastTimeStamp();
        uint256 winnerStartingBalance = expectedWinner.balance;

        // Act
        vm.recordLogs();
        newRaffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(
            uint256(requestId),
            address(newRaffle)
        );

        // Assert
        address recentWinner = newRaffle.getRecentWinner();
        Raffle.RaffleState raffleState = newRaffle.getRaffleState();
        uint256 winnerBalance = recentWinner.balance;
        uint256 endingTimeStamp = newRaffle.getLastTimeStamp();
        uint256 prize = entranceFee * (additionalEntrants + 1);

        assert(recentWinner == expectedWinner);
        assert(uint256(raffleState) == 0);
        assert(winnerBalance == winnerStartingBalance + prize);
        assert(endingTimeStamp > startingTimeStamp);
    }
}
