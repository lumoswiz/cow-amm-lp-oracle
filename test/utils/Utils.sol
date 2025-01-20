// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.25 < 0.9.0;

import { Test } from "forge-std/Test.sol";
import { IERC20 } from "cowprotocol/contracts/interfaces/IERC20.sol";

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

    function mock_token_balanceOf(IERC20 token, IERC20 pool, uint256 balance) internal {
        vm.mockCall(address(token), abi.encodeWithSignature("balanceOf(address)", address(pool)), abi.encode(balance));
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

    /// @dev Helper to mock total supply of pool LP tokens
    function mock_pool_totalSupply(address pool, uint256 supply) internal {
        vm.mockCall(pool, abi.encodeWithSignature("totalSupply()"), abi.encode(supply));
    }
}
