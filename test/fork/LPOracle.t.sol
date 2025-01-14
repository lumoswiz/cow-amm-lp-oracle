// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.25 < 0.9.0;

import { ForkTest } from "test/fork/Fork.t.sol";
import { stdMath } from "forge-std/StdMath.sol";

contract LPOracle_Fork_Test is ForkTest {
    constructor(address _token0, address _token1) ForkTest(_token0, _token1) { }

    function test_Decimals() external view {
        uint8 feed0Decimals = FORK_FEED0.decimals();
        uint8 feed1Decimals = FORK_FEED1.decimals();
        uint8 oracleDecimals = lpOracle.decimals();

        if (feed0Decimals == feed1Decimals) {
            assertEq(oracleDecimals, feed0Decimals);
        } else {
            assertEq(oracleDecimals, 18);
        }
    }

    function test_Descriptor() external view {
        string memory expectedDescription = string.concat(FORK_POOL.name(), " LP Token / USD");
        assertEq(lpOracle.description(), expectedDescription, "description");
    }

    function test_LatestRoundData_ManipulatePoolBalances_LargeAmountToken1Out() external {
        // Initial pool token balances
        uint256 token0Balance = FORK_TOKEN0.balanceOf(address(FORK_POOL));
        uint256 token1Balance = FORK_TOKEN1.balanceOf(address(FORK_POOL));

        // Get underlying price feed answers
        (, int256 answer0,,,) = FORK_FEED0.latestRoundData();
        (, int256 answer1,,,) = FORK_FEED1.latestRoundData();

        // Get other inputs for calculateNaivePrice
        uint8 feed0Decimals = FORK_FEED0.decimals();
        uint8 feed1Decimals = FORK_FEED1.decimals();
        uint256 lpSupply = FORK_POOL.totalSupply();

        // Calculate naive price before manipulation
        uint256 naivePriceBefore =
            calculateNaivePrice(feed0Decimals, feed1Decimals, answer0, answer1, token0Balance, token1Balance, lpSupply);

        // Get the current LPOracle answer
        (, int256 answer,,,) = lpOracle.latestRoundData();

        // Assert that the pool is in a relatively balanced state: naivePrice ≈ LPOracle answer
        assertApproxEqRel(uint256(answer), naivePriceBefore, 1e15); // within 0.1%

        // Calculate token amounts out and in
        uint256 token1AmountOut = (9000 * token1Balance) / 1e4; // 90% token 1 out
        uint256 token0AmountIn = calcInGivenOutSignedWadMath(
            token0Balance, uint256(lpOracle.WEIGHT0()), token1Balance, uint256(lpOracle.WEIGHT1()), token1AmountOut
        );

        // Mock the new balances
        mock_token_balanceOf(FORK_TOKEN0, FORK_POOL, token0Balance + token0AmountIn);
        mock_token_balanceOf(FORK_TOKEN1, FORK_POOL, token1Balance - token1AmountOut);

        // Calculate the naive price
        uint256 naivePriceAfter = calculateNaivePrice(
            feed0Decimals,
            feed1Decimals,
            answer0,
            answer1,
            token0Balance + token0AmountIn,
            token1Balance - token1AmountOut,
            lpSupply
        );

        // Retrieve the LPOracle answer
        (, answer,,,) = lpOracle.latestRoundData();

        // Assertions
        // The LPOracle answer after manipulation is within 0.1% price before manipulation
        assertApproxEqRel(uint256(answer), naivePriceBefore, 1e15);
        // The naive price after manipulation is > 200% more than the LPOracle price
        assertGt(stdMath.percentDelta(naivePriceAfter, uint256(answer)), 2e18);
    }
}
