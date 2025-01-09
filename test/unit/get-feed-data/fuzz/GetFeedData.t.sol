// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.25;

import { BaseTest } from "test/Base.t.sol";
import { FeedParams } from "test/utils/Types.sol";
import { stdError } from "forge-std/StdError.sol";

contract GetFeedData_Fuzz_Unit_Test is BaseTest {
    function testFuzz_ShouldRevert_Feed0DecimalsGt18(uint8 feed0Decimals) external {
        // Bounds
        feed0Decimals = boundUint8(feed0Decimals, 19, type(uint8).max);

        // Setup with mocks
        int256 answer0 = 1e30;
        int256 answer1 = 1e8;

        (FeedParams memory params0, FeedParams memory params1) =
            defaults.mockAllFeedParams(feed0Decimals, 8, answer0, answer1, block.timestamp, block.timestamp);

        setPriceFeedData(params0, params1);

        vm.expectRevert(stdError.arithmeticError);
        oracle.exposed_getFeedData();
    }

    function testFuzz_ShouldRevert_Feed1DecimalsGt18(uint8 feed1Decimals) external {
        // Bounds
        feed1Decimals = boundUint8(feed1Decimals, 19, type(uint8).max);

        // Setup with mocks
        int256 answer0 = 1e8;
        int256 answer1 = 1e19;

        (FeedParams memory params0, FeedParams memory params1) =
            defaults.mockAllFeedParams(8, feed1Decimals, answer0, answer1, block.timestamp, block.timestamp);

        setPriceFeedData(params0, params1);

        vm.expectRevert(stdError.arithmeticError);
        oracle.exposed_getFeedData();
    }

    modifier givenWhenDecimalsLtEq18() {
        _;
    }

    function testFuzz_GetFeedData_SameDecimals_Feed0Oldest(
        uint8 decimals,
        int256 answer0,
        int256 answer1,
        uint256 updatedAt0,
        uint256 updatedAt1
    )
        external
        givenWhenDecimalsLtEq18
    {
        // Bounds
        decimals = boundUint8(decimals, 0, 18);
        int256 adjustBy = int256(10 ** decimals);
        int256 min = type(int256).min / adjustBy;
        int256 max = type(int256).max / adjustBy;
        answer0 = bound(answer0, min, max);
        answer1 = bound(answer1, min, max);
        updatedAt0 = bound(updatedAt0, 0, defaults.DEC_1_2024());
        updatedAt1 = bound(updatedAt1, updatedAt0 + 1, type(uint40).max);

        // Setup with mocks
        (FeedParams memory params0, FeedParams memory params1) =
            defaults.mockAllFeedParams(decimals, decimals, answer0, answer1, updatedAt0, updatedAt1);

        setPriceFeedData(params0, params1);

        // Call
        (int256 price0, int256 price1, uint256 updatedAt) = oracle.exposed_getFeedData();

        // Assertions
        assertEq(price0, answer0, "price0");
        assertEq(price1, answer1, "price1");
        assertEq(updatedAt, updatedAt0, "updatedAt");
    }

    modifier givenWhenDifferentDecimals() {
        _;
    }

    function testFuzz_GetFeedData_ArithmeticErrors_NegativeDomain(
        uint8 feed0Decimals,
        uint8 feed1Decimals,
        int256 answer0,
        int256 answer1,
        uint256 updatedTimestamp
    )
        external
        givenWhenDecimalsLtEq18
        givenWhenDifferentDecimals
        whenNoAdjustArithmeticErrors
    {
        // Bounds
        feed0Decimals = boundUint8(feed0Decimals, 0, 17); // answer 0 will need adjusting
        feed1Decimals = boundUint8(feed1Decimals, 0, 18);
        vm.assume(feed0Decimals != feed1Decimals);

        int256 adjustBy0 = int256(10 ** (18 - feed0Decimals));
        answer0 = bound(answer0, type(int256).min, (type(int256).min / adjustBy0) - 1);
        updatedTimestamp = bound(updatedTimestamp, 0, type(uint40).max);

        // Setup with mocks
        (FeedParams memory params0, FeedParams memory params1) = defaults.mockAllFeedParams(
            feed0Decimals, feed1Decimals, answer0, answer1, updatedTimestamp, updatedTimestamp
        );

        setPriceFeedData(params0, params1);

        // Call
        vm.expectRevert(stdError.arithmeticError);
        oracle.exposed_getFeedData();
    }

    function testFuzz_GetFeedData_ArithmeticErrors_PositiveDomain(
        uint8 feed0Decimals,
        uint8 feed1Decimals,
        int256 answer0,
        int256 answer1,
        uint256 updatedTimestamp
    )
        external
        givenWhenDecimalsLtEq18
        givenWhenDifferentDecimals
        whenNoAdjustArithmeticErrors
    {
        // Bounds
        feed0Decimals = boundUint8(feed0Decimals, 0, 17); // answer 0 will need adjusting
        feed1Decimals = boundUint8(feed1Decimals, 0, 18);
        vm.assume(feed0Decimals != feed1Decimals);

        int256 adjustBy0 = int256(10 ** (18 - feed0Decimals));
        answer0 = bound(answer0, (type(int256).max / adjustBy0) + 1, type(int256).max);
        updatedTimestamp = bound(updatedTimestamp, 0, type(uint40).max);

        // Setup with mocks
        (FeedParams memory params0, FeedParams memory params1) = defaults.mockAllFeedParams(
            feed0Decimals, feed1Decimals, answer0, answer1, updatedTimestamp, updatedTimestamp
        );

        setPriceFeedData(params0, params1);

        // Call
        vm.expectRevert(stdError.arithmeticError);
        oracle.exposed_getFeedData();
    }

    modifier whenNoAdjustArithmeticErrors() {
        _;
    }

    function testFuzz_GetFeedData(
        uint8 feed0Decimals,
        uint8 feed1Decimals,
        int256 answer0,
        int256 answer1,
        uint256 updatedTimestamp
    )
        external
        givenWhenDecimalsLtEq18
        givenWhenDifferentDecimals
        whenNoAdjustArithmeticErrors
    {
        // Bounds
        feed0Decimals = boundUint8(feed0Decimals, 0, 18);
        feed1Decimals = boundUint8(feed1Decimals, 0, 18);
        vm.assume(feed0Decimals != feed1Decimals);

        int256 adjustBy0 = int256(10 ** (18 - feed0Decimals));
        answer0 = bound(answer0, type(int256).min / adjustBy0, type(int256).max / adjustBy0);

        int256 adjustBy1 = int256(10 ** (18 - feed1Decimals));
        answer1 = bound(answer1, type(int256).min / adjustBy1, type(int256).max / adjustBy1);
        updatedTimestamp = bound(updatedTimestamp, 0, type(uint40).max);

        // Setup with mocks
        (FeedParams memory params0, FeedParams memory params1) = defaults.mockAllFeedParams(
            feed0Decimals, feed1Decimals, answer0, answer1, updatedTimestamp, updatedTimestamp
        );

        setPriceFeedData(params0, params1);

        // Call
        (int256 price0, int256 price1, uint256 updatedAt) = oracle.exposed_getFeedData();

        // Assertions
        assertEq(price0, answer0 * adjustBy0, "price0");
        assertEq(price1, answer1 * adjustBy1, "price1");
        assertEq(updatedAt, updatedTimestamp, "updatedAt");
    }
}
