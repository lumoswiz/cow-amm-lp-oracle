// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.25;

import { BaseTest } from "test/Base.t.sol";
import { FeedParams } from "test/utils/Types.sol";
import { IERC20 } from "cowprotocol/contracts/interfaces/IERC20.sol";
import { stdError } from "forge-std/StdError.sol";

contract LatestRoundData_Fuzz_Unit_Test is BaseTest {
    modifier givenWhenDecimalsLtEq18() {
        _;
    }

    function testFuzz_ShouldRevert_PoolBalanceDifferenceTooLarge(
        uint256 token0PoolReserve,
        uint256 token1PoolReserve
    )
        external
        givenWhenDecimalsLtEq18
    {
        token0PoolReserve = bound(token0PoolReserve, 1, (type(uint256).max / 1e18) - 1);
        token1PoolReserve = bound(token1PoolReserve, token0PoolReserve * 1e18 + 1, type(uint256).max);

        // Mocks
        setLatestRoundDataMocks(defaults.ANSWER0(), defaults.ANSWER1(), token0PoolReserve, token1PoolReserve);

        vm.expectRevert();
        oracle.latestRoundData();
    }

    modifier whenValidPoolBalances() {
        _;
    }

    function testFuzz_shouldRevert_LtEqZeroAnswer0(int256 answer0)
        external
        givenWhenDecimalsLtEq18
        whenValidPoolBalances
    {
        vm.assume(answer0 <= 0);

        setLatestRoundDataMocks(answer0, defaults.ANSWER1(), defaults.TOKEN0_BALANCE(), defaults.TOKEN1_BALANCE());

        vm.expectRevert();
        oracle.latestRoundData();
    }

    function testFuzz_shouldRevert_LtEqZeroAnswer1(int256 answer1)
        external
        givenWhenDecimalsLtEq18
        whenValidPoolBalances
    {
        vm.assume(answer1 <= 0);

        setLatestRoundDataMocks(defaults.ANSWER0(), answer1, defaults.TOKEN0_BALANCE(), defaults.TOKEN1_BALANCE());

        vm.expectRevert();
        oracle.latestRoundData();
    }

    modifier whenPositivePrices() {
        _;
    }

    modifier whenPositiveLpSupply() {
        _;
    }

    modifier whenSameFeedDecimals() {
        _;
    }

    modifier whenBalancedPool() {
        _;
    }

    function testFuzz_ArbitraryWeights_BalancedPool(
        uint8 decimals,
        int256 answer0,
        int256 answer1,
        uint256 weight0,
        uint256 token1ValueLocked,
        uint256 lpSupply
    )
        external
        givenWhenDecimalsLtEq18
        whenValidPoolBalances
        whenPositivePrices
        whenPositiveLpSupply
        whenSameFeedDecimals
        whenBalancedPool
    {
        // Bounds
        decimals = boundUint8(decimals, 6, 18);
        int256 assetUnit = int256(10 ** decimals);
        weight0 = bound(weight0, 2e16, 98e16); // 2% to 98% weights
        token1ValueLocked = bound(token1ValueLocked, 5e21, 1e27); // 5k to 1bn
        answer0 = bound(answer0, assetUnit, 1_000_000 * assetUnit); // 1 to 1m
        answer1 = bound(answer1, assetUnit, 1_000_000 * assetUnit); // 1 to 1m
        lpSupply = bound(lpSupply, 100e18, 1e24); // 100 to 1m

        // Re-init oracle to adjust for different pool weights
        reinitOracleTokenArgs(18, 18, weight0);

        // Calculations
        uint256 token1PoolReserve = calcBalanceFromTVL(decimals, answer1, token1ValueLocked);
        uint256 token0PoolReserve =
            calcToken0FromToken1(decimals, decimals, answer0, answer1, weight0, token1PoolReserve);
        uint256 naivePrice =
            calculateNaivePrice(decimals, decimals, answer0, answer1, token0PoolReserve, token1PoolReserve, lpSupply);

        // Mocks
        setAllLatestRoundDataMocks(
            decimals,
            decimals,
            answer0,
            answer1,
            defaults.DEC_1_2024(),
            defaults.DEC_1_2024(),
            token0PoolReserve,
            token1PoolReserve,
            lpSupply
        );

        // Retrieve oracle answer
        (, int256 answer,,,) = oracle.latestRoundData();

        // Assertions
        // For a balanced pool, `naivePrice` and oracle answer should be the same
        assertApproxEqRel(uint256(answer), naivePrice, 1e15); // 100% == 1e18
    }
}
