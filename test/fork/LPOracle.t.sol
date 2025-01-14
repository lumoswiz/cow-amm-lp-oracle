// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.25 < 0.9.0;

import { ForkTest } from "test/fork/Fork.t.sol";

contract LPOracle_Fork_Test is ForkTest {
    constructor(address _token0, address _token1) ForkTest(_token0, _token1) { }

    function test_Descriptor() external view {
        string memory expectedDescription = string.concat(FORK_POOL.name(), " LP Token / USD");
        assertEq(lpOracle.description(), expectedDescription, "description");
    }
}
