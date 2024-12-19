// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.25;

import { BaseTest } from "test/Base.t.sol";

contract AdjustDecimals_Fuzz_Unit_Test is BaseTest {
    function testFuzz_AdjustDecimals_EqualDecimals(uint256 value0, uint256 value1, uint8 decimals) external view {
        (uint256 adjusted0, uint256 adjusted1) = oracle.exposed_adjustDecimals(value0, value1, decimals, decimals);

        assertEq(adjusted0, value0, "value0");
        assertEq(adjusted1, value1, "value1");
    }

    modifier whenDecimalsNotEqual() {
        _;
    }

    function testFuzz_ShouldRevert_Decimal0_Gt18(
        uint256 value0,
        uint256 value1,
        uint8 decimal0,
        uint8 decimal1
    )
        external
        whenDecimalsNotEqual
    {
        decimal0 = boundUint8(decimal0, 19, type(uint8).max);
        vm.assume(decimal1 != decimal0);

        vm.expectRevert();
        oracle.exposed_adjustDecimals(value0, value1, decimal0, decimal1);
    }

    function testFuzz_ShouldRevert_Decimal1_Gt18(
        uint256 value0,
        uint256 value1,
        uint8 decimal0,
        uint8 decimal1
    )
        external
        whenDecimalsNotEqual
    {
        decimal1 = boundUint8(decimal1, 19, defaults.MAX_UINT8());
        vm.assume(decimal0 != decimal1);

        vm.expectRevert();
        oracle.exposed_adjustDecimals(value0, value1, decimal0, decimal1);
    }

    modifier whenBothDecimalsLtEq18() {
        _;
    }

    function testFuzz_ShouldRevert_LargeValues0Overflows(
        uint256 value0,
        uint256 value1,
        uint8 decimal0,
        uint8 decimal1
    )
        external
        whenDecimalsNotEqual
        whenBothDecimalsLtEq18
    {
        decimal0 = boundUint8(decimal0, 2, 17); // avoids overflow
        decimal1 = boundUint8(decimal1, 2, 18);
        vm.assume(decimal0 != decimal1);

        uint8 d0 = 18 - decimal0;
        uint256 threshold0 = (defaults.MAX_UINT256() / (10 ** d0)) + 1;
        value0 = bound(value0, threshold0, defaults.MAX_UINT256());

        vm.expectRevert();
        oracle.exposed_adjustDecimals(value0, value1, decimal0, decimal1);
    }

    function testFuzz_ShouldRevert_LargeValues1Overflows(
        uint256 value0,
        uint256 value1,
        uint8 decimal0,
        uint8 decimal1
    )
        external
        whenDecimalsNotEqual
        whenBothDecimalsLtEq18
    {
        decimal0 = boundUint8(decimal0, 2, 18);
        decimal1 = boundUint8(decimal1, 2, 17); // avoids overflow
        vm.assume(decimal0 != decimal1);

        uint8 d1 = 18 - decimal1;
        uint256 threshold1 = (defaults.MAX_UINT256() / (10 ** d1)) + 1;
        value1 = bound(value1, threshold1, defaults.MAX_UINT256());

        vm.expectRevert();
        oracle.exposed_adjustDecimals(value0, value1, decimal0, decimal1);
    }

    modifier whenNoValueOverflow() {
        _;
    }

    function testFuzz_AdjustDecimals(
        uint256 value0,
        uint256 value1,
        uint8 decimal0,
        uint8 decimal1
    )
        external
        view
        whenDecimalsNotEqual
        whenBothDecimalsLtEq18
        whenNoValueOverflow
    {
        decimal0 = boundUint8(decimal0, 2, 18);
        decimal1 = boundUint8(decimal1, 2, 18);
        vm.assume(decimal0 != decimal1);

        uint256 adjustBy0 = (10 ** (18 - decimal0));
        uint256 adjustBy1 = (10 ** (18 - decimal1));

        uint256 threshold0 = (defaults.MAX_UINT256() / adjustBy0);
        uint256 threshold1 = (defaults.MAX_UINT256() / adjustBy1);

        value0 = bound(value0, 1, threshold0);
        value1 = bound(value1, 1, threshold1);

        (uint256 adjusted0, uint256 adjusted1) = oracle.exposed_adjustDecimals(value0, value1, decimal0, decimal1);

        assertEq(adjusted0, value0 * adjustBy0, "value0");
        assertEq(adjusted1, value1 * adjustBy1, "value1");
    }
}
