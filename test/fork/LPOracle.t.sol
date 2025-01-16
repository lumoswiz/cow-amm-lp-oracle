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
        // Setup asset adjustment amounts
        uint256 adjust0By = 10 ** (18 - FORK_TOKEN0.decimals());
        uint256 adjust1By = 10 ** (18 - FORK_TOKEN1.decimals());
        uint256 adjustedBalance0 = INITIAL_POOL_TOKEN0_BALANCE * adjust0By;
        uint256 adjustedBalance1 = INITIAL_POOL_TOKEN1_BALANCE * adjust1By;

        // Calculate naive price before manipulation
        uint256 naivePriceBefore = calculateNaivePrice(
            FEED0_DECIMALS,
            FEED1_DECIMALS,
            INITIAL_FEED0_ANSWER,
            INITIAL_FEED1_ANSWER,
            adjustedBalance0,
            adjustedBalance1,
            INITIAL_POOL_LP_SUPPLY
        );

        // Get the current LPOracle answer
        (, int256 answerBefore,,,) = lpOracle.latestRoundData();

        // Assert that the pool is in a relatively balanced state
        assertApproxEqRel(
            uint256(INITIAL_FEED0_ANSWER) * adjustedBalance0, uint256(INITIAL_FEED1_ANSWER) * adjustedBalance1, 2e16
        ); // within 1%

        // Calculate token amounts out and in
        uint256 token1AmountOut = (9000 * adjustedBalance1) / 1e4; // 90% token 1 out
        uint256 token0AmountIn = calcInGivenOutSignedWadMath(
            adjustedBalance0,
            uint256(lpOracle.WEIGHT0()),
            adjustedBalance1,
            uint256(lpOracle.WEIGHT1()),
            token1AmountOut
        );

        // Mock the new balances
        mock_token_balanceOf(FORK_TOKEN0, FORK_POOL, INITIAL_POOL_TOKEN0_BALANCE + token0AmountIn / adjust0By);
        mock_token_balanceOf(FORK_TOKEN1, FORK_POOL, INITIAL_POOL_TOKEN1_BALANCE - token1AmountOut / adjust1By);

        // Calculate the naive price
        uint256 naivePriceAfter = calculateNaivePrice(
            FEED0_DECIMALS,
            FEED1_DECIMALS,
            INITIAL_FEED0_ANSWER,
            INITIAL_FEED1_ANSWER,
            adjustedBalance0 + token0AmountIn,
            adjustedBalance1 - token1AmountOut,
            INITIAL_POOL_LP_SUPPLY
        );

        // Retrieve the LPOracle answer
        (, int256 answer,,,) = lpOracle.latestRoundData();

        // Assertions
        // The LPOracle answer before and after manipulation is approximately the same
        assertApproxEqRel(uint256(answer), uint256(answerBefore), 1e16);
        //The LPOracle price is less than the naive pricing (before manipulation)
        assertLt(uint256(answer), naivePriceBefore);
        // The naive price after manipulation is > 200% more than the LPOracle price
        assertGt(stdMath.percentDelta(naivePriceAfter, uint256(answer)), 2e18);
    }

    function test_LatestRoundData_ManipulatePoolBalances_LargeAmountToken0Out() external {
        // Setup asset adjustment amounts
        uint256 adjust0By = 10 ** (18 - FORK_TOKEN0.decimals());
        uint256 adjust1By = 10 ** (18 - FORK_TOKEN1.decimals());
        uint256 adjustedBalance0 = INITIAL_POOL_TOKEN0_BALANCE * adjust0By;
        uint256 adjustedBalance1 = INITIAL_POOL_TOKEN1_BALANCE * adjust1By;

        // Calculate naive price before manipulation
        uint256 naivePriceBefore = calculateNaivePrice(
            FEED0_DECIMALS,
            FEED1_DECIMALS,
            INITIAL_FEED0_ANSWER,
            INITIAL_FEED1_ANSWER,
            adjustedBalance0,
            adjustedBalance1,
            INITIAL_POOL_LP_SUPPLY
        );

        // Get the current LPOracle answer
        (, int256 answerBefore,,,) = lpOracle.latestRoundData();

        // Assert that the pool is in a relatively balanced state
        assertApproxEqRel(
            uint256(INITIAL_FEED0_ANSWER) * adjustedBalance0, uint256(INITIAL_FEED1_ANSWER) * adjustedBalance1, 2e16
        ); // within 1%

        // Calculate token amounts out and in
        uint256 token0AmountOut = (9000 * adjustedBalance0) / 1e4; // 90% token 0 out
        uint256 token1AmountIn = calcInGivenOutSignedWadMath(
            adjustedBalance1,
            uint256(lpOracle.WEIGHT1()),
            adjustedBalance0,
            uint256(lpOracle.WEIGHT0()),
            token0AmountOut
        );

        // Mock the new balances
        mock_token_balanceOf(FORK_TOKEN0, FORK_POOL, INITIAL_POOL_TOKEN0_BALANCE - token0AmountOut / adjust0By);
        mock_token_balanceOf(FORK_TOKEN1, FORK_POOL, INITIAL_POOL_TOKEN1_BALANCE + token1AmountIn / adjust1By);

        // Calculate the naive price
        uint256 naivePriceAfter = calculateNaivePrice(
            FEED0_DECIMALS,
            FEED1_DECIMALS,
            INITIAL_FEED0_ANSWER,
            INITIAL_FEED1_ANSWER,
            adjustedBalance0 - token0AmountOut,
            adjustedBalance1 + token1AmountIn,
            INITIAL_POOL_LP_SUPPLY
        );

        // Retrieve the LPOracle answer
        (, int256 answer,,,) = lpOracle.latestRoundData();

        // Assertions
        //The LPOracle price is less than the naive pricing (before manipulation)
        assertLt(uint256(answer), naivePriceBefore);
        // The LPOracle answer before and after manipulation is approximately the same
        assertApproxEqRel(uint256(answer), uint256(answerBefore), 1e16);
        // The naive price after manipulation is > 200% more than the LPOracle price
        assertGt(stdMath.percentDelta(naivePriceAfter, uint256(answer)), 2e18);
    }
}
