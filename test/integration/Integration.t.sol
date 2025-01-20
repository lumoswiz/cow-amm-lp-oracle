// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.25 < 0.9.0;

import { BaseTest } from "test/Base.t.sol";
import { Addresses } from "test/utils/Addresses.sol";

import { AaveLPOracle } from "test/integration/AaveLPOracle.sol";
import { LPOracle } from "src/LPOracle.sol";
import { LPOracleFactory } from "src/LPOracleFactory.sol";
import { IERC20 } from "cowprotocol/contracts/interfaces/IERC20.sol";
import { AggregatorV3Interface } from "@cow-amm/interfaces/AggregatorV3Interface.sol";

import { IPoolAddressesProvider } from "@aave-dao/aave-v3-origin/src/contracts/interfaces/IPoolAddressesProvider.sol";
import { IPool } from "@aave-dao/aave-v3-origin/src/contracts/interfaces/IPool.sol";
import { IPoolConfigurator } from "@aave-dao/aave-v3-origin/src/contracts/interfaces/IPoolConfigurator.sol";
import { IAaveOracle } from "@aave-dao/aave-v3-origin/src/contracts/interfaces/IAaveOracle.sol";
import { IDefaultInterestRateStrategyV2 } from
    "@aave-dao/aave-v3-origin/src/contracts/interfaces/IDefaultInterestRateStrategyV2.sol";
import { IPoolDataProvider } from "@aave-dao/aave-v3-origin/src/contracts/interfaces/IPoolDataProvider.sol";

import { ConfiguratorInputTypes } from
    "@aave-dao/aave-v3-origin/src/contracts/protocol/libraries/types/ConfiguratorInputTypes.sol";

contract IntegrationTest is Addresses, BaseTest {
    // LPOracle
    AaveLPOracle internal aaveLPOracle;
    LPOracle internal lpOracle;
    LPOracleFactory internal factory;
    IERC20 internal POOL_WETH_UNI;
    AggregatorV3Interface internal FEED_WETH;
    AggregatorV3Interface internal FEED_UNI;

    // WETH-UNI pool params
    uint256 internal INITIAL_POOL_TOKEN0_BALANCE;
    uint256 internal INITIAL_POOL_TOKEN1_BALANCE;

    // Aave
    IPoolAddressesProvider internal provider = IPoolAddressesProvider(0x2f39d218133AFaB8F2B819B1066c7E434Ad94E9e);
    IPool internal pool;
    IPoolConfigurator internal poolConfigurator;
    IAaveOracle internal aaveOracle;
    IPoolDataProvider poolDataProvider;

    // Pool admin
    address internal constant admin = 0x5300A1a15135EA4dc7aD5a167152C01EFc9b192A;

    // Reserve initialisation addresses
    address internal constant A_TOKEN_IMPL = 0x7EfFD7b47Bfd17e52fB7559d3f924201b9DbfF3d;
    address internal constant VARIABLE_DEBT_TOKEN_IMPL = 0xaC725CB59D16C81061BDeA61041a8A5e73DA9EC6;
    address internal constant INTEREST_RATE_STRATEGY = 0x9ec6F08190DeA04A54f8Afc53Db96134e5E3FdFB;
    address internal constant INCENTIVES_CONTROLLER = 0x8164Cc65827dcFe994AB23944CBC90e0aa80bFcb;
    address internal constant TREASURY = 0x464C71f6c2F760DdA6093dCB91C24c39e5d6e18c;

    // Reserve configuration params
    uint256 internal constant LTV = 6600;
    uint256 internal constant LIQUIDATION_THRESHOLD = 7100;
    uint256 internal constant LIQUIDATION_BONUS = 10_500;
    uint256 internal constant RESERVE_FACTOR = 2000;

    // Aave operation params
    address internal constant LP_TOKEN_HOLDER = 0x78e96Be52e38b3FC3445A2ED34a6e586fFAb9631;
    address internal constant USER = 0x62780bac6b361C703148B7fdeCDE44987C5C69D0;
    uint256 internal constant USER_LP_TOKEN_INITIAL_BALANCE = 100e18;
    address internal constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    function setUp() public virtual override {
        // Fork
        vm.createSelectFork({ blockNumber: 21_643_099, urlOrAlias: "mainnet" });

        // Addresses
        (address _pool, address _feed0, address _feed1) = getOracleConstructorArgs(WETH, UNI);
        POOL_WETH_UNI = IERC20(_pool);
        FEED_WETH = AggregatorV3Interface(_feed0);
        FEED_UNI = AggregatorV3Interface(_feed1);

        // Balances
        INITIAL_POOL_TOKEN0_BALANCE = IERC20(WETH).balanceOf(address(_pool));
        INITIAL_POOL_TOKEN1_BALANCE = IERC20(UNI).balanceOf(address(_pool));

        // Deploy contracts to the fork.
        factory = new LPOracleFactory();
        lpOracle = LPOracle(factory.deployOracle(_pool, _feed0, _feed1));
        aaveLPOracle = new AaveLPOracle(address(lpOracle));

        // Aave contracts
        pool = IPool(provider.getPool());
        poolConfigurator = IPoolConfigurator(provider.getPoolConfigurator());
        aaveOracle = IAaveOracle(provider.getPriceOracle());
        poolDataProvider = IPoolDataProvider(provider.getPoolDataProvider());

        // Start prank as pool admin
        vm.startPrank(admin);

        // Initialise WETH-UNI pool as reserve
        _initReserves();

        // Configure WETH-UNI pool reserve
        _configureReserve();

        // Setup price feed
        _setPriceFeed();
        vm.stopPrank();

        // Transfer LP tokens from a LP token holder to the user for this test suite
        vm.startPrank(LP_TOKEN_HOLDER);
        POOL_WETH_UNI.transfer(USER, USER_LP_TOKEN_INITIAL_BALANCE);
        vm.stopPrank();

        // Make a holder of the WETH-UNI pool tokens the default caller for this suite
        vm.startPrank(USER);
        // Approval
        POOL_WETH_UNI.approve(address(pool), type(uint256).max);
    }

    /* ------------------------------------------------------------ */
    /*   # SETUP HELPERS                                            */
    /* ------------------------------------------------------------ */

    function _initReserves() internal {
        ConfiguratorInputTypes.InitReserveInput[] memory inputs = new ConfiguratorInputTypes.InitReserveInput[](1);
        string memory name = POOL_WETH_UNI.name();
        string memory symbol = POOL_WETH_UNI.symbol();
        bytes memory interestRateData = abi.encode(
            IDefaultInterestRateStrategyV2.InterestRateData({
                optimalUsageRatio: 9000,
                baseVariableBorrowRate: 0,
                variableRateSlope1: 270,
                variableRateSlope2: 8000
            })
        );
        ConfiguratorInputTypes.InitReserveInput memory input = ConfiguratorInputTypes.InitReserveInput({
            aTokenImpl: A_TOKEN_IMPL,
            variableDebtTokenImpl: VARIABLE_DEBT_TOKEN_IMPL,
            useVirtualBalance: false,
            interestRateStrategyAddress: INTEREST_RATE_STRATEGY,
            underlyingAsset: address(POOL_WETH_UNI),
            treasury: TREASURY,
            incentivesController: INCENTIVES_CONTROLLER,
            aTokenName: string.concat("Aave ", name),
            aTokenSymbol: string.concat("a", symbol),
            variableDebtTokenName: string.concat("Aave Variable Debt ", name),
            variableDebtTokenSymbol: string.concat("variableDebt", symbol),
            params: "",
            interestRateData: interestRateData
        });
        inputs[0] = input;
        poolConfigurator.initReserves(inputs);
    }

    function _configureReserve() internal {
        poolConfigurator.configureReserveAsCollateral(
            address(POOL_WETH_UNI), LTV, LIQUIDATION_THRESHOLD, LIQUIDATION_BONUS
        );
        poolConfigurator.setReserveBorrowing(address(POOL_WETH_UNI), true);
        poolConfigurator.setReserveFlashLoaning(address(POOL_WETH_UNI), true);
        poolConfigurator.setReserveFactor(address(POOL_WETH_UNI), RESERVE_FACTOR);
    }

    function _setPriceFeed() internal {
        address[] memory assets = new address[](1);
        address[] memory sources = new address[](1);
        assets[0] = address(POOL_WETH_UNI);
        sources[0] = address(aaveLPOracle);

        aaveOracle.setAssetSources(assets, sources);
    }

    /* ------------------------------------------------------------ */
    /*   # TESTS                                                    */
    /* ------------------------------------------------------------ */

    function test_AaveOracle_GetAssetPrice() external {
        (, int256 answer,,,) = lpOracle.latestRoundData();
        uint256 price = aaveOracle.getAssetPrice(address(POOL_WETH_UNI));
        assertEq(uint256(answer), price);
    }

    function test_NaivePrice_ManipulatePool_TooMuchToken0_BorrowAgainstInflatedLPTokens() external {
        // Manipulate pool: 90% token1 out
        uint256 token1AmountOut = (9000 * INITIAL_POOL_TOKEN1_BALANCE) / 1e4; // 90% token 1 out
        uint256 token0AmountIn = calcInGivenOutSignedWadMath(
            INITIAL_POOL_TOKEN0_BALANCE, 0.5e18, INITIAL_POOL_TOKEN1_BALANCE, 0.5e18, token1AmountOut
        );

        // Mock the new balances
        mock_token_balanceOf(WETH, address(POOL_WETH_UNI), INITIAL_POOL_TOKEN0_BALANCE + token0AmountIn);
        mock_token_balanceOf(UNI, address(POOL_WETH_UNI), INITIAL_POOL_TOKEN1_BALANCE - token1AmountOut);

        // Assert token balances were set
        assertGt(IERC20(WETH).balanceOf(address(POOL_WETH_UNI)), INITIAL_POOL_TOKEN0_BALANCE);
        assertLt(IERC20(UNI).balanceOf(address(POOL_WETH_UNI)), INITIAL_POOL_TOKEN1_BALANCE);

        // Get naive price for lp tokens & mock this price for the oracle repsonse
        (, int256 answerWeth,,,) = FEED_WETH.latestRoundData();
        (, int256 answerUni,,,) = FEED_UNI.latestRoundData();
        uint256 naivePrice = calculateNaivePrice(
            FEED_WETH.decimals(),
            FEED_UNI.decimals(),
            answerWeth,
            answerUni,
            INITIAL_POOL_TOKEN0_BALANCE + token0AmountIn,
            INITIAL_POOL_TOKEN1_BALANCE - token1AmountOut,
            POOL_WETH_UNI.totalSupply()
        );
        vm.mockCall(
            address(aaveOracle),
            abi.encodeWithSignature("getAssetPrice(address)", address(POOL_WETH_UNI)),
            abi.encode(int256(naivePrice))
        );

        // Supply overvalued tokens (inactive `referralCode` = 0)
        pool.supply(address(POOL_WETH_UNI), USER_LP_TOKEN_INITIAL_BALANCE, USER, 0);

        // Borrow against this collateral
        // Aave V3.2: `interestRateMode` must equal 2
        // inactive `referralCode` = 0
        pool.borrow(DAI, 147_000e18, 2, 0, USER);

        // Get user account data
        (uint256 totalCollateralBaseBefore, uint256 totalDebtBase,,,, uint256 healthFactorBefore) =
            pool.getUserAccountData(USER);

        // Rebalancing trade occurs - pool back to initial, near balanced state
        mock_token_balanceOf(WETH, address(POOL_WETH_UNI), INITIAL_POOL_TOKEN0_BALANCE);
        mock_token_balanceOf(UNI, address(POOL_WETH_UNI), INITIAL_POOL_TOKEN1_BALANCE);

        // Set new naive price after rebalancing
        naivePrice = calculateNaivePrice(
            FEED_WETH.decimals(),
            FEED_UNI.decimals(),
            answerWeth,
            answerUni,
            INITIAL_POOL_TOKEN0_BALANCE,
            INITIAL_POOL_TOKEN1_BALANCE,
            POOL_WETH_UNI.totalSupply()
        );
        vm.mockCall(
            address(aaveOracle),
            abi.encodeWithSignature("getAssetPrice(address)", address(POOL_WETH_UNI)),
            abi.encode(int256(naivePrice))
        );

        // Get user account data
        (uint256 totalCollateralBase,,,,, uint256 healthFactor) = pool.getUserAccountData(USER);

        // Assertions
        // Don't repay, gain: totalDebtBase - totalCollateralBase
        // Approx. 103k in this scenario
        assertGt(totalDebtBase, totalCollateralBase);
    }

    function test_LPOracle_ManipulatePool_TooMuchToken0_BorrowAgainstInflatedLPTokens() external {
        // Manipulate pool: 90% token1 out
        uint256 token1AmountOut = (9000 * INITIAL_POOL_TOKEN1_BALANCE) / 1e4; // 90% token 1 out
        uint256 token0AmountIn = calcInGivenOutSignedWadMath(
            INITIAL_POOL_TOKEN0_BALANCE, 0.5e18, INITIAL_POOL_TOKEN1_BALANCE, 0.5e18, token1AmountOut
        );

        // Mock the new balances
        mock_token_balanceOf(WETH, address(POOL_WETH_UNI), INITIAL_POOL_TOKEN0_BALANCE + token0AmountIn);
        mock_token_balanceOf(UNI, address(POOL_WETH_UNI), INITIAL_POOL_TOKEN1_BALANCE - token1AmountOut);

        // Assert token balances were set
        assertGt(IERC20(WETH).balanceOf(address(POOL_WETH_UNI)), INITIAL_POOL_TOKEN0_BALANCE);
        assertLt(IERC20(UNI).balanceOf(address(POOL_WETH_UNI)), INITIAL_POOL_TOKEN1_BALANCE);

        // Supply
        pool.supply(address(POOL_WETH_UNI), USER_LP_TOKEN_INITIAL_BALANCE, USER, 0); // inactive referralCode

        // Borrow against this collateral
        pool.borrow(DAI, 29_000e18, 2, 0, USER); // interestRateMode = 2, inactive referralCode

        // Get user account data
        (uint256 totalCollateralBaseBefore, uint256 totalDebtBaseBefore,,,, uint256 healthFactorBefore) =
            pool.getUserAccountData(USER);

        // Rebalancing trade occurs - pool back to initial, near balanced state
        mock_token_balanceOf(WETH, address(POOL_WETH_UNI), INITIAL_POOL_TOKEN0_BALANCE);
        mock_token_balanceOf(UNI, address(POOL_WETH_UNI), INITIAL_POOL_TOKEN1_BALANCE);

        // Get user account data after rebalancing trade
        (uint256 totalCollateralBase, uint256 totalDebtBase,,,, uint256 healthFactor) = pool.getUserAccountData(USER);

        // Assertions
        // Collateral base, debt base and health factors should be the same
        assertEq(totalCollateralBase, totalCollateralBaseBefore, "totalCollateralBase");
        assertEq(totalDebtBase, totalDebtBaseBefore, "totalDebtBase");
        assertEq(healthFactor, healthFactorBefore, "healthFactor");
    }

        function test_LPOracle_ManipulatePool_TooMuchToken1_BorrowAgainstInflatedLPTokens() external {
        // Manipulate pool: 90% token1 out
        uint256 token0AmountOut = (9000 * INITIAL_POOL_TOKEN0_BALANCE) / 1e4; // 90% token 1 out
        uint256 token1AmountIn = calcInGivenOutSignedWadMath(
            INITIAL_POOL_TOKEN1_BALANCE, 0.5e18, INITIAL_POOL_TOKEN0_BALANCE, 0.5e18, token0AmountOut
        );

        // Mock the new balances
        mock_token_balanceOf(WETH, address(POOL_WETH_UNI), INITIAL_POOL_TOKEN0_BALANCE - token0AmountOut);
        mock_token_balanceOf(UNI, address(POOL_WETH_UNI), INITIAL_POOL_TOKEN1_BALANCE + token1AmountIn);

        // Assert token balances were set
        assertLt(IERC20(WETH).balanceOf(address(POOL_WETH_UNI)), INITIAL_POOL_TOKEN0_BALANCE);
        assertGt(IERC20(UNI).balanceOf(address(POOL_WETH_UNI)), INITIAL_POOL_TOKEN1_BALANCE);

        // Supply
        pool.supply(address(POOL_WETH_UNI), USER_LP_TOKEN_INITIAL_BALANCE, USER, 0); // inactive referralCode

        // Borrow against this collateral
        pool.borrow(DAI, 29_000e18, 2, 0, USER); // interestRateMode = 2, inactive referralCode

        // Get user account data
        (uint256 totalCollateralBaseBefore, uint256 totalDebtBaseBefore,,,, uint256 healthFactorBefore) =
            pool.getUserAccountData(USER);

        // Rebalancing trade occurs - pool back to initial, near balanced state
        mock_token_balanceOf(WETH, address(POOL_WETH_UNI), INITIAL_POOL_TOKEN0_BALANCE);
        mock_token_balanceOf(UNI, address(POOL_WETH_UNI), INITIAL_POOL_TOKEN1_BALANCE);

        // Get user account data after rebalancing trade
        (uint256 totalCollateralBase, uint256 totalDebtBase,,,, uint256 healthFactor) = pool.getUserAccountData(USER);

        // Assertions
        // Collateral base, debt base and health factors should be the same
        assertEq(totalCollateralBase, totalCollateralBaseBefore, "totalCollateralBase");
        assertEq(totalDebtBase, totalDebtBaseBefore, "totalDebtBase");
        assertEq(healthFactor, healthFactorBefore, "healthFactor");
    }
}
