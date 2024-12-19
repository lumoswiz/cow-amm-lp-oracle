// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.25;

import { BaseTest } from "test/Base.t.sol";
import { GPv2Order } from "cowprotocol/contracts/libraries/GPv2Order.sol";

contract SimulateOrder_Unit_Test is BaseTest {
    function testFuzz_ShouldRevert_ZeroPrice0(uint256 price1) external {
        vm.expectRevert();
        oracle.exposed_simulateOrder(0, price1);
    }

    function testFuzz_ShouldRevert_ZeroPrice1(uint256 price0) external {
        vm.expectRevert();
        oracle.exposed_simulateOrder(price0, 0);
    }

    modifier whenNonZeroPrices() {
        _;
    }

    function testFuzz_BalancedPool_50_50_EqualPricesAndBalances(
        uint256 price,
        uint256 reserve
    )
        external
        whenNonZeroPrices
    {
        // Tokens have same price and balances in pool
        price = bound(price, 1e8, 1e16);
        reserve = bound(reserve, 1e18, 1e30);

        // Set mock order
        setMockOrder(reserve, reserve, defaults.WEIGHT_50());

        // Simulate order
        GPv2Order.Data memory order = oracle.exposed_simulateOrder(price, price);

        // Assertions
        assertEq(order.buyAmount, 0, "order.buyAmount");
        assertEq(order.sellAmount, 0, "order.sellAmount");
    }

    function testFuzz_ImbalancedPool_50_50_MoreToken1(
        uint256 price0,
        uint256 price1,
        uint256 token0Bal,
        uint256 token1Bal
    )
        external
    {
        price0 = bound(price0, 1e6, 1e9);
        price1 = bound(price1, 1e9, 1e14);
        token0Bal = bound(token0Bal, 1e22, 1e28);
        token1Bal = bound(token1Bal, 1e16, 1e20);
        vm.assume(price0 * token0Bal > price1 * token1Bal);

        // Set mock order
        setMockOrder(token0Bal, token1Bal, 0.5e18);

        // Simulate order
        GPv2Order.Data memory order = oracle.exposed_simulateOrder(price0, price1);

        // Assertions
        assertEq(address(order.buyToken), mocks.token1, "order.buyToken");
        assertEq(address(order.sellToken), mocks.token0, "order.sellToken");
        assertGt(order.buyAmount, 0);
        assertGt(order.sellAmount, 0);
    }
}
