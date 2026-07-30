
# Stablecoin

- Use Chainlink Price Feeds.
- Create a function to exchange ETH and BTC for stablecoin value.

## Project goal

This project implements the base token contract for a decentralized stablecoin called `DecentralizedStablecoin` (`DSC`).

The idea is to build an ERC20 token that will be used inside a larger stablecoin system governed by a separate contract called `DSCEngine`.

The `DSC` token itself does not manage collateral, liquidations, health factor, price feeds, or peg logic. Its only responsibility is to behave as the ERC20 representation of the stablecoin and allow minting and burning only through the authorized contract.

## Stablecoin model

This stablecoin is designed to be:

- Exogenous: the collateral comes from assets outside the protocol, such as wETH and wBTC.
- Decentralized: the system does not depend on a single centralized issuer.
- Anchored / Pegged: the target value is anchored to the US dollar.
- Crypto Collateralized: the stablecoin is backed by crypto assets deposited as collateral.
- Algorithmically Minted: the amount of DSC that can be minted is determined by rules enforced by the protocol engine.

In practice, `DecentralizedStablecoin` is only the token. The actual economic logic lives inside `DSCEngine`.

## Why DSC and DSCEngine are separated?

The `DecentralizedStablecoin` contract is intentionally simple in order to reduce risk.

The token only knows:

1. how to behave as an ERC20 token;
2. who is allowed to mint;
3. who is allowed to burn;
4. which basic checks must be applied to amounts and addresses.

The `DSCEngine`, instead, is responsible for:

1. accepting collateral;
2. reading collateral prices through oracles;
3. calculating the USD value of deposited collateral;
4. deciding how much DSC can be minted;
5. handling liquidations;
6. keeping the protocol overcollateralized.

## Choice of standards

The contract inherits from OpenZeppelin’s `ERC20Burnable` and `Ownable`.

`ERC20Burnable` provides the standard ERC20 behavior plus burn functionality.

`Ownable` allows certain functions to be restricted to the owner. In this project, the owner should eventually be the `DSCEngine`, not a regular user. This way, only the engine can mint or burn DSC.

## Stablecoin Reasoning Flow

### High-Level Architecture

The protocol is built around one main idea: users should not control the stablecoin supply directly. Users interact with the `DSCEngine`, and the `DSCEngine` decides whether the action is safe. Only after the engine has checked collateral, prices, debt, and health factor does it interact with the `DecentralizedStablecoin` contract.

Users
 |
 | deposit collateral / mint DSC / repay DSC / redeem collateral
 v
DSCEngine
 |
 | checks prices, collateral value, health factor, liquidations
 v
DecentralizedStablecoin
 |
 | mints and burns only when DSCEngine says so
 v
DSC Token

### Responsibility Separation

The system is separated into two main contracts because the token should stay simple and the protocol logic should live in the engine. The `DecentralizedStablecoin` contract only represents the ERC20 stablecoin. It handles token behavior, minting, burning, basic amount checks, address checks, and ownership restrictions. The `DSCEngine` handles collateral deposits, collateral redemptions, Chainlink price feeds, USD value calculations, health factor checks, minting rules, repayment logic, and liquidations.

Stablecoin System
 |
 |-- DecentralizedStablecoin
 |      |
 |      |-- ERC20 token behavior
 |      |-- mint function
 |      |-- burn function
 |      |-- basic amount/address checks
 |      |-- onlyOwner restriction
 |
 |-- DSCEngine
        |
        |-- collateral deposits
        |-- collateral redemptions
        |-- Chainlink price feeds
        |-- USD value calculation
        |-- health factor checks
        |-- minting rules
        |-- repayment logic
        |-- liquidation logic

### Stablecoin Model

The stablecoin is designed to be exogenous, decentralized, anchored to the US dollar, crypto-collateralized, and algorithmically minted. The collateral comes from external assets such as wETH and wBTC. The target is `1 DSC ≈ $1.00`. The protocol does not rely on a centralized issuer. Instead, DSC is minted only when the user has enough collateral, and the whole system should remain overcollateralized.

Stablecoin Goal
 |
 |-- Relative Stability
 |      |
 |      v
 |   1 DSC ≈ $1.00
 |
 |-- Collateral Type
 |      |
 |      v
 |   Exogenous collateral: wETH / wBTC
 |
 |-- Backing Model
 |      |
 |      v
 |   Crypto collateralized
 |
 |-- Minting Model
 |      |
 |      v
 |   Algorithmically minted through DSCEngine
 |
 |-- Solvency Model
        |
        v
     Overcollateralized positions

### Ownership Flow

At deployment, the deployer becomes the initial owner of the `DecentralizedStablecoin` contract. This is only the starting point. In the complete system, ownership should be transferred to the `DSCEngine`, because the engine must be the only contract allowed to mint and burn DSC. This prevents users from creating or destroying DSC directly without going through the collateral and health factor checks.

Deploy DecentralizedStablecoin
 |
 v
Deployer becomes initial owner
 |
 v
Deploy DSCEngine
 |
 v
Transfer DSC ownership to DSCEngine
 |
 v
DSCEngine becomes the only contract allowed to mint and burn DSC
 |
 v
Users interact with DSCEngine, not directly with DSC mint/burn logic

### Minting Flow

Minting starts when a user wants to create DSC. The user must first deposit approved collateral into the `DSCEngine`. The engine records the collateral, reads the collateral price using Chainlink Price Feeds, converts the collateral amount into USD value, and calculates whether the user will remain sufficiently collateralized after minting. If the position is not safe, the transaction reverts. If the position is safe, the engine calls `mint` on the `DecentralizedStablecoin` contract.

User wants to mint DSC
 |
 v
User deposits approved collateral into DSCEngine
 |
 v
DSCEngine records user's collateral balance
 |
 v
DSCEngine reads collateral price from Chainlink Price Feed
 |
 v
DSCEngine converts collateral amount into USD value
 |
 v
DSCEngine calculates user's health factor
 |
 v
Is the user sufficiently collateralized?
 |
 |-- No
 |     |
 |     v
 |   Transaction reverts
 |
 |-- Yes
       |
       v
    DSCEngine calls DecentralizedStablecoin.mint(user, amount)
       |
       v
    DecentralizedStablecoin checks caller is owner
       |
       v
    DecentralizedStablecoin checks receiver is not address(0)
       |
       v
    DecentralizedStablecoin checks amount is greater than zero
       |
       v
    DSC is minted to user

### Mint Function Internal Flow

Inside the token contract, the mint function does not check collateral. That has already been done by the `DSCEngine`. The token only checks that the caller is the owner, that the receiver is not the zero address, and that the mint amount is not zero. If all checks pass, the token mints DSC to the receiver and returns `true`.

mint(_to,_amount)
 |
 |-- Is msg.sender the owner?
 |      |
 |      |-- No -> revert
 |      |
 |      |-- Yes
 |            |
 |            v
 |         Is _to address(0)?
 |            |
 |            |-- Yes -> revert DecentralizedStablecoin__NotZeroAddress
 |            |
 |            |-- No
 |                  |
 |                  v
 |               Is_amount == 0?
 |                  |
 |                  |-- Yes -> revert DecentralizedStablecoin__MustBeMoreThanZero
 |                  |
 |                  |-- No
 |                        |
 |                        v
 |                     _mint(_to, _amount)
 |                        |
 |                        v
 |                     return true

### Deposit Collateral and Mint DSC Flow

A combined function such as `depositCollateralAndMintDsc` would allow the user to deposit collateral and mint DSC in one transaction. The engine first transfers collateral from the user, updates the user’s collateral balance, calculates the USD value of that collateral, calculates the new DSC debt after minting, and then checks the user’s health factor. Only if the health factor remains acceptable does the engine mint DSC to the user.

User
 |
 | depositCollateralAndMintDsc(collateralToken, collateralAmount, dscAmount)
 v
DSCEngine
 |
 | transfer collateral from user to DSCEngine
 v
DSCEngine
 |
 | update user's collateral balance
 v
DSCEngine
 |
 | calculate USD value of deposited collateral
 v
DSCEngine
 |
 | calculate new DSC debt after minting
 v
DSCEngine
 |
 | check health factor after minting
 v
Is health factor acceptable?
 |
 |-- No
 |     |
 |     v
 |   revert
 |
 |-- Yes
       |
       v
    call DSC.mint(user, dscAmount)
       |
       v
    user receives DSC

### Repayment and Burning Flow

Burning is used when a user repays DSC debt. The user gives DSC back to the `DSCEngine`. The engine reduces the user’s recorded debt and then burns the DSC it received. This decreases the total DSC supply and keeps the token supply aligned with the debt accounting inside the protocol.

User wants to repay DSC debt
 |
 v
User sends DSC back to DSCEngine
 |
 v
DSCEngine reduces user's recorded DSC debt
 |
 v
DSCEngine calls DecentralizedStablecoin.burn(amount)
 |
 v
DecentralizedStablecoin checks caller is owner
 |
 v
DecentralizedStablecoin checks amount is greater than zero
 |
 v
DecentralizedStablecoin checks DSCEngine has enough DSC to burn
 |
 v
DecentralizedStablecoin calls super.burn(amount)
 |
 v
DSC supply decreases

### Burn Function Internal Flow

Inside the token contract, the burn function checks that the caller is the owner, that the amount is not zero, and that the caller has enough DSC to burn. Then it calls `super.burn(_amount)` to use the original burn logic from OpenZeppelin.

burn(_amount)
 |
 |-- Is msg.sender the owner?
 |      |
 |      |-- No -> revert
 |      |
 |      |-- Yes
 |            |
 |            v
 |         Get balanceOf(msg.sender)
 |            |
 |            v
 |         Is_amount == 0?
 |            |
 |            |-- Yes -> revert DecentralizedStablecoin__MustBeMoreThanZero
 |            |
 |            |-- No
 |                  |
 |                  v
 |               Is balance < _amount?
 |                  |
 |                  |-- Yes -> revert DecentralizedStablecoin__BurnAmountExceedsBalance
 |                  |
 |                  |-- No
 |                        |
 |                        v
 |                     super.burn(_amount)

### Redeem Collateral Flow

Redeeming collateral means the user wants to withdraw part of the collateral previously deposited. The engine must make sure that withdrawing collateral does not make the user’s position unsafe. It checks the user’s collateral balance, calculates the health factor after redemption, and only transfers collateral back if the position remains healthy.

User wants collateral back
 |
 v
User calls redeemCollateral
 |
 v
DSCEngine checks user's collateral balance
 |
 v
DSCEngine calculates user's health factor after redemption
 |
 v
Would redemption make the position unsafe?
 |
 |-- Yes
 |     |
 |     v
 |   Transaction reverts
 |
 |-- No
       |
       v
    DSCEngine updates user's collateral balance
       |
       v
    DSCEngine transfers collateral back to user

### Redeem Collateral for DSC Flow

A user may also want to repay DSC and redeem collateral in the same operation. In that case, the user sends DSC to the engine, the engine reduces the user’s debt, burns the returned DSC, checks the remaining collateral and health factor, and finally releases collateral back to the user if the position is safe.

User wants to repay DSC and redeem collateral
 |
 v
User sends DSC to DSCEngine
 |
 v
DSCEngine reduces user's DSC debt
 |
 v
DSCEngine burns returned DSC
 |
 v
DSCEngine checks remaining collateral and health factor
 |
 v
Is the position still healthy?
 |
 |-- No
 |     |
 |     v
 |   Transaction reverts
 |
 |-- Yes
       |
       v
    DSCEngine releases collateral to user

### Liquidation Flow

Liquidation protects the system when a user becomes undercollateralized. If the value of the user’s collateral falls too much, the health factor drops below the minimum threshold. A liquidator can repay part of that user’s DSC debt. The engine burns the repaid DSC, reduces the unsafe user’s debt, and transfers part of the unsafe user’s collateral to the liquidator, usually with a liquidation bonus.

A user's position becomes undercollateralized
 |
 v
Health factor falls below minimum threshold
 |
 v
Liquidator detects unsafe position
 |
 v
Liquidator repays part of the unsafe user's DSC debt
 |
 v
DSCEngine receives DSC from liquidator
 |
 v
DSCEngine burns repaid DSC
 |
 v
DSCEngine reduces unsafe user's debt
 |
 v
DSCEngine transfers part of unsafe user's collateral to liquidator
 |
 v
Liquidator receives collateral plus liquidation incentive
 |
 v
Unsafe user's position becomes healthier

When a user deposits collateral and mints DSC, two separate things are created: the user receives DSC tokens in their wallet, and the protocol records a debt position inside the `DSCEngine`.

example: if the user deposits $100 worth of ETH and mints 50 DSC, the user now has 50 DSC tokens, but also owes 50 DSC to the protocol. The collateral is locked as a guarantee for that debt.

The important point is that the DSC tokens in the wallet and the DSC debt in the engine are not the same thing. The user can keep, spend, transfer, or swap the 50 DSC tokens. The debt remains recorded in the protocol until someone repays it. If the value of the collateral falls too much, the position can become undercollateralized. At that point, the protocol allows a liquidator to step in. The liquidator repays the user’s DSC debt using their own DSC. The protocol burns that DSC and gives the liquidator part or all of the user’s collateral, usually with a bonus. So the liquidator is not paying the user’s debt for free. The liquidator is buying the user’s collateral at an attractive rate by repaying the user’s debt. If the user comes back before liquidation with 50 DSC, they can repay their own debt, the DSC gets burned, and they can recover their collateral. This is the best outcome for the user. If the user comes back after liquidation, it is too late. The debt has already been repaid by the liquidator, and the collateral has already been transferred to the liquidator. The user may still have 50 DSC tokens in their wallet, but those tokens are now just normal ERC20 tokens. They are no longer connected to the liquidated position.

This is why the user still has an incentive to maintain a healthy collateral ratio. If they do, they can repay the debt and recover their collateral. If they do not, someone else can repay the debt and take the collateral. The user may keep the DSC tokens they minted, but they lose the collateral that backed those tokens, usually at a worse rate because liquidation includes an incentive for the liquidator.

### Price Feed Flow

Price feeds are needed because the engine must know the USD value of each collateral token. When the engine needs to evaluate a position, it selects the collateral token, finds the matching Chainlink price feed, reads the latest price, normalizes decimals, and converts the token amount into USD value. That USD value is then used for minting, redemption, health factor checks, and liquidations.

DSCEngine needs collateral value
 |
 v
DSCEngine selects collateral token
 |
 v
DSCEngine finds matching Chainlink price feed
 |
 v
DSCEngine reads latest price
 |
 v
DSCEngine normalizes price decimals
 |
 v
DSCEngine converts token amount into USD value
 |
 v
USD value is used for minting, redemption, health factor, and liquidation checks

### Health Factor Flow

The health factor represents how safe a user’s position is. The engine calculates the collateral value in USD, applies the liquidation threshold, and compares the adjusted collateral value against the user’s DSC debt. If the health factor is healthy, the user can keep the position open, mint more if allowed, or redeem collateral if still safe. If the health factor is unhealthy, the user cannot mint more and the position can be liquidated.

User position
 |
 |-- collateral deposited
 |-- DSC minted / debt created
 v
DSCEngine calculates collateral value in USD
 |
 v
DSCEngine calculates adjusted collateral value using liquidation threshold
 |
 v
DSCEngine compares adjusted collateral value against DSC debt
 |
 v
Health factor result
 |
 |-- Healthy
 |      |
 |      v
 |   User can mint, redeem, or keep position open
 |
 |-- Unhealthy
        |
        v
     User cannot mint more / position can be liquidated

### Full User Lifecycle Flow

The complete user lifecycle starts with a collateral deposit. The engine records the collateral, reads the price feed, calculates the collateral value, and allows the user to mint DSC only if the position remains safe. Later, the user can repay DSC, the engine burns the repaid tokens, and then the user can redeem collateral. The position can be reduced or fully closed.

User deposits wETH / wBTC
 |
 v
DSCEngine records collateral
 |
 v
DSCEngine reads Chainlink price feed
 |
 v
DSCEngine calculates collateral USD value
 |
 v
User requests DSC mint
 |
 v
DSCEngine checks health factor
 |
 v
If healthy, DSCEngine mints DSC to user
 |
 v
User now has DSC debt
 |
 v
Later, user repays DSC
 |
 v
DSCEngine burns repaid DSC
 |
 v
User redeems collateral
 |
 v
Position is closed or reduced

### Contract Role Summary Flow

The `DecentralizedStablecoin` contract is only the ERC20 representation of the stablecoin. It does not know collateral, prices, health factor, or liquidation rules. The `DSCEngine` is the protocol brain. It knows the collateral, prices, user debt, health factor, and liquidation rules. Therefore, the engine controls when DSC can be minted or burned.

DecentralizedStablecoin
 |
 | simple ERC20 representation of the stablecoin
 | does not know collateral
 | does not know prices
 | does not know health factor
 | does not know liquidations
 v
Only executes mint and burn

DSCEngine
 |
 | protocol brain
 | knows collateral
 | knows prices
 | knows user debt
 | knows health factor
 | knows liquidation rules
 v
Controls when DSC can be minted or burned

### Core Reasoning Flow

The main reasoning is that a stablecoin needs relative stability. Relative stability requires controlled supply. Controlled supply requires mint and burn restrictions. Minting must depend on collateral value. Collateral value requires price feeds. Price feeds allow health factor calculation. Health factor decides whether minting or redemption is safe. Unsafe positions require liquidations. Therefore, the `DSCEngine` manages the protocol logic, while `DecentralizedStablecoin` remains a simple ERC20 controlled by the engine.

Stablecoin needs relative stability
 |
 v
Relative stability requires controlled supply
 |
 v
Controlled supply requires mint and burn restrictions
 |
 v
Minting must depend on collateral value
 |
 v
Collateral value requires price feeds
 |
 v
Price feeds allow health factor calculation
 |
 v
Health factor decides whether minting/redemption is safe
 |
 v
Unsafe positions require liquidations
 |
 v
Therefore, DSCEngine manages the protocol logic
 |
 v
DecentralizedStablecoin remains a simple ERC20 controlled by DSCEngine

#### Reentrancy problem

Reentrancy is a vulnerability that can happen when a contract calls an external contract before updating its own internal state.
If the external contract is malicious, it can call back into the original function before the first execution is finished. If the state has not been updated yet, the function may still see the old balance, old debt, or old collateral value and execute again incorrectly.

Example:

A user withdraws funds. If the contract sends the funds first and updates the user balance after, a malicious contract can reenter `withdraw()` before the balance is reduced and withdraw more than it should.

## Health Factor Calculation

The `_healthFactor` function calculates whether a user has enough collateral to safely back their minted DSC.
The important part of this calculation is the multiplication before the division:

(collateralAdjustedForThreshold * PRECISION) / totalDscMinted

Solidity does not support decimal numbers for `uint256`. When a division produces a decimal result, Solidity truncates the decimal part.

For example, mathematically: 75 / 100 = 0.75

But in Solidity integer math: 75 / 100 = 0

So the decimal part is lost. This would be a problem for the health factor because a value like `0.75` is important: it means the position is below the minimum health factor and can be liquidated. If Solidity returned only `0`, useful precision would be lost.

To avoid this, the contract scales the numerator before dividing by multiplying it by `PRECISION`.

If PRECISION = 1e18;
then instead of calculating: 75 / 100 = 0
the contract calculates: 75 *1e18 / 100 = 750000000000000000
This value represents: 0.75* 1e18

So the protocol preserves the decimal information while still using integers.

So the general rule is: (a * PRECISION) / b
instead of: a / b

Multiplying first preserves decimal precision before Solidity performs the integer division.
