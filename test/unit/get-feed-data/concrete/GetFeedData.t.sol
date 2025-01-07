// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.25;

import { BaseTest } from "test/Base.t.sol";
import { FeedParams } from "test/utils/Types.sol";
import { stdError } from "forge-std/StdError.sol";

contract GetFeedData_Concrete_Unit_Test is BaseTest {
    function test_ShouldRevert_Feed0DecimalsGt18() external {
        // Setup with mocks
        int256 answer0 = 1e19;
        int256 answer1 = 1e8;

        (FeedParams memory params0, FeedParams memory params1) =
            defaults.mockAllFeedParams(19, 8, answer0, answer1, block.timestamp, block.timestamp);

        setPriceFeedData(params0, params1);

        vm.expectRevert(stdError.arithmeticError);
        oracle.exposed_getFeedData();
    }

    function test_ShouldRevert_Feed1DecimalsGt18() external {
        // Setup with mocks
        int256 answer0 = 1e8;
        int256 answer1 = 1e19;

        (FeedParams memory params0, FeedParams memory params1) =
            defaults.mockAllFeedParams(8, 19, answer0, answer1, block.timestamp, block.timestamp);

        setPriceFeedData(params0, params1);

        vm.expectRevert(stdError.arithmeticError);
        oracle.exposed_getFeedData();
    }

    modifier givenWhenDecimalsLtEq18() {
        _;
    }

    function test_GetFeedData_SameDecimals_Feed0Oldest() external givenWhenDecimalsLtEq18 {
        // Setup with mocks
        uint8 decimals = 8;
        int256 answer0 = 3000e8;
        int256 answer1 = 1e8;
        uint256 updatedAt0 = block.timestamp - 1;
        uint256 updatedAt1 = block.timestamp;

        (FeedParams memory params0, FeedParams memory params1) =
            defaults.mockAllFeedParams(decimals, decimals, answer0, answer1, updatedAt0, updatedAt1);

        setPriceFeedData(params0, params1);

        // Call
        (int256 price0, int256 price1, uint256 updatedAt) = oracle.exposed_getFeedData();

        // Assertions
        assertEq(price0, 3000e8, "price0");
        assertEq(price1, 1e8, "price1");
        assertEq(updatedAt, block.timestamp - 1, "updatedAt");
    }

    function test_GetFeedData_SameDecimals_Feed1Oldest() external givenWhenDecimalsLtEq18 {
        // Setup with mocks
        uint8 decimals = 8;
        int256 answer0 = 3000e8;
        int256 answer1 = 1e8;
        uint256 updatedAt0 = block.timestamp;
        uint256 updatedAt1 = block.timestamp - 10;

        (FeedParams memory params0, FeedParams memory params1) =
            defaults.mockAllFeedParams(decimals, decimals, answer0, answer1, updatedAt0, updatedAt1);

        setPriceFeedData(params0, params1);

        // Call
        (int256 price0, int256 price1, uint256 updatedAt) = oracle.exposed_getFeedData();

        // Assertions
        assertEq(price0, 3000e8, "price0");
        assertEq(price1, 1e8, "price1");
        assertEq(updatedAt, block.timestamp - 10, "updatedAt");
    }

    modifier givenWhenDifferentDecimals() {
        _;
    }

    function test_ShouldRevert_Feed0ArithmeticError() external givenWhenDecimalsLtEq18 givenWhenDifferentDecimals {
        // Setup with mocks
        int256 answer0 = type(int256).max; // exceeds max value == type(int256).max / 1e12
        int256 answer1 = 1e18;

        (FeedParams memory params0, FeedParams memory params1) =
            defaults.mockAllFeedParams(6, 18, answer0, answer1, block.timestamp, block.timestamp);

        setPriceFeedData(params0, params1);

        vm.expectRevert(stdError.arithmeticError);
        oracle.exposed_getFeedData();
    }

    function test_ShouldRevert_Feed1ArithmeticError() external givenWhenDecimalsLtEq18 givenWhenDifferentDecimals {
        // Setup with mocks
        int256 answer0 = 1e18;
        int256 answer1 = type(int256).max; // exceeds max value == type(int256).max / 1e10

        (FeedParams memory params0, FeedParams memory params1) =
            defaults.mockAllFeedParams(18, 8, answer0, answer1, block.timestamp, block.timestamp);

        setPriceFeedData(params0, params1);

        vm.expectRevert(stdError.arithmeticError);
        oracle.exposed_getFeedData();
    }

    modifier whenNoAdjustArithmeticErrors() {
        _;
    }

    function test_GetFeedData_PositiveAnswers()
        external
        givenWhenDecimalsLtEq18
        givenWhenDifferentDecimals
        whenNoAdjustArithmeticErrors
    {
        // Setup with mocks
        uint8 feed0Decimals = 8;
        uint8 feed1Decimals = 10;
        int256 answer0 = 3000e8;
        int256 answer1 = 1e10;

        (FeedParams memory params0, FeedParams memory params1) = defaults.mockAllFeedParams(
            feed0Decimals, feed1Decimals, answer0, answer1, defaults.DEC_1_2024(), defaults.DEC_1_2024()
        );

        setPriceFeedData(params0, params1);

        // Call
        (int256 price0, int256 price1, uint256 updatedAt) = oracle.exposed_getFeedData();

        // Assertions
        assertEq(price0, 3000e18, "price0");
        assertEq(price1, 1e18, "price1");
        assertEq(updatedAt, defaults.DEC_1_2024(), "updatedAt");
    }

    function test_GetFeedData_NegativeAnswer()
        external
        givenWhenDecimalsLtEq18
        givenWhenDifferentDecimals
        whenNoAdjustArithmeticErrors
    {
        // Setup with mocks
        uint8 feed0Decimals = 8;
        uint8 feed1Decimals = 10;
        int256 answer0 = 3000e8;
        int256 answer1 = -1e10;

        (FeedParams memory params0, FeedParams memory params1) = defaults.mockAllFeedParams(
            feed0Decimals, feed1Decimals, answer0, answer1, defaults.DEC_1_2024(), defaults.DEC_1_2024()
        );

        setPriceFeedData(params0, params1);

        // Call
        (int256 price0, int256 price1, uint256 updatedAt) = oracle.exposed_getFeedData();

        // Assertions
        assertEq(price0, 3000e18, "price0");
        assertEq(price1, -1e18, "price1");
        assertEq(updatedAt, defaults.DEC_1_2024(), "updatedAt");
    }

    function test_GetFeedData_ZeroAnswer()
        external
        givenWhenDecimalsLtEq18
        givenWhenDifferentDecimals
        whenNoAdjustArithmeticErrors
    {
        // Setup with mocks
        uint8 feed0Decimals = 8;
        uint8 feed1Decimals = 10;
        int256 answer0 = 0;
        int256 answer1 = 1e10;

        (FeedParams memory params0, FeedParams memory params1) = defaults.mockAllFeedParams(
            feed0Decimals, feed1Decimals, answer0, answer1, defaults.DEC_1_2024(), defaults.DEC_1_2024()
        );

        setPriceFeedData(params0, params1);

        // Call
        (int256 price0, int256 price1, uint256 updatedAt) = oracle.exposed_getFeedData();

        // Assertions
        assertEq(price0, 0, "price0");
        assertEq(price1, 1e18, "price1");
        assertEq(updatedAt, defaults.DEC_1_2024(), "updatedAt");
    }
}
