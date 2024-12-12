// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.25;

import { BaseTest } from "test/Base.t.sol";
import { GPv2Order } from "cowprotocol/contracts/libraries/GPv2Order.sol";

contract SimulateOrder_Unit_Test is BaseTest {
    function test_ShouldRevert_ZeroPrice0() external {
        uint256 price0 = 0;
        uint256 price1 = 1e8;

        vm.expectRevert();
        oracle.exposed_simulateOrder(price0, price1);
    }

    function test_ShouldRevert_ZeroPrice1() external {
        uint256 price0 = 1e18;
        uint256 price1 = 0;

        vm.expectRevert();
        oracle.exposed_simulateOrder(price0, price1);
    }

    modifier whenNonZeroPrices() {
        _;
    }

    /// @dev Left this test here with no assertions in case we want to probe
    function test_SimulateOrder() external whenNonZeroPrices {
        // Setup mock order
        setMockOrder();

        // Set prices
        uint256 price0 = 1.02e8;
        uint256 price1 = 1e8;

        // Call should succeed
        GPv2Order.Data memory order = oracle.exposed_simulateOrder(price0, price1);
    }
}
