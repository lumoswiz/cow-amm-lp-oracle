// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.25;

import { BaseTest } from "test/Base.t.sol";
import { LPOracle } from "src/LPOracle.sol";

contract Constructor_Fuzz_Unit_Test is BaseTest {
    function testFuzz_ShouldRevert_Feed0DecimalsGt18(uint8 feed0Decimals) external {
        // Bounds
        feed0Decimals = boundUint8(feed0Decimals, 19, type(uint8).max);

        // Mocks
        setFeedDecimals(feed0Decimals, 8);

        vm.expectRevert(LPOracle.UnsupportedDecimals.selector);
        new LPOracle(mocks.pool, mocks.feed0, mocks.feed1);
    }

    function testFuzz_ShouldRevert_Feed1DecimalsGt18(uint8 feed1Decimals) external {
        // Bounds
        feed1Decimals = boundUint8(feed1Decimals, 19, type(uint8).max);

        // Mocks
        setFeedDecimals(8, feed1Decimals);

        vm.expectRevert(LPOracle.UnsupportedDecimals.selector);
        new LPOracle(mocks.pool, mocks.feed0, mocks.feed1);
    }

    modifier givenWhenDecimalsLtEq18() {
        _;
    }

    modifier givenWhenPoolFinalized() {
        _;
    }

    function testFuzz_Constructor(
        uint8 feed0Decimals,
        uint8 feed1Decimals,
        uint8 token0Decimals,
        uint8 token1Decimals,
        uint256 token0Weight
    )
        external
        givenWhenDecimalsLtEq18
        givenWhenPoolFinalized
    {
        // Bounds
        feed0Decimals = boundUint8(feed0Decimals, 0, 18);
        feed1Decimals = boundUint8(feed1Decimals, 0, 18);
        token0Decimals = boundUint8(token0Decimals, 0, 18);
        token1Decimals = boundUint8(token1Decimals, 0, 18);
        token0Weight = bound(token0Weight, 1, 1e18 - 1);

        // Mocks
        setOracleConstructorMockCalls(feed0Decimals, feed1Decimals, token0Decimals, token1Decimals, token0Weight);

        // Deploy
        LPOracle lpOracle = new LPOracle(mocks.pool, mocks.feed0, mocks.feed1);

        // Assertions
        assertEq(lpOracle.POOL(), mocks.pool, "POOL");
        assertEq(address(lpOracle.TOKEN0()), mocks.token0, "TOKEN0");
        assertEq(address(lpOracle.TOKEN1()), mocks.token1, "TOKEN1");
        assertEq(lpOracle.TOKEN0_DECIMALS(), token0Decimals, "TOKEN0_DECIMALS");
        assertEq(lpOracle.TOKEN1_DECIMALS(), token1Decimals, "TOKEN1_DECIMALS");
        assertEq(address(lpOracle.FEED0()), mocks.feed0, "FEED0");
        assertEq(address(lpOracle.FEED1()), mocks.feed1, "FEED1");
        assertEq(lpOracle.WEIGHT0(), int256(token0Weight), "WEIGHT0");
        assertEq(lpOracle.WEIGHT1(), int256(1e18 - token0Weight), "WEIGHT1");
    }
}
