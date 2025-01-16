// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.25;

import { BaseTest } from "test/Base.t.sol";
import { stdError } from "forge-std/StdError.sol";
import { wadMul, wadDiv, wadPow } from "solmate/utils/SignedWadMath.sol";

contract CalculateTVL_Concrete_Unit_Test is BaseTest {
    /* ------------------------------------------------------------ */
    /*   # POOL INVARIANT K CALCULATION                             */
    /* ------------------------------------------------------------ */

    // int256 k = wadMul(wadPow(wadDiv(balance0, balance1), WEIGHT0), balance1);

    function test_ShouldRevert_InvariantK_Balance0TooLarge() external {
        int256 balance0 = (type(int256).max / 1e18) + 1;
        int256 balance1 = 3000e18;
        vm.expectRevert();
        wadDiv(balance0, balance1);
    }

    modifier whenValidBalance0() {
        _;
    }

    function test_ShouldRevert_InvariantK_Balance1Zero() external whenValidBalance0 {
        int256 balance0 = 1e18;
        vm.expectRevert();
        wadDiv(balance0, 0);
    }

    function test_ShouldRevert_InvariantK_Balance1Negative() external whenValidBalance0 {
        int256 balance0 = 1e18;
        int256 balance1 = -1;
        int256 weight0 = 0.5e18;
        vm.expectRevert();
        wadPow(wadDiv(balance0, balance1), weight0);
    }

    function test_ShouldRevert_InvariantK_Balance1LargeRelativeBalance0() external whenValidBalance0 {
        int256 balance0 = 1e18;
        int256 balance1 = balance0 * 1e18 + 1;
        int256 weight0 = int256(defaults.WEIGHT_50());
        vm.expectRevert("UNDEFINED");
        wadPow(wadDiv(balance0, balance1), weight0);
    }

    modifier whenValidBalance1() {
        // Require 1 & 2
        // 1. > 0
        // 2. <= balance0 * 1e18
        _;
    }

    function test_ShouldRevert_InvariantK_WadMulOverflows() external whenValidBalance0 whenValidBalance1 {
        // Set max values
        int256 balance0 = (type(int256).max / 1e18);
        int256 balance1 = balance0 * 1e18;
        int256 weight0 = 98e16;
        vm.expectRevert();
        wadMul(wadPow(wadDiv(balance0, balance1), weight0), balance1);
    }

    modifier whenKDoesNotOverflow() {
        _;
    }

    /* ------------------------------------------------------------ */
    /*   # CALCULATE POOL TVL                                       */
    /* ------------------------------------------------------------ */

    // int256 pxComponent = wadPow(answer0, WEIGHT0);
    // int256 pyComponent = wadPow(answer1, WEIGHT1);
    // uint256 tvl = uint256(wadMul(wadMul(wadMul(k, pxComponent), pyComponent), weightFactor));

    function test_ShouldRevert_TVL_AnswerZero() external {
        vm.expectRevert("UNDEFINED");
        wadPow(0, 0.5e18);
    }

    function test_ShouldRevert_TVL_AnswerNegative() external {
        vm.expectRevert("UNDEFINED");
        wadPow(-1, 0.5e18);
    }

    modifier whenAnswersPositive() {
        _;
    }

    // In tvl calculation, there are 3 consecutive wadMul operations. To avoid overflow:
    // Require: k * pxComponent * pyComponent * weightFactor <= type(int256).max
    //
    // The weightFactor is a maximum for a 50/50 pool, minimum for 98/2 pool.
    // Maximum: weightFactor = 2e18
    //
    // For a given balance0 in a 50/50 balanced pool, changing the magnitude of balance1
    // by an order of 2 changes the order of the k value in the same direction. Example:
    // Let b0 = 1000e18 & b1 = 1e16: k = 3.16
    // Now, let b1 = 1e18: k = 31.6

    function test_ShouldRevert_TVL_WadMulsLeadToOverflow()
        external
        whenValidBalance0
        whenValidBalance1
        whenKDoesNotOverflow
        whenAnswersPositive
    {
        int256 weight0 = 0.5e18; // 50/50 pool
        int256 weightFactor = 2e18;

        // k value
        int256 balance0 = type(int160).max;
        int256 balance1 = balance0 * 1e18;
        int256 k = wadMul(wadPow(wadDiv(balance0, balance1), weight0), balance1);

        // components
        int256 answer0 = 1e24;
        int256 answer1 = 2e18;
        int256 pxComponent = wadPow(answer0, weight0);
        int256 pyComponent = wadPow(answer1, 1e18 - weight0);

        // tvl
        vm.expectRevert();
        uint256 tvl = uint256(wadMul(wadMul(wadMul(k, pxComponent), pyComponent), weightFactor));
    }

    function test_TVL_MaxKValue_VeryHighAnswersAndHighFeedDecimals()
        external
        pure
        whenValidBalance0
        whenValidBalance1
        whenKDoesNotOverflow
        whenAnswersPositive
    {
        // Max value for: k * pxComponent * pyComponent
        int256 weight0 = 0.5e18;
        int256 weightFactor = 2e18; // max weight factor
        int256 maxValueForKPxPy = type(int256).max / weightFactor; // has 58 decimals

        // Both answers are high
        // $10m expressed with 18 decimals
        int256 answer = 1_000_000e18;
        int256 pComponent = wadPow(answer, weight0); // pxComponent == pyComponent

        // max k value
        int256 maxK = maxValueForKPxPy / (pComponent ** 2);
        assertLt(maxK, 1e18); // relatively low maximum k value
    }

    function test_TVL_MaxKValue_LowAnswersAndLowFeedDecimals()
        external
        pure
        whenValidBalance0
        whenValidBalance1
        whenKDoesNotOverflow
        whenAnswersPositive
    {
        // Max value for: k * pxComponent * pyComponent
        int256 weight0 = 0.5e18;
        int256 weightFactor = 2e18; // max weight factor
        int256 maxValueForKPxPy = type(int256).max / weightFactor; // has 58 decimals

        // Both answers are relatively low
        // $0.0000001 expressed with 8 decimals
        int256 answer = 1;
        int256 pComponent = wadPow(answer, weight0); // pxComponent == pyComponent

        // max k value
        int256 maxK = maxValueForKPxPy / (pComponent ** 2);
        assertGt(maxK, 1e40); // relatively high maximum k value
    }

    /* ------------------------------------------------------------ */
    /*   # ORACLE: _calculateTVL                                    */
    /* ------------------------------------------------------------ */

    function test_ShouldRevert_TokenDecimalsGt18() external {
        reinitOracle(19, 6);
        setTokenBalances(1e19, 1e6);

        vm.expectRevert(stdError.arithmeticError);
        oracle.exposed_calculateTVL(1e8, 1e8);
    }

    modifier whenTokenDecimalsLtEq18() {
        _;
    }

    function test_CalculateTVL_SameDecimalTokens()
        external
        whenTokenDecimalsLtEq18
        whenValidBalance0
        whenValidBalance1
        whenKDoesNotOverflow
        whenAnswersPositive
    {
        // Setup: answers
        int256 answer0Base = 3000;
        int256 answer1Base = 1;
        (int256 answer0, int256 answer1) = (answer0Base * 1e8, answer1Base * 1e8);

        // Mock token balances for the balanced 50/50 pool
        setTokenBalances(defaults.TOKEN0_BALANCE(), defaults.TOKEN1_BALANCE());

        // Calculate TVL
        uint256 tvl = oracle.exposed_calculateTVL(answer0, answer1);

        // Assertions
        assertApproxEqAbs(tvl, (2 * uint256(answer0Base)) * 1e8, 2);
    }

    function test_CalculateTVL_DifferentDecimalTokens()
        external
        whenTokenDecimalsLtEq18
        whenValidBalance0
        whenValidBalance1
        whenKDoesNotOverflow
        whenAnswersPositive
    {
        // Setup: answers
        int256 answer0Base = 3000;
        int256 answer1Base = 1;
        (int256 answer0, int256 answer1) = (answer0Base * 1e8, answer1Base * 1e8);

        // Mocks
        reinitOracle(18, 6);
        setTokenBalances(1e18, uint256(answer0Base) * 1e6); // 1 unit token 0, 3000 units token 1

        // Calculate TVL
        uint256 tvl = oracle.exposed_calculateTVL(answer0, answer1);

        // Assertions
        assertApproxEqAbs(tvl, (2 * uint256(answer0Base)) * 1e8, 2);
    }
}
