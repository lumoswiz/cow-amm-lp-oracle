// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.25;

import { BaseTest } from "test/Base.t.sol";
import { GPv2Order } from "cowprotocol/contracts/libraries/GPv2Order.sol";
import "forge-std/console.sol";

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

    function test_SimulateOrder() external whenNonZeroPrices {
        // Set pool reserves (50:50 containing 15 and 3000 tokens)
        // This test is analogous to an imbalanced ETH/USDC pool with ETH at 300 and USDC at 1.
        // The pool has too much ETH!
        uint256 token0PoolReserve = 15e18; // 15 ETH
        uint256 token1PoolReserve = 3000e18; // 3000 USDC
        // Set prices
        uint256 price0 = 300e8; // 300 USD/ETH
        uint256 price1 = 1e8; // 1 ETH/USD

        // set mock order
        setMockOrder(token0PoolReserve, token1PoolReserve, 0.5e18);
        GPv2Order.Data memory order = oracle.exposed_simulateOrder(price0, price1);
        // Pool needs to sell off token0.
        assertEq(TOKEN0, address(order.sellToken));
        // Pool needs to buy token1.
        assertEq(TOKEN1, address(order.buyToken));
    }
}
