// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.25;

import { BaseTest } from "test/Base.t.sol";

contract CalculatePrice_Fuzz_Unit_Test is BaseTest {
    function testFuzz_CalculatePrice(
        uint8 token0Decimals,
        uint8 token1Decimals,
        uint8 feed0Decimals,
        uint8 feed1Decimals,
        uint256 token0Bal,
        uint256 token1Bal,
        uint256 price0,
        uint256 price1
    )
        external
    {
        token0Decimals = boundUint8(token0Decimals, 6, 18);
        token1Decimals = boundUint8(token1Decimals, 6, 18);
        feed0Decimals = boundUint8(feed0Decimals, 6, 18);
        feed1Decimals = boundUint8(feed1Decimals, 6, 18);

        token0Bal = bound(token0Bal, 1, 1e4);
        token1Bal = bound(token1Bal, 1, 1e4);
        price0 = bound(price0, 1, 1e6);
        price1 = bound(price1, 1, 1e6);

        mock_pool_totalSupply(mocks.pool, defaults.LP_TOKEN_SUPPLY());
        reinitOracleAll(feed0Decimals, feed1Decimals, token0Decimals, token1Decimals);

        token0Bal = token0Bal * 10 ** token0Decimals;
        token1Bal = token1Bal * 10 ** token1Decimals;
        price0 = price0 * 10 ** feed0Decimals;
        price1 = price1 * 10 ** feed1Decimals;

        uint256 value0 = (token0Bal * price0 * 1e18) / (10 ** (token0Decimals + feed0Decimals));
        uint256 value1 = (token1Bal * price1 * 1e18) / (10 ** (token1Decimals + feed1Decimals));

        uint256 price = oracle.exposed_calculatePrice(token0Bal, token1Bal, price0, price1);

        assertEq(price, ((value0 + value1) * 1e8) / defaults.LP_TOKEN_SUPPLY(), "price");
    }
}
