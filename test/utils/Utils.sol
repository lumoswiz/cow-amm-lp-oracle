// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.25 < 0.9.0;

import { Test } from "forge-std/Test.sol";
import { OrderParams } from "test/utils/Types.sol";

contract Utils is Test {
    /*----------------------------------------------------------*|
    |*  # MOCK CALLS: ERC20                                     *|
    |*----------------------------------------------------------*/

    function mock_token_balanceOf(address token, address pool, uint256 balance) internal {
        vm.mockCall(token, abi.encodeWithSignature("balanceOf(address)", pool), abi.encode(balance));
    }

    /*----------------------------------------------------------*|
    |*  # MOCK CALLS: BCoWPool                                 *|
    |*----------------------------------------------------------*/

    function mock_pool_getNormalizedWeight(address pool, address token, uint256 normWeight) internal {
        vm.mockCall(pool, abi.encodeWithSignature("getNormalizedWeight(address)", token), abi.encode(normWeight));
    }

    function mock_pool_getDenormalizedWeight(address pool, address token, uint256 denormWeight) internal {
        vm.mockCall(pool, abi.encodeWithSignature("getDenormalizedWeight(address)", token), abi.encode(denormWeight));
    }

    function mock_pool_getFinalTokens(address pool, address token0, address token1) internal {
        address[] memory tokens = new address[](2);
        tokens[0] = token0;
        tokens[1] = token1;

        vm.mockCall(pool, abi.encodeWithSignature("getFinalTokens()"), abi.encode(tokens));
    }

    function mock_pool__finalized(address pool) internal {
        vm.mockCall(pool, abi.encodeWithSignature("_finalized()"), abi.encode(true));
    }

    /*----------------------------------------------------------*|
    |*  # MOCK CALLS: BCoWHelper                                *|
    |*----------------------------------------------------------*/
    function mock_helper_tokens(address helper, address pool, address token0, address token1) internal {
        // Setup token addresses
        address[] memory tokens = new address[](2);
        tokens[0] = token0;
        tokens[1] = token1;

        // Mock helper.tokens() call
        vm.mockCall(helper, abi.encodeWithSignature("tokens(address)", pool), abi.encode(tokens));
    }

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

    function mock_factory_APP_DATA(address factory, bytes32 data) internal {
        vm.mockCall(factory, abi.encodeWithSignature("APP_DATA()"), abi.encode(data));
    }

    function mock_factory_isBPool(address factory, address pool) internal {
        vm.mockCall(factory, abi.encodeWithSignature("isBPool(address)", pool), abi.encode(true));
    }
}
