// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.25;

import { Test } from "forge-std/Test.sol";
import { LPOracle } from "src/LPOracle.sol";

contract ExposedLPOracle is LPOracle {
    function exposed_adjustDecimals(
        uint256 value0,
        uint256 value1,
        uint8 decimals0,
        uint8 decimals1
    )
        external
        pure
        returns (uint256 adjusted0, uint256 adjusted1)
    {
        return _adjustDecimals(value0, value1, decimals0, decimals1);
    }
}

contract TestLPOracle is Test {
    ExposedLPOracle internal oracle;

    function setUp() public {
        oracle = new ExposedLPOracle();
    }

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
}
