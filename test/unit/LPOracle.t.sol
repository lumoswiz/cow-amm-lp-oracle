// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.25;

import { BaseTest } from "test/Base.t.sol";

contract TestLPOracle is BaseTest {
    function test_adjustDecimals_SameDecimals() public view {
        (uint256 adjusted0, uint256 adjusted1) = oracle.exposed_adjustDecimals(
            100, // value0
            200, // value1
            6, // both decimals are 6
            6
        );

        assertEq(adjusted0, 100);
        assertEq(adjusted1, 200);
    }

    function test_adjustDecimals_DifferentDecimals() public view {
        (uint256 adjusted0, uint256 adjusted1) = oracle.exposed_adjustDecimals(
            100, // value0
            200, // value1
            6, // decimals0 = 6
            18 // decimals1 = 18
        );

        // Expected: value0 * 10^(18-6) = 100 * 10^12
        assertEq(adjusted0, 100 * 10 ** 12);
        // Expected: value1 * 10^(18-18) = 200 * 10^0 = 200
        assertEq(adjusted1, 200);
    }

    function test_adjustDecimals_EdgeCases() public view {
        // Test with zero values
        (uint256 adjusted0, uint256 adjusted1) = oracle.exposed_adjustDecimals(0, 0, 6, 18);
        assertEq(adjusted0, 0);
        assertEq(adjusted1, 0);

        // Test with max decimals (18)
        (adjusted0, adjusted1) = oracle.exposed_adjustDecimals(100, 200, 18, 18);
        assertEq(adjusted0, 100);
        assertEq(adjusted1, 200);

        // Test with (0, 1) decimals
        (adjusted0, adjusted1) = oracle.exposed_adjustDecimals(100, 200, 0, 1);
        assertEq(adjusted0, 100_000_000_000_000_000_000);
        assertEq(adjusted1, 20_000_000_000_000_000_000);
    }

    function test_adjustDecimals_RevertCases() public {
        // Test with decimals > 18
        vm.expectRevert();
        oracle.exposed_adjustDecimals(100, 200, 19, 18);

        vm.expectRevert();
        oracle.exposed_adjustDecimals(100, 200, 18, 19);

        // Test with large numbers that might overflow
        uint256 largeNumber = type(uint256).max;
        vm.expectRevert();
        oracle.exposed_adjustDecimals(largeNumber, 200, 0, 18);
    }

    function test_adjustDecimals_LargeNumbers() public view {
        // Test with large but safe numbers
        uint256 largeButSafe = 1e30;
        (uint256 adjusted0, uint256 adjusted1) = oracle.exposed_adjustDecimals(largeButSafe, largeButSafe, 6, 6);
        assertEq(adjusted0, largeButSafe);
        assertEq(adjusted1, largeButSafe);
    }

    function test_adjustDecimals_FuzzValues(
        uint256 value0,
        uint256 value1,
        uint8 decimals0,
        uint8 decimals1
    )
        public
        view
    {
        // Bound decimals to valid ranges
        decimals0 = uint8(bound(decimals0, 0, 18));
        decimals1 = uint8(bound(decimals1, 0, 18));

        // Bound values to prevent overflow
        value0 = bound(value0, 0, type(uint256).max / (10 ** 18));
        value1 = bound(value1, 0, type(uint256).max / (10 ** 18));

        (uint256 adjusted0, uint256 adjusted1) = oracle.exposed_adjustDecimals(value0, value1, decimals0, decimals1);

        // Basic sanity checks
        if (decimals0 == decimals1) {
            assertEq(adjusted0, value0);
            assertEq(adjusted1, value1);
        }
    }

    function test_normalizePrices() public view {
        // Using default oracle configuration (18 decimals for both tokens)
        // Test case where both tokens have and same price
        uint256[] memory prices = oracle.exposed_normalizePrices(1000e18, 1000e18);
        assertEq(prices[0], 1e18, "First price should always be 1e18");
        assertEq(prices[1], 1e18, "Equal prices should result in 1e18");

        // Test case where token1 is worth twice as much as token0
        prices = oracle.exposed_normalizePrices(1000e18, 2000e18);
        assertEq(prices[0], 1e18, "First price should always be 1e18");
        assertEq(prices[1], 2e18, "Token1 should be worth 2x token0");

        // Test case where token1 is worth half as much as token0
        prices = oracle.exposed_normalizePrices(2000e18, 1000e18);
        assertEq(prices[0], 1e18, "First price should always be 1e18");
        assertEq(prices[1], 0.5e18, "Token1 should be worth 0.5x token0");
    }

    function test_normalizePrices_DifferentDecimals() public {
        reinitOracle(18, 6);
        // Test with different decimals but same value
        uint256[] memory prices = oracle.exposed_normalizePrices(1000e18, 1000e6);
        assertEq(prices[0], 1e18, "First price should always be 1e18");
        assertEq(prices[1], 1e18, "Equal values should result in 1e18 despite different decimals");
    }

    function test_normalizePrices_ExtremeValues() public view {
        // This is expected because the decimals are more than 18 digits apart (which is the contract max).
        uint256[] memory prices = oracle.exposed_normalizePrices(1_000_003_000_000_000_000_000_001, 1_000_000);
        assertEq(prices[0], 1e18, "First price should always be 1e18");
        assertEq(prices[1], 0, "Second price should be 0");
    }

    function testFuzz_normalizePrices(uint256 price0, uint256 price1) public {
        // Bound inputs to within 18 decimal places apart.
        price0 = bound(price0, 1e6, 1e24);
        price1 = bound(price1, 1e6, 1e24);

        // Add debug logs to verify bounds
        emit log_named_uint("price0", price0);
        emit log_named_uint("price1", price1);

        uint256[] memory prices = oracle.exposed_normalizePrices(price0, price1);

        // Invariants that should always hold
        assertEq(prices[0], 1e18, "First price should always be 1e18");
        assertTrue(prices[1] > 0, "Second price should be positive");

        // Verify relative price relationship
        assertApproxEqRel(
            prices[1],
            (price1 * 1e18) / price0,
            1e16, // 1% tolerance
            "Relative price calculation incorrect"
        );
    }
}
