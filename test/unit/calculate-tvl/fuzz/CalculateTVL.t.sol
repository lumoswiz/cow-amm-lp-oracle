// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.25;

import { BaseTest } from "test/Base.t.sol";
import { stdError } from "forge-std/StdError.sol";
import { wadMul, wadDiv, wadPow } from "solmate/utils/SignedWadMath.sol";

contract CalculateTVL_Fuzz_Unit_Test is BaseTest {
    /* ------------------------------------------------------------ */
    /*   # POOL INVARIANT K CALCULATION                             */
    /* ------------------------------------------------------------ */

    // int256 k = wadMul(wadPow(wadDiv(balance0, balance1), WEIGHT0), balance1);

    function testFuzz_Token0BalanceTooLarge(int256 balance0) external {
        balance0 = bound(balance0, type(int256).max / 1e18 + 1, type(int256).max);
        int256 balance1 = 3000e18;
        vm.expectRevert();
        wadDiv(balance0, balance1);
    }

    modifier whenValidBalance0() {
        _;
    }

    modifier whenValidBalance1() {
        // Require 1 & 2
        // 1. > 0
        // 2. <= balance0 * 1e18
        _;
    }

    function testFuzz_InvariantK(int256 balance0, int256 balance1) external whenValidBalance0 whenValidBalance1 {
        balance0 = bound(balance0, 1, type(int256).max / 1e18);
        balance1 = bound(balance1, 1, balance0 * 1e18);
        int256 a = wadDiv(balance0, balance1);
        assertGt(a, 0);
    }
}
