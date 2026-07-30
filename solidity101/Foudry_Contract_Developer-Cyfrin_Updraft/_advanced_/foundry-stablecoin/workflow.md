# Foundry smart contract project workflow guide

This guide shows a reusable workflow from a Foundry project structured around `src`, `script`, `test`. It is meant as a general beginner-friendly operating flow that can be reused across future Solidity projects. Not every project needs every component. The goal is to understand the role of each file type and decide which parts are useful for the project being built.

---

## 1. Recommended project structure

A clean Foundry project usually separates production contracts, deployment logic, tests, and mocks.

```text
project-root/
├── src/
│   ├── MainContract.sol
│   ├── Token.sol
│   └── Interfaces.sol
│
├── script/
│   ├── Deploy.s.sol
│   └── HelperConfig.s.sol
│
├── test/
│   ├── unit
│   ├── integration
│   └── mocks
│
├── foundry.toml
├── .env
└── README.md
```

### `src/`

The `src` folder contains the real protocol contracts. These are the contracts that should eventually be deployed. Contracts in `src` should contain the core business logic of the protocol.

### `script/`

The `script` folder contains deployment and configuration logic. Deployment scripts should not contain protocol logic. Their job is to deploy contracts, wire dependencies together, transfer ownership if needed, and return deployed contract instances.

### `test/`

The `test` folder contains tests and testing utilities. Tests should verify that the protocol behaves correctly in normal cases, edge cases, and revert cases.

### `test/mocks/`

Mocks are simplified fake contracts used for local testing They are useful when the real external dependency is not available locally, too expensive to use, or not necessary for the specific test.

Examples:

```text
MockV3Aggregator  -> fake Chainlink price feed
ERC20Mock         -> fake ERC20 token such as WETH or WBTC
```

---

## 2. General development flow

A beginner-friendly flow for most Foundry projects is:

```text
1. Define the protocol idea
2. Define the core contracts
3. Define external dependencies
4. Create mocks for local testing
6. Create deployment script
5. Create HelperConfig for network-specific addresses
7. Write unit tests
8. Write integration tests
9. Test locally with Anvil
10. Deploy to testnet
11. Verify behavior on testnet
12. Prepare for mainnet only after strong testing and review
```

---

## 3. Step 1: define the protocol idea

Before writing Solidity code, the developer should write a simple description of what the protocol does.

Example:

```text
This protocol allows users to deposit approved collateral tokens and mint a decentralized stablecoin against that collateral.
```

Then define the main actors and actions.

Actors:

- User
- Protocol contract
- Stablecoin contract
- External price feed
- Collateral token

Actions (in this example):

- Deposit collateral
- Mint stablecoin
- Burn stablecoin
- Redeem collateral
- Liquidate unsafe positions

This helps avoid writing random functions without a clear protocol flow.

---

## 4. Step 2: Define the core contracts

A project usually has one or more core contracts in `src`.

In the reference project, there are two main contracts:

```text
DecentralizedStablecoin.sol
DSCEngine.sol
```

### Token Contract

The token contract should only handle token behavior. It should not contain the full protocol logic.

Example:

```text
- ERC20 name and symbol
- minting
- burning
- ownership restriction
```

### Engine

The engine contract should contain the core protocol rules.

Example:

```text
- accepted collateral tokens
- collateral deposits
- minting logic
- redeeming logic
- health factor logic
- liquidation logic
- price feed usage
```

This separation makes the system easier to reason about.

---

## 5. Step 3: Organize contract layout

A consistent Solidity layout makes contracts easier to read and maintain.

Recommended contract layout:

```text
1. SPDX license
2. pragma
3. imports
4. interfaces, libraries,contracts
5. errors
6. type declarations
7. state variables
8. events
9. modifiers
10. constructor
11. receive / fallback functions, if needed
12. public & external functions (no view/pure)
13. private & internal functions (no view/pure)
14. public & external view functions
15. private & internal view functions
16. public & external pure functions
17. private & internal pure functions
```

This is not mandatory, but it helps make every project predictable.

---

## 6. Step 4: Use custom errors

Custom errors are preferred over long revert strings because they are cheaper and clearer.

Example:

```solidity
error DSCEngine__NeedsMoreThanZero();
error DSCEngine__TokenNotAllowed();
error DSCEngine__TransferFailed();
error DSCEngine__BreaksHealthFactor(uint256 healthFactor);
```

A good pattern is:

```text
ContractName__ErrorName
```

This makes it clear which contract produced the error.

---

## 7. Step 5: Use modifiers for repeated checks

Modifiers are useful for checks that appear in many functions.

Example:

```solidity
modifier moreThanZero(uint256 amount) {
    if (amount == 0) {
        revert DSCEngine__NeedsMoreThanZero();
    }
    _;
}
```

Modifiers should stay simple. If the logic becomes complex, an internal function is usually better.

---

## 8. Step 6: Follow CEI

CEI means:

```text
Checks
Effects
Interactions
```

This is a common Solidity safety pattern.

- Checks: validate inputs and protocol conditions.

    ```solidity
    if (amount == 0) revert DSCEngine__NeedsMoreThanZero();
    ```

- Effects: update internal state.

    ```solidity
    s_collateralDeposited[msg.sender][token] += amount;
    ```

- Interactions: interact with external contracts after state updates.

    ```solidity
    bool success = IERC20(token).transferFrom(msg.sender, address(this), amount);
    if (!success) revert DSCEngine__TransferFailed();
    ```

This pattern reduces reentrancy risk and makes function flow easier to audit.

---

## 9. Step 7: Use reentrancy protection when needed

When a function transfers tokens or ETH, or calls an external contract, it may need reentrancy protection.

In OpenZeppelin, this is usually done with:

```solidity
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
```

Then:

```solidity
contract DSCEngine is ReentrancyGuard {
    function depositCollateral(...) external nonReentrant {
        ...
    }
}
```

Reentrancy is a vulnerability that can happen when a contract calls an external contract before updating its own internal state.
If the external contract is malicious, it can call back into the original function before the first execution is finished. If the state has not been updated yet, the function may still see the old balance, old debt, or old collateral value and execute again incorrectly.
s
Use `nonReentrant` especially when a function:

- transfers ERC20 tokens
- sends ETH
- calls unknown external contracts
- updates balances and then interacts externally

---

## 10. Step 8: Use interfaces for external dependencies

When a contract interacts with an external protocol, it should usually use an interface.

Examples:

```solidity
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
```

This allows the contract to interact with external contracts without needing their full implementation.

---

## 11. Step 9: Use a helperConfig for network management

A `HelperConfig` script is useful when the project needs different addresses depending on the network.

For example:

Sepolia:

- real WETH address
- real WBTC address
- real Chainlink price feeds
- real deployer key

Anvil:

- mock WETH
- mock WBTC
- mock price feeds
- local deployer key

This avoids hardcoding everything inside the deployment script. The constructor can select the correct configuration based on `block.chainid`.

This pattern is very useful for beginner projects because the same deployment script can work locally and on testnet.

---

## 12. Step 10: Use mocks for local development

Mocks are essential when testing locally with Anvil. For example, on Sepolia there may be real Chainlink price feeds. Locally, there are no real Chainlink price feeds unless they are deployed manually.

So the project deploys a mock price feed:

```solidity
MockV3Aggregator ethUsdPriceFeed = new MockV3Aggregator(
    DECIMALS,
    ETH_USD_PRICE
);
```

And mock collateral tokens:

```solidity
ERC20Mock wethMock = new ERC20Mock("WETH", "WETH", msg.sender, 1000e8);
ERC20Mock wbtcMock = new ERC20Mock("WBTC", "WBTC", msg.sender, 1000e8);
```

Mocks allow the developer to test protocol behavior without relying on real external infrastructure.Do not use mocks for production deployment.

---

## 13. Step 11: Create a deployment script

A deployment script should do only deployment and setup.

Typical responsibilities:

```text
1. Create HelperConfig
2. Read active network configuration
3. Build arrays or constructor parameters
4. Start broadcast with the correct deployer key
5. Deploy contracts
6. Wire contracts together
7. Transfer ownership if needed
8. Stop broadcast
9. Return deployed contracts
```

The ownership transfer is important when the engine must be the only contract allowed to mint and burn the stablecoin.

---

## 14. Step 12: Write tests in layers

A strong testing workflow usually has multiple layers.

### Unit Tests

Test one function at a time.

Examples:

```text
- depositCollateral reverts if amount is zero
- depositCollateral reverts if token is not allowed
- depositCollateral updates user balance
- mintDSC reverts if health factor is broken
```

### Integration Tests

Test multiple contracts working together.

Examples:

```text
- user deposits WETH and mints DSC
- user deposits collateral, price changes, then liquidation becomes possible
- deployment script deploys all contracts correctly
```

### Fork Tests

Test against real network state.

Examples:

```text
- use Sepolia price feed addresses
- use real token addresses
- verify deployment assumptions
```

### Fuzz Tests

Test with many random inputs.

Examples:

```text
- random collateral amounts
- random mint amounts
- random price changes
```

Fuzz tests are useful when the protocol has math-heavy logic.

---

## 15. Step 13: Test deployment scripts

Deployment scripts are code and should also be tested.

A simple deployment test can verify:

```text
- contracts deploy correctly
- engine address is not zero
- stablecoin address is not zero
- engine owns the stablecoin
- collateral token addresses are configured
- price feed addresses are configured
```

This helps catch broken constructor parameters before testnet deployment.

---

## 16. Step 14: Use Environment Variables

Private keys and RPC URLs should not be hardcoded.

Use a `.env` file:

```text
SEPOLIA_RPC_URL=...
SEPOLIA_PRIVATE_KEY=...
ETHERSCAN_API_KEY=...
LOC_PRIVATE_KEY=...
```

Then load them in Foundry commands or scripts.

Example in Solidity script:

```solidity
deployerKey: vm.envUint("SEPOLIA_PRIVATE_KEY")
```

Important rule:

```text
Never commit private keys to GitHub.
```

The `.env` file should be listed in `.gitignore`.

---

## 17. General checklist for a new foundry project

Before writing code:

```text
- What is the protocol supposed to do?
- Who are the users?
- What are the main actions?
- What external protocols are needed?
- Are mocks needed?
- Which networks should be supported?
```

When writing contracts:

```text
- Keep protocol logic in src
- Keep deployment logic in script
- Keep tests in test
- Use custom errors
- Use events for important state changes
- Use modifiers for simple repeated checks
- Use CEI
- Use ReentrancyGuard when needed
- Use interfaces for external contracts
- Keep decimals and precision consistent
```

When writing deployment scripts:

```text
- Use HelperConfig
- Avoid hardcoded addresses inside Deploy scripts
- Start broadcast with the correct deployer key
- Deploy contracts in the correct order
- Wire constructor dependencies correctly
- Transfer ownership if needed
- Return deployed contracts
```

When writing tests:

```text
- Test expected success cases
- Test expected revert cases
- Test edge cases
- Test deployment
- Test mocks
- Test with fuzzing when math is important
- Test with fork mode when external addresses matter
```

Before deploying:

```text
- Run forge build
- Run forge test
- Run forge coverage if useful
- Check .env values
- Check network addresses
- Check constructor arguments
- Check ownership transfers
- Check verification settings
```

---

## 18. When these structures are needed?

Not every project needs all components.

### Use `HelperConfig` when

```text
- the project deploys to multiple networks
- addresses change by network
- mocks are needed locally
- deployment should be reusable
```

### Use mocks when

```text
- the project depends on external contracts
- local testing needs fake tokens
- local testing needs fake price feeds
- edge cases are hard to reproduce with real contracts
```

### Use Chainlink price feeds when

```text
- the protocol needs asset prices
- collateral value must be calculated
- liquidation depends on market prices
```

### Use ERC20 mocks when

```text
- the protocol uses ERC20 tokens
- tests need local token balances
- tests need minting and burning flexibility
```

### Use ownership transfer when

```text
- one contract should control another contract
- an engine should be the only minter of a token
- protocol logic must be centralized in a manager contract
```

---

## 27. Mental model

A good Foundry project can be thought of like this:

```text
src/      = what the protocol is
script/   = how the protocol is deployed
config    = where the protocol is deployed
mocks     = fake external world for local testing
test/     = proof that the protocol behaves correctly
```

The cleaner the separation, the easier the project becomes to test, deploy, debug, and reuse.
