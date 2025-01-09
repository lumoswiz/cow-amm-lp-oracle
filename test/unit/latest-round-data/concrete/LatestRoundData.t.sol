// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.25;

import { BaseTest } from "test/Base.t.sol";
import { FeedParams } from "test/utils/Types.sol";
import { IERC20 } from "cowprotocol/contracts/interfaces/IERC20.sol";
import { stdError } from "forge-std/StdError.sol";

contract LatestRoundData_Concrete_Unit_Test is BaseTest {
    function test_ShouldRevert_Feed0DecimalsGt18() external {
        // Setup mocks
        reinitOracleTokenArgs(19, 8, defaults.WEIGHT_50());

        vm.expectRevert();
        oracle.latestRoundData();
    }

    function test_ShouldRevert_Feed1DecimalsGt18() external {
        // Setup mocks
        reinitOracleTokenArgs(8, 19, defaults.WEIGHT_50());

        vm.expectRevert();
        oracle.latestRoundData();
    }

    modifier givenWhenDecimalsLtEq18() {
        _;
    }

    function test_ShouldRevert_PoolBalanceDifferenceTooLarge() external givenWhenDecimalsLtEq18 {
        uint256 token0PoolReserve = 1e18;
        uint256 token1PoolReserve = token0PoolReserve * 1e18 + 1;

        // Mocks
        setLatestRoundDataMocks(defaults.ANSWER0(), defaults.ANSWER1(), token0PoolReserve, token1PoolReserve);

        vm.expectRevert("UNDEFINED");
        oracle.latestRoundData();
    }

    modifier whenValidPoolBalances() {
        _;
    }

    function test_ShouldRevert_Answer0Zero() external givenWhenDecimalsLtEq18 whenValidPoolBalances {
        uint256 token0PoolReserve = 1e18;
        uint256 token1PoolReserve = 3000e18;
        int256 answer0 = 0;
        int256 answer1 = 1e18;

        // Mocks
        setLatestRoundDataMocks(answer0, answer1, token0PoolReserve, token1PoolReserve);

        vm.expectRevert("UNDEFINED");
        oracle.latestRoundData();
    }

    function test_ShouldRevert_Answer0Negative() external givenWhenDecimalsLtEq18 whenValidPoolBalances {
        uint256 token0PoolReserve = 1e18;
        uint256 token1PoolReserve = 3000e18;
        int256 answer0 = -1;
        int256 answer1 = 1e18;

        // Mocks
        setLatestRoundDataMocks(answer0, answer1, token0PoolReserve, token1PoolReserve);

        vm.expectRevert("UNDEFINED");
        oracle.latestRoundData();
    }

    function test_ShouldRevert_Answer1Zero() external givenWhenDecimalsLtEq18 whenValidPoolBalances {
        uint256 token0PoolReserve = 1e18;
        uint256 token1PoolReserve = 3000e18;
        int256 answer0 = 3000e18;
        int256 answer1 = 0;

        // Mocks
        setLatestRoundDataMocks(answer0, answer1, token0PoolReserve, token1PoolReserve);

        vm.expectRevert("UNDEFINED");
        oracle.latestRoundData();
    }

    function test_ShouldRevert_Answer1Negative() external givenWhenDecimalsLtEq18 whenValidPoolBalances {
        uint256 token0PoolReserve = 1e18;
        uint256 token1PoolReserve = 3000e18;
        int256 answer0 = 3000e18;
        int256 answer1 = -1;

        // Mocks
        setLatestRoundDataMocks(answer0, answer1, token0PoolReserve, token1PoolReserve);

        vm.expectRevert("UNDEFINED");
        oracle.latestRoundData();
    }

    modifier whenPositivePrices() {
        _;
    }

    function test_ShouldRevert_ZeroLPTokenSupply()
        external
        givenWhenDecimalsLtEq18
        whenValidPoolBalances
        whenPositivePrices
    {
        uint256 token0PoolReserve = 1e18;
        uint256 token1PoolReserve = 3000e18;
        int256 answer0 = 3000e18;
        int256 answer1 = 1e18;
        uint256 lpSupply = 0;

        // Mocks
        setAllLatestRoundDataMocks(
            18,
            18,
            answer0,
            answer1,
            defaults.DEC_1_2024(),
            defaults.DEC_1_2024(),
            token0PoolReserve,
            token1PoolReserve,
            lpSupply
        );

        vm.expectRevert(stdError.divisionError);
        oracle.latestRoundData();
    }

    modifier whenPositiveLpSupply() {
        _;
    }

    modifier whenSameFeedDecimals() {
        _;
    }

    modifier whenBalancedPool() {
        _;
    }

    function test_50_50Pool()
        external
        givenWhenDecimalsLtEq18
        whenValidPoolBalances
        whenPositivePrices
        whenPositiveLpSupply
        whenSameFeedDecimals
        whenBalancedPool
    {
        uint256 token0PoolReserve = 1e18;
        uint256 token1PoolReserve = 3000e18;

        setLatestRoundDataMocks(defaults.ANSWER0(), defaults.ANSWER1(), token0PoolReserve, token1PoolReserve);

        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =
            oracle.latestRoundData();

        // Unimplemented assertions
        assertEq(roundId, 0, "roundId");
        assertEq(startedAt, 0, "startedAt");
        assertEq(answeredInRound, 0, "answeredInRound");

        // Implemented assertions
        // Expected LP token USD price = (1 * 3000 + 3000 * 1) / 1000 = $6/token === 6e8
        assertApproxEqRel(answer, 6e8, 1e10); // 100% == 1e18
        assertEq(updatedAt, block.timestamp, "updatedAt");
    }

    function test_80_20Pool()
        external
        givenWhenDecimalsLtEq18
        whenValidPoolBalances
        whenPositivePrices
        whenPositiveLpSupply
        whenSameFeedDecimals
        whenBalancedPool
    {
        // Re-init oracle to adjust for 80/20 pool
        reinitOracleTokenArgs(18, 18, 0.8e18);

        // token0 value: 3000 (80%)
        // token1 value: 750 (20%)
        uint256 token0PoolReserve = 1e18;
        uint256 token1PoolReserve = 750e18;

        setLatestRoundDataMocks(defaults.ANSWER0(), defaults.ANSWER1(), token0PoolReserve, token1PoolReserve);

        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =
            oracle.latestRoundData();

        // Unimplemented assertions
        assertEq(roundId, 0, "roundId");
        assertEq(startedAt, 0, "startedAt");
        assertEq(answeredInRound, 0, "answeredInRound");

        // Implemented assertions
        // Expected LP token USD price = (1 * 3000 + 750 * 1) / 1000 = $3.75/token === 3.75e8
        assertApproxEqRel(answer, 3.75e8, 1e10); // 100% == 1e18
        assertEq(updatedAt, block.timestamp, "updatedAt");
    }

    modifier whenUnbalancedPool() {
        _;
    }

    function test_LargeUnbalancing_50_50Pool_TooMuchToken1()
        external
        givenWhenDecimalsLtEq18
        whenValidPoolBalances
        whenPositivePrices
        whenPositiveLpSupply
        whenSameFeedDecimals
        whenUnbalancedPool
    {
        // Initial balanced pool state
        uint256 token0PoolReserve = 1e18;
        uint256 token1PoolReserve = 3000e18;

        setLatestRoundDataMocks(defaults.ANSWER0(), defaults.ANSWER1(), token0PoolReserve, token1PoolReserve);

        // Next pool state: too much token 1
        // token 0 out: amount == 0.9
        uint256 token0Amountout = 0.9e18;
        uint256 token1AmountIn = calcInGivenOutSignedWadMath(
            token1PoolReserve, defaults.WEIGHT_50(), token0PoolReserve, defaults.WEIGHT_50(), token0Amountout
        );
        token0PoolReserve -= token0Amountout;
        token1PoolReserve += token1AmountIn;

        // naivePrice ≈ $30.3 / LP token == 30.3e8 == (0.1 * 3000 + 30000 * 1)
        uint256 naivePrice = (
            token0PoolReserve * uint256(defaults.ANSWER0()) + token1PoolReserve * uint256(defaults.ANSWER1())
        ) / defaults.LP_TOKEN_SUPPLY();

        // LP price
        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =
            oracle.latestRoundData();

        // Assertions
        assertEq(roundId, 0, "roundId");
        assertEq(startedAt, 0, "startedAt");
        assertEq(answeredInRound, 0, "answeredInRound");

        // The naive LP token price is approx. 5x times higher than balanced pool price.
        assertApproxEqRel(naivePrice, 30.3e8, 1e10); // 100% == 1e18
        assertApproxEqRel(uint256(answer), 6e8, 1e10);
        assertEq(updatedAt, block.timestamp, "updatedAt");
    }

    function test_LargeUnbalancing_50_50Pool_TooMuchToken0()
        external
        givenWhenDecimalsLtEq18
        whenValidPoolBalances
        whenPositivePrices
        whenPositiveLpSupply
        whenSameFeedDecimals
        whenUnbalancedPool
    {
        // Initial balanced pool state
        uint256 token0PoolReserve = 1e18;
        uint256 token1PoolReserve = 3000e18;

        setLatestRoundDataMocks(defaults.ANSWER0(), defaults.ANSWER1(), token0PoolReserve, token1PoolReserve);

        // Next pool state: too much token 0
        // token 1 out: amount == 2700
        uint256 token1Amountout = 2700e18;
        uint256 token0AmountIn = calcInGivenOutSignedWadMath(
            token0PoolReserve, defaults.WEIGHT_50(), token1PoolReserve, defaults.WEIGHT_50(), token1Amountout
        );
        token0PoolReserve += token0AmountIn;
        token1PoolReserve -= token1Amountout;

        // naivePrice ≈ $30.3 / LP token == 30.3e8 == (10 * 3000 + 300 * 1)
        uint256 naivePrice = (
            token0PoolReserve * uint256(defaults.ANSWER0()) + token1PoolReserve * uint256(defaults.ANSWER1())
        ) / defaults.LP_TOKEN_SUPPLY();

        // LP price
        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =
            oracle.latestRoundData();

        // Assertions
        assertEq(roundId, 0, "roundId");
        assertEq(startedAt, 0, "startedAt");
        assertEq(answeredInRound, 0, "answeredInRound");

        // The naive LP token price is approx. 5x times higher than balanced pool price.
        assertApproxEqRel(naivePrice, 30.3e8, 1e10); // 100% == 1e18
        assertApproxEqRel(uint256(answer), 6e8, 1e10);
        assertEq(updatedAt, block.timestamp, "updatedAt");
    }

    function test_LargeUnbalancing_80_20Pool_TooMuchToken1()
        external
        givenWhenDecimalsLtEq18
        whenValidPoolBalances
        whenPositivePrices
        whenPositiveLpSupply
        whenSameFeedDecimals
        whenUnbalancedPool
    {
        // Re-init oracle to adjust for 80/20 pool
        reinitOracleTokenArgs(18, 18, 0.8e18);

        // Price in balanced state is 3.75e8
        // token0 value: 3000 (80%)
        // token1 value: 750 (20%)
        uint256 token0PoolReserve = 1e18;
        uint256 token1PoolReserve = 750e18;

        setLatestRoundDataMocks(defaults.ANSWER0(), defaults.ANSWER1(), token0PoolReserve, token1PoolReserve);

        // Next pool state: too much token 1
        // token 0 out: amount == 0.5
        uint256 token0Amountout = 0.5e18;
        uint256 token1AmountIn = calcInGivenOutSignedWadMath(
            token1PoolReserve, defaults.WEIGHT_20(), token0PoolReserve, defaults.WEIGHT_80(), token0Amountout
        );
        token0PoolReserve -= token0Amountout;
        token1PoolReserve += token1AmountIn;

        // NaivePrice: 0.5 * 3000 + 12000 * 1 = 13.5e8 == $13.5/lp token
        uint256 naivePrice = (
            token0PoolReserve * uint256(defaults.ANSWER0()) + token1PoolReserve * uint256(defaults.ANSWER1())
        ) / defaults.LP_TOKEN_SUPPLY();

        // LP price
        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =
            oracle.latestRoundData();

        // Assertions
        assertEq(roundId, 0, "roundId");
        assertEq(startedAt, 0, "startedAt");
        assertEq(answeredInRound, 0, "answeredInRound");

        // The naive LP token price is approx 3.6x higher.
        assertApproxEqRel(naivePrice, 13.5e8, 1e10); // 100% == 1e18
        assertApproxEqRel(uint256(answer), 3.75e8, 1e10);
        assertEq(updatedAt, block.timestamp, "updatedAt");
    }

    function test_LargeUnbalancing_80_20Pool_TooMuchToken0()
        external
        givenWhenDecimalsLtEq18
        whenValidPoolBalances
        whenPositivePrices
        whenPositiveLpSupply
        whenSameFeedDecimals
        whenUnbalancedPool
    {
        // Re-init oracle to adjust for 80/20 pool
        reinitOracleTokenArgs(18, 18, 0.8e18);

        // Price in balanced state is 3.75e8
        // token0 value: 3000 (80%)
        // token1 value: 750 (20%)
        uint256 token0PoolReserve = 1e18;
        uint256 token1PoolReserve = 750e18;

        setLatestRoundDataMocks(defaults.ANSWER0(), defaults.ANSWER1(), token0PoolReserve, token1PoolReserve);

        // Next pool state: too much token 0
        // token 1 out: amount == 250e8
        uint256 token1Amountout = 250e18;
        uint256 token0AmountIn = calcInGivenOutSignedWadMath(
            token0PoolReserve, defaults.WEIGHT_80(), token1PoolReserve, defaults.WEIGHT_20(), token1Amountout
        );
        token0PoolReserve += token0AmountIn;
        token1PoolReserve -= token1Amountout;

        // NaivePrice: 1.11 * 3000 + 500 * 1 = 3.83e8 == $3.83/lp token
        uint256 naivePrice = (
            token0PoolReserve * uint256(defaults.ANSWER0()) + token1PoolReserve * uint256(defaults.ANSWER1())
        ) / defaults.LP_TOKEN_SUPPLY();

        // LP price
        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =
            oracle.latestRoundData();

        // Assertions
        assertEq(roundId, 0, "roundId");
        assertEq(startedAt, 0, "startedAt");
        assertEq(answeredInRound, 0, "answeredInRound");

        assertApproxEqRel(naivePrice, 3.83e8, 3e15); // within 0.3%
        assertApproxEqRel(uint256(answer), 3.75e8, 1e10);
        assertEq(updatedAt, block.timestamp, "updatedAt");
    }

    modifier whenDifferentFeedDecimals() {
        _;
    }

    function test_50_50Pool_ScaledAnswers()
        external
        givenWhenDecimalsLtEq18
        whenValidPoolBalances
        whenPositivePrices
        whenPositiveLpSupply
        whenDifferentFeedDecimals
        whenBalancedPool
    {
        uint256 token0PoolReserve = 1e18;
        uint256 token1PoolReserve = 3000e18;
        int256 answer0 = 3000e8; // 8 decimal basis
        int256 answer1 = 1e18;

        // Mocks
        setAllLatestRoundDataMocks(
            8,
            18,
            answer0,
            answer1,
            defaults.DEC_1_2024(),
            defaults.DEC_1_2024(),
            token0PoolReserve,
            token1PoolReserve,
            defaults.LP_TOKEN_SUPPLY()
        );

        // Call
        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =
            oracle.latestRoundData();

        // Assertions
        assertEq(roundId, 0, "roundId");
        assertEq(startedAt, 0, "startedAt");
        assertEq(answeredInRound, 0, "answeredInRound");

        // Expected LP token USD price = (1 * 3000 + 3000 * 1) / 1000 = $6/token
        assertApproxEqRel(answer, 6e18, 1e10); // 100% == 1e18
        assertEq(updatedAt, defaults.DEC_1_2024(), "updatedAt");
    }

    function test_80_20Pool_ScaledAnswers()
        external
        givenWhenDecimalsLtEq18
        whenValidPoolBalances
        whenPositivePrices
        whenPositiveLpSupply
        whenSameFeedDecimals
        whenBalancedPool
    {
        // Re-init oracle to adjust for 80/20 pool
        reinitOracleTokenArgs(18, 18, 0.8e18);

        // Variables
        uint256 token0PoolReserve = 1e18;
        uint256 token1PoolReserve = 750e18;
        int256 answer0 = 3000e8; // 8 decimal basis
        int256 answer1 = 1e18;

        // Mocks
        setAllLatestRoundDataMocks(
            8,
            18,
            answer0,
            answer1,
            defaults.DEC_1_2024(),
            defaults.DEC_1_2024(),
            token0PoolReserve,
            token1PoolReserve,
            defaults.LP_TOKEN_SUPPLY()
        );

        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =
            oracle.latestRoundData();

        // Assertions
        assertEq(roundId, 0, "roundId");
        assertEq(startedAt, 0, "startedAt");
        assertEq(answeredInRound, 0, "answeredInRound");

        // Expected LP token USD price = (1 * 3000 + 750 * 1) / 1000 = $3.75/token
        assertApproxEqRel(answer, 3.75e18, 1e10); // 100% == 1e18
        assertEq(updatedAt, defaults.DEC_1_2024(), "updatedAt");
    }

    function test_LargeUnbalancing_50_50Pool_TooMuchToken1_ScaledAnswers()
        external
        givenWhenDecimalsLtEq18
        whenValidPoolBalances
        whenPositivePrices
        whenPositiveLpSupply
        whenSameFeedDecimals
        whenUnbalancedPool
    {
        // Initial balanced pool state
        uint256 token0PoolReserve = 1e18;
        uint256 token1PoolReserve = 3000e18;
        int256 answer0 = 3000e8; // 8 decimal basis
        int256 answer1 = 1e18;

        // Mocks
        setAllLatestRoundDataMocks(
            8,
            18,
            answer0,
            answer1,
            defaults.DEC_1_2024(),
            defaults.DEC_1_2024(),
            token0PoolReserve,
            token1PoolReserve,
            defaults.LP_TOKEN_SUPPLY()
        );

        // Next pool state: too much token 1
        // token 0 out: amount == 0.9
        uint256 token0Amountout = 0.9e18;
        uint256 token1AmountIn = calcInGivenOutSignedWadMath(
            token1PoolReserve, defaults.WEIGHT_50(), token0PoolReserve, defaults.WEIGHT_50(), token0Amountout
        );
        token0PoolReserve -= token0Amountout;
        token1PoolReserve += token1AmountIn;

        // naivePrice ≈ $30.3 / LP token == (0.1 * 3000 + 30000 * 1)
        uint256 naivePrice = (
            token0PoolReserve * uint256(answer0) * 10 ** (18 - 8) + token1PoolReserve * uint256(answer1)
        ) / defaults.LP_TOKEN_SUPPLY();

        // LP price
        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =
            oracle.latestRoundData();

        // Assertions
        assertEq(roundId, 0, "roundId");
        assertEq(startedAt, 0, "startedAt");
        assertEq(answeredInRound, 0, "answeredInRound");

        // The naive LP token price is approx. 5x times higher than balanced pool price.
        assertApproxEqRel(naivePrice, 30.3e18, 1e10); // 100% == 1e18
        assertApproxEqRel(uint256(answer), 6e18, 1e10);
        assertEq(updatedAt, defaults.DEC_1_2024(), "updatedAt");
    }

    function test_LargeUnbalancing_50_50Pool_TooMuchToken0_ScaledAnswers()
        external
        givenWhenDecimalsLtEq18
        whenValidPoolBalances
        whenPositivePrices
        whenPositiveLpSupply
        whenSameFeedDecimals
        whenUnbalancedPool
    {
        // Initial balanced pool state
        uint256 token0PoolReserve = 1e18;
        uint256 token1PoolReserve = 3000e18;
        int256 answer0 = 3000e8; // 8 decimal basis
        int256 answer1 = 1e18;

        // Mocks
        setAllLatestRoundDataMocks(
            8,
            18,
            answer0,
            answer1,
            defaults.DEC_1_2024(),
            defaults.DEC_1_2024(),
            token0PoolReserve,
            token1PoolReserve,
            defaults.LP_TOKEN_SUPPLY()
        );

        // Next pool state: too much token 0
        // token 1 out: amount == 2700
        uint256 token1Amountout = 2700e18;
        uint256 token0AmountIn = calcInGivenOutSignedWadMath(
            token0PoolReserve, defaults.WEIGHT_50(), token1PoolReserve, defaults.WEIGHT_50(), token1Amountout
        );
        token0PoolReserve += token0AmountIn;
        token1PoolReserve -= token1Amountout;

        // naivePrice ≈ $30.3 / LP token == (10 * 3000 + 300 * 1)
        uint256 naivePrice = (
            token0PoolReserve * uint256(answer0) * 10 ** (18 - 8) + token1PoolReserve * uint256(answer1)
        ) / defaults.LP_TOKEN_SUPPLY();

        // LP price
        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =
            oracle.latestRoundData();

        // Assertions
        assertEq(roundId, 0, "roundId");
        assertEq(startedAt, 0, "startedAt");
        assertEq(answeredInRound, 0, "answeredInRound");

        // The naive LP token price is approx. 5x times higher than balanced pool price.
        assertApproxEqRel(naivePrice, 30.3e18, 1e10); // 100% == 1e18
        assertApproxEqRel(uint256(answer), 6e18, 1e10);
        assertEq(updatedAt, defaults.DEC_1_2024(), "updatedAt");
    }

    function test_LargeUnbalancing_80_20Pool_TooMuchToken1_ScaledAnswers()
        external
        givenWhenDecimalsLtEq18
        whenValidPoolBalances
        whenPositivePrices
        whenPositiveLpSupply
        whenSameFeedDecimals
        whenUnbalancedPool
    {
        // Re-init oracle to adjust for 80/20 pool
        reinitOracleTokenArgs(18, 18, 0.8e18);

        // Price in balanced state is 3.75e8
        // token0 value: 3000 (80%)
        // token1 value: 750 (20%)
        uint256 token0PoolReserve = 1e18;
        uint256 token1PoolReserve = 750e18;
        int256 answer0 = 3000e8; // 8 decimal basis
        int256 answer1 = 1e18;

        // Mocks
        setAllLatestRoundDataMocks(
            8,
            18,
            answer0,
            answer1,
            defaults.DEC_1_2024(),
            defaults.DEC_1_2024(),
            token0PoolReserve,
            token1PoolReserve,
            defaults.LP_TOKEN_SUPPLY()
        );

        // Next pool state: too much token 1
        // token 0 out: amount == 0.5
        uint256 token0Amountout = 0.5e18;
        uint256 token1AmountIn = calcInGivenOutSignedWadMath(
            token1PoolReserve, defaults.WEIGHT_20(), token0PoolReserve, defaults.WEIGHT_80(), token0Amountout
        );
        token0PoolReserve -= token0Amountout;
        token1PoolReserve += token1AmountIn;

        // NaivePrice: 0.5 * 3000 + 12000 * 1 == $13.5/lp token
        uint256 naivePrice = (
            token0PoolReserve * uint256(answer0) * 10 ** (18 - 8) + token1PoolReserve * uint256(answer1)
        ) / defaults.LP_TOKEN_SUPPLY();

        // LP price
        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =
            oracle.latestRoundData();

        // Assertions
        assertEq(roundId, 0, "roundId");
        assertEq(startedAt, 0, "startedAt");
        assertEq(answeredInRound, 0, "answeredInRound");

        // The naive LP token price is approx 3.6x higher.
        assertApproxEqRel(naivePrice, 13.5e18, 1e10); // 100% == 1e18
        assertApproxEqRel(uint256(answer), 3.75e18, 1e10);
        assertEq(updatedAt, defaults.DEC_1_2024(), "updatedAt");
    }

    function test_LargeUnbalancing_80_20Pool_TooMuchToken0_ScaledAnswers()
        external
        givenWhenDecimalsLtEq18
        whenValidPoolBalances
        whenPositivePrices
        whenPositiveLpSupply
        whenSameFeedDecimals
        whenUnbalancedPool
    { }
}
