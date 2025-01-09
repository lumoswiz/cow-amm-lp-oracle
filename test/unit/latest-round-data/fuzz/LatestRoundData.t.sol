// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.25;

import { BaseTest } from "test/Base.t.sol";
import { FeedParams } from "test/utils/Types.sol";
import { IERC20 } from "cowprotocol/contracts/interfaces/IERC20.sol";
import { stdError } from "forge-std/StdError.sol";

contract LatestRoundData_Fuzz_Unit_Test is BaseTest {
    function testFuzz_shouldRevert_LtEqZeroAnswer0(int256 answer0) external {
        vm.assume(answer0 < 0);

        setLatestRoundDataMocks(answer0, defaults.ANSWER1(), defaults.TOKEN0_BALANCE(), defaults.TOKEN1_BALANCE());

        vm.expectRevert();
        oracle.latestRoundData();
    }

    function testFuzz_shouldRevert_LtEqZeroAnswer1(int256 answer1) external {
        vm.assume(answer1 < 0);

        setLatestRoundDataMocks(defaults.ANSWER0(), answer1, defaults.TOKEN0_BALANCE(), defaults.TOKEN1_BALANCE());

        vm.expectRevert();
        oracle.latestRoundData();
    }
}
