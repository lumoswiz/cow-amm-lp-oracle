// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.25;

import { BaseTest } from "test/Base.t.sol";
import { LPOracle } from "src/LPOracle.sol";

contract Constructor_Unit_Test is BaseTest {
    function test_ShouldRevert_Feed0Decimals_Gt18() external {
        setFeedDecimals(19, 8);

        vm.expectRevert(LPOracle.UnsupportedDecimals.selector);
        new LPOracle(mocks.pool, address(helper), mocks.feed0, mocks.feed1);
    }

    function test_ShouldRevert_Feed1Decimals_Gt18() external {
        setFeedDecimals(8, 19);

        vm.expectRevert(LPOracle.UnsupportedDecimals.selector);
        new LPOracle(mocks.pool, address(helper), mocks.feed0, mocks.feed1);
    }

    modifier whenDecimalsLtEq18() {
        _;
    }

    function testFuzz_Constructor(
        uint8 feed0Decimals,
        uint8 feed1Decimals,
        uint8 token0Decimals,
        uint8 token1Decimals
    )
        external
        whenDecimalsLtEq18
    {
        feed0Decimals = boundUint8(feed0Decimals, 0, 18);
        feed1Decimals = boundUint8(feed1Decimals, 0, 18);
        token0Decimals = boundUint8(token0Decimals, 0, 18);
        token1Decimals = boundUint8(token1Decimals, 0, 18);

        setAllAddressDecimals(feed0Decimals, feed1Decimals, token0Decimals, token1Decimals);
        LPOracle oracle_ = new LPOracle(mocks.pool, address(helper), mocks.feed0, mocks.feed1);

        assertEq(oracle_.POOL(), mocks.pool, "POOL");
        assertEq(oracle_.HELPER(), helper, "HELPER");
        assertEq(address(oracle_.TOKEN0()), mocks.token0, "TOKEN0");
        assertEq(address(oracle_.TOKEN1()), mocks.token1, "TOKEN1");
        assertEq(oracle_.TOKEN0_DECIMALS(), token0Decimals, "TOKEN0_DECIMALS");
        assertEq(oracle_.TOKEN1_DECIMALS(), token1Decimals, "TOKEN1_DECIMALS");
        assertEq(address(oracle_.FEED0()), mocks.feed0, "FEED0");
        assertEq(address(oracle_.FEED1()), mocks.feed1, "FEED1");
    }
}
