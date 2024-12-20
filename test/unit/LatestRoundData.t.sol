// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.25;

import { BaseTest } from "test/Base.t.sol";
import { FeedParams } from "test/utils/Types.sol";
import { IERC20 } from "cowprotocol/contracts/interfaces/IERC20.sol";

contract LatestRoundData_Unit_Test is BaseTest {
    function testFuzz_shouldRevert_LtEqZeroAnswer0(int256 answer0) external {
        vm.assume(answer0 < 0);

        setLatestRoundDataMocks(
            answer0, defaults.ANSWER1(), defaults.TOKEN0_BALANCE(), defaults.TOKEN1_BALANCE(), defaults.WEIGHT_50()
        );

        vm.expectRevert();
        oracle.latestRoundData();
    }

    function testFuzz_shouldRevert_LtEqZeroAnswer1(int256 answer1) external {
        vm.assume(answer1 < 0);

        setLatestRoundDataMocks(
            defaults.ANSWER0(), answer1, defaults.TOKEN0_BALANCE(), defaults.TOKEN1_BALANCE(), defaults.WEIGHT_50()
        );

        vm.expectRevert();
        oracle.latestRoundData();
    }

    modifier whenPositivePrices() {
        _;
    }

    modifier whenBalancedPool() {
        _;
    }

    function test_50_50Pool() external whenPositivePrices whenBalancedPool {
        uint256 token0PoolReserve = 1e18;
        uint256 token1PoolReserve = 4000e18;

        setLatestRoundDataMocks(
            defaults.ANSWER0(), defaults.ANSWER1(), token0PoolReserve, token1PoolReserve, defaults.WEIGHT_50()
        );

        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =
            oracle.latestRoundData();

        // Unimplemented assertions
        assertEq(roundId, 0, "roundId");
        assertEq(startedAt, 0, "startedAt");
        assertEq(answeredInRound, 0, "answeredInRound");

        // Implemented assertions
        // Expected LP token USD price = (1 * 4000 + 4000 * 1) / 1000 = $8/token === 8e8
        assertEq(answer, 8e8, "answer");
        assertEq(updatedAt, block.timestamp, "updatedAt");
    }

    function test_80_20Pool() external whenPositivePrices whenBalancedPool {
        uint256 token0PoolReserve = 1e18;
        uint256 token1PoolReserve = 1000e18;

        setLatestRoundDataMocks(
            defaults.ANSWER0(), defaults.ANSWER1(), token0PoolReserve, token1PoolReserve, defaults.WEIGHT_80()
        );

        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =
            oracle.latestRoundData();

        // Unimplemented assertions
        assertEq(roundId, 0, "roundId");
        assertEq(startedAt, 0, "startedAt");
        assertEq(answeredInRound, 0, "answeredInRound");

        // Implemented assertions
        // Expected LP token USD price = (1 * 4000 + 1000 * 1) / 5000 = $5/token === 5e8
        assertEq(answer, 5e8, "answer");
        assertEq(updatedAt, block.timestamp, "updatedAt");
    }

    modifier whenUnbalancedPool() {
        _;
    }

    function test_LargeUnbalancing_50_50Pool_TooMuchToken1() external whenPositivePrices whenUnbalancedPool {
        // Initial balanced pool state
        uint256 token0PoolReserve = 1e18;
        uint256 token1PoolReserve = 4000e18;

        setLatestRoundDataMocks(
            defaults.ANSWER0(), defaults.ANSWER1(), token0PoolReserve, token1PoolReserve, defaults.WEIGHT_50()
        );

        // Next pool state: attacker unbalances the pool
        // Assume: zero swap fees. Out token is token0.
        // tokenAmountOut is set to the maximum amount before reverting due to: BNum_BPowBaseTooHigh()
        uint256 tokenAmountOut = maxAmountOutGivenBalanceOut(token0PoolReserve);
        uint256 tokenAmountIn = calcInGivenOut(
            token1PoolReserve, defaults.WEIGHT_50(), token0PoolReserve, defaults.WEIGHT_50(), tokenAmountOut, 0
        );
        token0PoolReserve -= tokenAmountOut;
        token1PoolReserve += tokenAmountIn;

        // Naive price
        // token0PoolReserve ≈ 0.5e8 token 0, token1PoolReserve ≈ 8000e18 token 1
        // naivePrice ≈ 10e8 == (0.5 * 4000 + 8000 * 1)
        uint256 naivePrice = (token0PoolReserve * 4000e8 + token1PoolReserve * 1e8) / defaults.LP_TOKEN_SUPPLY();

        // LP price
        (, int256 answer,,,) = oracle.latestRoundData();

        // Assertions
        // The naive LP token price is approx 25% higher than balanced pool price.
        assertApproxEqRel(naivePrice, 10e8, 1e16); // within 1% of 10e8
        // LP token price is within 0.1% of the balanced pool state
        assertApproxEqRel(uint256(answer), 8e8, 1e15);
    }

    function test_LargeUnbalancing_50_50Pool_TooMuchToken0() external whenPositivePrices whenUnbalancedPool {
        // Initial balanced pool state
        uint256 token0PoolReserve = 1e18;
        uint256 token1PoolReserve = 4000e18;

        setLatestRoundDataMocks(
            defaults.ANSWER0(), defaults.ANSWER1(), token0PoolReserve, token1PoolReserve, defaults.WEIGHT_50()
        );

        // Next pool state: attacker unbalances the pool
        // Assume: zero swap fees. Out token is token1.
        // tokenAmountOut is set to the maximum amount before reverting due to: BNum_BPowBaseTooHigh()
        uint256 tokenAmountOut = maxAmountOutGivenBalanceOut(token1PoolReserve);
        uint256 tokenAmountIn = calcInGivenOut(
            token0PoolReserve, defaults.WEIGHT_50(), token1PoolReserve, defaults.WEIGHT_50(), tokenAmountOut, 0
        );
        token1PoolReserve -= tokenAmountOut;
        token0PoolReserve += tokenAmountIn;

        // Naive price
        // token0PoolReserve ≈ 0.5e8 token 0, token1PoolReserve ≈ 8000e18 token 1
        // naivePrice ≈ 10e8 == (2 * 4000 + 2000 * 1)
        uint256 naivePrice = (token0PoolReserve * 4000e8 + token1PoolReserve * 1e8) / defaults.LP_TOKEN_SUPPLY();

        // LP price
        (, int256 answer,,,) = oracle.latestRoundData();

        // Assertions
        // The naive LP token price is approx 25% higher than balanced pool price.
        assertApproxEqRel(naivePrice, 10e8, 1e16);
        // LP token price is within 0.1% of the balanced pool state
        assertApproxEqRel(uint256(answer), 8e8, 1e15);
    }

    function test_LargeUnbalancing_80_20Pool_TooMuchToken1() external whenPositivePrices whenUnbalancedPool {
        // Initial balanced pool state 80% token 0 - 20% token 1
        // Price in balanced state is 5e8
        uint256 token0PoolReserve = 1e18;
        uint256 token1PoolReserve = 1000e18;

        setLatestRoundDataMocks(
            defaults.ANSWER0(), defaults.ANSWER1(), token0PoolReserve, token1PoolReserve, defaults.WEIGHT_80()
        );

        // Next pool state: attacker unbalances the pool
        // Assume: zero swap fees. Out token is token0.
        // tokenAmountOut is set to approx. max amount before reverting due to: BNum_BPowBaseTooHigh()
        // uint256 tokenAmountOut = 0.5e18 - 1 wei;
        uint256 tokenAmountOut = maxAmountOutGivenBalanceOut(token0PoolReserve);
        uint256 tokenAmountIn = calcInGivenOut(
            token1PoolReserve, defaults.WEIGHT_20(), token0PoolReserve, defaults.WEIGHT_80(), tokenAmountOut, 0
        );
        token0PoolReserve -= tokenAmountOut;
        token1PoolReserve += tokenAmountIn;

        // NaivePrice ≈ 18e8 == (0.5 * 4000 + 16000 * 1)
        uint256 naivePrice = (token0PoolReserve * 4000e8 + token1PoolReserve * 1e8) / IERC20(mocks.pool).totalSupply();

        // LP price
        (, int256 answer,,,) = oracle.latestRoundData();

        // Assertions
        // The naive LP token price is approx 260% higher than balanced pool price.
        assertApproxEqRel(naivePrice, 18e8, 1e16); // 1% diff
        // LP token price is within 0.1% of the balance pool price.
        assertApproxEqRel(uint256(answer), 5e8, 1e15);
    }

    function test_LargeUnbalancing_0_20Pool_TooMuchToken0() external whenPositivePrices whenUnbalancedPool {
        // Initial balanced pool state 80% token 0 - 20% token 1
        // Price in balanced state is 5e8
        uint256 token0PoolReserve = 1e18;
        uint256 token1PoolReserve = 1000e18;

        setLatestRoundDataMocks(
            defaults.ANSWER0(), defaults.ANSWER1(), token0PoolReserve, token1PoolReserve, defaults.WEIGHT_80()
        );

        uint256 tokenAmountOut = maxAmountOutGivenBalanceOut(1000e18);
        uint256 tokenAmountIn = calcInGivenOut(1e18, 0.8e18, 1000e18, 0.2e18, tokenAmountOut, 0);
        token1PoolReserve -= tokenAmountOut;
        token0PoolReserve += tokenAmountIn;

        // NaivePrice ≈ 18e8 == (0.5 * 4000 + 16000 * 1)
        uint256 naivePrice = (token0PoolReserve * 4000e8 + token1PoolReserve * 1e8) / IERC20(mocks.pool).totalSupply();

        // LP price
        (, int256 answer,,,) = oracle.latestRoundData();

        // Assertions
        // The naive LP token price is within 6% of the balanced pool price.
        assertApproxEqRel(naivePrice, 5e8, 6e16); // 1% diff
        // LP token price is within 0.1% of the balance pool price.
        assertApproxEqRel(uint256(answer), 5e8, 1e15);
    }

    function test_BalancedPool_EqualTokenDecimals() external {
        uint256 token0PoolReserve = 1e6;
        uint256 token1PoolReserve = 4000e6;

        // Reinit the oracle to set token decimals to 6 instead of 18
        reinitOracle(6, 6);

        setLatestRoundDataMocks(
            defaults.ANSWER0(), defaults.ANSWER1(), token0PoolReserve, token1PoolReserve, defaults.WEIGHT_50()
        );

        (, int256 answer,,,) = oracle.latestRoundData();

        // Implemented assertions
        // Expected LP token USD price = (1 * 4000 + 4000 * 1) / 1000 = $8/token === 8e8
        assertEq(answer, 8e8, "answer");
    }
}
