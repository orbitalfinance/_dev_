// SPDX-License-Identifier: MIT

§)
// Fallback function (if exists)
// External, Public, Internal,Private
// View & pure functions

pragma solidity ^0.8.30;

/**
 * @title DSCEngine
 * @author Santo Mancuso
 *
 * It is similar to DAI if DAI had no governance, no fees, and was only backed by WETH and
 * WBTC.
 *
 * The DSC system shoul be overcollateralized. At no point the value of all the
 * collateral must be equal or lower of the backed value of all the DSC.
 *
 * @notice This contract is the core of the DSC System. It handles all the logic for minting
 * and redeeming DSC, as well as depositing & withdrawing collateral. In general, it can be useful
 * to define an IDSCEngine interface so other contracts can interact with the engine through its
 * public API without depending directly on the full DSCEngine implementation.
 *
 * @notice This contract is VERY loosely based on the MakerDAO DSS (Dai Stablecoin System).
 */

////////////////////////////
// Imports
////////////////////////////
import {DecentralizedStablecoin} from "./DecentralizedStablecoin.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract DSCEngine is ReentrancyGuard {
    ////////////////////////////
    // Errors
    ////////////////////////////
    error DCSEngine__NeedsMoreThanZero();
    error DSCEngine__TokenAddressesANdPriceFeedAddressesMustBeSameLength();
    error DCSEngine__NotAllowedToken();
    error DSCEngine__TransferFailed();
    error DSCEngine__BreaksHealthFactor(uint256 healthFactor);
    error DSCEngine__MintFailed();

    ////////////////////////////
    // State variables
    ////////////////////////////

    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10;
    uint256 private constant PRECISION = 1e18;
    uint256 private constant LIQUIDATION_THRESHOLD = 50; // 200% overcollateralized
    uint256 private constant LIQUIDATION_PRECISION = 100;
    uint256 private constant MIN_HEALTH_FACTOR = 1;

    mapping(address token => address priceFeed) private s_priceFeeds;
    mapping(address user => mapping(address token => uint256 amount)) private s_collateralDeposited;
    mapping(address user => uint256 amountDSCMinted) private s_DSCMinted;

    address[] private s_collateralTokens;

    DecentralizedStablecoin private immutable i_dsc;

    ////////////////////////////
    // Events
    ////////////////////////////
    event CollateralDeposited(address indexed user, address indexed token, uint256 amount);
    event CollateralRedeemed(address indexed user, address indexed token, uint256 indexed amount);

    ////////////////////////////
    // Modifiers
    ////////////////////////////
    modifier moreThanZero(uint256 amount) {
        if (amount == 0) {
            revert DCSEngine__NeedsMoreThanZero();
        }
        _;
    }

    modifier isTokenAllowed(address token) {
        if (s_priceFeeds[token] == address(0)) {
            revert DCSEngine__NotAllowedToken();
        }

        _;
    }

    ////////////////////////////
    // Constructor
    ////////////////////////////
    constructor(address[] memory tokenAddresses, address[] memory priceFeedAddresses, address dscAddress) {
        if (tokenAddresses.length != priceFeedAddresses.length) {
            revert DSCEngine__TokenAddressesANdPriceFeedAddressesMustBeSameLength();
        }

        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            s_priceFeeds[tokenAddresses[i]] = priceFeedAddresses[i];
            s_collateralTokens.push(tokenAddresses[i]);
        }

        i_dsc = DecentralizedStablecoin(dscAddress);
    }

    ////////////////////////////
    // External functions
    ////////////////////////////

    /*
     * @param tokenCollateralAddress The address of the token to deposit as collateral
     * @param amountCollateral The amount of collateral to deposit
     * @param amountDscToMint The amount of decentralized stablecoin to mint
     * @notice This function will deposit your collateral and mint DSC in one transaction
     */
    function depositCollateralAndMintDSC(
        address tokenCollateralAddress,
        uint256 amountCollateral,
        uint256 amountDSCToMint
    ) external {
        depositCollateral(tokenCollateralAddress, amountCollateral);
        mintDSC(amountDSCToMint);
    }

    /**
     * @param tokenCollateralAddress The address of the collateral to redeem
     * @param amountCollateral The amount of collateral to redeem
     * @param amountDscToBurn The amount of DSC to burn
     * This function burns DSC and redeems underlying collateral in one transaction
     */
    function redeemCollateralForDsc(address tokenCollateralAddress, uint256 amountCollateral, uint256 amountDscToBurn)
        external
    {
        burnDsc(amountDscToBurn);
        redeemCollateral(tokenCollateralAddress, amountCollateral);
        // redeemCollateral already checks health factor
    }

    // In order to redeem collateral health factor must be over 1 AFTER collateral pulled
    function redeemCollateral(address tokenCollateralAddress, uint256 amountCollateral)
        public
        moreThanZero(amountCollateral)
        nonReentrant
    {
        s_collateralDeposited[msg.sender][tokenCollateralAddress] -= amountCollateral;

        emit CollateralRedeemed(msg.sender, tokenCollateralAddress, amountCollateral);

        bool success = IERC20(tokenCollateralAddress).transfer(msg.sender, amountCollateral);
        if (!success) {
            revert DSCEngine__TransferFailed();
        }

        _revertIfHealthFactorIsBroken(msg.sender);
    }

    // Do we need to check if this breaks health factor?
    // 1. Riduce il debito interno dell’utente
    // 2. Prende i DSC dal wallet dell’utente
    // 3. Distrugge quei DSC dalla supply totale
    /*
    Prima:
    utente ha 100 DSC di debito
    utente ha 100 DSC nel wallet
    totalSupply DSC = 100

    burnDsc(40)

    Dopo:
    utente ha 60 DSC di debito
    utente ha 60 DSC nel wallet
    totalSupply DSC = 60
        */

    function burnDsc(uint256 amount) public moreThanZero(amount) {
        s_DSCMinted[msg.sender] -= amount;

        bool success = i_dsc.transferFrom(msg.sender, address(this), amount);

        // This conditional is hypothetically unreachable
        if (!success) {
            revert DSCEngine__TransferFailed();
        }

        i_dsc.burn(amount);

        _revertIfHealthFactorIsBroken(msg.sender); // I don't think this would ever hit...
    }

    function liquidate() external {}

    function getHealthFactor() external view {}

    ////////////////////////////
    // Public functions
    ////////////////////////////

    /**
     *
     * @param tokenCollateralAddress: the address of the token to deposit as collater
     * @param amountCollateral: the amount of collateral to deposit
     */

    function depositCollateral(address tokenCollateralAddress, uint256 amountCollateral)
        public
        moreThanZero(amountCollateral)
        isTokenAllowed(tokenCollateralAddress)
        nonReentrant
    {
        s_collateralDeposited[msg.sender][tokenCollateralAddress] += amountCollateral;
        emit CollateralDeposited(msg.sender, tokenCollateralAddress, amountCollateral);

        bool success = IERC20(tokenCollateralAddress).transferFrom(msg.sender, address(this), amountCollateral);
        if (!success) {
            revert DSCEngine__TransferFailed();
        }
    }

    // Check if the collateral value > DSC amount
    function mintDSC(uint256 amountDSCToMint) public moreThanZero(amountDSCToMint) nonReentrant {
        s_DSCMinted[msg.sender] += amountDSCToMint;
        _revertIfHealthFactorIsBroken(msg.sender);
        bool minted = i_dsc.mint(msg.sender, amountDSCToMint);
        if (!minted) {
            revert DSCEngine__MintFailed();
        }
    }

    ////////////////////////////
    // Public & External view functions
    ////////////////////////////

    function getAccountCollateralValue(address user) public view returns (uint256 totalCollateralValueInUsd) {
        // loop through each collateral token, get the amount they have deposited, and map it to
        // the price, to get the USD value
        for (uint256 i = 0; i < s_collateralTokens.length; i++) {
            address token = s_collateralTokens[i];
            uint256 amount = s_collateralDeposited[user][token];
            totalCollateralValueInUsd += getUsdValue(token, amount);
        }
        return totalCollateralValueInUsd;
    }

    function getUsdValue(address token, uint256 amount) public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[token]);
        (, int256 price,,,) = priceFeed.latestRoundData(); // The number returned from ChainLink has 8 decimal places
        return ((uint256(price) * ADDITIONAL_FEED_PRECISION) * amount) / PRECISION;
    }

    ////////////////////////////
    // Private & Internal view functions
    ////////////////////////////

    function _getAccountInformation(address user)
        private
        view
        returns (uint256 totalDscMinted, uint256 collateralValueInUsd)
    {
        totalDscMinted = s_DSCMinted[user];
        collateralValueInUsd = getAccountCollateralValue(user);
    }

    /*
    * It returns how close to liquidation a user is
    * If a user goes below 1, it can get liquidated
    */
    function _healthFactor(address user) private view returns (uint256) {
        // total DSC minted
        // total collateral VALUE
        (uint256 totalDscMinted, uint256 collatearlValueInUsd) = _getAccountInformation(user);
        uint256 collateralAdjustedForThreshold = (collatearlValueInUsd * LIQUIDATION_THRESHOLD) / LIQUIDATION_PRECISION;

        // $150 ETH e 100 DSC
        // 150 * 50 = 7500 / 100 = (75 / 100) < 1

        // $1000 ETH e 100 DSC
        // 1000 * 50 = 50000 / 100 = (500 / 100) > 1
        return (collateralAdjustedForThreshold * PRECISION) / totalDscMinted;
    }

    // 1. Check health factor (do they have enough collateral?)
    // 2. Revert if they don't
    function _revertIfHealthFactorIsBroken(address user) internal view {
        uint256 userHealthFactor = _healthFactor(user);
        if (userHealthFactor < MIN_HEALTH_FACTOR) {
            revert DSCEngine__BreaksHealthFactor(userHealthFactor);
        }
    }
}
