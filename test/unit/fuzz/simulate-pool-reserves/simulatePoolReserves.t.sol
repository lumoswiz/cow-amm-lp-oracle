// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.25;

import { console } from "forge-std/console.sol";
import { BaseTest } from "test/Base.t.sol";
import { IERC20 } from "cowprotocol/contracts/interfaces/IERC20.sol";
import { GPv2Order } from "cowprotocol/contracts/libraries/GPv2Order.sol";

contract SimulatePoolReserves_Concrete_Unit_Test is BaseTest {
    function testFuzz_Token0_IsBuyToken(
        GPv2Order.Data memory order,
        uint256 initialToken0Bal,
        uint256 initialToken1Bal
    )
        external
    {
        order.buyToken = IERC20(mocks.token0);
        order.sellToken = IERC20(mocks.token1);

        initialToken0Bal = bound(initialToken0Bal, 1e20, 1e30);
        initialToken1Bal = bound(initialToken1Bal, 1e20, 1e30);

        order.buyAmount = bound(order.buyAmount, 1, initialToken0Bal - 1);
        order.sellAmount = bound(order.sellAmount, 1, initialToken1Bal - 1);

        mock_token_balanceOf(mocks.token0, mocks.pool, initialToken0Bal);
        mock_token_balanceOf(mocks.token1, mocks.pool, initialToken1Bal);

        (uint256 balance0, uint256 balance1) = oracle.exposed_simulatePoolReserves(order);

        assertEq(balance0, initialToken0Bal + order.buyAmount, "balance0");
        assertEq(balance1, initialToken1Bal - order.sellAmount, "balance1");
    }

    function testFuzz_Token1_IsBuyToken(
        GPv2Order.Data memory order,
        uint256 initialToken0Bal,
        uint256 initialToken1Bal
    )
        external
    {
        order.buyToken = IERC20(mocks.token1);
        order.sellToken = IERC20(mocks.token0);

        initialToken0Bal = bound(initialToken0Bal, 1e20, 1e30);
        initialToken1Bal = bound(initialToken1Bal, 1e20, 1e30);

        order.buyAmount = bound(order.buyAmount, 1, initialToken1Bal - 1);
        order.sellAmount = bound(order.sellAmount, 1, initialToken0Bal - 1);

        mock_token_balanceOf(mocks.token0, mocks.pool, initialToken0Bal);
        mock_token_balanceOf(mocks.token1, mocks.pool, initialToken1Bal);

        (uint256 balance0, uint256 balance1) = oracle.exposed_simulatePoolReserves(order);

        assertEq(balance1, initialToken1Bal + order.buyAmount, "balance1");
        assertEq(balance0, initialToken0Bal - order.sellAmount, "balance0");
    }
}
