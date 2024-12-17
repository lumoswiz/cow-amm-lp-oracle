// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.25;

import { BaseTest } from "test/Base.t.sol";
import { FeedParams } from "test/utils/Types.sol";

contract GetFeedData_Unit_Test is BaseTest {
    function testFuzz_Feed0_UpdatedAt_IsOldest(uint256 feed0UpdatedAt, uint256 feed1UpdatedAt) external {
        feed0UpdatedAt = bound(feed0UpdatedAt, 0, DEC_1_2024);
        feed1UpdatedAt = bound(feed1UpdatedAt, feed0UpdatedAt + 1, type(uint40).max);

        FeedParams memory params0 = FeedParams({ addr: FEED0, decimals: 8, answer: 1e8, updatedAt: feed0UpdatedAt });
        FeedParams memory params1 = FeedParams({ addr: FEED1, decimals: 8, answer: 1.1e8, updatedAt: feed1UpdatedAt });

        setPriceFeedData(params0, params1);

        (,, uint256 updatedAt) = oracle.exposed_getFeedData();

        assertEq(updatedAt, feed0UpdatedAt, "updatedAt");
    }

    function testFuzz_Feed1_UpdatedAt_IsOldest(uint256 feed0UpdatedAt, uint256 feed1UpdatedAt) external {
        feed1UpdatedAt = bound(feed1UpdatedAt, 0, DEC_1_2024);
        feed0UpdatedAt = bound(feed0UpdatedAt, feed1UpdatedAt + 1, type(uint40).max);

        FeedParams memory params0 = FeedParams({ addr: FEED0, decimals: 8, answer: 1e8, updatedAt: feed0UpdatedAt });
        FeedParams memory params1 = FeedParams({ addr: FEED1, decimals: 8, answer: 1.1e8, updatedAt: feed1UpdatedAt });

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

    /// @dev When negative answers, explicit casting leads to unexpected behaviour.
    /// @dev In consuming functions, verify this can't lead to potentially harmful price values.
    function testFuzz_NegativeAnswer0(int256 answer0, int256 answer1) external whenSameDecimals whenSameUpdatedAt {
        vm.assume(answer0 < 0);
        answer1 = bound(answer1, 1, 1e16);

        FeedParams memory params0 =
            FeedParams({ addr: FEED0, decimals: 8, answer: answer0, updatedAt: block.timestamp });
        FeedParams memory params1 =
            FeedParams({ addr: FEED1, decimals: 8, answer: answer1, updatedAt: block.timestamp });

        setPriceFeedData(params0, params1);

        (uint256 price0, uint256 price1, uint256 updatedAt) = oracle.exposed_getFeedData();

        assertGt(price0, type(uint128).max, "price0 > MAX_UINT128");
        assertEq(price1, uint256(answer1), "price1 == uint256(answer1)");
        assertEq(updatedAt, block.timestamp, "updatedAt");
    }

    /// @dev When negative answers, explicit casting leads to unexpected behaviour.
    function testFuzz_NegativeAnswer1(int256 answer0, int256 answer1) external whenSameDecimals whenSameUpdatedAt {
        vm.assume(answer1 < 0);
        answer0 = bound(answer0, 1, 1e16);

        FeedParams memory params0 =
            FeedParams({ addr: FEED0, decimals: 8, answer: answer0, updatedAt: block.timestamp });
        FeedParams memory params1 =
            FeedParams({ addr: FEED1, decimals: 8, answer: answer1, updatedAt: block.timestamp });

        setPriceFeedData(params0, params1);

        (uint256 price0, uint256 price1, uint256 updatedAt) = oracle.exposed_getFeedData();

        assertGt(price1, type(uint128).max, "price1 > MAX_UINT128");
        assertEq(price0, uint256(answer0), "price0 == uint256(answer0)");
        assertEq(updatedAt, block.timestamp, "updatedAt");
    }

    modifier whenPositivePrices() {
        _;
    }

    function testFuzz_getFeedData(int256 answer0, int256 answer1) external whenPositivePrices whenSameUpdatedAt {
        answer0 = bound(answer0, 1, 1e24);
        answer1 = bound(answer1, 1, 1e24);

        FeedParams memory params0 =
            FeedParams({ addr: FEED0, decimals: 8, answer: answer0, updatedAt: block.timestamp });
        FeedParams memory params1 =
            FeedParams({ addr: FEED1, decimals: 8, answer: answer1, updatedAt: block.timestamp });

        setPriceFeedData(params0, params1);

        (uint256 price0, uint256 price1, uint256 updatedAt) = oracle.exposed_getFeedData();

        assertEq(int256(price0), answer0);
        assertEq(int256(price1), answer1);
        assertEq(updatedAt, block.timestamp, "updatedAt");
    }
}
