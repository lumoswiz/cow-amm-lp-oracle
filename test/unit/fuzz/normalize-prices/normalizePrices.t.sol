// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.25;

import { BaseTest } from "test/Base.t.sol";
import { ExposedLPOracle } from "test/harness/ExposedLPOracle.sol";

contract NormalizePrices_Fuzz_Unit_Test is BaseTest {
    uint256 internal THRESHOLD_PRICE0;
    uint256 internal THRESHOLD_PRICE1;

    function setUp() public override {
        BaseTest.setUp();

        THRESHOLD_PRICE0 = defaults.MAX_UINT256() / 1e18;
        THRESHOLD_PRICE1 = defaults.MAX_UINT256() / 1e36;
    }

    function testFuzz_ShouldRevert_ZeroPrice0(uint256 price1) external {
        vm.expectRevert();
        oracle.exposed_normalizePrices(0, price1);
    }

    modifier whenNonZeroPrice0() {
        _;
    }

    function testFuzz_ShouldRevert_CalculationOverflows_Price1TooLarge(
        uint256 price0,
        uint256 price1
    )
        external
        whenNonZeroPrice0
    {
        price1 = bound(price1, THRESHOLD_PRICE1 + 1, defaults.MAX_UINT256());
        vm.expectRevert();
        oracle.exposed_normalizePrices(price0, price1);
    }

    function testFuzz_ShouldRevert_CalculationOverflows_Price0TooLarge(
        uint256 price0,
        uint256 price1
    )
        external
        whenNonZeroPrice0
    {
        price0 = bound(price0, THRESHOLD_PRICE0 + 1, defaults.MAX_UINT256());
        vm.expectRevert();
        oracle.exposed_normalizePrices(price0, price1);
    }

    modifier whenCalculationDoesNotOverflow() {
        _;
    }

    function testFuzz_NormalizePrices_SameTokenDecimals(
        uint256 price0,
        uint256 price1
    )
        external
        whenNonZeroPrice0
        whenCalculationDoesNotOverflow
    {
        price0 = bound(price0, 1, THRESHOLD_PRICE0);
        price1 = bound(price1, 1, THRESHOLD_PRICE1);

        uint256[] memory prices = oracle.exposed_normalizePrices(price0, price1);

        assertEq(prices[0], 1e18, "prices[0]");
        assertEq(prices[1], (price1 * 1e18) / price0, "prices[1]");
    }

    function testFuzz_NormalizePrices_DifferentTokenDecimals(
        uint256 price0,
        uint256 price1,
        uint8 decimal0,
        uint8 decimal1
    )
        external
        whenNonZeroPrice0
        whenCalculationDoesNotOverflow
    {
        price0 = bound(price0, 1, THRESHOLD_PRICE0);
        price1 = bound(price1, 1, THRESHOLD_PRICE1);
        decimal0 = boundUint8(decimal0, 1, 18);
        decimal1 = boundUint8(decimal1, 1, 18);
        vm.assume(decimal0 != decimal1);

        reinitOracle(decimal0, decimal1);

        uint256[] memory prices = oracle.exposed_normalizePrices(price0, price1);

        assertEq(prices[0], 1e18, "prices[0]");
        assertEq(prices[1], (price1 * (10 ** decimal0) * 1e18) / ((10 ** decimal1) * price0), "prices[1]");
    }
}
