// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.25;

import { BaseTest } from "test/Base.t.sol";
import { FeedParams } from "test/utils/Types.sol";
import { stdError } from "forge-std/StdError.sol";

contract GetFeedData_Unit_Test is BaseTest {
    function test_AdjustDecimals_SameDecimals() external {
        int256 answer0 = 100e6;
        int256 answer1 = 200e6;

        FeedParams memory params0 =
            FeedParams({ addr: mocks.feed0, decimals: 6, answer: answer0, updatedAt: block.timestamp });
        FeedParams memory params1 =
            FeedParams({ addr: mocks.feed1, decimals: 6, answer: answer1, updatedAt: block.timestamp });

        setPriceFeedData(params0, params1);

        (int256 price0, int256 price1,) = oracle.exposed_getFeedData();

        assertEq(price0, 100e6, "price0");
        assertEq(price1, 200e6, "price1");
    }

    function test_AdjustDecimals_DifferentDecimals() external {
        int256 answer0 = 100e6;
        int256 answer1 = 200e18;

        FeedParams memory params0 =
            FeedParams({ addr: mocks.feed0, decimals: 6, answer: answer0, updatedAt: block.timestamp });
        FeedParams memory params1 =
            FeedParams({ addr: mocks.feed1, decimals: 18, answer: answer1, updatedAt: block.timestamp });

        setPriceFeedData(params0, params1);

        (int256 price0, int256 price1,) = oracle.exposed_getFeedData();

        assertEq(price0, 100e6 * 1e12, "price0");
        assertEq(price1, 200e18, "price1");
    }

    function test_AdjustDecimals_ZeroAnswers() external {
        int256 answer0 = 0;
        int256 answer1 = 0;

        FeedParams memory params0 =
            FeedParams({ addr: mocks.feed0, decimals: 6, answer: answer0, updatedAt: block.timestamp });
        FeedParams memory params1 =
            FeedParams({ addr: mocks.feed1, decimals: 6, answer: answer1, updatedAt: block.timestamp });

        setPriceFeedData(params0, params1);

        (int256 price0, int256 price1,) = oracle.exposed_getFeedData();

        assertEq(price0, 0, "price0");
        assertEq(price1, 0, "price1");
    }

    function test_AdjustDecimals_LowAndDifferentDecimals() external {
        int256 answer0 = 100;
        int256 answer1 = 200e1;

        FeedParams memory params0 =
            FeedParams({ addr: mocks.feed0, decimals: 0, answer: answer0, updatedAt: block.timestamp });
        FeedParams memory params1 =
            FeedParams({ addr: mocks.feed1, decimals: 1, answer: answer1, updatedAt: block.timestamp });

        setPriceFeedData(params0, params1);

        (int256 price0, int256 price1,) = oracle.exposed_getFeedData();

        assertEq(price0, 100e18, "price0");
        assertEq(price1, 200e18, "price1");
    }

    function test_AdjustDecimals_NegativeAnswer_SameDecimals() external {
        int256 answer0 = -1e8;
        int256 answer1 = 200e8;

        FeedParams memory params0 =
            FeedParams({ addr: mocks.feed0, decimals: 8, answer: answer0, updatedAt: block.timestamp });
        FeedParams memory params1 =
            FeedParams({ addr: mocks.feed1, decimals: 8, answer: answer1, updatedAt: block.timestamp });

        setPriceFeedData(params0, params1);

        (int256 price0, int256 price1,) = oracle.exposed_getFeedData();

        assertEq(price0, -1e8, "price0");
        assertEq(price1, 200e8, "price1");
    }

    function test_AdjustDecimals_NegativeAnswer_DifferentDecimals() external {
        int256 answer0 = -1e8;
        int256 answer1 = 200e18;

        FeedParams memory params0 =
            FeedParams({ addr: mocks.feed0, decimals: 8, answer: answer0, updatedAt: block.timestamp });
        FeedParams memory params1 =
            FeedParams({ addr: mocks.feed1, decimals: 18, answer: answer1, updatedAt: block.timestamp });

        setPriceFeedData(params0, params1);

        (int256 price0, int256 price1,) = oracle.exposed_getFeedData();

        assertEq(price0, -1e8 * 1e10, "price0");
        assertEq(price1, 200e18, "price1");
    }

    function test_ShouldRevert_DecimalsGt18() external {
        int256 answer0 = 1e19;
        int256 answer1 = 1e18;

        FeedParams memory params0 =
            FeedParams({ addr: mocks.feed0, decimals: 19, answer: answer0, updatedAt: block.timestamp });
        FeedParams memory params1 =
            FeedParams({ addr: mocks.feed1, decimals: 18, answer: answer1, updatedAt: block.timestamp });

        setPriceFeedData(params0, params1);

        vm.expectRevert(stdError.arithmeticError);
        (int256 price0, int256 price1,) = oracle.exposed_getFeedData();
    }

    function test_ShouldRevert_LargeAnswer() external {
        int256 answer0 = type(int256).max;
        int256 answer1 = 1e18;

        FeedParams memory params0 =
            FeedParams({ addr: mocks.feed0, decimals: 6, answer: answer0, updatedAt: block.timestamp });
        FeedParams memory params1 =
            FeedParams({ addr: mocks.feed1, decimals: 18, answer: answer1, updatedAt: block.timestamp });

        setPriceFeedData(params0, params1);

        vm.expectRevert(stdError.arithmeticError);
        (int256 price0, int256 price1,) = oracle.exposed_getFeedData();
    }

    function testFuzz_AdjustDecimals(
        uint8 feed0Decimals,
        uint8 feed1Decimals,
        int256 answer0,
        int256 answer1
    )
        external
    {
        // Bound to valid ranges
        feed0Decimals = boundUint8(feed0Decimals, 0, 18);
        feed1Decimals = boundUint8(feed1Decimals, 0, 18);

        // Bound answers to prevent overflow
        answer0 = bound(answer0, 0, type(int256).max / (10 ** 18));
        answer1 = bound(answer1, 0, type(int256).max / (10 ** 18));

        FeedParams memory params0 =
            FeedParams({ addr: mocks.feed0, decimals: feed0Decimals, answer: answer0, updatedAt: block.timestamp });
        FeedParams memory params1 =
            FeedParams({ addr: mocks.feed1, decimals: feed1Decimals, answer: answer1, updatedAt: block.timestamp });

        setPriceFeedData(params0, params1);

        (int256 price0, int256 price1,) = oracle.exposed_getFeedData();

        if (feed0Decimals == feed1Decimals) {
            assertEq(price0, answer0, "price0");
            assertEq(price1, answer1, "price1");
        }
    }

    function testFuzz_Feed0_UpdatedAt_IsOldest(uint256 feed0UpdatedAt, uint256 feed1UpdatedAt) external {
        feed0UpdatedAt = bound(feed0UpdatedAt, 0, defaults.DEC_1_2024());
        feed1UpdatedAt = bound(feed1UpdatedAt, feed0UpdatedAt + 1, type(uint40).max);

        FeedParams memory params0 =
            FeedParams({ addr: mocks.feed0, decimals: 8, answer: 1e8, updatedAt: feed0UpdatedAt });
        FeedParams memory params1 =
            FeedParams({ addr: mocks.feed1, decimals: 8, answer: 1.1e8, updatedAt: feed1UpdatedAt });

        setPriceFeedData(params0, params1);

        (,, uint256 updatedAt) = oracle.exposed_getFeedData();

        assertEq(updatedAt, feed0UpdatedAt, "updatedAt");
    }

    function testFuzz_Feed1_UpdatedAt_IsOldest(uint256 feed0UpdatedAt, uint256 feed1UpdatedAt) external {
        feed1UpdatedAt = bound(feed1UpdatedAt, 0, defaults.DEC_1_2024());
        feed0UpdatedAt = bound(feed0UpdatedAt, feed1UpdatedAt + 1, type(uint40).max);

        FeedParams memory params0 =
            FeedParams({ addr: mocks.feed0, decimals: 8, answer: 1e8, updatedAt: feed0UpdatedAt });
        FeedParams memory params1 =
            FeedParams({ addr: mocks.feed1, decimals: 8, answer: 1.1e8, updatedAt: feed1UpdatedAt });

        setPriceFeedData(params0, params1);

        (,, uint256 updatedAt) = oracle.exposed_getFeedData();

        assertEq(updatedAt, feed1UpdatedAt, "updatedAt");
    }

    modifier whenSameDecimals() {
        _;
    }

    modifier whenSameUpdatedAt() {
        _;
    }

    // Todo: comment these out for now, accomodate negative answer tests in the upcoming test refactor.
    //    /// @dev When negative answers, explicit casting leads to unexpected behaviour.
    //    /// @dev In consuming functions, verify this can't lead to potentially harmful price values.
    //    function testFuzz_NegativeAnswer0(int256 answer0, int256 answer1) external whenSameDecimals whenSameUpdatedAt
    // {
    //        vm.assume(answer0 < 0);
    //        answer1 = bound(answer1, 1, 1e16);
    //
    //        (FeedParams memory params0, FeedParams memory params1) = defaults.mockFeedParams(answer0, answer1);
    //
    //        setPriceFeedData(params0, params1);
    //
    //        (int256 price0, int256 price1, uint256 updatedAt) = oracle.exposed_getFeedData();
    //
    //        assertGt(price0, type(uint128).max, "price0 > MAX_UINT128");
    //        assertEq(price1, answer1, "price1 == answer1");
    //        assertEq(updatedAt, block.timestamp, "updatedAt");
    //    }

    //    /// @dev When negative answers, explicit casting leads to unexpected behaviour.
    //    function testFuzz_NegativeAnswer1(int256 answer0, int256 answer1) external whenSameDecimals whenSameUpdatedAt
    // {
    //        vm.assume(answer1 < 0);
    //        answer0 = bound(answer0, 1, 1e16);
    //
    //        (FeedParams memory params0, FeedParams memory params1) = defaults.mockFeedParams(answer0, answer1);
    //
    //        setPriceFeedData(params0, params1);
    //
    //        (uint256 price0, uint256 price1, uint256 updatedAt) = oracle.exposed_getFeedData();
    //
    //        assertGt(price1, type(uint128).max, "price1 > MAX_UINT128");
    //        assertEq(price0, answer0, "price0 == answer0");
    //        assertEq(updatedAt, block.timestamp, "updatedAt");
    //    }

    modifier whenPositivePrices() {
        _;
    }

    function testFuzz_getFeedData(int256 answer0, int256 answer1) external whenPositivePrices whenSameUpdatedAt {
        answer0 = bound(answer0, 1, 1e24);
        answer1 = bound(answer1, 1, 1e24);

        (FeedParams memory params0, FeedParams memory params1) = defaults.mockFeedParams(answer0, answer1);

        setPriceFeedData(params0, params1);

        (int256 price0, int256 price1, uint256 updatedAt) = oracle.exposed_getFeedData();

        assertEq(price0, answer0);
        assertEq(price1, answer1);
        assertEq(updatedAt, block.timestamp, "updatedAt");
    }
}
