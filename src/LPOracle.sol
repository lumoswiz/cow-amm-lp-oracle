// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.25;

import { AggregatorV3Interface } from "@cow-amm/interfaces/AggregatorV3Interface.sol";
import { IERC20 } from "cowprotocol/contracts/interfaces/IERC20.sol";
import { IBCoWPool } from "@balancer/cow-amm/src/interfaces/IBCoWPool.sol";
import { wadMul, wadDiv, wadPow } from "solmate/utils/SignedWadMath.sol";

contract LPOracle is AggregatorV3Interface {
    /// @notice Thrown when Chainlink price feeds with more than 18 decimals are used.
    error UnsupportedDecimals();

    /// @notice BCoWPool address.
    address public immutable POOL;

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

    /// @notice Pool token 0 normalized weight
    int256 public immutable WEIGHT0;

    /// @notice Pool token 1 normalized weight
    int256 public immutable WEIGHT1;

    /// @notice Chainlink USD price for pool token 0
    AggregatorV3Interface public immutable FEED0;

    /// @notice Chainlink USD price for pool token 1
    AggregatorV3Interface public immutable FEED1;

    /// @dev Must check Chainlink price feeds match pool token ordering.
    /// @param _pool BCoWPool address.
    /// @param _feed0 Chainlink USD price feed for pool token at index 0.
    /// @param _feed1 Chainlink USD price feed for pool token at index 1.
    constructor(address _pool, address _feed0, address _feed1) {
        /* Set price feeds & revert if feeds have greater than 18 decimals */
        FEED0 = AggregatorV3Interface(_feed0);
        FEED1 = AggregatorV3Interface(_feed1);
        if (FEED0.decimals() > 18 || FEED1.decimals() > 18) revert UnsupportedDecimals();

        /* Set pool contract */
        POOL = _pool;

        /* Gets pool tokens with correct ordering and pool validation checks */
        address[] memory tokens = IBCoWPool(POOL).getFinalTokens();
        TOKEN0 = IERC20(tokens[0]);
        TOKEN1 = IERC20(tokens[1]);

        /* Set token decimals */
        TOKEN0_DECIMALS = TOKEN0.decimals();
        TOKEN1_DECIMALS = TOKEN1.decimals();

        /* Add pool token normalized weights casted to int256 */
        WEIGHT0 = int256(IBCoWPool(POOL).getNormalizedWeight(tokens[0]));
        WEIGHT1 = int256(IBCoWPool(POOL).getNormalizedWeight(tokens[1]));
    }

    /*----------------------------------------------------------*|
    |*  # AGGREGATOR V3 INTERFACE REQUIREMENTS                  *|
    |*----------------------------------------------------------*/

    /// @notice Returns the number of decimals used.
    function decimals() external pure returns (uint8) {
        return 8;
    }

    /// @notice Returns the description of the LP token pricing oracle.
    function description() external view returns (string memory) {
        return string.concat(IERC20(POOL).name(), " LP Token / USD");
    }

    /// @notice Returns the oracle version.
    /// @dev Chainlink interface requires implementation.
    function version() external pure returns (uint256) {
        return 0;
    }

    /// @dev Chainlink interface requires implementation. No meaningful values for this contract.
    function getRoundData(uint80)
        external
        pure
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (0, 0, 0, 0, 0);
    }

    /// @notice Returns the latest price data for the BCoWPool AMM LP Token.
    /// @dev Price is determined based on simulated reserve balances post rebalancing trade from external price feeds.
    /// @return roundId Not implemented.
    /// @return answer LP Token price.
    /// @return startedAt Not implemented.
    /// @return updatedAt The timestamp of the feed with the oldest price udpate.
    /// @return answeredInRound Not implemented.
    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        /* Get the price feed data */
        (uint256 price0, uint256 price1, uint256 updatedAt_) = _getFeedData();

        /* Simulate pool reserves with pool AMM math */
        (uint256 token0Bal, uint256 token1Bal) = _simulatePoolReserves(price0, price1);

        /* Determine LP token price */
        uint256 lpPrice = _calculatePrice(token0Bal, token1Bal, price0, price1);

        return (0, int256(lpPrice), 0, updatedAt_, 0);
    }

    /*----------------------------------------------------------*|
    |*  # INTERNAL HELPERS                                      *|
    |*----------------------------------------------------------*/

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

    /// @notice Simulates the token balances for a 2 token weighted BCoWPool.
    /// @dev Assumes zero fees & post rebalancing trade.
    /// @param price0 Chainlink USD price for token 0.
    /// @param price1 Chainlink USD price for token 1.
    /// @return simBal0 Simulated balance for token 0.
    /// @return simBal1 Simulated balance for token 1.
    function _simulatePoolReserves(
        uint256 price0,
        uint256 price1
    )
        internal
        view
        returns (uint256 simBal0, uint256 simBal1)
    {
        /* Get pool k value */
        int256 balance0 = int256(TOKEN0.balanceOf(POOL));
        int256 balance1 = int256(TOKEN1.balanceOf(POOL));
        int256 k = wadMul(wadPow(wadDiv(balance0, balance1), WEIGHT0), balance1);

        /* Calculate simulated token 0 reserves */
        int256 x_num = wadMul(int256(price1), WEIGHT0);
        int256 x_den = wadMul(int256(price0), WEIGHT1);
        simBal0 = uint256(wadMul(k, wadPow(wadDiv(x_num, x_den), WEIGHT1)));

        /* Calculate simulated token 1 reserves */
        int256 y_num = wadMul(int256(price0), WEIGHT1);
        int256 y_den = wadMul(int256(price1), WEIGHT0);
        simBal1 = uint256(wadMul(k, wadPow(wadDiv(y_num, y_den), WEIGHT0)));
    }

    /// @notice Calculates the LP token price for the pool given token prices, simulated balances and LP token supply.
    /// @dev Intermediate values have 18 decimals & should accomodate different token and feed decimals.
    /// @dev Assumes: pool LP token ERC-20 implementation uses 18 decimals.
    /// @param token0Bal Simulated pool balance of token0.
    /// @param token1Bal Simulated pool balance of token1.
    /// @param price0 External USD price feed latest answer for pool token0.
    /// @param price1 External USD price feed latest answer for pool token1.
    /// @return LP token USD price (8 decimals).
    function _calculatePrice(
        uint256 token0Bal,
        uint256 token1Bal,
        uint256 price0,
        uint256 price1
    )
        internal
        view
        returns (uint256)
    {
        uint256 value0 = (token0Bal * price0 * 1e18) / (10 ** (TOKEN0_DECIMALS + FEED0.decimals()));
        uint256 value1 = (token1Bal * price1 * 1e18) / (10 ** (TOKEN1_DECIMALS + FEED1.decimals()));
        return ((value0 + value1) * 1e8) / IERC20(POOL).totalSupply();
    }
}
