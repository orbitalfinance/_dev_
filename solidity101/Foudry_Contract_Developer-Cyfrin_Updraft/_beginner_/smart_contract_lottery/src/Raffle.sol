//SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

// ================================================================
// CONTRACT LAYOUT
// ================================================================
// 1. Pragma statements && NatSpec
// 2. Import statements
// 3. Errors (Custom Errors preferred for gas-optimisation)
// 4. Interfaces, libraries, contracts
// -->
// 3.2 Errors
// 5. Type declarations
// 6. State variables
// 7. Events
// 8. Modifiers
// 9. Functions
//
// FUNCTION LAYOUT
// ================================================================
// 1. Constructor
// 2. Receive function (if any)
// 3. Fallback function (if any)
// 4. External functions
// 5. Public functions
// 6. Internal functions
// 7. Private functions
// 8. View and pure functions at the end of each visibility group
// ================================================================

// /**
//  * @title Smart Contract Lottery : Raffle contract
//  * @author Santo Mancuso - inspired by Patrick Collins’ Cyfrin Updraft course
//  * @notice This smart contract creates a sample raffle
//  * @dev Implements Chainlink VRFvx.x
//  */

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

contract Raffle is VRFConsumerBaseV2Plus {
    /** Errors */
    error Raffle_NotEnoughEthToEnterRaffle();
    error Raffle_TransferFailed();
    error Raffle_RaffleNotOpen();
    error Raffle_UpkeepNotNeeded(
        uint256 currentBalance,
        uint256 numPlayers,
        uint256 raffleState
    );

    // Type declarations
    enum RaffleState {
        OPEN, // Convertible into integers: 0,1,2
        CALCULATING
    }

    // State variables
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    bytes32 private immutable i_keyhash;
    uint256 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    uint256 private s_lastTimeStamp;
    address payable[] private s_players;
    address private s_recentWinner;
    RaffleState private s_raffleState;

    /** Events */
    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);
    event RequestRaffleWinner(uint256 indexed requestId);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address _vrfCoordinator,
        bytes32 gasLane, //keyhash: price we are willing to pay
        uint256 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(_vrfCoordinator) {
        i_entranceFee = entranceFee;

        // @dev The duration of a lottery in seconds. The interval between lottery rounds.
        i_interval = interval;
        i_keyhash = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;

        s_lastTimeStamp = block.timestamp;
        s_raffleState = RaffleState.OPEN;
    }

    function enterRaffle() external payable {
        // Sol1:
        //  require(msg.value >= i_entranceFee,"Not enough ETH sent!" );
        // Sol2:
        //  require(msg.value >= i_entranceFee, NotEnoughEthToEnterRaffle());
        if (msg.value < i_entranceFee) {
            revert Raffle_NotEnoughEthToEnterRaffle();
        }

        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle_RaffleNotOpen();
        }

        s_players.push(payable(msg.sender));
        emit RaffleEntered(msg.sender);
    }

    /**
     * @dev Chainlink nodes call this function to check if the lottery is ready to pick a winner. These conditons must be satisfied for upkeepNedeed to be true :
     *  1. The time interval has passed between raffle runs
     *  2. The lottery is open
     *  3. The contract has ETH
     *  4. There are funds in the subscription (implictly true)
     * @return upkeepNeeded -> true if it's time to restart the lottery
     */
    function checkUpkeep(
        bytes memory /* checkData */
    ) public view returns (bool upkeepNeeded, bytes memory /* performData */) {
        bool timeHasPassed = ((block.timestamp - s_lastTimeStamp) >=
            i_interval);
        bool isOpen = s_raffleState == RaffleState.OPEN;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;
        upkeepNeeded = timeHasPassed && isOpen && hasBalance && hasPlayers;
        return (upkeepNeeded, "");
    }

    function performUpkeep(bytes memory /* performData */) external {
        // 1. Get a random number
        // 2. Use the random number to pick up a player
        // 3. This function must be automatically called

        // Enough time is passed since the starting of the lottery?
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle_UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }

        s_raffleState = RaffleState.CALCULATING;

        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient
            .RandomWordsRequest({
                keyHash: i_keyhash, //keyhash: price we are willing to pay
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit, //callbackGasLimit: maximum gas we are willing to spend
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            });

        // Get a random number from Chainlink VRF (Verifiable Random Function).
        // It is a 2 transactions process: request the RNG (Random Number Generator) and get the RNG.

        uint256 requestId = s_vrfCoordinator.requestRandomWords(request);
        emit RequestRaffleWinner(requestId); // It is redundant, already present in VRFCoordinator
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] calldata randomWords
    ) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        s_raffleState = RaffleState.OPEN;

        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle_TransferFailed();
        }

        emit WinnerPicked(s_recentWinner);
    }

    /**Getter functions */
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }

    function getPlayers() external view returns (address payable[] memory) {
        return s_players;
    }

    function getLastTimeStamp() external view returns (uint256) {
        return s_lastTimeStamp;
    }

    function getRecentWinner() external view returns (address) {
        return s_recentWinner;
    }
}
