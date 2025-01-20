// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.25;

import { BaseTest } from "test/Base.t.sol";
import { wadMul, wadDiv, wadPow } from "solmate/utils/SignedWadMath.sol";

contract CalculateTVL_Fuzz_Unit_Test is BaseTest {
    /* ------------------------------------------------------------ */
    /*   # POOL INVARIANT K CALCULATION                             */
    /* ------------------------------------------------------------ */

    // int256 k = wadMul(wadPow(wadDiv(balance0, balance1), WEIGHT0), balance1);

    function testFuzz_Token0BalanceTooLarge(int256 balance0) external {
        balance0 = bound(balance0, type(int256).max / 1e18 + 1, type(int256).max);
        int256 balance1 = 3000e18;
        vm.expectRevert();
        wadDiv(balance0, balance1);
    }

    modifier whenValidBalance0() {
        _;
    }

    modifier whenValidBalance1() {
        // Require 1 & 2
        // 1. > 0
        // 2. <= balance0 * 1e18
        _;
    }

    function testFuzz_InvariantK(int256 balance0, int256 balance1) external whenValidBalance0 whenValidBalance1 {
        balance0 = bound(balance0, 1, type(int256).max / 1e18);
        balance1 = bound(balance1, 1, balance0 * 1e18);
        int256 a = wadDiv(balance0, balance1);
        assertGt(a, 0);
    }

    /* ------------------------------------------------------------ */
    /*   # WEIGHT FACTOR                                            */
    /* ------------------------------------------------------------ */

    // int256 weightFactor = wadPow(wadDiv(WEIGHT0, WEIGHT1), WEIGHT1) + wadPow(wadDiv(WEIGHT1, WEIGHT0), WEIGHT0);

    function testFuzz_WeightFactor_ForValidPoolWeights(int256 weight0) external {
        weight0 = bound(weight0, 2e16, 98e16); // only valid BCoWPool combinations
        int256 weight1 = 1e18 - weight0;
        int256 weightFactor = wadPow(wadDiv(weight0, weight1), weight1) + wadPow(wadDiv(weight1, weight0), weight0);
        assertGt(weightFactor, 0);
    }

    /* ------------------------------------------------------------ */
    /*   # CALCULATE POOL TVL                                       */
    /* ------------------------------------------------------------ */

    // int256 pxComponent = wadPow(answer0, WEIGHT0);
    // int256 pyComponent = wadPow(answer1, WEIGHT1);
    // uint256 tvl = uint256(wadMul(wadMul(wadMul(k, pxComponent), pyComponent), weightFactor));

    modifier whenKDoesNotOverflow() {
        _;
    }

    modifier whenAnswersPositive() {
        _;
    }

    function testFuzz_TVL_HighAnswersAndHighDecimals(
        int256 balance1,
        int256 answer0,
        int256 answer1,
        int256 weight0
    )
        external
        whenValidBalance0
        whenValidBalance1
        whenKDoesNotOverflow
        whenAnswersPositive
    {
        // Bounds
        answer0 = bound(answer0, 100_000e18, 1_000_000e18);
        answer1 = bound(answer1, 100_000e18, 1_000_000e18);
        weight0 = bound(weight0, 2e16, 98e16);
        balance1 = bound(balance1, 1e17, 1e19); // value locked range: 10k to 1bn
        int256 balance0 = int256(calcToken0FromToken1(18, 18, answer0, answer1, uint256(weight0), uint256(balance1)));

        // Calculations
        int256 k = wadMul(wadPow(wadDiv(balance0, balance1), weight0), balance1);
        int256 weightFactor =
            wadPow(wadDiv(weight0, 1e18 - weight0), 1e18 - weight0) + wadPow(wadDiv(1e18 - weight0, weight0), weight0);

        int256 pxComponent = wadPow(answer0, weight0);
        int256 pyComponent = wadPow(answer1, 1e18 - weight0);
        int256 tvl = wadMul(wadMul(wadMul(k, pxComponent), pyComponent), weightFactor);

        // Assertions
        assertGt(tvl, 0, "zero TVL");
    }

    function testFuzz_TVL_LowAnswersAndLowDecimals(
        int256 balance1,
        int256 answer0,
        int256 answer1,
        int256 weight0
    )
        external
        whenValidBalance0
        whenValidBalance1
        whenKDoesNotOverflow
        whenAnswersPositive
    {
        // Bounds
        answer0 = bound(answer0, 1, 10); // 0.000001 to 0.00001 in 6 decimals
        answer1 = bound(answer1, 1, 10); // 0.000001 to 0.00001 in 6 decimals
        weight0 = bound(weight0, 2e16, 98e16);
        balance1 = bound(balance1, 1e28, 1e32); // value locked range: 10k to 1bn
        int256 balance0 = int256(calcToken0FromToken1(6, 6, answer0, answer1, uint256(weight0), uint256(balance1)));

        // Calculations
        int256 k = wadMul(wadPow(wadDiv(balance0, balance1), weight0), balance1);
        int256 weightFactor =
            wadPow(wadDiv(weight0, 1e18 - weight0), 1e18 - weight0) + wadPow(wadDiv(1e18 - weight0, weight0), weight0);

        int256 pxComponent = wadPow(answer0, weight0);
        int256 pyComponent = wadPow(answer1, 1e18 - weight0);
        int256 tvl = wadMul(wadMul(wadMul(k, pxComponent), pyComponent), weightFactor);

        // Assertions
        assertGt(tvl, 0, "zero TVL");
    }
}
