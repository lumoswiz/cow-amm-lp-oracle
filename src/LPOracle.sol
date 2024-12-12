// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { ICOWAMMPoolHelper } from "@cow-amm/interfaces/ICOWAMMPoolHelper.sol";
import { GPv2Order } from "cowprotocol/contracts/libraries/GPv2Order.sol";
import { IERC20 } from "cowprotocol/contracts/interfaces/IERC20.sol";

contract LPOracle {
    /// @notice BCoWPool address.
    address public immutable POOL;
    /// @notice BCoWHelper contract.
    ICOWAMMPoolHelper public immutable HELPER;

    /// @notice Pool tokens.
    /// @dev Tokens at indicies 0 and 1 in `getFinalTokens` function. Use same order for input prices vector to `order`
    /// function.
    IERC20 public immutable TOKEN0;
    IERC20 public immutable TOKEN1;

    /// @notice Pool token 0 decimals
    uint256 public immutable TOKEN0_DECIMALS;

    /// @notice Pool token 1 decimals
    uint256 public immutable TOKEN1_DECIMALS;

    /// @dev Must check Chainlink price feeds match pool token ordering.
    /// @param _pool BCoWPool address.
    /// @param _helper BCoWHelper address.
    constructor(address _pool, address _helper) {
        /* Set pool and helper contracts */
        POOL = _pool;
        HELPER = ICOWAMMPoolHelper(_helper);

        /* Gets pool tokens with correct ordering and pool validation checks */
        address[] memory tokens = HELPER.tokens(POOL);
        TOKEN0 = IERC20(tokens[0]);
        TOKEN1 = IERC20(tokens[1]);

        TOKEN0_DECIMALS = TOKEN0.decimals();
        TOKEN1_DECIMALS = TOKEN1.decimals();
    }

    /// @notice Retrieves the order to satisfy the pool's invariants given the token prices.
    /// @dev Zero fee constant function AMM.
    /// @dev Decimals for price0 and price1 should be identical.
    /// @param price0 USD price of pool token 0.
    /// @param price1 USD price of pool token 1.
    /// @return order Order required to satisfy pool's invariants given the input pricing vector.
    function _simulateOrder(uint256 price0, uint256 price1) internal view returns (GPv2Order.Data memory order) {
        uint256[] memory prices = _normalizePrices(price0, price1);
        /* Simulate the order */
        (order,,,) = HELPER.order(POOL, prices);
    }

    /// @notice Normalizes input prices to the format expected by the pool helper
    /// @dev First price is normalized to 1e18, second price is adjusted relative to first price
    /// @dev Takes into account token decimals when calculating relative price
    /// @param price0 price of pool token 0
    /// @param price1 price of pool token 1
    /// @return prices Array of normalized prices where prices[0] = 1e18 and prices[1] is the relative price
    function _normalizePrices(uint256 price0, uint256 price1) internal view returns (uint256[] memory prices) {
        prices = new uint256[](2);
        prices[0] = 1e18;
        prices[1] = (price1 * (10 ** TOKEN0_DECIMALS) * 1e18) / (price0 * (10 ** TOKEN1_DECIMALS));
    }

    /// @notice Adjusts input values according to decimals.
    /// @dev Used to adjust pool reserve balances and price feed answers.
    /// @param value0 Value associated with pool token 0.
    /// @param value1 Value associated with pool token 1.
    /// @param decimals0 Decimals for value0.
    /// @param decimals1 Decimals for value1.
    /// @return Ensures the return values have the same decimal base.
    function _adjustDecimals(
        uint256 value0,
        uint256 value1,
        uint256 decimals0,
        uint256 decimals1
    )
        internal
        pure
        returns (uint256, uint256)
    {
        if (decimals0 == decimals1) {
            return (value0, value1);
        } else {
            return (value0 * (10 ** (18 - decimals0)), value1 * (10 ** (18 - decimals1)));
        }
    }
}