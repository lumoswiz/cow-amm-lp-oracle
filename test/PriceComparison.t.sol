// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.25;

import { BaseTest } from "test/Base.t.sol";

contract PriceComparisonTest is BaseTest {
    uint256 internal constant BALANCE0 = 1e18;
    uint256 internal constant BALANCE1 = 3000e18;
    int256 internal constant ANSWER0 = 3000e8;
    int256 internal constant ANSWER1 = 1e8;

    function setUp() public override {
        // Run base test setup
        BaseTest.setUp();

        // Set mock data for latest round data
        setLatestRoundDataMocks(ANSWER0, ANSWER1, BALANCE0, BALANCE1, defaults.WEIGHT_50());
    }

    // gas: 46934
    function test_latestRoundData() external {
        uint256 startGas = gasleft();
        (, int256 answer,,,) = oracle.latestRoundData();
        emit log_named_uint("v1 gas", startGas - gasleft());
        assertApproxEqRel(uint256(answer), 6e8, 1e15); // within 0.1%
    }

    // gas: 28513- Approx 40% savings.
    function test_latestRoundDataSolady() external {
        uint256 startGas = gasleft();
        (, int256 answer,,,) = oracle.latestRoundDataSolady();
        emit log_named_uint("solady gas", startGas - gasleft());
        assertApproxEqRel(uint256(answer), 6e8, 1e15); // within 0.1%
    }

    // gas: 28998.
    // Lots of int256 casting in this implementation. We can avoid this by saving WEIGHT values as int's,
    // & we don't have to cast chainlink price feed answers to uint256.
    function test_latestRoundDataSolmate() external {
        uint256 startGas = gasleft();
        (, int256 answer,,,) = oracle.latestRoundDataSolmate();
        emit log_named_uint("solmate gas", startGas - gasleft());
        assertApproxEqRel(uint256(answer), 6e8, 1e15); // within 0.1
    }
}
