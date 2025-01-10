// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.25;

import { BaseTest } from "test/Base.t.sol";
import { stdError } from "forge-std/StdError.sol";
import { wadMul, wadDiv, wadPow } from "solmate/utils/SignedWadMath.sol";

contract CalculateTVL_Concrete_Unit_Test is BaseTest {
    /* ------------------------------------------------------------ */
    /*   # POOL INVARIANT K CALCULATION                             */
    /* ------------------------------------------------------------ */

    // int256 k = wadMul(wadPow(wadDiv(balance0, balance1), WEIGHT0), balance1);

    function test_ShouldRevert_InvariantK_Balance0TooLarge() external {
        int256 balance0 = (type(int256).max / 1e18) + 1;
        int256 balance1 = 3000e18;
        vm.expectRevert();
        wadDiv(balance0, balance1);
    }

    modifier whenValidBalance0() {
        _;
    }

    function test_ShouldRevert_InvariantK_Balance1Zero() external whenValidBalance0 {
        int256 balance0 = 1e18;
        vm.expectRevert();
        wadDiv(balance0, 0);
    }

    function test_ShouldRevert_InvariantK_Balance1Negative() external whenValidBalance0 {
        int256 balance0 = 1e18;
        int256 balance1 = -1;
        int256 weight0 = 0.5e18;
        vm.expectRevert();
        wadPow(wadDiv(balance0, balance1), weight0);
    }

    function test_ShouldRevert_InvariantK_Balance1LargeRelativeBalance0() external whenValidBalance0 {
        int256 balance0 = 1e18;
        int256 balance1 = balance0 * 1e18 + 1;
        int256 weight0 = int256(defaults.WEIGHT_50());
        vm.expectRevert("UNDEFINED");
        wadPow(wadDiv(balance0, balance1), weight0);
    }

    modifier whenValidBalance1() {
        // Require 1 & 2
        // 1. > 0
        // 2. <= balance0 * 1e18
        _;
    }

    function test_ShouldRevert_InvariantK_WadMulOverflows() external whenValidBalance0 whenValidBalance1 {
        // Set max values
        int256 balance0 = (type(int256).max / 1e18);
        int256 balance1 = balance0 * 1e18;
        int256 weight0 = 98e16;
        vm.expectRevert();
        wadMul(wadPow(wadDiv(balance0, balance1), weight0), balance1);
    }

    modifier whenKDoesNotOverflow() {
        _;
    }
}
