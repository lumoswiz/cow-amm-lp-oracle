// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.25;

import { ICOWAMMPoolHelper } from "@cow-amm/interfaces/ICOWAMMPoolHelper.sol";
import { AggregatorV3Interface } from "@cow-amm/interfaces/AggregatorV3Interface.sol";
import { IERC20 } from "cowprotocol/contracts/interfaces/IERC20.sol";
import { GPv2Order } from "cowprotocol/contracts/libraries/GPv2Order.sol";

contract LPOracle {
    /// @notice Thrown when Chainlink price feeds with more than 18 decimals are used.
    error UnsupportedDecimals();

    /// @notice BCoWPool address.
    address public immutable POOL;

    /// @notice BCoWHelper contract.
    ICOWAMMPoolHelper public immutable HELPER;

    /// @notice Pool token 0.
    /// @dev Token at index 0 from `pool.getFinalTokens` call.
    IERC20 public immutable TOKEN0;

    /// @notice Pool token 1.
    /// @dev Token at index 1 from `pool.getFinalTokens` call.
    IERC20 public immutable TOKEN1;

    /// @notice Pool token 0 decimals
    uint256 public immutable TOKEN0_DECIMALS;

    /// @notice Pool token 1 decimals
    uint256 public immutable TOKEN1_DECIMALS;

    /// @notice Chainlink USD price for pool token 0
    AggregatorV3Interface public immutable FEED0;

    /// @notice Chainlink USD price for pool token 1
    AggregatorV3Interface public immutable FEED1;

    /// @dev Must check Chainlink price feeds match pool token ordering.
    /// @param _pool BCoWPool address.
    /// @param _helper BCoWHelper address.
    /// @param _feed0 Chainlink USD price feed for pool token at index 0.
    /// @param _feed1 Chainlink USD price feed for pool token at index 1.
    constructor(address _pool, address _helper, address _feed0, address _feed1) {
        /* Set price feeds & revert if feeds have greater than 18 decimals */
        FEED0 = AggregatorV3Interface(_feed0);
        FEED1 = AggregatorV3Interface(_feed1);
        if (FEED0.decimals() > 18 || FEED1.decimals() > 18) revert UnsupportedDecimals();

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

    /// @notice Retrieves latest price data from Chainlink feeds and adjusts for decimals.
    /// @return price0 USD price of token 0.
    /// @return price1 USD price of token1.
    /// @return updatedAt The timestamp of the feed with the oldest price udpate.
    function _getFeedData() internal view returns (uint256 price0, uint256 price1, uint256 updatedAt) {
        /* Get latestRoundData from price feeds */
        (, int256 answer0,, uint256 updatedAt0,) = FEED0.latestRoundData();
        (, int256 answer1,, uint256 updatedAt1,) = FEED1.latestRoundData();

        /* Adjust answers for price feed decimals */
        (price0, price1) = _adjustDecimals(uint256(answer0), uint256(answer1), FEED0.decimals(), FEED1.decimals());

        /* Set update timestamp of oldest price feed */
        updatedAt = updatedAt0 < updatedAt1 ? updatedAt0 : updatedAt1;
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

    /// @notice Retrieves the simulated pool reserves post rebalancing trade.
    /// @dev Adjusts the reserve balances for decimal differences to prepare for LP token price computation.
    /// @param order The simulated rebalancing trade order.
    /// @return token0Bal Simulated pool balance of token 0.
    /// @return token1Bal Simulated pool balance of token 1.
    function _simulatePoolReserves(GPv2Order.Data memory order)
        internal
        view
        returns (uint256 token0Bal, uint256 token1Bal)
    {
        /* Get current pool token balances */
        uint256 balance0 = TOKEN0.balanceOf(POOL);
        uint256 balance1 = TOKEN1.balanceOf(POOL);

        /* Determine post rebalancing trade pool token balances */
        if (TOKEN0 == order.buyToken) {
            balance0 += order.buyAmount;
            balance1 -= order.sellAmount;
        } else {
            balance0 -= order.sellAmount;
            balance1 += order.buyAmount;
        }

        /* Adjust for decimals */
        (token0Bal, token1Bal) = _adjustDecimals(balance0, balance1, TOKEN0_DECIMALS, TOKEN1_DECIMALS);
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
