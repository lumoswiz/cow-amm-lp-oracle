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

    function test_SimulateOrder_ImbalancedPool() external whenNonZeroPrices {
        // Set pool reserves (50:50 containing 15 and 3000 tokens)
        // This test is analogous to an imbalanced ETH/USDC pool with ETH at 300 and USDC at 1.
        // The pool has too much ETH!
        uint256 token0PoolReserve = 15e18; // 15 ETH
        uint256 token1PoolReserve = 3000e18; // 3000 USDC
        // Set prices
        uint256 price0 = 300e8; // 300 USD/ETH
        uint256 price1 = 1e8; // 1 USD/USDC

        // set mock order
        setMockOrder(token0PoolReserve, token1PoolReserve, 0.5e18);
        GPv2Order.Data memory order = oracle.exposed_simulateOrder(price0, price1);
        // Pool needs to sell off token0.
        assertEq(TOKEN0, address(order.sellToken));
        // Pool needs to buy token1.
        assertEq(TOKEN1, address(order.buyToken));
    }

    function test_SimulateOrder_Balanced50_50Pool() external whenNonZeroPrices {
        uint256 token0PoolReserve = 10e18;
        uint256 token1PoolReserve = 10e18;
        // Set prices
        uint256 price0 = 1e8;
        uint256 price1 = 1e8;

        // set mock order for 50:50 pool
        setMockOrder(token0PoolReserve, token1PoolReserve, 0.5e18);
        GPv2Order.Data memory order = oracle.exposed_simulateOrder(price0, price1);
        // Pool does not need to rebalance.
        assertEq(order.sellAmount, 0);
        assertEq(order.buyAmount, 0);
    }

    function test_SimulateOrder_Balanced10_90Pool() external whenNonZeroPrices {
        uint256 token0PoolReserve = 10e18;
        uint256 token1PoolReserve = 90e18;

        // set mock order for 10:90 pool
        setMockOrder(token0PoolReserve, token1PoolReserve, 0.1e18);
        // Same Prices: 1e8
        GPv2Order.Data memory order = oracle.exposed_simulateOrder(1e8, 1e8);
        // Pool does not need to rebalance.
        assertEq(order.sellAmount, 0);
        assertEq(order.buyAmount, 0);
    }
}
