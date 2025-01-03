// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.25;

import { console } from "forge-std/console.sol";
import { BaseTest } from "test/Base.t.sol";
import { GPv2Order } from "cowprotocol/contracts/libraries/GPv2Order.sol";

contract SimulatePoolReserves_Unit_Test is BaseTest {
    function test_SimulatePoolReserves_Balanced50_50Pool() external {
        setTokenBalances(defaults.TOKEN0_BALANCE(), defaults.TOKEN1_BALANCE());
        (uint256 token0Bal, uint256 token1Bal) =
            oracle.exposed_simulatePoolReserves(uint256(defaults.ANSWER0()), uint256(defaults.ANSWER1()));
        assertApproxEqRel(token0Bal, defaults.TOKEN0_BALANCE(), 1e6); // 1e18 == 100%.
        assertApproxEqRel(token1Bal, defaults.TOKEN1_BALANCE(), 1e6);
    }

    function test_SimulatePoolReserves_Balanced80_20Pool() external {
        uint256 token0PoolReserve = 80e18;
        uint256 token1PoolReserve = 20e18;

        setTokenBalances(token0PoolReserve, token1PoolReserve);
        reinitOracleTokenArgs(18, 18, 0.8e18);
        (uint256 token0Bal, uint256 token1Bal) = oracle.exposed_simulatePoolReserves(1e8, 1e8);
        assertApproxEqRel(token0Bal, token0PoolReserve, 1e6); // 1e18 == 100%
        assertApproxEqRel(token1Bal, token1PoolReserve, 1e6);
    }

    function test_SimulatePoolReserves_50_50Pool_tooMuchToken1() external {
        // Balance state
        uint256 token0PoolReserve = 1e18;
        uint256 token1PoolReserve = 3000e18;

        // Trade removes 0.9 token 0 from the pool
        uint256 token0AmountOut = 0.9e18;
        uint256 token1AmountIn = calcInGivenOutSignedWadMath(
            token1PoolReserve, defaults.WEIGHT_50(), token0PoolReserve, defaults.WEIGHT_50(), token0AmountOut
        );

        token0PoolReserve -= token0AmountOut;
        token1PoolReserve += token1AmountIn;

        // Set prices
        uint256 price0 = 3000e8; // 3000 USD/token 0
        uint256 price1 = 1e8; // 1 USD/token 1

        // Mock token balances
        setTokenBalances(token0PoolReserve, token1PoolReserve);

        // Simulate pool reserves
        (uint256 token0Bal, uint256 token1Bal) = oracle.exposed_simulatePoolReserves(price0, price1);

        // Assertions
        assertApproxEqRel(token0Bal, token0PoolReserve + token0AmountOut, 1e8); // 1e18 == 100%
        assertApproxEqRel(token1Bal, token1PoolReserve - token1AmountIn, 1e8);

        // One would expect the pool to be balanced after the trade adjustment.
        // Verify approximately balanced pool reserves.
        assertApproxEqRel(
            token0Bal * price0,
            token1Bal * price1,
            1e8, // 1e18 == 100%
            "Relative price calculation incorrect"
        );
    }

    function test_SimulatePoolReserves_50_50Pool_tooMuchToken0() external {
        // Balance state
        uint256 token0PoolReserve = 1e18;
        uint256 token1PoolReserve = 3000e18;

        // Trade removes 2_700 token 1 from the pool
        uint256 token1AmountOut = 2700e18;
        uint256 token0AmountIn = calcInGivenOutSignedWadMath(
            token0PoolReserve, defaults.WEIGHT_50(), token1PoolReserve, defaults.WEIGHT_50(), token1AmountOut
        );

        token0PoolReserve += token0AmountIn;
        token1PoolReserve -= token1AmountOut;

        // Set prices
        uint256 price0 = 3000e8; // 3000 USD/token 0
        uint256 price1 = 1e8; // 1 USD/token 1

        // Mock token balances
        setTokenBalances(token0PoolReserve, token1PoolReserve);

        // Simulate pool reserves
        (uint256 token0Bal, uint256 token1Bal) = oracle.exposed_simulatePoolReserves(price0, price1);

        emit log_uint(token0PoolReserve);
        emit log_uint(token1PoolReserve);

        // Assertions
        assertApproxEqRel(token0Bal, token0PoolReserve - token0AmountIn, 1e8); // 1e18 == 100%
        assertApproxEqRel(token1Bal, token1PoolReserve + token1AmountOut, 1e8);
    }

    function test_SimulatePoolReserves_Imbalanced_50_50Pool_IncreasingToken0Amount() external {
        uint256 token0Reserve = 100e18;
        uint256 token1Reserve = 300_000e18;
        uint256 price0 = 3000e8;
        uint256 price1 = 1e8;

        uint256[] memory token0Reserves = new uint256[](7);
        token0Reserves[0] = 102e18;
        token0Reserves[1] = 105e18;
        token0Reserves[2] = 110e18;
        token0Reserves[3] = 120e18;
        token0Reserves[4] = 150e18;
        token0Reserves[5] = 300e18;
        token0Reserves[6] = 100_000e18;

        for (uint256 i; i < token0Reserves.length; ++i) {
            // Calculate token1AmountOut given token0Reserves: trading against pool
            uint256 token1AmountOut = calcOutGivenInSignedWadMath(
                token0Reserve,
                defaults.WEIGHT_50(),
                token1Reserve,
                defaults.WEIGHT_50(),
                token0Reserves[i] - token0Reserve
            );

            // Mock token balances
            setTokenBalances(token0Reserves[i], token1Reserve - token1AmountOut);

            // Simulate pool reserves
            (uint256 token0Bal, uint256 token1Bal) = oracle.exposed_simulatePoolReserves(price0, price1);

            // Assertions
            assertApproxEqRel(token0Bal, token0Reserve, 1e8); // 1e18 == 100%
            assertApproxEqRel(token1Bal, token1Reserve, 1e8);

            // One would expect the pool to be balanced after the trade adjustment.
            // Verify approximately balanced pool reserves.
            assertApproxEqRel(
                token0Bal * price0,
                token1Bal * price1,
                1e8, // 1e18 == 100%
                "Relative price calculation incorrect"
            );
        }
    }

    function test_SimulatePoolReserves_Imbalanced_50_50Pool_IncreasingToken1Amount() external {
        uint256 token0Reserve = 100e18;
        uint256 token1Reserve = 300_000e18;
        uint256 price0 = 3000e8;
        uint256 price1 = 1e8;

        uint256[] memory token1Reserves = new uint256[](7);
        token1Reserves[0] = 306_000e18;
        token1Reserves[1] = 315_000e18;
        token1Reserves[2] = 350_000e18;
        token1Reserves[3] = 400_000e18;
        token1Reserves[4] = 750_000e18;
        token1Reserves[5] = 900_000e18;
        token1Reserves[6] = 30_000_000e18;

        for (uint256 i; i < token1Reserves.length; ++i) {
            // Calculate token1AmountOut given token0Reserves: trading against pool
            uint256 token0AmountOut = calcOutGivenInSignedWadMath(
                token1Reserve,
                defaults.WEIGHT_50(),
                token0Reserve,
                defaults.WEIGHT_50(),
                token1Reserves[i] - token1Reserve
            );

            // Mock token balances
            setTokenBalances(token0Reserve - token0AmountOut, token1Reserves[i]);

            // Simulate pool reserves
            (uint256 token0Bal, uint256 token1Bal) = oracle.exposed_simulatePoolReserves(price0, price1);

            // Assertions
            assertApproxEqRel(token0Bal, token0Reserve, 1e8); // 1e18 == 100%
            assertApproxEqRel(token1Bal, token1Reserve, 1e8);

            // One would expect the pool to be balanced after the trade adjustment.
            // Verify approximately balanced pool reserves.
            assertApproxEqRel(
                token0Bal * price0,
                token1Bal * price1,
                1e8, // 1e18 == 100%
                "Relative price calculation incorrect"
            );
        }
    }

    // @todo: @bh2smith - is this test still helpful?
    //    function test_SimulatePoolReserves_ImbalancedPool() external {
    //        uint256 usdcReserve = 300_000e18;
    //        uint256 price0 = 3000e8; // 3000 USD/ETH
    //        uint256 price1 = 1e8; // 1 ETH/USD
    //        uint256 weight = 0.5e18;
    //
    //        uint256[] memory ethReserves = new uint256[](7);
    //
    //        ethReserves[0] = 102e18;
    //        ethReserves[1] = 105e18;
    //        ethReserves[2] = 110e18;
    //        ethReserves[3] = 120e18;
    //        ethReserves[4] = 150e18;
    //        ethReserves[5] = 300e18;
    //        ethReserves[6] = 100_000e18;
    //
    //        uint256[] memory expectedDiffs = new uint256[](7);
    //
    //        // Pool Imbalance (BIPS) after trade:
    //        expectedDiffs[0] = 0;
    //        expectedDiffs[1] = 5;
    //        expectedDiffs[2] = 22;
    //        expectedDiffs[3] = 82; // 10% Initial pool imbalance => 0.82% after trade.
    //        expectedDiffs[4] = 399;
    //        expectedDiffs[5] = 2499;
    //        expectedDiffs[6] = 9960;
    //        for (uint256 i = 0; i < ethReserves.length; i++) {
    //            // assertPoolBalanceAfterTrade(ethReserves[i], usdcReserve, price0, price1, weight, expectedDiffs[i]);
    //            setTokenBalances(ethReserves[i], usdcReserve);
    //            (uint256 token0Bal, uint256 token1Bal) = oracle.exposed_simulatePoolReserves(price0, price1);
    //
    //            uint256 diffBefore = relativeDiffBips(ethReserves[i], usdcReserve, price0, price1);
    //
    //            // @todo: fix these assertions
    //            // assertApproxEqRel(token0Bal, ethReserves[i] - order.sellAmount);
    //            // assertApproxEqRel(token1Bal, usdcReserve + order.buyAmount);
    //
    //            uint256 diffAfter = relativeDiffBips(token0Bal, token1Bal, price0, price1);
    //            console.log(diffBefore, diffAfter);
    //            assertEq(diffAfter, expectedDiffs[i]);
    //        }
    //    }

    //    function relativeDiffBips(
    //        uint256 token0Bal,
    //        uint256 token1Bal,
    //        uint256 price0,
    //        uint256 price1
    //    )
    //        internal
    //        pure
    //        returns (uint256 bips)
    //    {
    //        uint256 value0 = token0Bal * price0;
    //        uint256 value1 = token1Bal * price1;
    //
    //        // Calculate relative difference as BIPS (1 BIP = 0.01%)
    //        if (value0 > value1) {
    //            bips = ((value0 - value1) * 10_000) / value0;
    //        } else {
    //            bips = ((value1 - value0) * 10_000) / value1;
    //        }
    //    }
}
