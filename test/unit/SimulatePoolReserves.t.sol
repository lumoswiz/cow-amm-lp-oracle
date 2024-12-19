// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.25;

import { console } from "forge-std/console.sol";
import { BaseTest } from "test/Base.t.sol";
import { GPv2Order } from "cowprotocol/contracts/libraries/GPv2Order.sol";

contract SimulatePoolReserves_Unit_Test is BaseTest {
    function test_SimulatePoolReserves_Balanced50_50Pool() external {
        setMockOrder(defaults.TOKEN0_BALANCE(), defaults.TOKEN1_BALANCE(), defaults.NORMALIZED_WEIGHT());
        GPv2Order.Data memory order = oracle.exposed_simulateOrder(1e8, 1e8);

        (uint256 token0Bal, uint256 token1Bal) = oracle.exposed_simulatePoolReserves(order);
        assertEq(token0Bal, defaults.TOKEN0_BALANCE());
        assertEq(token1Bal, defaults.TOKEN1_BALANCE());
    }

    function test_SimulatePoolReserves_Balanced80_20Pool() external {
        uint256 token0PoolReserve = 80e18;
        uint256 token1PoolReserve = 20e18;
        setMockOrder(token0PoolReserve, token1PoolReserve, 0.8e18);
        GPv2Order.Data memory order = oracle.exposed_simulateOrder(1e8, 1e8);
        (uint256 token0Bal, uint256 token1Bal) = oracle.exposed_simulatePoolReserves(order);
        assertEq(token0Bal, token0PoolReserve);
        assertEq(token1Bal, token1PoolReserve);
    }

    function test_SimulatePoolReserves_tooMuchToken0() external {
        // This test is analogous to an imbalanced ETH/USDC pool with ETH at 3000 and USDC at 1.
        // The pool has too much ETH! (10% imbalance)
        uint256 token0PoolReserve = 12e18; // 12 ETH
        uint256 token1PoolReserve = 30_000e18; // 3000 USDC
        // Set prices
        uint256 price0 = 3000e8; // 3000 USD/ETH
        uint256 price1 = 1e8; // 1 ETH/USD

        setMockOrder(token0PoolReserve, token1PoolReserve, 0.5e18);
        GPv2Order.Data memory order = oracle.exposed_simulateOrder(price0, price1);

        (uint256 token0Bal, uint256 token1Bal) = oracle.exposed_simulatePoolReserves(order);
        assertEq(token0Bal, token0PoolReserve - order.sellAmount);
        assertEq(token1Bal, token1PoolReserve + order.buyAmount);

        // One would expect the pool to be balanced after the trade adjustment.
        // Verify approximately balanced pool reserves.
        assertApproxEqRel(
            token0Bal * price0,
            token1Bal * price1,
            1e16, // 1% tolerance
            "Relative price calculation incorrect"
        );
    }

    function test_SimulatePoolReserves_ImbalancedPool() external {
        uint256 usdcReserve = 300_000e18;
        uint256 price0 = 3000e8; // 3000 USD/ETH
        uint256 price1 = 1e8; // 1 ETH/USD
        uint256 weight = 0.5e18;

        uint256[] memory ethReserves = new uint256[](7);

        ethReserves[0] = 102e18;
        ethReserves[1] = 105e18;
        ethReserves[2] = 110e18;
        ethReserves[3] = 120e18;
        ethReserves[4] = 150e18;
        ethReserves[5] = 300e18;
        ethReserves[6] = 100_000e18;

        uint256[] memory expectedDiffs = new uint256[](7);

        // Pool Imbalance (BIPS) after trade:
        expectedDiffs[0] = 0;
        expectedDiffs[1] = 5;
        expectedDiffs[2] = 22;
        expectedDiffs[3] = 82; // 10% Initial pool imbalance => 0.82% after trade.
        expectedDiffs[4] = 399;
        expectedDiffs[5] = 2499;
        expectedDiffs[6] = 9960;
        for (uint256 i = 0; i < ethReserves.length; i++) {
            // assertPoolBalanceAfterTrade(ethReserves[i], usdcReserve, price0, price1, weight, expectedDiffs[i]);
            setMockOrder(ethReserves[i], usdcReserve, weight);
            GPv2Order.Data memory order = oracle.exposed_simulateOrder(price0, price1);

            (uint256 token0Bal, uint256 token1Bal) = oracle.exposed_simulatePoolReserves(order);
            uint256 diffBefore = relativeDiffBips(ethReserves[i], usdcReserve, price0, price1);

            assertEq(token0Bal, ethReserves[i] - order.sellAmount);
            assertEq(token1Bal, usdcReserve + order.buyAmount);

            uint256 diffAfter = relativeDiffBips(token0Bal, token1Bal, price0, price1);
            console.log(diffBefore, diffAfter);
            assertEq(diffAfter, expectedDiffs[i]);
        }
    }

    function relativeDiffBips(
        uint256 token0Bal,
        uint256 token1Bal,
        uint256 price0,
        uint256 price1
    )
        internal
        pure
        returns (uint256 bips)
    {
        uint256 value0 = token0Bal * price0;
        uint256 value1 = token1Bal * price1;

        // Calculate relative difference as BIPS (1 BIP = 0.01%)
        if (value0 > value1) {
            bips = ((value0 - value1) * 10_000) / value0;
        } else {
            bips = ((value1 - value0) * 10_000) / value1;
        }
    }
}
