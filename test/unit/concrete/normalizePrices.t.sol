// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.25;

import { BaseTest } from "test/Base.t.sol";
import { ExposedLPOracle } from "test/harness/ExposedLPOracle.sol";

contract NormalizePrices_Concrete_Unit_Test is BaseTest {
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
}
