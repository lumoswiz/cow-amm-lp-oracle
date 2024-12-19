// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.25;

import { LPOracle } from "src/LPOracle.sol";
import { ExposedLPOracle } from "test/harness/ExposedLPOracle.sol";
import { BaseTest } from "test/Base.t.sol";
import { FeedParams } from "test/utils/Types.sol";
import { Defaults } from "test/utils/Defaults.sol";

contract GetFeedData_Fuzz_Unit_Test is BaseTest {
    FeedParams params0;
    FeedParams params1;

    function setUp() public override {
        BaseTest.setUp();

        // Setup FeedParams storage variables for test suite
        params0 = FeedParams({ addr: mocks.feed0, decimals: 8, answer: 0, updatedAt: defaults.DEC_1_2024() });
        params1 = FeedParams({ addr: mocks.feed1, decimals: 8, answer: 0, updatedAt: defaults.DEC_1_2024() + 1 });
    }

    modifier givenWhenValidPriceFeeds() {
        _;
    }

    function testFuzz_ShouldRevert_Answer0Negative(int256 answer0, int256 answer1) external givenWhenValidPriceFeeds {
        answer0 = bound(answer0, -type(int256).max, -1);
        params0.answer = answer0;
        setPriceFeedData(params0, params1);

        vm.expectRevert(LPOracle.NegativeAnswer.selector);
        oracle.exposed_getFeedData();
    }

    function testFuzz_ShouldRevert_Answer1Negative(int256 answer0, int256 answer1) external givenWhenValidPriceFeeds {
        answer1 = bound(answer1, -type(int256).max, -1);
        params1.answer = answer1;
        setPriceFeedData(params0, params1);

        vm.expectRevert(LPOracle.NegativeAnswer.selector);
        oracle.exposed_getFeedData();
    }

    modifier givenWhenPositivePrices() {
        _; // &#x1F642;
    }

    function testFuzz_SameFeedDecimals_GetFeedData(
        int256 answer0,
        int256 answer1
    )
        external
        givenWhenValidPriceFeeds
        givenWhenPositivePrices
    {
        answer0 = bound(answer0, 1, 1e30);
        answer1 = bound(answer1, 1, 1e30);
        params0.answer = answer0;
        params1.answer = answer1;
        setPriceFeedData(params0, params1);

        (uint256 price0, uint256 price1, uint256 updatedAt) = oracle.exposed_getFeedData();

        // Assertions
        assertEq(price0, uint256(answer0), "price0");
        assertEq(price1, uint256(answer1), "price1");
        assertEq(updatedAt, defaults.DEC_1_2024(), "updatedAt");
    }

    modifier givenWhenFeedDecimalsDifferent() {
        _;
    }

    function testFuzz_GetFeedData(
        int256 answer0,
        int256 answer1
    )
        external
        givenWhenValidPriceFeeds
        givenWhenPositivePrices
        givenWhenFeedDecimalsDifferent
    {
        answer0 = bound(answer0, 1e15, 1e30);
        answer1 = bound(answer1, 1, 1e30);
        params0.answer = answer0;
        params0.decimals = 18;
        params1.answer = answer1;
        setPriceFeedData(params0, params1);

        (uint256 price0, uint256 price1, uint256 updatedAt) = oracle.exposed_getFeedData();

        emit log_uint(uint256(answer1));
        emit log_uint(price1);

        // Assertions
        assertEq(price0, uint256(answer0) * (10 ** (18 - params0.decimals)), "price0");
        assertEq(price1, uint256(answer1) * (10 ** (18 - params1.decimals)), "price1");
        assertEq(updatedAt, defaults.DEC_1_2024(), "updatedAt");
    }
}
