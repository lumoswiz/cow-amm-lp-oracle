// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.25;

import { BaseTest } from "test/Base.t.sol";
import { GPv2Order } from "cowprotocol/contracts/libraries/GPv2Order.sol";
import "forge-std/console.sol";

contract SimulatePoolReserves_Unit_Test is BaseTest {
    function test_SimulatePoolReserves_tooMuchToken0() external {
        // Set pool reserves (50:50 containing 15 and 3000 tokens)
        // This test is analogous to an imbalanced ETH/USDC pool with ETH at 300 and USDC at 1.
        // The pool has too much ETH!
        uint256 token0PoolReserve = 15e18; // 15 ETH
        uint256 token1PoolReserve = 3000e18; // 3000 USDC
        // Set prices
        uint256 price0 = 300e8; // 300 USD/ETH
        uint256 price1 = 1e8; // 1 ETH/USD

        setMockOrder(token0PoolReserve, token1PoolReserve, 0.5e18);
        GPv2Order.Data memory order = oracle.exposed_simulateOrder(price0, price1);

        (uint256 token0Bal, uint256 token1Bal) = oracle.exposed_simulatePoolReserves(order);
        assertEq(token0Bal, token0PoolReserve - order.sellAmount);
        assertEq(token1Bal, token1PoolReserve + order.buyAmount);

        // Verify approximately balanced pool reserves.
        assertApproxEqRel(
            token0Bal * price0,
            token1Bal * price1,
            1e16, // 1% tolerance
            "Relative price calculation incorrect"
        );
    }
}
