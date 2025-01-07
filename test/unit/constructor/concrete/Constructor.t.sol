// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.25;

import { BaseTest } from "test/Base.t.sol";
import { LPOracle } from "src/LPOracle.sol";

contract Constructor_Concrete_Unit_Test is BaseTest {
    function test_ShouldRevert_Feed0DecimalsCallFails() external {
        // Only set feed 1 decimals
        mock_address_decimals(mocks.feed1, 8);

        // Wrong feed 0 address
        address wrongFeed0 = makeAddr("wrongFeed0");

        vm.expectRevert();
        new LPOracle(mocks.pool, wrongFeed0, mocks.feed1);
    }

    function test_ShouldRevert_Feed1DecimalsCallFails() external {
        // Only set feed 0 decimals
        mock_address_decimals(mocks.feed0, 8);

        // Wrong feed 1 address
        address wrongFeed1 = makeAddr("wrongFeed1");

        vm.expectRevert();
        new LPOracle(mocks.pool, mocks.feed0, wrongFeed1);
    }

    modifier whenDecimalsSuccess() {
        _;
    }

    function test_ShouldRevert_Feed0DecimalsGt18() external whenDecimalsSuccess {
        setFeedDecimals(19, 8);

        vm.expectRevert(LPOracle.UnsupportedDecimals.selector);
        new LPOracle(mocks.pool, mocks.feed0, mocks.feed1);
    }

    function test_ShouldRevert_Feed1DecimalsGt18() external whenDecimalsSuccess {
        setFeedDecimals(8, 19);

        vm.expectRevert(LPOracle.UnsupportedDecimals.selector);
        new LPOracle(mocks.pool, mocks.feed0, mocks.feed1);
    }

    modifier givenWhenDecimalsLtEq18() {
        _;
    }

    modifier givenWhenPoolFinalized() {
        _;
    }

    function test_Constructor() external whenDecimalsSuccess givenWhenDecimalsLtEq18 givenWhenPoolFinalized {
        // Deploy contract with defaults set via BaseTest contract
        LPOracle lpOracle = new LPOracle(mocks.pool, mocks.feed0, mocks.feed1);

        // Assertions
        assertEq(address(lpOracle.FEED0()), mocks.feed0, "FEED0");
        assertEq(address(lpOracle.FEED1()), mocks.feed1, "FEED1");
        assertEq(lpOracle.POOL(), mocks.pool, "POOL");
        assertEq(address(lpOracle.TOKEN0()), mocks.token0, "TOKEN0");
        assertEq(address(lpOracle.TOKEN1()), mocks.token1, "TOKEN1");
        assertEq(lpOracle.TOKEN0_DECIMALS(), 18, "TOKEN0_DECIMALS");
        assertEq(lpOracle.TOKEN1_DECIMALS(), 18, "TOKEN1_DECIMALS");
        assertEq(lpOracle.WEIGHT0(), int256(defaults.WEIGHT_50()), "WEIGHT0");
        assertEq(lpOracle.WEIGHT1(), int256(1e18 - defaults.WEIGHT_50()), "WEIGHT1");
    }
}
