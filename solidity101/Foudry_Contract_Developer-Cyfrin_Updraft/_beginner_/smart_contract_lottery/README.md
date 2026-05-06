# Raffle Contract

## What does it do?

1. Users can enter by paying for a ticket.
   1. The ticket fees go to the winner during the draw.
2. After a set period of time, the lottery automatically draws a winner.
   1. This is done programmatically.
3. The contract uses Chainlink VRF and Chainlink Automation.
   1. Chainlink VRF provides randomness.
   2. Chainlink Automation provides time-based triggers.

## Tests

1. Write deploy scripts.
   1. These will not work on zkSync.
2. Write tests for:
   1. Local chain
   2. Forked testnet
   3. Forked mainnet
