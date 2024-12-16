// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.25;

import { BaseTest } from "test/Base.t.sol";
import { FeedParams } from "test/utils/Types.sol";

contract LatestRoundData_Unit_Test is BaseTest {
    function testFuzz_shouldRevert_LtEqZeroAnswer0(int256 answer0) external {
        vm.assume(answer0 < 0);

        FeedParams memory feedParams0 =
            FeedParams({ addr: FEED0, decimals: 8, answer: answer0, updatedAt: block.timestamp });
        FeedParams memory feedParams1 =
            FeedParams({ addr: FEED1, decimals: 8, answer: 1e8, updatedAt: block.timestamp });

        setPriceFeedData(feedParams0, feedParams1);
        setMockOrder(1e18, 1e18, WEIGHT_50);
        mock_pool_totalSupply(MOCK_POOL, LP_TOKEN_SUPPLY);

        vm.expectRevert();
        oracle.latestRoundData();
    }

    function testFuzz_shouldRevert_LtEqZeroAnswer1(int256 answer1) external {
        vm.assume(answer1 < 0);

        FeedParams memory feedParams0 =
            FeedParams({ addr: FEED0, decimals: 8, answer: 1e8, updatedAt: block.timestamp });
        FeedParams memory feedParams1 =
            FeedParams({ addr: FEED1, decimals: 8, answer: answer1, updatedAt: block.timestamp });

        setPriceFeedData(feedParams0, feedParams1);
        setMockOrder(1e18, 1e18, WEIGHT_50);
        mock_pool_totalSupply(MOCK_POOL, LP_TOKEN_SUPPLY);

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
        FeedParams memory feedParams0 =
            FeedParams({ addr: FEED0, decimals: 8, answer: 4000e8, updatedAt: block.timestamp });
        FeedParams memory feedParams1 =
            FeedParams({ addr: FEED1, decimals: 8, answer: 1e8, updatedAt: block.timestamp });
        setPriceFeedData(feedParams0, feedParams1);

        uint256 token0PoolReserve = 1e18;
        uint256 token1PoolReserve = 4000e18;
        setMockOrder(token0PoolReserve, token1PoolReserve, WEIGHT_50);

        mock_pool_totalSupply(MOCK_POOL, LP_TOKEN_SUPPLY);

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
        FeedParams memory feedParams0 =
            FeedParams({ addr: FEED0, decimals: 8, answer: 4000e8, updatedAt: block.timestamp });
        FeedParams memory feedParams1 =
            FeedParams({ addr: FEED1, decimals: 8, answer: 1e8, updatedAt: block.timestamp });
        setPriceFeedData(feedParams0, feedParams1);

        uint256 token0PoolReserve = 1e18;
        uint256 token1PoolReserve = 1000e18;
        setMockOrder(token0PoolReserve, token1PoolReserve, WEIGHT_80);

        mock_pool_totalSupply(MOCK_POOL, LP_TOKEN_SUPPLY);

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

    function test_50_50Pool_LargeUnbalancing_TooMuchToken0() external whenPositivePrices whenUnbalancedPool {
        FeedParams memory feedParams0 =
            FeedParams({ addr: FEED0, decimals: 8, answer: 4000e8, updatedAt: block.timestamp });
        FeedParams memory feedParams1 =
            FeedParams({ addr: FEED1, decimals: 8, answer: 1e8, updatedAt: block.timestamp });

        // Initial balanced pool state
        uint256 token0PoolReserve = 1e18;
        uint256 token1PoolReserve = 4000e18;

        // Next pool state: attacker unbalances the pool
        // Assume: zero swap fees. Out token is token0.
        // tokenAmountOut is set to the maximum amount before reverting due to: BNum_BPowBaseTooHigh()
        uint256 tokenAmountOut = 0.5e18 - 1 wei;
        uint256 tokenAmountIn =
            calcInGivenOut(token1PoolReserve, WEIGHT_50, token0PoolReserve, WEIGHT_50, tokenAmountOut, 0);
        token0PoolReserve -= tokenAmountOut;
        token1PoolReserve += tokenAmountIn;

        // Mock calls
        setPriceFeedData(feedParams0, feedParams1);
        setMockOrder(token0PoolReserve, token1PoolReserve, WEIGHT_50);
        mock_pool_totalSupply(MOCK_POOL, LP_TOKEN_SUPPLY);

        // Naive price
        // token0PoolReserve ≈ 0.5e8 token 0, token1PoolReserve ≈ 8000e18 token 1
        // naivePrice ≈ 10e8 == (0.5 * 4000 + 8000 * 1)
        uint256 naivePrice = (token0PoolReserve * 4000e8 + token1PoolReserve * 1e8) / LP_TOKEN_SUPPLY;

        // LP price
        (, int256 answer,,,) = oracle.latestRoundData();

        // Assertions
        // The naive LP token price is approx 25% higher than balanced pool price.
        assertApproxEqRel(naivePrice, 10e8, 1e16);
        // LP token price is within 2.5% of the balanced pool state
        assertApproxEqRel(uint256(answer), 8e8, 2.5e16);
    }

    function test_50_50Pool_LargeUnbalancing_TooMuchToken1() external whenPositivePrices whenUnbalancedPool {
        FeedParams memory feedParams0 =
            FeedParams({ addr: FEED0, decimals: 8, answer: 4000e8, updatedAt: block.timestamp });
        FeedParams memory feedParams1 =
            FeedParams({ addr: FEED1, decimals: 8, answer: 1e8, updatedAt: block.timestamp });

        // Initial balanced pool state
        uint256 token0PoolReserve = 1e18;
        uint256 token1PoolReserve = 4000e18;

        // Next pool state: attacker unbalances the pool
        // Assume: zero swap fees. Out token is token1.
        // tokenAmountOut is set to the maximum amount before reverting due to: BNum_BPowBaseTooHigh()
        uint256 tokenAmountOut = 1999e18;
        uint256 tokenAmountIn =
            calcInGivenOut(token0PoolReserve, WEIGHT_50, token1PoolReserve, WEIGHT_50, tokenAmountOut, 0);
        token1PoolReserve -= tokenAmountOut;
        token0PoolReserve += tokenAmountIn;

        // Mock calls
        setPriceFeedData(feedParams0, feedParams1);
        setMockOrder(token0PoolReserve, token1PoolReserve, WEIGHT_50);
        mock_pool_totalSupply(MOCK_POOL, LP_TOKEN_SUPPLY);

        // Naive price
        // token0PoolReserve ≈ 0.5e8 token 0, token1PoolReserve ≈ 8000e18 token 1
        // naivePrice ≈ 10e8 == (2 * 4000 + 2000 * 1)
        uint256 naivePrice = (token0PoolReserve * 4000e8 + token1PoolReserve * 1e8) / LP_TOKEN_SUPPLY;

        // LP price
        (, int256 answer,,,) = oracle.latestRoundData();

        // Assertions
        // The naive LP token price is approx 25% higher than balanced pool price.
        assertApproxEqRel(naivePrice, 10e8, 1e16);
        // LP token price is within 2.5% of the balanced pool state
        assertApproxEqRel(uint256(answer), 8e8, 2.5e16);
    }

    function test_80_20Pool_LargeUnbalancing_TooMuchToken0() external whenPositivePrices whenUnbalancedPool {
        FeedParams memory feedParams0 =
            FeedParams({ addr: FEED0, decimals: 8, answer: 4000e8, updatedAt: block.timestamp });
        FeedParams memory feedParams1 =
            FeedParams({ addr: FEED1, decimals: 8, answer: 1e8, updatedAt: block.timestamp });

        // Initial balanced pool state 80% token 0 - 20% token 1
        // Price in balanced state is 5e8
        uint256 token0PoolReserve = 1e18;
        uint256 token1PoolReserve = 1000e18;

        // Mock calls
        setPriceFeedData(feedParams0, feedParams1);
        setMockOrder(token0PoolReserve, token1PoolReserve, WEIGHT_80); // 3rd input is token0 weight
        mock_pool_totalSupply(MOCK_POOL, LP_TOKEN_SUPPLY);

        // Next pool state: attacker unbalances the pool
        // Assume: zero swap fees. Out token is token0.
        // tokenAmountOut is set to approx. max amount before reverting due to: BNum_BPowBaseTooHigh()
        uint256 tokenAmountOut = 0.5e18 - 1 wei;
        uint256 tokenAmountIn =
            calcInGivenOut(token1PoolReserve, WEIGHT_20, token0PoolReserve, WEIGHT_80, tokenAmountOut, 0);
        token0PoolReserve -= tokenAmountOut;
        token1PoolReserve += tokenAmountIn;

        // NaivePrice ≈ 18e8 == (0.5 * 4000 + 16000 * 1)
        uint256 naivePrice = (token0PoolReserve * 4000e8 + token1PoolReserve * 1e8) / LP_TOKEN_SUPPLY;

        // LP price
        (, int256 answer,,,) = oracle.latestRoundData();

        // Assertions
        // The naive LP token price is approx 260% higher than balanced pool price.
        assertApproxEqRel(naivePrice, 18e8, 1e16); // 1% diff
        // LP token price is within 0.1% of the balance pool price.
        assertApproxEqRel(uint256(answer), 5e8, 1e15);
    }

    function test_80_20Pool_LargeUnbalancing_TooMuchToken1() external whenPositivePrices whenUnbalancedPool {
        FeedParams memory feedParams0 =
            FeedParams({ addr: FEED0, decimals: 8, answer: 4000e8, updatedAt: block.timestamp });
        FeedParams memory feedParams1 =
            FeedParams({ addr: FEED1, decimals: 8, answer: 1e8, updatedAt: block.timestamp });

        // Initial balanced pool state 80% token 0 - 20% token 1
        // Price in balanced state is 5e8
        uint256 token0PoolReserve = 1e18;
        uint256 token1PoolReserve = 1000e18;

        // Mock calls
        setPriceFeedData(feedParams0, feedParams1);
        setMockOrder(token0PoolReserve, token1PoolReserve, WEIGHT_80); // 3rd input is token0 weight
        mock_pool_totalSupply(MOCK_POOL, LP_TOKEN_SUPPLY);

        // Next pool state: attacker unbalances the pool
        // Assume: zero swap fees. Out token is token1.
        // tokenAmountOut is set to approx. max amount before reverting due to: BNum_BPowBaseTooHigh()
        uint256 tokenAmountOut = 499e18;
        uint256 tokenAmountIn =
            calcInGivenOut(token0PoolReserve, WEIGHT_80, token1PoolReserve, WEIGHT_20, tokenAmountOut, 0);
        token1PoolReserve -= tokenAmountOut;
        token0PoolReserve += tokenAmountIn;

        // NaivePrice ≈ 10e8 == (0.5 * 4000 + 16000 * 1)
        uint256 naivePrice = (token0PoolReserve * 4000e8 + token1PoolReserve * 1e8) / LP_TOKEN_SUPPLY;

        // LP price
        (, int256 answer,,,) = oracle.latestRoundData();

        // Assertions
        // The naive LP token price is approx 6% higher than balanced pool price.
        assertApproxEqRel(naivePrice, 5e8, 6e16);
        // LP token price is within 0.1% of the balance pool price.
        assertApproxEqRel(uint256(answer), 5e8, 1e15);
    }
}
