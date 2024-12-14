// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.25 < 0.9.0;

import { Test } from "forge-std/Test.sol";
import { OrderParams } from "test/utils/Types.sol";
import { GPv2Order } from "cowprotocol/contracts/libraries/GPv2Order.sol";

contract Utils is Test {
    /*----------------------------------------------------------*|
    |*  # BOUNDS                                                *|
    |*----------------------------------------------------------*/

    /// @dev Helper to bound uint8 values for fuzz testing.
    function boundUint8(uint8 x, uint8 min, uint8 max) internal pure returns (uint8) {
        return uint8(bound(x, min, max));
    }

    /*----------------------------------------------------------*|
    |*  # MOCK CALLS: SHARED                                    *|
    |*----------------------------------------------------------*/

    /// @dev Helper to mock a `decimals()` call to an arbitrary address.
    function mock_address_decimals(address addr, uint8 decimals) internal {
        vm.mockCall(addr, abi.encodeWithSignature("decimals()"), abi.encode(decimals));
    }

    /*----------------------------------------------------------*|
    |*  # MOCK CALLS: AggregatorV3Interface                     *|
    |*----------------------------------------------------------*/

    function mock_feed_latestRoundData(address feed, int256 answer, uint256 updatedAt) internal {
        vm.mockCall(feed, abi.encodeWithSignature("latestRoundData()"), abi.encode(0, answer, 0, updatedAt, 0));
    }

    /*----------------------------------------------------------*|
    |*  # MOCK CALLS: ERC20                                     *|
    |*----------------------------------------------------------*/

    /// @dev Helper to mock token pool balances.
    function mock_token_balanceOf(address token, address pool, uint256 balance) internal {
        vm.mockCall(token, abi.encodeWithSignature("balanceOf(address)", pool), abi.encode(balance));
    }

    /*----------------------------------------------------------*|
    |*  # MOCK CALLS: BCoWPool                                 *|
    |*----------------------------------------------------------*/

    /// @dev Helper to mock the normalized weight of a pool token.
    function mock_pool_getNormalizedWeight(address pool, address token, uint256 normWeight) internal {
        vm.mockCall(pool, abi.encodeWithSignature("getNormalizedWeight(address)", token), abi.encode(normWeight));
    }

    /// @dev Helper to mock the denormalized weight of a pool token.
    function mock_pool_getDenormalizedWeight(address pool, address token, uint256 denormWeight) internal {
        vm.mockCall(pool, abi.encodeWithSignature("getDenormalizedWeight(address)", token), abi.encode(denormWeight));
    }

    /// @dev Helper to mock the `pool.getFinalTokens` call.
    function mock_pool_getFinalTokens(address pool, address token0, address token1) internal {
        address[] memory tokens = new address[](2);
        tokens[0] = token0;
        tokens[1] = token1;

        vm.mockCall(pool, abi.encodeWithSignature("getFinalTokens()"), abi.encode(tokens));
    }

    /// @dev Helper to set the pool state as finalized, required for LPOracle._simulateOrder calls.
    function mock_pool__finalized(address pool) internal {
        vm.mockCall(pool, abi.encodeWithSignature("_finalized()"), abi.encode(true));
    }

    /*----------------------------------------------------------*|
    |*  # MOCK CALLS: BCoWHelper                                *|
    |*----------------------------------------------------------*/

    /// @dev Helper to mock the tokens array in BCoWHelper.
    function mock_helper_tokens(address helper, address pool, address token0, address token1) internal {
        // Setup token addresses
        address[] memory tokens = new address[](2);
        tokens[0] = token0;
        tokens[1] = token1;

        // Mock helper.tokens() call
        vm.mockCall(helper, abi.encodeWithSignature("tokens(address)", pool), abi.encode(tokens));
    }

    /// @dev Helper to mock the BCoWHelper._reserves call.
    function mock_helper_reserves(
        address pool,
        address token,
        uint256 balance,
        uint256 normWeight,
        uint256 denormWeight
    )
        internal
    {
        mock_token_balanceOf(token, pool, balance);
        mock_pool_getNormalizedWeight(pool, token, normWeight);
        mock_pool_getDenormalizedWeight(pool, token, denormWeight);
    }

    /// @dev Helper to aggregate all mock calls requried for the BCoWHelper.order call in LPOracle._simulateOrder.
    function mock_helper_order(OrderParams memory params) internal {
        // Mock BCoWFactory.isBPool
        mock_factory_isBPool(params.factory, params.pool);

        // Mock BCowPool.getFinalTokens
        mock_pool_getFinalTokens(params.pool, params.token0.addr, params.token1.addr);

        // Mocks helper._reserves for token0
        mock_helper_reserves(
            params.pool, params.token0.addr, params.token0.balance, params.token0.normWeight, params.token0.denormWeight
        );

        // Mocks helper._reserves for token1
        mock_helper_reserves(
            params.pool, params.token1.addr, params.token1.balance, params.token1.normWeight, params.token1.denormWeight
        );
    }

    /*----------------------------------------------------------*|
    |*  # MOCK CALLS: BCoWFactory                               *|
    |*----------------------------------------------------------*/

    /// @dev Helper to mock the `APP_DATA` in the factory contract, required to deploy MockBCoWHelper.
    function mock_factory_APP_DATA(address factory, bytes32 data) internal {
        vm.mockCall(factory, abi.encodeWithSignature("APP_DATA()"), abi.encode(data));
    }

    /// @dev Helper to mock the factory.isBPool call, required to mock the order.
    function mock_factory_isBPool(address factory, address pool) internal {
        vm.mockCall(factory, abi.encodeWithSignature("isBPool(address)", pool), abi.encode(true));
    }
}
