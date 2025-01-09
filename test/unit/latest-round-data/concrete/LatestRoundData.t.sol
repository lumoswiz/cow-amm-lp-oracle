// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.25;

import { BaseTest } from "test/Base.t.sol";
import { FeedParams } from "test/utils/Types.sol";
import { IERC20 } from "cowprotocol/contracts/interfaces/IERC20.sol";
import { stdError } from "forge-std/StdError.sol";

contract LatestRoundData_Concrete_Unit_Test is BaseTest {
    modifier whenPositivePrices() {
        _;
    }

    modifier whenBalancedPool() {
        _;
    }

    function test_50_50Pool() external whenPositivePrices whenBalancedPool {
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

    function test_80_20Pool() external whenPositivePrices whenBalancedPool {
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

    function test_LargeUnbalancing_50_50Pool_TooMuchToken1() external whenPositivePrices whenUnbalancedPool {
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
        (, int256 answer,,,) = oracle.latestRoundData();

        // Assertions
        // The naive LP token price is approx. 5x times higher than balanced pool price.
        assertApproxEqRel(naivePrice, 30.3e8, 1e10); // 100% == 1e18
        assertApproxEqRel(uint256(answer), 6e8, 1e10);
    }

    function test_LargeUnbalancing_50_50Pool_TooMuchToken0() external whenPositivePrices whenUnbalancedPool {
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

        emit log_uint(token0PoolReserve);
        emit log_uint(token1PoolReserve);

        // naivePrice ≈ $30.3 / LP token == 30.3e8 == (10 * 3000 + 300 * 1)
        uint256 naivePrice = (
            token0PoolReserve * uint256(defaults.ANSWER0()) + token1PoolReserve * uint256(defaults.ANSWER1())
        ) / defaults.LP_TOKEN_SUPPLY();

        // LP price
        (, int256 answer,,,) = oracle.latestRoundData();

        // Assertions
        // The naive LP token price is approx. 5x times higher than balanced pool price.
        assertApproxEqRel(naivePrice, 30.3e8, 1e10); // 100% == 1e18
        assertApproxEqRel(uint256(answer), 6e8, 1e10);
    }

    function test_LargeUnbalancing_80_20Pool_TooMuchToken1() external whenPositivePrices whenUnbalancedPool {
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
        (, int256 answer,,,) = oracle.latestRoundData();

        // Assertions
        // The naive LP token price is approx 3.6x higher.
        assertApproxEqRel(naivePrice, 13.5e8, 1e10); // 100% == 1e18
        assertApproxEqRel(uint256(answer), 3.75e8, 1e10);
    }

    function test_LargeUnbalancing_80_20Pool_TooMuchToken0() external whenPositivePrices whenUnbalancedPool {
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
        (, int256 answer,,,) = oracle.latestRoundData();

        // Assertions
        assertApproxEqRel(naivePrice, 3.83e8, 3e15); // within 0.3%
        assertApproxEqRel(uint256(answer), 3.75e8, 1e10);
    }
}
